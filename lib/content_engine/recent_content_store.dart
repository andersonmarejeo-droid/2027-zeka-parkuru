import 'package:shared_preferences/shared_preferences.dart';

import 'content_version.dart';

class RecentContentStore {
  final SharedPreferencesAsync _prefs;

  RecentContentStore({SharedPreferencesAsync? preferences})
    : _prefs = preferences ?? SharedPreferencesAsync();

  Future<Set<String>> recentItems({
    required String gameId,
    required int level,
  }) async {
    final List<String> values =
        await _prefs.getStringList(_itemKey(gameId, level)) ?? <String>[];
    return values.toSet();
  }

  Future<Set<String>> recentSessions({
    required String gameId,
    required int level,
  }) async {
    final List<String> values =
        await _prefs.getStringList(_sessionKey(gameId, level)) ?? <String>[];
    return values.toSet();
  }

  Future<bool> rememberSession({
    required String gameId,
    required int level,
    required String fingerprint,
    ContentHistoryPolicy policy = const ContentHistoryPolicy(),
  }) async {
    return _remember(
      key: _sessionKey(gameId, level),
      fingerprints: <String>[fingerprint],
      limit: policy.sessionLimit,
    );
  }

  Future<bool> rememberItems({
    required String gameId,
    required int level,
    required Iterable<String> fingerprints,
    ContentHistoryPolicy policy = const ContentHistoryPolicy(),
  }) async {
    return _remember(
      key: _itemKey(gameId, level),
      fingerprints: fingerprints,
      limit: policy.itemLimit,
    );
  }

  Future<bool> _remember({
    required String key,
    required Iterable<String> fingerprints,
    required int limit,
  }) async {
    final List<String> current = await _prefs.getStringList(key) ?? <String>[];
    final List<String> incoming = fingerprints.toSet().toList(growable: false);
    final Set<String> previous = current.toSet();
    final bool allFresh = incoming.every(
      (String item) => !previous.contains(item),
    );

    final Set<String> incomingSet = incoming.toSet();
    final List<String> updated = <String>[
      ...incoming.reversed,
      ...current.where((String item) => !incomingSet.contains(item)),
    ].take(limit).toList(growable: false);

    await _prefs.setStringList(key, updated);
    return allFresh;
  }

  String _itemKey(String gameId, int level) {
    return 'content_items_${kContentEngineVersion}_${gameId}_$level';
  }

  String _sessionKey(String gameId, int level) {
    return 'content_sessions_${kContentEngineVersion}_${gameId}_$level';
  }
}
