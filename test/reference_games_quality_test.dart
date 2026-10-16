import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/reference_games/arrow_maze_puzzle.dart';
import 'package:zeka_parkuru/games/reference_games/atlas_puzzle.dart';
import 'package:zeka_parkuru/games/reference_games/katamino_puzzle.dart';
import 'package:zeka_parkuru/games/reference_games/reference_game_support.dart';
import 'package:zeka_parkuru/games/reference_games/single_stroke_puzzle.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('atlas assets contain real province and country boundaries', () async {
    final Map<String, Object?> turkey = jsonDecode(
      await rootBundle.loadString('assets/maps/turkey_provinces.json'),
    ) as Map<String, Object?>;
    final Map<String, Object?> world = jsonDecode(
      await rootBundle.loadString('assets/maps/world_countries.json'),
    ) as Map<String, Object?>;
    final List<AtlasFeature> provinces = (turkey['features']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(AtlasFeature.fromJson)
        .toList();
    final List<AtlasFeature> countries = (world['features']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(AtlasFeature.fromJson)
        .toList();

    expect(provinces, hasLength(81));
    expect(countries.length, greaterThan(200));
    expect(
      provinces.every((AtlasFeature feature) => feature.rings.isNotEmpty),
      isTrue,
    );
    expect(
      countries.every((AtlasFeature feature) => feature.rings.isNotEmpty),
      isTrue,
    );
    const AtlasFeature square = AtlasFeature(
      code: 'test',
      center: <double>[1, 1],
      rings: <List<List<double>>>[
        <List<double>>[
          <double>[0, 0],
          <double>[2, 0],
          <double>[2, 2],
          <double>[0, 2],
          <double>[0, 0],
        ],
      ],
    );
    expect(atlasPointInFeature(1, 1, square), isTrue);
    expect(atlasPointInFeature(3, 3, square), isFalse);
  });

  test(
    'atlas clues hide names and typed answers accept locale variants',
    () async {
      for (final AtlasKind kind in AtlasKind.values) {
        final List<AtlasFeature> features = await AtlasDataset.load(kind);
        final List<AtlasFeature> targets = features
            .where(
              (AtlasFeature feature) =>
                  AtlasDataset.isTarget(kind, feature.code),
            )
            .toList(growable: false);

        for (final AtlasFeature target in targets) {
          final String clue = AtlasDataset.areaClue(kind, target.code);
          final String positionalHint = AtlasDataset.positionClue(kind, target);
          final String culturalHint = AtlasDataset.culturalClue(
            kind,
            target.code,
          );
          final String culturalDetailHint = AtlasDataset.culturalDetailClue(
            kind,
            target.code,
          );
          final String structureHint = AtlasDataset.nameStructureClue(
            kind,
            target.code,
          );
          final String firstLetterHint = AtlasDataset.firstLetterClue(
            kind,
            target.code,
          );
          final String lastLetterHint = AtlasDataset.lastLetterClue(
            kind,
            target.code,
          );
          final String normalizedName = AtlasDataset.normalizeAnswer(
            AtlasDataset.label(kind, target.code),
          );

          expect(clue, isNotEmpty, reason: target.code);
          expect(positionalHint, isNotEmpty, reason: target.code);
          expect(culturalHint, isNotEmpty, reason: target.code);
          expect(culturalDetailHint, isNotEmpty, reason: target.code);
          expect(structureHint, isNotEmpty, reason: target.code);
          expect(firstLetterHint, isNotEmpty, reason: target.code);
          expect(lastLetterHint, isNotEmpty, reason: target.code);
          expect(
            clue,
            isNot(
              kind == AtlasKind.turkey
                  ? 'Bu şehir Türkiye sınırları içindedir.'
                  : 'Bu ülke dünya haritasında yer alır.',
            ),
            reason: 'Every target needs a specific area clue: ${target.code}.',
          );
          expect(
            AtlasDataset.normalizeAnswer(clue).contains(normalizedName),
            isFalse,
            reason: 'Base clue must not reveal ${target.code}.',
          );
          expect(
            AtlasDataset.normalizeAnswer(positionalHint)
                .contains(normalizedName),
            isFalse,
            reason: 'Position hint must not reveal ${target.code}.',
          );
          for (final String extraHint in <String>[
            culturalHint,
            culturalDetailHint,
            structureHint,
            firstLetterHint,
            lastLetterHint,
          ]) {
            expect(
              AtlasDataset.normalizeAnswer(extraHint).contains(normalizedName),
              isFalse,
              reason: 'Hints must not reveal ${target.code}.',
            );
          }
          expect(
            AtlasDataset.answerMatches(
              kind,
              target.code,
              AtlasDataset.label(kind, target.code),
            ),
            isTrue,
            reason: target.code,
          );
          if (kind == AtlasKind.world) {
            expect(
              AtlasDataset.answerMatches(
                kind,
                target.code,
                AtlasDataset.label(kind, target.code, english: true),
              ),
              isTrue,
              reason: target.code,
            );
          }
        }
      }

      expect(AtlasDataset.answerMatches(AtlasKind.world, 'USA', 'ABD'), isTrue);
      expect(
        AtlasDataset.answerMatches(AtlasKind.turkey, 'TR-63', 'Sanliurfa'),
        isTrue,
      );
    },
  );

  test('map question sets do not repeat across 300 rounds per atlas', () async {
    for (final AtlasKind kind in AtlasKind.values) {
      final String asset = kind == AtlasKind.turkey
          ? 'assets/maps/turkey_provinces.json'
          : 'assets/maps/world_countries.json';
      final Map<String, Object?> data = jsonDecode(
        await rootBundle.loadString(asset),
      ) as Map<String, Object?>;
      final List<String> codes = (data['features']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map((Map<String, Object?> feature) => feature['code']! as String)
          .toList();
      for (int level = 1; level <= 10; level++) {
        final Set<String> boards = <String>{
          for (
            int round = 0;
            round < ReferenceRoundStore.variantsPerLevel;
            round++
          )
            atlasQuestionCodes(
              kind: kind,
              codes: codes,
              level: level,
              variant: round,
            ).join(','),
        };
        expect(
          boards,
          hasLength(300),
          reason: '${kind.name} level $level question sets should be unique.',
        );
      }
    }
  });

  test('atlas answer points decrease for each additional hint', () {
    final List<int> points = <int>[
      for (
        int hints = 0;
        hints <= AtlasScorePolicy.maxHintsPerQuestion;
        hints++
      )
        AtlasScorePolicy.pointsForHints(hints),
    ];

    expect(points, <int>[100, 85, 70, 55, 40, 25, 10]);
    for (int index = 1; index < points.length; index++) {
      expect(points[index], lessThan(points[index - 1]));
    }
  });

  test('Katamino creates 300 distinct expert boards with exact coverage', () {
    for (int level = 1; level <= 10; level++) {
      final Set<String> signatures = <String>{};
      for (int variant = 0; variant < 300; variant++) {
        final KataminoPuzzle puzzle = KataminoPuzzle.generate(level, variant);
        signatures.add(puzzle.signature);
        expect(
          puzzle.width * puzzle.height,
          puzzle.pieces.length * puzzle.pieceSize,
        );
        expect(
          puzzle.pieces.every(
            (List<PolyCell> piece) => piece.length == puzzle.pieceSize,
          ),
          isTrue,
        );
        for (final List<PolyCell> piece in puzzle.pieces) {
          final Set<PolyCell> reached = <PolyCell>{piece.first};
          bool changed = true;
          while (changed) {
            changed = false;
            for (final PolyCell cell in piece) {
              final bool touchesReached = reached.any(
                (PolyCell previous) =>
                    (previous.x - cell.x).abs() + (previous.y - cell.y).abs() ==
                    1,
              );
              if (!reached.contains(cell) && touchesReached) {
                reached.add(cell);
                changed = true;
              }
            }
          }
          expect(reached, equals(piece.toSet()));
        }
      }
      expect(
        signatures,
        hasLength(300),
        reason: 'Katamino level $level should not repeat.',
      );
    }
  });

  test('Katamino placement snaps to the closest legal orientation', () {
    const List<PolyCell> verticalBar = <PolyCell>[
      PolyCell(0, 0),
      PolyCell(0, 1),
      PolyCell(0, 2),
      PolyCell(0, 3),
    ];
    const KataminoPuzzle puzzle = KataminoPuzzle(
      width: 4,
      height: 4,
      pieceSize: 4,
      pieces: <List<PolyCell>>[verticalBar],
    );
    final List<int?> board = List<int?>.filled(16, 0);
    for (int x = 0; x < 4; x++) {
      board[12 + x] = null;
    }

    final KataminoPlacement? placement = findNearestKataminoPlacement(
      puzzle: puzzle,
      board: board,
      piece: verticalBar,
      targetX: 1,
      targetY: 1,
      preferredRotation: 0,
      preferredMirror: false,
    );
    expect(placement, isNotNull);
    expect(placement!.rotation, isNot(0));
    expect(placement.indices.toSet(), <int>{12, 13, 14, 15});

    expect(
      findNearestKataminoPlacement(
        puzzle: puzzle,
        board: List<int?>.filled(16, 0),
        piece: verticalBar,
        targetX: 1,
        targetY: 1,
        preferredRotation: 0,
        preferredMirror: false,
      ),
      isNull,
    );
  });

  test('single-stroke boards have a complete Euler trail and 300 variants', () {
    for (int level = 1; level <= 10; level++) {
      final Set<String> signatures = <String>{};
      for (int variant = 0; variant < 300; variant++) {
        final SingleStrokePuzzle puzzle = SingleStrokePuzzle.generate(
          level,
          variant,
        );
        signatures.add(puzzle.signature);
        expect(puzzle.solution.first, puzzle.start);
        expect(puzzle.solution.last, puzzle.end);
        expect(puzzle.solution.length - 1, puzzle.edges.length);
        final Set<String> traversed = <String>{};
        for (int index = 0; index < puzzle.solution.length - 1; index++) {
          final int a = puzzle.solution[index], b = puzzle.solution[index + 1];
          final String key = a < b ? '$a-$b' : '$b-$a';
          expect(
            puzzle.edges.any((StrokeEdge edge) => edge.key == key),
            isTrue,
          );
          traversed.add(key);
        }
        expect(traversed.length, puzzle.edges.length);
      }
      expect(
        signatures,
        hasLength(300),
        reason: 'Single-stroke level $level should not repeat.',
      );
    }
  });

  test('single-stroke every campaign level keeps every neighbour reachable', () {
    for (int level = 1; level <= 30; level++) {
      for (int variant = 0; variant < 30; variant++) {
        final SingleStrokePuzzle puzzle = SingleStrokePuzzle.generate(
          level,
          variant,
        );
        final List<int> route = puzzle.solution;
        expect(route.length, puzzle.edges.length + 1);
        expect(route.first, puzzle.start);
        expect(route.last, puzzle.end);

        final Set<String> traversed = <String>{};
        final List<int> degree = List<int>.filled(puzzle.points.length, 0);
        for (final StrokeEdge edge in puzzle.edges) {
          degree[edge.a]++;
          degree[edge.b]++;
        }
        for (int index = 0; index < route.length - 1; index++) {
          final int a = route[index];
          final int b = route[index + 1];
          final String key = a < b ? '$a-$b' : '$b-$a';
          expect(
            puzzle.edges.any((StrokeEdge edge) => edge.key == key),
            isTrue,
            reason: 'Missing neighbour edge at level $level/$variant: $key',
          );
          traversed.add(key);
        }
        expect(
          traversed.length,
          puzzle.edges.length,
          reason: 'A route got stuck at level $level/$variant.',
        );
        expect(
          degree.where((int value) => value.isOdd).length,
          anyOf(0, 2),
          reason: 'Invalid Euler endpoints at level $level/$variant.',
        );
        expect(
          degree.every((int value) => value > 0),
          isTrue,
          reason: 'A generated point is isolated at level $level/$variant.',
        );
      }
    }
  });

  test('single-stroke nodes keep a drawable minimum separation', () {
    // The board renders nodes at roughly 12% of its width. Keep centres at
    // least 14.5% apart so the main network remains easy to trace on a phone.
    const double minimumDistance = .145;
    for (int level = 1; level <= 30; level++) {
      for (int variant = 0; variant < 30; variant++) {
        final SingleStrokePuzzle puzzle = SingleStrokePuzzle.generate(
          level,
          variant,
        );
        for (int a = 0; a < puzzle.points.length; a++) {
          for (int b = a + 1; b < puzzle.points.length; b++) {
            final StrokePoint first = puzzle.points[a];
            final StrokePoint second = puzzle.points[b];
            expect(
              sqrt(
                (first.x - second.x) * (first.x - second.x) +
                    (first.y - second.y) * (first.y - second.y),
              ),
              greaterThanOrEqualTo(minimumDistance),
              reason: 'Nodes $a and $b overlap at level $level/$variant.',
            );
          }
        }
      }
    }
  });

  test(
    'single-stroke campaign grows from polygons into the reference house',
    () {
      expect(GameContentPolicy.nativeStages('single_stroke'), 30);
      final List<SingleStrokePuzzle> campaign =
          List<SingleStrokePuzzle>.generate(30, (int index) {
            final int chapter = index + 1;
            expect(GameContentPolicy.nativeLevel(chapter, stages: 30), chapter);
            return SingleStrokePuzzle.generate(chapter, 0);
          });

      expect(campaign.first.shapeNameTr, 'Üçgen');
      expect(campaign[4].shapeNameTr, 'Ev');
      expect(campaign[7].shapeNameTr, 'Ev ve kesişen çizgiler');
      expect(campaign[7].edges, hasLength(10));
      expect(campaign[8].edges, hasLength(14));
      expect(campaign[12].edges, hasLength(18));
      expect(campaign[16].edges, hasLength(22));
      expect(campaign[20].edges, hasLength(25));
      expect(campaign.last.edges, hasLength(28));
      expect(campaign.last.points, hasLength(19));
      for (int index = 1; index < campaign.length; index++) {
        expect(
          campaign[index].edges.length,
          greaterThanOrEqualTo(campaign[index - 1].edges.length),
          reason: 'Chapter ${index + 1} should not reduce puzzle complexity.',
        );
      }
    },
  );

  test(
    'arrow mazes stay connected and generate 300 distinct expert boards',
    () {
      for (int level = 1; level <= 10; level++) {
        final Set<String> signatures = <String>{};
        for (int variant = 0; variant < 300; variant++) {
          final ArrowMazePuzzle puzzle = ArrowMazePuzzle.generate(
            level,
            variant,
          );
          signatures.add(puzzle.signature);
          expect(puzzle.path.first, 0);
          expect(puzzle.path.last, puzzle.width * puzzle.height - 1);
          for (int cell = 0; cell < puzzle.width * puzzle.height; cell++) {
            expect(
              puzzle.nextCell(cell, puzzle.arrows[cell]),
              isNotNull,
              reason:
                  'Arrow-maze level $level variant $variant has a blocked arrow at cell $cell.',
            );
          }
          for (int index = 0; index < puzzle.path.length - 1; index++) {
            expect(
              puzzle.walls[puzzle.path[index]],
              contains(puzzle.path[index + 1]),
            );
          }
        }
        expect(
          signatures,
          hasLength(300),
          reason: 'Arrow-maze level $level should not repeat.',
        );
      }
    },
  );

  test('arrow maze movement and rendered walls share one neighbour rule', () {
    for (int level = 1; level <= 30; level++) {
      final ArrowMazePuzzle puzzle = ArrowMazePuzzle.generate(level, level);
      for (int cell = 0; cell < puzzle.width * puzzle.height; cell++) {
        for (final MazeDirection direction in MazeDirection.values) {
          final int? next = puzzle.nextCell(cell, direction);
          expect(next != null, isNot(puzzle.isWall(cell, direction)));
          if (next == null) {
            final int x = cell % puzzle.width + direction.dx;
            final int y = cell ~/ puzzle.width + direction.dy;
            if (x < 0 || x >= puzzle.width || y < 0 || y >= puzzle.height) {
              expect(puzzle.isWall(cell, direction), isTrue);
            }
          }
        }
      }
    }
  });
}
