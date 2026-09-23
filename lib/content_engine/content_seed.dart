import 'dart:math';

class ContentSeed {
  const ContentSeed._();

  static int mix({
    required int sessionSeed,
    required int level,
    required int round,
    required int salt,
  }) {
    int value = sessionSeed & 0x7fffffff;
    value = (value * 31 + level * 7919) & 0x7fffffff;
    value = (value * 31 + round * 1009) & 0x7fffffff;
    value = (value * 31 + salt * 9176) & 0x7fffffff;
    return value;
  }

  static Random random({
    required int sessionSeed,
    required int level,
    int round = 0,
    int salt = 0,
  }) {
    return Random(
      mix(sessionSeed: sessionSeed, level: level, round: round, salt: salt),
    );
  }
}
