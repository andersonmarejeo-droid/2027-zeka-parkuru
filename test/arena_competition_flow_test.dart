import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _source(String path) => File(path).readAsStringSync();

void main() {
  group('Arena entry and shared competition flow', () {
    test('three arena entries use one working card component', () {
      final String arena = _source('lib/pages/arena_page.dart');

      expect(arena, contains("'ARKADAŞLARINA MEYDAN OKU'"));
      expect(arena, contains('class _ArenaActionCard'));
      expect(
        RegExp(r'_ArenaActionCard\(').allMatches(arena).length,
        greaterThanOrEqualTo(4),
      );
      expect(arena, contains("'BİREBİR DÜELLO'"));
      expect(arena, contains("'GRUP OLUŞTUR'"));
      expect(arena, contains("'KODLA KATIL'"));
      expect(arena, contains('onTap: _createGroup'));
      expect(arena, contains('onTap: _joinGroup'));
    });

    test('duel and group share retry skip and leave decisions', () {
      final String arena = _source('lib/pages/arena_page.dart');
      final String challenge = _source('lib/pages/challenge_center_page.dart');
      final String decision = _source(
        'lib/widgets/competition_exit_decision.dart',
      );

      expect(decision, contains('enum CompetitionExitDecision'));
      expect(decision, contains('CompetitionExitDecision.retry'));
      expect(decision, contains('CompetitionExitDecision.skip'));
      expect(decision, contains('CompetitionExitDecision.leave'));
      expect(decision, contains('isDismissible: false'));
      expect(decision, contains('enableDrag: false'));

      for (final String page in <String>[arena, challenge]) {
        expect(page, contains('showCompetitionExitDecision('));
        expect(page, contains('CompetitionExitDecision.retry'));
        expect(page, contains('CompetitionExitDecision.skip'));
        expect(page, contains('CompetitionExitDecision.leave'));
      }
    });

    test('group saves one result before checkpoint and transition', () {
      final String arena = _source('lib/pages/arena_page.dart');
      final String service = _source('lib/services/arena_service.dart');

      final int submitIndex = arena.indexOf('await _arena.submitAttempt(');
      final int checkpointIndex = arena.indexOf(
        'await _saveCheckpoint(currentCheckpoint)',
      );
      final int transitionIndex = arena.indexOf(
        'CompetitionStageTransition.show(',
      );

      expect(submitIndex, greaterThanOrEqualTo(0));
      expect(checkpointIndex, greaterThan(submitIndex));
      expect(transitionIndex, greaterThan(checkpointIndex));
      expect(arena, contains('nextStationIndex: index + 1'));
      expect(arena, contains('ArenaAttemptOutcome.failed'));
      expect(arena, contains('ArenaAttemptOutcome.skipped'));
      expect(arena, isNot(contains('class _ArenaSeriesGameShell')));

      expect(service, contains('arena_pending_attempts_v1'));
      expect(service, contains('_existingAttemptMatches'));
      expect(service, contains('_canQueueAttemptError'));
    });

    test('all eleven games stay behind the common competition builder', () {
      final String arena = _source('lib/pages/arena_page.dart');
      final String catalog = _source('lib/pages/challenge_game_catalog.dart');

      const List<String> gameIds = <String>[
        'logic',
        'numbers',
        'picture_iq',
        'memory',
        'reflex',
        'shape_puzzle',
        'blocks',
        'hanoi',
        'word_hunt',
        'candy_sort',
        'number_sort',
      ];

      for (final String gameId in gameIds) {
        expect(catalog, contains("case '$gameId':"), reason: gameId);
      }

      expect(arena, contains('buildChallengeCompetitionPage('));
      expect(arena, isNot(contains('Widget _competitionPage(')));
      expect(catalog, contains('challengeGameDefinitions'));
    });

    test('group and duel each select six games from eleven', () {
      final String arena = _source('lib/services/arena_service.dart');
      final String challenge = _source(
        'lib/services/social_challenge_service.dart',
      );

      expect(arena, contains('requestedPool.length >= 6'));
      expect(arena, contains('shuffledGames.take(6)'));
      expect(arena, contains("'schemaVersion': 2"));
      expect(arena, contains("'gameIds': games"));

      expect(challenge, contains('List<String>.from(pool)..shuffle(_random)'));
      expect(challenge, contains('shuffled.take(6)'));
      expect(challenge, contains("'schemaVersion': 4"));
      expect(challenge, contains("'gameIds': gameIds"));
      expect(challenge, contains("'layoutCodes': layoutCodes"));
    });
  });
}
