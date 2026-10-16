import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _source(String path) => File(path).readAsStringSync();

void main() {
  group('1e1 duello 8 oyun sozlesmesi', () {
    test('yirmi bir oyun havuzundan tekrarsiz sekiz oyun secilir', () {
      final String service = _source(
        'lib/services/social_challenge_service.dart',
      );
      final String catalog = _source('lib/pages/challenge_game_catalog.dart');

      const List<String> gameIds = <String>[
        'logic',
        'numbers',
        'blocks',
        'memory',
        'card_pairs',
        'focus_filter',
        'rhythm_memory',
        'attention_tunnel',
        'reflex',
        'hanoi',
        'word_hunt',
        'meaning_match',
        'proverb_finish',
        'sentence_builder',
        'near_meaning',
        'letter_maze',
        'language_detective',
        'story_order',
        'picture_iq',
        'number_sort',
        'shape_puzzle',
      ];

      for (final String gameId in gameIds) {
        expect(service, contains("'$gameId'"), reason: gameId);
        expect(catalog, contains("case '$gameId':"), reason: gameId);
      }

      expect(catalog, contains('challengeGameDefinitions'));
      expect(
        RegExp(r"^\s*id: '[^']+',", multiLine: true).allMatches(catalog).length,
        gameIds.length,
      );
      expect(service, contains('List<String>.from(pool)..shuffle(_random)'));
      expect(service, contains('shuffled.take(8)'));
      expect(
        RegExp(
          r'List<int>\.generate\(\s*8,',
          multiLine: true,
        ).allMatches(service).length,
        2,
      );
      expect(service, contains("'schemaVersion': 2"));
    });

    test('eski duello sürümleri ve seri uzunlukları korunur', () {
      final String service = _source(
        'lib/services/social_challenge_service.dart',
      );

      expect(service, contains('if (schemaVersion >= 4) return 6;'));
      expect(service, contains('if (schemaVersion == 3) return 5;'));
      expect(service, contains('if (schemaVersion == 2) return 8;'));
    });

    test('tamamlandi basarisiz gecildi ve cikildi ayri islenir', () {
      final String page = _source('lib/pages/challenge_center_page.dart');

      expect(page, contains('rawResult is DailyStageResult'));
      expect(page, contains('case DailyStageOutcome.completed:'));
      expect(page, contains('case DailyStageOutcome.failed:'));
      expect(page, contains('case DailyStageOutcome.skipped:'));
      expect(page, contains('case DailyStageOutcome.exited:'));
      expect(page, contains('showCompetitionExitDecision('));
      expect(page, contains('case CompetitionExitDecision.retry:'));
      expect(page, contains('case CompetitionExitDecision.skip:'));
      expect(page, contains('case CompetitionExitDecision.leave:'));
      expect(page, contains('clearActiveStationStartedAt: true'));
      expect(page, contains('CompetitionStageTransition.show('));
      expect(
        page,
        matches(
          RegExp(
            r'await _runProgress\.save\(checkpoint\);\s+'
            r'if \(!mounted\) return;\s+'
            r'final DailyStageOutcome outcome;',
          ),
        ),
      );
      expect(page, isNot(contains('class _ChallengeSeriesGameShell')));
      expect(page, isNot(contains('class _ChallengeSeriesSkip')));
    });

    test('yalniz cozulmus bolum kontrol noktasini ilerletir', () {
      final String page = _source('lib/pages/challenge_center_page.dart');

      // Basari, otomatik basarisizlik ve kullanicinin bolumu gecmesi.
      expect(
        RegExp(r'nextStationIndex: index \+ 1').allMatches(page).length,
        3,
      );
      expect(page, contains('totalScore: checkpoint.totalScore + stageScore'));
      expect(page, contains('skips: checkpoint.skips + 1'));
      expect(page, contains('Bu bölüme kaldığın yerden'));
      expect(page, contains('setState(() => _busy = true);'));
    });

    test('V4 Firestore kurallari alti oyun ve tek sonucu dogrular', () {
      final String rules = _source('firestore.rules');

      expect(rules, contains('function validChallengeCreateV4'));
      expect(rules, contains('data.gameIds.size() == 6'));
      expect(rules, contains('data.gameIds.toSet().size() == 6'));
      expect(rules, contains('function validChallengeScoreV4'));
      expect(rules, contains('resource.data.schemaVersion == 4'));
      expect(
        rules,
        contains('<= (6 - request.resource.data.challengerSkips) * 3'),
      );
      expect(rules, contains('validChallengeScoreV4()'));
      expect(rules, contains('in [2, 3, 4]'));
      expect(rules, contains('data.nextStationIndex <= 6'));
    });

    test('uygulama kapaliyken gecen sure duello suresine eklenmez', () {
      final String page = _source('lib/pages/challenge_center_page.dart');
      final String progress = _source(
        'lib/services/challenge_run_progress_service.dart',
      );

      expect(page, contains('checkpoint.activeStationStartedAtMs != null'));
      expect(page, contains('clearActiveStationStartedAt: true'));

      final int compareStart = progress.indexOf('int _compareProgress(');
      final int compareEnd = progress.indexOf(
        'ChallengeRunCheckpoint? _mostAdvanced',
      );
      expect(compareStart, greaterThanOrEqualTo(0));
      expect(compareEnd, greaterThan(compareStart));
      expect(
        progress.substring(compareStart, compareEnd),
        isNot(contains('activeStationStartedAtMs')),
      );
    });
  });
}
