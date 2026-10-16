import '../../services/common_level_score_service.dart';
import '../../services/daily_course_service.dart';
import 'parkur_game_kit.dart';

/// The deliberately small state machine shared by future games.
///
/// It does not contain a puzzle's rules. It only prevents the recurring UI
/// failures around pause, duplicate completion and result routing.
enum StudioGamePhase { ready, playing, paused, completed, failed, exited }

enum StudioResultAction { replay, map, next }

class StudioGameResult {
  const StudioGameResult._({
    required this.phase,
    required this.score,
    required this.stars,
    required this.action,
  });

  final StudioGamePhase phase;
  final int score;
  final int stars;
  final StudioResultAction action;

  bool get completed => phase == StudioGamePhase.completed;

  factory StudioGameResult.completed({
    required int score,
    required int stars,
    StudioResultAction action = StudioResultAction.map,
  }) {
    return StudioGameResult._(
      phase: StudioGamePhase.completed,
      score: score.clamp(0, 10000000).toInt(),
      stars: stars.clamp(0, 3).toInt(),
      action: action,
    );
  }

  factory StudioGameResult.failed({int score = 0}) => StudioGameResult._(
    phase: StudioGamePhase.failed,
    score: score.clamp(0, 10000000).toInt(),
    stars: 0,
    action: StudioResultAction.replay,
  );

  factory StudioGameResult.exited({int score = 0}) => StudioGameResult._(
    phase: StudioGamePhase.exited,
    score: score.clamp(0, 10000000).toInt(),
    stars: 0,
    action: StudioResultAction.map,
  );

  ParkurGameResult toParkurResult() => ParkurGameResult(
    completed: completed,
    stars: stars,
    score: score,
    nextLevel: completed && action == StudioResultAction.next,
    replayLevel: action == StudioResultAction.replay,
  );

  DailyStageResult toDailyStageResult(String gameId) {
    return switch (phase) {
      StudioGamePhase.completed => DailyStageResult.completed(
        gameId: gameId,
        stars: stars,
        rawScore: score,
      ),
      StudioGamePhase.failed => DailyStageResult.failed(gameId: gameId),
      _ => DailyStageResult.exited(gameId: gameId),
    };
  }
}

class StudioGameSession {
  /// A hint should support deduction, never replace the level's solution.
  /// Individual games may choose a smaller cap for a simpler board.
  static const int defaultMaxHints = 3;
  static const int maximumSupportedHints = 6;

  StudioGameSession({
    required this.level,
    required this.seed,
    int maxHints = defaultMaxHints,
  }) : maxHints = maxHints.clamp(0, maximumSupportedHints).toInt();

  final int level;
  final int seed;
  final int maxHints;

  StudioGamePhase _phase = StudioGamePhase.ready;
  int _score = 0;
  int _mistakes = 0;
  int _hintsUsed = 0;

  StudioGamePhase get phase => _phase;
  int get score => _score;
  int get mistakes => _mistakes;
  int get hintsUsed => _hintsUsed;
  int get remainingHints =>
      (maxHints - _hintsUsed).clamp(0, maxHints).toInt();
  bool get canUseHint => acceptsInput && _hintsUsed < maxHints;
  bool get acceptsInput => _phase == StudioGamePhase.playing;

  void start() {
    if (_phase == StudioGamePhase.ready) _phase = StudioGamePhase.playing;
  }

  void pause() {
    if (_phase == StudioGamePhase.playing) _phase = StudioGamePhase.paused;
  }

  void resume() {
    if (_phase == StudioGamePhase.paused) _phase = StudioGamePhase.playing;
  }

  bool recordAccepted({int points = 0}) {
    if (!acceptsInput) return false;
    _score = (_score + points).clamp(0, 10000000).toInt();
    return true;
  }

  bool recordMistake() {
    if (!acceptsInput) return false;
    _mistakes++;
    return true;
  }

  bool useHint({int pointCost = 0}) {
    if (!canUseHint) return false;
    _hintsUsed++;
    _score = (_score - pointCost).clamp(0, 10000000).toInt();
    CommonLevelScoreSession.recordHint();
    return true;
  }

  StudioGameResult complete({
    required int stars,
    StudioResultAction action = StudioResultAction.map,
  }) {
    if (_phase != StudioGamePhase.playing) {
      return StudioGameResult.exited(score: _score);
    }
    _phase = StudioGamePhase.completed;
    return StudioGameResult.completed(
      score: _score,
      stars: stars,
      action: action,
    );
  }

  StudioGameResult fail() {
    if (!acceptsInput) return StudioGameResult.exited(score: _score);
    _phase = StudioGamePhase.failed;
    return StudioGameResult.failed(score: _score);
  }

  StudioGameResult exit() {
    if (_phase == StudioGamePhase.completed ||
        _phase == StudioGamePhase.failed) {
      return StudioGameResult.exited(score: _score);
    }
    _phase = StudioGamePhase.exited;
    return StudioGameResult.exited(score: _score);
  }
}
