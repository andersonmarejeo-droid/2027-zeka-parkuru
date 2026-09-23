import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_engine.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_models.dart';

void main() {
  group('V11.3 professional visual grammar', () {
    test('scene grammar never duplicates logical operands decoratively', () async {
      final questions = await ProfessionalIqEngine().compose(
        level: 10,
        count: 192,
        sessionSeed: 20260825,
        fixedSession: true,
      );
      expect(
        questions
            .where((item) => item.family == ProfessionalIqFamily.paperFold)
            .every((item) => item.scene == ProfessionalIqScene.fold),
        isTrue,
      );
      expect(
        questions
            .where(
              (item) =>
                  item.family == ProfessionalIqFamily.xor ||
                  item.family == ProfessionalIqFamily.overlay ||
                  item.family == ProfessionalIqFamily.symmetry,
            )
            .every((item) => item.scene == ProfessionalIqScene.symbols),
        isTrue,
      );
      expect(
        questions
            .where((item) => item.family == ProfessionalIqFamily.countRelation)
            .every((item) => item.scene == ProfessionalIqScene.balance),
        isTrue,
      );
    });

    test('every generated question remains single-answer and visible', () async {
      for (var seed = 5100; seed < 5110; seed++) {
        final questions = await ProfessionalIqEngine().compose(
          level: 10,
          count: 96,
          sessionSeed: seed,
          fixedSession: true,
        );
        for (final question in questions) {
          expect(question.options.length, 4);
          expect(question.correctIndex, inInclusiveRange(0, 3));
          expect(
            question.options.map((item) => item.visibleSignature).toSet().length,
            4,
            reason: '${question.family.name} / $seed',
          );
        }
      }
    });
  });
}
