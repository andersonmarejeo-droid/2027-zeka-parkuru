import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArenaRunCheckpoint {
  final String eventId;
  final String playerUid;
  final String parkourFingerprint;
  final int nextStationIndex;
  final int totalPoints;
  final int totalStars;
  final int failedStages;
  final int skippedStages;

  const ArenaRunCheckpoint({
    required this.eventId,
    required this.playerUid,
    required this.parkourFingerprint,
    required this.nextStationIndex,
    required this.totalPoints,
    required this.totalStars,
    required this.failedStages,
    required this.skippedStages,
  });

  factory ArenaRunCheckpoint.fresh({
    required String eventId,
    required String playerUid,
    required String parkourFingerprint,
  }) {
    return ArenaRunCheckpoint(
      eventId: eventId,
      playerUid: playerUid,
      parkourFingerprint: parkourFingerprint,
      nextStationIndex: 0,
      totalPoints: 0,
      totalStars: 0,
      failedStages: 0,
      skippedStages: 0,
    );
  }

  ArenaRunCheckpoint copyWith({
    int? nextStationIndex,
    int? totalPoints,
    int? totalStars,
    int? failedStages,
    int? skippedStages,
  }) {
    return ArenaRunCheckpoint(
      eventId: eventId,
      playerUid: playerUid,
      parkourFingerprint: parkourFingerprint,
      nextStationIndex: nextStationIndex ?? this.nextStationIndex,
      totalPoints: totalPoints ?? this.totalPoints,
      totalStars: totalStars ?? this.totalStars,
      failedStages: failedStages ?? this.failedStages,
      skippedStages: skippedStages ?? this.skippedStages,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': 1,
    'eventId': eventId,
    'playerUid': playerUid,
    'parkourFingerprint': parkourFingerprint,
    'nextStationIndex': nextStationIndex,
    'totalPoints': totalPoints,
    'totalStars': totalStars,
    'failedStages': failedStages,
    'skippedStages': skippedStages,
  };

  static ArenaRunCheckpoint? tryParse(String source) {
    try {
      final dynamic decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
        return null;
      }

      int safeInt(String key, int max) {
        final dynamic value = decoded[key];
        if (value is! num) return 0;
        return value.toInt().clamp(0, max).toInt();
      }

      final String eventId = decoded['eventId'] is String
          ? decoded['eventId'] as String
          : '';
      final String playerUid = decoded['playerUid'] is String
          ? decoded['playerUid'] as String
          : '';
      final String fingerprint = decoded['parkourFingerprint'] is String
          ? decoded['parkourFingerprint'] as String
          : '';

      if (eventId.isEmpty || playerUid.isEmpty || fingerprint.isEmpty) {
        return null;
      }

      return ArenaRunCheckpoint(
        eventId: eventId,
        playerUid: playerUid,
        parkourFingerprint: fingerprint,
        nextStationIndex: safeInt('nextStationIndex', 30),
        totalPoints: safeInt('totalPoints', 30000),
        totalStars: safeInt('totalStars', 90),
        failedStages: safeInt('failedStages', 30),
        skippedStages: safeInt('skippedStages', 30),
      );
    } catch (_) {
      return null;
    }
  }
}

class ArenaRunProgressService {
  ArenaRunProgressService._();

  static final ArenaRunProgressService instance = ArenaRunProgressService._();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _key(String eventId, String playerUid) =>
      'arena_run_v2_${playerUid}_$eventId';

  Future<ArenaRunCheckpoint> loadOrCreate({
    required String eventId,
    required String playerUid,
    required String parkourFingerprint,
    required int stationCount,
    required int authoritativeNextStationIndex,
    required int authoritativeTotalPoints,
    required int authoritativeTotalStars,
    required int authoritativeFailedStages,
    required int authoritativeSkippedStages,
  }) async {
    final String key = _key(eventId, playerUid);
    final String? encoded = await _preferences.getString(key);
    ArenaRunCheckpoint? local;

    if (encoded != null) {
      local = ArenaRunCheckpoint.tryParse(encoded);
      final bool valid =
          local != null &&
          local.eventId == eventId &&
          local.playerUid == playerUid &&
          local.parkourFingerprint == parkourFingerprint &&
          local.nextStationIndex <= stationCount;
      if (!valid) {
        local = null;
        await _preferences.remove(key);
      }
    }

    final ArenaRunCheckpoint authoritative = ArenaRunCheckpoint(
      eventId: eventId,
      playerUid: playerUid,
      parkourFingerprint: parkourFingerprint,
      nextStationIndex: authoritativeNextStationIndex
          .clamp(0, stationCount)
          .toInt(),
      totalPoints: authoritativeTotalPoints.clamp(0, 30000).toInt(),
      totalStars: authoritativeTotalStars.clamp(0, 90).toInt(),
      failedStages: authoritativeFailedStages.clamp(0, stationCount).toInt(),
      skippedStages: authoritativeSkippedStages.clamp(0, stationCount).toInt(),
    );

    final ArenaRunCheckpoint selected;
    if (local == null ||
        authoritative.nextStationIndex > local.nextStationIndex) {
      selected = authoritative;
    } else if (local.nextStationIndex > authoritative.nextStationIndex) {
      selected = local;
    } else {
      selected = local.copyWith(
        totalPoints: local.totalPoints > authoritative.totalPoints
            ? local.totalPoints
            : authoritative.totalPoints,
        totalStars: local.totalStars > authoritative.totalStars
            ? local.totalStars
            : authoritative.totalStars,
        failedStages: local.failedStages > authoritative.failedStages
            ? local.failedStages
            : authoritative.failedStages,
        skippedStages: local.skippedStages > authoritative.skippedStages
            ? local.skippedStages
            : authoritative.skippedStages,
      );
    }

    await save(selected);
    return selected;
  }

  Future<void> save(ArenaRunCheckpoint checkpoint) async {
    await _preferences.setString(
      _key(checkpoint.eventId, checkpoint.playerUid),
      jsonEncode(checkpoint.toJson()),
    );
  }

  Future<void> clear({
    required String eventId,
    required String playerUid,
  }) async {
    try {
      await _preferences.remove(_key(eventId, playerUid));
    } catch (error, stackTrace) {
      debugPrint('Arena run checkpoint clear failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
