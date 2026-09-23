import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_engine.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_models.dart';

String perceptualWithoutFreePosition(ProfessionalIqFigure f) {
  final int rotation = f.rotationMatters ? f.rotation : 0;
  final bool mirror = f.mirrorMatters && f.mirrored;
  return '${f.shape}:${f.color}:$rotation:${f.count}:${f.size}:$mirror:${f.dotMask}';
}

void main() {
  group('V15 perceptual quality gate', () {
    test('rotation uses clearly asymmetric motifs and centered answers', () async {
      final questions = await ProfessionalIqEngine().compose(
        level: 10,
        count: 320,
        sessionSeed: 150001,
        fixedSession: true,
      );

      for (final q in questions.where(
        (q) => q.family == ProfessionalIqFamily.rotation,
      )) {
        expect(q.answer.rotationMatters, isTrue, reason: q.fingerprint);
        expect(q.options.map((f) => f.position).toSet(), <int>{4});
        expect(q.options.map((f) => f.shape).toSet(), <int>{q.answer.shape});
        expect(q.options.map((f) => f.color).toSet(), <int>{q.answer.color});
        expect(q.options.map((f) => f.count).toSet(), <int>{1});
        expect(q.options.map((f) => f.rotation).toSet().length, 4);
      }
    });

    test('mirror never uses hidden card position as a clue', () async {
      final questions = await ProfessionalIqEngine().compose(
        level: 10,
        count: 320,
        sessionSeed: 150002,
        fixedSession: true,
      );

      for (final q in questions.where(
        (q) => q.family == ProfessionalIqFamily.mirror,
      )) {
        expect(q.board.whereType<ProfessionalIqFigure>().map((f) => f.position).toSet(), <int>{4});
        expect(q.options.map((f) => f.position).toSet(), <int>{4});
        expect(q.answer.mirrorMatters, isTrue, reason: q.fingerprint);
        expect(q.options.map(perceptualWithoutFreePosition).toSet().length, 4);
      }
    });

    test('matrix choices can never differ only by free-floating position', () async {
      final questions = await ProfessionalIqEngine().compose(
        level: 10,
        count: 640,
        sessionSeed: 150003,
        fixedSession: true,
      );

      for (final q in questions.where(
        (q) => q.family == ProfessionalIqFamily.matrix2 ||
            q.family == ProfessionalIqFamily.matrix3 ||
            q.family == ProfessionalIqFamily.mixedRules,
      )) {
        expect(q.options.map((f) => f.position).toSet(), <int>{4});
        expect(q.options.map(perceptualWithoutFreePosition).toSet().length, 4,
            reason: q.fingerprint);
      }
    });

    test('no matrix pair can be the same answer after free card position is ignored', () async {
      for (int seed = 0; seed < 12; seed++) {
        final questions = await ProfessionalIqEngine().compose(
          level: 10,
          count: 240,
          sessionSeed: 151000 + seed,
          fixedSession: true,
        );
        for (final q in questions.where((q) =>
            q.family == ProfessionalIqFamily.matrix2 ||
            q.family == ProfessionalIqFamily.matrix3 ||
            q.family == ProfessionalIqFamily.mixedRules)) {
          final signatures = q.options.map(perceptualWithoutFreePosition).toList();
          expect(signatures.toSet().length, 4, reason: 'seed=$seed ${q.fingerprint}');
          for (int i = 0; i < signatures.length; i++) {
            for (int j = i + 1; j < signatures.length; j++) {
              expect(signatures[i], isNot(signatures[j]),
                  reason: 'duplicate matrix options $i/$j seed=$seed ${q.fingerprint}');
            }
          }
        }
      }
    });

    test('position questions expose position on a visible grid scene', () async {
      final questions = await ProfessionalIqEngine().compose(
        level: 10,
        count: 320,
        sessionSeed: 150004,
        fixedSession: true,
      );
      for (final q in questions.where(
        (q) => q.family == ProfessionalIqFamily.sizePosition,
      )) {
        expect(q.scene, ProfessionalIqScene.spatialGrid);
        expect(q.options.map((f) => '${f.position}:${f.size}').toSet().length, 4);
      }
    });

    test('series-style questions stay at or below one quarter of a session', () async {
      bool isSeries(ProfessionalIqFamily f) =>
          f == ProfessionalIqFamily.colorPattern ||
          f == ProfessionalIqFamily.countRelation ||
          f == ProfessionalIqFamily.sizePosition ||
          f == ProfessionalIqFamily.visualSeries;

      for (int seed = 0; seed < 20; seed++) {
        final questions = await ProfessionalIqEngine().compose(
          level: 10,
          count: 12,
          sessionSeed: 150100 + seed,
          fixedSession: true,
        );
        final count = questions.where((q) => isSeries(q.family)).length;
        expect(count, lessThanOrEqualTo(3), reason: 'seed=$seed');
      }
    });

    test('recognizable object motif pool is actually used', () async {
      final questions = await ProfessionalIqEngine().compose(
        level: 10,
        count: 480,
        sessionSeed: 150005,
        fixedSession: true,
      );
      final motifs = <int>{};
      for (final q in questions) {
        for (final f in q.board.whereType<ProfessionalIqFigure>()) {
          if (!f.isDotPattern) motifs.add(f.shape);
        }
        for (final f in q.options) {
          if (!f.isDotPattern) motifs.add(f.shape);
        }
      }
      expect(ProfessionalIqEngine.motifCount, 20);
      expect(motifs.where((id) => id >= 12).length, greaterThanOrEqualTo(6));
    });
  });
}
