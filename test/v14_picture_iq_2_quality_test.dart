import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_engine.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_models.dart';

bool isSeriesFamily(ProfessionalIqFamily family) =>
    family == ProfessionalIqFamily.colorPattern ||
    family == ProfessionalIqFamily.shapeTransform ||
    family == ProfessionalIqFamily.rotation ||
    family == ProfessionalIqFamily.countRelation ||
    family == ProfessionalIqFamily.sizePosition ||
    family == ProfessionalIqFamily.visualSeries;

void main() {
  group('V14 Görsel Akıl 2.0 kalite kapısı', () {
    test('başlangıç seviyesi tek tip seri sorularına sıkışmaz', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 1,
            count: 24,
            sessionSeed: 140001,
            fixedSession: true,
          );
      expect(
        questions.map((ProfessionalIqQuestion q) => q.family).toSet(),
        containsAll(<ProfessionalIqFamily>{
          ProfessionalIqFamily.analogy,
          ProfessionalIqFamily.oddOneOut,
          ProfessionalIqFamily.rotation,
          ProfessionalIqFamily.mirror,
        }),
      );
      expect(
        questions.where((ProfessionalIqQuestion q) => isSeriesFamily(q.family)).length,
        lessThan(questions.length ~/ 2),
      );
    });

    test('şıklar oyuncunun gördüğü biçimde daima benzersizdir', () async {
      for (int seed = 0; seed < 16; seed++) {
        final List<ProfessionalIqQuestion> questions =
            await ProfessionalIqEngine().compose(
              level: 10,
              count: 120,
              sessionSeed: 140100 + seed,
              fixedSession: true,
            );
        for (final ProfessionalIqQuestion q in questions) {
          expect(q.options.length, 4, reason: q.family.name);
          expect(
            q.options
                .map((ProfessionalIqFigure f) => f.visibleSignature)
                .toSet()
                .length,
            4,
            reason: 'render duplicate: ${q.family.name}',
          );
        }
      }
    });

    test('görsel havuz üçgen-kare döngüsünden çok daha geniştir', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 320,
            sessionSeed: 140220,
            fixedSession: true,
          );
      final Set<int> motifs = <int>{};
      for (final ProfessionalIqQuestion q in questions) {
        for (final ProfessionalIqFigure? f in q.board) {
          if (f != null && !f.isDotPattern) motifs.add(f.shape);
        }
        for (final ProfessionalIqFigure f in q.options) {
          if (!f.isDotPattern) motifs.add(f.shape);
        }
      }
      expect(motifs.length, greaterThanOrEqualTo(10));
      expect(motifs.every((int id) => id >= 0 && id < ProfessionalIqEngine.motifCount), isTrue);
    });

    test('aykırıyı bul sorusunda yalnız bir 3+1 ana kural vardır', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 320,
            sessionSeed: 140330,
            fixedSession: true,
          );

      bool threeEqual(Iterable<int> values) {
        final Map<int, int> counts = <int, int>{};
        for (final int value in values) {
          counts[value] = (counts[value] ?? 0) + 1;
        }
        return counts.values.contains(3);
      }

      for (final ProfessionalIqQuestion q in questions.where(
        (ProfessionalIqQuestion item) =>
            item.family == ProfessionalIqFamily.oddOneOut,
      )) {
        final int ruleCount = <bool>[
          threeEqual(q.options.map((ProfessionalIqFigure f) => f.color)),
          threeEqual(q.options.map((ProfessionalIqFigure f) => f.count)),
          threeEqual(q.options.map((ProfessionalIqFigure f) => f.size)),
          threeEqual(q.options.map((ProfessionalIqFigure f) => f.rotation)),
        ].where((bool value) => value).length;
        expect(ruleCount, 1, reason: q.fingerprint);
      }
    });
  });
}
