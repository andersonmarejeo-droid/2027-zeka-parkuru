import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'beam_director_puzzle.dart';

class BeamDirectorGamePage extends StatelessWidget {
  const BeamDirectorGamePage({
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
      titleTr: 'Işın ${index + 1}',
      titleEn: 'Beam ${index + 1}',
      subtitleTr: 'Aynaları çevir, ışını hedefe ulaştır',
      subtitleEn: 'Turn mirrors and guide the beam to its target',
      difficulty: index < 3
          ? 'BAŞLANGIÇ'
          : index < 7
          ? 'ODAK'
          : 'USTA',
      icon: Icons.light_mode_rounded,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.logic);
    return ParkurLevelHub(
      gameId: 'beam_director',
      progressPrefix: 'beam_director',
      titleTr: 'Işın Yönlendir',
      titleEn: 'Beam Director',
      taglineTr: 'Işığı doğru rotaya yönlendir',
      taglineEn: 'Guide light along the right route',
      accent: skin.accent,
      icon: Icons.light_mode_rounded,
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
          ) => BeamDirectorPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class BeamDirectorPlayPage extends StatefulWidget {
  const BeamDirectorPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<BeamDirectorPlayPage> createState() => _BeamDirectorPlayPageState();
}

class _BeamDirectorPlayPageState extends State<BeamDirectorPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  late final BeamDirectorPuzzle _puzzle;
  late final StudioGameSession _session;
  late List<bool> _mirrorStates;
  int _moves = 0;
  int _hints = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _puzzle = BeamDirectorPuzzle.forLevel(widget.level.number);
    _mirrorStates = _puzzle.initialStates;
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  BeamTrace get _trace => _puzzle.trace(_mirrorStates);

  int get _minimumMoves {
    int result = 0;
    for (int index = 0; index < _puzzle.mirrors.length; index++) {
      if (_puzzle.initialStates[index] != _puzzle.solvedStates[index]) result++;
    }
    return result;
  }

  void _turnMirror(int cell) {
    if (_finished) return;
    final int index = _puzzle.mirrors.indexWhere(
      (BeamMirror mirror) => mirror.cell == cell,
    );
    if (index < 0) return;
    setState(() {
      _mirrorStates[index] = !_mirrorStates[index];
      _moves++;
    });
    _session.recordAccepted();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .5),
    );
    if (_trace.reachesTarget) _complete();
  }

  void _hint() {
    if (_finished || !_session.canUseHint) return;
    final int index = List<int>.generate(_puzzle.mirrors.length, (int i) => i)
        .firstWhere(
          (int i) => _mirrorStates[i] != _puzzle.solvedStates[i],
          orElse: () => -1,
        );
    if (index < 0) return;
    setState(() {
      _mirrorStates[index] = _puzzle.solvedStates[index];
      _hints++;
    });
    _session.useHint();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .58));
    if (_trace.reachesTarget) _complete();
  }

  void _reset() {
    if (_finished) return;
    setState(() {
      _mirrorStates = _puzzle.initialStates;
      _moves = 0;
      _hints = 0;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .48));
  }

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    final int extraMoves = math.max(0, _moves - _minimumMoves);
    int stars = extraMoves <= 1
        ? 3
        : extraMoves <= 5
        ? 2
        : 1;
    if (_hints > 0) stars = math.min(stars, 2);
    final int score = math.max(100, 1250 - _moves * 28 - _hints * 170);
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
          'IŞIN HEDEFTE',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          '$stars ⭐  •  $score puan\n$_moves hamle ile ışık hedefe ulaştı.',
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
    final BeamTrace trace = _trace;
    return Scaffold(
      backgroundColor: skin.boardBackground,
      appBar: AppBar(
        backgroundColor: skin.boardBackground,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('IŞIN YÖNLENDİR • ${widget.level.number}'),
        actions: <Widget>[
          IconButton(
            onPressed: _hint,
            tooltip: 'İpucu',
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            onPressed: _reset,
            tooltip: 'Sıfırla',
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
                child: _BeamStatus(
                  reachesTarget: trace.reachesTarget,
                  moves: _moves,
                  best: widget.previousBestScore,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Aynalara dokunarak yönlerini değiştir. Işık, sarı kaynaktan teal hedefe ulaşmalı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _BeamBoard(
                        puzzle: _puzzle,
                        mirrorStates: _mirrorStates,
                        trace: trace,
                        onTap: _turnMirror,
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
                  label: const Text('BİR AYNAYI DÜZELT'),
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

class _BeamStatus extends StatelessWidget {
  const _BeamStatus({
    required this.reachesTarget,
    required this.moves,
    required this.best,
  });

  final bool reachesTarget;
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
          reachesTarget ? Icons.light_mode_rounded : Icons.light_mode_outlined,
          color: reachesTarget ? StudioVisuals.amber : Colors.white60,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            reachesTarget ? 'HEDEFE ULAŞTI' : 'IŞIN YOLDA',
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

class _BeamBoard extends StatelessWidget {
  const _BeamBoard({
    required this.puzzle,
    required this.mirrorStates,
    required this.trace,
    required this.onTap,
  });

  final BeamDirectorPuzzle puzzle;
  final List<bool> mirrorStates;
  final BeamTrace trace;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints limits) {
      final double cell = limits.maxWidth / puzzle.width;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (TapUpDetails details) {
          final int column = details.localPosition.dx ~/ cell;
          final int row = details.localPosition.dy ~/ cell;
          if (column >= 0 &&
              row >= 0 &&
              column < puzzle.width &&
              row < puzzle.height) {
            onTap(row * puzzle.width + column);
          }
        },
        child: CustomPaint(
          key: const ValueKey<String>('beam_director_board'),
          painter: _BeamPainter(
            puzzle: puzzle,
            mirrorStates: mirrorStates,
            trace: trace,
          ),
          child: const SizedBox.expand(),
        ),
      );
    },
  );
}

class _BeamPainter extends CustomPainter {
  const _BeamPainter({
    required this.puzzle,
    required this.mirrorStates,
    required this.trace,
  });

  final BeamDirectorPuzzle puzzle;
  final List<bool> mirrorStates;
  final BeamTrace trace;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / puzzle.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(26)),
      Paint()..color = const Color(0xFFF8F7F1),
    );
    for (int index = 0; index < puzzle.cellCount; index++) {
      final Offset center = _centerFor(index, cell);
      final Rect tile = Rect.fromCenter(
        center: center,
        width: cell * .86,
        height: cell * .86,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile, Radius.circular(cell * .16)),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile, Radius.circular(cell * .16)),
        Paint()
          ..color = const Color(0xFFE8E7E0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    if (trace.cells.length > 1) {
      final Path path = Path()
        ..moveTo(
          _centerFor(trace.cells.first, cell).dx,
          _centerFor(trace.cells.first, cell).dy,
        );
      for (final int beamCell in trace.cells.skip(1)) {
        final Offset point = _centerFor(beamCell, cell);
        path.lineTo(point.dx, point.dy);
      }
      final Color beam = trace.reachesTarget
          ? StudioVisuals.teal
          : StudioVisuals.amber;
      canvas.drawPath(
        path,
        Paint()
          ..color = beam.withValues(alpha: .22)
          ..strokeWidth = cell * .18
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = beam
          ..strokeWidth = cell * .055
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    for (int index = 0; index < puzzle.mirrors.length; index++) {
      final BeamMirror mirror = puzzle.mirrors[index];
      final Offset center = _centerFor(mirror.cell, cell);
      final double edge = cell * .27;
      final Paint mirrorPaint = Paint()
        ..color = const Color(0xFF68758A)
        ..strokeWidth = cell * .07
        ..strokeCap = StrokeCap.round;
      final bool slash = mirrorStates[index];
      canvas.drawLine(
        slash ? center + Offset(-edge, edge) : center + Offset(-edge, -edge),
        slash ? center + Offset(edge, -edge) : center + Offset(edge, edge),
        mirrorPaint,
      );
      canvas.drawCircle(
        center,
        cell * .06,
        Paint()..color = const Color(0xFFF1F4F6),
      );
    }

    _drawTerminal(
      canvas,
      center: _centerFor(puzzle.sourceCell, cell),
      cell: cell,
      color: StudioVisuals.amber,
      icon: Icons.wb_sunny_rounded,
    );
    _drawTerminal(
      canvas,
      center: _centerFor(puzzle.targetCell, cell),
      cell: cell,
      color: StudioVisuals.teal,
      icon: Icons.center_focus_strong_rounded,
    );
  }

  Offset _centerFor(int index, double cell) => Offset(
    ((index % puzzle.width) + .5) * cell,
    ((index ~/ puzzle.width) + .5) * cell,
  );

  void _drawTerminal(
    Canvas canvas, {
    required Offset center,
    required double cell,
    required Color color,
    required IconData icon,
  }) {
    canvas.drawCircle(
      center,
      cell * .27,
      Paint()..color = color.withValues(alpha: .16),
    );
    canvas.drawCircle(center, cell * .15, Paint()..color = color);
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: cell * .17,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _BeamPainter oldDelegate) => true;
}
