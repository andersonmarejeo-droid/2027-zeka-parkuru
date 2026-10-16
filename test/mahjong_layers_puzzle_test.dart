import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/mahjong_layers/mahjong_layers_puzzle.dart';

void main() {
  group('Mahjong Katmanları content contract', () {
    test('classic free-tile rule requires an empty top and one open side', () {
      const List<MahjongTile> tiles = <MahjongTile>[
        MahjongTile(id: 0, faceKey: 'a', faceLabel: 'A', x: 2, y: 0, layer: 0),
        MahjongTile(id: 1, faceKey: 'b', faceLabel: 'B', x: 0, y: 0, layer: 0),
        MahjongTile(id: 2, faceKey: 'c', faceLabel: 'C', x: 4, y: 0, layer: 0),
        MahjongTile(id: 3, faceKey: 'd', faceLabel: 'D', x: 2, y: 0, layer: 1),
      ];
      expect(
        MahjongLayersPuzzle.isTileFreeInLayout(
          tiles: tiles,
          remaining: <int>{0, 1, 2, 3},
          tileId: 0,
        ),
        isFalse,
        reason: 'the upper overlap blocks the tile',
      );
      expect(
        MahjongLayersPuzzle.isTileFreeInLayout(
          tiles: tiles,
          remaining: <int>{0, 1, 2},
          tileId: 0,
        ),
        isFalse,
        reason: 'both horizontal sides are still closed',
      );
      expect(
        MahjongLayersPuzzle.isTileFreeInLayout(
          tiles: tiles,
          remaining: <int>{0, 1},
          tileId: 0,
        ),
        isTrue,
        reason: 'one horizontal side is now open',
      );
    });

    test('the 20 campaign boards are unique and replayably solvable', () {
      final Set<String> signatures = <String>{};
      final Set<MahjongTopology> topologies = <MahjongTopology>{};
      for (
        int level = 1;
        level <= MahjongLayersPuzzle.maximumUniqueCases;
        level++
      ) {
        final MahjongLayersPuzzle puzzle = MahjongLayersPuzzle.forLevel(level);
        expect(signatures.add(puzzle.boardSignature), isTrue);
        expect(
          puzzle.tileCount,
          MahjongLayersPuzzle.tilesForStage(puzzle.localStage),
        );
        expect(
          puzzle.layerCount,
          MahjongLayersPuzzle.layersForStage(puzzle.localStage),
        );
        expect(puzzle.tileCount.isEven, isTrue);
        expect(puzzle.solution, hasLength(puzzle.pairCount));
        expect(puzzle.initialRemaining, hasLength(puzzle.tileCount));
        expect(puzzle.verifySolution(), isTrue, reason: 'level $level');
        expect(puzzle.initialFreeCount, greaterThanOrEqualTo(2));
        expect(puzzle.boardWidthUnits, greaterThan(0));
        expect(puzzle.boardHeightUnits, greaterThan(0));

        final Map<String, int> faceCounts = <String, int>{};
        for (final MahjongTile tile in puzzle.tiles) {
          faceCounts.update(
            tile.faceKey,
            (int count) => count + 1,
            ifAbsent: () => 1,
          );
        }
        expect(faceCounts.values.every((int count) => count == 2), isTrue);

        for (int first = 0; first < puzzle.tiles.length; first++) {
          final MahjongTile a = puzzle.tiles[first];
          for (int second = first + 1; second < puzzle.tiles.length; second++) {
            final MahjongTile b = puzzle.tiles[second];
            if (a.layer != b.layer) continue;
            final bool overlaps =
                a.x < b.x + MahjongLayersPuzzle.tileSpan &&
                a.x + MahjongLayersPuzzle.tileSpan > b.x &&
                a.y < b.y + MahjongLayersPuzzle.tileSpan &&
                a.y + MahjongLayersPuzzle.tileSpan > b.y;
            expect(
              overlaps,
              isFalse,
              reason: 'same-layer overlap at level $level',
            );
          }
        }

        Set<int> remaining = puzzle.initialRemaining;
        for (final MahjongMove move in puzzle.solution) {
          expect(
            puzzle.canMatch(move.firstTileId, move.secondTileId, remaining),
            isTrue,
            reason: 'illegal proof move at level $level',
          );
          final Set<int> before = remaining;
          remaining = puzzle.removePair(
            remaining,
            move.firstTileId,
            move.secondTileId,
          );
          expect(
            before,
            contains(move.firstTileId),
            reason: 'input state mutated',
          );
          expect(remaining, isNot(contains(move.firstTileId)));
        }
        expect(puzzle.isSolved(remaining), isTrue);
        topologies.add(puzzle.topology);
      }
      expect(signatures, hasLength(MahjongLayersPuzzle.maximumUniqueCases));
      expect(() => MahjongLayersPuzzle.forLevel(21), throwsRangeError);
      expect(topologies, hasLength(greaterThanOrEqualTo(5)));
    });

    test(
      'the ten-stage curve rises into advanced and expert layered boards',
      () {
        final List<MahjongLayersPuzzle> stages = <MahjongLayersPuzzle>[
          for (int stage = 1; stage <= 10; stage++)
            MahjongLayersPuzzle.forLevel(stage),
        ];
        expect(
          stages.map((MahjongLayersPuzzle puzzle) => puzzle.tileCount),
          <int>[24, 32, 40, 48, 56, 64, 72, 80, 88, 96],
        );
        expect(
          stages.map((MahjongLayersPuzzle puzzle) => puzzle.layerCount),
          <int>[1, 2, 2, 2, 3, 3, 3, 4, 4, 4],
        );
        for (int index = 1; index < stages.length; index++) {
          expect(
            stages[index].difficultyScore,
            greaterThan(stages[index - 1].difficultyScore),
            reason: 'stage ${index + 1} should be harder than the prior stage',
          );
        }
        for (int stage = 7; stage <= 8; stage++) {
          expect(stages[stage - 1].difficultyTier, 'İLERİ');
          expect(stages[stage - 1].coveredTileCount, greaterThanOrEqualTo(14));
        }
        for (int stage = 9; stage <= 10; stage++) {
          expect(stages[stage - 1].difficultyTier, 'UZMAN');
          expect(stages[stage - 1].coveredTileCount, greaterThanOrEqualTo(22));
        }
        expect(stages.last.topologyKind, isNotEmpty);
      },
    );

    test(
      'an invalid pair cannot mutate the state and hint is a legal move',
      () {
        final MahjongLayersPuzzle puzzle = MahjongLayersPuzzle.forLevel(1);
        final Set<int> initial = puzzle.initialRemaining;
        final MahjongMove? hint = puzzle.hintMove(initial);
        expect(hint, isNotNull);
        expect(
          puzzle.canMatch(hint!.firstTileId, hint.secondTileId, initial),
          isTrue,
        );
        final List<int> free = puzzle.availableTileIds(initial).toList();
        expect(
          () => puzzle.removePair(initial, free.first, free.first),
          throwsArgumentError,
        );
        expect(initial, hasLength(puzzle.tileCount));
      },
    );
  });
}
