import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'tower_balance_engine.dart';
import 'tower_balance_scenario.dart';

class TowerBalanceGamePage extends StatelessWidget {
  const TowerBalanceGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = TowerBalanceScenario.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final String tr = switch (level) {
        <= 3 => 'Geniş tabanda ağırlık merkezini bul ve parçayı hizala.',
        <= 6 => 'Kütle farkını ve salınım fazını okuyarak kuleyi yükselt.',
        7 || 8 => 'İleri: rüzgâr etkisinde dar destek aralığını koru.',
        9 => 'Uzman: iki hata payında asimetrik yükleri dengele.',
        _ => 'Usta finali: değişken momentte kuleyi kur, destek pimini sakla.',
      };
      final String en = switch (level) {
        <= 3 =>
          'Read the center of mass and align each piece on the broad base.',
        <= 6 => 'Read weight differences and sway phase as the tower grows.',
        7 || 8 => 'Advanced: protect the narrow support zone in crosswind.',
        9 => 'Expert: balance asymmetric loads with only two mistakes allowed.',
        _ => 'Master finale: balance a shifting moment and save your single brace pin.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Denge Atölyesi ${level.toString().padLeft(2, '0')}',
        titleEn: 'Balance Workshop ${level.toString().padLeft(2, '0')}',
        subtitleTr: tr,
        subtitleEn: en,
        difficulty: switch (level) {
          <= 3 => 'USTALAŞMA',
          <= 6 => 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.balance_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'tower_balance',
      progressPrefix: 'tower_balance',
      titleTr: 'Kule Denge',
      titleEn: 'Tower Balance',
      taglineTr: 'Kütleyi oku • Zamanı seç • Dengede yüksel',
      taglineEn: 'Read the mass • Time the drop • Build in balance',
      accent: skin.accent,
      icon: Icons.balance_rounded,
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
          ) => TowerBalancePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class TowerBalancePlayPage extends StatefulWidget {
  const TowerBalancePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<TowerBalancePlayPage> createState() => _TowerBalancePlayPageState();
}

class _TowerBalancePlayPageState extends State<TowerBalancePlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF34434B);
  static const Color _accent = Color(0xFF318C82);
  static const List<Color> _materials = <Color>[
    Color(0xFFC89261),
    Color(0xFF80B8AE),
    Color(0xFF8A959B),
    Color(0xFFD4AC64),
  ];
  static const List<String> _materialTr = <String>[
    'AHŞAP',
    'SERAMİK',
    'TAŞ',
    'PİRİNÇ',
  ];
  static const List<String> _materialEn = <String>[
    'TIMBER',
    'CERAMIC',
    'STONE',
    'BRASS',
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late final TowerBalanceScenario _scenario;
  late StudioGameSession _session;
  final List<TowerPlacedPiece> _placed = <TowerPlacedPiece>[];
  Duration _lastTick = Duration.zero;
  double _elapsed = 0;
  double _aimX = .5;
  int _pieceIndex = 0;
  int _mistakes = 0;
  int _score = 0;
  int _pinCharges = 0;
  bool _pinArmed = false;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  TowerPlacementAssessment? _lastAssessment;

  TowerPieceSpec? get _incoming => _pieceIndex < _scenario.pieces.length
      ? _scenario.pieces[_pieceIndex]
      : null;

  TowerPlacementAssessment? get _assessment {
    final TowerPieceSpec? incoming = _incoming;
    if (incoming == null) return _lastAssessment;
    return TowerBalanceEngine.assess(
      scenario: _scenario,
      placed: _placed,
      incoming: incoming,
      centerX: _aimX,
      elapsedSeconds: _elapsed,
      supportPin: _pinArmed,
    );
  }

  int get _stars {
    if (_mistakes == 0 && _pinCharges == _scenario.supportPins) return 3;
    if (_mistakes <= 1) return 2;
    return 1;
  }

  double get _calmWindow =>
      TowerBalanceEngine.waveAt(_scenario, _elapsed).abs();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    _scenario = TowerBalanceScenario.forLevel(widget.level.number);
    _pinCharges = _scenario.supportPins;
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    unawaited(_audioProfile.preload(_audio));
    _ticker.start();
    _ready = true;
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

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    _elapsed += raw.clamp(0, .035).toDouble();
    if (mounted) setState(() {});
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

  void _aimAt(double x) {
    final TowerPieceSpec? incoming = _incoming;
    if (!_ready || _paused || _finished || incoming == null) return;
    setState(() {
      _aimX = x
          .clamp(.085 + incoming.width / 2, .915 - incoming.width / 2)
          .toDouble();
      _lastAssessment = null;
    });
  }

  void _togglePin() {
    if (_pinCharges <= 0 || _paused || _finished) return;
    setState(() => _pinArmed = !_pinArmed);
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .24),
    );
  }

  void _placePiece() {
    final TowerPieceSpec? incoming = _incoming;
    if (!_ready || _paused || _finished || incoming == null) return;
    final TowerPlacementAssessment assessment = TowerBalanceEngine.assess(
      scenario: _scenario,
      placed: _placed,
      incoming: incoming,
      centerX: _aimX,
      elapsedSeconds: _elapsed,
      supportPin: _pinArmed,
    );
    _lastAssessment = assessment;
    if (assessment.stable) {
      _placed.add(TowerPlacedPiece(spec: incoming, centerX: _aimX));
      _pieceIndex++;
      _mistakes = math.max(0, _mistakes - 1);
      if (_pinArmed) _pinCharges = math.max(0, _pinCharges - 1);
      _pinArmed = false;
      final int points =
          95 +
          (assessment.overlapFraction * 110).round() +
          ((assessment.allowedMargin -
                      (assessment.projectedCenter - TowerBalanceEngine.pivotX)
                          .abs()) *
                  260)
              .round();
      _score += math.max(50, points);
      _session.recordAccepted(points: math.max(50, points));
      _lastAssessment = null;
      if (_pieceIndex >= _scenario.placementCount) {
        unawaited(_finish(completed: true));
      } else {
        final TowerPieceSpec? next = _incoming;
        if (next != null) {
          _aimX = _aimX
              .clamp(.085 + next.width / 2, .915 - next.width / 2)
              .toDouble();
        }
        _audio.hapticLight();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .27),
        );
        setState(() {});
      }
    } else {
      _mistakes++;
      _session.recordMistake();
      if (_pinArmed) {
        _pinCharges = math.max(0, _pinCharges - 1);
        _pinArmed = false;
      }
      _audio.hapticHeavy();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .32));
      if (_mistakes >= _scenario.mistakeLimit) {
        unawaited(_finish(completed: false));
      } else if (mounted) {
        setState(() {});
      }
    }
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
              title: Text(
                _english
                    ? 'Tower fell out of balance'
                    : 'Kule dengesini kaybetti',
              ),
              content: Text(
                _english
                    ? 'The balance limit was exceeded. Re-read the load and sway, then rebuild?'
                    : 'Denge sınırı aşıldı. Yükü ve salınımı yeniden okuyup kuleyi tekrar kuralım mı?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Level map' : 'Bölüm listesi'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(_english ? 'Rebuild' : 'Yeniden kur'),
                ),
              ],
            ),
          ) ??
          false;
      if (!mounted) return;
      if (retry) {
        setState(_restart);
      } else {
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    _session.complete(
      stars: _stars,
      action: widget.level.number < TowerBalanceGamePage.totalCases
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
      titleTr: 'KULE DENGEDE',
      titleEn: 'TOWER STANDS',
      detailTr:
          '${_scenario.placementCount} parça yerleşti · $_mistakes savrulma.',
      detailEn:
          '${_scenario.placementCount} pieces placed · $_mistakes balance slips.',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < TowerBalanceGamePage.totalCases,
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

  void _restart() {
    _ticker.stop();
    _lastTick = Duration.zero;
    _elapsed = 0;
    _aimX = .5;
    _pieceIndex = 0;
    _mistakes = 0;
    _score = 0;
    _pinCharges = _scenario.supportPins;
    _pinArmed = false;
    _placed.clear();
    _lastAssessment = null;
    _finished = false;
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _ticker.start();
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
        appBar: AppBar(title: Text(_english ? 'TOWER BALANCE' : 'KULE DENGE')),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final TowerPieceSpec? incoming = _incoming;
    final TowerPlacementAssessment? assessment = _assessment;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english ? 'TOWER BALANCE' : 'KULE DENGE',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('tower_balance_pause'),
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
              padding: const EdgeInsets.fromLTRB(13, 6, 13, 7),
              child: Column(
                children: <Widget>[
                  _TowerHud(
                    placed: _pieceIndex,
                    total: _scenario.placementCount,
                    score: _score,
                    mistakes: _mistakes,
                    mistakeLimit: _scenario.mistakeLimit,
                    calmWindow: _calmWindow,
                    english: _english,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final double width = math.min(limits.maxWidth, 570);
                        final double height = math.min(
                          limits.maxHeight,
                          width * 1.12,
                        );
                        return Center(
                          child: SizedBox(
                            width: width,
                            height: height,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (TapDownDetails details) =>
                                  _aimAt(details.localPosition.dx / width),
                              onTapUp: (_) => _placePiece(),
                              onPanUpdate: (DragUpdateDetails details) =>
                                  _aimAt(details.localPosition.dx / width),
                              onPanEnd: (_) => _placePiece(),
                              child: CustomPaint(
                                key: const ValueKey<String>(
                                  'tower_balance_scene',
                                ),
                                painter: _TowerPainter(
                                  pieces: List<TowerPlacedPiece>.of(_placed),
                                  incoming: incoming,
                                  aimX: _aimX,
                                  scenario: _scenario,
                                  elapsed: _elapsed,
                                  assessment: assessment,
                                  mistakes: _mistakes,
                                  pinArmed: _pinArmed,
                                  paused: _paused,
                                  english: _english,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  _TowerControls(
                    aimX: _aimX,
                    canPlace: !_paused && !_finished && incoming != null,
                    canUsePin: _pinCharges > 0 && !_paused && !_finished,
                    pinArmed: _pinArmed,
                    english: _english,
                    material: incoming?.material ?? 0,
                    mass: incoming?.mass ?? 0,
                    onAim: _aimAt,
                    onPlace: _placePiece,
                    onPin: _togglePin,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _english
                        ? 'Move the suspended piece, watch the balance window, then place. The center of mass must stay over the support.'
                        : 'Askıdaki parçayı hizala, denge penceresini izle ve yerleştir. Ağırlık merkezi desteğin üzerinde kalmalı.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 9,
                      height: 1.2,
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

class _TowerHud extends StatelessWidget {
  const _TowerHud({
    required this.placed,
    required this.total,
    required this.score,
    required this.mistakes,
    required this.mistakeLimit,
    required this.calmWindow,
    required this.english,
  });

  final int placed;
  final int total;
  final int score;
  final int mistakes;
  final int mistakeLimit;
  final double calmWindow;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('tower_balance_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: _TowerMetric(
            label: english ? 'HEIGHT' : 'YÜKSEKLİK',
            value: '$placed / $total',
            icon: Icons.height_rounded,
            color: _TowerBalancePlayPageState._accent,
          ),
        ),
        Container(width: 1, height: 29, color: StudioVisuals.line),
        Expanded(
          child: _TowerMetric(
            label: english ? 'SCORE' : 'PUAN',
            value: '$score',
            icon: Icons.stars_rounded,
            color: const Color(0xFFD3A45A),
          ),
        ),
        Container(width: 1, height: 29, color: StudioVisuals.line),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                english ? 'BALANCE' : 'DENGE',
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: (1 - calmWindow).clamp(0, 1).toDouble(),
                  backgroundColor: const Color(0xFFE9E5DD),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    calmWindow < .30
                        ? _TowerBalancePlayPageState._accent
                        : const Color(0xFFD5A85F),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  mistakeLimit,
                  (int index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      Icons.circle_rounded,
                      size: 6,
                      color: index < mistakeLimit - mistakes
                          ? const Color(0xFFD48675)
                          : const Color(0xFFE8E3DC),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TowerMetric extends StatelessWidget {
  const _TowerMetric({
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
      Icon(icon, color: color, size: 16),
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
                color: StudioVisuals.muted,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _TowerBalancePlayPageState._ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TowerControls extends StatelessWidget {
  const _TowerControls({
    required this.aimX,
    required this.canPlace,
    required this.canUsePin,
    required this.pinArmed,
    required this.english,
    required this.material,
    required this.mass,
    required this.onAim,
    required this.onPlace,
    required this.onPin,
  });

  final double aimX;
  final bool canPlace;
  final bool canUsePin;
  final bool pinArmed;
  final bool english;
  final int material;
  final double mass;
  final ValueChanged<double> onAim;
  final VoidCallback onPlace;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Container(
        padding: const EdgeInsets.fromLTRB(9, 2, 5, 2),
        decoration: BoxDecoration(
          color: StudioVisuals.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: StudioVisuals.line),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.swap_horiz_rounded,
              color: _TowerBalancePlayPageState._accent,
              size: 20,
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 50,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    english
                        ? _TowerBalancePlayPageState._materialEn[material]
                        : _TowerBalancePlayPageState._materialTr[material],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _TowerBalancePlayPageState._materials[material],
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${english ? 'MASS' : 'KÜTLE'} ${mass.toStringAsFixed(1)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 15,
                  ),
                ),
                child: Slider(
                  key: const ValueKey<String>('tower_balance_aim'),
                  value: aimX.clamp(.18, .82),
                  min: .18,
                  max: .82,
                  activeColor: _TowerBalancePlayPageState._accent,
                  onChanged: onAim,
                ),
              ),
            ),
            SizedBox(
              height: 41,
              child: FilledButton.icon(
                key: const ValueKey<String>('tower_balance_place'),
                onPressed: canPlace ? onPlace : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _TowerBalancePlayPageState._accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.vertical_align_bottom_rounded, size: 16),
                label: Text(
                  english ? 'PLACE' : 'YERLEŞTİR',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      if (canUsePin || pinArmed)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const ValueKey<String>('tower_balance_pin'),
              onPressed: onPin,
              style: OutlinedButton.styleFrom(
                foregroundColor: pinArmed
                    ? Colors.white
                    : const Color(0xFFAD8242),
                backgroundColor: pinArmed
                    ? const Color(0xFFAD8242)
                    : Colors.white,
                side: const BorderSide(color: Color(0xFFD8BF91)),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              icon: const Icon(Icons.push_pin_outlined, size: 15),
              label: Text(
                english
                    ? (pinArmed ? 'BRACE ARMED' : 'USE SUPPORT PIN')
                    : (pinArmed ? 'PİM HAZIR' : 'DESTEK PİMİ'),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      Semantics(
        label:
            '${english ? _TowerBalancePlayPageState._materialEn[material] : _TowerBalancePlayPageState._materialTr[material]} · ${mass.toStringAsFixed(1)}',
        child: const SizedBox.shrink(),
      ),
    ],
  );
}

class _TowerPainter extends CustomPainter {
  const _TowerPainter({
    required this.pieces,
    required this.incoming,
    required this.aimX,
    required this.scenario,
    required this.elapsed,
    required this.assessment,
    required this.mistakes,
    required this.pinArmed,
    required this.paused,
    required this.english,
  });

  final List<TowerPlacedPiece> pieces;
  final TowerPieceSpec? incoming;
  final double aimX;
  final TowerBalanceScenario scenario;
  final double elapsed;
  final TowerPlacementAssessment? assessment;
  final int mistakes;
  final bool pinArmed;
  final bool paused;
  final bool english;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final double height = size.height / size.width;
    canvas.save();
    canvas.scale(size.width, size.width);
    final Rect rect = Rect.fromLTWH(0, 0, 1, height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(.045)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFCF7),
            Color(0xFFF4F0E8),
            Color(0xFFE9E3D9),
          ],
        ).createShader(rect),
    );
    final Paint ambient = Paint()
      ..color = const Color(0xFFB8A98E).withValues(alpha: .12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(.5, height * .40),
        width: .74,
        height: height * .53,
      ),
      ambient,
    );

    // Workshop ruler and fine drafting grid, kept subordinate to the tower.
    final Paint ruler = Paint()
      ..color = const Color(0xFF9B968B).withValues(alpha: .19)
      ..strokeWidth = .0014;
    for (int index = 0; index < 10; index++) {
      final double y = .20 + index * .115;
      if (y < height - .19) {
        canvas.drawLine(Offset(.08, y), Offset(.92, y), ruler);
        canvas.drawLine(
          Offset(.08, y),
          Offset(.105, y),
          Paint()
            ..color = const Color(0xFF8B857A).withValues(alpha: .38)
            ..strokeWidth = .003,
        );
      }
    }
    for (int index = 0; index < 11; index++) {
      final double x = .12 + index * .076;
      canvas.drawLine(
        Offset(x, height - .18),
        Offset(x, height - .155),
        Paint()
          ..color = const Color(0xFF8B857A).withValues(alpha: .30)
          ..strokeWidth = .002,
      );
    }

    final double floorY = height - .155;
    final double towerHeight = pieces.fold<double>(
      0,
      (double sum, TowerPlacedPiece piece) => sum + piece.spec.height,
    );
    final double incomingHeight = incoming?.height ?? 0;
    final double scaleY = math.min(
      1,
      (height - .40) / math.max(.2, towerHeight + incomingHeight),
    );
    final double swingWave = TowerBalanceEngine.waveAt(scenario, elapsed);
    final double swingAngle = swingWave * scenario.tiltAmplitude;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(.5, floorY + .026),
        width: .76,
        height: .065,
      ),
      Paint()..color = const Color(0xFF645B4D).withValues(alpha: .20),
    );
    canvas.save();
    canvas.translate(.5, floorY);
    canvas.rotate(swingAngle);
    final RRect base = RRect.fromRectAndRadius(
      Rect.fromLTRB(-.37, -.026, .37, .024),
      const Radius.circular(.018),
    );
    canvas.drawRRect(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFE2BD77),
            Color(0xFFB98E4B),
            Color(0xFF80633E),
          ],
        ).createShader(base.outerRect),
    );
    canvas.drawRRect(
      base,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .003
        ..color = const Color(0xFFFFF3D5).withValues(alpha: .82),
    );
    final Rect pivotBounds = Rect.fromCircle(
      center: const Offset(0, .03),
      radius: .034,
    );
    canvas.drawCircle(
      const Offset(0, .03),
      .034,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFFF8EAC9), Color(0xFF9F7748)],
        ).createShader(pivotBounds),
    );
    canvas.drawLine(
      const Offset(-.035, .03),
      const Offset(.035, .03),
      Paint()
        ..color = const Color(0xFF68533B)
        ..strokeWidth = .006,
    );
    if (pinArmed) {
      final Paint pin = Paint()
        ..color = const Color(0xFF9C7440)
        ..strokeWidth = .012
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-.17, .035), const Offset(0, -.055), pin);
      canvas.drawLine(const Offset(.17, .035), const Offset(0, -.055), pin);
      canvas.drawCircle(
        const Offset(0, -.058),
        .017,
        Paint()..color = const Color(0xFFDDB96F),
      );
    }
    canvas.restore();

    final double targetY = floorY - .04;
    canvas.drawLine(
      Offset(.5, .13),
      Offset(.5, floorY + .02),
      Paint()
        ..color = const Color(0xFF788A80).withValues(alpha: .24)
        ..strokeWidth = .002
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(.5, targetY),
      .015,
      Paint()..color = const Color(0xFF627D70).withValues(alpha: .65),
    );

    double stackTop = floorY - .052;
    for (final TowerPlacedPiece piece in pieces) {
      final double blockHeight = piece.spec.height * scaleY;
      stackTop -= blockHeight;
      _drawBlock(
        canvas,
        centerX: piece.centerX,
        centerY: stackTop + blockHeight / 2,
        width: piece.spec.width,
        height: blockHeight,
        spec: piece.spec,
        settled: true,
      );
    }

    final TowerPieceSpec? next = incoming;
    if (next != null) {
      final double blockHeight = next.height * scaleY;
      final double cableBottom = math.max(.19, stackTop - .115);
      canvas.drawLine(
        Offset(aimX, .12),
        Offset(aimX, cableBottom - blockHeight * .48),
        Paint()
          ..color = const Color(0xFF818278)
          ..strokeWidth = .003,
      );
      canvas.drawCircle(
        Offset(aimX, .12),
        .014,
        Paint()..color = const Color(0xFFC49B5D),
      );
      _drawBlock(
        canvas,
        centerX: aimX,
        centerY: cableBottom,
        width: next.width,
        height: blockHeight,
        spec: next,
        settled: false,
        stable: assessment?.stable ?? false,
      );
      final double center = assessment?.projectedCenter ?? .5;
      final Color momentColor = assessment == null
          ? const Color(0xFF769482)
          : assessment!.stable
          ? const Color(0xFF4B9C7C)
          : const Color(0xFFD17969);
      final Paint moment = Paint()
        ..color = momentColor.withValues(alpha: .72)
        ..strokeWidth = .0032;
      canvas.drawLine(
        Offset(center, .18),
        Offset(center, floorY - .015),
        moment,
      );
      canvas.drawCircle(
        Offset(center, floorY - .015),
        .013,
        Paint()..color = momentColor,
      );
      _drawText(
        canvas,
        english ? 'LOAD' : 'KÜTLE',
        Offset(aimX, cableBottom - blockHeight * .72),
        .15,
        .033,
        const Color(0xFF6C7772),
        FontWeight.w900,
      );
    }

    final double momentError = assessment == null
        ? 0
        : assessment!.projectedCenter - .5;
    final Color gaugeColor = assessment == null
        ? _TowerBalancePlayPageState._accent
        : assessment!.stable
        ? _TowerBalancePlayPageState._accent
        : const Color(0xFFD17969);
    final Rect gauge = Rect.fromLTRB(.18, .095, .82, .108);
    canvas.drawRRect(
      RRect.fromRectAndRadius(gauge, const Radius.circular(.009)),
      Paint()..color = const Color(0xFF808A80).withValues(alpha: .22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(.5 + momentError.clamp(-.30, .30), .1015),
          width: .025,
          height: .04,
        ),
        const Radius.circular(.009),
      ),
      Paint()..color = gaugeColor,
    );
    _drawText(
      canvas,
      english ? 'CENTER OF MASS' : 'AĞIRLIK MERKEZİ',
      Offset(.5, .075),
      .38,
      .027,
      const Color(0xFF777B72),
      FontWeight.w900,
    );
    _drawText(
      canvas,
      english ? 'SUPPORT' : 'DESTEK',
      Offset(.5, floorY + .075),
      .20,
      .026,
      const Color(0xFF807660),
      FontWeight.w900,
    );

    if (mistakes > 0 && !paused) {
      _drawText(
        canvas,
        english ? 'RECOVER THE BALANCE' : 'DENGEYİ TOPARLA',
        Offset(.5, .16),
        .42,
        .031,
        const Color(0xFFB97362),
        FontWeight.w900,
      );
    }
    if (paused) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(.07, .06, .86, height - .12),
          const Radius.circular(.045),
        ),
        Paint()..color = const Color(0xCCF4F0E8),
      );
      _drawText(
        canvas,
        english ? 'PAUSED' : 'DURAKLATILDI',
        Offset(.5, height * .49),
        .56,
        .055,
        _TowerBalancePlayPageState._ink,
        FontWeight.w900,
      );
    }
    canvas.restore();
  }

  void _drawBlock(
    Canvas canvas, {
    required double centerX,
    required double centerY,
    required double width,
    required double height,
    required TowerPieceSpec spec,
    required bool settled,
    bool stable = true,
  }) {
    final Color material = _TowerBalancePlayPageState._materials[spec.material];
    final Rect rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: width,
      height: height,
    );
    final RRect round = RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.min(.016, height * .20)),
    );
    if (settled) {
      canvas.drawRRect(
        round.shift(const Offset(.009, .014)),
        Paint()..color = const Color(0xFF493E30).withValues(alpha: .18),
      );
    }
    canvas.drawRRect(
      round,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(material, Colors.white, .37)!,
            material,
            Color.lerp(material, const Color(0xFF45423B), .23)!,
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      round,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .0035
        ..color = stable
            ? Colors.white.withValues(alpha: .72)
            : const Color(0xFFD17869),
    );
    canvas.drawLine(
      Offset(rect.left + .014, rect.top + .018),
      Offset(rect.right - .014, rect.top + .018),
      Paint()
        ..color = Colors.white.withValues(alpha: .46)
        ..strokeWidth = .002,
    );
    if (spec.material == 0) {
      for (double x = rect.left + .026; x < rect.right - .02; x += .047) {
        canvas.drawLine(
          Offset(x, rect.top + .027),
          Offset(x - .006, rect.bottom - .023),
          Paint()
            ..color = const Color(0xFF744E35).withValues(alpha: .21)
            ..strokeWidth = .002,
        );
      }
    } else if (spec.material == 3) {
      canvas.drawCircle(
        Offset(rect.left + .022, centerY),
        .006,
        Paint()..color = const Color(0xFFFFE7A7).withValues(alpha: .84),
      );
      canvas.drawCircle(
        Offset(rect.right - .022, centerY),
        .006,
        Paint()..color = const Color(0xFF7E633A).withValues(alpha: .72),
      );
    }
    canvas.drawCircle(
      Offset(centerX + spec.massBias * spec.width, centerY),
      .009,
      Paint()
        ..color = const Color(0xFFFBF5E8)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(centerX + spec.massBias * spec.width, centerY),
      .009,
      Paint()
        ..color = const Color(0xFF66594B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .002,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double maxWidth,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: .35,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TowerPainter oldDelegate) => true;
}
