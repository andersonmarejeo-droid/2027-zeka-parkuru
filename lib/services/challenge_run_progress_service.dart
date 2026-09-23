import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_bootstrap_service.dart';

class ChallengeRunCheckpoint {
  final String challengeId;
  final String playerUid;
  final String parkourFingerprint;
  final int nextStationIndex;
  final int totalScore;
  final int totalStars;
  final int elapsedMs;
  final int skips;
  final int? activeStationStartedAtMs;

  const ChallengeRunCheckpoint({
    required this.challengeId,
    required this.playerUid,
    required this.parkourFingerprint,
    required this.nextStationIndex,
    required this.totalScore,
    required this.totalStars,
    required this.elapsedMs,
    required this.skips,
    required this.activeStationStartedAtMs,
  });

  factory ChallengeRunCheckpoint.fresh({
    required String challengeId,
    required String playerUid,
    required String parkourFingerprint,
  }) {
    return ChallengeRunCheckpoint(
      challengeId: challengeId,
      playerUid: playerUid,
      parkourFingerprint: parkourFingerprint,
      nextStationIndex: 0,
      totalScore: 0,
      totalStars: 0,
      elapsedMs: 0,
      skips: 0,
      activeStationStartedAtMs: null,
    );
  }

  ChallengeRunCheckpoint copyWith({
    int? nextStationIndex,
    int? totalScore,
    int? totalStars,
    int? elapsedMs,
    int? skips,
    int? activeStationStartedAtMs,
    bool clearActiveStationStartedAt = false,
  }) {
    return ChallengeRunCheckpoint(
      challengeId: challengeId,
      playerUid: playerUid,
      parkourFingerprint: parkourFingerprint,
      nextStationIndex: nextStationIndex ?? this.nextStationIndex,
      totalScore: totalScore ?? this.totalScore,
      totalStars: totalStars ?? this.totalStars,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      skips: skips ?? this.skips,
      activeStationStartedAtMs: clearActiveStationStartedAt
          ? null
          : activeStationStartedAtMs ?? this.activeStationStartedAtMs,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': 1,
    'challengeId': challengeId,
    'playerUid': playerUid,
    'parkourFingerprint': parkourFingerprint,
    'nextStationIndex': nextStationIndex,
    'totalScore': totalScore,
    'totalStars': totalStars,
    'elapsedMs': elapsedMs,
    'skips': skips,
    'activeStationStartedAtMs': activeStationStartedAtMs,
  };

  static ChallengeRunCheckpoint? tryParse(String source) {
    try {
      final dynamic decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
        return null;
      }

      int nonNegativeInt(String key) {
        final dynamic value = decoded[key];
        if (value is! num) return 0;
        return value.toInt().clamp(0, 86400000).toInt();
      }

      final String challengeId = decoded['challengeId'] is String
          ? decoded['challengeId'] as String
          : '';
      final String playerUid = decoded['playerUid'] is String
          ? decoded['playerUid'] as String
          : '';
      final String fingerprint = decoded['parkourFingerprint'] is String
          ? decoded['parkourFingerprint'] as String
          : '';

      if (challengeId.isEmpty || playerUid.isEmpty || fingerprint.isEmpty) {
        return null;
      }

      final dynamic rawStartedAt = decoded['activeStationStartedAtMs'];
      final int? startedAt = rawStartedAt is num && rawStartedAt.toInt() > 0
          ? rawStartedAt.toInt()
          : null;

      return ChallengeRunCheckpoint(
        challengeId: challengeId,
        playerUid: playerUid,
        parkourFingerprint: fingerprint,
        nextStationIndex: nonNegativeInt('nextStationIndex'),
        totalScore: nonNegativeInt('totalScore'),
        totalStars: nonNegativeInt('totalStars'),
        elapsedMs: nonNegativeInt('elapsedMs'),
        skips: nonNegativeInt('skips'),
        activeStationStartedAtMs: startedAt,
      );
    } catch (_) {
      return null;
    }
  }
}

class ChallengeRunProgressService {
  ChallengeRunProgressService._();

  static final ChallengeRunProgressService instance =
      ChallengeRunProgressService._();

  static const Duration _remoteTimeout = Duration(seconds: 8);

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<void> _remoteTail = Future<void>.value();

  CollectionReference<Map<String, dynamic>> get _remoteProgress =>
      FirebaseFirestore.instance.collection('challenge_progress_v1');

  String _key(String challengeId, String playerUid) =>
      'challenge_run_v1_${playerUid}_$challengeId';

  String _remoteDocumentId(String challengeId, String playerUid) =>
      '$challengeId--$playerUid';

  bool _remoteAvailable(String playerUid) {
    final FirebaseBootstrapService firebase = FirebaseBootstrapService.instance;
    return firebase.ready && firebase.uid == playerUid;
  }

  ChallengeRunCheckpoint? _decodeRemote(Map<String, dynamic>? source) {
    if (source == null) return null;

    final Map<String, dynamic> json = Map<String, dynamic>.from(source)
      ..remove('updatedAt');

    return ChallengeRunCheckpoint.tryParse(jsonEncode(json));
  }

  bool _isUsable({
    required ChallengeRunCheckpoint? checkpoint,
    required String challengeId,
    required String playerUid,
    required String parkourFingerprint,
    required int stationCount,
  }) {
    return checkpoint != null &&
        checkpoint.challengeId == challengeId &&
        checkpoint.playerUid == playerUid &&
        checkpoint.parkourFingerprint == parkourFingerprint &&
        checkpoint.nextStationIndex <= stationCount;
  }

  int _compareProgress(
    ChallengeRunCheckpoint left,
    ChallengeRunCheckpoint right,
  ) {
    final List<int> leftValues = <int>[
      left.nextStationIndex,
      left.totalScore,
      left.totalStars,
      left.skips,
      left.elapsedMs,
    ];

    final List<int> rightValues = <int>[
      right.nextStationIndex,
      right.totalScore,
      right.totalStars,
      right.skips,
      right.elapsedMs,
    ];

    for (int index = 0; index < leftValues.length; index++) {
      final int result = leftValues[index].compareTo(rightValues[index]);
      if (result != 0) return result;
    }

    return 0;
  }

  ChallengeRunCheckpoint? _mostAdvanced(
    ChallengeRunCheckpoint? local,
    ChallengeRunCheckpoint? remote,
  ) {
    if (local == null) return remote;
    if (remote == null) return local;

    return _compareProgress(local, remote) >= 0 ? local : remote;
  }

  Future<ChallengeRunCheckpoint?> _loadLocal({
    required String challengeId,
    required String playerUid,
  }) async {
    final String key = _key(challengeId, playerUid);
    final String? encoded = await _preferences.getString(key);

    if (encoded == null) return null;

    final ChallengeRunCheckpoint? checkpoint = ChallengeRunCheckpoint.tryParse(
      encoded,
    );

    if (checkpoint == null) {
      await _preferences.remove(key);
    }

    return checkpoint;
  }

  Future<ChallengeRunCheckpoint?> _loadRemote({
    required String challengeId,
    required String playerUid,
  }) async {
    if (!_remoteAvailable(playerUid)) return null;

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _remoteProgress
              .doc(_remoteDocumentId(challengeId, playerUid))
              .get()
              .timeout(_remoteTimeout);

      if (!snapshot.exists) return null;
      return _decodeRemote(snapshot.data());
    } catch (error, stackTrace) {
      debugPrint('Challenge progress remote load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> _saveLocal(ChallengeRunCheckpoint checkpoint) {
    return _preferences.setString(
      _key(checkpoint.challengeId, checkpoint.playerUid),
      jsonEncode(checkpoint.toJson()),
    );
  }

  void _queueRemote({
    required String playerUid,
    required String label,
    required Future<void> Function() operation,
  }) {
    if (!_remoteAvailable(playerUid)) return;

    final Future<void> previous = _remoteTail;

    Future<void> run() async {
      try {
        await previous;
      } catch (_) {
        // Önceki çevrim içi işlem başarısız olsa da yerel kuyruk devam eder.
      }

      if (!_remoteAvailable(playerUid)) return;

      try {
        await operation().timeout(_remoteTimeout);
      } catch (error, stackTrace) {
        debugPrint('Challenge progress $label failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    _remoteTail = run();
  }

  void _queueRemoteSave(ChallengeRunCheckpoint checkpoint) {
    _queueRemote(
      playerUid: checkpoint.playerUid,
      label: 'remote save',
      operation: () => _remoteProgress
          .doc(_remoteDocumentId(checkpoint.challengeId, checkpoint.playerUid))
          .set(<String, dynamic>{
            ...checkpoint.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          }),
    );
  }

  void _queueRemoteDelete({
    required String challengeId,
    required String playerUid,
  }) {
    _queueRemote(
      playerUid: playerUid,
      label: 'remote delete',
      operation: () => _remoteProgress
          .doc(_remoteDocumentId(challengeId, playerUid))
          .delete(),
    );
  }

  Future<ChallengeRunCheckpoint> loadOrCreate({
    required String challengeId,
    required String playerUid,
    required String parkourFingerprint,
    required int stationCount,
  }) async {
    final ChallengeRunCheckpoint? local = await _loadLocal(
      challengeId: challengeId,
      playerUid: playerUid,
    );

    final ChallengeRunCheckpoint? remote = await _loadRemote(
      challengeId: challengeId,
      playerUid: playerUid,
    );

    final ChallengeRunCheckpoint? validLocal =
        _isUsable(
          checkpoint: local,
          challengeId: challengeId,
          playerUid: playerUid,
          parkourFingerprint: parkourFingerprint,
          stationCount: stationCount,
        )
        ? local
        : null;

    final ChallengeRunCheckpoint? validRemote =
        _isUsable(
          checkpoint: remote,
          challengeId: challengeId,
          playerUid: playerUid,
          parkourFingerprint: parkourFingerprint,
          stationCount: stationCount,
        )
        ? remote
        : null;

    if (local != null && validLocal == null) {
      await _preferences.remove(_key(challengeId, playerUid));
    }

    if (remote != null && validRemote == null) {
      _queueRemoteDelete(challengeId: challengeId, playerUid: playerUid);
    }

    final ChallengeRunCheckpoint? selected = _mostAdvanced(
      validLocal,
      validRemote,
    );

    if (selected == null) {
      return ChallengeRunCheckpoint.fresh(
        challengeId: challengeId,
        playerUid: playerUid,
        parkourFingerprint: parkourFingerprint,
      );
    }

    await _saveLocal(selected);

    if (validRemote == null ||
        (validLocal != null && _compareProgress(validLocal, validRemote) > 0)) {
      _queueRemoteSave(selected);
    }

    return selected;
  }

  Future<bool> hasProgress({
    required String challengeId,
    required String playerUid,
  }) async {
    final ChallengeRunCheckpoint? local = await _loadLocal(
      challengeId: challengeId,
      playerUid: playerUid,
    );

    if (local != null &&
        local.challengeId == challengeId &&
        local.playerUid == playerUid &&
        local.nextStationIndex > 0) {
      return true;
    }

    final ChallengeRunCheckpoint? remote = await _loadRemote(
      challengeId: challengeId,
      playerUid: playerUid,
    );

    return remote != null &&
        remote.challengeId == challengeId &&
        remote.playerUid == playerUid &&
        remote.nextStationIndex > 0;
  }

  Future<void> save(ChallengeRunCheckpoint checkpoint) async {
    // Oyun hiçbir zaman ağ yanıtını beklemez; önce cihaz kaydı tamamlanır.
    await _saveLocal(checkpoint);
    _queueRemoteSave(checkpoint);
  }

  Future<void> clear({
    required String challengeId,
    required String playerUid,
  }) async {
    await _preferences.remove(_key(challengeId, playerUid));

    _queueRemoteDelete(challengeId: challengeId, playerUid: playerUid);
  }
}
