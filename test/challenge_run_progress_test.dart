import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/services/challenge_run_progress_service.dart';

void main() {
  test('meydan okuma kontrol noktası kayıpsız çözümlenir', () {
    const ChallengeRunCheckpoint source = ChallengeRunCheckpoint(
      challengeId: 'challenge-1',
      playerUid: 'player-1',
      parkourFingerprint: '3|logic,blocks|5,6|10,20',
      nextStationIndex: 2,
      totalScore: 1700,
      totalStars: 5,
      elapsedMs: 42000,
      skips: 1,
      activeStationStartedAtMs: 100000,
    );

    final ChallengeRunCheckpoint? decoded = ChallengeRunCheckpoint.tryParse(
      jsonEncode(source.toJson()),
    );

    expect(decoded, isNotNull);
    expect(decoded!.challengeId, source.challengeId);
    expect(decoded.playerUid, source.playerUid);
    expect(decoded.parkourFingerprint, source.parkourFingerprint);
    expect(decoded.nextStationIndex, source.nextStationIndex);
    expect(decoded.totalScore, source.totalScore);
    expect(decoded.totalStars, source.totalStars);
    expect(decoded.elapsedMs, source.elapsedMs);
    expect(decoded.skips, source.skips);
    expect(
      decoded.activeStationStartedAtMs,
      source.activeStationStartedAtMs,
    );
  });

  test('bozuk veya eski kontrol noktası reddedilir', () {
    expect(ChallengeRunCheckpoint.tryParse('bozuk-json'), isNull);
    expect(
      ChallengeRunCheckpoint.tryParse(
        jsonEncode(<String, dynamic>{'schemaVersion': 99}),
      ),
      isNull,
    );
  });

test('ilerleme Firestore ve yerel yedekle korunur', () {
    final String service = File(
      'lib/services/challenge_run_progress_service.dart',
    ).readAsStringSync();

    final String rules = File('firestore.rules').readAsStringSync();
    final String functions = File('functions/index.js').readAsStringSync();

    final String adminDelete = File(
      'functions/admin_tools/process_account_deletions.js',
    ).readAsStringSync();

    expect(service, contains("collection('challenge_progress_v1')"));
    expect(service, contains('await _saveLocal(checkpoint)'));
    expect(service, contains('_queueRemoteSave(checkpoint)'));
    expect(service, contains('FieldValue.serverTimestamp()'));
    expect(service, contains('remote load failed'));

    expect(
      rules,
      contains('match /challenge_progress_v1/{progressId}'),
    );
    expect(rules, contains('allow list: if false'));
    expect(rules, contains('validChallengeProgressData'));
    expect(
      rules,
      allOf(
        contains('request.resource.data.nextStationIndex'),
        contains('>= resource.data.nextStationIndex'),
      ),
    );

    expect(
      functions,
      contains(
        'deleteWhere("challenge_progress_v1", '
        '"playerUid", "==", uid)',
      ),
    );

    expect(
      adminDelete,
      contains(
        'deleteWhere(db, "challenge_progress_v1", '
        '"playerUid", "==", uid, execute, stats)',
      ),
    );
  });
}
