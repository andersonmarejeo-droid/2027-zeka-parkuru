import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ReaderProgressStore {
  ReaderProgressStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String storageKey = 'mind_tool_reader_completed_v1';
  static const String reviewStorageKey = 'mind_tool_reader_review_v1';
  final SharedPreferencesAsync _preferences;

  Future<Set<String>> completedStoryIds() async {
    final String? raw = await _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return <String>{};
    final Object? value = jsonDecode(raw);
    if (value is! List<Object?>) {
      throw const FormatException('Reader progress must be a list.');
    }
    final Set<String> ids = value.whereType<String>().toSet();
    return ids;
  }

  Future<void> markCompleted(String storyId, {DateTime? now}) async {
    if (storyId.trim().isEmpty) throw ArgumentError('Story id is required.');
    final Set<String> ids = await completedStoryIds();
    if (ids.add(storyId)) {
      final List<String> sorted = ids.toList()..sort();
      await _preferences.setString(storageKey, jsonEncode(sorted));
    }
    final Map<String, ReaderReviewSchedule> schedules = await reviewSchedules();
    if (schedules.containsKey(storyId)) return;
    final DateTime completedAt = now ?? DateTime.now();
    schedules[storyId] = ReaderReviewSchedule(
      storyId: storyId,
      dueAt: completedAt.add(const Duration(days: 1)),
      intervalDays: 1,
      reviewCount: 0,
    );
    await _saveSchedules(schedules);
  }

  Future<Map<String, ReaderReviewSchedule>> reviewSchedules() async {
    final String? raw = await _preferences.getString(reviewStorageKey);
    if (raw == null || raw.isEmpty) return <String, ReaderReviewSchedule>{};
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Reader review schedule must be a map.');
    }
    final Map<String, ReaderReviewSchedule> schedules =
        <String, ReaderReviewSchedule>{};
    for (final MapEntry<String, Object?> entry in decoded.entries) {
      if (entry.value is! Map<String, Object?>) {
        throw const FormatException('Invalid reader review schedule.');
      }
      final ReaderReviewSchedule schedule = ReaderReviewSchedule.fromJson(
        entry.value! as Map<String, Object?>,
      );
      if (schedule.storyId != entry.key) {
        throw const FormatException('Reader review key does not match story.');
      }
      schedules[entry.key] = schedule;
    }
    return schedules;
  }

  Future<Map<String, ReaderReviewSchedule>> ensureReviewSchedulesFor(
    Iterable<String> completedStoryIds, {
    DateTime? now,
  }) async {
    final Map<String, ReaderReviewSchedule> schedules = await reviewSchedules();
    final DateTime firstReviewAt = now ?? DateTime.now();
    bool changed = false;
    for (final String storyId in completedStoryIds) {
      if (storyId.trim().isEmpty || schedules.containsKey(storyId)) continue;
      schedules[storyId] = ReaderReviewSchedule(
        storyId: storyId,
        dueAt: firstReviewAt,
        intervalDays: 1,
        reviewCount: 0,
      );
      changed = true;
    }
    if (changed) await _saveSchedules(schedules);
    return schedules;
  }

  Future<List<ReaderReviewSchedule>> dueReviews({DateTime? now}) async {
    final DateTime at = now ?? DateTime.now();
    final List<ReaderReviewSchedule> due = (await reviewSchedules()).values
        .where((ReaderReviewSchedule review) => !review.dueAt.isAfter(at))
        .toList(growable: false);
    return due;
  }

  Future<ReaderReviewSchedule> recordReview({
    required String storyId,
    required bool rememberedAll,
    DateTime? now,
  }) async {
    final Map<String, ReaderReviewSchedule> schedules = await reviewSchedules();
    final ReaderReviewSchedule? previous = schedules[storyId];
    if (previous == null) {
      throw StateError('Story has no scheduled recall review.');
    }
    final int nextInterval = rememberedAll
        ? (previous.intervalDays < 3
              ? 3
              : (previous.intervalDays * 2).clamp(1, 30).toInt())
        : 1;
    final ReaderReviewSchedule next = ReaderReviewSchedule(
      storyId: storyId,
      dueAt: (now ?? DateTime.now()).add(Duration(days: nextInterval)),
      intervalDays: nextInterval,
      reviewCount: previous.reviewCount + 1,
    );
    schedules[storyId] = next;
    await _saveSchedules(schedules);
    return next;
  }

  Future<void> _saveSchedules(
    Map<String, ReaderReviewSchedule> schedules,
  ) async {
    final Map<String, Object?> json = <String, Object?>{
      for (final MapEntry<String, ReaderReviewSchedule> entry
          in schedules.entries)
        entry.key: entry.value.toJson(),
    };
    await _preferences.setString(reviewStorageKey, jsonEncode(json));
  }
}

class ReaderReviewSchedule {
  const ReaderReviewSchedule({
    required this.storyId,
    required this.dueAt,
    required this.intervalDays,
    required this.reviewCount,
  });

  final String storyId;
  final DateTime dueAt;
  final int intervalDays;
  final int reviewCount;

  Map<String, Object?> toJson() => <String, Object?>{
    'storyId': storyId,
    'dueAt': dueAt.toIso8601String(),
    'intervalDays': intervalDays,
    'reviewCount': reviewCount,
  };

  factory ReaderReviewSchedule.fromJson(Map<String, Object?> json) {
    final String id = json['storyId'] as String? ?? '';
    final Object? rawDueAt = json['dueAt'];
    final int interval = json['intervalDays'] as int? ?? 0;
    final int reviews = json['reviewCount'] as int? ?? -1;
    if (id.isEmpty ||
        rawDueAt is! String ||
        interval < 1 ||
        interval > 30 ||
        reviews < 0) {
      throw const FormatException('Invalid reader review entry.');
    }
    return ReaderReviewSchedule(
      storyId: id,
      dueAt: DateTime.parse(rawDueAt),
      intervalDays: interval,
      reviewCount: reviews,
    );
  }
}
