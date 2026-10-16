import '../games/shared/studio_game_contracts.dart';

import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/catalog/domain/studio_game_catalog.dart';
import 'zeka_scoring_service.dart';

class DailyCourseGameResult {
  final String gameId;
  final int stars;
  final int score;

  const DailyCourseGameResult({
    required this.gameId,
    required this.stars,
    required this.score,
  });
}

/// A result that belongs only to the Daily Course flow.
///
/// Other competition flows deliberately keep using [DailyCourseGameResult]
/// so their existing behaviour is not changed by the Daily Course rules.
enum DailyStageOutcome { completed, failed, skipped, exited }

class DailyStageResult {
  final String gameId;
  final DailyStageOutcome outcome;
  final int stars;
  final int rawScore;

  const DailyStageResult._({
    required this.gameId,
    required this.outcome,
    required this.stars,
    required this.rawScore,
  });

  const DailyStageResult.completed({
    required String gameId,
    required int stars,
    required int rawScore,
  }) : this._(
         gameId: gameId,
         outcome: DailyStageOutcome.completed,
         stars: stars,
         rawScore: rawScore,
       );

  const DailyStageResult.failed({required String gameId})
    : this._(
        gameId: gameId,
        outcome: DailyStageOutcome.failed,
        stars: 0,
        rawScore: 0,
      );

  const DailyStageResult.skipped({required String gameId})
    : this._(
        gameId: gameId,
        outcome: DailyStageOutcome.skipped,
        stars: 0,
        rawScore: 0,
      );

  const DailyStageResult.exited({required String gameId})
    : this._(
        gameId: gameId,
        outcome: DailyStageOutcome.exited,
        stars: 0,
        rawScore: 0,
      );

  bool get resolvesStage => outcome != DailyStageOutcome.exited;
}

class DailyCourseData {
  final String dateKey;
  final List<String> games;

  /// Kept for compatibility with the existing page and tests. In V3 this set
  /// means "resolved" and therefore includes completed, failed and skipped
  /// stations.
  final Set<String> completedGames;
  final Set<String> successfulGames;
  final Set<String> failedGames;
  final Set<String> skippedGames;
  final int totalStars;
  final int totalScore;

  const DailyCourseData({
    required this.dateKey,
    required this.games,
    required this.completedGames,
    this.successfulGames = const <String>{},
    this.failedGames = const <String>{},
    this.skippedGames = const <String>{},
    required this.totalStars,
    required this.totalScore,
  });

  int get completedCount => games.where(completedGames.contains).length;
  int get successfulCount => games.where(successfulGames.contains).length;

  bool get allCompleted => games.isNotEmpty && completedCount == games.length;
  bool get allSuccessful => games.isNotEmpty && successfulCount == games.length;

  String? get nextGameId {
    for (final String gameId in games) {
      if (!completedGames.contains(gameId)) return gameId;
    }
    return null;
  }

  bool isCompleted(String gameId) => completedGames.contains(gameId);

  DailyStageOutcome? outcomeFor(String gameId) {
    if (successfulGames.contains(gameId)) return DailyStageOutcome.completed;
    if (failedGames.contains(gameId)) return DailyStageOutcome.failed;
    if (skippedGames.contains(gameId)) return DailyStageOutcome.skipped;
    return null;
  }
}

class DailyCourseService {
  DailyCourseService._();

  static final DailyCourseService instance = DailyCourseService._();

  static const int dailyGameCount = 8;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  Future<void>? _countingFuture;
  Future<DailyCourseData>? _recordingFuture;

  /// Every active catalog game can appear in the daily course. Retired and
  /// planned entries are excluded by [StudioGameCatalog.playable].
  static final List<String> gameIds = List<String>.unmodifiable(
    StudioGameCatalog.playable.map((GameDefinition game) => game.id),
  );

  static const String _stateKey = 'daily_course_v3_state';
  static const String _dateKeyName = 'daily_course_v1_date';
  static const String _completedKey = 'daily_course_v1_completed_games';
  static const String _starsKey = 'daily_course_v1_stars';
  static const String _scoreKey = 'daily_course_v2_brain_score';
  static const String _countedDatesKey = 'daily_course_v1_counted_dates';

  Future<DailyCourseData> loadToday() async {
    final DateTime now = DateTime.now();
    final _DailyCoursePersistedState state = await _loadStateForToday(now);
    return _dataFromState(now, state, countCompletion: true);
  }

  Future<DailyCourseData> _dataFromState(
    DateTime now,
    _DailyCoursePersistedState state, {
    required bool countCompletion,
  }) async {
    final List<String> games = gamesForDate(now);
    final Set<String> resolved = <String>{};
    final Set<String> successful = <String>{};
    final Set<String> failed = <String>{};
    final Set<String> skipped = <String>{};
    int totalStars = state.legacyStars;
    int totalScore = state.legacyScore;

    for (final MapEntry<String, _DailyStageRecord> entry
        in state.records.entries) {
      if (!games.contains(entry.key)) continue;
      resolved.add(entry.key);
      totalStars += entry.value.stars;
      totalScore += entry.value.points;
      switch (entry.value.outcome) {
        case DailyStageOutcome.completed:
          successful.add(entry.key);
        case DailyStageOutcome.failed:
          failed.add(entry.key);
        case DailyStageOutcome.skipped:
          skipped.add(entry.key);
        case DailyStageOutcome.exited:
          break;
      }
    }

    if (countCompletion) {
      await _countCompletedCourseIfNeeded(
        now: now,
        games: games,
        completed: resolved,
      );
    }

    return DailyCourseData(
      dateKey: _dateKey(now),
      games: games,
      completedGames: resolved,
      successfulGames: successful,
      failedGames: failed,
      skippedGames: skipped,
      totalStars: totalStars,
      totalScore: totalScore,
    );
  }

  Future<int> loadLifetimeCompletedCount() async {
    await loadToday();
    return (await _prefs.getStringList(_countedDatesKey) ?? const <String>[])
        .length;
  }

  /// Compatibility entry point for callers that only produce successful
  /// results. New Daily Course navigation uses [recordStageResult].
  Future<DailyCourseData> recordGameCompleted(DailyCourseGameResult result) {
    return recordStageResult(
      DailyStageResult.completed(
        gameId: result.gameId,
        stars: result.stars,
        rawScore: result.score,
      ),
    );
  }

  Future<DailyCourseData> recordStageResult(
    DailyStageResult result, {
    String? expectedDateKey,
  }) async {
    final Future<DailyCourseData>? pending = _recordingFuture;
    if (pending != null) {
      await pending;
      return recordStageResult(result, expectedDateKey: expectedDateKey);
    }

    final Future<DailyCourseData> operation = _recordStageResultOnce(
      result,
      expectedDateKey: expectedDateKey,
    );
    _recordingFuture = operation;
    try {
      return await operation;
    } finally {
      if (identical(_recordingFuture, operation)) {
        _recordingFuture = null;
      }
    }
  }

  Future<DailyCourseData> _recordStageResultOnce(
    DailyStageResult result, {
    String? expectedDateKey,
  }) async {
    final DateTime now = DateTime.now();
    final String today = _dateKey(now);
    final _DailyCoursePersistedState state = await _loadStateForToday(now);

    // A level opened before midnight must never be written into tomorrow's
    // route.
    if (expectedDateKey != null && expectedDateKey != today) {
      return _dataFromState(now, state, countCompletion: true);
    }

    final List<String> games = gamesForDate(now);
    if (!result.resolvesStage ||
        !games.contains(result.gameId) ||
        state.records.containsKey(result.gameId)) {
      return _dataFromState(now, state, countCompletion: true);
    }

    final int stars = result.outcome == DailyStageOutcome.completed
        ? result.stars.clamp(0, 3).toInt()
        : 0;
    final int points = result.outcome == DailyStageOutcome.completed
        ? ZekaScoringService.dailyResultPoints(stars)
        : 0;

    final Map<String, _DailyStageRecord> nextRecords =
        Map<String, _DailyStageRecord>.from(state.records)
          ..[result.gameId] = _DailyStageRecord(
            outcome: result.outcome,
            stars: stars,
            rawScore: result.outcome == DailyStageOutcome.completed
                ? max(0, result.rawScore)
                : 0,
            points: points,
          );

    final _DailyCoursePersistedState nextState = state.copyWith(
      records: nextRecords,
    );
    await _saveState(nextState);
    return _dataFromState(now, nextState, countCompletion: true);
  }

  List<String> gamesForDate(DateTime date) {
    final int seed = date.year * 10000 + date.month * 100 + date.day;
    final List<String> shuffled = List<String>.from(gameIds)
      ..shuffle(Random(seed));
    return shuffled.take(dailyGameCount).toList(growable: false);
  }

  List<String> gamesForReplay(DateTime date, int replayRound) {
    final int normalizedRound = replayRound < 1 ? 1 : replayRound;
    final int seed = date.year * 10000 + date.month * 100 + date.day;
    final List<String> shuffled = List<String>.from(gameIds)
      ..shuffle(Random(seed));
    final int step = max(1, shuffled.length - dailyGameCount);
    final int offset = (normalizedRound * step) % shuffled.length;

    return List<String>.generate(
      dailyGameCount,
      (int index) => shuffled[(offset + index) % shuffled.length],
      growable: false,
    );
  }

  int levelForDailyCourse({
    required DateTime date,
    required String gameId,
    required int runNumber,
  }) {
    final int gameIndex = gameIds.indexOf(gameId);
    if (gameIndex < 0) {
      throw ArgumentError.value(gameId, 'gameId', 'Bilinmeyen parkur oyunu');
    }

    final int dateSeed = date.year * 10000 + date.month * 100 + date.day;
    final int normalizedRun = runNumber < 0 ? 0 : runNumber;

    return ((dateSeed + (gameIndex * 3) + (normalizedRun * 7)) %
            GameContentPolicy.campaignLevels) +
        1;
  }

  /// Stable across app restarts so leaving and returning opens the same
  /// question/puzzle layout without affecting normal game replayability.
  int layoutCodeForDailyCourse({
    required DateTime date,
    required String gameId,
    required int runNumber,
  }) {
    if (!gameIds.contains(gameId)) {
      throw ArgumentError.value(gameId, 'gameId', 'Bilinmeyen parkur oyunu');
    }
    int hash = 0x45d9f3b;
    final String source = '${_dateKey(date)}|$gameId|${max(0, runNumber)}';
    for (final int codeUnit in source.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  Future<_DailyCoursePersistedState> _loadStateForToday(DateTime now) async {
    final String today = _dateKey(now);
    final String? encoded = await _prefs.getString(_stateKey);
    if (encoded != null) {
      try {
        final Object? decoded = jsonDecode(encoded);
        if (decoded is Map<String, dynamic>) {
          final _DailyCoursePersistedState? state =
              _DailyCoursePersistedState.fromJson(decoded);
          if (state != null && state.dateKey == today) return state;
        }
      } on Object {
        // Fall through to the safe V2 migration/reset below.
      }
    }

    final _DailyCoursePersistedState state = await _migrateOrResetState(now);
    await _saveState(state);
    return state;
  }

  Future<_DailyCoursePersistedState> _migrateOrResetState(DateTime now) async {
    final String today = _dateKey(now);
    final String? legacyDate = await _prefs.getString(_dateKeyName);
    if (legacyDate != today) {
      return _DailyCoursePersistedState.empty(today);
    }

    final List<String> games = gamesForDate(now);
    final List<String> legacyCompleted =
        (await _prefs.getStringList(_completedKey) ?? const <String>[])
            .where(games.contains)
            .toSet()
            .toList(growable: false);
    final int legacyStars = await _prefs.getInt(_starsKey) ?? 0;
    final int? storedScore = await _prefs.getInt(_scoreKey);
    final int legacyScore =
        storedScore ??
        (legacyCompleted.length *
                ZekaScoringService.dailyCompletionBasePoints) +
            (legacyStars * ZekaScoringService.dailyStarPoints);

    return _DailyCoursePersistedState(
      dateKey: today,
      records: <String, _DailyStageRecord>{
        for (final String gameId in legacyCompleted)
          gameId: const _DailyStageRecord(
            outcome: DailyStageOutcome.completed,
            stars: 0,
            rawScore: 0,
            points: 0,
          ),
      },
      legacyStars: max(0, legacyStars),
      legacyScore: max(0, legacyScore),
    );
  }

  Future<void> _saveState(_DailyCoursePersistedState state) {
    return _prefs.setString(_stateKey, jsonEncode(state.toJson()));
  }

  Future<void> _countCompletedCourseIfNeeded({
    required DateTime now,
    required List<String> games,
    required Set<String> completed,
  }) async {
    final Future<void>? pending = _countingFuture;
    if (pending != null) {
      await pending;
      await _countCompletedCourseIfNeeded(
        now: now,
        games: games,
        completed: completed,
      );
      return;
    }

    final Future<void> operation = _countCompletedCourseOnce(
      now: now,
      games: games,
      completed: completed,
    );
    _countingFuture = operation;

    try {
      await operation;
    } finally {
      if (identical(_countingFuture, operation)) {
        _countingFuture = null;
      }
    }
  }

  Future<void> _countCompletedCourseOnce({
    required DateTime now,
    required List<String> games,
    required Set<String> completed,
  }) async {
    if (games.isEmpty || !games.every(completed.contains)) return;

    final String today = _dateKey(now);
    final List<String> countedDates = List<String>.from(
      await _prefs.getStringList(_countedDatesKey) ?? const <String>[],
    );

    if (countedDates.contains(today)) return;

    countedDates.add(today);
    await _prefs.setStringList(_countedDatesKey, countedDates);
  }

  String _dateKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _DailyStageRecord {
  final DailyStageOutcome outcome;
  final int stars;
  final int rawScore;
  final int points;

  const _DailyStageRecord({
    required this.outcome,
    required this.stars,
    required this.rawScore,
    required this.points,
  });

  Map<String, Object> toJson() => <String, Object>{
    'outcome': outcome.name,
    'stars': stars,
    'rawScore': rawScore,
    'points': points,
  };

  static _DailyStageRecord? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final DailyStageOutcome? outcome = switch (value['outcome']) {
      'completed' => DailyStageOutcome.completed,
      'failed' => DailyStageOutcome.failed,
      'skipped' => DailyStageOutcome.skipped,
      _ => null,
    };
    if (outcome == null) return null;
    return _DailyStageRecord(
      outcome: outcome,
      stars: ((value['stars'] as num?)?.toInt() ?? 0).clamp(0, 3).toInt(),
      rawScore: max(0, (value['rawScore'] as num?)?.toInt() ?? 0),
      points: max(0, (value['points'] as num?)?.toInt() ?? 0),
    );
  }
}

class _DailyCoursePersistedState {
  final String dateKey;
  final Map<String, _DailyStageRecord> records;
  final int legacyStars;
  final int legacyScore;

  const _DailyCoursePersistedState({
    required this.dateKey,
    required this.records,
    required this.legacyStars,
    required this.legacyScore,
  });

  factory _DailyCoursePersistedState.empty(String dateKey) {
    return _DailyCoursePersistedState(
      dateKey: dateKey,
      records: const <String, _DailyStageRecord>{},
      legacyStars: 0,
      legacyScore: 0,
    );
  }

  _DailyCoursePersistedState copyWith({
    Map<String, _DailyStageRecord>? records,
  }) {
    return _DailyCoursePersistedState(
      dateKey: dateKey,
      records: records ?? this.records,
      legacyStars: legacyStars,
      legacyScore: legacyScore,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'dateKey': dateKey,
    'records': <String, Object>{
      for (final MapEntry<String, _DailyStageRecord> entry in records.entries)
        entry.key: entry.value.toJson(),
    },
    'legacyStars': legacyStars,
    'legacyScore': legacyScore,
  };

  static _DailyCoursePersistedState? fromJson(Map<String, dynamic> json) {
    final String dateKey = json['dateKey'] as String? ?? '';
    if (dateKey.isEmpty) return null;
    final Map<String, _DailyStageRecord> records =
        <String, _DailyStageRecord>{};
    final Object? rawRecords = json['records'];
    if (rawRecords is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in rawRecords.entries) {
        final _DailyStageRecord? record = _DailyStageRecord.fromJson(
          entry.value,
        );
        if (record != null) records[entry.key] = record;
      }
    }
    return _DailyCoursePersistedState(
      dateKey: dateKey,
      records: records,
      legacyStars: max(0, (json['legacyStars'] as num?)?.toInt() ?? 0),
      legacyScore: max(0, (json['legacyScore'] as num?)?.toInt() ?? 0),
    );
  }
}
