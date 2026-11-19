import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language_controller.dart';
import 'firebase_bootstrap_service.dart';
import 'player_progress_service.dart';
import 'unified_progress_service.dart';

class OnlineLeaderboardEntry {
  final String uid;
  final String displayName;
  final String avatar;
  final int xp;
  final int level;
  final int score;
  final int stars;
  final int completedLevels;
  final int bestStreak;
  final int perfectDays;
  final String leagueShortName;
  final String locale;
  final String friendCode;
  final DateTime? updatedAt;

  const OnlineLeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.avatar,
    required this.xp,
    required this.level,
    required this.score,
    required this.stars,
    required this.completedLevels,
    required this.bestStreak,
    required this.perfectDays,
    required this.leagueShortName,
    required this.locale,
    required this.friendCode,
    required this.updatedAt,
  });

  bool get recentlyActive {
    final DateTime? lastSeen = updatedAt;
    if (lastSeen == null) return false;
    final Duration age = DateTime.now().difference(lastSeen);
    return !age.isNegative && age <= const Duration(minutes: 15);
  }

  factory OnlineLeaderboardEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return OnlineLeaderboardEntry._fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  factory OnlineLeaderboardEntry.fromCache(Map<String, dynamic> data) {
    return OnlineLeaderboardEntry._fromMap(
      _safeString(data['uid'], fallback: '', maxLength: 128),
      data,
    );
  }

  factory OnlineLeaderboardEntry._fromMap(
    String uid,
    Map<String, dynamic> data,
  ) {
    final dynamic rawUpdatedAt = data['updatedAt'];
    DateTime? updatedAt;

    if (rawUpdatedAt is Timestamp) {
      updatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is String) {
      updatedAt = DateTime.tryParse(rawUpdatedAt);
    }

    final int completedLevels = _safeInt(
      data['completedLevels'],
      0,
      UnifiedProgressData.maksimumSeviye,
    );

    final int rawScore = _safeInt(data['score'], 0, 10000000);
    int normalizedScore = rawScore;
    if (completedLevels > 0 && normalizedScore > (completedLevels * 15 + 100)) {
      normalizedScore = (normalizedScore / 18.0).round().clamp(10, 1000000);
    }

    final int rawXp = _safeInt(data['xp'], 0, 1000000);
    int normalizedXp = rawXp;
    if (completedLevels > 0 && normalizedXp > (completedLevels * 15 + 100)) {
      normalizedXp = (normalizedXp / 18.0).round().clamp(10, 1000000);
    }

    return OnlineLeaderboardEntry(
      uid: uid,
      displayName: _safeString(
        data['displayName'],
        fallback: 'Player',
        maxLength: 18,
      ),
      avatar: _safeString(data['avatar'], fallback: '🧠', maxLength: 32),
      xp: normalizedXp,
      level: _safeInt(data['level'], 1, 50),
      score: normalizedScore,
      stars: _safeInt(data['stars'], 0, UnifiedProgressData.maksimumYildiz),
      completedLevels: completedLevels,
      bestStreak: _safeInt(data['bestStreak'], 0, 10000),
      perfectDays: _safeInt(data['perfectDays'], 0, 10000),
      leagueShortName: _safeString(
        data['league'],
        fallback: 'BAŞLANGIÇ',
        maxLength: 16,
      ),
      locale: _safeString(data['locale'], fallback: 'en', maxLength: 10),
      friendCode: _safeString(data['friendCode'], fallback: '', maxLength: 10),
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toCacheMap() {
    return <String, dynamic>{
      'uid': uid,
      'displayName': displayName,
      'avatar': avatar,
      'xp': xp,
      'level': level,
      'score': score,
      'stars': stars,
      'completedLevels': completedLevels,
      'bestStreak': bestStreak,
      'perfectDays': perfectDays,
      'league': leagueShortName,
      'locale': locale,
      'friendCode': friendCode,
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
    };
  }

  static String _safeString(
    dynamic value, {
    required String fallback,
    required int maxLength,
  }) {
    if (value is! String) return fallback;

    final String trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;

    return trimmed.length > maxLength
        ? trimmed.substring(0, maxLength)
        : trimmed;
  }

  static int _safeInt(dynamic value, int min, int max) {
    if (value is! num) return min;

    return value.toInt().clamp(min, max).toInt();
  }
}

class OnlineLeaderboardResult {
  final bool online;
  final bool fromCache;
  final bool syncPending;
  final DateTime? cachedAt;
  final List<OnlineLeaderboardEntry> entries;
  final String? currentUid;
  final int? currentRank;
  final int? totalPlayers;
  final String? error;

  const OnlineLeaderboardResult({
    required this.online,
    required this.fromCache,
    required this.syncPending,
    required this.cachedAt,
    required this.entries,
    required this.currentUid,
    required this.currentRank,
    required this.totalPlayers,
    required this.error,
  });

  factory OnlineLeaderboardResult.offline({
    required String? error,
    bool syncPending = false,
  }) {
    return OnlineLeaderboardResult(
      online: false,
      fromCache: false,
      syncPending: syncPending,
      cachedAt: null,
      entries: const <OnlineLeaderboardEntry>[],
      currentUid: null,
      currentRank: null,
      totalPlayers: null,
      error: error,
    );
  }
}

class OnlineLeaderboardService {
  OnlineLeaderboardService._();

  static final OnlineLeaderboardService instance = OnlineLeaderboardService._();

  static const String _collectionName = 'leaderboard_v3_public';
  static const String _cacheKey = 'leaderboard_v3_last_snapshot';
  static const String _pendingSyncKey = 'leaderboard_v3_pending_player_sync';
  static const Duration _connectTimeout = Duration(seconds: 8);
  static const Duration _writeTimeout = Duration(seconds: 7);
  static const Duration _readTimeout = Duration(seconds: 10);

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Future<bool>? _syncingFuture;

  FirebaseBootstrapService get _firebase => FirebaseBootstrapService.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(_collectionName);

  Future<bool> syncCurrentPlayer(PlayerDashboardData data) async {
    await _ensureFirebaseReady();

    final String? uid = _firebase.uid;
    if (uid == null || uid.isEmpty) return false;

    final Map<String, dynamic> publicData = _publicPlayerData(data);

    // The latest local state replaces the previous pending state. This keeps
    // reconnects idempotent and prevents duplicate queue records.
    await _storePendingSync(uid, publicData);
    return _flushPendingSync();
  }

  Future<bool> retryPendingSync() => _flushPendingSync();

  Future<bool> hasPendingSync() async {
    try {
      return (await _prefs.getString(_pendingSyncKey)) != null;
    } catch (error) {
      debugPrint('Leaderboard pending-state read failed: $error');
      return false;
    }
  }

  Future<OnlineLeaderboardResult> loadCachedGlobal() {
    return _offlineFromCache(null);
  }

  Future<OnlineLeaderboardResult> fetchGlobal({int limit = 30}) async {
    if (!await _ensureFirebaseReady()) {
      return _offlineFromCache(_firebase.lastError);
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
          .orderBy('score', descending: true)
          .limit(limit.clamp(5, 100).toInt())
          .get(const GetOptions(source: Source.server))
          .timeout(_readTimeout);

      final List<OnlineLeaderboardEntry> entries = snapshot.docs
          .map(OnlineLeaderboardEntry.fromSnapshot)
          .toList(growable: false);

      final List<OnlineLeaderboardEntry> sorted =
          List<OnlineLeaderboardEntry>.from(entries);

      // V7.2'de resmi sıralama alanı adil ve merkezi Zeka Puanı'dır.
      // Yıldız ve tamamlanan bölüm yalnızca eşit puanı bozar.
      sorted.sort((a, b) {
        final int scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;

        final int starCompare = b.stars.compareTo(a.stars);
        if (starCompare != 0) return starCompare;

        return b.completedLevels.compareTo(a.completedLevels);
      });

      final String? currentUid = _firebase.uid;
      int? currentRank = _rankFromLoadedEntries(sorted, currentUid);
      int? totalPlayers;

      // The visible list remains usable even if global count/rank aggregation
      // is temporarily unavailable.
      try {
        final AggregateQuerySnapshot totalSnapshot = await _collection
            .count()
            .get()
            .timeout(_readTimeout);
        totalPlayers = totalSnapshot.count;

        if (currentUid != null && currentUid.isNotEmpty) {
          final DocumentSnapshot<Map<String, dynamic>> currentSnapshot =
              await _collection
                  .doc(currentUid)
                  .get(const GetOptions(source: Source.server))
                  .timeout(_readTimeout);

          if (currentSnapshot.exists) {
            final OnlineLeaderboardEntry currentEntry =
                OnlineLeaderboardEntry.fromSnapshot(currentSnapshot);

            if (!sorted.any((entry) => entry.uid == currentUid)) {
              sorted.add(currentEntry);
            }

            final AggregateQuerySnapshot higherScoreSnapshot = await _collection
                .where('score', isGreaterThan: currentEntry.score)
                .count()
                .get()
                .timeout(_readTimeout);

            currentRank = (higherScoreSnapshot.count ?? 0) + 1;
          }
        }
      } catch (aggregateError) {
        debugPrint(
          'Leaderboard rank/count aggregation failed: '
          '$aggregateError',
        );
        totalPlayers ??= sorted.length;
      }

      final OnlineLeaderboardResult result = OnlineLeaderboardResult(
        online: true,
        fromCache: false,
        syncPending: await hasPendingSync(),
        cachedAt: null,
        entries: sorted,
        currentUid: currentUid,
        currentRank: currentRank,
        totalPlayers: totalPlayers ?? sorted.length,
        error: null,
      );

      await _saveCache(result);
      return result;
    } catch (error) {
      debugPrint('Leaderboard fetch failed: $error');
      return _offlineFromCache(
        'Dünya sıralamasına bağlanılamadı. İnternet, Özel DNS, VPN veya '
        'reklam engelleyici ayarını kontrol et.',
      );
    }
  }

  String friendCodeForUid(String uid) {
    final String normalized = uid.toUpperCase().replaceAll(
      RegExp('[^A-Z0-9]'),
      '',
    );
    if (normalized.length >= 8) return normalized.substring(0, 8);
    return normalized.padRight(8, 'X');
  }

  Future<OnlineLeaderboardEntry?> findByFriendCode(String rawCode) async {
    if (!await _ensureFirebaseReady()) return null;

    final String code = rawCode.trim().toUpperCase().replaceAll(
      RegExp('[^A-Z0-9]'),
      '',
    );
    if (code.length != 8) return null;

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
          .where('friendCode', isEqualTo: code)
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(_readTimeout);
      if (snapshot.docs.isEmpty) return null;
      return OnlineLeaderboardEntry.fromSnapshot(snapshot.docs.first);
    } catch (error) {
      debugPrint('Friend-code lookup failed: $error');
      return null;
    }
  }

  Future<List<OnlineLeaderboardEntry>> fetchPlayersByUid(
    Iterable<String> uids,
  ) async {
    if (!await _ensureFirebaseReady()) {
      return const <OnlineLeaderboardEntry>[];
    }

    final List<String> unique = uids
        .where((uid) => uid.trim().isNotEmpty)
        .toSet()
        .take(30)
        .toList(growable: false);
    if (unique.isEmpty) return const <OnlineLeaderboardEntry>[];

    final List<OnlineLeaderboardEntry> result = <OnlineLeaderboardEntry>[];
    for (final String uid in unique) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _collection.doc(uid).get();
        if (snapshot.exists) {
          result.add(OnlineLeaderboardEntry.fromSnapshot(snapshot));
        }
      } catch (error) {
        debugPrint('Friend profile read failed: $uid | $error');
      }
    }
    return result;
  }

  Future<bool> _ensureFirebaseReady() async {
    if (_firebase.ready) return true;

    try {
      await _firebase.initialize().timeout(_connectTimeout);
    } catch (error) {
      debugPrint('Leaderboard reconnect failed: $error');
    }

    return _firebase.ready;
  }

  Map<String, dynamic> _publicPlayerData(PlayerDashboardData data) {
    return <String, dynamic>{
      'displayName': _sanitizeName(data.profile.displayName),
      'avatar': _sanitizeAvatar(data.profile.avatar),
      'xp': data.zekaScore.clamp(0, 1000000).toInt(),
      'level': data.level.clamp(1, 50).toInt(),
      'score': data.zekaScore.clamp(0, 10000000).toInt(),
      'stars': data.progress.toplamYildiz
          .clamp(0, UnifiedProgressData.maksimumYildiz)
          .toInt(),
      'completedLevels': data.progress.tamamlananSeviye
          .clamp(0, UnifiedProgressData.maksimumSeviye)
          .toInt(),
      'bestStreak': data.daily.bestStreak.clamp(0, 10000).toInt(),
      'perfectDays': data.daily.perfectDays.clamp(0, 10000).toInt(),
      'league': data.league.shortName,
      'locale': AppLanguageController.instance.resolvedLocale.languageCode,
      'friendCode': friendCodeForUid(_firebase.uid ?? ''),
      'schemaVersion': 3,
    };
  }

  Future<void> _storePendingSync(String uid, Map<String, dynamic> data) async {
    try {
      await _prefs.setString(
        _pendingSyncKey,
        jsonEncode(<String, dynamic>{'uid': uid, 'data': data}),
      );
    } catch (error) {
      debugPrint('Leaderboard pending-state write failed: $error');
    }
  }

  Future<bool> _flushPendingSync() async {
    final Future<bool>? activeSync = _syncingFuture;
    if (activeSync != null) return activeSync;

    final Future<bool> operation = _flushPendingSyncOnce();
    _syncingFuture = operation;

    try {
      return await operation;
    } finally {
      if (identical(_syncingFuture, operation)) {
        _syncingFuture = null;
      }
    }
  }

  Future<bool> _flushPendingSyncOnce() async {
    if (!await _ensureFirebaseReady()) return false;

    // Two passes cover the rare case where the player finishes another level
    // while an older payload is still being written.
    for (int pass = 0; pass < 2; pass++) {
      final String? raw = await _prefs.getString(_pendingSyncKey);
      if (raw == null) return true;

      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is! Map) {
          await _removePendingIfUnchanged(raw);
          return false;
        }

        final Map<String, dynamic> pending = Map<String, dynamic>.from(decoded);
        final String uid = pending['uid'] is String
            ? (pending['uid'] as String).trim()
            : '';
        final dynamic rawData = pending['data'];

        if (uid.isEmpty || rawData is! Map) {
          await _removePendingIfUnchanged(raw);
          return false;
        }

        final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);

        await _collection
            .doc(uid)
            .set(<String, dynamic>{
              ...data,
              'uid': uid,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(_writeTimeout);

        final String? latest = await _prefs.getString(_pendingSyncKey);
        if (latest == raw) {
          await _prefs.remove(_pendingSyncKey);
          return true;
        }
      } catch (error) {
        debugPrint('Leaderboard sync failed: $error');
        return false;
      }
    }

    return false;
  }

  Future<void> _removePendingIfUnchanged(String raw) async {
    final String? latest = await _prefs.getString(_pendingSyncKey);
    if (latest == raw) {
      await _prefs.remove(_pendingSyncKey);
    }
  }

  Future<void> _saveCache(OnlineLeaderboardResult result) async {
    try {
      await _prefs.setString(
        _cacheKey,
        jsonEncode(<String, dynamic>{
          'savedAt': DateTime.now().toUtc().toIso8601String(),
          'currentUid': result.currentUid,
          'currentRank': result.currentRank,
          'totalPlayers': result.totalPlayers,
          'entries': result.entries
              .map((entry) => entry.toCacheMap())
              .toList(growable: false),
        }),
      );
    } catch (error) {
      debugPrint('Leaderboard cache write failed: $error');
    }
  }

  Future<OnlineLeaderboardResult> _offlineFromCache(String? error) async {
    final bool syncPending = await hasPendingSync();

    try {
      final String? raw = await _prefs.getString(_cacheKey);
      if (raw == null) {
        return OnlineLeaderboardResult.offline(
          error: error,
          syncPending: syncPending,
        );
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return OnlineLeaderboardResult.offline(
          error: error,
          syncPending: syncPending,
        );
      }

      final Map<String, dynamic> cache = Map<String, dynamic>.from(decoded);
      final dynamic rawEntries = cache['entries'];
      if (rawEntries is! List) {
        return OnlineLeaderboardResult.offline(
          error: error,
          syncPending: syncPending,
        );
      }

      final List<OnlineLeaderboardEntry> entries = rawEntries
          .whereType<Map>()
          .map(
            (entry) => OnlineLeaderboardEntry.fromCache(
              Map<String, dynamic>.from(entry),
            ),
          )
          .where((entry) => entry.uid.isNotEmpty)
          .toList(growable: false);

      return OnlineLeaderboardResult(
        online: false,
        fromCache: true,
        syncPending: syncPending,
        cachedAt: cache['savedAt'] is String
            ? DateTime.tryParse(cache['savedAt'] as String)
            : null,
        entries: entries,
        currentUid: cache['currentUid'] is String
            ? cache['currentUid'] as String
            : _firebase.uid,
        currentRank: cache['currentRank'] is num
            ? (cache['currentRank'] as num).toInt()
            : null,
        totalPlayers: cache['totalPlayers'] is num
            ? (cache['totalPlayers'] as num).toInt()
            : entries.length,
        error: error,
      );
    } catch (cacheError) {
      debugPrint('Leaderboard cache read failed: $cacheError');
      return OnlineLeaderboardResult.offline(
        error: error,
        syncPending: syncPending,
      );
    }
  }

  int? _rankFromLoadedEntries(
    List<OnlineLeaderboardEntry> entries,
    String? currentUid,
  ) {
    if (currentUid == null || currentUid.isEmpty) return null;

    final int index = entries.indexWhere((entry) => entry.uid == currentUid);

    if (index < 0) return null;

    final int currentScore = entries[index].score;
    int playersWithHigherScore = 0;

    for (final OnlineLeaderboardEntry entry in entries) {
      if (entry.score > currentScore) playersWithHigherScore++;
    }

    return playersWithHigherScore + 1;
  }

  String _sanitizeName(String value) {
    final String trimmed = value.trim();
    final String safe = trimmed.isEmpty ? 'Player' : trimmed;

    return safe.length > 18 ? safe.substring(0, 18) : safe;
  }

  String _sanitizeAvatar(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return '🧠';

    return trimmed.length > 32 ? trimmed.substring(0, 32) : trimmed;
  }
}
