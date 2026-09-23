import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_engine.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_models.dart';

void main() {
  group('V11.4 visual IQ logic integrity', () {
    test('invisible rotation and mirror state do not create fresh content', () {
      const ProfessionalIqFigure circle = ProfessionalIqFigure(
        shape: 0,
        color: 1,
        rotation: 0,
        count: 1,
        size: 1,
        pattern: 0,
        position: 4,
      );
      expect(circle.logicSignature, circle.copyWith(rotation: 3).logicSignature);

      const ProfessionalIqFigure star = ProfessionalIqFigure(
        shape: 3,
        color: 1,
        rotation: 0,
        count: 1,
        size: 1,
        pattern: 0,
        position: 4,
      );
      expect(star.logicSignature, star.copyWith(mirrored: true).logicSignature);
    });

    test('dot-rule families render raw operands instead of duplicated layers', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 160,
            sessionSeed: 260826,
            fixedSession: true,
          );
      for (final ProfessionalIqQuestion q in questions.where(
        (q) =>
            q.family == ProfessionalIqFamily.symmetry ||
            q.family == ProfessionalIqFamily.overlay ||
            q.family == ProfessionalIqFamily.xor,
      )) {
        expect(q.scene, ProfessionalIqScene.symbols, reason: q.family.name);
      }
    });

    test('count relation uses a visible four-step cycle', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 160,
            sessionSeed: 260827,
            fixedSession: true,
          );
      const Set<String> allowed = <String>{
        '1-2-3-1',
        '3-2-1-3',
        '1-3-2-1',
        '2-1-3-2',
      };
      for (final ProfessionalIqQuestion q in questions.where(
        (q) => q.family == ProfessionalIqFamily.countRelation,
      )) {
        final String cycle = <int>[
          q.board[0]!.count,
          q.board[1]!.count,
          q.board[2]!.count,
          q.answer.count,
        ].join('-');
        expect(allowed, contains(cycle));
      }
    });

    test('symmetry and paper-fold second panels are rule-bearing, not noise', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 240,
            sessionSeed: 260828,
            fixedSession: true,
          );
      for (final ProfessionalIqQuestion q in questions.where(
        (q) =>
            q.family == ProfessionalIqFamily.symmetry ||
            q.family == ProfessionalIqFamily.paperFold,
      )) {
        final int a = q.board[0]!.dotMask;
        final int b = q.board[1]!.dotMask;
        expect(q.answer.dotMask, a | b, reason: q.family.name);
      }
    });

    test('size-position path moves through adjacent cells', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 160,
            sessionSeed: 260829,
            fixedSession: true,
          );
      bool adjacent(int a, int b) {
        final int ar = a ~/ 3, ac = a % 3;
        final int br = b ~/ 3, bc = b % 3;
        return (ar - br).abs() + (ac - bc).abs() == 1;
      }

      for (final ProfessionalIqQuestion q in questions.where(
        (q) => q.family == ProfessionalIqFamily.sizePosition,
      )) {
        final List<int> path = <int>[
          q.board[0]!.position,
          q.board[1]!.position,
          q.board[2]!.position,
          q.answer.position,
        ];
        expect(adjacent(path[0], path[1]), isTrue);
        expect(adjacent(path[1], path[2]), isTrue);
        expect(adjacent(path[2], path[3]), isTrue);
      }
    });
  });
}
