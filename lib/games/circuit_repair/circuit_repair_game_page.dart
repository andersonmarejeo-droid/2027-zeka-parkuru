import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import 'circuit_repair_puzzle.dart';

class CircuitRepairGamePage extends StatelessWidget {
  const CircuitRepairGamePage({
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
      titleTr: 'Devre ${index + 1}',
      titleEn: 'Circuit ${index + 1}',
      subtitleTr: 'Parçaları döndür, akımı hedefe ulaştır',
      subtitleEn: 'Rotate parts and power the target',
      difficulty: index < 3
          ? 'BAŞLANGIÇ'
          : index < 7
          ? 'ODAK'
          : 'USTA',
      icon: Icons.electric_bolt_rounded,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.logic);
    return ParkurLevelHub(
      gameId: 'circuit_repair',
      progressPrefix: 'circuit_repair',
      titleTr: 'Devre Tamiri',
      titleEn: 'Circuit Repair',
      taglineTr: 'Enerji yolunu onar',
      taglineEn: 'Restore the energy route',
      accent: skin.accent,
      icon: Icons.electric_bolt_rounded,
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
          ) => CircuitRepairPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class CircuitRepairPlayPage extends StatefulWidget {
  const CircuitRepairPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<CircuitRepairPlayPage> createState() => _CircuitRepairPlayPageState();
}

class _CircuitRepairPlayPageState extends State<CircuitRepairPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  late final CircuitPuzzle _puzzle;
  late final StudioGameSession _session;
  late List<int> _turns;
  int _moves = 0;
  int _hints = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _puzzle = CircuitPuzzle.forLevel(widget.level.number);
    _turns = List<int>.filled(_puzzle.cellCount, 0);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    );
    _session.start();
    unawaited(_audioProfile.preload(_audio));
  }

  List<int> get _masks => List<int>.generate(
    _puzzle.cellCount,
    (int cell) => _puzzle.rotateCurrentMask(cell, _turns[cell]),
  );

  void _rotate(int cell) {
    if (_finished || _puzzle.tiles[cell].isEmpty) return;
    setState(() {
      _turns[cell] = (_turns[cell] + 1) % 4;
      _moves++;
    });
    _session.recordAccepted();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: 0.52),
    );
    if (_puzzle.isTargetEnergized(_masks)) _complete();
  }

  void _hint() {
    if (_finished || !_session.canUseHint) return;
    final int cell = List<int>.generate(_puzzle.cellCount, (int index) => index)
        .firstWhere(
          (int index) =>
              !_puzzle.tiles[index].isEmpty &&
              _puzzle.rotateCurrentMask(index, _turns[index]) !=
                  _puzzle.solvedMaskAt(index),
          orElse: () => -1,
        );
    if (cell < 0) return;
    setState(() {
      _turns[cell] = (4 - _puzzle.tiles[cell].initialTurns) % 4;
      _hints++;
    });
    _session.useHint();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: 0.58));
    if (_puzzle.isTargetEnergized(_masks)) _complete();
  }

  void _reset() {
    if (_finished) return;
    setState(() {
      _turns = List<int>.filled(_puzzle.cellCount, 0);
      _moves = 0;
      _hints = 0;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: 0.48));
  }

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    final int extra = math.max(0, _moves - _puzzle.minimumTurns);
    int stars = extra <= 2
        ? 3
        : extra <= 8
        ? 2
        : 1;
    if (_hints > 0) stars = math.min(stars, 2);
    final int score = math.max(100, 1200 - _moves * 24 - _hints * 160);
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < 10
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticMedium();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .36),
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF202145),
        title: const Text(
          'DEVRE ÇALIŞIYOR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          '$stars ⭐  •  $score puan\n$_moves hamle ile hedefe enerji ulaştı.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(
                StudioGameResult.completed(
                  score: score,
                  stars: stars,
                  action: StudioResultAction.replay,
                ).toParkurResult(),
              );
            },
            child: const Text('TEKRAR'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(result.toParkurResult());
            },
            child: Text(widget.level.number < 10 ? 'SONRAKİ' : 'HARİTA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.logic);
    final bool powered = _puzzle.isTargetEnergized(_masks);
    return Scaffold(
      backgroundColor: skin.boardBackground,
      appBar: AppBar(
        backgroundColor: skin.boardBackground,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('DEVRE TAMİRİ • ${widget.level.number}'),
        actions: <Widget>[
          IconButton(
            onPressed: _hint,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 540,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: _CircuitStatus(
                  powered: powered,
                  moves: _moves,
                  best: widget.previousBestScore,
                ),
              ),
              const Text(
                'Her parçaya dokunarak 90° döndür. Enerji kaynaktan hedefe akmalı.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _CircuitBoard(
                        puzzle: _puzzle,
                        masks: _masks,
                        powered: powered,
                        onTap: _rotate,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: FilledButton.icon(
                  onPressed: _hint,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: const Text('BİR PARÇAYI DÜZELT'),
                  style: FilledButton.styleFrom(
                    backgroundColor: skin.accent,
                    minimumSize: const Size.fromHeight(
                      GameInputPolicy.minimumTargetSize,
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
}

class _CircuitStatus extends StatelessWidget {
  const _CircuitStatus({
    required this.powered,
    required this.moves,
    required this.best,
  });
  final bool powered;
  final int moves;
  final int best;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: StudioVisuals.compactRadius,
    ),
    child: Row(
      children: <Widget>[
        Icon(
          powered ? Icons.bolt_rounded : Icons.bolt_outlined,
          color: powered ? StudioVisuals.amber : Colors.white60,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            powered ? 'ENERJİ ULAŞTI' : 'AKIM BEKLİYOR',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          '$moves hamle${best > 0 ? '  •  $best rekor' : ''}',
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    ),
  );
}

class _CircuitBoard extends StatelessWidget {
  const _CircuitBoard({
    required this.puzzle,
    required this.masks,
    required this.powered,
    required this.onTap,
  });
  final CircuitPuzzle puzzle;
  final List<int> masks;
  final bool powered;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints limits) {
      final double cell = limits.maxWidth / puzzle.size;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (TapUpDetails details) {
          final int column = details.localPosition.dx ~/ cell;
          final int row = details.localPosition.dy ~/ cell;
          if (column >= 0 &&
              row >= 0 &&
              column < puzzle.size &&
              row < puzzle.size) {
            onTap(row * puzzle.size + column);
          }
        },
        child: CustomPaint(
          key: const ValueKey<String>('circuit_repair_board'),
          painter: _CircuitPainter(
            puzzle: puzzle,
            masks: masks,
            powered: powered,
          ),
          child: const SizedBox.expand(),
        ),
      );
    },
  );
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter({
    required this.puzzle,
    required this.masks,
    required this.powered,
  });
  final CircuitPuzzle puzzle;
  final List<int> masks;
  final bool powered;
  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / puzzle.size;
    final Paint panel = Paint()..color = const Color(0xFFF8F5EE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(26)),
      panel,
    );
    for (int index = 0; index < puzzle.cellCount; index++) {
      final int row = index ~/ puzzle.size;
      final int column = index % puzzle.size;
      final Offset center = Offset((column + .5) * cell, (row + .5) * cell);
      final Rect rect = Rect.fromCenter(
        center: center,
        width: cell * .86,
        height: cell * .86,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * .15)),
        Paint()..color = Colors.white,
      );
      final int mask = masks[index];
      final Color wire = powered ? StudioVisuals.teal : const Color(0xFF6F63C8);
      final Paint trace = Paint()
        ..color = wire
        ..strokeWidth = cell * .12
        ..strokeCap = StrokeCap.round;
      for (final CircuitDirection direction in CircuitDirection.values) {
        if ((mask & direction.bit) == 0) continue;
        canvas.drawLine(
          center,
          center + Offset(direction.dx * cell * .36, direction.dy * cell * .36),
          trace,
        );
      }
      if (mask != 0) canvas.drawCircle(center, cell * .09, trace);
      if (index == puzzle.source || index == puzzle.target) {
        final Color terminal = index == puzzle.source
            ? StudioVisuals.amber
            : StudioVisuals.teal;
        canvas.drawCircle(
          center,
          cell * .23,
          Paint()..color = terminal.withValues(alpha: .2),
        );
        canvas.drawCircle(center, cell * .12, Paint()..color = terminal);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter oldDelegate) => true;
}
