import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/services/arena_run_progress_service.dart';

import 'test_preferences.dart';

String _source(String path) => File(path).readAsStringSync();

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  group('Group six-game flow contract', () {
    test('checkpoint preserves every resolved outcome counter', () {
      const ArenaRunCheckpoint source = ArenaRunCheckpoint(
        eventId: 'event-1',
        playerUid: 'player-1',
        parkourFingerprint: 'arena-v2|event-1|2|1|logic,memory|10,20',
        nextStationIndex: 2,
        totalPoints: 700,
        totalStars: 2,
        failedStages: 1,
        skippedStages: 0,
      );

      final ArenaRunCheckpoint? decoded = ArenaRunCheckpoint.tryParse(
        jsonEncode(source.toJson()),
      );

      expect(decoded, isNotNull);
      expect(decoded!.eventId, source.eventId);
      expect(decoded.playerUid, source.playerUid);
      expect(decoded.parkourFingerprint, source.parkourFingerprint);
      expect(decoded.nextStationIndex, source.nextStationIndex);
      expect(decoded.totalPoints, source.totalPoints);
      expect(decoded.totalStars, source.totalStars);
      expect(decoded.failedStages, source.failedStages);
      expect(decoded.skippedStages, source.skippedStages);
    });

    test(
      'local checkpoint prevents replay while cloud snapshot catches up',
      () async {
        final ArenaRunProgressService service =
            ArenaRunProgressService.instance;
        const ArenaRunCheckpoint local = ArenaRunCheckpoint(
          eventId: 'event-local',
          playerUid: 'player-local',
          parkourFingerprint: 'fingerprint-local',
          nextStationIndex: 3,
          totalPoints: 1700,
          totalStars: 5,
          failedStages: 1,
          skippedStages: 0,
        );
        await service.save(local);

        final ArenaRunCheckpoint merged = await service.loadOrCreate(
          eventId: local.eventId,
          playerUid: local.playerUid,
          parkourFingerprint: local.parkourFingerprint,
          stationCount: 6,
          authoritativeNextStationIndex: 1,
          authoritativeTotalPoints: 400,
          authoritativeTotalStars: 1,
          authoritativeFailedStages: 0,
          authoritativeSkippedStages: 0,
        );

        expect(merged.nextStationIndex, 3);
        expect(merged.totalPoints, 1700);
        expect(merged.failedStages, 1);
      },
    );

    test('new group race selects six unique games from active catalog', () {
      final String service = _source('lib/services/arena_service.dart');
      final String rules = _source('firestore.rules');

      expect(service, contains('.take(eventGameCount)'));
      expect(service, contains('requestedPool.length >= eventGameCount'));
      expect(service, contains("'gameIds': games"));
      expect(service, contains("'schemaVersion': 2"));

      expect(rules, contains('data.gameIds.size() == 6'));
      expect(rules, contains('data.gameIds.toSet().size() == 6'));
      expect(rules, contains('validArenaEventCreate(data, uid, eventId)'));
    });

    test('all game outcomes use one coordinator without a nested shell', () {
      final String page = _source('lib/pages/arena_page.dart');
      final String catalog = _source('lib/pages/challenge_game_catalog.dart');

      expect(page, contains('buildChallengeCompetitionPage('));
      expect(page, contains('rawResult is DailyStageResult'));
      expect(page, contains('DailyStageOutcome.completed'));
      expect(page, contains('DailyStageOutcome.failed'));
      expect(page, contains('DailyStageOutcome.skipped'));
      expect(page, contains('DailyStageOutcome.exited'));
      expect(page, contains('showCompetitionExitDecision('));
      expect(page, contains('CompetitionExitDecision.retry'));
      expect(page, contains('CompetitionExitDecision.skip'));
      expect(page, contains('CompetitionExitDecision.leave'));
      expect(page, contains('CompetitionStageTransition.show('));
      expect(page, isNot(contains('class _ArenaSeriesGameShell')));
      expect(page, isNot(contains('Widget _competitionPage(')));

      const List<String> gameIds = <String>[
        'logic',
        'numbers',
        'blocks',
        'memory',
        'hanoi',
        'word_hunt',
        'picture_iq',
        'candy_sort',
        'number_sort',
        'shape_puzzle',
        'reflex',
      ];
      for (final String gameId in gameIds) {
        expect(catalog, contains("case '$gameId':"), reason: gameId);
      }
    });

    test('resolved stage is durable and cannot be replayed', () {
      final String page = _source('lib/pages/arena_page.dart');
      final String service = _source('lib/services/arena_service.dart');

      expect(page, contains('ArenaRunProgressService.instance'));
      expect(page, contains('await _arena.submitAttempt('));
      expect(page, contains('await _saveCheckpoint(currentCheckpoint)'));
      expect(page, contains('nextStationIndex: index + 1'));
      expect(page, contains('event.gameIds.take(localNext)'));
      expect(page, contains('gameId == nextGameId'));

      expect(
        service,
        contains(r"final String documentId = '${event.id}--$uid--$gameId'"),
      );
      expect(
        service,
        contains('existing[\'outcome\'] == pending[\'outcome\']'),
      );
      expect(service, contains('_canQueueAttemptError'));
      expect(service, isNot(contains("const <String>{'permission-denied'")));
    });

    test('failed and skipped stages score zero and active event is atomic', () {
      final String service = _source('lib/services/arena_service.dart');
      final String rules = _source('firestore.rules');

      expect(service, contains('ArenaAttemptOutcome.failed'));
      expect(service, contains('ArenaAttemptOutcome.skipped'));
      expect(service, contains("? competitionPoints(safeStars)"));
      expect(service, contains(": 0"));
      expect(service, contains("'activeEventId': reference.id"));
      expect(service, contains("'activeEventId': null"));

      expect(
        rules,
        contains("data.outcome in ['completed', 'failed', 'skipped']"),
      );
      expect(rules, contains("data.outcome in ['failed', 'skipped']"));
      expect(rules, contains('data.points == 0'));
      expect(rules, contains('validArenaGroupEventLink(groupId)'));
      expect(rules, contains('arenaEventExistsAfter(newEventId)'));
      expect(
        rules,
        contains('arenaGroupDataAfter(groupId).activeEventId == null'),
      );
    });

    test('join requires code proof bound to the joining user', () {
      final String service = _source('lib/services/arena_service.dart');
      final String rules = _source('firestore.rules');

      expect(service, contains(r"'joinCodeProof': '$code:$uid'"));
      expect(
        rules,
        contains("resource.data.joinCode + ':' + request.auth.uid"),
      );
    });
  });
}
