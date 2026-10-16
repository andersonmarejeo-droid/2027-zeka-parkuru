import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'studio_game_contracts.dart';

/// Small persisted cursors, not eagerly decoded boards. Each chapter cycles
/// through its own disjoint slice of the deterministic content pool.
abstract final class CampaignRoundStore {
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static final Map<String, int> _fallbackCursors = {};
  static Future<void>? _pending;

  static Future<int> reserve(String gameId, int chapter) async {
    final previous = _pending;
    final completer = Completer<void>();
    _pending = completer.future;
    if (previous != null) await previous;
    try {
      final key = 'campaign30_${gameId}_chapter_${chapter}_cursor';
      int cursor = _fallbackCursors[key] ?? 0;
      try {
        cursor =
            (await _preferences
                        .getInt(key)
                        .timeout(const Duration(seconds: 2)) ??
                    0)
                .clamp(0, 1 << 30);
        await _preferences
            .setInt(key, cursor + 1)
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        // A temporarily unavailable platform store must never block play.
      }
      _fallbackCursors[key] = cursor + 1;
      final int variantCount = GameContentPolicy.variantsForChapter(
        gameId,
        chapter,
      );
      return GameContentPolicy.poolIndexForGame(
        gameId,
        chapter,
        cursor % variantCount,
        stages: GameContentPolicy.nativeStages(gameId),
      );
    } finally {
      completer.complete();
      if (identical(_pending, completer.future)) _pending = null;
    }
  }
}
