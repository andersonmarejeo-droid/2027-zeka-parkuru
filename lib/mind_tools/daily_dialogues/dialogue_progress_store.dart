import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DialogueProgressStore {
  DialogueProgressStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String storageKey = 'mind_tool_daily_dialogues_v1';
  final SharedPreferencesAsync _preferences;

  Future<Map<String, int>> loadBestClarity() async {
    final String? raw = await _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return <String, int>{};
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Conversation progress must be a map.');
    }
    final Map<String, int> result = <String, int>{};
    for (final MapEntry<String, Object?> entry in decoded.entries) {
      if (entry.value is int) {
        result[entry.key] = (entry.value! as int).clamp(0, 4);
      }
    }
    return result;
  }

  Future<void> recordCompletion(String scenarioId, int clarityPoints) async {
    if (scenarioId.trim().isEmpty) {
      throw ArgumentError('Scenario id is required.');
    }
    if (clarityPoints < 0 || clarityPoints > 4) {
      throw RangeError.range(clarityPoints, 0, 4, 'clarityPoints');
    }
    final Map<String, int> current = await loadBestClarity();
    final int oldBest = current[scenarioId] ?? -1;
    if (clarityPoints <= oldBest) {
      return;
    }
    current[scenarioId] = clarityPoints;
    final Map<String, int> sorted = Map<String, int>.fromEntries(
      current.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    await _preferences.setString(storageKey, jsonEncode(sorted));
  }
}
