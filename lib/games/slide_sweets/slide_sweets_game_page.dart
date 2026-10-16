import '../shared/studio_game_contracts.dart';

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
import 'slide_sweets_engine.dart';
import 'slide_sweets_scenario.dart';

class SlideSweetsGamePage extends StatelessWidget {
  const SlideSweetsGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = GameContentPolicy.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    GameContentPolicy.nativeStages('slide_sweets'),
    (int index) {
      final int level = index + 1;
      final String tr = switch (level) {
        <= 3 => 'Kavşak yönünü seç; üç şeker rengini istasyonlarına ulaştır.',
        <= 6 => 'İki kavşağın yönünü ayrı seç; sıradaki siparişleri oku.',
        7 || 8 => 'İleri: hız bandı ve dar tamponla eşzamanlı akışı yönet.',
        9 => 'Uzman: sık dalgada iki kavşağı da doğru fazda değiştir.',
        _ => 'Usta finali: 17 siparişi taşma olmadan, seri akışta tamamla.',
      };
      final String en = switch (level) {
        <= 3 => 'Choose a gate direction and send the three candy colours to their stations.',
        <= 6 => 'Set both gate directions independently and read the upcoming orders.',
        7 || 8 => 'Advanced: manage a surge belt and a narrow buffer under concurrency.',
        9 =>
          'Expert: phase both diverters through a tightly spaced order wave.',
        _ => 'Master finale: route 17 orders through both gates without a jam.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Üretim Hattı ${level.toString().padLeft(2, '0')}',
        titleEn: 'Confectionery Line ${level.toString().padLeft(2, '0')}',
        subtitleTr: tr,
        subtitleEn: en,
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.factory_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('slide_sweets');
    return ParkurLevelHub(
      gameId: 'slide_sweets',
      progressPrefix: 'slide_sweets',
      titleTr: 'Şeker Konveyörü',
      titleEn: 'Sweet Conveyor',
      taglineTr: 'Her kavşağı ayrı ayarla • Akışı oku • Siparişleri yetiştir',
      taglineEn: 'Set each gate • Read the flow • Fill each order',
      accent: skin.accent,
      icon: Icons.factory_rounded,
      levels: _levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => SlideSweetsPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class SlideSweetsPlayPage extends StatefulWidget {
  const SlideSweetsPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<SlideSweetsPlayPage> createState() => _SlideSweetsPlayPageState();
}

class _SlideSweetsPlayPageState extends State<SlideSweetsPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = StudioVisuals.ink;
  static const Color _accent = Color(0xFF7357D8);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late SlideSweetsScenario _scenario;
  late SlideSweetsEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  double _elapsed = 0;
  int _score = 0;
  int _combo = 0;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;

  int get _stars {
    if (_engine.missedCount == 0 && _elapsed <= _scenario.goldTimeSeconds) {
      return 3;
    }
    if (_engine.missedCount <= 1) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareScenario());
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

  Future<void> _prepareScenario() async {
    SlideSweetsScenario scenario = (widget.level.poolIndex != null
        ? SlideSweetsScenario.forPracticeRound(widget.level.contentIndex)
        : SlideSweetsScenario.forLevel(widget.level.contentLevel));
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'slide_sweets_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (widget.level.poolIndex == null && visits > 0) {
        final int index =
            await preferences.getInt('slide_sweets_practice_index') ?? 0;
        if (index < SlideSweetsScenario.maximumPracticeRounds) {
          final int next = index + 1;
          await preferences.setInt('slide_sweets_practice_index', next);
          scenario = SlideSweetsScenario.forPracticeRound(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = (widget.level.poolIndex != null
          ? SlideSweetsScenario.forPracticeRound(widget.level.contentIndex)
          : SlideSweetsScenario.forLevel(widget.level.contentLevel));
    }
    if (!mounted) return;
    _scenario = scenario;
    _startRound();
    setState(() => _ready = true);
  }

  void _startRound() {
    _ticker.stop();
    _engine = SlideSweetsEngine(scenario: _scenario);
    _elapsed = 0;
    _score = 0;
    _combo = 0;
    _paused = false;
    _finished = false;
    _lastTick = Duration.zero;
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _ticker.start();
  }

  void _setPaused(bool paused) {
    if (!_ready || _finished || _paused == paused) return;
    setState(() => _paused = paused);
    if (paused) {
      _session.pause();
      _ticker.stop();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .24));
  }

  void _setGateDirection(int gate, int offset) {
    if (_paused || _finished) return;
    if (_engine.diverterOffsets[gate] == offset) return;
    _engine.setDiverter(gate, offset);
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .16),
    );
    setState(() {});
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final double delta = raw.clamp(0, .05).toDouble();
    _elapsed += delta;
    final ConveyorStepResult result = _engine.step(delta);
    for (int index = 0; index < result.delivered; index++) {
      _combo++;
      final int points = 100 + math.min(90, (_combo - 1) * 15);
      _score += points;
      _session.recordAccepted(points: points);
    }
    if (result.rejected > 0 || result.overflowed > 0) {
      _combo = 0;
      for (
        int index = 0;
        index < result.rejected + result.overflowed;
        index++
      ) {
        _session.recordMistake();
      }
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .25));
    } else if (result.delivered > 0) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .26));
    }

    if (_engine.missedCount > _scenario.missLimit) {
      unawaited(_finish(completed: false));
    } else if (_engine.isComplete) {
      unawaited(
        _finish(
          completed:
              _engine.deliveredCount >=
              _scenario.orderCount - _scenario.missLimit,
        ),
      );
    }
    if (mounted && !_finished) setState(() {});
  }

  Future<void> _finish({required bool completed}) async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    if (!completed) {
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(_english ? 'Line overloaded' : 'Hat tıkandı'),
              content: Text(
                _english
                    ? 'Too many packs missed their station. Re-read the order ribbon and try the line again?'
                    : 'Fazla paket yanlış istasyona gitti. Sipariş şeridini yeniden okuyup hattı tekrar deneyelim mi?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Level map' : 'Bölüm listesi'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(_english ? 'Retry' : 'Tekrar dene'),
                ),
              ],
            ),
          ) ??
          false;
      if (!mounted) return;
      if (retry) {
        setState(_startRound);
      } else {
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < SlideSweetsGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 170));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'SİPARİŞ HATTI TAMAMLANDI',
      titleEn: 'ORDER LINE COMPLETE',
      detailTr:
          '${_engine.deliveredCount}/${_scenario.orderCount} paket · ${_engine.missedCount} kaçan · ${_elapsed.toStringAsFixed(1)} sn.',
      detailEn:
          '${_engine.deliveredCount}/${_scenario.orderCount} packs · ${_engine.missedCount} missed · ${_elapsed.toStringAsFixed(1)} s.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < SlideSweetsGamePage.totalCases,
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
        appBar: AppBar(
          title: Text(_english ? 'SWEET CONVEYOR' : 'ŞEKER KONVEYÖRÜ'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english ? 'SWEET CONVEYOR' : 'ŞEKER KONVEYÖRÜ',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('slide_sweets_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: () => _setPaused(!_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 6),
              child: Column(
                children: <Widget>[
                  _SweetsHud(
                    delivered: _engine.deliveredCount,
                    total: _scenario.orderCount,
                    missed: _engine.missedCount,
                    missLimit: _scenario.missLimit,
                    elapsed: _elapsed,
                    english: _english,
                  ),
                  const SizedBox(height: 5),
                  _OrderRibbon(
                    orders: _scenario.orders,
                    nextIndex: _engine.nextOrderIndex,
                    activeCount: _engine.activeSweets.length,
                    bufferLimit: _engine.bufferLimit,
                    english: _english,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 570);
                        final double height = math.min(
                          limits.maxHeight,
                          width * .67,
                        );
                        return Center(
                          child: SizedBox(
                            key: const ValueKey<String>('slide_sweets_scene'),
                            width: width,
                            height: height,
                            child: CustomPaint(
                              painter: _ConveyorPainter(
                                engine: _engine,
                                elapsed: _elapsed,
                                english: _english,
                                paused: _paused,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DiverterControl(
                    gate: 0,
                    offset: _engine.diverterOffsets[0],
                    english: _english,
                    onSelect: (int direction) =>
                        _setGateDirection(0, direction),
                  ),
                  const SizedBox(height: 5),
                  _DiverterControl(
                    gate: 1,
                    offset: _engine.diverterOffsets[1],
                    english: _english,
                    onSelect: (int direction) =>
                        _setGateDirection(1, direction),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _english
                        ? 'Choose UPPER, MIDDLE or LOWER separately at each gate. Match each sweet to its coloured station.'
                        : 'Her kavşakta ÜST, ORTA veya ALT yönünü ayrı seç. Şekeri rengiyle eşleşen istasyona yönlendir.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.muted,
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SweetsHud extends StatelessWidget {
  const _SweetsHud({
    required this.delivered,
    required this.total,
    required this.missed,
    required this.missLimit,
    required this.elapsed,
    required this.english,
  });

  final int delivered;
  final int total;
  final int missed;
  final int missLimit;
  final double elapsed;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('slide_sweets_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: _SweetsMetric(
            label: english ? 'PACKED' : 'PAKETLENDİ',
            value: '$delivered / $total',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF71977C),
          ),
        ),
        Container(width: 1, height: 27, color: StudioVisuals.line),
        Expanded(
          child: _SweetsMetric(
            label: english ? 'MISSED' : 'KAÇAN',
            value: '$missed / $missLimit',
            icon: Icons.warning_amber_rounded,
            color: missed == 0
                ? _SlideSweetsPlayPageState._accent
                : const Color(0xFFC57561),
          ),
        ),
        Container(width: 1, height: 27, color: StudioVisuals.line),
        Expanded(
          child: _SweetsMetric(
            label: english ? 'TIME' : 'SÜRE',
            value: '${elapsed.toStringAsFixed(1)} s',
            icon: Icons.schedule_rounded,
            color: const Color(0xFF7C8B9A),
          ),
        ),
      ],
    ),
  );
}

class _SweetsMetric extends StatelessWidget {
  const _SweetsMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Icon(icon, color: color, size: 15),
      const SizedBox(width: 4),
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: _SlideSweetsPlayPageState._ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _OrderRibbon extends StatelessWidget {
  const _OrderRibbon({
    required this.orders,
    required this.nextIndex,
    required this.activeCount,
    required this.bufferLimit,
    required this.english,
  });

  final List<int> orders;
  final int nextIndex;
  final int activeCount;
  final int bufferLimit;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final int start = nextIndex.clamp(0, orders.length);
    final List<int> visible = orders.skip(start).take(5).toList();
    return Row(
      children: <Widget>[
        Text(
          english ? 'NEXT' : 'SIRADA',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: StudioVisuals.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Row(
            children: <Widget>[
              for (int index = 0; index < visible.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: 5),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _ConveyorPainter.laneColors[visible[index]]
                        .withValues(alpha: .12),
                    border: Border.all(
                      color: _ConveyorPainter.laneColors[visible[index]]
                          .withValues(alpha: .40),
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.circle,
                      size: 11,
                      color: _ConveyorPainter.laneColors[visible[index]],
                    ),
                  ),
                ),
              ],
              if (visible.isEmpty)
                const Icon(
                  Icons.done_all_rounded,
                  color: Color(0xFF71977C),
                  size: 17,
                ),
            ],
          ),
        ),
        const Icon(
          Icons.inventory_2_outlined,
          size: 12,
          color: StudioVisuals.muted,
        ),
        const SizedBox(width: 2),
        Text(
          '$activeCount/$bufferLimit',
          key: const ValueKey<String>('slide_sweets_buffer'),
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: _SlideSweetsPlayPageState._ink,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '${orders.length - start}',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: StudioVisuals.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DiverterControl extends StatelessWidget {
  const _DiverterControl({
    required this.gate,
    required this.offset,
    required this.english,
    required this.onSelect,
  });

  final int gate;
  final int offset;
  final bool english;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final int selectedLane = (1 + offset).clamp(0, 2).toInt();
    final Color selectedColor = _ConveyorPainter.laneColors[selectedLane];
    final String selectedRoute = switch (offset) {
      -1 => english ? 'UPPER BELT' : 'ÜST BANT',
      1 => english ? 'LOWER BELT' : 'ALT BANT',
      _ => english ? 'MIDDLE BELT' : 'ORTA BANT',
    };
    return Container(
      key: ValueKey<String>('slide_sweets_gate_$gate'),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E2EC)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0E342A50),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 7,
                height: 17,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: selectedColor.withValues(alpha: .30),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${english ? 'GATE' : 'KAPI'} ${gate + 1}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _SlideSweetsPlayPageState._ink,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .55,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedRoute,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Color.lerp(
                      selectedColor,
                      _SlideSweetsPlayPageState._ink,
                      .22,
                    ),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: <Widget>[
              for (int direction = -1; direction <= 1; direction++) ...<Widget>[
                if (direction > -1) const SizedBox(width: 6),
                Expanded(
                  child: _SweetsDirectionButton(
                    gate: gate,
                    direction: direction,
                    selected: offset == direction,
                    english: english,
                    onTap: () => onSelect(direction),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SweetsDirectionButton extends StatelessWidget {
  const _SweetsDirectionButton({
    required this.gate,
    required this.direction,
    required this.selected,
    required this.english,
    required this.onTap,
  });

  final int gate;
  final int direction;
  final bool selected;
  final bool english;
  final VoidCallback onTap;

  static const List<Color> _colors = _ConveyorPainter.laneColors;

  @override
  Widget build(BuildContext context) {
    final int lane = (1 + direction).clamp(0, 2).toInt();
    final Color color = _colors[lane];
    final IconData icon = switch (direction) {
      -1 => Icons.north_rounded,
      1 => Icons.south_rounded,
      _ => Icons.east_rounded,
    };
    final String label = switch (direction) {
      -1 => english ? 'UPPER' : 'ÜST',
      1 => english ? 'LOWER' : 'ALT',
      _ => english ? 'MIDDLE' : 'ORTA',
    };
    return Semantics(
      button: true,
      selected: selected,
      label: english
          ? 'Junction ${gate + 1}, $label belt'
          : 'Kavşak ${gate + 1}, $label bant',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>(
            'slide_sweets_gate_${gate}_direction_$direction',
          ),
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color.lerp(color, Colors.white, .13)!,
                        color,
                      ],
                    )
                  : null,
              color: selected ? null : color.withValues(alpha: .08),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: .30),
                width: selected ? 1.7 : 1,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: .23),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 17,
                  color: selected ? _SlideSweetsPlayPageState._ink : color,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: _SlideSweetsPlayPageState._ink,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConveyorPainter extends CustomPainter {
  const _ConveyorPainter({
    required this.engine,
    required this.elapsed,
    required this.english,
    required this.paused,
  });

  static const List<Color> laneColors = <Color>[
    Color(0xFFF74783),
    Color(0xFFF5A623),
    Color(0xFF18BFA6),
  ];

  final SlideSweetsEngine engine;
  final double elapsed;
  final bool english;
  final bool paused;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final double w = size.width;
    final double h = size.height;
    final Rect bounds = Offset.zero & size;
    final RRect frame = RRect.fromRectAndRadius(
      bounds.deflate(2),
      const Radius.circular(24),
    );
    canvas.drawShadow(
      Path()..addRRect(frame),
      const Color(0x334C3D33),
      9,
      true,
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFCF7),
            Color(0xFFF0EAFE),
          ],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFFD8CFF0),
    );

    final double left = w * .115;
    final double right = w * .895;
    final double beltWidth = right - left;
    final List<double> lanes = <double>[h * .30, h * .52, h * .74];

    // Fine, clipped workshop drafting marks add material detail without
    // competing with the order colours or status typography.
    final Paint grain = Paint()
      ..color = const Color(0xFFD3CDE2).withValues(alpha: .32)
      ..strokeWidth = 1;
    for (int i = 1; i < 9; i++) {
      final double x = w * i / 9;
      canvas.drawLine(Offset(x, h * .08), Offset(x, h * .92), grain);
    }

    for (int lane = 0; lane < 3; lane++) {
      final double y = lanes[lane];
      final Rect beltRect = Rect.fromCenter(
        center: Offset((left + right) / 2, y),
        width: beltWidth,
        height: h * .115,
      );
      final RRect belt = RRect.fromRectAndRadius(
        beltRect,
        Radius.circular(h * .052),
      );
      canvas.drawRRect(belt, Paint()..color = const Color(0xFF8374C2));
      canvas.drawRRect(
        belt.deflate(h * .018),
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[
              Color(0xFF50427F),
              Color(0xFF302B5F),
              Color(0xFF62539A),
            ],
          ).createShader(beltRect),
      );
      final Paint dash = Paint()
        ..color = const Color(0xFFE3D8FF).withValues(alpha: .74)
        ..strokeWidth = math.max(1.3, h * .006)
        ..strokeCap = StrokeCap.round;
      for (int mark = 0; mark < 11; mark++) {
        final double x = left + ((mark * .11 + elapsed * .14) % 1) * beltWidth;
        canvas.drawLine(
          Offset(x, y - h * .026),
          Offset(x + h * .018, y - h * .026),
          dash,
        );
        canvas.drawLine(
          Offset(x, y + h * .026),
          Offset(x + h * .018, y + h * .026),
          dash,
        );
      }
      for (final double rollerX in <double>[left, right]) {
        canvas.drawCircle(
          Offset(rollerX, y),
          h * .061,
          Paint()
            ..shader =
                const RadialGradient(
                  colors: <Color>[
                    Color(0xFFFFF4D1),
                    Color(0xFFB5A5E6),
                    Color(0xFF50427F),
                  ],
                ).createShader(
                  Rect.fromCircle(center: Offset(rollerX, y), radius: h * .061),
                ),
        );
        canvas.drawCircle(
          Offset(rollerX, y),
          h * .022,
          Paint()..color = const Color(0xFF342C61),
        );
      }
      _drawStation(
        canvas,
        Offset(right + w * .052, y),
        h * .052,
        laneColors[lane],
        lane,
        w,
        h,
      );
    }

    for (int gate = 0; gate < SlideSweetsEngine.gatePositions.length; gate++) {
      final double x = left + beltWidth * SlideSweetsEngine.gatePositions[gate];
      final RRect housing = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, (lanes.first + lanes.last) / 2),
          width: w * .078,
          height: lanes.last - lanes.first + h * .12,
        ),
        const Radius.circular(13),
      );
      canvas.drawRRect(
        housing,
        Paint()..color = const Color(0xFFE0D8FF).withValues(alpha: .84),
      );
      canvas.drawRRect(
        housing,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF9D8BDB),
      );
      final int offset = engine.diverterOffsets[gate];
      final double fromY = lanes[1];
      final int toLane = (1 + offset).clamp(0, 2);
      final Offset start = Offset(x, fromY);
      final Offset end = Offset(x, lanes[toLane]);
      final Color routeColor = laneColors[toLane];
      final Paint rail = Paint()
        ..color = routeColor
        ..strokeWidth = math.max(2.2, h * .012)
        ..strokeCap = StrokeCap.round;
      if (offset == 0) {
        canvas.drawLine(
          Offset(x - w * .016, fromY),
          Offset(x + w * .016, fromY),
          Paint()
            ..color = routeColor.withValues(alpha: .24)
            ..strokeWidth = math.max(7.0, h * .035)
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(x - w * .016, fromY),
          Offset(x + w * .016, fromY),
          rail,
        );
      } else {
        final Offset turn = Offset(
          x,
          end.dy - (end.dy - start.dy).sign * h * .045,
        );
        canvas.drawLine(
          start,
          turn,
          Paint()
            ..color = routeColor.withValues(alpha: .24)
            ..strokeWidth = math.max(7.0, h * .035)
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          start,
          turn,
          rail,
        );
        canvas.drawCircle(
          end,
          math.max(3.0, h * .019),
          Paint()..color = routeColor,
        );
      }
      final TextPainter label = TextPainter(
        text: TextSpan(
          text: 'G${gate + 1}',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: laneColors[toLane],
            fontSize: math.max(7, h * .036),
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(x - label.width / 2, h * .09));
    }

    final Paint sourcePaint = Paint()..color = const Color(0xFF8A70D6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(left - w * .05, lanes[1]),
          width: w * .08,
          height: h * .18,
        ),
        const Radius.circular(10),
      ),
      sourcePaint,
    );
    final TextPainter source = TextPainter(
      text: TextSpan(
        text: english ? 'IN' : 'GİRİŞ',
        style: TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white,
          fontSize: math.max(6.5, h * .032),
          fontWeight: FontWeight.w900,
          letterSpacing: .35,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w * .08);
    source.paint(
      canvas,
      Offset(left - w * .05 - source.width / 2, lanes[1] - source.height / 2),
    );

    for (final ConveyorSweet sweet in engine.activeSweets) {
      final double x = left + beltWidth * sweet.progress;
      final double y = lanes[sweet.lane];
      final double radius = h * .071;
      _drawSweet(
        canvas,
        Offset(x, y),
        radius,
        laneColors[sweet.targetLane],
        sweet.orderIndex,
      );
    }

    if (paused) {
      canvas.drawRRect(frame, Paint()..color = const Color(0xAAFCF8F0));
      final TextPainter pausedText = TextPainter(
        text: TextSpan(
          text: english ? 'LINE PAUSED' : 'HAT DURAKLATILDI',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: const Color(0xFF6A5A4D),
            fontSize: math.max(13, h * .085),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w * .8);
      pausedText.paint(
        canvas,
        Offset((w - pausedText.width) / 2, (h - pausedText.height) / 2),
      );
    }
  }

  void _drawStation(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    int lane,
    double w,
    double h,
  ) {
    canvas.drawCircle(
      center,
      radius * 1.25,
      Paint()..color = color.withValues(alpha: .23),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.42),
          colors: <Color>[
            Color.lerp(color, Colors.white, .65)!,
            color,
            Color.lerp(color, const Color(0xFF40362F), .23)!,
          ],
          stops: const <double>[0, .48, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center.translate(-radius * .26, -radius * .30),
      radius * .17,
      Paint()..color = Colors.white.withValues(alpha: .72),
    );
    final TextPainter laneName = TextPainter(
      text: TextSpan(
        text: english
            ? const <String>['ROSE', 'HONEY', 'MINT'][lane]
            : const <String>['GÜL', 'BAL', 'NANE'][lane],
        style: TextStyle(
          fontFamily: 'Roboto',
          color: const Color(0xFF79695B),
          fontSize: math.max(6, h * .027),
          fontWeight: FontWeight.w900,
          letterSpacing: .3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w * .13);
    laneName.paint(
      canvas,
      Offset(center.dx - laneName.width / 2, center.dy + radius * 1.28),
    );
  }

  void _drawSweet(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    int serial,
  ) {
    final Path wrapper = Path()
      ..moveTo(center.dx - radius * 1.5, center.dy)
      ..lineTo(center.dx - radius * .72, center.dy - radius * .57)
      ..lineTo(center.dx - radius * .72, center.dy + radius * .57)
      ..close();
    final Path wrapperRight = Path()
      ..moveTo(center.dx + radius * 1.5, center.dy)
      ..lineTo(center.dx + radius * .72, center.dy - radius * .57)
      ..lineTo(center.dx + radius * .72, center.dy + radius * .57)
      ..close();
    canvas.drawPath(
      wrapper,
      Paint()..color = Color.lerp(color, Colors.white, .24)!,
    );
    canvas.drawPath(
      wrapperRight,
      Paint()..color = Color.lerp(color, Colors.white, .24)!,
    );
    final Rect orb = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center.translate(0, radius * .16),
      radius,
      Paint()..color = const Color(0x3344352C),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.34, -.42),
          colors: <Color>[
            Color.lerp(color, Colors.white, .72)!,
            Color.lerp(color, Colors.white, .10)!,
            Color.lerp(color, const Color(0xFF4B3440), .25)!,
          ],
          stops: const <double>[0, .44, 1],
        ).createShader(orb),
    );
    canvas.drawCircle(
      center.translate(-radius * .29, -radius * .32),
      radius * .16,
      Paint()..color = Colors.white.withValues(alpha: .82),
    );
    final TextPainter serialText = TextPainter(
      text: TextSpan(
        text: '${serial + 1}',
        style: TextStyle(
          fontFamily: 'Roboto',
          color: Colors.white.withValues(alpha: .9),
          fontSize: radius * .48,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    serialText.paint(
      canvas,
      Offset(
        center.dx - serialText.width / 2,
        center.dy - serialText.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ConveyorPainter oldDelegate) =>
      oldDelegate.engine != engine ||
      oldDelegate.elapsed != elapsed ||
      oldDelegate.english != english ||
      oldDelegate.paused != paused;
}
