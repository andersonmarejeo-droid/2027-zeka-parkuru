import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'cafe_shift_engine.dart';
import 'cafe_shift_scenario.dart';

class CafeShiftGamePage extends StatelessWidget {
  const CafeShiftGamePage({super.key});

  static const int totalCases = CafeShiftScenario.campaignLevels;
  static const int totalStars = totalCases * 3;
  static final List<ParkurLevelSpec>
  _levels = List<ParkurLevelSpec>.generate(totalCases, (int index) {
    final int level = index + 1;
    return ParkurLevelSpec(
      number: level,
      titleTr: 'Vardiya ${level.toString().padLeft(2, '0')}',
      titleEn: 'Shift ${level.toString().padLeft(2, '0')}',
      subtitleTr: switch (level) {
        <= 3 => 'Fişi oku, doğru istasyonda hazırla, doğru müşteriye ver.',
        <= 6 => 'Öğütücü, kahve makinesi ve su ısıtıcısını sırala.',
        7 || 8 => 'İleri: iki fişi sırada tutup istasyonları paralel çalıştır.',
        9 || 10 => 'Uzman: özel istekleri ve müşteri sabrını birlikte yönet.',
        <= 16 => 'Usta: üç müşterinin tarifini aynı anda planla.',
        _ => 'Final servisi: çift işlem, sınırlı stok ve dar sabır penceresi.',
      },
      subtitleEn: switch (level) {
        <= 3 => 'Read the ticket, prepare at the right station and serve the right guest.',
        <= 6 => 'Sequence the grinder, espresso machine and kettle.',
        7 ||
        8 => 'Advanced: keep two tickets moving through parallel stations.',
        9 || 10 => 'Expert: balance special requests with guest patience.',
        <= 16 => 'Master: route three guests through concurrent recipes.',
        _ => 'Final service: repeat steps, limited stock and tight patience.',
      },
      difficulty: switch (level) {
        <= 3 => 'AÇILIŞ',
        <= 6 => 'MENÜ',
        7 || 8 => 'İLERİ',
        9 || 10 => 'UZMAN',
        <= 16 => 'USTA',
        _ => 'FİNAL',
      },
      icon: Icons.local_cafe_rounded,
    );
  }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'cafe_shift',
      progressPrefix: 'cafe_shift',
      titleTr: 'Kafe Vardiyası',
      titleEn: 'Cafe Shift',
      taglineTr: 'Fişi oku • İstasyonu yönet • Servis et',
      taglineEn: 'Read • Route • Serve',
      accent: skin.accent,
      icon: Icons.local_cafe_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => CafeShiftPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class CafeShiftPlayPage extends StatefulWidget {
  const CafeShiftPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<CafeShiftPlayPage> createState() => _CafeShiftPlayPageState();
}

class _CafeShiftPlayPageState extends State<CafeShiftPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _accent = Color(0xFF548A80);
  static const Color _ink = Color(0xFF3E4B49);
  static const Color _amber = Color(0xFFBF8C4D);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late CafeShiftScenario _scenario;
  late CafeShiftEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  int? _selectedOrderId;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  int get _score =>
      (_engine.servedCount * 125 +
              _engine.totalTips * 5 +
              math.max(0, 600 - _engine.elapsed.round() * 4) -
              _engine.missedCount * 180)
          .clamp(0, 10000000)
          .toInt();
  int get _stars =>
      _engine.missedCount == 0 && _engine.servedCount == _scenario.orders.length
      ? 3
      : _engine.servedCount >= _engine.completedOrdersNeeded
      ? 2
      : 1;

  CafeOrderProgress? get _selectedOrder =>
      _selectedOrderId == null ? null : _engine.order(_selectedOrderId!);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareShift());
  }

  Future<void> _prepareShift() async {
    CafeShiftScenario scenario = CafeShiftScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'cafe_shift_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('cafe_shift_practice_index') ?? 0;
        if (index < CafeShiftScenario.practiceShifts) {
          final int next = index + 1;
          await preferences.setInt('cafe_shift_practice_index', next);
          scenario = CafeShiftScenario.forPracticeShift(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // The authored shift stays available if local preferences are unavailable.
    }
    if (!mounted) return;
    _scenario = scenario;
    _resetShift();
    setState(() => _ready = true);
    _ticker.start();
  }

  void _resetShift() {
    _engine = CafeShiftEngine(scenario: _scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _selectedOrderId = _engine.orders.firstOrNull?.spec.id;
    _paused = false;
    _finished = false;
    _feedback = _english
        ? 'Select a ticket, send it to its next station, then serve that guest.'
        : 'Fişi seç, sıradaki doğru istasyonda hazırla, sonra o müşteriye ver.';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_ready && !_paused && !_finished) _setPaused(true);
    } else if (state == AppLifecycleState.resumed && _paused && !_finished) {
      _setPaused(false);
    }
  }

  void _setPaused(bool value) {
    if (!_ready || _finished || _paused == value) return;
    setState(() {
      _paused = value;
      _feedback = value
          ? (_english
                ? 'SHIFT PAUSED · ORDERS AND TIMERS ARE HELD'
                : 'VARDİYA DURAKLATILDI · SİPARİŞLER BEKLEMEDE')
          : (_english
                ? 'BACK ON BAR · CHECK THE OLDEST TICKET'
                : 'TEZGAHA DÖNDÜN · EN ESKİ FİŞİ KONTROL ET');
    });
    if (value) {
      _ticker.stop();
      _session.pause();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .2));
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final CafeShiftStepResult result = _engine.step(
      raw.clamp(0, .05).toDouble(),
    );
    if (result.completedStages > 0) {
      _session.recordAccepted(points: result.completedStages * 4);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .11));
    }
    if (result.missed > 0) {
      _session.recordMistake();
      _feedback = _english
          ? 'GUEST LEFT · SERVE THE EARLIEST TICKET FIRST'
          : 'MÜŞTERİ AYRILDI · EN ESKİ FİŞİ ÖNCE SERVİS ET';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .21));
    }
    if (_selectedOrderId == null || _engine.order(_selectedOrderId!) == null) {
      _selectedOrderId = _engine.orders.firstOrNull?.spec.id;
    }
    setState(() {});
    if (result.completed) {
      _ticker.stop();
      unawaited(_finishShift());
    } else if (result.failed) {
      unawaited(_offerRetry());
    }
  }

  void _selectOrder(int id) {
    if (_paused || _finished || _engine.order(id) == null) return;
    setState(() {
      _selectedOrderId = id;
      final CafeOrderProgress ticket = _engine.order(id)!;
      _feedback = ticket.readyToServe
          ? (_english
                ? 'TICKET READY · SERVE THIS GUEST'
                : 'FİŞ HAZIR · BU MÜŞTERİYE SERVİS ET')
          : (_english
                ? 'NEXT · ${_stationName(ticket.nextStation!, true).toUpperCase()}'
                : 'SIRADA · ${context.l10n.uppercaseLabel(_stationName(ticket.nextStation!, false))}');
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .14));
  }

  void _startStation(CafeStation station) {
    final CafeOrderProgress? ticket = _selectedOrder;
    if (ticket == null) return;
    final CafeActionResult result = _engine.startStage(ticket.spec.id, station);
    if (!result.accepted) {
      final bool wrongStation = ticket.nextStation != station;
      setState(
        () => _feedback = wrongStation
            ? (_english
                  ? 'THIS TICKET NEEDS ${_stationName(ticket.nextStation!, true).toUpperCase()}'
                  : 'BU FİŞTE SIRADAKİ İSTASYON: ${context.l10n.uppercaseLabel(_stationName(ticket.nextStation!, false))}')
            : (_english
                  ? 'STATION BUSY OR INGREDIENT STOCK LOW'
                  : 'İSTASYON MEŞGUL VEYA MALZEME STOKU DÜŞÜK'),
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .15));
      return;
    }
    _session.recordAccepted(points: 5);
    setState(
      () => _feedback = _english
          ? '${_stationName(station, true).toUpperCase()} RUNNING · SWITCH TICKETS TO KEEP THE BAR MOVING'
          : '${context.l10n.uppercaseLabel(_stationName(station, false))} ÇALIŞIYOR · PARALEL HAZIRLIK İÇİN DİĞER FİŞİ SEÇ',
    );
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .18),
    );
    _audio.hapticLight();
  }

  void _serve() {
    final CafeOrderProgress? ticket = _selectedOrder;
    if (ticket == null) return;
    final CafeActionResult result = _engine.serve(ticket.spec.id);
    if (!result.served) {
      setState(
        () => _feedback = _english
            ? 'FINISH EVERY RECIPE STEP BEFORE SERVING'
            : 'SERVİS ETMEDEN ÖNCE TARİFTEKİ TÜM ADIMLARI BİTİR',
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .16));
      return;
    }
    _session.recordAccepted(points: result.points);
    _selectedOrderId = _engine.orders.firstOrNull?.spec.id;
    setState(
      () => _feedback = _english
          ? 'ORDER OUT · +${result.points} · READ THE NEXT TICKET'
          : 'SİPARİŞ TESLİM · +${result.points} · SIRADAKİ FİŞİ OKU',
    );
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .25));
    _audio.hapticLight();
    if (_engine.completed) {
      _ticker.stop();
      unawaited(_finishShift());
    }
  }

  Future<void> _offerRetry() async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    _session.fail();
    final bool retry =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(_english ? 'SHIFT LOST' : 'VARDİYA KAÇTI'),
            content: Text(
              _english
                  ? 'Read the ticket route before assigning a station. Keep multiple orders moving and serve before patience runs out.'
                  : 'İstasyona başlamadan fişin tarif sırasını oku. Birden fazla siparişi paralel hazırla ve sabır tükenmeden servis et.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_english ? 'MAP' : 'HARİTA'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(_english ? 'RETRY' : 'YENİDEN DENE'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted) return;
    if (retry) {
      setState(() {
        _resetShift();
        _ticker.start();
      });
    } else {
      Navigator.of(context)
          .pop(StudioGameResult.failed(score: _score).toParkurResult());
    }
  }

  Future<void> _finishShift() async {
    if (_finished || !mounted) return;
    _finished = true;
    _session.complete(
      stars: _stars,
      action: widget.level.number < CafeShiftGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'VARDİYA BAŞARIYLA KAPANDI',
      titleEn: 'SHIFT COMPLETE',
      detailTr:
          '${_engine.servedCount} sipariş · ${_engine.missedCount} kaçan · ${_engine.totalTips} bahşiş',
      detailEn:
          '${_engine.servedCount} orders · ${_engine.missedCount} lost · ${_engine.totalTips} tips',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < CafeShiftGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: _score,
        stars: _stars,
        action: action,
      ).toParkurResult(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(title: Text(_english ? 'CAFE SHIFT' : 'KAFE VARDİYASI')),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final bool disabled = _paused || _finished;
    final CafeOrderProgress? selected = _selectedOrder;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          _english
              ? 'CAFE · SHIFT ${widget.level.number}'
              : 'KAFE · VARDİYA ${widget.level.number}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('cafe_shift_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: () => _setPaused(!_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Column(
            children: <Widget>[
              _buildHud(),
              const SizedBox(height: 7),
              _buildTickets(disabled),
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                child: Text(
                  _feedback,
                  key: const ValueKey<String>('cafe_shift_feedback'),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.78,
                    child: RepaintBoundary(
                      key: const ValueKey<String>('cafe_shift_scene'),
                      child: CustomPaint(
                        painter: _CafePainter(
                          engine: _engine,
                          selected: selected,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildStationGrid(disabled, selected),
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  key: const ValueKey<String>('cafe_shift_serve'),
                  onPressed:
                      disabled || selected == null || !selected.readyToServe
                      ? null
                      : _serve,
                  icon: const Icon(Icons.room_service_rounded),
                  label: Text(
                    _english ? 'SERVE ORDER' : 'SİPARİŞİ VER',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: .3,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud() => Container(
    key: const ValueKey<String>('cafe_shift_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE8E5DC)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: _ink.withValues(alpha: .05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.receipt_long_rounded, size: 17, color: _amber),
        const SizedBox(width: 6),
        Text(
          '${_engine.servedCount}/${_scenario.orders.length}',
          style: const TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _english ? 'SERVED' : 'SERVİS',
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
          ),
        ),
        const Spacer(),
        const Icon(Icons.inventory_2_outlined, size: 15, color: _accent),
        const SizedBox(width: 4),
        Text(
          '${_engine.stock}',
          style: const TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          _english ? 'STOCK' : 'STOK',
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.payments_outlined, size: 15, color: _amber),
        const SizedBox(width: 4),
        Text(
          '${_engine.totalTips} ₺',
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Widget _buildTickets(bool disabled) {
    final List<CafeOrderProgress> tickets = _engine.orders;
    return SizedBox(
      height: 64,
      child: Row(
        children: <Widget>[
          for (int index = 0; index < 3; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: 6),
            Expanded(
              child: index >= tickets.length
                  ? const SizedBox.shrink()
                  : _CafeTicket(
                      ticket: tickets[index],
                      selected: tickets[index].spec.id == _selectedOrderId,
                      english: _english,
                      enabled: !disabled,
                      onTap: () => _selectOrder(tickets[index].spec.id),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStationGrid(bool disabled, CafeOrderProgress? selected) {
    return Column(
      children: <Widget>[
        for (int row = 0; row < 2; row++) ...<Widget>[
          if (row > 0) const SizedBox(height: 5),
          Row(
            children: <Widget>[
              for (int column = 0; column < 3; column++) ...<Widget>[
                if (column > 0) const SizedBox(width: 6),
                Expanded(
                  child: _stationButton(
                    CafeStation.values[row * 3 + column],
                    disabled,
                    selected,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _stationButton(
    CafeStation station,
    bool disabled,
    CafeOrderProgress? selected,
  ) {
    final CafeStationState state = _engine.station(station);
    final bool next = selected?.nextStation == station;
    final String label = _stationName(station, _english);
    final String sub = state.busy
        ? '${state.remaining.toStringAsFixed(1)}s'
        : next
        ? (_english ? 'NEXT STEP' : 'SIRADAKİ ADIM')
        : (_english ? 'READY' : 'HAZIR');
    return SizedBox(
      height: 48,
      child: FilledButton.tonal(
        key: ValueKey<String>('cafe_station_${station.name}'),
        onPressed:
            disabled || state.busy || selected == null || selected.readyToServe
            ? null
            : () => _startStation(station),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          backgroundColor: next ? const Color(0xFFE4EFE9) : Colors.white,
          foregroundColor: _ink,
          disabledBackgroundColor: state.busy
              ? const Color(0xFFE9E6DD)
              : const Color(0xFFF0F0EB),
          disabledForegroundColor: state.busy
              ? _amber
              : const Color(0xFF9A9B95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(
              color: next ? const Color(0xFFABC8B9) : const Color(0xFFE4E5DF),
            ),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(_stationIcon(station), size: 16),
              const SizedBox(width: 4),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: state.busy ? _amber : _accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CafeTicket extends StatelessWidget {
  const _CafeTicket({
    required this.ticket,
    required this.selected,
    required this.english,
    required this.enabled,
    required this.onTap,
  });

  final CafeOrderProgress ticket;
  final bool selected;
  final bool english;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String product = _productName(ticket.spec.product, english);
    final String modifier = _modifierName(ticket.spec.modifier, english);
    return Material(
      color: selected ? const Color(0xFFEAF2EC) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 5, 7, 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? const Color(0xFF88B6A2)
                  : const Color(0xFFE5E5DD),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    _productIcon(ticket.spec.product),
                    size: 13,
                    color: const Color(0xFF9A7548),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${ticket.spec.id + 1} · $product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF42514C),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                modifier.isEmpty
                    ? _nextStep(ticket, english)
                    : '$modifier · ${_nextStep(ticket, english)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ticket.patienceFraction,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFE9E8E1),
                  color: ticket.patienceFraction < .28
                      ? const Color(0xFFC96F5B)
                      : const Color(0xFF82A996),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _stationName(CafeStation station, bool english) => switch (station) {
  CafeStation.grinder => english ? 'GRINDER' : 'ÖĞÜTÜCÜ',
  CafeStation.espresso => english ? 'BREWER' : 'KAHVE',
  CafeStation.kettle => english ? 'KETTLE' : 'SU ISIT',
  CafeStation.grill => english ? 'GRILL' : 'IZGARA',
  CafeStation.milk => english ? 'MILK BAR' : 'SÜT BAR',
  CafeStation.finishing => english ? 'FINISH' : 'SON DOKUNUŞ',
};

String _productName(CafeProduct product, bool english) => switch (product) {
  CafeProduct.espresso => english ? 'ESPRESSO' : 'ESPRESSO',
  CafeProduct.latte => english ? 'LATTE' : 'LATTE',
  CafeProduct.tea => english ? 'TEA' : 'ÇAY',
  CafeProduct.toastie => english ? 'TOASTIE' : 'TOST',
  CafeProduct.cocoa => english ? 'COCOA' : 'KAKAO',
};

String _modifierName(CafeModifier modifier, bool english) => switch (modifier) {
  CafeModifier.none => '',
  CafeModifier.oatMilk => english ? 'OAT' : 'YULAF SÜTÜ',
  CafeModifier.doubleShot => english ? 'DOUBLE' : 'ÇİFT SHOT',
  CafeModifier.extraToast => english ? 'EXTRA TOAST' : 'EKSTRA KIZARMIŞ',
  CafeModifier.sugarFree => english ? 'NO SUGAR' : 'ŞEKERSİZ',
};

String _nextStep(CafeOrderProgress ticket, bool english) => ticket.readyToServe
    ? (english ? 'READY TO SERVE' : 'SERVİSE HAZIR')
    : _stationName(ticket.nextStation!, english);

IconData _stationIcon(CafeStation station) => switch (station) {
  CafeStation.grinder => Icons.grain_rounded,
  CafeStation.espresso => Icons.coffee_maker_rounded,
  CafeStation.kettle => Icons.local_fire_department_outlined,
  CafeStation.grill => Icons.outdoor_grill_rounded,
  CafeStation.milk => Icons.opacity_rounded,
  CafeStation.finishing => Icons.room_service_outlined,
};

IconData _productIcon(CafeProduct product) => switch (product) {
  CafeProduct.espresso ||
  CafeProduct.latte ||
  CafeProduct.cocoa => Icons.local_cafe_rounded,
  CafeProduct.tea => Icons.emoji_food_beverage_rounded,
  CafeProduct.toastie => Icons.breakfast_dining_rounded,
};

class _CafePainter extends CustomPainter {
  const _CafePainter({required this.engine, required this.selected});

  final CafeShiftEngine engine;
  final CafeOrderProgress? selected;
  static const Color _wood = Color(0xFF76563D);
  static const Color _sage = Color(0xFF7C9B88);
  static const Color _ink = Color(0xFF4B4841);
  static const Color _amber = Color(0xFFBF8C4D);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect clip = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(20),
    );
    canvas.drawRRect(clip, Paint()..color = const Color(0xFFE5DDCE));
    canvas.save();
    canvas.clipRRect(clip);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFFAF5E8),
            Color(0xFFF1E8D8),
            Color(0xFFE8DDCB),
          ],
        ).createShader(bounds),
    );
    _drawWindow(canvas, size);
    _drawTiles(canvas, size);
    _drawShelf(canvas, size);
    _drawGuests(canvas, size);
    _drawCounter(canvas, size);
    _drawStations(canvas, size);
    _drawSteam(canvas, size);
    canvas.restore();
  }

  void _drawWindow(Canvas canvas, Size size) {
    final Rect frame = Rect.fromLTWH(
      size.width * .035,
      size.height * .06,
      size.width * .28,
      size.height * .43,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frame.shift(const Offset(1, 3)),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0x223E3931),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(8)),
      Paint()..color = const Color(0xFFC7D7CD),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame.deflate(3), const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFCDE4D8),
            Color(0xFF9DBEAE),
            Color(0xFFDDE6D3),
          ],
        ).createShader(frame),
    );
    canvas.drawLine(
      Offset(frame.center.dx, frame.top + 3),
      Offset(frame.center.dx, frame.bottom - 3),
      Paint()
        ..color = const Color(0xFFD3D6C9)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(frame.left + 3, frame.center.dy),
      Offset(frame.right - 3, frame.center.dy),
      Paint()
        ..color = const Color(0xFFD3D6C9)
        ..strokeWidth = 2,
    );
    final Path ray = Path()
      ..moveTo(frame.right - 5, frame.bottom - 2)
      ..lineTo(size.width * .56, size.height * .70)
      ..lineTo(size.width * .13, size.height * .70)
      ..close();
    canvas.drawPath(
      ray,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[const Color(0x33FFF0C8), const Color(0x00FFF0C8)],
        ).createShader(frame),
    );
  }

  void _drawTiles(Canvas canvas, Size size) {
    final double startX = size.width * .36;
    final double endX = size.width * .97;
    final double top = size.height * .10;
    final double bottom = size.height * .48;
    for (int row = 0; row < 3; row++) {
      for (int column = 0; column < 7; column++) {
        final Rect tile = Rect.fromLTWH(
          startX + column * size.width * .085,
          top + row * size.height * .115,
          size.width * .078,
          size.height * .103,
        ).deflate(1.2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(tile, const Radius.circular(3)),
          Paint()
            ..color = (row + column).isEven
                ? const Color(0xFFE4D8C5)
                : const Color(0xFFDCD0BE),
        );
        canvas.drawLine(
          tile.topLeft + const Offset(2, 2),
          tile.topRight + const Offset(-2, 2),
          Paint()
            ..color = Colors.white.withValues(alpha: .30)
            ..strokeWidth = 1,
        );
      }
    }
    canvas.drawLine(
      Offset(startX, bottom),
      Offset(endX, bottom),
      Paint()
        ..color = const Color(0x1F604F3D)
        ..strokeWidth = 1.2,
    );
  }

  void _drawShelf(Canvas canvas, Size size) {
    final Rect shelf = Rect.fromLTWH(
      size.width * .43,
      size.height * .09,
      size.width * .52,
      size.height * .07,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        shelf.shift(const Offset(0, 2)),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF9A7655),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shelf, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFB58C61), Color(0xFF8B6547)],
        ).createShader(shelf),
    );
    for (int i = 0; i < 5; i++) {
      final Rect jar = Rect.fromLTWH(
        shelf.left + 7 + i * (shelf.width - 20) / 5,
        shelf.top - size.height * .08,
        shelf.width * .065,
        size.height * .075,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(jar, const Radius.circular(5)),
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: .66),
              const Color(0xFFB7A68D),
            ],
          ).createShader(jar),
      );
      canvas.drawRect(
        Rect.fromLTWH(jar.left, jar.top, jar.width, 3),
        Paint()..color = _sage.withValues(alpha: .85),
      );
    }
  }

  void _drawGuests(Canvas canvas, Size size) {
    final int count = math.min(3, engine.orders.length);
    for (int index = 0; index < count; index++) {
      final double cx = size.width * (.43 + index * .205);
      final double cy = size.height * .39;
      final Color coat = <Color>[
        const Color(0xFF657E72),
        const Color(0xFFB2765E),
        const Color(0xFF637689),
      ][index];
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + size.height * .10),
          width: size.width * .115,
          height: size.height * .10,
        ),
        Paint()..color = const Color(0x252E322E),
      );
      final Rect body = Rect.fromCenter(
        center: Offset(cx, cy + size.height * .08),
        width: size.width * .10,
        height: size.height * .18,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(8)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[coat, Color.lerp(coat, _ink, .35)!],
          ).createShader(body),
      );
      canvas.drawCircle(
        Offset(cx, cy - size.height * .045),
        size.width * .027,
        Paint()..color = const Color(0xFFE2C4A4),
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, cy - size.height * .055),
          width: size.width * .065,
          height: size.height * .055,
        ),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFF554840)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * .008,
      );
      final double patience = engine.orders[index].patienceFraction;
      final Rect bar = Rect.fromLTWH(
        cx - size.width * .035,
        cy - size.height * .125,
        size.width * .07,
        3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: .78),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bar.left, bar.top, bar.width * patience, bar.height),
          const Radius.circular(2),
        ),
        Paint()..color = patience < .3 ? const Color(0xFFC96E59) : _sage,
      );
    }
  }

  void _drawCounter(Canvas canvas, Size size) {
    final Rect counter = Rect.fromLTWH(
      0,
      size.height * .60,
      size.width,
      size.height * .40,
    );
    canvas.drawRect(
      counter,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF8F6B4B), _wood, Color(0xFF604634)],
        ).createShader(counter),
    );
    for (int index = 0; index < 8; index++) {
      final double y = counter.top + size.height * (.055 + index * .04);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - size.height * .015),
        Paint()
          ..color = Colors.white.withValues(alpha: .045)
          ..strokeWidth = 1,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, counter.top, size.width, size.height * .025),
      Paint()..color = const Color(0xFFD5B17A),
    );
    canvas.drawLine(
      Offset(0, counter.top + size.height * .028),
      Offset(size.width, counter.top + size.height * .028),
      Paint()
        ..color = const Color(0xFF573E2F)
        ..strokeWidth = 1.2,
    );
  }

  void _drawStations(Canvas canvas, Size size) {
    final List<CafeStationState> stationStates = engine.stations;
    for (int index = 0; index < stationStates.length; index++) {
      final CafeStationState state = stationStates[index];
      final double cx = size.width * (.085 + index * .166);
      final double baseline = size.height * .78;
      final bool activeForOrder = selected?.nextStation == state.station;
      final Rect shadow = Rect.fromCenter(
        center: Offset(cx, baseline + size.height * .085),
        width: size.width * .135,
        height: size.height * .08,
      );
      canvas.drawOval(shadow, Paint()..color = const Color(0x33443326));
      final Rect machine = _stationRect(state.station, cx, baseline, size);
      final Color metal = state.busy
          ? const Color(0xFFE9C98D)
          : const Color(0xFFBAC5BE);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          machine.shift(Offset(0, size.height * .012)),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0x3341362E),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(machine, const Radius.circular(5)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Colors.white, metal, const Color(0xFF667B78)],
          ).createShader(machine),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(machine, const Radius.circular(5)),
        Paint()
          ..color = activeForOrder
              ? _sage.withValues(alpha: .8)
              : Colors.white.withValues(alpha: .50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = activeForOrder ? 1.6 : .8,
      );
      _drawMachineDetail(canvas, state.station, machine, size);
      if (state.busy) {
        final Rect progress = Rect.fromLTWH(
          machine.left,
          machine.bottom + size.height * .014,
          machine.width,
          3,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(progress, const Radius.circular(2)),
          Paint()..color = Colors.white.withValues(alpha: .72),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              progress.left,
              progress.top,
              progress.width * state.progress,
              progress.height,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = _amber,
        );
      }
    }
  }

  Rect _stationRect(
    CafeStation station,
    double cx,
    double baseline,
    Size size,
  ) {
    final double unit = size.shortestSide;
    final double width = unit * (station == CafeStation.espresso ? .115 : .105);
    final double height =
        unit *
        switch (station) {
          CafeStation.grinder => .19,
          CafeStation.espresso => .23,
          CafeStation.kettle => .16,
          CafeStation.grill => .15,
          CafeStation.milk => .19,
          CafeStation.finishing => .13,
        };
    return Rect.fromLTWH(cx - width / 2, baseline - height, width, height);
  }

  void _drawMachineDetail(
    Canvas canvas,
    CafeStation station,
    Rect machine,
    Size size,
  ) {
    final Paint dark = Paint()..color = const Color(0xFF526461);
    final Paint gold = Paint()..color = const Color(0xFFB98951);
    switch (station) {
      case CafeStation.grinder:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              machine.left + machine.width * .24,
              machine.top - machine.height * .22,
              machine.width * .52,
              machine.height * .25,
            ),
            const Radius.circular(5),
          ),
          Paint()..color = const Color(0xFFE4D3B6),
        );
        canvas.drawRect(
          Rect.fromLTWH(
            machine.left + machine.width * .18,
            machine.bottom - machine.height * .30,
            machine.width * .64,
            machine.height * .14,
          ),
          dark,
        );
        break;
      case CafeStation.espresso:
        canvas.drawRect(
          Rect.fromLTWH(
            machine.left + machine.width * .14,
            machine.top + machine.height * .19,
            machine.width * .72,
            machine.height * .16,
          ),
          dark,
        );
        canvas.drawLine(
          Offset(machine.center.dx, machine.top + machine.height * .48),
          Offset(machine.center.dx, machine.bottom - machine.height * .06),
          Paint()
            ..color = const Color(0xFF566B68)
            ..strokeWidth = 2,
        );
        canvas.drawCircle(
          Offset(
            machine.left + machine.width * .72,
            machine.top + machine.height * .13,
          ),
          2.5,
          gold,
        );
        break;
      case CafeStation.kettle:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              machine.left + machine.width * .17,
              machine.top + machine.height * .19,
              machine.width * .66,
              machine.height * .68,
            ),
            Radius.circular(machine.width * .2),
          ),
          Paint()..color = const Color(0xFFE5D9C6),
        );
        canvas.drawArc(
          Rect.fromLTWH(
            machine.left + machine.width * .65,
            machine.top + machine.height * .3,
            machine.width * .31,
            machine.height * .4,
          ),
          -math.pi / 2,
          math.pi,
          false,
          Paint()
            ..color = dark.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        break;
      case CafeStation.grill:
        for (int line = 0; line < 3; line++) {
          final double y = machine.top + machine.height * (.25 + line * .22);
          canvas.drawLine(
            Offset(machine.left + 3, y),
            Offset(machine.right - 3, y),
            Paint()
              ..color = dark.color
              ..strokeWidth = 1.3,
          );
        }
        break;
      case CafeStation.milk:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              machine.left + machine.width * .18,
              machine.top + machine.height * .18,
              machine.width * .64,
              machine.height * .70,
            ),
            const Radius.circular(4),
          ),
          Paint()..color = const Color(0xFFF3F0E7),
        );
        canvas.drawRect(
          Rect.fromLTWH(
            machine.left + machine.width * .25,
            machine.top + machine.height * .28,
            machine.width * .50,
            machine.height * .15,
          ),
          Paint()..color = _sage,
        );
        break;
      case CafeStation.finishing:
        canvas.drawOval(
          Rect.fromCenter(
            center: machine.center,
            width: machine.width * .68,
            height: machine.height * .46,
          ),
          Paint()..color = const Color(0xFFF4E7CE),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: machine.center,
            width: machine.width * .39,
            height: machine.height * .25,
          ),
          Paint()..color = const Color(0xFFBE8B56),
        );
        break;
    }
    canvas.drawLine(
      Offset(machine.left + 2, machine.top + 2),
      Offset(machine.right - 2, machine.top + 2),
      Paint()
        ..color = Colors.white.withValues(alpha: .6)
        ..strokeWidth = 1,
    );
  }

  void _drawSteam(Canvas canvas, Size size) {
    for (final CafeStationState state in engine.stations) {
      if (!state.busy ||
          state.station != CafeStation.espresso &&
              state.station != CafeStation.kettle) {
        continue;
      }
      final int index = CafeStation.values.indexOf(state.station);
      final double x = size.width * (.085 + index * .166);
      final double y = size.height * .50;
      for (int curl = 0; curl < 3; curl++) {
        final Path path = Path()
          ..moveTo(x + curl * 3, y)
          ..cubicTo(
            x - 3 + curl * 3,
            y - 7,
            x + 5 + curl * 3,
            y - 10,
            x + 2 + curl * 3,
            y - 16,
          );
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: .58)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CafePainter oldDelegate) =>
      oldDelegate.engine != engine ||
      oldDelegate.engine.elapsed != engine.elapsed ||
      oldDelegate.selected != selected;
}
