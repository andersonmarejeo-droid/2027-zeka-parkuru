import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_engine.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_models.dart';

String semanticSignature(
  ProfessionalIqFamily family,
  ProfessionalIqFigure figure,
) {
  if (figure.isDotPattern) return 'dots:${figure.dotMask}';
  final int rotation = figure.shape == 0 || figure.shape == 2
      ? 0
      : figure.rotation;
  final bool mirror = figure.shape == 6 && figure.mirrored;
  return switch (family) {
    ProfessionalIqFamily.colorPattern => 'color:${figure.color}',
    ProfessionalIqFamily.shapeTransform => 'shape:${figure.shape}',
    ProfessionalIqFamily.rotation => 'rotation:$rotation',
    ProfessionalIqFamily.mirror =>
      'mirror:${figure.position}:$rotation:$mirror',
    ProfessionalIqFamily.countRelation => 'count:${figure.count}',
    ProfessionalIqFamily.sizePosition =>
      'sizePosition:${figure.size}:${figure.position}',
    ProfessionalIqFamily.analogy =>
      'analogy:${figure.shape}:$rotation:${figure.count}:${figure.size}:${figure.position}:$mirror',
    ProfessionalIqFamily.visualSeries =>
      'series:${figure.shape}:${figure.color}:$rotation:${figure.count}:${figure.size}',
    ProfessionalIqFamily.matrix2 ||
    ProfessionalIqFamily.matrix3 ||
    ProfessionalIqFamily.mixedRules =>
      'matrix:${figure.shape}:${figure.color}:$rotation:${figure.count}:${figure.size}:${figure.position}:$mirror',
    ProfessionalIqFamily.symmetry ||
    ProfessionalIqFamily.overlay ||
    ProfessionalIqFamily.xor ||
    ProfessionalIqFamily.paperFold => 'dots:${figure.dotMask}',
    ProfessionalIqFamily.oddOneOut => figure.visibleSignature,
  };
}

void main() {
  group('V11.5 visual IQ diversity and single-answer guarantee', () {
    test('every generated question has four visibly and logically distinct choices', () async {
      for (int seed = 0; seed < 12; seed++) {
        final List<ProfessionalIqQuestion> questions =
            await ProfessionalIqEngine().compose(
              level: 10,
              count: 96,
              sessionSeed: 551500 + seed,
              fixedSession: true,
            );
        for (final ProfessionalIqQuestion question in questions) {
          expect(question.options.length, 4);
          expect(
            question.options.map((item) => item.visibleSignature).toSet().length,
            4,
            reason: 'visible duplicate: ${question.family.name}',
          );
          if (question.family != ProfessionalIqFamily.oddOneOut) {
            expect(
              question.options
                  .map((item) => semanticSignature(question.family, item))
                  .toSet()
                  .length,
              4,
              reason: 'logical duplicate: ${question.family.name}',
            );
          }
        }
      }
    });

    test('count questions never differ only by color', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 240,
            sessionSeed: 551520,
            fixedSession: true,
          );
      for (final ProfessionalIqQuestion question in questions.where(
        (q) => q.family == ProfessionalIqFamily.countRelation,
      )) {
        expect(
          question.options.map((item) => item.count).toSet().length,
          4,
        );
      }
    });

    test('count, rotation and matrix families expose multiple structural patterns', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 480,
            sessionSeed: 551530,
            fixedSession: true,
          );

      String boardKey(ProfessionalIqQuestion q) => q.board
          .map((item) => item?.visibleSignature ?? '?')
          .join('|');

      // Sequence/matrix families expose their structure on the board itself.
      // oddOneOut intentionally has an empty board: its four figures live in
      // options. Testing boardKey for oddOneOut therefore always produced the
      // single value "" and was a false-negative in the V12.1 test.
      for (final ProfessionalIqFamily family in <ProfessionalIqFamily>[
        ProfessionalIqFamily.countRelation,
        ProfessionalIqFamily.rotation,
        ProfessionalIqFamily.sizePosition,
        ProfessionalIqFamily.matrix2,
        ProfessionalIqFamily.matrix3,
      ]) {
        final Set<String> patterns = questions
            .where((q) => q.family == family)
            .map(boardKey)
            .toSet();
        expect(patterns.length, greaterThanOrEqualTo(4), reason: family.name);
      }

      String oddRule(ProfessionalIqQuestion q) {
        bool hasThreeEqual(Iterable<int> values) {
          final Map<int, int> counts = <int, int>{};
          for (final int value in values) {
            counts[value] = (counts[value] ?? 0) + 1;
          }
          return counts.values.contains(3);
        }

        if (hasThreeEqual(q.options.map((item) => item.color))) return 'color';
        if (hasThreeEqual(q.options.map((item) => item.count))) return 'count';
        if (hasThreeEqual(q.options.map((item) => item.size))) return 'size';
        if (hasThreeEqual(q.options.map((item) => item.rotation))) {
          return 'rotation';
        }
        return 'unknown';
      }

      final Set<String> oddPatterns = questions
          .where((q) => q.family == ProfessionalIqFamily.oddOneOut)
          .map(oddRule)
          .toSet();
      expect(oddPatterns, containsAll(<String>{'color', 'count', 'size', 'rotation'}));
      expect(oddPatterns, isNot(contains('unknown')));
    });

    test('dot operators are rendered once, without decorative duplicate layers', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 180,
            sessionSeed: 551540,
            fixedSession: true,
          );
      for (final ProfessionalIqQuestion q in questions.where(
        (q) =>
            q.family == ProfessionalIqFamily.symmetry ||
            q.family == ProfessionalIqFamily.overlay ||
            q.family == ProfessionalIqFamily.xor,
      )) {
        expect(q.scene, ProfessionalIqScene.symbols);
      }
    });
  });
}
