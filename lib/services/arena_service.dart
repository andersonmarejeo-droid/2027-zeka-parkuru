import '../games/shared/studio_game_contracts.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/catalog/domain/studio_game_catalog.dart';
import 'firebase_bootstrap_service.dart';
import 'online_leaderboard_service.dart';
import 'player_progress_service.dart';

class ArenaGroup {
  final String id;
  final String ownerUid;
  final String name;
  final String joinCode;
  final List<String> memberIds;
  final String? activeEventId;
  final int eventSequence;
  final int schemaVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ArenaGroup({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.joinCode,
    required this.memberIds,
    this.activeEventId,
    this.eventSequence = 0,
    this.schemaVersion = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArenaGroup.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    return ArenaGroup(
      id: snapshot.id,
      ownerUid: _text(data['ownerUid']),
      name: _text(data['name'], fallback: 'Zekâ Grubu'),
      joinCode: _text(data['joinCode']),
      memberIds: _stringList(data['memberIds'], maxItems: 30),
      activeEventId: _nullableText(data['activeEventId']),
      eventSequence: _safeInt(data['eventSequence'], 0, 1000000),
      schemaVersion: _safeInt(data['schemaVersion'], 1, 2, fallback: 1),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  bool isOwner(String? uid) => uid != null && ownerUid == uid;
  bool hasMember(String? uid) => uid != null && memberIds.contains(uid);
}

class ArenaEvent {
  final String id;
  final String groupId;
  final String ownerUid;
  final String title;
  final String format;
  final String status;
  final int level;
  final List<String> gameIds;
  final List<String> participantIds;
  final Map<String, int> layoutCodes;
  final int schemaVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? endsAt;

  const ArenaEvent({
    required this.id,
    required this.groupId,
    required this.ownerUid,
    required this.title,
    required this.format,
    required this.status,
    required this.level,
    required this.gameIds,
    required this.participantIds,
    required this.layoutCodes,
    this.schemaVersion = 1,
    required this.createdAt,
    required this.updatedAt,
    required this.endsAt,
  });

  factory ArenaEvent.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    final Map<String, int> layouts = <String, int>{};
    final dynamic rawLayouts = data['layoutCodes'];
    if (rawLayouts is Map) {
      rawLayouts.forEach((dynamic key, dynamic value) {
        if (key is String && value is num) {
          layouts[key] = value.toInt();
        }
      });
    }
    return ArenaEvent(
      id: snapshot.id,
      groupId: _text(data['groupId']),
      ownerUid: _text(data['ownerUid']),
      title: _text(data['title'], fallback: 'Zekâ Yarışı'),
      format: _text(data['format'], fallback: 'direct'),
      status: _text(data['status'], fallback: 'active'),
      level: _safeInt(
        data['level'],
        1,
        GameContentPolicy.campaignLevels,
        fallback: 1,
      ),
      gameIds: _stringList(data['gameIds'], maxItems: 11),
      participantIds: _stringList(data['participantIds'], maxItems: 30),
      layoutCodes: layouts,
      schemaVersion: _safeInt(data['schemaVersion'], 1, 2, fallback: 1),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      endsAt: _date(data['endsAt']),
    );
  }

  bool get active => status == 'active' && !expired;
  bool get completed => status == 'completed';
  bool get expired => endsAt != null && DateTime.now().isAfter(endsAt!);
  bool get isPlayable =>
      gameIds.isNotEmpty &&
      gameIds.toSet().length == gameIds.length &&
      gameIds.every(StudioGameCatalog.isAvailable);
  int layoutCodeFor(String gameId) => layoutCodes[gameId] ?? 1;
}

enum ArenaAttemptOutcome {
  completed,
  failed,
  skipped;

  String get storageValue => name;

  static ArenaAttemptOutcome fromStorage(dynamic value) {
    return switch (value) {
      'failed' => ArenaAttemptOutcome.failed,
      'skipped' => ArenaAttemptOutcome.skipped,
      _ => ArenaAttemptOutcome.completed,
    };
  }
}

class ArenaAttempt {
  final String id;
  final String eventId;
  final String groupId;
  final String uid;
  final String displayName;
  final String avatar;
  final String gameId;
  final ArenaAttemptOutcome outcome;
  final int rawScore;
  final int stars;
  final int points;
  final int schemaVersion;
  final DateTime? submittedAt;

  const ArenaAttempt({
    required this.id,
    required this.eventId,
    required this.groupId,
    required this.uid,
    required this.displayName,
    required this.avatar,
    required this.gameId,
    this.outcome = ArenaAttemptOutcome.completed,
    required this.rawScore,
    required this.stars,
    required this.points,
    this.schemaVersion = 1,
    required this.submittedAt,
  });

  factory ArenaAttempt.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    return ArenaAttempt(
      id: snapshot.id,
      eventId: _text(data['eventId']),
      groupId: _text(data['groupId']),
      uid: _text(data['uid']),
      displayName: _text(data['displayName'], fallback: 'Oyuncu'),
      avatar: _text(data['avatar'], fallback: '🧠'),
      gameId: _text(data['gameId']),
      outcome: ArenaAttemptOutcome.fromStorage(data['outcome']),
      rawScore: _safeInt(data['rawScore'], 0, 10000000),
      stars: _safeInt(data['stars'], 0, 3),
      points: _safeInt(data['points'], 0, 1000),
      schemaVersion: _safeInt(data['schemaVersion'], 1, 2, fallback: 1),
      submittedAt: _date(data['submittedAt']),
    );
  }
}

class ArenaReaction {
  final String id;
  final String eventId;
  final String groupId;
  final String uid;
  final String displayName;
  final String avatar;
  final String reaction;
  final DateTime? updatedAt;

  const ArenaReaction({
    required this.id,
    required this.eventId,
    required this.groupId,
    required this.uid,
    required this.displayName,
    required this.avatar,
    required this.reaction,
    required this.updatedAt,
  });

  factory ArenaReaction.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    return ArenaReaction(
      id: snapshot.id,
      eventId: _text(data['eventId']),
      groupId: _text(data['groupId']),
      uid: _text(data['uid']),
      displayName: _text(data['displayName'], fallback: 'Oyuncu'),
      avatar: _text(data['avatar'], fallback: '🧠'),
      reaction: _text(data['reaction']),
      updatedAt: _date(data['updatedAt']),
    );
  }
}

class ArenaStanding {
  final String uid;
  final String displayName;
  final String avatar;
  final int completedGames;
  final int totalGames;
  final int totalStars;
  final int totalPoints;

  const ArenaStanding({
    required this.uid,
    required this.displayName,
    required this.avatar,
    required this.completedGames,
    required this.totalGames,
    required this.totalStars,
    required this.totalPoints,
  });

  bool get finished => completedGames >= totalGames;
}

class ArenaWeeklyStanding {
  const ArenaWeeklyStanding({
    required this.uid,
    required this.displayName,
    required this.avatar,
    required this.attemptCount,
    required this.totalStars,
    required this.totalPoints,
  });

  final String uid;
  final String displayName;
  final String avatar;
  final int attemptCount;
  final int totalStars;
  final int totalPoints;
}

class ArenaService {
  ArenaService._();

  static final ArenaService instance = ArenaService._();

  static const String inviteBaseUrl =
      'https://zeka-parkuru-eu-2026.web.app/arena.html';

  static final List<String> allGameIds = List<String>.unmodifiable(
    StudioGameCatalog.playable.where((game) => !StudioGameCatalog.isGameRetired(game.id)).map((GameDefinition game) => game.id),
  );

  static const int eventGameCount = 6;

  static const List<String> featuredGameIds = <String>[
    'hanoi',
    'mini_sudoku',
    'number_sort',
  ];

  static const String _pendingAttemptsKey = 'arena_pending_attempts_v1';
  static const Duration _attemptWriteTimeout = Duration(seconds: 12);
  static const int _maxPendingAttempts = 30;

  final FirebaseBootstrapService _firebase = FirebaseBootstrapService.instance;
  final PlayerProgressService _player = PlayerProgressService.instance;
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final Random _random = Random.secure();
  Future<void>? _pendingAttemptSync;
  bool _lastAttemptQueued = false;
  String? _lastAttemptError;
  String? _lastEventError;

  CollectionReference<Map<String, dynamic>> get _groups =>
      FirebaseFirestore.instance.collection('arena_groups_v1');

  CollectionReference<Map<String, dynamic>> get _invites =>
      FirebaseFirestore.instance.collection('arena_invites_v1');

  CollectionReference<Map<String, dynamic>> get _events =>
      FirebaseFirestore.instance.collection('arena_events_v1');

  CollectionReference<Map<String, dynamic>> get _attempts =>
      FirebaseFirestore.instance.collection('arena_attempts_v1');

  CollectionReference<Map<String, dynamic>> get _reactions =>
      FirebaseFirestore.instance.collection('arena_reactions_v1');

  String? get currentUid => _firebase.uid;
  String? get lastError => _firebase.lastError;
  bool get lastAttemptQueued => _lastAttemptQueued;
  String? get lastAttemptError => _lastAttemptError;
  String? get lastEventError => _lastEventError;

  Future<bool> ensureOnline({bool forceRetry = false}) async {
    await _firebase.initialize(forceRetry: forceRetry);
    return _firebase.ready;
  }

  String inviteUrl(ArenaGroup group) =>
      '$inviteBaseUrl?g='
      '${Uri.encodeQueryComponent(group.id)}&code='
      '${Uri.encodeQueryComponent(group.joinCode)}';

  static int competitionPoints(int stars) {
    final int safeStars = stars.clamp(0, 3).toInt();
    return 100 + safeStars * 300;
  }

  Stream<T> _restartableStream<T>(Stream<T> Function() sourceFactory) {
    return Stream<T>.multi((controller) {
      final StreamSubscription<T> subscription = sourceFactory().listen(
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

  Stream<List<ArenaGroup>> watchMyGroups() =>
      _restartableStream<List<ArenaGroup>>(_watchMyGroupsSingle);

  Stream<List<ArenaGroup>> _watchMyGroupsSingle() async* {
    if (!await ensureOnline()) {
      yield const <ArenaGroup>[];
      return;
    }
    final String? uid = currentUid;
    if (uid == null) {
      yield const <ArenaGroup>[];
      return;
    }
    yield* _groups
        .where('memberIds', arrayContains: uid)
        .limit(30)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<ArenaGroup> groups = snapshot.docs
              .map(ArenaGroup.fromSnapshot)
              .toList();
          groups.sort((ArenaGroup a, ArenaGroup b) {
            final DateTime left = a.updatedAt ?? DateTime(2000);
            final DateTime right = b.updatedAt ?? DateTime(2000);
            return right.compareTo(left);
          });
          return groups;
        });
  }

  Stream<ArenaGroup?> watchGroup(String groupId) =>
      _restartableStream<ArenaGroup?>(() => _watchGroupSingle(groupId));

  Stream<ArenaGroup?> _watchGroupSingle(String groupId) async* {
    if (!await ensureOnline() || groupId.trim().isEmpty) {
      yield null;
      return;
    }
    yield* _groups
        .doc(groupId.trim())
        .snapshots()
        .map(
          (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.exists ? ArenaGroup.fromSnapshot(snapshot) : null,
        );
  }

  Future<ArenaGroup?> getGroup(String groupId) async {
    if (!await ensureOnline() || groupId.trim().isEmpty) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _groups
          .doc(groupId.trim())
          .get();
      return snapshot.exists ? ArenaGroup.fromSnapshot(snapshot) : null;
    } catch (error) {
      debugPrint('Arena group read failed: $error');
      return null;
    }
  }

  Future<ArenaGroup?> createGroup(String rawName) async {
    if (!await ensureOnline()) return null;
    final String? uid = currentUid;
    if (uid == null) return null;
    final String name = _cleanName(rawName, fallback: 'Zekâ Grubu');

    try {
      for (int attempt = 0; attempt < 8; attempt++) {
        final String code = _newJoinCode();
        final DocumentReference<Map<String, dynamic>> inviteRef = _invites.doc(
          code,
        );
        final DocumentReference<Map<String, dynamic>> groupRef = _groups.doc();
        try {
          await FirebaseFirestore.instance.runTransaction((
            Transaction transaction,
          ) async {
            final DocumentSnapshot<Map<String, dynamic>> invite =
                await transaction.get(inviteRef);
            if (invite.exists) throw StateError('join-code-collision');
            transaction.set(groupRef, <String, dynamic>{
              'ownerUid': uid,
              'name': name,
              'joinCode': code,
              'joinCodeProof': '$code:$uid',
              'memberIds': <String>[uid],
              'activeEventId': null,
              'eventSequence': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'schemaVersion': 2,
            });
            transaction.set(inviteRef, <String, dynamic>{
              'joinCode': code,
              'groupId': groupRef.id,
              'ownerUid': uid,
              'createdAt': FieldValue.serverTimestamp(),
              'schemaVersion': 1,
            });
          });
          return await getGroup(groupRef.id);
        } on StateError catch (error) {
          if (error.message == 'join-code-collision') continue;
          rethrow;
        }
      }
    } catch (error) {
      debugPrint('Arena group create failed: $error');
    }
    return null;
  }

  Future<ArenaGroup?> joinByCode(String rawCode) async {
    if (!await ensureOnline()) return null;
    final String code = _normalizeCode(rawCode);
    if (code.length != 6) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> invite = await _invites
          .doc(code)
          .get();
      if (!invite.exists) return null;
      final String groupId = _text(invite.data()?['groupId']);
      if (groupId.isEmpty) return null;
      return await _joinGroupByAuthorizedCode(groupId: groupId, code: code);
    } catch (error) {
      debugPrint('Arena join by code failed: $error');
      return null;
    }
  }

  Future<ArenaGroup?> joinByInvite({
    required String groupId,
    required String joinCode,
  }) async {
    if (!await ensureOnline()) return null;
    final String code = _normalizeCode(joinCode);
    final String cleanGroupId = groupId.trim();
    if (code.length != 6 || cleanGroupId.isEmpty) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> invite = await _invites
          .doc(code)
          .get();
      if (!invite.exists || _text(invite.data()?['groupId']) != cleanGroupId) {
        return null;
      }
      return await _joinGroupByAuthorizedCode(
        groupId: cleanGroupId,
        code: code,
      );
    } catch (error) {
      debugPrint('Arena invite join failed: $error');
      return null;
    }
  }

  Future<ArenaGroup?> _joinGroupByAuthorizedCode({
    required String groupId,
    required String code,
  }) async {
    final String? uid = currentUid;
    if (uid == null) return null;

    // Zaten üyeyse grup okuması güvenlik kuralından geçer ve gereksiz update
    // yapılmaz. Üye değilse bu get permission-denied olabilir; join devam eder.
    final ArenaGroup? existing = await getGroup(groupId);
    if (existing != null) {
      return existing.joinCode == code ? existing : null;
    }

    try {
      await _groups.doc(groupId).update(<String, dynamic>{
        'memberIds': FieldValue.arrayUnion(<String>[uid]),
        'joinCodeProof': '$code:$uid',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return await getGroup(groupId);
    } catch (error) {
      debugPrint('Arena authorized join failed: $error');
      return null;
    }
  }

  Stream<List<ArenaEvent>> watchGroupEvents(String groupId) =>
      _restartableStream<List<ArenaEvent>>(
        () => _watchGroupEventsSingle(groupId),
      );

  Stream<List<ArenaEvent>> _watchGroupEventsSingle(String groupId) async* {
    if (!await ensureOnline() || groupId.trim().isEmpty) {
      yield const <ArenaEvent>[];
      return;
    }
    yield* _events
        .where('groupId', isEqualTo: groupId.trim())
        .limit(30)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<ArenaEvent> events = snapshot.docs
              .map(ArenaEvent.fromSnapshot)
              .where((ArenaEvent event) => event.isPlayable)
              .toList();
          events.sort((ArenaEvent a, ArenaEvent b) {
            final DateTime left = a.createdAt ?? DateTime(2000);
            final DateTime right = b.createdAt ?? DateTime(2000);
            return right.compareTo(left);
          });
          return events;
        });
  }

  Stream<ArenaEvent?> watchEvent(String eventId) =>
      _restartableStream<ArenaEvent?>(() => _watchEventSingle(eventId));

  Stream<ArenaEvent?> _watchEventSingle(String eventId) async* {
    if (!await ensureOnline() || eventId.trim().isEmpty) {
      yield null;
      return;
    }
    yield* _events.doc(eventId.trim()).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      if (!snapshot.exists) return null;
      final ArenaEvent event = ArenaEvent.fromSnapshot(snapshot);
      return event.isPlayable ? event : null;
    });
  }

  Future<ArenaEvent?> getEvent(String eventId) async {
    if (!await ensureOnline() || eventId.trim().isEmpty) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _events
          .doc(eventId.trim())
          .get();
      if (!snapshot.exists) return null;
      final ArenaEvent event = ArenaEvent.fromSnapshot(snapshot);
      return event.isPlayable ? event : null;
    } catch (error) {
      debugPrint('Arena event read failed: $error');
      return null;
    }
  }

  Future<ArenaEvent?> createEvent({
    required ArenaGroup group,
    required String rawTitle,
    required List<String> selectedGameIds,
    Duration duration = const Duration(hours: 48),
  }) async {
    _lastEventError = null;
    if (!await ensureOnline()) {
      _lastEventError = 'firebase-unavailable';
      return null;
    }
    final String? uid = currentUid;
    if (uid == null || !group.isOwner(uid) || group.memberIds.length < 2) {
      _lastEventError = 'owner-or-members-invalid';
      return null;
    }

    final List<String> requestedPool = selectedGameIds
        .where(allGameIds.contains)
        .toSet()
        .toList(growable: true);
    final List<String> shuffledGames = List<String>.from(
      requestedPool.length >= eventGameCount ? requestedPool : allGameIds,
    )..shuffle(_random);
    final List<String> games = shuffledGames
        .take(eventGameCount)
        .toList(growable: false);

    try {
      return await _createEventTransaction(
        group: group,
        uid: uid,
        rawTitle: rawTitle,
        games: games,
        duration: duration,
        legacySchema: false,
      );
    } on _ArenaActiveEventError catch (error) {
      return getEvent(error.eventId);
    } on FirebaseException catch (error) {
      _lastEventError = error.code;
      debugPrint('Arena event create failed (${error.code}): ${error.message}');

      // Some installed builds can reach a Firebase project whose rules were
      // deployed before the schema-2 migration.  Retry the same atomic write
      // in the old document shape so an already-created group remains usable.
      // Once the current rules are deployed this branch is never needed.
      if (error.code != 'permission-denied') return null;
      try {
        final ArenaEvent? legacyEvent = await _createEventTransaction(
          group: group,
          uid: uid,
          rawTitle: rawTitle,
          games: games,
          duration: duration,
          legacySchema: true,
        );
        _lastEventError = null;
        return legacyEvent;
      } on _ArenaActiveEventError catch (activeError) {
        return getEvent(activeError.eventId);
      } on FirebaseException catch (legacyError) {
        _lastEventError = legacyError.code;
        debugPrint(
          'Legacy arena event create failed '
          '(${legacyError.code}): ${legacyError.message}',
        );
        return null;
      }
    } catch (error) {
      _lastEventError = error.toString();
      debugPrint('Arena event create failed: $error');
      return null;
    }
  }

  Future<ArenaEvent?> _createEventTransaction({
    required ArenaGroup group,
    required String uid,
    required String rawTitle,
    required List<String> games,
    required Duration duration,
    required bool legacySchema,
  }) async {
    // The transaction below is the source of truth for activeEventId. A
    // preflight groupId + status query can require an index and can be
    // rejected by Firestore rules before the atomic write starts.
    final Map<String, int> layoutCodes = <String, int>{
      for (final String gameId in games)
        gameId: _random.nextInt(0x7ffffffe) + 1,
    };
    final DocumentReference<Map<String, dynamic>> reference = _events.doc();
    final DateTime ends = DateTime.now().toUtc().add(duration);
    final DocumentReference<Map<String, dynamic>> groupRef = _groups.doc(
      group.id,
    );

    await FirebaseFirestore.instance.runTransaction((
      Transaction transaction,
    ) async {
      final DocumentSnapshot<Map<String, dynamic>> groupSnapshot =
          await transaction.get(groupRef);
      if (!groupSnapshot.exists) {
        throw StateError('arena-group-missing');
      }

      final Map<String, dynamic> groupData =
          groupSnapshot.data() ?? <String, dynamic>{};
      if (_text(groupData['ownerUid']) != uid) {
        throw StateError('arena-owner-mismatch');
      }

      final String? activeEventId = _nullableText(groupData['activeEventId']);
      if (activeEventId != null) {
        final DocumentSnapshot<Map<String, dynamic>> activeSnapshot =
            await transaction.get(_events.doc(activeEventId));
        if (activeSnapshot.exists) {
          final ArenaEvent activeEvent = ArenaEvent.fromSnapshot(
            activeSnapshot,
          );
          if (activeEvent.active && activeEvent.isPlayable) {
            throw _ArenaActiveEventError(activeEventId);
          }
        }
      }

      final List<String> currentMembers = _stringList(
        groupData['memberIds'],
        maxItems: 30,
      );
      if (currentMembers.length < 2) {
        throw StateError('arena-not-enough-members');
      }

      final int nextSequence =
          _safeInt(groupData['eventSequence'], 0, 1000000) + 1;
      final Map<String, dynamic> eventData = <String, dynamic>{
        'groupId': group.id,
        'ownerUid': uid,
        'title': _cleanName(rawTitle, fallback: 'Zekâ Yarışı'),
        'format': 'direct',
        'status': 'active',
        'level': 1,
        'gameIds': games,
        'participantIds': currentMembers,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'endsAt': Timestamp.fromDate(ends),
        'schemaVersion': legacySchema ? 1 : 2,
      };
      if (!legacySchema) eventData['layoutCodes'] = layoutCodes;
      transaction.set(reference, eventData);

      final Map<String, dynamic> groupUpdate = <String, dynamic>{
        'activeEventId': reference.id,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!legacySchema) {
        groupUpdate['eventSequence'] = nextSequence;
        groupUpdate['schemaVersion'] = 2;
      }
      transaction.update(groupRef, groupUpdate);
    });
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await reference
        .get();
    return snapshot.exists ? ArenaEvent.fromSnapshot(snapshot) : null;
  }

  /// Watches attempts for one event and its group.
  ///
  /// Firestore evaluates security rules against every document a query could
  /// return.  The read rule for arena attempts checks the owning group's
  /// membership, so an `eventId`-only query cannot be proven safe and is
  /// rejected with `permission-denied`.  Keeping the group constraint in the
  /// query makes the rule provable and avoids locking the arena screen.
  Stream<List<ArenaAttempt>> watchAttempts({
    required String eventId,
    required String groupId,
  }) => _restartableStream<List<ArenaAttempt>>(
    () => _watchAttemptsSingle(eventId, groupId),
  );

  Stream<List<ArenaAttempt>> _watchAttemptsSingle(
    String eventId,
    String groupId,
  ) async* {
    final String cleanEventId = eventId.trim();
    final String cleanGroupId = groupId.trim();
    if (!await ensureOnline() || cleanEventId.isEmpty || cleanGroupId.isEmpty) {
      yield const <ArenaAttempt>[];
      return;
    }
    unawaited(_flushPendingAttempts());
    final Query<Map<String, dynamic>> query = _attempts
        .where('eventId', isEqualTo: cleanEventId)
        .where('groupId', isEqualTo: cleanGroupId)
        .limit(400);
    yield* query.snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) =>
          snapshot.docs.map(ArenaAttempt.fromSnapshot).toList(growable: false),
    );
  }

  Future<List<ArenaAttempt>> loadPendingAttemptsForEvent(
    ArenaEvent event,
  ) async {
    final String uid = currentUid ?? '';
    if (uid.isEmpty) return const <ArenaAttempt>[];
    final List<Map<String, dynamic>> pending = await _readPendingAttempts();
    return pending
        .where(
          (Map<String, dynamic> item) =>
              _text(item['eventId']) == event.id &&
              _text(item['uid']) == uid &&
              event.gameIds.contains(_text(item['gameId'])),
        )
        .map(
          (Map<String, dynamic> item) => ArenaAttempt(
            id: _text(item['documentId']),
            eventId: event.id,
            groupId: event.groupId,
            uid: uid,
            displayName: _text(item['displayName'], fallback: 'Oyuncu'),
            avatar: _text(item['avatar'], fallback: '🧠'),
            gameId: _text(item['gameId']),
            outcome: ArenaAttemptOutcome.fromStorage(item['outcome']),
            rawScore: _safeInt(item['rawScore'], 0, 10000000),
            stars: _safeInt(item['stars'], 0, 3),
            points: _safeInt(item['points'], 0, 1000),
            schemaVersion: _safeInt(item['schemaVersion'], 1, 2, fallback: 1),
            submittedAt: null,
          ),
        )
        .toList(growable: false);
  }

  /// Same rule-safe query constraint as [watchAttempts].
  Stream<List<ArenaReaction>> watchReactions({
    required String eventId,
    required String groupId,
  }) => _restartableStream<List<ArenaReaction>>(
    () => _watchReactionsSingle(eventId, groupId),
  );

  Stream<List<ArenaReaction>> _watchReactionsSingle(
    String eventId,
    String groupId,
  ) async* {
    final String cleanEventId = eventId.trim();
    final String cleanGroupId = groupId.trim();
    if (!await ensureOnline() || cleanEventId.isEmpty || cleanGroupId.isEmpty) {
      yield const <ArenaReaction>[];
      return;
    }
    final Query<Map<String, dynamic>> query = _reactions
        .where('eventId', isEqualTo: cleanEventId)
        .where('groupId', isEqualTo: cleanGroupId)
        .limit(30);
    yield* query.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<ArenaReaction> reactions = snapshot.docs
          .map(ArenaReaction.fromSnapshot)
          .toList(growable: false);
      reactions.sort((ArenaReaction left, ArenaReaction right) {
        final DateTime leftTime =
            left.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime rightTime =
            right.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return rightTime.compareTo(leftTime);
      });
      return reactions;
    });
  }

  Future<bool> sendReaction({
    required ArenaEvent event,
    required String reaction,
  }) async {
    const Set<String> allowed = <String>{
      'good_game',
      'rematch',
      'close_game',
      'congrats',
    };
    final String normalized = reaction.trim();
    if (!allowed.contains(normalized) || !await ensureOnline()) return false;

    final String? uid = currentUid;
    if (uid == null || !event.participantIds.contains(uid)) return false;

    final PlayerDashboardData dashboard = await _player.load();
    final String documentId = '${event.id}--$uid';

    try {
      await _reactions.doc(documentId).set(<String, dynamic>{
        'eventId': event.id,
        'groupId': event.groupId,
        'uid': uid,
        'displayName': dashboard.profile.displayName,
        'avatar': dashboard.profile.avatar,
        'reaction': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      });
      return true;
    } catch (error) {
      debugPrint('Arena reaction send failed: $error');
      return false;
    }
  }

  Stream<List<ArenaAttempt>> watchGroupAttempts(String groupId) =>
      _restartableStream<List<ArenaAttempt>>(
        () => _watchGroupAttemptsSingle(groupId),
      );

  Stream<List<ArenaAttempt>> _watchGroupAttemptsSingle(String groupId) async* {
    if (!await ensureOnline() || groupId.trim().isEmpty) {
      yield const <ArenaAttempt>[];
      return;
    }
    yield* _attempts
        .where('groupId', isEqualTo: groupId.trim())
        .limit(1000)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(ArenaAttempt.fromSnapshot)
              .toList(growable: false),
        );
  }

  Future<bool> submitAttempt({
    required ArenaEvent event,
    required String gameId,
    required ArenaAttemptOutcome outcome,
    required int rawScore,
    required int stars,
  }) async {
    _lastAttemptQueued = false;
    _lastAttemptError = null;

    if (!event.active) {
      _lastAttemptError = 'arena-event-inactive';
      return false;
    }

    final bool online = await ensureOnline();
    final String? uid = currentUid;
    if (uid == null ||
        !event.participantIds.contains(uid) ||
        !event.gameIds.contains(gameId)) {
      _lastAttemptError = 'arena-participant-mismatch';
      return false;
    }

    final PlayerDashboardData dashboard = await _player.load();
    final bool completed = outcome == ArenaAttemptOutcome.completed;
    final int safeStars = completed ? stars.clamp(0, 3).toInt() : 0;
    final int safeScore = completed ? rawScore.clamp(0, 10000000).toInt() : 0;
    final bool modernAttempt = event.schemaVersion >= 2;
    final String documentId = '${event.id}--$uid--$gameId';

    final Map<String, dynamic> pending = <String, dynamic>{
      'documentId': documentId,
      'eventId': event.id,
      'groupId': event.groupId,
      'uid': uid,
      'displayName': _limitedText(
        dashboard.profile.displayName,
        maxRunes: 18,
        fallback: 'Oyuncu',
      ),
      'avatar': _limitedText(
        dashboard.profile.avatar,
        maxRunes: 32,
        fallback: '🧠',
      ),
      'gameId': gameId,
      'outcome': outcome.storageValue,
      'rawScore': safeScore,
      'stars': safeStars,
      'points': modernAttempt
          ? completed
                ? competitionPoints(safeStars)
                : 0
          : competitionPoints(safeStars),
      'expiresAtMs': event.endsAt?.millisecondsSinceEpoch,
      'schemaVersion': modernAttempt ? 2 : 1,
    };

    if (!online) {
      final bool stored = await _storePendingAttempt(pending);
      if (!stored) {
        _lastAttemptError = 'arena-pending-store-failed';
        return false;
      }
      _lastAttemptQueued = true;
      _lastAttemptError = 'arena-attempt-queued-offline';
      return true;
    }

    try {
      final bool accepted = await _writeAttempt(pending);
      if (accepted) {
        unawaited(_flushPendingAttempts());
        return true;
      }

      _lastAttemptError = 'arena-existing-attempt-mismatch';
      return false;
    } catch (error) {
      debugPrint('Arena attempt submit failed: $error');
      if (!_canQueueAttemptError(error)) {
        _lastAttemptError = error.toString();
        return false;
      }
      final bool stored = await _storePendingAttempt(pending);
      if (!stored) {
        _lastAttemptError = error.toString();
        return false;
      }
      _lastAttemptQueued = true;
      _lastAttemptError = error.toString();
      return true;
    }
  }

  Future<bool> _writeAttempt(Map<String, dynamic> pending) async {
    final String documentId = _text(pending['documentId']);
    if (documentId.isEmpty) return false;

    final DocumentReference<Map<String, dynamic>> reference = _attempts.doc(
      documentId,
    );

    // The attempt rules intentionally let participants CREATE a result and
    // read existing results, but do not let them read a missing attempt
    // document. A transaction starts by reading that missing document, so
    // Firestore denies the very first result before the create can be tried.
    // A direct set is evaluated as a create when the deterministic ID is
    // unused; if a previous request already created it, read back the
    // immutable result and treat an identical retry as successful.
    try {
      await reference
          .set(_attemptCloudData(pending))
          .timeout(_attemptWriteTimeout);
      return true;
    } catch (error, stackTrace) {
      if (error is FirebaseException && error.code == 'permission-denied') {
        try {
          final DocumentSnapshot<Map<String, dynamic>> existing =
              await reference.get().timeout(_attemptWriteTimeout);
          if (existing.exists) {
            return _existingAttemptMatches(existing.data(), pending);
          }
        } catch (readError) {
          debugPrint('Arena existing attempt lookup failed: $readError');
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  bool _existingAttemptMatches(
    Map<String, dynamic>? existing,
    Map<String, dynamic> pending,
  ) {
    if (existing == null) return false;
    final bool sameIdentity =
        existing['eventId'] == pending['eventId'] &&
        existing['groupId'] == pending['groupId'] &&
        existing['uid'] == pending['uid'] &&
        existing['gameId'] == pending['gameId'];
    if (!sameIdentity) return false;

    final int schemaVersion = _safeInt(
      pending['schemaVersion'],
      1,
      2,
      fallback: 1,
    );
    if (schemaVersion == 1) return true;

    return existing['schemaVersion'] == 2 &&
        existing['outcome'] == pending['outcome'] &&
        existing['rawScore'] == pending['rawScore'] &&
        existing['stars'] == pending['stars'] &&
        existing['points'] == pending['points'];
  }

  Map<String, dynamic> _attemptCloudData(Map<String, dynamic> pending) {
    final Map<String, dynamic> data = <String, dynamic>{
      'eventId': pending['eventId'],
      'groupId': pending['groupId'],
      'uid': pending['uid'],
      'displayName': pending['displayName'],
      'avatar': pending['avatar'],
      'gameId': pending['gameId'],
      'rawScore': pending['rawScore'],
      'stars': pending['stars'],
      'points': pending['points'],
      'submittedAt': FieldValue.serverTimestamp(),
      'schemaVersion': pending['schemaVersion'],
    };
    if (pending['schemaVersion'] == 2) {
      data['outcome'] = pending['outcome'];
    }
    return data;
  }

  bool _canQueueAttemptError(Object error) {
    if (error is TimeoutException) return true;
    if (error is! FirebaseException) return false;
    return const <String>{
      'aborted',
      'cancelled',
      'deadline-exceeded',
      'internal',
      'network-request-failed',
      'resource-exhausted',
      'unavailable',
      'unknown',
    }.contains(error.code);
  }

  Future<bool> _storePendingAttempt(Map<String, dynamic> pending) async {
    try {
      final List<Map<String, dynamic>> items = await _readPendingAttempts();
      final String documentId = _text(pending['documentId']);
      items.removeWhere(
        (Map<String, dynamic> item) => _text(item['documentId']) == documentId,
      );
      items.add(Map<String, dynamic>.from(pending));

      if (items.length > _maxPendingAttempts) {
        items.removeRange(0, items.length - _maxPendingAttempts);
      }

      await _preferences.setString(_pendingAttemptsKey, jsonEncode(items));
      return true;
    } catch (error) {
      debugPrint('Arena pending attempt store failed: $error');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _readPendingAttempts() async {
    final String? encoded = await _preferences.getString(_pendingAttemptsKey);
    if (encoded == null || encoded.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final dynamic decoded = jsonDecode(encoded);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
          .toList(growable: true);
    } catch (error) {
      debugPrint('Arena pending attempt read failed: $error');
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _flushPendingAttempts() async {
    final Future<void>? active = _pendingAttemptSync;
    if (active != null) {
      await active;
      return;
    }

    final Future<void> operation = _flushPendingAttemptsOnce();
    _pendingAttemptSync = operation;
    try {
      await operation;
    } finally {
      if (identical(_pendingAttemptSync, operation)) {
        _pendingAttemptSync = null;
      }
    }
  }

  Future<void> _flushPendingAttemptsOnce() async {
    final List<Map<String, dynamic>> pending = await _readPendingAttempts();
    if (pending.isEmpty) return;

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final String activeUid = currentUid ?? '';
    final List<Map<String, dynamic>> remaining = <Map<String, dynamic>>[];

    for (int index = 0; index < pending.length; index++) {
      final Map<String, dynamic> item = pending[index];
      final dynamic rawExpiry = item['expiresAtMs'];
      if (rawExpiry is int && rawExpiry <= nowMs) continue;
      if (_text(item['uid']) != activeUid) {
        remaining.add(item);
        continue;
      }

      try {
        final bool accepted = await _writeAttempt(item);
        if (!accepted) {
          debugPrint(
            'Arena pending attempt dropped because the immutable result '
            'already exists with different contents.',
          );
        }
      } catch (error) {
        debugPrint('Arena pending attempt sync failed: $error');
        if (_canQueueAttemptError(error)) {
          remaining.addAll(pending.skip(index));
          break;
        }
        // Yetki, doğrulama veya kalıcı veri uyuşmazlığı tekrar denenmez.
        // Böylece reddedilmiş eski bir kayıt kuyruğu sonsuza dek kilitlemez.
      }
    }

    if (remaining.isEmpty) {
      await _preferences.remove(_pendingAttemptsKey);
    } else {
      await _preferences.setString(_pendingAttemptsKey, jsonEncode(remaining));
    }
  }

  String _limitedText(
    String value, {
    required int maxRunes,
    required String fallback,
  }) {
    final String trimmed = value.trim();
    final String safe = trimmed.isEmpty ? fallback : trimmed;
    final List<int> runes = safe.runes.toList(growable: false);
    if (runes.length <= maxRunes) return safe;
    return String.fromCharCodes(runes.take(maxRunes));
  }

  Future<bool> finishEvent(ArenaEvent event) async {
    if (!await ensureOnline()) return false;
    final String? uid = currentUid;
    if (uid == null || event.ownerUid != uid || event.completed) return false;
    try {
      if (event.schemaVersion < 2) {
        await _events.doc(event.id).update(<String, dynamic>{
          'status': 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      final DocumentReference<Map<String, dynamic>> eventRef = _events.doc(
        event.id,
      );
      final DocumentReference<Map<String, dynamic>> groupRef = _groups.doc(
        event.groupId,
      );
      await FirebaseFirestore.instance.runTransaction((
        Transaction transaction,
      ) async {
        final DocumentSnapshot<Map<String, dynamic>> eventSnapshot =
            await transaction.get(eventRef);
        final DocumentSnapshot<Map<String, dynamic>> groupSnapshot =
            await transaction.get(groupRef);
        if (!eventSnapshot.exists || !groupSnapshot.exists) {
          throw StateError('arena-finish-target-missing');
        }

        final Map<String, dynamic> eventData =
            eventSnapshot.data() ?? <String, dynamic>{};
        final Map<String, dynamic> groupData =
            groupSnapshot.data() ?? <String, dynamic>{};
        if (_text(eventData['ownerUid']) != uid ||
            _text(eventData['status']) != 'active' ||
            _nullableText(groupData['activeEventId']) != event.id) {
          throw StateError('arena-finish-state-mismatch');
        }

        transaction.update(eventRef, <String, dynamic>{
          'status': 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(groupRef, <String, dynamic>{
          'activeEventId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (error) {
      debugPrint('Arena event finish failed: $error');
      return false;
    }
  }

  List<ArenaStanding> buildStandings({
    required ArenaEvent event,
    required List<ArenaAttempt> attempts,
    List<OnlineLeaderboardEntry> profiles = const <OnlineLeaderboardEntry>[],
  }) {
    final Map<String, OnlineLeaderboardEntry> profileByUid =
        <String, OnlineLeaderboardEntry>{
          for (final OnlineLeaderboardEntry profile in profiles)
            profile.uid: profile,
        };
    final Map<String, List<ArenaAttempt>> byUid =
        <String, List<ArenaAttempt>>{};
    for (final ArenaAttempt attempt in attempts) {
      if (!event.participantIds.contains(attempt.uid) ||
          !event.gameIds.contains(attempt.gameId)) {
        continue;
      }
      byUid.putIfAbsent(attempt.uid, () => <ArenaAttempt>[]).add(attempt);
    }

    final List<ArenaStanding> standings = event.participantIds.map((
      String uid,
    ) {
      final List<ArenaAttempt> items = byUid[uid] ?? const <ArenaAttempt>[];
      final OnlineLeaderboardEntry? profile = profileByUid[uid];
      return ArenaStanding(
        uid: uid,
        displayName: items.isNotEmpty
            ? items.first.displayName
            : profile?.displayName ?? 'Oyuncu',
        avatar: items.isNotEmpty ? items.first.avatar : profile?.avatar ?? '🧠',
        completedGames: items.length,
        totalGames: event.gameIds.length,
        totalStars: items.fold<int>(0, (int value, ArenaAttempt item) {
          return value + item.stars;
        }),
        totalPoints: items.fold<int>(0, (int value, ArenaAttempt item) {
          return value + item.points;
        }),
      );
    }).toList();

    standings.sort((ArenaStanding a, ArenaStanding b) {
      final int points = b.totalPoints.compareTo(a.totalPoints);
      if (points != 0) return points;
      final int completed = b.completedGames.compareTo(a.completedGames);
      if (completed != 0) return completed;
      final int stars = b.totalStars.compareTo(a.totalStars);
      if (stars != 0) return stars;
      return a.displayName.compareTo(b.displayName);
    });
    return standings;
  }

  List<ArenaWeeklyStanding> buildWeeklyStandings({
    required List<ArenaAttempt> attempts,
    List<OnlineLeaderboardEntry> profiles = const <OnlineLeaderboardEntry>[],
    DateTime? now,
  }) {
    final DateTime current = (now ?? DateTime.now()).toUtc();
    final DateTime today = DateTime.utc(
      current.year,
      current.month,
      current.day,
    );
    final DateTime weekStart = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final Map<String, OnlineLeaderboardEntry> profileByUid =
        <String, OnlineLeaderboardEntry>{
          for (final OnlineLeaderboardEntry profile in profiles)
            profile.uid: profile,
        };
    final Map<String, List<ArenaAttempt>> byUid =
        <String, List<ArenaAttempt>>{};

    for (final ArenaAttempt attempt in attempts) {
      final DateTime? submittedAt = attempt.submittedAt?.toUtc();
      if (submittedAt == null || submittedAt.isBefore(weekStart)) continue;
      byUid.putIfAbsent(attempt.uid, () => <ArenaAttempt>[]).add(attempt);
    }

    final List<ArenaWeeklyStanding> standings = byUid.entries
        .map((MapEntry<String, List<ArenaAttempt>> entry) {
          final List<ArenaAttempt> items = entry.value;
          final OnlineLeaderboardEntry? profile = profileByUid[entry.key];
          return ArenaWeeklyStanding(
            uid: entry.key,
            displayName: items.isNotEmpty
                ? items.first.displayName
                : profile?.displayName ?? 'Oyuncu',
            avatar: items.isNotEmpty
                ? items.first.avatar
                : profile?.avatar ?? '🧠',
            attemptCount: items.length,
            totalStars: items.fold<int>(
              0,
              (int total, ArenaAttempt item) => total + item.stars,
            ),
            totalPoints: items.fold<int>(
              0,
              (int total, ArenaAttempt item) => total + item.points,
            ),
          );
        })
        .toList(growable: false);

    standings.sort((ArenaWeeklyStanding a, ArenaWeeklyStanding b) {
      final int points = b.totalPoints.compareTo(a.totalPoints);
      if (points != 0) return points;
      final int attempts = b.attemptCount.compareTo(a.attemptCount);
      if (attempts != 0) return attempts;
      final int stars = b.totalStars.compareTo(a.totalStars);
      if (stars != 0) return stars;
      return a.displayName.compareTo(b.displayName);
    });
    return standings;
  }

  String _newJoinCode() {
    const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List<String>.generate(
      6,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  static String _normalizeCode(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String _cleanName(String value, {required String fallback}) {
    final String cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return fallback;
    return cleaned.length <= 40 ? cleaned : cleaned.substring(0, 40);
  }
}

String _text(dynamic value, {String fallback = ''}) {
  if (value is! String || value.trim().isEmpty) return fallback;
  return value.trim();
}

String? _nullableText(dynamic value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

class _ArenaActiveEventError implements Exception {
  final String eventId;

  const _ArenaActiveEventError(this.eventId);
}

List<String> _stringList(dynamic value, {required int maxItems}) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().take(maxItems).toList(growable: false);
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

int _safeInt(dynamic value, int min, int max, {int? fallback}) {
  if (value is! num) return fallback ?? min;
  return value.toInt().clamp(min, max).toInt();
}
