import 'dart:math';

/// Stable seeds allow a level to be reproduced in replay, QA and competition.
abstract final class ContentSeed {
  static int forLevel({
    required String gameId,
    required int level,
    int attempt = 0,
  }) {
    int hash = 0x811C9DC5;
    for (final int unit in '$gameId:$level:$attempt'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static Random randomFor({
    required String gameId,
    required int level,
    int attempt = 0,
  }) => Random(forLevel(gameId: gameId, level: level, attempt: attempt));
}
