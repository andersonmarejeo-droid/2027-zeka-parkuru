import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../reference_games/reference_game_support.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import 'bubble_shooter_puzzle.dart';

class BubbleShooterGamePage extends StatelessWidget {
  const BubbleShooterGamePage({super.key});

  static const int totalLevels = 10;
  static const int totalStars = totalLevels * 3;

  static final List<ParkurLevelSpec> levels = List<ParkurLevelSpec>.generate(
    totalLevels,
    (int index) {
      final int number = index + 1;
      final String subtitleTr = switch (number) {
        <= 2 => 'Aynı renkten üç veya fazlasını bir araya getir.',
        <= 6 => 'Renk kümelerini zincirleyip tavandaki alanı temizle.',
        7 || 8 => 'İleri: beş renk ve dar atış hakkıyla kümeleri planla.',
        9 => 'Uzman: geniş dizilimi sınırlı atışta erit.',
        _ => 'Usta finali: altı rengi ve her atışı hassas yönet.',
      };
      final String subtitleEn = switch (number) {
        <= 2 => 'Match three or more bubbles of the same color.',
        <= 6 => 'Chain color clusters and clear the full ceiling.',
        7 || 8 => 'Advanced: plan five colors with a tight shot budget.',
        9 => 'Expert: clear a broad field with very few shots.',
        _ => 'Master finale: manage six colors and every shot precisely.',
      };
      return ParkurLevelSpec(
        number: number,
        titleTr: 'Baloncuk Arenası ${number.toString().padLeft(2, '0')}',
        titleEn: 'Bubble Arena ${number.toString().padLeft(2, '0')}',
        subtitleTr: subtitleTr,
        subtitleEn: subtitleEn,
        difficulty: switch (number) {
          <= 3 => 'TEMEL',
          <= 6 => 'USTALAŞMA',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.bubble_chart_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) => ParkurLevelHub(
    gameId: 'bubble_shooter',
    progressPrefix: 'bubble_shooter',
    titleTr: 'BALONCUK ARENASI',
    titleEn: 'BUBBLE SHOOTER',
    taglineTr: 'Nişan al • Renkleri eşleştir • Alanı temizle',
    taglineEn: 'Aim • Match colors • Clear the field',
    accent: const Color(0xFF318C82),
    icon: Icons.bubble_chart_rounded,
    levels: levels,
    dailyCourseMode: false,
    playBuilder:
        (
          BuildContext context,
          ParkurLevelSpec level,
          int previousBestScore,
          int? fixedSessionSeed,
          bool competitionMode,
        ) => BubbleShooterPlayPage(
          level: level,
          previousBestScore: previousBestScore,
          fixedSessionSeed: fixedSessionSeed,
        ),
  );
}

class BubbleShooterPlayPage extends StatefulWidget {
  const BubbleShooterPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.fixedSessionSeed,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? fixedSessionSeed;

  @override
  State<BubbleShooterPlayPage> createState() => _BubbleShooterPlayPageState();
}

class _BubbleShooterPlayPageState extends State<BubbleShooterPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _ink = Color(0xFF263C3C);
  static const Color _accent = Color(0xFF318C82);
  static const List<Color> _colors = <Color>[
    Color(0xFF18A999),
    Color(0xFFFF796C),
    Color(0xFFF0B94C),
    Color(0xFF8B78D2),
    Color(0xFF5598D4),
    Color(0xFF6BAE72),
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final AnimationController _shotAnimation;
  late final AnimationController _popAnimation;
  List<_BubbleBurst> _popBursts = <_BubbleBurst>[];
  Timer? _timer;
  BubbleShooterPuzzle? _puzzle;
  BubbleShooterEngine? _engine;
  StudioGameSession? _session;
  math.Random _random = math.Random();
  int _currentColor = 0;
  int _nextColor = 1;
  int _shots = 0;
  int _elapsed = 0;
  int _score = 0;
  int _hints = 0;
  int _streak = 0;
  int _sessionBestScore = 0;
  Size _fieldSize = Size.zero;
  Offset? _aimPoint;
  Offset _shotFrom = Offset.zero;
  Offset _shotTo = Offset.zero;
  int _shotColor = 0;
  bool _shotInFlight = false;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;

  BubbleShooterEngine get _board => _engine!;
  BubbleShooterPuzzle get _spec => _puzzle!;

  int get _stars {
    if (_shots <= (_spec.shotLimit * .58).floor() && _hints == 0) return 3;
    if (_shots <= (_spec.shotLimit * .82).floor()) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shotAnimation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 270),
        )..addListener(() {
          if (mounted && _shotInFlight) setState(() {});
        });
    _popAnimation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 440),
        )..addListener(() {
          if (mounted && _popBursts.isNotEmpty) setState(() {});
        });
    _popAnimation.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _popBursts = <_BubbleBurst>[]);
      }
    });
    _sessionBestScore = widget.previousBestScore;
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareRound());
  }

  Future<void> _prepareRound() async {
    final int variant = widget.fixedSessionSeed == null
        ? await ReferenceRoundStore.reserve(
            gameId: 'bubble_shooter',
            level: widget.level.number,
          )
        : widget.fixedSessionSeed! % ReferenceRoundStore.variantsPerLevel;
    if (!mounted) return;
    final int seed = ReferenceRoundStore.seed(
      'bubble_shooter',
      widget.level.number,
      variant,
    );
    _random = math.Random(seed ^ 0x44AA1);
    _puzzle = BubbleShooterPuzzle.generate(widget.level.number, variant);
    _engine = BubbleShooterEngine(_spec);
    final List<int> openingColors = <int>{
      for (final int value in _spec.cells.whereType<int>()) value,
    }.toList()..sort();
    _currentColor = openingColors[_random.nextInt(openingColors.length)];
    _nextColor = openingColors[_random.nextInt(openingColors.length)];
    _shots = 0;
    _elapsed = 0;
    _score = 0;
    _hints = 0;
    _streak = 0;
    _paused = false;
    _finished = false;
    _aimPoint = null;
    _popBursts = <_BubbleBurst>[];
    _popAnimation.stop();
    _session = StudioGameSession(level: widget.level.number, seed: seed)
      ..start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted && !_paused && !_finished) setState(() => _elapsed++);
    });
    setState(() => _ready = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      if (_ready && !_paused && !_finished) _setPaused(true);
    }
  }

  void _setPaused(bool value) {
    if (!_ready || _finished || _paused == value) return;
    setState(() => _paused = value);
    if (value) {
      _session?.pause();
    } else {
      _session?.resume();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .22));
  }

  Offset _shooterCenter(Size size) => Offset(size.width / 2, size.height - 42);

  Offset _bubbleCenter(int row, int column, double diameter) => Offset(
    (column + (row.isOdd ? 1 : .5)) * diameter,
    diameter * .5 + row * diameter * .8660254,
  );

  List<Offset> _traceShot(Offset target, Size size) {
    final double diameter = size.width / BubbleShooterPuzzle.columns;
    final Offset start = _shooterCenter(size);
    Offset direction = target - start;
    if (direction.distance < 1) direction = const Offset(0, -1);
    if (direction.dy >= -12) {
      direction = Offset(direction.dx, -math.max(52.0, direction.dy.abs()));
    }
    direction = direction / direction.distance;
    final List<Offset> path = <Offset>[start];
    Offset point = start;
    for (int step = 0; step < 900; step++) {
      point += direction * 3.5;
      if (point.dx < diameter * .5) {
        point = Offset(diameter * .5, point.dy);
        direction = Offset(direction.dx.abs(), direction.dy);
      } else if (point.dx > size.width - diameter * .5) {
        point = Offset(size.width - diameter * .5, point.dy);
        direction = Offset(-direction.dx.abs(), direction.dy);
      }
      if (step % 5 == 0) path.add(point);
      if (point.dy <= diameter * .5) break;
      bool collided = false;
      for (int row = 0; row < BubbleShooterPuzzle.maxRows; row++) {
        for (int column = 0; column < BubbleShooterPuzzle.columns; column++) {
          if (_board.at(row, column) == null) continue;
          if ((point - _bubbleCenter(row, column, diameter)).distance <
              diameter * .91) {
            collided = true;
            break;
          }
        }
        if (collided) break;
      }
      if (collided) break;
    }
    path.add(point);
    return path;
  }

  (int, int)? _landingCell(List<Offset> path, Size size) {
    final double diameter = size.width / BubbleShooterPuzzle.columns;
    final Offset impact = path.last;
    (int, int)? chosen;
    double bestDistance = double.infinity;
    for (int row = 0; row < BubbleShooterPuzzle.maxRows; row++) {
      for (int column = 0; column < BubbleShooterPuzzle.columns; column++) {
        if (!BubbleShooterPuzzle.isValidCell(row, column) ||
            _board.at(row, column) != null) {
          continue;
        }
        final bool attached =
            row == 0 ||
            _board
                .neighbors(row, column)
                .any(((int, int) cell) => _board.at(cell.$1, cell.$2) != null);
        if (!attached) continue;
        final double distance =
            (_bubbleCenter(row, column, diameter) - impact).distanceSquared;
        if (distance < bestDistance) {
          bestDistance = distance;
          chosen = (row, column);
        }
      }
    }
    return chosen;
  }

  void _shootToward(Offset target) {
    if (!_ready ||
        _paused ||
        _finished ||
        _shotInFlight ||
        _shots >= _spec.shotLimit) {
      return;
    }
    _aimPoint = target;
    final List<Offset> path = _traceShot(target, _fieldSize);
    final (int, int)? cell = _landingCell(path, _fieldSize);
    if (cell == null) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      unawaited(_finish(completed: false, boardBlocked: true));
      return;
    }

    _shotFrom = path.first;
    _shotTo = _bubbleCenter(cell.$1, cell.$2, _fieldSize.width / 8);
    _shotColor = _currentColor;
    _shotInFlight = true;
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .24),
    );
    _shotAnimation.forward(from: 0).whenComplete(() {
      if (!mounted || !_shotInFlight) return;
      _shotInFlight = false;
      final BubbleShotResult result = _board.fire(
        row: cell.$1,
        column: cell.$2,
        color: _shotColor,
      );
      if (!result.placed) {
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .24),
        );
        setState(() {});
        return;
      }
      _shots++;
      if (result.popped) {
        final double diameter = _fieldSize.width / BubbleShooterPuzzle.columns;
        _popBursts = result.removedBubbles
            .take(24)
            .map((bubble) {
              return _BubbleBurst(
                center: _bubbleCenter(bubble.$1, bubble.$2, diameter),
                color: _colors[bubble.$3 % _colors.length],
              );
            })
            .toList(growable: false);
        _popAnimation.forward(from: 0);
        _streak++;
        final int points =
            result.matched * 30 + result.fallen * 45 + _streak * 12;
        _score += points;
        _session?.recordAccepted(points: points);
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .34),
        );
        _audio.hapticLight();
      } else {
        _streak = 0;
        _session?.recordMistake();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .12),
        );
      }
      _currentColor = _nextColor;
      final List<int> colors = List<int>.generate(
        _spec.colorCount,
        (int i) => i,
      );
      _nextColor = colors[_random.nextInt(colors.length)];
      setState(() {});
      if (_board.isCleared) {
        unawaited(_finish(completed: true));
      } else if (_shots >= _spec.shotLimit) {
        unawaited(_finish(completed: false));
      }
    });
    setState(() {});
  }

  void _showHint() {
    final StudioGameSession? session = _session;
    if (_hints >= 3 || !_ready || _paused || _finished || session == null) {
      return;
    }
    if (!session.useHint()) return;
    setState(() => _hints++);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .24));
    // The suggested color is chosen from the largest remaining cluster.
    int bestRow = 0;
    int bestColumn = 0;
    int bestColor = _currentColor;
    int bestCount = 0;
    for (int row = 0; row < _spec.rows; row++) {
      for (int column = 0; column < BubbleShooterPuzzle.columns; column++) {
        final int? color = _board.at(row, column);
        if (color == null) continue;
        final int count = _board
            .neighbors(row, column)
            .where(((int, int) cell) => _board.at(cell.$1, cell.$2) == color)
            .length;
        if (count > bestCount) {
          bestCount = count;
          bestRow = row;
          bestColumn = column;
          bestColor = color;
        }
      }
    }
    _currentColor = bestColor;
    final Offset target = _bubbleCenter(
      bestRow,
      bestColumn,
      _fieldSize.width / 8,
    );
    _aimPoint = target;
  }

  Future<void> _finish({
    required bool completed,
    bool boardBlocked = false,
  }) async {
    if (_finished || !mounted) return;
    _finished = true;
    _timer?.cancel();
    if (!completed) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .32));
      final bool retry =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: Text(
                boardBlocked
                    ? (_english ? 'Board is blocked' : 'Tahta sıkıştı')
                    : (_english ? 'Out of shots' : 'Atış hakkı bitti'),
              ),
              content: Text(
                boardBlocked
                    ? (_english
                          ? 'There is no safe place to attach the next bubble. Restart the level and plan a different cluster.'
                          : 'Yeni balonu bağlayacak uygun bir hücre kalmadı. Bölümü yeniden başlatıp farklı bir küme planla.')
                    : _english
                    ? '$_shots of ${_spec.shotLimit} shots used. Adjust your aim and give the board another try.'
                    : '${_spec.shotLimit} atıştan $_shots tanesini kullandın. Nişanını ayarlayıp tahtayı yeniden dene.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(_english ? 'Level map' : 'Bölüm listesi'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(_english ? 'Retry' : 'Yeniden dene'),
                ),
              ],
            ),
          ) ??
          false;
      if (!mounted) return;
      if (retry) {
        _ready = false;
        _shotInFlight = false;
        await _prepareRound();
      } else {
        Navigator.of(context)
            .pop(StudioGameResult.failed(score: _score).toParkurResult());
      }
      return;
    }

    final int timeBonus = math.max(0, 180 - _elapsed);
    _score += timeBonus;
    _session?.recordAccepted(points: timeBonus);
    _session?.complete(
      stars: _stars,
      action: widget.level.number < BubbleShooterGamePage.totalLevels
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 460));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'BALONCUK ARENASI TAMAMLANDI',
      titleEn: 'BUBBLE ARENA CLEARED',
      detailTr: '$_shots atış · $_streak seri · $_elapsed sn.',
      detailEn: '$_shots shots · $_streak streak · $_elapsed s.',
      stars: _stars,
      score: _score,
      previousBestScore: _sessionBestScore,
      canGoNext: widget.level.number < BubbleShooterGamePage.totalLevels,
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
    _timer?.cancel();
    _shotAnimation.dispose();
    _popAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready || _engine == null || _puzzle == null) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          title: Text(_english ? 'BUBBLE SHOOTER' : 'BALONCUK ARENASI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final int remaining = math.max(0, _spec.shotLimit - _shots);
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _english ? 'BUBBLE SHOOTER' : 'BALONCUK ARENASI',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          IconButton(
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
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints limits) {
            final double width = math.min(limits.maxWidth - 24, 440);
            final double diameter = width / BubbleShooterPuzzle.columns;
            final double boardHeight =
                diameter * (.8660254 * (_spec.rows - 1) + 2.35) + 39;
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 22),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: <Widget>[
                        _BubbleScorePanel(
                          shots: _shots,
                          remaining: remaining,
                          score: _score,
                          elapsed: _elapsed,
                          level: widget.level.number,
                          color: _accent,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          key: const ValueKey<String>(
                            'bubble_shooter_play_field',
                          ),
                          width: width,
                          height: boardHeight,
                          child: LayoutBuilder(
                            builder:
                                (BuildContext context, BoxConstraints box) {
                                  _fieldSize = Size(
                                    box.maxWidth,
                                    box.maxHeight,
                                  );
                                  final Offset initialAim = Offset(
                                    _fieldSize.width * .5,
                                    _fieldSize.height * .42,
                                  );
                                  final List<Offset> aimPath = _traceShot(
                                    _aimPoint ?? initialAim,
                                    _fieldSize,
                                  );
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (DragStartDetails details) =>
                                        setState(
                                          () =>
                                              _aimPoint = details.localPosition,
                                        ),
                                    onPanUpdate: (DragUpdateDetails details) =>
                                        setState(
                                          () =>
                                              _aimPoint = details.localPosition,
                                        ),
                                    onPanEnd: (DragEndDetails details) {
                                      if (_aimPoint != null) {
                                        _shootToward(_aimPoint!);
                                      }
                                    },
                                    onTapUp: (TapUpDetails details) =>
                                        _shootToward(details.localPosition),
                                    child: CustomPaint(
                                      painter: _BubbleShooterPainter(
                                        cells: _board.cells,
                                        columns: BubbleShooterPuzzle.columns,
                                        currentColor: _colors[_currentColor],
                                        nextColor: _colors[_nextColor],
                                        aimPath: aimPath,
                                        shotFrom: _shotFrom,
                                        shotTo: _shotTo,
                                        shotColor: _shotColor < _colors.length
                                            ? _colors[_shotColor]
                                            : _accent,
                                        shotProgress: _shotAnimation.value,
                                        shotInFlight: _shotInFlight,
                                        paused: _paused,
                                        popBursts: _popBursts,
                                        popProgress: _popAnimation.value,
                                      ),
                                    ),
                                  );
                                },
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _BubbleLegend(
                                color: _colors[_currentColor],
                                label: _english ? 'NOW' : 'ŞİMDİ',
                              ),
                            ),
                            Expanded(
                              child: _BubbleLegend(
                                color: _colors[_nextColor],
                                label: _english ? 'NEXT' : 'SONRA',
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: _english ? 'Hint' : 'İpucu',
                              onPressed: _hints >= 3 ? null : _showHint,
                              icon: const Icon(Icons.lightbulb_outline_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _english
                              ? 'Tap a direction to shoot, or drag and release to aim precisely.'
                              : 'Atış için ekrana dokun; hassas nişan için sürükleyip bırak.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: StudioVisuals.muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BubbleScorePanel extends StatelessWidget {
  const _BubbleScorePanel({
    required this.shots,
    required this.remaining,
    required this.score,
    required this.elapsed,
    required this.level,
    required this.color,
  });

  final int shots;
  final int remaining;
  final int score;
  final int elapsed;
  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE6ECE8)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x0C243D37),
          blurRadius: 15,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        _ScoreMetric(
          label: context.l10n.isEnglish ? 'LEVEL' : 'BÖLÜM',
          value: '$level',
          color: color,
        ),
        _ScoreMetric(
          label: context.l10n.isEnglish ? 'SHOTS' : 'ATIŞ',
          value: '$shots',
          color: const Color(0xFF52665E),
        ),
        _ScoreMetric(
          label: context.l10n.isEnglish ? 'LEFT' : 'KALAN',
          value: '$remaining',
          color: remaining <= 8 ? const Color(0xFFE37267) : color,
        ),
        _ScoreMetric(
          label: context.l10n.isEnglish ? 'SCORE' : 'PUAN',
          value: '$score',
          color: const Color(0xFF52665E),
        ),
        _ScoreMetric(
          label: context.l10n.isEnglish ? 'TIME' : 'SÜRE',
          value: '${elapsed}s',
          color: const Color(0xFF52665E),
        ),
      ],
    ),
  );
}

class _ScoreMetric extends StatelessWidget {
  const _ScoreMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: <Widget>[
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontWeight: FontWeight.w800,
            fontSize: 8,
            letterSpacing: .3,
          ),
        ),
      ],
    ),
  );
}

class _BubbleLegend extends StatelessWidget {
  const _BubbleLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: <Color>[Colors.white, color]),
          boxShadow: <BoxShadow>[
            BoxShadow(color: color.withValues(alpha: .25), blurRadius: 7),
          ],
        ),
      ),
      const SizedBox(width: 7),
      Text(
        label,
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
    ],
  );
}

class _BubbleBurst {
  const _BubbleBurst({required this.center, required this.color});

  final Offset center;
  final Color color;
}

class _BubbleShooterPainter extends CustomPainter {
  const _BubbleShooterPainter({
    required this.cells,
    required this.columns,
    required this.currentColor,
    required this.nextColor,
    required this.aimPath,
    required this.shotFrom,
    required this.shotTo,
    required this.shotColor,
    required this.shotProgress,
    required this.shotInFlight,
    required this.paused,
    required this.popBursts,
    required this.popProgress,
  });

  final List<int?> cells;
  final int columns;
  final Color currentColor;
  final Color nextColor;
  final List<Offset> aimPath;
  final Offset shotFrom;
  final Offset shotTo;
  final Color shotColor;
  final double shotProgress;
  final bool shotInFlight;
  final bool paused;
  final List<_BubbleBurst> popBursts;
  final double popProgress;

  Offset _center(int row, int column, double diameter) => Offset(
    (column + (row.isOdd ? 1 : .5)) * diameter,
    diameter * .5 + row * diameter * .8660254,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect panel = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(25),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF9FCFA),
            Color(0xFFEAF3EF),
            Color(0xFFE5F0EB),
          ],
        ).createShader(bounds),
    );
    canvas.save();
    canvas.clipRRect(panel);
    final Paint glow = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              const Color(0xFFB6DED1).withValues(alpha: .34),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .5, size.height * .17),
              radius: size.width * .72,
            ),
          );
    canvas.drawRect(bounds, glow);

    final double diameter = size.width / columns;
    final Paint ceiling = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0x00FFFFFF),
          Color(0xFFB6D6CB),
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromLTWH(10, 3, size.width - 20, 3));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 3, size.width - 24, 3),
        const Radius.circular(4),
      ),
      ceiling,
    );

    for (int row = 0; row < BubbleShooterPuzzle.maxRows; row++) {
      for (int column = 0; column < columns; column++) {
        final int? color = cells[row * columns + column];
        if (color == null) continue;
        _drawBubble(
          canvas,
          _center(row, column, diameter),
          diameter * .46,
          _bubbleColor(color),
        );
      }
    }

    _drawPopBursts(canvas, diameter);

    if (!shotInFlight && aimPath.length > 1) {
      final Paint guide = Paint()..color = _accent.withValues(alpha: .44);
      for (int index = 1; index < aimPath.length - 1; index += 2) {
        canvas.drawCircle(
          aimPath[index],
          math.max(1.6, diameter * .045),
          guide,
        );
      }
      canvas.drawCircle(
        aimPath.last,
        diameter * .16,
        Paint()..color = _accent.withValues(alpha: .15),
      );
    }

    final Offset cannon = Offset(size.width / 2, size.height - 39);
    final Rect baseRect = Rect.fromCenter(
      center: cannon + const Offset(0, 17),
      width: diameter * 2.25,
      height: diameter * .58,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, Radius.circular(diameter * .28)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFF74BBA9),
            Color(0xFF318C82),
            Color(0xFF26796F),
          ],
        ).createShader(baseRect),
    );
    final Offset launchDirection = aimPath.length > 1
        ? (aimPath[1] - aimPath.first) / (aimPath[1] - aimPath.first).distance
        : const Offset(0, -1);
    canvas.save();
    canvas.translate(
      cannon.dx + launchDirection.dx * diameter * .46,
      cannon.dy + launchDirection.dy * diameter * .46,
    );
    canvas.rotate(
      math.atan2(launchDirection.dy, launchDirection.dx) + math.pi / 2,
    );
    final Rect barrel = Rect.fromCenter(
      center: Offset.zero,
      width: diameter * .56,
      height: diameter * 1.16,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barrel, Radius.circular(diameter * .2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Color(0xFF26796F),
            Color(0xFF6FB7A6),
            Color(0xFF26796F),
          ],
        ).createShader(barrel),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        barrel.deflate(diameter * .13),
        Radius.circular(diameter * .14),
      ),
      Paint()..color = const Color(0xFFD9EEE6),
    );
    canvas.restore();
    canvas.drawCircle(
      cannon,
      diameter * .47,
      Paint()..color = const Color(0xFF2B7D72),
    );
    canvas.drawCircle(
      cannon,
      diameter * .39,
      Paint()..color = const Color(0xFFE8F4EF),
    );
    if (shotInFlight) {
      final double t = Curves.easeOutCubic.transform(shotProgress);
      _drawBubble(
        canvas,
        Offset.lerp(shotFrom, shotTo, t)!,
        diameter * .44,
        shotColor,
      );
    } else {
      _drawBubble(canvas, cannon, diameter * .35, currentColor);
    }
    _drawBubble(
      canvas,
      Offset(size.width - diameter * .55, size.height - diameter * .45),
      diameter * .20,
      nextColor,
    );

    if (paused) {
      canvas.drawRRect(panel, Paint()..color = const Color(0xCCF3F6F3));
      final TextPainter painter = TextPainter(
        text: const TextSpan(
          text: 'Ⅱ',
          style: TextStyle(
            color: _ink,
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          (size.width - painter.width) / 2,
          (size.height - painter.height) / 2,
        ),
      );
    }
    canvas.restore();
    canvas.drawRRect(
      panel,
      Paint()
        ..color = const Color(0xFFD8E7E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  Color _bubbleColor(int index) => switch (index % 6) {
    0 => const Color(0xFF18A999),
    1 => const Color(0xFFFF796C),
    2 => const Color(0xFFF0B94C),
    3 => const Color(0xFF8B78D2),
    4 => const Color(0xFF5598D4),
    _ => const Color(0xFF6BAE72),
  };

  void _drawPopBursts(Canvas canvas, double diameter) {
    if (popBursts.isEmpty) return;
    final double squashProgress = (popProgress / .28).clamp(0.0, 1.0);
    final double ringProgress = ((popProgress - .08) / .7).clamp(0.0, 1.0);
    final double sparkleProgress = ((popProgress - .28) / .72).clamp(0.0, 1.0);
    for (final _BubbleBurst burst in popBursts) {
      if (popProgress < .28) {
        final double radius = diameter * .46 * (1 - squashProgress * .35);
        canvas.drawCircle(
          burst.center,
          radius,
          Paint()
            ..color = Color.lerp(
              burst.color,
              Colors.white,
              .42,
            )!.withValues(alpha: (1 - squashProgress) * .8),
        );
      }
      if (popProgress >= .08) {
        final double radius = diameter * (.18 + ringProgress * .78);
        canvas.drawCircle(
          burst.center,
          radius,
          Paint()
            ..color = burst.color.withValues(alpha: (1 - ringProgress) * .72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.4, diameter * .045 * (1 - ringProgress)),
        );
      }
      if (popProgress >= .28) {
        final double travel = diameter * (.18 + sparkleProgress * .64);
        final double alpha = (1 - sparkleProgress).clamp(0.0, 1.0);
        for (int spark = 0; spark < 4; spark++) {
          final double angle = spark * math.pi / 2 + math.pi / 4;
          canvas.drawCircle(
            burst.center + Offset(math.cos(angle), math.sin(angle)) * travel,
            math.max(1.2, diameter * .055 * alpha),
            Paint()..color = Colors.white.withValues(alpha: alpha),
          );
        }
      }
    }
  }

  void _drawBubble(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center.translate(0, radius * .10),
      radius * .99,
      Paint()
        ..color = const Color(0xFF244943).withValues(alpha: .14)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .18),
    );
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.34, -.43),
          radius: 1.12,
          colors: <Color>[
            Color.lerp(color, Colors.white, .84)!,
            Color.lerp(color, Colors.white, .28)!,
            color,
            Color.lerp(color, const Color(0xFF153A43), .28)!,
          ],
          stops: const <double>[0, .24, .72, 1],
        ).createShader(rect),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        center.dx - radius * .52,
        center.dy - radius * .64,
        radius * .52,
        radius * .22,
      ),
      Paint()..color = Colors.white.withValues(alpha: .74),
    );
    canvas.drawCircle(
      center + Offset(radius * .37, radius * .40),
      radius * .075,
      Paint()..color = Colors.white.withValues(alpha: .36),
    );
  }

  static const Color _accent = Color(0xFF318C82);
  static const Color _ink = Color(0xFF263C3C);

  @override
  bool shouldRepaint(covariant _BubbleShooterPainter oldDelegate) => true;
}
