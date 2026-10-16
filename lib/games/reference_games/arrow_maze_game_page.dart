import '../shared/studio_game_contracts.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../games/shared/game_audio_profile.dart';
import '../../games/shared/parkur_game_kit.dart';
import '../../games/shared/studio_game_session.dart';
import '../../games/shared/studio_game_skin.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import 'arrow_maze_puzzle.dart';
import 'reference_game_support.dart';

class ArrowMazeGamePage extends StatelessWidget {
  const ArrowMazeGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });
  static const int totalCases = GameContentPolicy.campaignLevels;
  static const int totalStars = totalCases * 3;

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('arrow_maze');
    return ParkurLevelHub(
      gameId: 'arrow_maze',
      progressPrefix: 'arrow_maze',
      titleTr: 'Ok Labirenti',
      titleEn: 'Arrow Maze',
      taglineTr: 'Okları çevir, çıkışa giden rotayı kur',
      taglineEn: 'Turn the arrows and chart a route to the exit',
      accent: skin.accent,
      icon: Icons.alt_route_rounded,
      levels: referenceLevels(
        titleTr: 'Yön Labirenti',
        titleEn: 'Direction Maze',
        icon: Icons.alt_route_rounded,
        english: context.l10n.isEnglish,
      ),
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder: (
        BuildContext context,
        ParkurLevelSpec level,
        int best,
        int? layout,
        bool competition,
      ) => _ArrowMazePlayPage(
        level: level,
        dailyCourseMode: dailyCourseMode,
      ),
    );
  }
}

class _ArrowMazePlayPage extends StatefulWidget {
  const _ArrowMazePlayPage({required this.level, required this.dailyCourseMode});
  final ParkurLevelSpec level;
  final bool dailyCourseMode;
  @override
  State<_ArrowMazePlayPage> createState() => _ArrowMazePlayPageState();
}

class _ArrowMazePlayPageState extends State<_ArrowMazePlayPage> {
  static const Color _accent = Color(0xFF665AA2);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _profile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  late final StudioGameSession _session;
  ArrowMazePuzzle? _puzzle;
  List<MazeDirection> _arrows = <MazeDirection>[];
  final List<int> _trail = <int>[];
  bool _loading = true;
  bool _finished = false;
  bool _english = false;
  int get _current => _trail.isEmpty ? 0 : _trail.last;
  int get _moves => _trail.length - 1;

  @override
  void initState() {
    super.initState();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_profile.preload(_audio));
    unawaited(_prepare());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _english = context.l10n.isEnglish;
  }

  Future<void> _prepare() async {
    final int variant =
        widget.level.poolIndex ??
        await ReferenceRoundStore.reserve(
          gameId: 'arrow_maze',
          level: widget.level.number,
        );
    final ArrowMazePuzzle puzzle = ArrowMazePuzzle.generate(
      widget.level.contentLevel,
      variant,
    );
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _arrows = List<MazeDirection>.from(puzzle.arrows);
      _trail.add(0);
      _loading = false;
    });
  }

  int? _nextCell(int cell, MazeDirection direction) {
    return _puzzle!.nextCell(cell, direction);
  }

  bool _isWall(int cell, MazeDirection direction) {
    return _puzzle!.isWall(cell, direction);
  }

  void _rotate(int delta) {
    if (_finished || _puzzle == null) return;
    final int currentIndex = _arrows[_current].index;
    for (int step = 1; step <= MazeDirection.values.length; step++) {
      final int nextIndex =
          (currentIndex + delta * step + MazeDirection.values.length) %
          MazeDirection.values.length;
      final MazeDirection nextDirection = MazeDirection.values[nextIndex];
      if (_nextCell(_current, nextDirection) == null) continue;
      setState(() => _arrows[_current] = nextDirection);
      break;
    }
    _sound(GameAudioEvent.primaryAction);
  }

  void _advance() {
    if (_finished) return;
    final int? next = _nextCell(_current, _arrows[_current]);
    if (next == null) {
      _session.recordMistake();
      _sound(GameAudioEvent.rejected);
      return;
    }
    if (_trail.length > 1 && next == _trail[_trail.length - 2]) {
      _session.recordMistake();
    }
    setState(() => _trail.add(next));
    _session.recordAccepted(points: 8);
    _sound(GameAudioEvent.accepted);
    if (next == _puzzle!.width * _puzzle!.height - 1) unawaited(_finish());
  }

  void _undo() {
    if (_trail.length <= 1 || _finished) return;
    setState(() => _trail.removeLast());
    _sound(GameAudioEvent.primaryAction);
  }

  void _hint() {
    if (_finished || _puzzle == null || !_session.canUseHint) return;
    _session.useHint(pointCost: 40);
    final int pathIndex = _puzzle!.path.indexOf(_current);
    if (pathIndex >= 0 && pathIndex + 1 < _puzzle!.path.length) {
      final int next = _puzzle!.path[pathIndex + 1];
      final int directionIndex = MazeDirection.values.indexWhere(
        (MazeDirection d) => _nextCell(_current, d) == next,
      );
      if (directionIndex >= 0) {
        setState(
          () => _arrows[_current] = MazeDirection.values[directionIndex],
        );
      }
    }
    _sound(GameAudioEvent.hint);
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    final int optimal = _puzzle!.path.length - 1;
    final int stars = _moves <= optimal + 2
        ? 3
        : _moves <= optimal + widget.level.number
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: StudioResultAction.next,
    );
    _sound(GameAudioEvent.levelComplete);
    if (mounted) {
      Navigator.of(context).pop(
        widget.dailyCourseMode
            ? result.toDailyStageResult('arrow_maze')
            : result.toParkurResult(),
      );
    }
  }

  void _sound(GameAudioEvent event) => unawaited(
    _profile.play(
      _audio,
      event,
      gain: .32,
      levelNumber: event == GameAudioEvent.levelComplete
          ? widget.level.number
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading || _puzzle == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F6F3),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final ArrowMazePuzzle puzzle = _puzzle!;
    return ReferencePlayScaffold(
      title: _english ? 'Arrow Maze' : 'Ok Labirenti',
      level: widget.level.number,
      accent: _accent,
      english: _english,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReferenceCard(
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.alt_route_rounded, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _english
                            ? 'Steer the current tile'
                            : 'Bulunduğun oku yönlendir',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF26343A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _english
                            ? 'Rotate until the arrow enters an open passage, then move.'
                            : 'Ok açık bir koridora bakana kadar çevir, sonra ilerle.',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFF788780),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ReferenceCard(
            padding: 12,
            child: Column(
              children: <Widget>[
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double cell = constraints.maxWidth / puzzle.width;
                    final double boardSize = cell * puzzle.width;
                    return SizedBox(
                      width: boardSize,
                      height: boardSize,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: puzzle.width,
                        ),
                        itemCount: puzzle.width * puzzle.height,
                        itemBuilder: (BuildContext context, int index) {
                          final bool here = index == _current,
                              start = index == 0,
                              goal = index == puzzle.width * puzzle.height - 1;
                          final bool visited = _trail.contains(index);
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: here
                                  ? const Color(0xFFE7E2FA)
                                  : start
                                  ? const Color(0xFFE6F2ED)
                                  : goal
                                  ? const Color(0xFFFFF1D9)
                                  : visited
                                  ? const Color(0xFFF2EFFA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: here ? _accent : const Color(0xFFE1E7E3),
                                width: here ? 1.8 : 1,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                for (final MazeDirection d
                                    in MazeDirection.values)
                                  if (_isWall(index, d))
                                    Positioned(
                                      left: d == MazeDirection.left ? 0 : null,
                                      right: d == MazeDirection.right
                                          ? 0
                                          : null,
                                      top: d == MazeDirection.up ? 0 : null,
                                      bottom: d == MazeDirection.down
                                          ? 0
                                          : null,
                                      child: SizedBox(
                                        width:
                                            d == MazeDirection.left ||
                                                d == MazeDirection.right
                                            ? 5
                                            : null,
                                        height:
                                            d == MazeDirection.up ||
                                                d == MazeDirection.down
                                            ? 5
                                            : null,
                                        child: ColoredBox(
                                          color: const Color(0xFFB9C9C1),
                                        ),
                                      ),
                                    ),
                                if (here)
                                  Icon(
                                    _arrows[index].icon,
                                    color: _accent,
                                    size: 21,
                                  )
                                else if (start)
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Color(0xFF438C70),
                                    size: 20,
                                  )
                                else if (goal)
                                  const Icon(
                                    Icons.flag_rounded,
                                    color: Color(0xFFB68343),
                                    size: 17,
                                  )
                                else if (visited)
                                  const Icon(
                                    Icons.circle,
                                    color: Color(0xFF9A8DD8),
                                    size: 7,
                                  )
                                else
                                  Icon(
                                    _arrows[index].icon,
                                    color: const Color(0xFF9BAAA3),
                                    size: 16,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 11),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${_english ? 'Moves' : 'Hamle'}: $_moves  ·  ${_english ? 'Route target' : 'Rota hedefi'}: ${puzzle.path.length - 1}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Color(0xFF788780),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: _english ? 'Hint' : 'İpucu',
                      onPressed: _hint,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rotate(-1),
                        icon: const Icon(Icons.rotate_left_rounded),
                        label: Text(_english ? 'Turn left' : 'Sola çevir'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rotate(1),
                        icon: const Icon(Icons.rotate_right_rounded),
                        label: Text(_english ? 'Turn right' : 'Sağa çevir'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ReferencePrimaryButton(
                  label: _english ? 'Follow arrow' : 'Ok yönünde ilerle',
                  accent: _accent,
                  onPressed: _advance,
                  icon: Icons.arrow_forward_rounded,
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _trail.length <= 1 ? null : _undo,
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: Text(_english ? 'Undo move' : 'Son hamleyi geri al'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
