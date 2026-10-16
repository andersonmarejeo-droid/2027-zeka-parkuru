import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../games/shared/content_seed.dart';
import '../../games/shared/game_audio_profile.dart';
import '../../games/shared/parkur_game_kit.dart';
import '../../games/shared/studio_game_contracts.dart';
import '../../games/shared/studio_game_session.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/studio_game_skin.dart';
import 'flow_connect_puzzle.dart';

/// S02 — connect same-colour terminals without letting paths cross.
class FlowConnectGamePage extends StatelessWidget {
  const FlowConnectGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    10,
    (int index) => ParkurLevelSpec(
      number: index + 1,
      titleTr: 'Bağlantı ${index + 1}',
      titleEn: 'Connection ${index + 1}',
      subtitleTr: index < 3
          ? 'Aynı renkteki iki ucu bağla'
          : 'Yollar kesişmeden tüm uçları birleştir',
      subtitleEn: index < 3
          ? 'Connect the matching terminals'
          : 'Connect every terminal without crossings',
      difficulty: index < 3
          ? 'BAŞLANGIÇ'
          : index < 7
          ? 'ODAK'
          : 'USTA',
      icon: Icons.device_hub_rounded,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.logic);
    return ParkurLevelHub(
      gameId: 'flow_connect',
      progressPrefix: 'flow_connect',
      titleTr: 'Akış Bağlantısı',
      titleEn: 'Flow Connect',
      taglineTr: 'Yollar kesişmeden bağla',
      taglineEn: 'Connect without crossings',
      accent: skin.accent,
      icon: Icons.device_hub_rounded,
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
          ) => FlowConnectPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            fixedSessionSeed: competitionLayoutCode,
            competitionMode: competitionMode,
          ),
    );
  }
}

class FlowConnectPlayPage extends StatefulWidget {
  const FlowConnectPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  @override
  State<FlowConnectPlayPage> createState() => _FlowConnectPlayPageState();
}

class _FlowConnectPlayPageState extends State<FlowConnectPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );

  late final FlowPuzzle _puzzle;
  late final StudioGameSession _session;
  final Map<int, List<int>> _paths = <int, List<int>>{};

  int? _activePairId;
  int? _activePointer;
  int _moves = 0;
  int _hints = 0;
  bool _resultPending = false;

  @override
  void initState() {
    super.initState();
    _puzzle = FlowPuzzle.forLevel(widget.level.number);
    _session = StudioGameSession(
      level: widget.level.number,
      seed:
          widget.fixedSessionSeed ??
          ContentSeed.forLevel(
            gameId: 'flow_connect',
            level: widget.level.number,
          ),
    );
    _session.start();
    unawaited(_audioProfile.preload(_audio));
  }

  int? _cellAt(Offset position, Size boardSize) {
    final double cellSize = boardSize.width / _puzzle.size;
    final int column = position.dx ~/ cellSize;
    final int row = position.dy ~/ cellSize;
    if (column < 0 ||
        row < 0 ||
        column >= _puzzle.size ||
        row >= _puzzle.size) {
      return null;
    }
    return row * _puzzle.size + column;
  }

  void _onPointerDown(PointerDownEvent event, Size boardSize) {
    if (_activePointer != null || _resultPending || !_session.acceptsInput) {
      return;
    }
    final int? cell = _cellAt(event.localPosition, boardSize);
    if (cell == null) return;
    final FlowPair? pair = _puzzle.pairForEndpoint(cell);
    if (pair == null) {
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.rejected, gain: 0.46),
      );
      return;
    }

    setState(() {
      _activePointer = event.pointer;
      _activePairId = pair.id;
      _paths[pair.id] = <int>[cell];
    });
    _session.recordAccepted();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: 0.52),
    );
  }

  void _onPointerMove(PointerMoveEvent event, Size boardSize) {
    if (event.pointer != _activePointer || _activePairId == null) return;
    final int? next = _cellAt(event.localPosition, boardSize);
    if (next == null) return;
    _extendTo(next);
  }

  void _onPointerEnd(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    setState(() {
      _activePointer = null;
      _activePairId = null;
    });
  }

  void _extendTo(int candidate) {
    final int? pairId = _activePairId;
    if (pairId == null || _resultPending) return;
    final FlowPair pair = _puzzle.pairs.firstWhere(
      (FlowPair value) => value.id == pairId,
    );
    final List<int> activePath = List<int>.from(_paths[pairId] ?? <int>[]);
    if (activePath.isEmpty || candidate == activePath.last) return;

    if (!_puzzle.areAdjacent(activePath.last, candidate)) {
      return;
    }

    final int previousIndex = activePath.indexOf(candidate);
    if (previousIndex >= 0) {
      setState(() => _paths[pairId] = activePath.sublist(0, previousIndex + 1));
      return;
    }

    final FlowPair? endpointOwner = _puzzle.pairForEndpoint(candidate);
    final bool usedByAnotherPath = _paths.entries.any(
      (MapEntry<int, List<int>> entry) =>
          entry.key != pairId && entry.value.contains(candidate),
    );
    if ((endpointOwner != null && endpointOwner.id != pairId) ||
        usedByAnotherPath) {
      _audio.hapticLight();
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.rejected, gain: 0.48),
      );
      return;
    }

    activePath.add(candidate);
    _moves++;
    _session.recordAccepted();
    final bool connected = _puzzle.isConnected(pair, activePath);
    setState(() {
      _paths[pairId] = activePath;
      if (connected) {
        _activePairId = null;
        _activePointer = null;
      }
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: 0.35),
    );

    if (_puzzle.isComplete(_paths)) {
      _completeLevel();
    }
  }

  void _showHint() {
    if (_resultPending || !_session.canUseHint) return;
    final int remainingPairs = _puzzle.pairs
        .where((FlowPair pair) => !_puzzle.isConnected(pair, _paths[pair.id]))
        .length;
    if (remainingPairs <= 1) return;
    final FlowPair pair = _puzzle.pairs.firstWhere(
      (FlowPair value) => !_puzzle.isConnected(value, _paths[value.id]),
      orElse: () => _puzzle.pairs.first,
    );
    setState(() {
      _paths[pair.id] = List<int>.from(pair.solution);
      _hints++;
      _activePairId = null;
      _activePointer = null;
    });
    _session.useHint();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: 0.60));
    if (_puzzle.isComplete(_paths)) _completeLevel();
  }

  void _reset() {
    if (_resultPending) return;
    setState(() {
      _paths.clear();
      _activePairId = null;
      _activePointer = null;
      _moves = 0;
      _hints = 0;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: 0.48));
  }

  int _stars() {
    final int extraMoves = math.max(0, _moves - _puzzle.optimalMoves);
    int stars = extraMoves <= 2
        ? 3
        : extraMoves <= _puzzle.size * 2
        ? 2
        : 1;
    if (_hints > 0) stars = math.min(stars, 2);
    return stars;
  }

  int _score() {
    return math.max(
      100,
      1300 + _puzzle.pairs.length * 80 - _moves * 25 - _hints * 180,
    );
  }

  Future<void> _completeLevel() async {
    if (_resultPending || !_session.acceptsInput) return;
    _resultPending = true;
    _audio.hapticMedium();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .38),
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    final bool canGoNext = widget.level.number < 10;
    final int stars = _stars();
    final int score = _score();
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: canGoNext ? StudioResultAction.next : StudioResultAction.map,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _FlowResultDialog(
          stars: stars,
          score: score,
          moves: _moves,
          optimalMoves: _puzzle.optimalMoves,
          onReplay: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop(
              StudioGameResult.completed(
                score: score,
                stars: stars,
                action: StudioResultAction.replay,
              ).toParkurResult(),
            );
          },
          onContinue: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop(result.toParkurResult());
          },
          continueLabel: canGoNext ? 'SONRAKİ' : 'HARİTAYA DÖN',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.logic);
    final int completedPairs = _puzzle.pairs
        .where((FlowPair pair) => _puzzle.isConnected(pair, _paths[pair.id]))
        .length;

    return Scaffold(
      backgroundColor: skin.boardBackground,
      appBar: AppBar(
        backgroundColor: skin.boardBackground,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'AKIŞ BAĞLANTISI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              'BÖLÜM ${widget.level.number}  •  ${_puzzle.size}×${_puzzle.size}',
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'İpucu',
            onPressed: _showHint,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            tooltip: 'Sıfırla',
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 560,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: _FlowStatusStrip(
                  completedPairs: completedPairs,
                  totalPairs: _puzzle.pairs.length,
                  moves: _moves,
                  bestScore: widget.previousBestScore,
                  accent: skin.accent,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(
                  'Aynı renkteki uçları bağla. Başka bir yolun veya rengin üzerinden geçme.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints limits) {
                          final Size boardSize = Size.square(
                            math.min(limits.maxWidth, limits.maxHeight),
                          );
                          return Semantics(
                            label: 'Akış bağlantısı oyun tahtası',
                            child: Listener(
                              onPointerDown: (PointerDownEvent event) =>
                                  _onPointerDown(event, boardSize),
                              onPointerMove: (PointerMoveEvent event) =>
                                  _onPointerMove(event, boardSize),
                              onPointerUp: _onPointerEnd,
                              onPointerCancel: _onPointerEnd,
                              child: CustomPaint(
                                key: const ValueKey<String>(
                                  'flow_connect_board',
                                ),
                                painter: _FlowBoardPainter(
                                  puzzle: _puzzle,
                                  paths: _paths,
                                  activePairId: _activePairId,
                                  boardColor: skin.boardSurface,
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('SIFIRLA'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          minimumSize: const Size.fromHeight(
                            GameInputPolicy.minimumTargetSize,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _showHint,
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: const Text('İPUCU'),
                        style: FilledButton.styleFrom(
                          backgroundColor: skin.accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(
                            GameInputPolicy.minimumTargetSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowStatusStrip extends StatelessWidget {
  const _FlowStatusStrip({
    required this.completedPairs,
    required this.totalPairs,
    required this.moves,
    required this.bestScore,
    required this.accent,
  });

  final int completedPairs;
  final int totalPairs;
  final int moves;
  final int bestScore;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: StudioVisuals.compactRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: <Widget>[
          _FlowMetric(
            icon: Icons.device_hub_rounded,
            label: 'BAĞLANTI',
            value: '$completedPairs/$totalPairs',
            color: accent,
          ),
          const SizedBox(width: 18),
          _FlowMetric(
            icon: Icons.touch_app_outlined,
            label: 'HAMLE',
            value: '$moves',
            color: StudioVisuals.amber,
          ),
          const Spacer(),
          if (bestScore > 0)
            _FlowMetric(
              icon: Icons.stars_outlined,
              label: 'REKOR',
              value: '$bestScore',
              color: Colors.white70,
            ),
        ],
      ),
    );
  }
}

class _FlowMetric extends StatelessWidget {
  const _FlowMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlowBoardPainter extends CustomPainter {
  const _FlowBoardPainter({
    required this.puzzle,
    required this.paths,
    required this.activePairId,
    required this.boardColor,
  });

  final FlowPuzzle puzzle;
  final Map<int, List<int>> paths;
  final int? activePairId;
  final Color boardColor;

  Offset _centerFor(int cell, double cellSize) {
    return Offset(
      (cell % puzzle.size + 0.5) * cellSize,
      (cell ~/ puzzle.size + 0.5) * cellSize,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / puzzle.size;
    final RRect board = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    );
    canvas.drawRRect(board, Paint()..color = boardColor);
    canvas.save();
    canvas.clipRRect(board);

    for (int row = 0; row < puzzle.size; row++) {
      for (int column = 0; column < puzzle.size; column++) {
        final Rect cell = Rect.fromLTWH(
          column * cellSize + cellSize * 0.055,
          row * cellSize + cellSize * 0.055,
          cellSize * 0.89,
          cellSize * 0.89,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(cell, Radius.circular(cellSize * 0.18)),
          Paint()..color = Colors.white.withValues(alpha: 0.035),
        );
      }
    }

    for (final FlowPair pair in puzzle.pairs) {
      final List<int>? path = paths[pair.id];
      if (path == null || path.length < 2) continue;
      final Paint halo = Paint()
        ..color = pair.color.withValues(
          alpha: pair.id == activePairId ? 0.24 : 0.14,
        )
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.42;
      final Paint line = Paint()
        ..color = pair.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.23;
      final Path drawPath = Path()
        ..moveTo(
          _centerFor(path.first, cellSize).dx,
          _centerFor(path.first, cellSize).dy,
        );
      for (int index = 1; index < path.length; index++) {
        final Offset point = _centerFor(path[index], cellSize);
        drawPath.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(drawPath, halo);
      canvas.drawPath(drawPath, line);
    }

    for (final FlowPair pair in puzzle.pairs) {
      for (final int endpoint in <int>[pair.start, pair.end]) {
        final Offset center = _centerFor(endpoint, cellSize);
        canvas.drawCircle(
          center,
          cellSize * 0.29,
          Paint()..color = pair.color.withValues(alpha: 0.22),
        );
        canvas.drawCircle(center, cellSize * 0.18, Paint()..color = pair.color);
        canvas.drawCircle(
          center.translate(-cellSize * 0.045, -cellSize * 0.045),
          cellSize * 0.045,
          Paint()..color = Colors.white.withValues(alpha: 0.75),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlowBoardPainter oldDelegate) => true;
}

class _FlowResultDialog extends StatelessWidget {
  const _FlowResultDialog({
    required this.stars,
    required this.score,
    required this.moves,
    required this.optimalMoves,
    required this.onReplay,
    required this.onContinue,
    required this.continueLabel,
  });

  final int stars;
  final int score;
  final int moves;
  final int optimalMoves;
  final VoidCallback onReplay;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF202145),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white12),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.auto_awesome_rounded,
              color: StudioVisuals.amber,
              size: 36,
            ),
            const SizedBox(height: 9),
            const Text(
              'AKIŞ TAMAMLANDI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                3,
                (int index) => Icon(
                  index < stars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: StudioVisuals.amber,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ResultMetric(label: 'PUAN', value: '$score'),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ResultMetric(label: 'HAMLE', value: '$moves'),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ResultMetric(label: 'HEDEF', value: '$optimalMoves'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReplay,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      minimumSize: const Size.fromHeight(
                        GameInputPolicy.minimumTargetSize,
                      ),
                    ),
                    child: const Text('TEKRAR'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: StudioVisuals.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(
                        GameInputPolicy.minimumTargetSize,
                      ),
                    ),
                    child: Text(continueLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
