import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/reference_games/single_stroke_puzzle.dart';

void main() {
  group('Tek Çizgi Ustası içerik güvenliği', () {
    test('30 bölümün farklı varyantları temiz geometriyle üretilebilir', () {
      for (int variant = 0; variant < 40; variant++) {
        for (int level = 1; level <= 30; level++) {
          expect(
            () => SingleStrokePuzzle.generate(level, variant),
            returnsNormally,
            reason: 'Bölüm $level, varyant $variant',
          );
        }
      }
    });

    test('her bölümde bütün çizgiler tek seferde geçilebilir', () {
      for (int level = 1; level <= 30; level++) {
        final SingleStrokePuzzle puzzle = SingleStrokePuzzle.generate(level, 0);
        final List<String> routeEdges = <String>[
          for (int index = 1; index < puzzle.solution.length; index++)
            _edgeKey(puzzle.solution[index - 1], puzzle.solution[index]),
        ];

        expect(puzzle.solution, hasLength(puzzle.edges.length + 1));
        expect(routeEdges.toSet(), hasLength(puzzle.edges.length));
        expect(
          routeEdges.toSet(),
          equals(puzzle.edges.map((StrokeEdge edge) => edge.key).toSet()),
          reason: 'Bölüm $level çözüm yolu her çizgiyi bir kez geçmeli.',
        );
        expect(puzzle.solution.first, puzzle.start);
        expect(puzzle.solution.last, puzzle.end);
      }
    });

    test('kampanyadaki her seviye görsel olarak farklı bir şekle sahip', () {
      final Map<String, List<int>> levelsBySignature = <String, List<int>>{};
      for (int level = 1; level <= 30; level++) {
        final String signature = SingleStrokePuzzle.generate(
          level,
          0,
        ).signature;
        levelsBySignature.putIfAbsent(signature, () => <int>[]).add(level);
      }
      final List<List<int>> repeatedLevels = levelsBySignature.values
          .where((List<int> levels) => levels.length > 1)
          .toList(growable: false);
      expect(
        repeatedLevels,
        isEmpty,
        reason: 'Tekrar eden şekiller: $repeatedLevels',
      );
    });
  });
}

String _edgeKey(int first, int second) =>
    first < second ? '$first-$second' : '$second-$first';
