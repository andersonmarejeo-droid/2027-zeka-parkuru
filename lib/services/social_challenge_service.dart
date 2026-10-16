import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../features/catalog/domain/studio_game_catalog.dart';
import 'firebase_bootstrap_service.dart';
import 'online_leaderboard_service.dart';
import 'player_progress_service.dart';

class SocialChallenge {
  final String id;
  final String challengerUid;
  final String challengerName;
  final String challengerAvatar;
  final String? targetUid;
  final String? opponentUid;
  final String? opponentName;
  final String? opponentAvatar;
  final List<String> participantIds;
  final String status;

  // ----------------------------------------------------------
  // V1 TEK OYUN GERİYE UYUMLULUK
  // ----------------------------------------------------------
  final String gameId;
  final int level;
  final int seed;

  // ----------------------------------------------------------
  // V2: 21 oyundan seçilen 8 oyunluk seri.
  // V3: 5, V4: 21 oyundan seçilen 6 oyunluk seri.
  // ----------------------------------------------------------
  final int schemaVersion;
  final List<String> gameIds;
  final List<int> levels;
  final List<int> layoutCodes;

  final int? challengerScore;
  final int? challengerStars;
  final int? challengerTimeMs;
  final int? challengerSkips;

  final int? opponentScore;
  final int? opponentStars;
  final int? opponentTimeMs;
  final int? opponentSkips;

  final String? challengerReaction;
  final String? opponentReaction;

  final String? winnerUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const SocialChallenge({
    required this.id,
    required this.challengerUid,
    required this.challengerName,
    required this.challengerAvatar,
    required this.targetUid,
    required this.opponentUid,
    required this.opponentName,
    required this.opponentAvatar,
    required this.participantIds,
    required this.status,
    required this.gameId,
    required this.level,
    required this.seed,
    required this.schemaVersion,
    required this.gameIds,
    required this.levels,
    required this.layoutCodes,
    required this.challengerScore,
    required this.challengerStars,
    required this.challengerTimeMs,
    required this.challengerSkips,
    required this.opponentScore,
    required this.opponentStars,
    required this.opponentTimeMs,
    required this.opponentSkips,
    required this.challengerReaction,
    required this.opponentReaction,
    required this.winnerUid,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });

  factory SocialChallenge.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};

    DateTime? dateOf(dynamic value) {
      return value is Timestamp ? value.toDate() : null;
    }

    String? nullableText(dynamic value) {
      if (value is! String || value.trim().isEmpty) return null;
      return value.trim();
    }

    int? nullableInt(dynamic value) {
      return value is num ? value.toInt() : null;
    }

    List<String> stringList(dynamic value) {
      if (value is! List) return const <String>[];
      return value.whereType<String>().toList(growable: false);
    }

    List<int> intList(dynamic value) {
      if (value is! List) return const <int>[];
      return value
          .whereType<num>()
          .map((value) => value.toInt())
          .toList(growable: false);
    }

    final String legacyGameId = data['gameId'] is String
        ? data['gameId'] as String
        : 'reflex';

    final int legacyLevel = data['level'] is num
        ? (data['level'] as num).toInt()
        : 1;

    final int legacySeed = data['seed'] is num
        ? (data['seed'] as num).toInt()
        : 1;

    final int version = data['schemaVersion'] is num
        ? (data['schemaVersion'] as num).toInt()
        : 1;

    final List<String> parsedGameIds = stringList(data['gameIds']);
    final List<int> parsedLevels = intList(data['levels']);
    final List<int> parsedLayoutCodes = intList(data['layoutCodes']);

    return SocialChallenge(
      id: snapshot.id,
      challengerUid: data['challengerUid'] is String
          ? data['challengerUid'] as String
          : '',
      challengerName: data['challengerName'] is String
          ? data['challengerName'] as String
          : 'Oyuncu',
      challengerAvatar: data['challengerAvatar'] is String
          ? data['challengerAvatar'] as String
          : '🧠',
      targetUid: nullableText(data['targetUid']),
      opponentUid: nullableText(data['opponentUid']),
      opponentName: nullableText(data['opponentName']),
      opponentAvatar: nullableText(data['opponentAvatar']),
      participantIds: data['participantIds'] is List
          ? (data['participantIds'] as List).whereType<String>().toList(
              growable: false,
            )
          : const <String>[],
      status: data['status'] is String ? data['status'] as String : 'pending',

      // V1
      gameId: legacyGameId,
      level: legacyLevel,
      seed: legacySeed,

      // V2
      schemaVersion: version,
      gameIds: parsedGameIds.isNotEmpty
          ? parsedGameIds
          : <String>[legacyGameId],
      levels: parsedLevels.isNotEmpty ? parsedLevels : <int>[legacyLevel],
      layoutCodes: parsedLayoutCodes.isNotEmpty
          ? parsedLayoutCodes
          : <int>[legacySeed],

      challengerScore: nullableInt(data['challengerScore']),
      challengerStars: nullableInt(data['challengerStars']),
      challengerTimeMs: nullableInt(data['challengerTimeMs']),
      challengerSkips: nullableInt(data['challengerSkips']),

      opponentScore: nullableInt(data['opponentScore']),
      opponentStars: nullableInt(data['opponentStars']),
      opponentTimeMs: nullableInt(data['opponentTimeMs']),
      opponentSkips: nullableInt(data['opponentSkips']),

      challengerReaction: nullableText(data['challengerReaction']),
      opponentReaction: nullableText(data['opponentReaction']),

      winnerUid: nullableText(data['winnerUid']),
      createdAt: dateOf(data['createdAt']),
      updatedAt: dateOf(data['updatedAt']),
      expiresAt: dateOf(data['expiresAt']),
    );
  }

  bool get pending => status == 'pending';
  bool get accepted => status == 'accepted';
  bool get completed => status == 'completed';
  bool get declined => status == 'declined';

  bool get expired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  int get seriesGameCount {
    // Treat newer schemas as the current six-game series until a future
    // migration explicitly changes the contract.
    if (schemaVersion >= 4) return 6;
    if (schemaVersion == 3) return 5;
    if (schemaVersion == 2) return 8;
    return 0;
  }

  bool get isSeries =>
      seriesGameCount > 0 &&
      gameIds.length == seriesGameCount &&
      levels.length == seriesGameCount &&
      layoutCodes.length == seriesGameCount;

  /// Historical challenges can outlive the game that created them. They must
  /// not re-enter the playable parkour flow after that game is retired.
  bool get isPlayable => (isSeries ? gameIds : <String>[gameId]).every(
    StudioGameCatalog.isAvailable,
  );

  bool isChallenger(String uid) => uid == challengerUid;

  bool isOpponent(String uid) => uid == opponentUid || uid == targetUid;

  int? scoreFor(String uid) {
    if (uid == challengerUid) return challengerScore;
    if (uid == opponentUid) return opponentScore;
    return null;
  }

  int? starsFor(String uid) {
    if (uid == challengerUid) return challengerStars;
    if (uid == opponentUid) return opponentStars;
    return null;
  }

  int? timeFor(String uid) {
    if (uid == challengerUid) return challengerTimeMs;
    if (uid == opponentUid) return opponentTimeMs;
    return null;
  }

  int? skipsFor(String uid) {
    if (uid == challengerUid) return challengerSkips;
    if (uid == opponentUid) return opponentSkips;
    return null;
  }

  int levelForIndex(int index) {
    if (index < 0 || index >= levels.length) return level;
    return levels[index];
  }

  int layoutCodeForIndex(int index) {
    if (index < 0 || index >= layoutCodes.length) return seed;
    return layoutCodes[index];
  }

  String opponentLabelFor(String uid) {
    if (uid == challengerUid) {
      return opponentName ?? 'Rakip bekleniyor';
    }
    return challengerName;
  }

  String opponentAvatarFor(String uid) {
    if (uid == challengerUid) {
      return opponentAvatar ?? '⚔️';
    }
    return challengerAvatar;
  }
}

class SocialChallengeService {
  SocialChallengeService._();

  static final SocialChallengeService instance = SocialChallengeService._();

  static const String inviteBaseUrl =
      'https://zeka-parkuru-eu-2026.web.app/davet.html';

  final FirebaseBootstrapService _firebase = FirebaseBootstrapService.instance;
  final PlayerProgressService _player = PlayerProgressService.instance;
  final Random _random = Random.secure();

  CollectionReference<Map<String, dynamic>> get _challenges =>
      FirebaseFirestore.instance.collection('challenges_v1');

  CollectionReference<Map<String, dynamic>> get _friendships =>
      FirebaseFirestore.instance.collection('friendships_v1');

  String? get currentUid => _firebase.uid;
  String? get lastError => _firebase.lastError;

  String? get currentFriendCode {
    final String? uid = currentUid;
    if (uid == null) return null;
    return OnlineLeaderboardService.instance.friendCodeForUid(uid);
  }

  String inviteUrl(String challengeId) =>
      '$inviteBaseUrl?c=${Uri.encodeQueryComponent(challengeId)}';

  Future<bool> ensureOnline({bool forceRetry = false}) async {
    await _firebase.initialize(forceRetry: forceRetry);
    return _firebase.ready;
  }

  Stream<T> _restartableStream<T>(Stream<T> Function() sourceFactory) {
    return Stream<T>.multi((controller) {
      final subscription = sourceFactory().listen(
        controller.add,
        onError: (Object error, StackTrace stackTrace) {
          controller.addError(error, stackTrace);
        },
        onDone: () {
          controller.close();
        },
      );

      controller.onPause = () => subscription.pause();
      controller.onResume = subscription.resume;
      controller.onCancel = subscription.cancel;
    }, isBroadcast: true);
  }

  Stream<List<SocialChallenge>> watchMyChallenges() =>
      _restartableStream<List<SocialChallenge>>(_watchMyChallengesSingle);

  Stream<List<String>> watchFriendUids() =>
      _restartableStream<List<String>>(_watchFriendUidsSingle);

  Stream<List<SocialChallenge>> _watchMyChallengesSingle() async* {
    if (!await ensureOnline()) {
      yield const <SocialChallenge>[];
      return;
    }

    final String? uid = currentUid;
    if (uid == null) {
      yield const <SocialChallenge>[];
      return;
    }

    yield* _challenges
        .where('participantIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SocialChallenge.fromSnapshot)
              .where((SocialChallenge challenge) => challenge.isPlayable)
              .toList(growable: false),
        );
  }

  Stream<List<String>> _watchFriendUidsSingle() async* {
    if (!await ensureOnline()) {
      yield const <String>[];
      return;
    }

    final String? uid = currentUid;
    if (uid == null) {
      yield const <String>[];
      return;
    }

    yield* _friendships
        .where('members', arrayContains: uid)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final Set<String> result = <String>{};
          for (final document in snapshot.docs) {
            final dynamic rawMembers = document.data()['members'];
            if (rawMembers is! List) continue;
            result.addAll(
              rawMembers.whereType<String>().where((item) => item != uid),
            );
          }
          return result.toList(growable: false);
        });
  }

  Stream<SocialChallenge?> watchChallenge(String challengeId) =>
      _restartableStream<SocialChallenge?>(
        () => _watchChallengeSingle(challengeId),
      );

  Stream<SocialChallenge?> _watchChallengeSingle(String challengeId) async* {
    if (!await ensureOnline() || challengeId.trim().isEmpty) {
      yield null;
      return;
    }

    yield* _challenges.doc(challengeId.trim()).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return SocialChallenge.fromSnapshot(snapshot);
    });
  }

  Future<SocialChallenge?> getChallenge(String challengeId) async {
    if (!await ensureOnline() || challengeId.trim().isEmpty) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _challenges
          .doc(challengeId.trim())
          .get();
      return snapshot.exists ? SocialChallenge.fromSnapshot(snapshot) : null;
    } catch (error) {
      debugPrint('Challenge read failed: $error');
      return null;
    }
  }

  Future<SocialChallenge?> createSeriesChallenge({
    OnlineLeaderboardEntry? target,
  }) async {
    if (!await ensureOnline()) return null;

    final String? uid = currentUid;
    if (uid == null || target?.uid == uid) return null;

    const List<String> pool = <String>[
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

    final List<String> shuffled = List<String>.from(pool)..shuffle(_random);
    shuffled.removeWhere(
      (String gameId) => !StudioGameCatalog.isAvailable(gameId),
    );
    if (shuffled.length < 8) return null;

    final List<String> gameIds = shuffled.take(8).toList(growable: false);

    final List<int> levels = List<int>.generate(
      8,
      (_) => 5 + _random.nextInt(6),
      growable: false,
    );

    final List<int> layoutCodes = List<int>.generate(
      8,
      (_) => _random.nextInt(0x7ffffffe) + 1,
      growable: false,
    );

    final PlayerDashboardData dashboard = await _player.load();

    final DocumentReference<Map<String, dynamic>> reference = _challenges.doc();

    final DateTime expires = DateTime.now().toUtc().add(
      const Duration(hours: 48),
    );

    final List<String> participants = <String>[
      uid,
      if (target != null) target.uid,
    ];

    await reference.set(<String, dynamic>{
      'challengerUid': uid,
      'challengerName': dashboard.profile.displayName,
      'challengerAvatar': dashboard.profile.avatar,
      'targetUid': target?.uid,
      'opponentUid': null,
      'opponentName': target?.displayName,
      'opponentAvatar': target?.avatar,
      'participantIds': participants,
      'status': 'pending',

      'gameIds': gameIds,
      'levels': levels,
      'layoutCodes': layoutCodes,

      'challengerScore': null,
      'challengerStars': null,
      'challengerTimeMs': null,
      'challengerSkips': null,

      'opponentScore': null,
      'opponentStars': null,
      'opponentTimeMs': null,
      'opponentSkips': null,

      'winnerUid': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expires),
      'schemaVersion': 2,
    });

    return getChallenge(reference.id);
  }

  Future<SocialChallenge?> createChallenge({
    OnlineLeaderboardEntry? target,
    String gameId = 'reflex',
  }) async {
    if (!await ensureOnline()) return null;

    final String? uid = currentUid;
    if (uid == null || target?.uid == uid) return null;

    final String normalizedGameId = gameId.trim();

    const Set<String> advancedChallengeGames = <String>{
      'blocks',
      'memory',
      'card_pairs',
      'focus_filter',
      'rhythm_memory',
      'attention_tunnel',
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
    };

    final bool legacyReflex = normalizedGameId == 'reflex';

    if (!legacyReflex &&
        (!advancedChallengeGames.contains(normalizedGameId) ||
            !StudioGameCatalog.isAvailable(normalizedGameId))) {
      return null;
    }

    // Yeni Meydan Okuma oyunlarında yalnızca orta-ileri / ileri bölümler.
    // Eski Refleks davetleri geriye uyumluluk için Bölüm 1 olarak kalır.
    final int challengeLevel = legacyReflex ? 1 : 5 + _random.nextInt(6);

    final PlayerDashboardData dashboard = await _player.load();
    final DocumentReference<Map<String, dynamic>> reference = _challenges.doc();
    final DateTime expires = DateTime.now().toUtc().add(
      const Duration(hours: 48),
    );
    final int seed = _random.nextInt(0x7ffffffe) + 1;

    final List<String> participants = <String>[
      uid,
      if (target != null) target.uid,
    ];

    await reference.set(<String, dynamic>{
      'challengerUid': uid,
      'challengerName': dashboard.profile.displayName,
      'challengerAvatar': dashboard.profile.avatar,
      'targetUid': target?.uid,
      'opponentUid': null,
      'opponentName': target?.displayName,
      'opponentAvatar': target?.avatar,
      'participantIds': participants,
      'status': 'pending',
      'gameId': normalizedGameId,
      'level': challengeLevel,
      'seed': seed,
      'challengerScore': null,
      'challengerStars': null,
      'opponentScore': null,
      'opponentStars': null,
      'winnerUid': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expires),
      'schemaVersion': 1,
    });

    return getChallenge(reference.id);
  }

  Future<bool> acceptChallenge(String challengeId) async {
    if (!await ensureOnline()) return false;
    final String? uid = currentUid;
    if (uid == null) return false;
    final PlayerDashboardData dashboard = await _player.load();
    final DocumentReference<Map<String, dynamic>> reference = _challenges.doc(
      challengeId,
    );

    try {
      String? challengerUid;
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(reference);
        if (!snapshot.exists) throw StateError('challenge-not-found');

        final SocialChallenge challenge = SocialChallenge.fromSnapshot(
          snapshot,
        );
        if (!challenge.isPlayable) {
          throw StateError('challenge-retired-game');
        }
        if (!challenge.pending || challenge.expired) {
          throw StateError('challenge-not-pending');
        }
        if (challenge.challengerUid == uid) {
          throw StateError('cannot-accept-own-challenge');
        }
        if (challenge.targetUid != null && challenge.targetUid != uid) {
          throw StateError('challenge-for-another-player');
        }

        challengerUid = challenge.challengerUid;
        transaction.update(reference, <String, dynamic>{
          'opponentUid': uid,
          'opponentName': dashboard.profile.displayName,
          'opponentAvatar': dashboard.profile.avatar,
          'participantIds': <String>[challenge.challengerUid, uid],
          'status': 'accepted',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      final String? other = challengerUid;
      if (other != null) await _createFriendship(uid, other);
      return true;
    } catch (error) {
      debugPrint('Challenge accept failed: $error');
      return false;
    }
  }

  Future<bool> declineChallenge(String challengeId) async {
    if (!await ensureOnline()) return false;
    final String? uid = currentUid;
    if (uid == null) return false;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final DocumentReference<Map<String, dynamic>> reference = _challenges
            .doc(challengeId);
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(reference);
        if (!snapshot.exists) throw StateError('challenge-not-found');
        final SocialChallenge challenge = SocialChallenge.fromSnapshot(
          snapshot,
        );
        if (!challenge.pending ||
            (challenge.targetUid != uid && challenge.opponentUid != uid)) {
          throw StateError('challenge-cannot-be-declined');
        }
        transaction.update(reference, <String, dynamic>{
          'status': 'declined',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (error) {
      debugPrint('Challenge decline failed: $error');
      return false;
    }
  }

  Future<bool> submitScore({
    required String challengeId,
    required int score,
    required int stars,
  }) async {
    if (!await ensureOnline()) return false;
    final String? uid = currentUid;
    if (uid == null) return false;

    final DocumentReference<Map<String, dynamic>> reference = _challenges.doc(
      challengeId,
    );
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(reference);
        if (!snapshot.exists) throw StateError('challenge-not-found');
        final SocialChallenge challenge = SocialChallenge.fromSnapshot(
          snapshot,
        );
        if (!challenge.isPlayable) {
          throw StateError('challenge-retired-game');
        }
        if ((!challenge.accepted && !challenge.completed) ||
            challenge.expired) {
          throw StateError('challenge-not-playable');
        }

        final Map<String, dynamic> update = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final int safeScore = score.clamp(0, 1000000).toInt();
        final int safeStars = stars.clamp(0, 3).toInt();
        int? challengerScore = challenge.challengerScore;
        int? opponentScore = challenge.opponentScore;

        if (challenge.challengerUid == uid) {
          if (challengerScore != null) {
            final bool sameResult =
                challengerScore == safeScore &&
                (challenge.challengerStars ?? 0) == safeStars;
            if (sameResult) return;
            throw StateError('score-already-set');
          }
          challengerScore = safeScore;
          update['challengerScore'] = safeScore;
          update['challengerStars'] = safeStars;
        } else if (challenge.opponentUid == uid) {
          if (opponentScore != null) {
            final bool sameResult =
                opponentScore == safeScore &&
                (challenge.opponentStars ?? 0) == safeStars;
            if (sameResult) return;
            throw StateError('score-already-set');
          }
          opponentScore = safeScore;
          update['opponentScore'] = safeScore;
          update['opponentStars'] = safeStars;
        } else {
          throw StateError('not-a-participant');
        }

        if (challengerScore != null && opponentScore != null) {
          update['status'] = 'completed';
          update['winnerUid'] = challengerScore == opponentScore
              ? 'draw'
              : challengerScore > opponentScore
              ? challenge.challengerUid
              : challenge.opponentUid;
        }

        transaction.update(reference, update);
      });
      return true;
    } catch (error) {
      debugPrint('Challenge score submit failed: $error');
      return false;
    }
  }

  Future<bool> sendReaction({
    required String challengeId,
    required String reaction,
  }) async {
    const Set<String> allowedReactions = <String>{
      'good_game',
      'rematch',
      'close_game',
      'congrats',
    };

    final String normalized = reaction.trim();

    if (!allowedReactions.contains(normalized)) return false;
    if (!await ensureOnline()) return false;

    final String? uid = currentUid;
    if (uid == null || uid.isEmpty || challengeId.trim().isEmpty) {
      return false;
    }

    final DocumentReference<Map<String, dynamic>> reference = _challenges.doc(
      challengeId.trim(),
    );

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(reference);

        if (!snapshot.exists) {
          throw StateError('challenge-not-found');
        }

        final SocialChallenge challenge = SocialChallenge.fromSnapshot(
          snapshot,
        );

        if (!challenge.completed) {
          throw StateError('challenge-not-completed');
        }

        final String field;

        if (challenge.challengerUid == uid) {
          field = 'challengerReaction';
        } else if (challenge.opponentUid == uid) {
          field = 'opponentReaction';
        } else {
          throw StateError('not-a-participant');
        }

        transaction.update(reference, <String, dynamic>{
          field: normalized,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (error) {
      debugPrint('Challenge reaction failed: $error');
      return false;
    }
  }

  Future<bool> submitSeriesResult({
    required String challengeId,
    required int score,
    required int stars,
    required int elapsedMs,
    required int skips,
  }) async {
    if (!await ensureOnline()) return false;

    final String? uid = currentUid;
    if (uid == null) return false;

    final DocumentReference<Map<String, dynamic>> reference = _challenges.doc(
      challengeId,
    );

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(reference);

        if (!snapshot.exists) {
          throw StateError('challenge-not-found');
        }

        final SocialChallenge challenge = SocialChallenge.fromSnapshot(
          snapshot,
        );

        if (!challenge.isSeries || !challenge.isPlayable) {
          throw StateError('challenge-not-series');
        }

        if ((!challenge.accepted && !challenge.completed) ||
            challenge.expired) {
          throw StateError('challenge-not-playable');
        }

        final int stationCount = challenge.gameIds.length;
        final int safeScore = score.clamp(0, stationCount * 1000).toInt();
        final int safeStars = stars.clamp(0, stationCount * 3).toInt();
        final int safeElapsedMs = elapsedMs.clamp(0, 86400000).toInt();
        final int safeSkips = skips.clamp(0, stationCount).toInt();

        final Map<String, dynamic> update = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };

        int? challengerScore = challenge.challengerScore;
        int? challengerTimeMs = challenge.challengerTimeMs;

        int? opponentScore = challenge.opponentScore;
        int? opponentTimeMs = challenge.opponentTimeMs;

        if (challenge.challengerUid == uid) {
          if (challengerScore != null) {
            final bool sameResult =
                challengerScore == safeScore &&
                (challenge.challengerStars ?? 0) == safeStars &&
                (challenge.challengerTimeMs ?? 0) == safeElapsedMs &&
                (challenge.challengerSkips ?? 0) == safeSkips;
            if (sameResult) return;
            throw StateError('score-already-set');
          }

          challengerScore = safeScore;
          challengerTimeMs = safeElapsedMs;

          update['challengerScore'] = safeScore;
          update['challengerStars'] = safeStars;
          update['challengerTimeMs'] = safeElapsedMs;
          update['challengerSkips'] = safeSkips;
        } else if (challenge.opponentUid == uid) {
          if (opponentScore != null) {
            final bool sameResult =
                opponentScore == safeScore &&
                (challenge.opponentStars ?? 0) == safeStars &&
                (challenge.opponentTimeMs ?? 0) == safeElapsedMs &&
                (challenge.opponentSkips ?? 0) == safeSkips;
            if (sameResult) return;
            throw StateError('score-already-set');
          }

          opponentScore = safeScore;
          opponentTimeMs = safeElapsedMs;

          update['opponentScore'] = safeScore;
          update['opponentStars'] = safeStars;
          update['opponentTimeMs'] = safeElapsedMs;
          update['opponentSkips'] = safeSkips;
        } else {
          throw StateError('not-a-participant');
        }

        if (challengerScore != null &&
            opponentScore != null &&
            challengerTimeMs != null &&
            opponentTimeMs != null) {
          update['status'] = 'completed';

          if (challengerScore > opponentScore) {
            update['winnerUid'] = challenge.challengerUid;
          } else if (opponentScore > challengerScore) {
            update['winnerUid'] = challenge.opponentUid;
          } else if (challengerTimeMs < opponentTimeMs) {
            update['winnerUid'] = challenge.challengerUid;
          } else if (opponentTimeMs < challengerTimeMs) {
            update['winnerUid'] = challenge.opponentUid;
          } else {
            update['winnerUid'] = 'draw';
          }
        }

        transaction.update(reference, update);
      });

      return true;
    } catch (error) {
      debugPrint('Challenge series submit failed: $error');
      return false;
    }
  }

  Future<void> _createFriendship(String firstUid, String secondUid) async {
    final List<String> members = <String>[firstUid, secondUid]..sort();
    final String id = '${members[0]}_${members[1]}';
    await _friendships.doc(id).set(<String, dynamic>{
      'members': members,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    }, SetOptions(merge: true));
  }
}
