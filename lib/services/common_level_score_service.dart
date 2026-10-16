import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// A single, predictable score for every campaign level.
///
/// A completed level is worth ten points. Each hint costs two points, down to
/// zero. Completion and unlocking are deliberately independent of the score.
class CommonLevelScoreSession {
  CommonLevelScoreSession._();

  static const int pointsPerLevel = 10;
  static const int pointsPerHint = 2;

  static CommonLevelScoreSession? _active;

  int _hintsUsed = 0;
  bool _finished = false;

  static CommonLevelScoreSession begin() {
    final CommonLevelScoreSession session = CommonLevelScoreSession._();
    _active = session;
    return session;
  }

  static void recordHint() {
    _active?._recordHint();
  }

  int get hintsUsed => _hintsUsed;

  int get points => (pointsPerLevel - (_hintsUsed * pointsPerHint))
      .clamp(0, pointsPerLevel)
      .toInt();

  int finish() {
    if (!_finished) {
      _finished = true;
      if (identical(_active, this)) _active = null;
    }
    return points;
  }

  void _recordHint() {
    if (!_finished) _hintsUsed++;
  }
}

abstract final class CommonLevelScoreStore {
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<List<int>> load({
    required String gameId,
    required int levelCount,
    required List<int> completedStars,
  }) async {
    final List<String>? stored = await _prefs.getStringList(
      '${gameId}_common_points',
    );
    return List<int>.generate(levelCount, (int index) {
      if (stored != null && index < stored.length) {
        return (int.tryParse(stored[index]) ?? 0)
            .clamp(0, CommonLevelScoreSession.pointsPerLevel)
            .toInt();
      }
      return index < completedStars.length && completedStars[index] > 0
          ? CommonLevelScoreSession.pointsPerLevel
          : 0;
    }, growable: false);
  }

  static Future<void> recordBest({
    required String gameId,
    required int levelIndex,
    required int points,
    required int levelCount,
    required List<int> completedStars,
  }) async {
    final List<int> commonPoints = await load(
      gameId: gameId,
      levelCount: levelCount,
      completedStars: completedStars,
    );
    if (levelIndex < 0 || levelIndex >= commonPoints.length) return;
    commonPoints[levelIndex] = max(
      commonPoints[levelIndex],
      points.clamp(0, CommonLevelScoreSession.pointsPerLevel).toInt(),
    );
    await _prefs.setStringList(
      '${gameId}_common_points',
      commonPoints.map((int value) => '$value').toList(growable: false),
    );
  }
}
