import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_engine.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_localizations.dart';
import 'package:zeka_parkuru/games/picture_iq/professional_iq_models.dart';

void main() {
  group('V11.1 professional visual reasoning engine', () {
    test('all sixteen question families are available by level ten', () {
      final List<ProfessionalIqFamily> families =
          ProfessionalIqEngine.familiesForLevel(10);
      expect(ProfessionalIqFamily.values.length, 16);
      expect(families.toSet(), ProfessionalIqFamily.values.toSet());
      expect(ProfessionalIqEngine.familyCount, 16);
      expect(ProfessionalIqEngine.structuralTemplatesPerFamily, 10);
      expect(ProfessionalIqEngine.estimatedEquivalentVariants, 12000);
      expect(ProfessionalIqEngine.historyLimit, 250);
    });

    test(
      'fixed Arena sessions are deterministic and structurally valid',
      () async {
        final ProfessionalIqEngine engine = ProfessionalIqEngine();
        final List<ProfessionalIqQuestion> first = await engine.compose(
          level: 10,
          count: 24,
          sessionSeed: 731991,
          fixedSession: true,
        );
        final List<ProfessionalIqQuestion> second = await engine.compose(
          level: 10,
          count: 24,
          sessionSeed: 731991,
          fixedSession: true,
        );

        expect(
          first.map((ProfessionalIqQuestion item) => item.fingerprint),
          second.map((ProfessionalIqQuestion item) => item.fingerprint),
        );
        for (final ProfessionalIqQuestion question in first) {
          expect(question.options.length, 4);
          expect(
            question.options.map((item) => item.signature).toSet().length,
            4,
          );
          expect(question.correctIndex, inInclusiveRange(0, 3));
          expect(question.answer, question.options[question.correctIndex]);
        }
      },
    );

    test('family scheduling is balanced', () async {
      final List<ProfessionalIqQuestion> questions =
          await ProfessionalIqEngine().compose(
            level: 10,
            count: 64,
            sessionSeed: 20261101,
            fixedSession: true,
          );
      final int analogyCount = questions
          .where((item) => item.family == ProfessionalIqFamily.analogy)
          .length;
      expect(analogyCount, lessThanOrEqualTo(questions.length ~/ 4));
      for (int index = 2; index < questions.length; index++) {
        expect(
          questions[index].family == questions[index - 1].family &&
              questions[index].family == questions[index - 2].family,
          isFalse,
        );
      }
    });

    test('palette-only swaps do not count as fresh logical content', () {
      const ProfessionalIqFigure first = ProfessionalIqFigure(
        shape: 1,
        color: 0,
        rotation: 2,
        count: 2,
        size: 1,
        pattern: 3,
        position: 4,
      );
      final ProfessionalIqFigure recolored = first.copyWith(color: 4);
      expect(first.signature, isNot(recolored.signature));
      expect(first.logicSignature, recolored.logicSignature);
    });

    test('result is a skill profile and never a clinical IQ score', () {
      final ProfessionalIqSessionProfile profile = buildProfessionalIqProfile(
        const <ProfessionalIqAnswerRecord>[
          ProfessionalIqAnswerRecord(
            skill: ProfessionalIqSkill.visualPattern,
            correct: true,
            responseMillis: 3500,
          ),
          ProfessionalIqAnswerRecord(
            skill: ProfessionalIqSkill.spatialReasoning,
            correct: false,
            responseMillis: 7200,
          ),
        ],
      );
      expect(profile.skills.length, 6);
      expect(profile.strongest, isNotNull);
      expect(profile.growthArea, isNotNull);

      final String page = File('lib/games/picture_iq/picture_iq_game_page.dart')
          .readAsStringSync();
      expect(page, contains('buildProfessionalIqProfile'));
      expect(page, contains("copy.text('notClinical')"));
      expect(page, isNot(contains('IQ puanı')));
      expect(page, isNot(contains('IQ score')));
    });

    test('professional copy covers all eight languages', () {
      const List<Locale> locales = <Locale>[
        Locale('tr'),
        Locale('en'),
        Locale('ar'),
        Locale('id'),
        Locale('pt', 'BR'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
      ];
      for (final Locale locale in locales) {
        final ProfessionalIqCopy copy = ProfessionalIqCopy(locale);
        expect(copy.text('skillProfile'), isNot('skillProfile'));
        expect(copy.text('notClinical'), isNot('notClinical'));
        for (final ProfessionalIqFamily family in ProfessionalIqFamily.values) {
          expect(copy.familyName(family), isNot('family_${family.name}'));
        }
      }
    });

    test('feedback waits for an explicit next action', () {
      final String page = File('lib/games/picture_iq/picture_iq_game_page.dart')
          .readAsStringSync();
      expect(page, contains('Future<void> _nextQuestion()'));
      expect(page, contains("copy.text('nextQuestion')"));
      expect(page, isNot(contains('Future<void>.delayed')));
    });
  });
}
