import '../shared/studio_game_contracts.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../games/shared/game_audio_profile.dart';
import '../../games/shared/parkur_game_kit.dart';
import '../../games/shared/studio_game_session.dart';
import '../../games/shared/studio_game_skin.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import 'katamino_puzzle.dart';
import 'reference_game_support.dart';

class KataminoGamePage extends StatelessWidget {
  const KataminoGamePage({
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
    final StudioGameSkin skin = StudioGameSkin.forId('katamino_workshop');
    return ParkurLevelHub(
      gameId: 'katamino_workshop',
      progressPrefix: 'katamino_workshop',
      titleTr: 'Katamino Atölyesi',
      titleEn: 'Katamino Workshop',
      taglineTr: 'Poliomino parçalarını boşluğa yerleştir',
      taglineEn: 'Fit polyomino pieces into the board',
      accent: skin.accent,
      icon: Icons.extension_rounded,
      levels: referenceLevels(
        titleTr: 'Döşeme',
        titleEn: 'Tiling',
        icon: Icons.extension_rounded,
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
      ) => _KataminoPlayPage(
        level: level,
        dailyCourseMode: dailyCourseMode,
      ),
    );
  }
}

class _KataminoPlayPage extends StatefulWidget {
  const _KataminoPlayPage({required this.level, required this.dailyCourseMode});
  final ParkurLevelSpec level;
  final bool dailyCourseMode;
  @override
  State<_KataminoPlayPage> createState() => _KataminoPlayPageState();
}

class _KataminoPlayPageState extends State<_KataminoPlayPage> {
  static const Color _accent = Color(0xFF8E603B);
  static const List<Color> _palette = <Color>[
    Color(0xFFB67B48),
    Color(0xFFD19B5E),
    Color(0xFF94613E),
    Color(0xFFC58B56),
    Color(0xFF876044),
    Color(0xFFE0B979),
    Color(0xFFA66E43),
    Color(0xFFCA9563),
  ];
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _profile = GameAudioProfile.forClass(
    StudioGameClass.visual,
  );
  final List<List<int?>> _undo = <List<int?>>[];
  final GlobalKey _boardKey = GlobalKey();
  late final StudioGameSession _session;
  KataminoPuzzle? _puzzle;
  KataminoPlacement? _previewPlacement;
  List<int?> _board = <int?>[];
  bool _loading = true;
  bool _finished = false;
  bool _english = false;
  int? _selected;
  int _rotation = 0;
  bool _mirrored = false;
  int _moves = 0;
  String? _boardMessage;

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
          gameId: 'katamino_workshop',
          level: widget.level.number,
        );
    final KataminoPuzzle puzzle = KataminoPuzzle.generate(
      widget.level.contentLevel,
      variant,
    );
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _board = List<int?>.filled(puzzle.width * puzzle.height, null);
      _loading = false;
    });
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

  List<PolyCell> _shape(int piece) =>
      transformPolyomino(_puzzle!.pieces[piece], _rotation, _mirrored);

  KataminoPlacement? _placementAt(int x, int y) {
    final KataminoPuzzle? puzzle = _puzzle;
    final int? selected = _selected;
    if (puzzle == null || selected == null || _finished) return null;
    return findNearestKataminoPlacement(
      puzzle: puzzle,
      board: _board,
      piece: puzzle.pieces[selected],
      targetX: x,
      targetY: y,
      preferredRotation: _rotation,
      preferredMirror: _mirrored,
    );
  }

  void _previewAtCell(int x, int y) {
    if (_selected == null || _finished) return;
    final KataminoPlacement? placement = _placementAt(x, y);
    if (_samePlacement(_previewPlacement, placement)) return;
    setState(() => _previewPlacement = placement);
  }

  bool _samePlacement(KataminoPlacement? a, KataminoPlacement? b) =>
      a?.x == b?.x &&
      a?.y == b?.y &&
      a?.rotation == b?.rotation &&
      a?.mirrored == b?.mirrored;

  void _placeAtCell(int x, int y) {
    if (_selected == null || _finished) return;
    final KataminoPlacement? placement = _placementAt(x, y);
    if (placement == null) {
      _session.recordMistake();
      _sound(GameAudioEvent.rejected);
      setState(() {
        _previewPlacement = null;
        _boardMessage = _english
            ? 'No open fit remains for this piece. Undo a move and try another spot.'
            : 'Bu parçaya boş yer kalmadı. Bir hamleyi geri alıp başka yer deneyebilirsin.';
      });
      return;
    }
    _commitPlacement(placement);
  }

  void _commitPlacement(KataminoPlacement placement) {
    final int? selected = _selected;
    if (selected == null || _finished) return;
    _undo.add(List<int?>.from(_board));
    setState(() {
      for (final int index in placement.indices) {
        _board[index] = selected;
      }
      _selected = null;
      _rotation = 0;
      _mirrored = false;
      _previewPlacement = null;
      _boardMessage = null;
      _moves++;
    });
    _session.recordAccepted(points: 10);
    _sound(GameAudioEvent.accepted);
    if (_board.every((int? cell) => cell != null)) unawaited(_finish());
  }

  void _activateDraggedPiece(int index) {
    if (_finished || _board.contains(index)) return;
    if (_selected == index) return;
    setState(() {
      _selected = index;
      _rotation = 0;
      _mirrored = false;
      _previewPlacement = null;
      _boardMessage = null;
    });
    _sound(GameAudioEvent.primaryAction);
  }

  void _previewAtGlobalPosition(Offset globalPosition) {
    final RenderObject? renderObject = _boardKey.currentContext
        ?.findRenderObject();
    if (_selected == null || renderObject is! RenderBox) return;
    final Offset local = renderObject.globalToLocal(globalPosition);
    final KataminoPuzzle? puzzle = _puzzle;
    if (puzzle == null || renderObject.size.isEmpty) return;
    final int x = (local.dx / renderObject.size.width * puzzle.width)
        .floor()
        .clamp(0, puzzle.width - 1)
        .toInt();
    final int y = (local.dy / renderObject.size.height * puzzle.height)
        .floor()
        .clamp(0, puzzle.height - 1)
        .toInt();
    _previewAtCell(x, y);
  }

  void _placeAtGlobalPosition(Offset globalPosition) {
    final RenderObject? renderObject = _boardKey.currentContext
        ?.findRenderObject();
    final KataminoPuzzle? puzzle = _puzzle;
    if (renderObject is! RenderBox || puzzle == null) return;
    final Offset local = renderObject.globalToLocal(globalPosition);
    if (renderObject.size.isEmpty) return;
    final int x = (local.dx / renderObject.size.width * puzzle.width)
        .floor()
        .clamp(0, puzzle.width - 1)
        .toInt();
    final int y = (local.dy / renderObject.size.height * puzzle.height)
        .floor()
        .clamp(0, puzzle.height - 1)
        .toInt();
    _placeAtCell(x, y);
  }

  void _undoMove() {
    if (_undo.isEmpty || _finished) return;
    setState(() {
      _board = _undo.removeLast();
      _moves = max(0, _moves - 1);
    });
    _sound(GameAudioEvent.primaryAction);
  }

  void _selectPiece(int index) {
    if (_finished || _board.contains(index)) return;
    setState(() {
      _selected = _selected == index ? null : index;
      _rotation = 0;
      _mirrored = false;
      _previewPlacement = null;
      _boardMessage = null;
    });
    _sound(GameAudioEvent.primaryAction);
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    final int ideal = _puzzle!.pieces.length;
    final int stars = _moves <= ideal + 2
        ? 3
        : _moves <= ideal + widget.level.number
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
            ? result.toDailyStageResult('katamino_workshop')
            : result.toParkurResult(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _puzzle == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F6F3),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final KataminoPuzzle puzzle = _puzzle!;
    final String hint = _english
        ? 'Tap a board cell or hold a piece and drag it onto the board. It snaps to the nearest open fit.'
        : 'Parçayı seçip boş bir kareye dokun; ya da parçaya basılı tutup tahtaya sürükle. En yakın uygun yere oturur.';
    return ReferencePlayScaffold(
      title: _english ? 'Katamino Workshop' : 'Katamino Atölyesi',
      level: widget.level.number,
      accent: _accent,
      english: _english,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReferenceCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _english
                            ? 'Fill the silhouette'
                            : 'Tahtayı eksiksiz döşe',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF26343A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hint,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8EFF3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${puzzle.pieces.length} parça',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ReferenceCard(
            padding: 13,
            child: Column(
              children: <Widget>[
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double width = min(constraints.maxWidth, 440);
                    final double cell = width / puzzle.width;
                    final double height = cell * puzzle.height;
                    return Center(
                      child: Container(
                        width: width,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFFD2A36B),
                              Color(0xFF9A6840),
                              Color(0xFF744A2D),
                            ],
                            stops: <double>[0, .48, 1],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: const Color(0xFF654126),
                            width: 1.4,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x334A321D),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Color(0x55FFE1B1),
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              const CustomPaint(
                                painter: _WoodGrainPainter(
                                  seed: 9021,
                                  strength: .44,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(2),
                                child: DragTarget<int>(
                                  onWillAcceptWithDetails:
                                      (DragTargetDetails<int> details) {
                                        if (_finished ||
                                            _board.contains(details.data)) {
                                          return false;
                                        }
                                        _activateDraggedPiece(details.data);
                                        return true;
                                      },
                                  onMove: (DragTargetDetails<int> details) =>
                                      _previewAtGlobalPosition(details.offset),
                                  onLeave: (int? _) {
                                    if (_previewPlacement != null && mounted) {
                                      setState(() => _previewPlacement = null);
                                    }
                                  },
                                  onAcceptWithDetails:
                                      (DragTargetDetails<int> details) {
                                        _activateDraggedPiece(details.data);
                                        _placeAtGlobalPosition(details.offset);
                                      },
                                  builder:
                                      (
                                        BuildContext context,
                                        List<int?> candidateData,
                                        List<dynamic> rejectedData,
                                      ) => GridView.builder(
                                        key: _boardKey,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: puzzle.width,
                                            ),
                                        itemCount: _board.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                              final int x =
                                                      index % puzzle.width,
                                                  y = index ~/ puzzle.width;
                                              final int? piece = _board[index];
                                              final bool preview =
                                                  piece == null &&
                                                  (_previewPlacement?.indices
                                                          .contains(index) ??
                                                      false) &&
                                                  _selected != null;
                                              return GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTapDown: _selected == null
                                                    ? null
                                                    : (_) =>
                                                          _previewAtCell(x, y),
                                                onTap: () => _placeAtCell(x, y),
                                                child: _ParquetTile(
                                                  color: piece == null
                                                      ? preview
                                                            ? _palette[_selected! %
                                                                  _palette
                                                                      .length]
                                                            : const Color(
                                                                0xFFE5D0AC,
                                                              )
                                                      : _palette[piece %
                                                            _palette.length],
                                                  seed:
                                                      1409 +
                                                      index * 31 +
                                                      (piece ?? 0),
                                                  margin: const EdgeInsets.all(
                                                    1.3,
                                                  ),
                                                  isPreview: preview,
                                                ),
                                              );
                                            },
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _previewPlacement != null
                            ? (_english
                                  ? 'Nearest valid fit is highlighted'
                                  : 'Uygun yer yeşil ışıkla gösteriliyor')
                            : _selected == null
                            ? (_english
                                  ? 'Choose a piece below'
                                  : 'Aşağıdan bir parça seç')
                            : '${_english ? 'Selected piece' : 'Seçili parça'} ${_selected! + 1}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5E7069),
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: _english ? 'Rotate' : 'Döndür',
                      onPressed: _selected == null
                          ? null
                          : () {
                              setState(() {
                                _rotation = (_rotation + 1) % 4;
                                _previewPlacement = null;
                              });
                              _sound(GameAudioEvent.primaryAction);
                            },
                      icon: const Icon(Icons.rotate_right_rounded),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      tooltip: _english ? 'Mirror' : 'Aynala',
                      onPressed: _selected == null
                          ? null
                          : () {
                              setState(() {
                                _mirrored = !_mirrored;
                                _previewPlacement = null;
                              });
                              _sound(GameAudioEvent.primaryAction);
                            },
                      icon: const Icon(Icons.flip_rounded),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      tooltip: _english ? 'Undo' : 'Geri al',
                      onPressed: _undo.isEmpty ? null : _undoMove,
                      icon: const Icon(Icons.undo_rounded),
                    ),
                  ],
                ),
                if (_boardMessage != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _boardMessage!,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFFAD5745),
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          ReferenceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _english ? 'PIECES' : 'PARÇALAR',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    letterSpacing: 1.2,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7D8B85),
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    // Four compact columns keep every available piece visible
                    // together, while each card remains comfortably tappable.
                    const int columns = 4;
                    const double spacing = 6;
                    const double cardHeight = 76;
                    final double cardWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: puzzle.pieces.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            mainAxisExtent: cardHeight,
                          ),
                      itemBuilder: (BuildContext context, int index) {
                        final bool placed = _board.contains(index);
                        final bool active = _selected == index;
                        final List<PolyCell> previewCells = active
                            ? (_previewPlacement?.cells ?? _shape(index))
                            : puzzle.pieces[index];
                        final Widget pieceCard = InkWell(
                          onTap: placed ? null : () => _selectPiece(index),
                          borderRadius: BorderRadius.circular(11),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.all(5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: placed
                                  ? const Color(0xFFE5D7C4)
                                  : active
                                  ? const Color(0xFFF6E8D4)
                                  : const Color(0xFFFFFCF7),
                              border: Border.all(
                                color: active
                                    ? _accent
                                    : const Color(0xFFD5B895),
                                width: active ? 1.8 : 1,
                              ),
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0xFF754827).withValues(
                                    alpha: active ? .20 : .10,
                                  ),
                                  blurRadius: active ? 7 : 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Opacity(
                              opacity: placed ? .35 : 1,
                              child: _PolyominoPreview(
                                cells: previewCells,
                                color: _palette[index % _palette.length],
                                tileExtent: _pieceTileExtent(
                                  previewCells,
                                  maxWidth: cardWidth - 10,
                                  maxHeight: cardHeight - 10,
                                ),
                              ),
                            ),
                          ),
                        );
                        return LongPressDraggable<int>(
                          data: index,
                          maxSimultaneousDrags: placed ? 0 : 1,
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          onDragStarted: () => _activateDraggedPiece(index),
                          onDragEnd: (DraggableDetails details) {
                            if (mounted &&
                                !details.wasAccepted &&
                                _previewPlacement != null) {
                              setState(() => _previewPlacement = null);
                            }
                          },
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDFBF7),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _accent, width: 1.5),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x558D5A35),
                                    blurRadius: 14,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: _PolyominoPreview(
                                cells: active
                                    ? _shape(index)
                                    : puzzle.pieces[index],
                                color: _palette[index % _palette.length],
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: .32,
                            child: pieceCard,
                          ),
                          child: pieceCard,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_english ? 'Moves' : 'Hamle'}: $_moves   ·   ${_english ? 'Placed' : 'Yerleşen'}: ${_board.where((int? value) => value != null).length}/${_board.length}',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF798780),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  double _pieceTileExtent(
    List<PolyCell> cells, {
    required double maxWidth,
    required double maxHeight,
  }) {
    if (cells.isEmpty) return 16;
    final int width = cells.map((PolyCell cell) => cell.x).reduce(max) + 1;
    final int height = cells.map((PolyCell cell) => cell.y).reduce(max) + 1;
    return min(
      20.0,
      min(maxWidth / width, maxHeight / height),
    ).clamp(11.0, 20.0).toDouble();
  }
}

class _PolyominoPreview extends StatelessWidget {
  const _PolyominoPreview({
    required this.cells,
    required this.color,
    this.tileExtent = 20,
  });
  final List<PolyCell> cells;
  final Color color;
  final double tileExtent;
  @override
  Widget build(BuildContext context) {
    final int width = cells.map((PolyCell cell) => cell.x).reduce(max) + 1;
    final int height = cells.map((PolyCell cell) => cell.y).reduce(max) + 1;
    return SizedBox(
      width: width * tileExtent,
      height: height * tileExtent,
      child: Stack(
        children: cells
            .asMap()
            .entries
            .map((MapEntry<int, PolyCell> entry) {
              final int index = entry.key;
              final PolyCell cell = entry.value;
              return Positioned(
                left: cell.x * tileExtent,
                top: cell.y * tileExtent,
                child: SizedBox(
                  width: tileExtent,
                  height: tileExtent,
                  child: _ParquetTile(
                    color: color,
                    seed: 3803 + index * 23 + cell.x * 5 + cell.y,
                    radius: 4,
                    margin: const EdgeInsets.all(.6),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _ParquetTile extends StatelessWidget {
  const _ParquetTile({
    required this.color,
    required this.seed,
    this.margin = EdgeInsets.zero,
    this.radius = 5,
    this.isPreview = false,
  });

  final Color color;
  final int seed;
  final EdgeInsetsGeometry margin;
  final double radius;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final Color edge = Color.lerp(color, const Color(0xFF56371F), .34)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(color, const Color(0xFFFFE6BA), .30)!,
            Color.lerp(color, const Color(0xFFB56D35), .08)!,
            Color.lerp(color, const Color(0xFF75421F), .26)!,
            Color.lerp(color, const Color(0xFF3F2414), .30)!,
          ],
          stops: const <double>[0, .34, .78, 1],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isPreview
              ? const Color(0xFF168D78)
              : edge.withValues(alpha: .76),
          width: isPreview ? 2 : .8,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isPreview
                ? const Color(0xFF159C81).withValues(alpha: .52)
                : const Color(0xFF4E321B).withValues(alpha: .17),
            blurRadius: isPreview ? 8 : 2.4,
            offset: isPreview ? const Offset(0, 0) : const Offset(0, 1.4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .42),
            blurRadius: .6,
            offset: const Offset(-.6, -.7),
          ),
          BoxShadow(
            color: const Color(0xFF3A2113).withValues(alpha: .22),
            blurRadius: 1.4,
            offset: const Offset(0, 1.7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - .4),
        child: CustomPaint(
          painter: _WoodGrainPainter(seed: seed, strength: .88),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  const _WoodGrainPainter({required this.seed, required this.strength});

  final int seed;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Random random = Random(seed);
    final Paint grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .72
      ..color = const Color(0xFF4A2B18).withValues(alpha: .16 * strength);
    final Paint fineGrain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .34
      ..color = const Color(0xFFFFEBCB).withValues(alpha: .19 * strength);
    final Paint highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .55
      ..color = const Color(0xFFFFF0D5).withValues(alpha: .28 * strength);

    for (int index = 0; index < 8; index++) {
      final double y =
          size.height * (.08 + index * .12) +
          (random.nextDouble() - .5) * size.height * .045;
      final double bend = (random.nextDouble() - .5) * size.height * .14;
      final Path path = Path()
        ..moveTo(-2, y)
        ..cubicTo(
          size.width * .27,
          y + bend,
          size.width * .63,
          y - bend * .72,
          size.width + 2,
          y + bend * .25,
        );
      canvas.drawPath(path, grain);
      canvas.save();
      canvas.translate(0, -1.1);
      canvas.drawPath(path, highlight);
      canvas.restore();
      if (size.width > 28) {
        final Path fine = Path()
          ..moveTo(-2, y + size.height * .025)
          ..cubicTo(
            size.width * .28,
            y + bend * .7,
            size.width * .67,
            y - bend * .45,
            size.width + 2,
            y + bend * .12,
          );
        canvas.drawPath(fine, fineGrain);
      }
    }

    if (seed % 4 == 0 && size.shortestSide > 14) {
      final double centerX = size.width * (.25 + random.nextDouble() * .5);
      final double centerY = size.height * (.28 + random.nextDouble() * .42);
      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate((random.nextDouble() - .5) * .16);
      final Paint knot = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .6
        ..color = const Color(0xFF55371F).withValues(alpha: .12 * strength);
      for (int ring = 0; ring < 3; ring++) {
        final Rect oval = Rect.fromCenter(
          center: Offset.zero,
          width: size.width * (.08 + ring * .045),
          height: size.height * (.035 + ring * .02),
        );
        canvas.drawOval(oval, knot);
      }
      canvas.restore();
    }

    final Paint topEdge = Paint()
      ..strokeWidth = .8
      ..color = Colors.white.withValues(alpha: .36 * strength);
    canvas.drawLine(const Offset(2, 1.5), Offset(size.width - 2, 1.5), topEdge);
  }

  @override
  bool shouldRepaint(_WoodGrainPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.strength != strength;
}
