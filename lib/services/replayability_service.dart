import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../content_engine/content_seed.dart';

class ReplayabilityService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const int _historyLimit = 80;
  static final Random _entropy = Random.secure();

  Future<int> newSeed({required String gameId, required int level}) async {
    final String key = 'replay_history_${gameId}_$level';

    final List<String> saved = await _prefs.getStringList(key) ?? <String>[];

    final Set<int> recent = saved.map(int.tryParse).whereType<int>().toSet();

    int seed;
    int guard = 0;

    do {
      final int nowPart = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
      final int randomPart = _entropy.nextInt(0x7fffffff);

      seed = (nowPart ^ randomPart ^ (level * 7919)) & 0x7fffffff;
      guard++;
    } while (recent.contains(seed) && guard < 100);

    final List<String> updated = <String>[
      seed.toString(),
      ...saved.where((value) => value != seed.toString()),
    ].take(_historyLimit).toList();

    await _prefs.setStringList(key, updated);

    return seed;
  }

  Random randomFor({
    required int sessionSeed,
    required int round,
    int salt = 0,
  }) {
    return ContentSeed.random(
      sessionSeed: sessionSeed,
      level: 0,
      round: round,
      salt: salt,
    );
  }

  Future<bool> registerFingerprint({
    required String gameId,
    required int level,
    required String fingerprint,
    int historyLimit = 12,
  }) async {
    final String key = 'replay_fp_${gameId}_$level';

    final List<String> history = await _prefs.getStringList(key) ?? <String>[];

    final bool wasRecent = history.contains(fingerprint);

    final List<String> updated = <String>[
      fingerprint,
      ...history.where((item) => item != fingerprint),
    ].take(historyLimit).toList();

    await _prefs.setStringList(key, updated);

    return !wasRecent;
  }
}
