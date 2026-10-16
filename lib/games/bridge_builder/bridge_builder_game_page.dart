import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'bridge_builder_puzzle.dart';

class BridgeBuilderGamePage extends StatelessWidget {
  const BridgeBuilderGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = GameContentPolicy.minimumUniqueRounds;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) => ParkurLevelSpec(
      number: index + 1,
      titleTr: 'Ada ${'${index + 1}'.padLeft(3, '0')}',
      titleEn: 'Network ${'${index + 1}'.padLeft(3, '0')}',
      subtitleTr: 'Tüm adaları tek bir köprü ağına bağla',
      subtitleEn: 'Join every island into one bridge network',
      difficulty: index < 60
          ? 'MÜHENDİS ADAYI'
          : index < 130
          ? 'MÜHENDİS'
          : index < 220
          ? 'KIDEMLİ'
          : 'BAŞMÜHENDİS',
      icon: Icons.account_tree_rounded,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.logic);
    return ParkurLevelHub(
      gameId: 'bridge_builder',
      progressPrefix: 'bridge_builder',
      titleTr: 'Köprü Kur',
      titleEn: 'Bridge Builder',
      taglineTr: 'Köprüleri kurallara göre birleştir',
      taglineEn: 'Build a connected network by the rules',
      accent: skin.accent,
      icon: Icons.account_tree_rounded,
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
          ) => BridgeBuilderPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class BridgeBuilderPlayPage extends StatefulWidget {
  const BridgeBuilderPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<BridgeBuilderPlayPage> createState() => _BridgeBuilderPlayPageState();
}

class _BridgeBuilderPlayPageState extends State<BridgeBuilderPlayPage> {
  static const Color _ink = Color(0xFF293844);
  static const Color _board = Color(0xFFE9EEEC);
  static const Color _copper = Color(0xFFB47D58);
  static const Color _sage = Color(0xFF648D80);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  final List<List<int>> _undo = <List<int>>[];
  late final BridgeBuilderPuzzle _puzzle;
  late final StudioGameSession _session;
  late List<int> _values;
  bool _english = false;
  bool _finished = false;
  int? _selectedIsland;
  int? _hintedLink;
  int _moves = 0;
  int _hints = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = BridgeBuilderPuzzle.forLevel(widget.level.number);
    _values = List<int>.filled(_puzzle.links.length, 0);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  void _tapBoard(Offset localPosition, Size size) {
    if (_finished) return;
    final List<Offset> points = BridgeBoardGeometry.positions(_puzzle, size);
    for (int index = 0; index < points.length; index++) {
      if ((points[index] - localPosition).distance <
          BridgeBoardGeometry.islandRadius + 4) {
        setState(() {
          _selectedIsland = _selectedIsland == index ? null : index;
          _hintedLink = null;
        });
        unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .3));
        return;
      }
    }

    final int? link = BridgeBoardGeometry.linkAt(
      _puzzle,
      points,
      localPosition,
    );
    if (link == null) {
      setState(() => _selectedIsland = null);
      return;
    }
    final BridgeLink route = _puzzle.links[link];
    if (_selectedIsland != null &&
        route.first != _selectedIsland &&
        route.second != _selectedIsland) {
      setState(() => _selectedIsland = null);
    }
    final int next = (_values[link] + 1) % 3;
    if (next > 0 && _puzzle.wouldCross(link, _values)) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .4));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _english
                ? 'Bridges cannot cross. Choose a different route.'
                : 'Köprüler kesişemez. Başka bir güzergâh seç.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
        ),
      );
      return;
    }
    _setLink(link, next);
  }

  void _setLink(int index, int value) {
    if (_finished || _values[index] == value) return;
    setState(() {
      _undo.add(List<int>.from(_values));
      _values[index] = value;
      _moves++;
      _hintedLink = null;
    });
    _session.recordAccepted();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .3),
    );
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    final List<int> previous = _undo.removeLast();
    setState(() {
      _values = previous;
      _moves++;
      _hintedLink = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .35));
  }

  void _hint() {
    if (_finished || !_session.canUseHint) return;
    final int targetLink = List<int>.generate(_values.length, (int i) => i)
        .firstWhere(
          (int i) => _values[i] != _puzzle.solution[i],
          orElse: () => -1,
        );
    if (targetLink < 0) return;
    final int value = _puzzle.solution[targetLink];
    final List<int> corrected = List<int>.from(_values);
    for (int other = 0; other < corrected.length; other++) {
      if (other != targetLink &&
          _puzzle.crosses(targetLink, other) &&
          value > 0) {
        corrected[other] = 0;
      }
    }
    setState(() {
      _hints++;
      _undo.add(List<int>.from(_values));
      _values = corrected;
      _values[targetLink] = value;
      _hintedLink = targetLink;
      _selectedIsland = null;
    });
    _session.useHint(pointCost: 80);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .45));
  }

  void _reset() {
    if (_finished) return;
    setState(() {
      _values = List<int>.filled(_puzzle.links.length, 0);
      _undo.clear();
      _moves = 0;
      _hints = 0;
      _hintedLink = null;
      _selectedIsland = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .4));
  }

  Future<void> _checkNetwork() async {
    if (_finished) return;
    if (_puzzle.isSolved(_values)) {
      await _complete();
      return;
    }
    _session.recordMistake();
    final String message = _puzzle.hasCrossingBridge(_values)
        ? (_english
              ? 'Two bridges cross. Reroute one of them.'
              : 'İki köprü kesişiyor. Güzergâhlardan birini değiştir.')
        : !_puzzle.hasCorrectIslandTotals(_values)
        ? (_english
              ? 'Some islands still need a different bridge count.'
              : 'Bazı adaların köprü sayısı hedefe eşit değil.')
        : (_english
              ? 'The network is not connected yet.'
              : 'Ağ henüz bütün adalara ulaşmıyor.');
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .38));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    final int stars = _hints == 0
        ? 3
        : _hints == 1
        ? 2
        : 1;
    final int score = math.max(140, 1700 - _moves * 8 - _hints * 180);
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < BridgeBuilderGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticMedium();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .38),
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
        backgroundColor: _ink,
        title: Text(
          _english ? 'NETWORK CONNECTED' : 'AĞ TAMAMLANDI',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _english
              ? '$stars stars  •  $score points\nEvery island is connected.'
              : '$stars yıldız  •  $score puan\nTüm adalar tek ağa bağlandı.',
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
                  action: StudioResultAction.map,
                ).toParkurResult(),
              );
            },
            child: Text(_english ? 'MAP' : 'PARKUR'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(result.toParkurResult());
            },
            child: Text(
              widget.level.number < BridgeBuilderGamePage.totalCases
                  ? (_english ? 'NEXT ISLAND' : 'SONRAKİ ADA')
                  : (_english ? 'CASE BOARD' : 'DOSYA PANOSU'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    final int cycles = BridgeBuilderPuzzle.cyclesForLevel(widget.level.number);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F1),
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 10,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'BRIDGE BUILDER' : 'KÖPRÜ MÜHENDİSİ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            Text(
              _english
                  ? 'NETWORK ${widget.level.number.toString().padLeft(3, '0')}'
                  : 'ADA ${widget.level.number.toString().padLeft(3, '0')}',
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _hint,
            tooltip: _english ? 'Reveal one route' : 'Bir güzergâhı göster',
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            onPressed: _reset,
            tooltip: _english ? 'Reset network' : 'Ağı sıfırla',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 680,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
            children: <Widget>[
              _BridgeCaseHeader(
                level: widget.level.number,
                islandCount: _puzzle.islands.length,
                loopCount: cycles,
                moves: _moves,
                bestScore: widget.previousBestScore,
                english: _english,
              ),
              const SizedBox(height: 12),
              _BridgeInstructions(english: _english),
              const SizedBox(height: 14),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final Size boardSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return Semantics(
                              label: _english
                                  ? 'Bridge network puzzle. Tap a dashed route to cycle the bridge count.'
                                  : 'Köprü ağı bulmacası. Köprü sayısını değiştirmek için kesik güzergâha dokun.',
                              child: GestureDetector(
                                key: const ValueKey<String>(
                                  'bridge_builder_board',
                                ),
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (TapUpDetails details) =>
                                    _tapBoard(details.localPosition, boardSize),
                                child: _BridgeBoardSurface(
                                  puzzle: _puzzle,
                                  values: _values,
                                  selectedIsland: _selectedIsland,
                                  hintedLink: _hintedLink,
                                  size: boardSize,
                                  english: _english,
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _BridgeLegend(english: _english),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  _BridgeToolButton(
                    icon: Icons.undo_rounded,
                    label: _english ? 'UNDO' : 'GERİ AL',
                    onPressed: _undo.isEmpty ? null : _undoMove,
                  ),
                  const Spacer(),
                  _BridgeToolButton(
                    icon: Icons.lightbulb_outline_rounded,
                    label: _english ? 'HINT' : 'İPUCU',
                    onPressed: _hint,
                  ),
                  const Spacer(),
                  _BridgeToolButton(
                    icon: Icons.restart_alt_rounded,
                    label: _english ? 'RESET' : 'SIFIRLA',
                    onPressed: _reset,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey<String>('bridge_builder_check'),
                onPressed: _checkNetwork,
                icon: const Icon(Icons.hub_outlined),
                label: Text(
                  _english ? 'VERIFY NETWORK' : 'AĞI DOĞRULA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: StudioGameClass.logic.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(
                    GameInputPolicy.minimumTargetSize + 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
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

class BridgeBoardGeometry {
  const BridgeBoardGeometry._();

  static const double islandRadius = 10;
  static const double _gutter = 36;

  static List<Offset> positions(BridgeBuilderPuzzle puzzle, Size size) {
    final int minRow = puzzle.islands
        .map((BridgeIsland island) => island.point.row)
        .reduce(math.min);
    final int maxRow = puzzle.islands
        .map((BridgeIsland island) => island.point.row)
        .reduce(math.max);
    final int minColumn = puzzle.islands
        .map((BridgeIsland island) => island.point.column)
        .reduce(math.min);
    final int maxColumn = puzzle.islands
        .map((BridgeIsland island) => island.point.column)
        .reduce(math.max);
    final double rowSpan = math.max(1, maxRow - minRow).toDouble();
    final double columnSpan = math.max(1, maxColumn - minColumn).toDouble();
    final double scale = math.min(
      math.max(0, size.width - _gutter * 2) / columnSpan,
      math.max(0, size.height - _gutter * 2) / rowSpan,
    );
    final double contentWidth = columnSpan * scale;
    final double contentHeight = rowSpan * scale;
    final double left = (size.width - contentWidth) / 2;
    final double top = (size.height - contentHeight) / 2;
    return <Offset>[
      for (final BridgeIsland island in puzzle.islands)
        Offset(
          left + (island.point.column - minColumn) * scale,
          top + (island.point.row - minRow) * scale,
        ),
    ];
  }

  static int? linkAt(
    BridgeBuilderPuzzle puzzle,
    List<Offset> points,
    Offset tap,
  ) {
    int? closest;
    double closestDistance = 24;
    for (int index = 0; index < puzzle.links.length; index++) {
      final BridgeLink link = puzzle.links[index];
      final Offset start = points[link.first];
      final Offset end = points[link.second];
      final Offset vector = end - start;
      final double lengthSquared =
          vector.dx * vector.dx + vector.dy * vector.dy;
      final double t =
          (((tap - start).dx * vector.dx + (tap - start).dy * vector.dy) /
                  lengthSquared)
              .clamp(0.0, 1.0);
      final double distance = (tap - (start + vector * t)).distance;
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = index;
      }
    }
    return closest;
  }
}

class _BridgeBoardSurface extends StatelessWidget {
  const _BridgeBoardSurface({
    required this.puzzle,
    required this.values,
    required this.selectedIsland,
    required this.hintedLink,
    required this.size,
    required this.english,
  });

  final BridgeBuilderPuzzle puzzle;
  final List<int> values;
  final int? selectedIsland;
  final int? hintedLink;
  final Size size;
  final bool english;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _BridgeBuilderPlayPageState._board,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: const Color(0xFFD8DFDC)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: _BridgeBuilderPlayPageState._ink.withValues(alpha: .09),
          blurRadius: 19,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: .9),
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        size: size,
        painter: _BridgeBoardPainter(
          puzzle: puzzle,
          values: values,
          selectedIsland: selectedIsland,
          hintedLink: hintedLink,
          english: english,
        ),
      ),
    ),
  );
}

class _BridgeBoardPainter extends CustomPainter {
  _BridgeBoardPainter({
    required this.puzzle,
    required List<int> values,
    required this.selectedIsland,
    required this.hintedLink,
    required this.english,
  }) : values = List<int>.unmodifiable(values);

  final BridgeBuilderPuzzle puzzle;
  final List<int> values;
  final int? selectedIsland;
  final int? hintedLink;
  final bool english;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF1F4F1), Color(0xFFE3EAE7)],
        ).createShader(bounds),
    );
    final List<Offset> points = BridgeBoardGeometry.positions(puzzle, size);
    _drawGrid(canvas, size);
    _drawLinks(canvas, points);
    _drawIslands(canvas, points);
    _drawStamp(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..color = const Color(0xFF789087).withValues(alpha: .065)
      ..strokeWidth = .55;
    final double step = math.max(18, math.min(30, size.width / 12));
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final Paint glow = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: .58),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .48, size.height * .43),
              radius: size.shortestSide * .56,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
  }

  void _drawLinks(Canvas canvas, List<Offset> points) {
    for (int index = 0; index < puzzle.links.length; index++) {
      final BridgeLink link = puzzle.links[index];
      final Offset a = points[link.first];
      final Offset b = points[link.second];
      final Offset vector = b - a;
      final Offset unit = vector / vector.distance;
      final Offset start = a + unit * (BridgeBoardGeometry.islandRadius + 2);
      final Offset end = b - unit * (BridgeBoardGeometry.islandRadius + 2);
      final bool active = values[index] > 0;
      final Color candidateColor = index == hintedLink
          ? _BridgeBuilderPlayPageState._copper.withValues(alpha: .55)
          : const Color(0xFF70817D).withValues(alpha: .23);
      _drawDash(
        canvas,
        start,
        end,
        Paint()
          ..color = candidateColor
          ..strokeWidth = index == hintedLink ? 2 : 1.35
          ..strokeCap = StrokeCap.round,
      );
      if (!active) continue;
      final Offset normal = Offset(-unit.dy, unit.dx) * 4;
      final int count = values[index];
      for (int bridge = 0; bridge < count; bridge++) {
        final double offset = count == 1 ? 0 : (bridge == 0 ? -1 : 1);
        final Color bridgeColor = count == 1
            ? const Color(0xFF536C70)
            : _BridgeBuilderPlayPageState._copper;
        final Offset from = start + normal * offset;
        final Offset to = end + normal * offset;
        final Paint shadow = Paint()
          ..color = const Color(0xFF293844).withValues(alpha: .17)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          from + const Offset(0, 1.5),
          to + const Offset(0, 1.5),
          shadow,
        );
        canvas.drawLine(
          from,
          to,
          Paint()
            ..color = bridgeColor
            ..strokeWidth = 4.7
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          from,
          to,
          Paint()
            ..color = const Color(0xFFA3B5AE).withValues(alpha: .55)
            ..strokeWidth = 1
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawIslands(Canvas canvas, List<Offset> points) {
    for (int index = 0; index < points.length; index++) {
      final Offset center = points[index];
      final double radius = BridgeBoardGeometry.islandRadius;
      final bool selected = index == selectedIsland;
      final int current = _currentTotal(index);
      final int target = puzzle.islands[index].target;
      final Color face = current > target
          ? const Color(0xFFF4E5E0)
          : current == target
          ? const Color(0xFFE4F0EB)
          : const Color(0xFFFFFEFA);
      if (selected) {
        canvas.drawCircle(
          center,
          radius + 7,
          Paint()..color = StudioGameClass.logic.accent.withValues(alpha: .13),
        );
      }
      canvas.drawCircle(
        center + const Offset(0, 3),
        radius + 1,
        Paint()
          ..color = const Color(0xFF31474D).withValues(alpha: .16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.35, -.45),
            radius: .95,
            colors: <Color>[Color(0xFFFFFFFF), Color(0xFFE8ECE8)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawCircle(center, radius - 2, Paint()..color = face);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = selected
              ? StudioGameClass.logic.accent
              : const Color(0xFFC5D0CA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2 : 1,
      );
      _drawText(
        canvas,
        '$target',
        center + const Offset(0, -1.5),
        color: _BridgeBuilderPlayPageState._ink,
        size: 13,
        weight: FontWeight.w900,
      );
      if (current > 0) {
        _drawText(
          canvas,
          '$current',
          center + Offset(radius * .72, radius * .63),
          color: current == target
              ? _BridgeBuilderPlayPageState._sage
              : const Color(0xFFBD665E),
          size: 8,
          weight: FontWeight.w900,
        );
      }
    }
  }

  void _drawStamp(Canvas canvas, Size size) {
    final String stamp = english
        ? 'SURVEY • ${puzzle.islands.length} NODES'
        : 'KEŞİF • ${puzzle.islands.length} ADA';
    _drawText(
      canvas,
      stamp,
      Offset(size.width / 2, size.height - 15),
      color: const Color(0xFF71827E).withValues(alpha: .68),
      size: 8,
      weight: FontWeight.w800,
      letterSpacing: 1.15,
    );
  }

  int _currentTotal(int island) {
    int total = 0;
    for (int index = 0; index < puzzle.links.length; index++) {
      final BridgeLink link = puzzle.links[index];
      if (link.first == island || link.second == island) total += values[index];
    }
    return total;
  }

  static void _drawDash(Canvas canvas, Offset start, Offset end, Paint paint) {
    final Offset vector = end - start;
    final double distance = vector.distance;
    if (distance <= 0) return;
    final Offset direction = vector / distance;
    for (double offset = 0; offset < distance; offset += 8) {
      canvas.drawLine(
        start + direction * offset,
        start + direction * math.min(distance, offset + 3),
        paint,
      );
    }
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required Color color,
    required double size,
    required FontWeight weight,
    double letterSpacing = 0,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _BridgeBoardPainter oldDelegate) =>
      !listEquals(oldDelegate.values, values) ||
      oldDelegate.selectedIsland != selectedIsland ||
      oldDelegate.hintedLink != hintedLink ||
      oldDelegate.english != english;
}

class _BridgeCaseHeader extends StatelessWidget {
  const _BridgeCaseHeader({
    required this.level,
    required this.islandCount,
    required this.loopCount,
    required this.moves,
    required this.bestScore,
    required this.english,
  });

  final int level;
  final int islandCount;
  final int loopCount;
  final int moves;
  final int bestScore;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF344850), Color(0xFF263942)],
      ),
      borderRadius: BorderRadius.circular(21),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: _BridgeBuilderPlayPageState._ink.withValues(alpha: .16),
          blurRadius: 17,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: .13)),
          ),
          child: const Icon(
            Icons.account_tree_outlined,
            color: Color(0xFFD7B18A),
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'NETWORK CASE $level' : 'AĞ DOSYASI $level',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                english
                    ? '$islandCount islands  ·  $loopCount loops'
                    : '$islandCount ada  ·  $loopCount bağlı halka',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD0DCDA),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '${english ? 'MOVES' : 'HAMLE'} $moves',
              style: const TextStyle(
                color: Color(0xFFE4C49A),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
            Text(
              '${english ? 'BEST' : 'REKOR'} $bestScore',
              style: const TextStyle(
                color: Color(0xFFB6C3C1),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BridgeInstructions extends StatelessWidget {
  const _BridgeInstructions({required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFEFA),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE5E4DB)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.info_outline_rounded,
          color: _BridgeBuilderPlayPageState._copper,
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            english
                ? 'Tap a route to cycle 0–2 bridges. Match each island number; no crossings, one connected network.'
                : 'Güzergâha dokunarak 0–2 köprü kur. Ada sayılarını tuttur; kesişme olmasın, ağ bağlı kalsın.',
            style: const TextStyle(
              color: _BridgeBuilderPlayPageState._ink,
              fontSize: 10,
              height: 1.32,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BridgeLegend extends StatelessWidget {
  const _BridgeLegend({required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      _BridgeLegendItem(
        color: const Color(0xFF536C70),
        label: english ? 'Single' : 'Tek',
      ),
      const SizedBox(width: 18),
      _BridgeLegendItem(
        color: _BridgeBuilderPlayPageState._copper,
        label: english ? 'Double' : 'Çift',
      ),
      const SizedBox(width: 18),
      _BridgeLegendItem(
        color: const Color(0xFF899995),
        label: english ? 'Candidate' : 'Aday yol',
        dashed: true,
      ),
    ],
  );
}

class _BridgeLegendItem extends StatelessWidget {
  const _BridgeLegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(
        width: 18,
        child: dashed
            ? Icon(Icons.more_horiz_rounded, size: 17, color: color)
            : Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _BridgeToolButton extends StatelessWidget {
  const _BridgeToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 82,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _BridgeBuilderPlayPageState._ink,
        minimumSize: const Size(48, 55),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 19),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}
