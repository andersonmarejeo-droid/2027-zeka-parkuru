import 'dart:math' as math;

import 'slide_sweets_scenario.dart';

class ConveyorSweet {
  ConveyorSweet({required this.orderIndex, required this.targetLane});

  final int orderIndex;
  final int targetLane;
  double progress = 0;
  int lane = 1;
  int _passedGates = 0;

  bool get isSurge => false;
}

class ConveyorStepResult {
  const ConveyorStepResult({
    this.spawned = 0,
    this.gatesPassed = 0,
    this.delivered = 0,
    this.rejected = 0,
    this.overflowed = 0,
  });

  final int spawned;
  final int gatesPassed;
  final int delivered;
  final int rejected;
  final int overflowed;

  bool get hadDelivery => delivered > 0;
  bool get hadMistake => rejected > 0 || overflowed > 0;
}

/// Deterministic conveyor simulation. Diverters are persistent, while the
/// coloured packets move concurrently through junctions.
class SlideSweetsEngine {
  SlideSweetsEngine({required this.scenario})
      : _diverters = List<int>.filled(scenario.gateCount, 0);

  static const List<double> dualGatePositions = <double>[.32, .66];
  static const List<double> singleGatePositions = <double>[.48];
  static const List<double> gatePositions = dualGatePositions;

  List<double> get activeGatePositions => scenario.gateCount == 1
      ? singleGatePositions
      : dualGatePositions;

  int get gateCount => scenario.gateCount;

  final SlideSweetsScenario scenario;
  final List<ConveyorSweet> _active = <ConveyorSweet>[];
  final List<int> _diverters;
  int _nextOrder = 0;
  int _delivered = 0;
  int _missed = 0;
  double _spawnClock = .42;
  double _elapsed = 0;

  int get nextOrderIndex => _nextOrder;
  int get deliveredCount => _delivered;
  int get missedCount => _missed;
  int get queuedCount => scenario.orderCount - _nextOrder;
  int get bufferLimit => scenario.bufferCapacity + 2;
  double get elapsedSeconds => _elapsed;
  bool get isComplete => queuedCount == 0 && _active.isEmpty;
  List<ConveyorSweet> get activeSweets =>
      List<ConveyorSweet>.unmodifiable(_active);
  List<int> get diverterOffsets => List<int>.unmodifiable(_diverters);

  bool setDiverter(int gate, int offset) {
    if (gate < 0 || gate >= _diverters.length || offset < -1 || offset > 1) {
      return false;
    }
    _diverters[gate] = offset;
    return true;
  }

  int laneForOrder(int orderIndex) {
    if (orderIndex < 0 || orderIndex >= scenario.orderCount) {
      throw RangeError.index(orderIndex, scenario.orders, 'orderIndex');
    }
    return scenario.orders[orderIndex];
  }

  ConveyorStepResult step(double deltaSeconds) {
    final double delta = deltaSeconds.clamp(0, .05).toDouble();
    if (delta == 0 || isComplete) return const ConveyorStepResult();
    _elapsed += delta;
    _spawnClock -= delta;
    int spawned = 0;
    int overflowed = 0;
    final int capacity = bufferLimit;
    while (_spawnClock <= 0 && _nextOrder < scenario.orderCount) {
      if (_active.length >= capacity) {
        _missed++;
        overflowed++;
      } else {
        _active.add(
          ConveyorSweet(
            orderIndex: _nextOrder,
            targetLane: scenario.orders[_nextOrder],
          ),
        );
        spawned++;
      }
      _nextOrder++;
      _spawnClock += scenario.spawnInterval;
    }

    int gatesPassed = 0;
    int delivered = 0;
    int rejected = 0;
    final List<ConveyorSweet> completed = <ConveyorSweet>[];
    for (final ConveyorSweet sweet in _active) {
      final double previous = sweet.progress;
      final bool surge =
          scenario.surgeEvery > 0 &&
          (sweet.orderIndex + 1) % scenario.surgeEvery == 0;
      sweet.progress = math.min(
        1.04,
        sweet.progress + delta * scenario.beltSpeed * (surge ? 1.34 : 1),
      );
      final List<double> positions = activeGatePositions;
      for (int gate = 0; gate < positions.length; gate++) {
        final int bit = 1 << gate;
        if ((sweet._passedGates & bit) == 0 &&
            previous < positions[gate] &&
            sweet.progress >= positions[gate]) {
          sweet.lane = (sweet.lane + _diverters[gate]).clamp(0, 2).toInt();
          sweet._passedGates |= bit;
          gatesPassed++;
        }
      }
      if (sweet.progress >= 1) {
        completed.add(sweet);
        if (sweet.lane == sweet.targetLane) {
          _delivered++;
          delivered++;
        } else {
          _missed++;
          rejected++;
        }
      }
    }
    _active.removeWhere(completed.contains);
    return ConveyorStepResult(
      spawned: spawned,
      gatesPassed: gatesPassed,
      delivered: delivered,
      rejected: rejected,
      overflowed: overflowed,
    );
  }
}
