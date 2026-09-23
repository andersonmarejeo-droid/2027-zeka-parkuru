import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_engine.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_models.dart';

void main() {
  group('V11.2 visible-rule professional IQ', () {
    test('expanded pool keeps all sixteen families', () {
      expect(ProfessionalIqFamily.values.length, 16);
      expect(
        ProfessionalIqEngine.familiesForLevel(10).toSet(),
        ProfessionalIqFamily.values.toSet(),
      );
      expect(ProfessionalIqEngine.validatedTemplatesPerFamily, 36);
      expect(ProfessionalIqEngine.validatedEquivalentVariants, 90000);
    });

    test('fixed sessions are deterministic and visibly unambiguous', () async {
      final ProfessionalIqEngine engine = ProfessionalIqEngine();
      final List<ProfessionalIqQuestion> first = await engine.compose(
        level: 10,
        count: 96,
        sessionSeed: 20260825,
        fixedSession: true,
      );
      final List<ProfessionalIqQuestion> second = await engine.compose(
        level: 10,
        count: 96,
        sessionSeed: 20260825,
        fixedSession: true,
      );
      expect(
        first.map((item) => item.fingerprint),
        second.map((item) => item.fingerprint),
      );
      for (final ProfessionalIqQuestion question in first) {
        expect(question.options.length, 4);
        expect(
          question.options.map((item) => item.visibleSignature).toSet().length,
          4,
          reason: question.family.name,
        );
        expect(question.correctIndex, inInclusiveRange(0, 3));
      }
    });

    test('series families expose a visible rule without duplicate answer cards', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 240,
            sessionSeed: 81173,
            fixedSession: true,
          );
      for (final ProfessionalIqQuestion question in questions.where(
        (item) =>
            item.family == ProfessionalIqFamily.visualSeries ||
            item.family == ProfessionalIqFamily.colorPattern,
      )) {
        expect(question.board.length, 4);
        expect(question.board.last, isNull);
        expect(
          question.options.map((item) => item.visibleSignature).toSet().length,
          4,
        );
      }
    });


    test('silhouette matching is a direct non-series task', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 240,
            sessionSeed: 81174,
            fixedSession: true,
          );
      for (final ProfessionalIqQuestion question in questions.where(
        (item) => item.family == ProfessionalIqFamily.shapeTransform,
      )) {
        expect(question.layout, ProfessionalIqLayout.transform);
        expect(question.scene, ProfessionalIqScene.parts);
        expect(question.board.length, 2);
        expect(question.board.first, isNotNull);
        expect(question.board.last, isNull);
        expect(question.options.map((item) => item.shape).toSet().length, 4);
      }
    });

    test('odd-one-out always has four visibly distinct candidates', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 240,
            sessionSeed: 41903,
            fixedSession: true,
          );
      for (final ProfessionalIqQuestion question in questions.where(
        (item) => item.family == ProfessionalIqFamily.oddOneOut,
      )) {
        expect(question.options.length, 4);
        expect(
          question.options.map((item) => item.visibleSignature).toSet().length,
          4,
        );
        expect(question.correctIndex, inInclusiveRange(0, 3));
      }
    });

    test('ordinary figures do not expose a hidden pattern badge', () {
      const ProfessionalIqFigure first = ProfessionalIqFigure(
        shape: 3,
        color: 2,
        rotation: 1,
        count: 2,
        size: 1,
        pattern: 0,
        position: 4,
      );
      final ProfessionalIqFigure hiddenBadgeChange = first.copyWith(pattern: 3);
      expect(first.visibleSignature, hiddenBadgeChange.visibleSignature);
      expect(first.logicSignature, hiddenBadgeChange.logicSignature);
    });
  });
}
