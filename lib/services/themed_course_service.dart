import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/catalog/domain/studio_game_catalog.dart';
import 'daily_course_service.dart';
import 'zeka_scoring_service.dart';

/// A repeatable course with a deliberate game mix and difficulty band.
///
/// The daily course keeps its own date-based rules. These courses are
/// intentionally independent so a player can finish a themed run without
/// changing the daily streak or today's route.
class ThemedCourseDefinition {
  final String id;
  final String titleTr;
  final String titleEn;
  final String subtitleTr;
  final String subtitleEn;
  final String descriptionTr;
  final String descriptionEn;
  final List<String> games;
  final int minLevel;
  final int maxLevel;

  const ThemedCourseDefinition({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.subtitleTr,
    required this.subtitleEn,
    required this.descriptionTr,
    required this.descriptionEn,
    required this.games,
    required this.minLevel,
    required this.maxLevel,
  });

  List<String> get playableGames => games
      .where((g) => StudioGameCatalog.isAvailable(g) && !StudioGameCatalog.isGameRetired(g))
      .toList(growable: false);

  String title({required bool english}) => english ? titleEn : titleTr;
  String subtitle({required bool english}) =>
      english ? subtitleEn : subtitleTr;
  String description({required bool english}) =>
      english ? descriptionEn : descriptionTr;
}

abstract final class ThemedCourseCatalog {
  static const List<ThemedCourseDefinition> definitions = <ThemedCourseDefinition>[
    ThemedCourseDefinition(
      id: 'star_hunt',
      titleTr: 'Yıldız Avcısı',
      titleEn: 'Star Hunt',
      subtitleTr: 'Parlak hamlelerin peşinde',
      subtitleEn: 'Chase your brightest moves',
      descriptionTr:
          'Hafıza, dikkat ve görsel oyunları dengeli bir yıldız serisinde birleştirir.',
      descriptionEn:
          'A balanced star run combining memory, focus and visual games.',
      games: <String>[
        'memory',
        'card_pairs',
        'focus_filter',
        'rhythm_memory',
        'attention_tunnel',
        'shape_puzzle',
      ],
      minLevel: 4,
      maxLevel: 12,
    ),
    ThemedCourseDefinition(
      id: 'mind_gym',
      titleTr: 'Zihin Jimnastiği',
      titleEn: 'Mind Gym',
      subtitleTr: 'Her kas için başka bir hamle',
      subtitleEn: 'A different move for every mental muscle',
      descriptionTr:
          'Sayı, görsel, hafıza ve strateji oyunlarıyla dengeli bir antrenman yap.',
      descriptionEn:
          'Train with a balanced mix of number, visual, memory and strategy games.',
      games: <String>[
        'numbers',
        'blocks',
        'memory',
        'meaning_match',
        'number_sort',
        'shape_puzzle',
      ],
      minLevel: 6,
      maxLevel: 18,
    ),
    ThemedCourseDefinition(
      id: 'high_iq',
      titleTr: 'Yüksek IQ Parkuru',
      titleEn: 'High IQ Circuit',
      subtitleTr: 'İleri seviyede düşün, sakin ilerle',
      subtitleEn: 'Think deeper, move calmly',
      descriptionTr:
          'Oyunun daha ileri bölümlerinden seçilen, planlama ve çözüm odaklı zorlu seri.',
      descriptionEn:
          'A demanding series drawn from later levels and built around planning and solving.',
      games: <String>[
        'blocks',
        'number_sort',
        'hanoi',
        'meaning_match',
        'candy_sort',
        'attention_tunnel',
      ],
      minLevel: 13,
      maxLevel: 26,
    ),
    ThemedCourseDefinition(
      id: 'word_labyrinth',
      titleTr: 'Sözcük Labirenti',
      titleEn: 'Word Labyrinth',
      subtitleTr: 'Anlamın izini sür',
      subtitleEn: 'Follow the trail of meaning',
      descriptionTr:
          'Kelime, cümle ve dil oyunlarının bağlamlar arasında ilerleyen özel seçkisi.',
      descriptionEn:
          'A focused selection of word, sentence and language games connected by context.',
      games: <String>[
        'word_hunt',
        'meaning_match',
        'sentence_builder',
        'near_meaning',
        'letter_maze',
        'language_detective',
        'story_order',
      ],
      minLevel: 8,
      maxLevel: 22,
    ),
    ThemedCourseDefinition(
      id: 'speed_precision',
      titleTr: 'Hız ve Keskinlik',
      titleEn: 'Speed & Precision',
      subtitleTr: 'Çabuk gör, doğru seç',
      subtitleEn: 'See quickly, choose precisely',
      descriptionTr:
          'Refleks, ritim ve dikkat oyunlarıyla hızını doğrulukla buluştur.',
      descriptionEn:
          'Pair speed with accuracy through reflex, rhythm and focus games.',
      games: <String>[
        'reflex',
        'focus_filter',
        'rhythm_memory',
        'attention_tunnel',
        'numbers',
        'card_pairs',
      ],
      minLevel: 5,
      maxLevel: 16,
    ),
  ];

  static ThemedCourseDefinition byId(String id) {
    for (final ThemedCourseDefinition definition in definitions) {
      if (definition.id == id) return definition;
    }
    throw ArgumentError.value(id, 'courseId', 'Bilinmeyen tematik parkur');
  }

  static bool isPlayable(ThemedCourseDefinition definition) {
    return definition.playableGames.length >= 3;
  }
}

class ThemedCourseData {
  final ThemedCourseDefinition definition;
  final int round;
  final List<String> games;
  final Set<String> completedGames;
  final Set<String> successfulGames;
  final Set<String> failedGames;
  final Set<String> skippedGames;
  final int totalStars;
  final int totalScore;

  const ThemedCourseData({
    required this.definition,
    required this.round,
    required this.games,
    required this.completedGames,
    required this.successfulGames,
    required this.failedGames,
    required this.skippedGames,
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

class ThemedCourseService {
  ThemedCourseService._();

  static final ThemedCourseService instance = ThemedCourseService._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final Map<String, Future<ThemedCourseData>?> _recording =
      <String, Future<ThemedCourseData>?>{};

  Future<ThemedCourseData> load(String courseId) async {
    final ThemedCourseDefinition definition =
        ThemedCourseCatalog.byId(courseId);
    final _ThemedCourseState state = await _loadState(definition);
    return _dataFromState(definition, state);
  }

  Future<ThemedCourseData> startNewRound(String courseId) async {
    final ThemedCourseDefinition definition =
        ThemedCourseCatalog.byId(courseId);
    final _ThemedCourseState current = await _loadState(definition);
    final _ThemedCourseState next = _ThemedCourseState.empty(
      round: max(1, current.round + 1),
    );
    await _saveState(definition, next);
    return _dataFromState(definition, next);
  }

  Future<ThemedCourseData> recordStageResult({
    required String courseId,
    required DailyStageResult result,
  }) async {
    final Future<ThemedCourseData>? pending = _recording[courseId];
    if (pending != null) {
      await pending;
      return recordStageResult(courseId: courseId, result: result);
    }

    final Future<ThemedCourseData> operation = _recordStageResultOnce(
      courseId: courseId,
      result: result,
    );
    _recording[courseId] = operation;
    try {
      return await operation;
    } finally {
      if (identical(_recording[courseId], operation)) {
        _recording[courseId] = null;
      }
    }
  }

  Future<ThemedCourseData> _recordStageResultOnce({
    required String courseId,
    required DailyStageResult result,
  }) async {
    final ThemedCourseDefinition definition =
        ThemedCourseCatalog.byId(courseId);
    final _ThemedCourseState state = await _loadState(definition);
    if (!result.resolvesStage ||
        !definition.games.contains(result.gameId) ||
        state.records.containsKey(result.gameId)) {
      return _dataFromState(definition, state);
    }

    final int stars = result.outcome == DailyStageOutcome.completed
        ? result.stars.clamp(0, 3).toInt()
        : 0;
    final int points = result.outcome == DailyStageOutcome.completed
        ? ZekaScoringService.dailyResultPoints(stars)
        : 0;
    final Map<String, _ThemedStageRecord> records =
        Map<String, _ThemedStageRecord>.from(state.records)
          ..[result.gameId] = _ThemedStageRecord(
            outcome: result.outcome,
            stars: stars,
            rawScore: result.outcome == DailyStageOutcome.completed
                ? max(0, result.rawScore)
                : 0,
            points: points,
          );
    final _ThemedCourseState next = state.copyWith(records: records);
    await _saveState(definition, next);
    return _dataFromState(definition, next);
  }

  int levelFor({
    required String courseId,
    required String gameId,
    required int round,
  }) {
    final ThemedCourseDefinition definition =
        ThemedCourseCatalog.byId(courseId);
    if (!definition.games.contains(gameId)) {
      throw ArgumentError.value(gameId, 'gameId', 'Parkurda olmayan oyun');
    }
    final int span = max(1, definition.maxLevel - definition.minLevel + 1);
    final int hash = _stableHash('$courseId|$gameId|${max(1, round)}|level');
    return definition.minLevel + (hash % span);
  }

  int layoutCodeFor({
    required String courseId,
    required String gameId,
    required int round,
  }) {
    final ThemedCourseDefinition definition =
        ThemedCourseCatalog.byId(courseId);
    if (!definition.games.contains(gameId)) {
      throw ArgumentError.value(gameId, 'gameId', 'Parkurda olmayan oyun');
    }
    return _stableHash('$courseId|$gameId|${max(1, round)}|layout');
  }

  Future<_ThemedCourseState> _loadState(
    ThemedCourseDefinition definition,
  ) async {
    final String? encoded = await _prefs.getString(_stateKey(definition));
    if (encoded != null) {
      try {
        final Object? decoded = jsonDecode(encoded);
        if (decoded is Map<String, dynamic>) {
          final _ThemedCourseState? parsed =
              _ThemedCourseState.fromJson(decoded);
          if (parsed != null) return parsed;
        }
      } on Object {
        // A corrupt themed save is discarded safely below.
      }
    }
    final _ThemedCourseState empty = _ThemedCourseState.empty(round: 1);
    await _saveState(definition, empty);
    return empty;
  }

  Future<void> _saveState(
    ThemedCourseDefinition definition,
    _ThemedCourseState state,
  ) {
    return _prefs.setString(_stateKey(definition), jsonEncode(state.toJson()));
  }

  ThemedCourseData _dataFromState(
    ThemedCourseDefinition definition,
    _ThemedCourseState state,
  ) {
    final Set<String> completed = <String>{};
    final Set<String> successful = <String>{};
    final Set<String> failed = <String>{};
    final Set<String> skipped = <String>{};
    int totalStars = 0;
    int totalScore = 0;

    final List<String> activeGames = definition.playableGames;
    for (final String gameId in activeGames) {
      final _ThemedStageRecord? record = state.records[gameId];
      if (record == null) continue;
      completed.add(gameId);
      totalStars += record.stars;
      totalScore += record.points;
      switch (record.outcome) {
        case DailyStageOutcome.completed:
          successful.add(gameId);
        case DailyStageOutcome.failed:
          failed.add(gameId);
        case DailyStageOutcome.skipped:
          skipped.add(gameId);
        case DailyStageOutcome.exited:
          break;
      }
    }

    return ThemedCourseData(
      definition: definition,
      round: state.round,
      games: List<String>.unmodifiable(activeGames),
      completedGames: Set<String>.unmodifiable(completed),
      successfulGames: Set<String>.unmodifiable(successful),
      failedGames: Set<String>.unmodifiable(failed),
      skippedGames: Set<String>.unmodifiable(skipped),
      totalStars: totalStars,
      totalScore: totalScore,
    );
  }

  String _stateKey(ThemedCourseDefinition definition) =>
      'themed_course_v1_${definition.id}';

  int _stableHash(String source) {
    int hash = 0x45d9f3b;
    for (final int codeUnit in source.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}

class _ThemedStageRecord {
  final DailyStageOutcome outcome;
  final int stars;
  final int rawScore;
  final int points;

  const _ThemedStageRecord({
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

  static _ThemedStageRecord? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final DailyStageOutcome? outcome = switch (value['outcome']) {
      'completed' => DailyStageOutcome.completed,
      'failed' => DailyStageOutcome.failed,
      'skipped' => DailyStageOutcome.skipped,
      _ => null,
    };
    if (outcome == null) return null;
    return _ThemedStageRecord(
      outcome: outcome,
      stars: ((value['stars'] as num?)?.toInt() ?? 0).clamp(0, 3).toInt(),
      rawScore: max(0, (value['rawScore'] as num?)?.toInt() ?? 0),
      points: max(0, (value['points'] as num?)?.toInt() ?? 0),
    );
  }
}

class _ThemedCourseState {
  final int round;
  final Map<String, _ThemedStageRecord> records;

  const _ThemedCourseState({required this.round, required this.records});

  factory _ThemedCourseState.empty({required int round}) {
    return _ThemedCourseState(
      round: max(1, round),
      records: const <String, _ThemedStageRecord>{},
    );
  }

  _ThemedCourseState copyWith({Map<String, _ThemedStageRecord>? records}) {
    return _ThemedCourseState(
      round: round,
      records: records ?? this.records,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'version': 1,
    'round': round,
    'records': <String, Object>{
      for (final MapEntry<String, _ThemedStageRecord> entry in records.entries)
        entry.key: entry.value.toJson(),
    },
  };

  static _ThemedCourseState? fromJson(Map<String, dynamic> json) {
    final int round = max(1, (json['round'] as num?)?.toInt() ?? 1);
    final Map<String, _ThemedStageRecord> records =
        <String, _ThemedStageRecord>{};
    final Object? rawRecords = json['records'];
    if (rawRecords is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in rawRecords.entries) {
        final _ThemedStageRecord? record = _ThemedStageRecord.fromJson(
          entry.value,
        );
        if (record != null) records[entry.key] = record;
      }
    }
    return _ThemedCourseState(round: round, records: records);
  }
}
