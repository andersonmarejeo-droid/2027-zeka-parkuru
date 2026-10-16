import 'dart:math' as math;

import 'cafe_shift_scenario.dart';

class CafeOrderProgress {
  CafeOrderProgress(this.spec) : patience = spec.patienceSeconds;

  final CafeOrderSpec spec;
  double patience;
  int stageIndex = 0;
  CafeStation? assignedStation;
  bool stockReserved = false;

  bool get readyToServe => stageIndex >= spec.route.length;
  CafeStation? get nextStation => readyToServe ? null : spec.route[stageIndex];
  double get patienceFraction =>
      (patience / spec.patienceSeconds).clamp(0, 1).toDouble();
}

class CafeStationState {
  CafeStationState(this.station);

  final CafeStation station;
  int? orderId;
  double remaining = 0;
  double totalDuration = 0;

  double get progress => totalDuration <= 0
      ? 0
      : (1 - remaining / totalDuration).clamp(0, 1).toDouble();
  bool get busy => orderId != null;
}

class CafeShiftStepResult {
  const CafeShiftStepResult({
    this.completedStages = 0,
    this.arrivals = 0,
    this.missed = 0,
    this.completed = false,
    this.failed = false,
  });

  final int completedStages;
  final int arrivals;
  final int missed;
  final bool completed;
  final bool failed;
}

class CafeActionResult {
  const CafeActionResult({
    this.accepted = false,
    this.stageStarted = false,
    this.served = false,
    this.points = 0,
  });

  final bool accepted;
  final bool stageStarted;
  final bool served;
  final int points;
}

/// Concurrent station production, limited ingredient stock and customer timing.
class CafeShiftEngine {
  CafeShiftEngine({required this.scenario})
    : stock = scenario.startingStock,
      _stations = <CafeStation, CafeStationState>{
        for (final CafeStation station in CafeStation.values)
          station: CafeStationState(station),
      } {
    for (
      int count = 0;
      count < math.min(scenario.activeLimit, scenario.orders.length);
      count++
    ) {
      _spawnNext();
    }
    nextArrivalAt = scenario.arrivalInterval;
  }

  final CafeShiftScenario scenario;
  final Map<CafeStation, CafeStationState> _stations;
  final List<CafeOrderProgress> _orders = <CafeOrderProgress>[];
  double elapsed = 0;
  late double nextArrivalAt;
  int spawnedCount = 0;
  int servedCount = 0;
  int missedCount = 0;
  int totalTips = 0;
  int stock;
  bool completed = false;
  bool failed = false;

  List<CafeOrderProgress> get orders =>
      List<CafeOrderProgress>.unmodifiable(_orders);
  List<CafeStationState> get stations =>
      List<CafeStationState>.unmodifiable(_stations.values);
  int get ordersRemaining => scenario.orders.length - servedCount - missedCount;
  int get completedOrdersNeeded =>
      scenario.orders.length - scenario.allowedMisses;
  double get rushPressure =>
      (_orders.length / scenario.activeLimit).clamp(0, 1).toDouble();

  CafeStationState station(CafeStation station) => _stations[station]!;
  CafeOrderProgress? order(int id) {
    for (final CafeOrderProgress order in _orders) {
      if (order.spec.id == id) return order;
    }
    return null;
  }

  CafeActionResult startStage(int orderId, CafeStation station) {
    if (completed || failed) return const CafeActionResult();
    final CafeOrderProgress? ticket = order(orderId);
    final CafeStationState equipment = _stations[station]!;
    if (ticket == null ||
        ticket.readyToServe ||
        ticket.assignedStation != null ||
        ticket.nextStation != station ||
        equipment.busy ||
        (!ticket.stockReserved && stock <= 0)) {
      return const CafeActionResult();
    }
    if (!ticket.stockReserved) {
      ticket.stockReserved = true;
      stock--;
    }
    final double duration = ticket.spec.stageSeconds[ticket.stageIndex];
    ticket.assignedStation = station;
    equipment
      ..orderId = orderId
      ..remaining = duration
      ..totalDuration = duration;
    return const CafeActionResult(accepted: true, stageStarted: true);
  }

  CafeActionResult serve(int orderId) {
    if (completed || failed) return const CafeActionResult();
    final CafeOrderProgress? ticket = order(orderId);
    if (ticket == null ||
        !ticket.readyToServe ||
        ticket.assignedStation != null) {
      return const CafeActionResult();
    }
    final int points = ticket.spec.tip + (ticket.patience * .8).round();
    totalTips += ticket.spec.tip;
    servedCount++;
    _orders.remove(ticket);
    _updateTerminalState();
    return CafeActionResult(accepted: true, served: true, points: points);
  }

  CafeShiftStepResult step(double deltaSeconds) {
    if (completed || failed || deltaSeconds <= 0) {
      return CafeShiftStepResult(completed: completed, failed: failed);
    }
    final double elapsedStep = deltaSeconds.clamp(0, .1).toDouble();
    elapsed += elapsedStep;
    int completedStages = 0;
    int missed = 0;
    int arrivals = 0;
    for (final CafeStationState equipment in _stations.values) {
      if (!equipment.busy) continue;
      equipment.remaining -= elapsedStep;
      if (equipment.remaining > 0) continue;
      final int orderId = equipment.orderId!;
      final CafeOrderProgress? ticket = order(orderId);
      equipment
        ..orderId = null
        ..remaining = 0
        ..totalDuration = 0;
      if (ticket != null) {
        ticket.assignedStation = null;
        ticket.stageIndex++;
        completedStages++;
      }
    }
    for (final CafeOrderProgress ticket in List<CafeOrderProgress>.of(
      _orders,
    )) {
      ticket.patience = math.max(0, ticket.patience - elapsedStep);
      if (ticket.patience > 0) continue;
      _cancelOrderWork(ticket);
      _orders.remove(ticket);
      missedCount++;
      missed++;
    }
    if (missedCount > scenario.allowedMisses) failed = true;
    if (!failed &&
        spawnedCount < scenario.orders.length &&
        _orders.length < scenario.activeLimit &&
        elapsed >= nextArrivalAt) {
      _spawnNext();
      arrivals++;
      nextArrivalAt = elapsed + scenario.arrivalInterval;
    }
    _updateTerminalState();
    return CafeShiftStepResult(
      completedStages: completedStages,
      arrivals: arrivals,
      missed: missed,
      completed: completed,
      failed: failed,
    );
  }

  void _spawnNext() {
    if (spawnedCount >= scenario.orders.length) return;
    _orders.add(CafeOrderProgress(scenario.orders[spawnedCount]));
    spawnedCount++;
  }

  void _cancelOrderWork(CafeOrderProgress ticket) {
    final CafeStation? station = ticket.assignedStation;
    if (station == null) return;
    final CafeStationState equipment = _stations[station]!;
    equipment
      ..orderId = null
      ..remaining = 0
      ..totalDuration = 0;
    ticket.assignedStation = null;
  }

  void _updateTerminalState() {
    if (failed ||
        completed ||
        spawnedCount < scenario.orders.length ||
        _orders.isNotEmpty) {
      return;
    }
    if (servedCount >= completedOrdersNeeded) {
      completed = true;
    } else {
      failed = true;
    }
  }
}
