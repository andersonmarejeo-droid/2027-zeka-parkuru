import 'dart:math' as math;

import '../shared/content_seed.dart';
import '../shared/studio_game_contracts.dart';

/// The visual families used by a pair.  Each key is deliberately allocated to
/// one pair only: a player is never punished for choosing the "wrong" copy of
/// an otherwise identical tile.  The board strategy, rather than arbitrary
/// duplicate-pair luck, is what makes the late Mahjong stages difficult.
enum MahjongTopology { ribbon, terrace, bridge, pagoda, crown, labyrinth }

extension MahjongTopologyLabel on MahjongTopology {
  String get label => switch (this) {
    MahjongTopology.ribbon => 'Şerit',
    MahjongTopology.terrace => 'Teras',
    MahjongTopology.bridge => 'Köprü',
    MahjongTopology.pagoda => 'Pagoda',
    MahjongTopology.crown => 'Taç',
    MahjongTopology.labyrinth => 'Labirent',
  };
}

/// A tile uses a two-by-two logical footprint.  [x] and [y] are logical board
/// units rather than screen pixels, making the same layout fit both phones and
/// tablets without changing the Mahjong blocking rules.
class MahjongTile {
  const MahjongTile({
    required this.id,
    required this.faceKey,
    required this.faceLabel,
    required this.x,
    required this.y,
    required this.layer,
  });

  final int id;
  final String faceKey;
  final String faceLabel;
  final int x;
  final int y;
  final int layer;
}

/// One legal pair removal in the generator-proven solution route.
class MahjongMove {
  const MahjongMove({required this.firstTileId, required this.secondTileId});

  final int firstTileId;
  final int secondTileId;

  Set<int> get tileIds => <int>{firstTileId, secondTileId};
}

/// Deterministic, layered Mahjong Solitaire content.
///
/// A tile is free only when no higher tile overlaps it and at least one of its
/// horizontal sides is open.  Every generated board stores a replayable legal
/// removal route; this is a constructive solvability proof rather than a
/// heuristic "looks playable" check.
class MahjongLayersPuzzle {
  static const int maximumUniqueCases = GameContentPolicy.bestSeriesCampaignLevels;
  static const int tileSpan = 2;

  static final Map<int, MahjongLayersPuzzle> _cache =
      <int, MahjongLayersPuzzle>{};
  static final Set<String> _signatures = <String>{};
  static int _generatedThrough = 0;

  MahjongLayersPuzzle({
    required this.level,
    required this.localStage,
    required this.topology,
    required this.tiles,
    required this.solution,
    required this.layerCount,
    required this.coveredTileCount,
    required this.initialFreeCount,
    required this.branchingScore,
    required this.forcedPairCount,
  });

  final int level;
  final int localStage;
  final MahjongTopology topology;
  final List<MahjongTile> tiles;
  final List<MahjongMove> solution;
  final int layerCount;

  /// Tiles that are covered by an overlapping higher layer at the opening.
  final int coveredTileCount;

  /// Number of tiles that obey the classic free-tile rule at the opening.
  final int initialFreeCount;

  /// Number of legal matching choices at the opening.  It is diagnostic data
  /// for balancing layouts, not a promise that every branch is a solution.
  final int branchingScore;

  /// How many positions on the constructive route have exactly one legal pair.
  final int forcedPairCount;

  late final Map<int, MahjongTile> _tilesById = <int, MahjongTile>{
    for (final MahjongTile tile in tiles) tile.id: tile,
  };

  late final Set<int> _initialRemaining = Set<int>.unmodifiable(
    tiles.map((MahjongTile tile) => tile.id),
  );

  int get tileCount => tiles.length;
  int get pairCount => tileCount ~/ 2;
  String get topologyKind => topology.label;
  String get difficultyTier => switch (localStage) {
    <= 2 => 'BAŞLANGIÇ',
    <= 6 => 'USTALAŞMA',
    <= 8 => 'İLERİ',
    _ => 'UZMAN',
  };

  /// A stable scale combining intentional stage growth with actual layout
  /// depth.  The hundreds digit preserves the designed 1→10 progression;
  /// the lower portion exposes useful topology diagnostics.
  int get difficultyScore =>
      localStage * 100 +
      pairCount * 2 +
      layerCount * 12 +
      coveredTileCount +
      forcedPairCount;

  int get minimumX => tiles.map((MahjongTile tile) => tile.x).reduce(math.min);
  int get maximumX =>
      tiles.map((MahjongTile tile) => tile.x + tileSpan).reduce(math.max);
  int get minimumY => tiles.map((MahjongTile tile) => tile.y).reduce(math.min);
  int get maximumY =>
      tiles.map((MahjongTile tile) => tile.y + tileSpan).reduce(math.max);
  int get boardWidthUnits => maximumX - minimumX;
  int get boardHeightUnits => maximumY - minimumY;

  Set<int> get initialRemaining => _initialRemaining;

  /// Coordinates and face assignment form the content identity.  It excludes
  /// the level number so accidental repeats in different chapters are caught.
  String get boardSignature {
    final List<MahjongTile> ordered = List<MahjongTile>.from(tiles)
      ..sort((MahjongTile a, MahjongTile b) => a.id.compareTo(b.id));
    return ordered
        .map(
          (MahjongTile tile) =>
              '${tile.x},${tile.y},${tile.layer},${tile.faceKey}',
        )
        .join('|');
  }

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  static int tilesForStage(int stage) {
    _checkStage(stage);
    return _tileCountsByStage[stage - 1].fold<int>(0, (int a, int b) => a + b);
  }

  static int layersForStage(int stage) {
    _checkStage(stage);
    return _tileCountsByStage[stage - 1].length;
  }

  static MahjongLayersPuzzle forLevel(int level) {
    if (level < 1 || level > maximumUniqueCases) {
      throw RangeError.range(level, 1, maximumUniqueCases, 'level');
    }
    // Generate sequentially so uniqueness is guaranteed even if a deep level
    // is opened before a player has visited its earlier chapter.
    while (_generatedThrough < level) {
      final int nextLevel = _generatedThrough + 1;
      final MahjongLayersPuzzle puzzle = _generate(nextLevel, _signatures);
      _cache[nextLevel] = puzzle;
      _signatures.add(puzzle.boardSignature);
      _generatedThrough = nextLevel;
    }
    return _cache[level]!;
  }

  MahjongTile tileForId(int id) {
    final MahjongTile? tile = _tilesById[id];
    if (tile == null) throw ArgumentError.value(id, 'id', 'Unknown tile');
    return tile;
  }

  bool isTileFree(int tileId, Set<int> remaining) =>
      isTileFreeInLayout(tiles: tiles, remaining: remaining, tileId: tileId);

  /// The exact classical rule shared by generation, UI feedback and tests:
  /// no overlapping tile above, plus an open left or right side.
  static bool isTileFreeInLayout({
    required List<MahjongTile> tiles,
    required Set<int> remaining,
    required int tileId,
  }) {
    MahjongTile? selected;
    final Map<int, MahjongTile> byId = <int, MahjongTile>{};
    for (final MahjongTile tile in tiles) {
      byId[tile.id] = tile;
      if (tile.id == tileId) selected = tile;
    }
    if (selected == null || !remaining.contains(tileId)) return false;
    if (remaining.any((int id) => !byId.containsKey(id))) return false;

    bool blockedAbove = false;
    bool blockedOnLeft = false;
    bool blockedOnRight = false;
    for (final int id in remaining) {
      if (id == tileId) continue;
      final MahjongTile other = byId[id]!;
      if (other.layer > selected.layer && _overlaps(selected, other)) {
        blockedAbove = true;
        break;
      }
      if (other.layer != selected.layer || !_verticalOverlap(selected, other)) {
        continue;
      }
      if (other.x + tileSpan == selected.x) blockedOnLeft = true;
      if (selected.x + tileSpan == other.x) blockedOnRight = true;
    }
    return !blockedAbove && (!blockedOnLeft || !blockedOnRight);
  }

  Set<int> availableTileIds(Set<int> remaining) => Set<int>.unmodifiable(
    remaining.where((int id) => isTileFree(id, remaining)),
  );

  List<MahjongMove> availableMoves(Set<int> remaining) {
    final List<int> free = availableTileIds(remaining).toList()..sort();
    final List<MahjongMove> moves = <MahjongMove>[];
    for (int first = 0; first < free.length; first++) {
      for (int second = first + 1; second < free.length; second++) {
        if (canMatch(free[first], free[second], remaining)) {
          moves.add(
            MahjongMove(firstTileId: free[first], secondTileId: free[second]),
          );
        }
      }
    }
    return List<MahjongMove>.unmodifiable(moves);
  }

  bool canMatch(int firstTileId, int secondTileId, Set<int> remaining) {
    if (firstTileId == secondTileId ||
        !remaining.contains(firstTileId) ||
        !remaining.contains(secondTileId)) {
      return false;
    }
    final MahjongTile? first = _tilesById[firstTileId];
    final MahjongTile? second = _tilesById[secondTileId];
    return first != null &&
        second != null &&
        first.faceKey == second.faceKey &&
        isTileFree(firstTileId, remaining) &&
        isTileFree(secondTileId, remaining);
  }

  /// Returns a new immutable state and never mutates [remaining].
  Set<int> removePair(Set<int> remaining, int firstTileId, int secondTileId) {
    if (!canMatch(firstTileId, secondTileId, remaining)) {
      throw ArgumentError('Only two free matching tiles may be removed.');
    }
    return Set<int>.unmodifiable(
      <int>{...remaining}
        ..remove(firstTileId)
        ..remove(secondTileId),
    );
  }

  bool isSolved(Set<int> remaining) => remaining.isEmpty;

  /// Prefer the retained constructive route.  If a caller supplies a custom
  /// valid state, fall back to any currently legal matching pair.
  MahjongMove? hintMove(Set<int> remaining) {
    for (final MahjongMove move in solution) {
      if (remaining.contains(move.firstTileId) &&
          remaining.contains(move.secondTileId) &&
          canMatch(move.firstTileId, move.secondTileId, remaining)) {
        return move;
      }
    }
    final List<MahjongMove> legal = availableMoves(remaining);
    return legal.isEmpty ? null : legal.first;
  }

  /// Replays the stored route through the real free-tile rule.
  bool verifySolution() {
    Set<int> remaining = initialRemaining;
    for (final MahjongMove move in solution) {
      if (!canMatch(move.firstTileId, move.secondTileId, remaining)) {
        return false;
      }
      remaining = removePair(remaining, move.firstTileId, move.secondTileId);
    }
    return isSolved(remaining);
  }

  static MahjongLayersPuzzle _generate(int level, Set<String> usedSignatures) {
    final int stage = stageForLevel(level);
    for (int attempt = 0; attempt < 2000; attempt++) {
      final math.Random random = ContentSeed.randomFor(
        gameId: 'mahjong_layers',
        level: level,
        attempt: attempt,
      );
      final MahjongTopology topology = _topologyFor(stage, random);
      final _TopologyLayout layout = _buildTopology(
        stage: stage,
        topology: topology,
        random: random,
      );
      final List<MahjongMove> solution = _solutionFor(layout.segments, random);
      final List<MahjongTile> tiles = _assignFaces(
        layout.positions,
        solution,
        random,
      );
      final MahjongLayersPuzzle provisional = MahjongLayersPuzzle(
        level: level,
        localStage: stage,
        topology: topology,
        tiles: List<MahjongTile>.unmodifiable(tiles),
        solution: List<MahjongMove>.unmodifiable(solution),
        layerCount: layout.layerCount,
        coveredTileCount: 0,
        initialFreeCount: 0,
        branchingScore: 0,
        forcedPairCount: 0,
      );
      final _RouteMetrics metrics = _measureRoute(provisional);
      final MahjongLayersPuzzle puzzle = MahjongLayersPuzzle(
        level: level,
        localStage: stage,
        topology: topology,
        tiles: List<MahjongTile>.unmodifiable(tiles),
        solution: List<MahjongMove>.unmodifiable(solution),
        layerCount: layout.layerCount,
        coveredTileCount: metrics.coveredTileCount,
        initialFreeCount: metrics.initialFreeCount,
        branchingScore: metrics.branchingScore,
        forcedPairCount: metrics.forcedPairCount,
      );
      if (usedSignatures.contains(puzzle.boardSignature) ||
          !_matchesStageDesign(puzzle) ||
          !puzzle.verifySolution()) {
        continue;
      }
      return puzzle;
    }
    throw StateError('Could not generate Mahjong board for level $level.');
  }

  static _RouteMetrics _measureRoute(MahjongLayersPuzzle puzzle) {
    final Set<int> opening = puzzle.initialRemaining;
    int covered = 0;
    for (final MahjongTile tile in puzzle.tiles) {
      if (opening.any((int id) {
        if (id == tile.id) return false;
        final MahjongTile other = puzzle.tileForId(id);
        return other.layer > tile.layer && _overlaps(tile, other);
      })) {
        covered++;
      }
    }
    int forced = 0;
    Set<int> remaining = opening;
    for (final MahjongMove move in puzzle.solution) {
      if (puzzle.availableMoves(remaining).length == 1) forced++;
      if (!puzzle.canMatch(move.firstTileId, move.secondTileId, remaining)) {
        return const _RouteMetrics(
          coveredTileCount: -1,
          initialFreeCount: 0,
          branchingScore: 0,
          forcedPairCount: 0,
        );
      }
      remaining = puzzle.removePair(
        remaining,
        move.firstTileId,
        move.secondTileId,
      );
    }
    return _RouteMetrics(
      coveredTileCount: covered,
      initialFreeCount: puzzle.availableTileIds(opening).length,
      branchingScore: puzzle.availableMoves(opening).length,
      forcedPairCount: forced,
    );
  }

  static bool _matchesStageDesign(MahjongLayersPuzzle puzzle) {
    if (puzzle.tileCount != tilesForStage(puzzle.localStage) ||
        puzzle.layerCount != layersForStage(puzzle.localStage) ||
        puzzle.solution.length != puzzle.pairCount ||
        puzzle.coveredTileCount < 0 ||
        puzzle.initialFreeCount < 2) {
      return false;
    }
    if (puzzle.localStage >= 7 && puzzle.coveredTileCount < 14) return false;
    if (puzzle.localStage >= 9 && puzzle.coveredTileCount < 22) return false;
    return true;
  }

  static MahjongTopology _topologyFor(int stage, math.Random random) {
    final List<MahjongTopology> options = switch (stage) {
      <= 2 => <MahjongTopology>[
        MahjongTopology.ribbon,
        MahjongTopology.terrace,
      ],
      <= 4 => <MahjongTopology>[
        MahjongTopology.ribbon,
        MahjongTopology.terrace,
        MahjongTopology.bridge,
      ],
      <= 6 => <MahjongTopology>[
        MahjongTopology.terrace,
        MahjongTopology.bridge,
        MahjongTopology.pagoda,
        MahjongTopology.crown,
      ],
      _ => MahjongTopology.values,
    };
    return options[random.nextInt(options.length)];
  }

  static _TopologyLayout _buildTopology({
    required int stage,
    required MahjongTopology topology,
    required math.Random random,
  }) {
    final List<int> tileCounts = _tileCountsByStage[stage - 1];
    final List<List<_RowSpec>> rowsByLayer = <List<_RowSpec>>[
      for (int layer = 0; layer < tileCounts.length; layer++)
        _rowsForLayer(
          tileCount: tileCounts[layer],
          layer: layer,
          topology: topology,
          random: random,
        ),
    ];
    final int maximumRows = rowsByLayer.fold<int>(
      0,
      (int current, List<_RowSpec> rows) => math.max(current, rows.length),
    );
    final List<_Segment> segments = <_Segment>[];
    int nextId = 0;
    for (int layer = 0; layer < rowsByLayer.length; layer++) {
      final List<_RowSpec> rows = rowsByLayer[layer];
      final int yShift = _layerYShift(topology, layer, random);
      final int firstY = (maximumRows - rows.length) * tileSpan + yShift;
      for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final _RowSpec row = rows[rowIndex];
        final int span =
            row.lengths.fold<int>(0, (int a, int b) => a + b) * tileSpan +
            (row.lengths.length - 1) * 4;
        final int baseX = _rowStart(
          topology: topology,
          rowIndex: rowIndex,
          rowCount: rows.length,
          layer: layer,
          span: span,
          random: random,
        );
        int x = baseX;
        for (final int length in row.lengths) {
          final List<_Position> positions = <_Position>[];
          for (int index = 0; index < length; index++) {
            positions.add(
              _Position(
                id: nextId++,
                x: x + index * tileSpan,
                y: firstY + rowIndex * tileSpan,
                layer: layer,
              ),
            );
          }
          segments.add(_Segment(layer: layer, positions: positions));
          x += length * tileSpan + 4;
        }
      }
    }
    return _TopologyLayout(
      positions: <_Position>[
        for (final _Segment segment in segments) ...segment.positions,
      ],
      segments: segments,
      layerCount: tileCounts.length,
    );
  }

  static List<_RowSpec> _rowsForLayer({
    required int tileCount,
    required int layer,
    required MahjongTopology topology,
    required math.Random random,
  }) {
    final int rowCount = (tileCount + 7) ~/ 8;
    final List<int> rowLengths = _evenParts(tileCount, rowCount, random);
    return <_RowSpec>[
      for (int row = 0; row < rowLengths.length; row++)
        _RowSpec(
          _segmentsForRow(
            length: rowLengths[row],
            row: row,
            layer: layer,
            topology: topology,
            random: random,
          ),
        ),
    ];
  }

  static List<int> _evenParts(int total, int count, math.Random random) {
    final List<int> parts = List<int>.filled(count, 2);
    int remaining = total - count * 2;
    while (remaining > 0) {
      final List<int> eligible = <int>[
        for (int index = 0; index < parts.length; index++)
          if (parts[index] < 8) index,
      ];
      final int selected = eligible[random.nextInt(eligible.length)];
      parts[selected] += 2;
      remaining -= 2;
    }
    return parts;
  }

  static List<int> _segmentsForRow({
    required int length,
    required int row,
    required int layer,
    required MahjongTopology topology,
    required math.Random random,
  }) {
    final bool split = switch (topology) {
      MahjongTopology.bridge => length >= 8 && (row + layer).isEven,
      MahjongTopology.labyrinth =>
        length >= 6 && ((row + layer).isEven || random.nextBool()),
      MahjongTopology.crown => length == 8 && row.isOdd && layer.isEven,
      _ => false,
    };
    if (!split) return <int>[length];
    final int left = length >= 8 ? 4 : 2;
    return <int>[left, length - left];
  }

  static int _layerYShift(
    MahjongTopology topology,
    int layer,
    math.Random random,
  ) {
    if (layer == 0) return 0;
    return switch (topology) {
      MahjongTopology.ribbon => layer.isOdd ? 1 : 0,
      MahjongTopology.bridge => layer.isOdd ? 1 : 0,
      MahjongTopology.labyrinth => (layer + random.nextInt(2)) % 2,
      _ => layer.isOdd ? 1 : 0,
    };
  }

  static int _rowStart({
    required MahjongTopology topology,
    required int rowIndex,
    required int rowCount,
    required int layer,
    required int span,
    required math.Random random,
  }) {
    const int boardSpan = 26;
    int shift = 0;
    switch (topology) {
      case MahjongTopology.ribbon:
        shift = rowIndex.isEven ? -1 : 1;
      case MahjongTopology.terrace:
        shift = layer.isOdd ? 1 : 0;
      case MahjongTopology.bridge:
        shift = (rowIndex + layer).isEven ? 0 : 1;
      case MahjongTopology.pagoda:
        shift = layer + (rowIndex.isOdd ? 1 : 0);
      case MahjongTopology.crown:
        final int edgeDistance = math.min(rowIndex, rowCount - rowIndex - 1);
        shift = edgeDistance == 0 ? 1 : 0;
      case MahjongTopology.labyrinth:
        shift = random.nextInt(3) - 1;
    }
    final int centered = (boardSpan - span) ~/ 2 + shift;
    return centered.clamp(0, boardSpan - span);
  }

  static List<MahjongMove> _solutionFor(
    List<_Segment> segments,
    math.Random random,
  ) {
    final Map<int, List<List<MahjongMove>>> queuesByLayer =
        <int, List<List<MahjongMove>>>{};
    for (final _Segment segment in segments) {
      final List<MahjongMove> queue = <MahjongMove>[];
      for (
        int left = 0, right = segment.positions.length - 1;
        left < right;
        left++, right--
      ) {
        queue.add(
          MahjongMove(
            firstTileId: segment.positions[left].id,
            secondTileId: segment.positions[right].id,
          ),
        );
      }
      queuesByLayer
          .putIfAbsent(segment.layer, () => <List<MahjongMove>>[])
          .add(queue);
    }
    final List<MahjongMove> route = <MahjongMove>[];
    final List<int> layers = queuesByLayer.keys.toList()..sort();
    for (final int layer in layers.reversed) {
      final List<List<MahjongMove>> queues = queuesByLayer[layer]!;
      while (queues.any((List<MahjongMove> queue) => queue.isNotEmpty)) {
        final List<List<MahjongMove>> ready = queues
            .where((List<MahjongMove> queue) => queue.isNotEmpty)
            .toList();
        final List<MahjongMove> selected = ready[random.nextInt(ready.length)];
        route.add(selected.removeAt(0));
      }
    }
    return route;
  }

  static List<MahjongTile> _assignFaces(
    List<_Position> positions,
    List<MahjongMove> solution,
    math.Random random,
  ) {
    final List<_FaceDefinition> faces = List<_FaceDefinition>.from(_faces)
      ..shuffle(random);
    if (solution.length > faces.length) {
      throw StateError('Not enough Mahjong face definitions.');
    }
    final Map<int, _FaceDefinition> faceForId = <int, _FaceDefinition>{};
    for (int index = 0; index < solution.length; index++) {
      final MahjongMove move = solution[index];
      faceForId[move.firstTileId] = faces[index];
      faceForId[move.secondTileId] = faces[index];
    }
    return <MahjongTile>[
      for (final _Position position in positions)
        MahjongTile(
          id: position.id,
          faceKey: faceForId[position.id]!.key,
          faceLabel: faceForId[position.id]!.label,
          x: position.x,
          y: position.y,
          layer: position.layer,
        ),
    ];
  }

  static bool _overlaps(MahjongTile a, MahjongTile b) =>
      a.x < b.x + tileSpan &&
      a.x + tileSpan > b.x &&
      a.y < b.y + tileSpan &&
      a.y + tileSpan > b.y;

  static bool _verticalOverlap(MahjongTile a, MahjongTile b) =>
      a.y < b.y + tileSpan && a.y + tileSpan > b.y;

  static void _checkStage(int stage) {
    if (stage < 1 || stage > 10) {
      throw RangeError.range(stage, 1, 10, 'stage');
    }
  }

  static const List<List<int>> _tileCountsByStage = <List<int>>[
    <int>[24],
    <int>[24, 8],
    <int>[24, 16],
    <int>[28, 20],
    <int>[30, 18, 8],
    <int>[32, 20, 12],
    <int>[36, 24, 12],
    <int>[36, 24, 12, 8],
    <int>[40, 24, 16, 8],
    <int>[40, 28, 16, 12],
  ];

  static const List<_FaceDefinition> _faces = <_FaceDefinition>[
    _FaceDefinition('bamboo_1', '竹1'),
    _FaceDefinition('bamboo_2', '竹2'),
    _FaceDefinition('bamboo_3', '竹3'),
    _FaceDefinition('bamboo_4', '竹4'),
    _FaceDefinition('bamboo_5', '竹5'),
    _FaceDefinition('bamboo_6', '竹6'),
    _FaceDefinition('bamboo_7', '竹7'),
    _FaceDefinition('bamboo_8', '竹8'),
    _FaceDefinition('bamboo_9', '竹9'),
    _FaceDefinition('circle_1', '●1'),
    _FaceDefinition('circle_2', '●2'),
    _FaceDefinition('circle_3', '●3'),
    _FaceDefinition('circle_4', '●4'),
    _FaceDefinition('circle_5', '●5'),
    _FaceDefinition('circle_6', '●6'),
    _FaceDefinition('circle_7', '●7'),
    _FaceDefinition('circle_8', '●8'),
    _FaceDefinition('circle_9', '●9'),
    _FaceDefinition('character_1', '萬1'),
    _FaceDefinition('character_2', '萬2'),
    _FaceDefinition('character_3', '萬3'),
    _FaceDefinition('character_4', '萬4'),
    _FaceDefinition('character_5', '萬5'),
    _FaceDefinition('character_6', '萬6'),
    _FaceDefinition('character_7', '萬7'),
    _FaceDefinition('character_8', '萬8'),
    _FaceDefinition('character_9', '萬9'),
    _FaceDefinition('wind_east', '東'),
    _FaceDefinition('wind_south', '南'),
    _FaceDefinition('wind_west', '西'),
    _FaceDefinition('wind_north', '北'),
    _FaceDefinition('dragon_red', '中'),
    _FaceDefinition('dragon_green', '發'),
    _FaceDefinition('dragon_white', '白'),
    _FaceDefinition('season_spring', '春'),
    _FaceDefinition('season_summer', '夏'),
    _FaceDefinition('season_autumn', '秋'),
    _FaceDefinition('season_winter', '冬'),
    _FaceDefinition('flower_plum', '梅'),
    _FaceDefinition('flower_orchid', '蘭'),
    _FaceDefinition('flower_chrysanthemum', '菊'),
    _FaceDefinition('flower_bamboo', '竹花'),
    _FaceDefinition('jade_1', '玉1'),
    _FaceDefinition('jade_2', '玉2'),
    _FaceDefinition('jade_3', '玉3'),
    _FaceDefinition('jade_4', '玉4'),
    _FaceDefinition('jade_5', '玉5'),
    _FaceDefinition('jade_6', '玉6'),
    _FaceDefinition('cloud_1', '雲1'),
    _FaceDefinition('cloud_2', '雲2'),
    _FaceDefinition('cloud_3', '雲3'),
    _FaceDefinition('cloud_4', '雲4'),
    _FaceDefinition('moon_1', '月1'),
    _FaceDefinition('moon_2', '月2'),
    _FaceDefinition('moon_3', '月3'),
    _FaceDefinition('moon_4', '月4'),
    _FaceDefinition('star_1', '星1'),
    _FaceDefinition('star_2', '星2'),
    _FaceDefinition('star_3', '星3'),
    _FaceDefinition('star_4', '星4'),
    _FaceDefinition('seal_1', '印1'),
    _FaceDefinition('seal_2', '印2'),
    _FaceDefinition('seal_3', '印3'),
    _FaceDefinition('seal_4', '印4'),
  ];
}

class _TopologyLayout {
  const _TopologyLayout({
    required this.positions,
    required this.segments,
    required this.layerCount,
  });

  final List<_Position> positions;
  final List<_Segment> segments;
  final int layerCount;
}

class _Position {
  const _Position({
    required this.id,
    required this.x,
    required this.y,
    required this.layer,
  });

  final int id;
  final int x;
  final int y;
  final int layer;
}

class _Segment {
  const _Segment({required this.layer, required this.positions});

  final int layer;
  final List<_Position> positions;
}

class _RowSpec {
  const _RowSpec(this.lengths);

  final List<int> lengths;
}

class _FaceDefinition {
  const _FaceDefinition(this.key, this.label);

  final String key;
  final String label;
}

class _RouteMetrics {
  const _RouteMetrics({
    required this.coveredTileCount,
    required this.initialFreeCount,
    required this.branchingScore,
    required this.forcedPairCount,
  });

  final int coveredTileCount;
  final int initialFreeCount;
  final int branchingScore;
  final int forcedPairCount;
}
