import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'app_error_monitoring_service.dart';
import 'firebase_bootstrap_service.dart';

class AppAnalyticsService {
  AppAnalyticsService._();

  static final AppAnalyticsService instance =
      AppAnalyticsService._();

  FirebaseAnalytics get _analytics =>
      FirebaseAnalytics.instance;

  AppErrorMonitoringService get _errors =>
      AppErrorMonitoringService.instance;

  bool get _enabled =>
      FirebaseBootstrapService.instance.ready;

  Future<void> logAppOpen() async {
    if (!_enabled) return;

    try {
      await _analytics.logAppOpen();
    } catch (error) {
      debugPrint('Analytics app_open skipped: $error');
    }
  }

  Future<void> logScreen(String screenName) async {
    unawaited(_errors.setArea('screen_$screenName'));
    if (!_enabled) return;

    try {
      await _analytics.logScreenView(
        screenName: screenName,
      );
    } catch (error) {
      debugPrint('Analytics screen skipped: $error');
    }
  }

  Future<void> logGameOpen(String gameId) async {
    unawaited(_errors.setArea('game_$gameId'));
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'game_open',
        parameters: <String, Object>{
          'game_id': gameId,
        },
      );
    } catch (error) {
      debugPrint('Analytics game_open skipped: $error');
    }
  }

  Future<void> logLevelComplete({
    required String gameId,
    required int stars,
    required int score,
    required int dailyTasksCompleted,
    required int streak,
  }) async {
    unawaited(_errors.logEvent('level_complete_$gameId'));
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'level_complete',
        parameters: <String, Object>{
          'game_id': gameId,
          'stars': stars,
          'score': score,
          'daily_tasks': dailyTasksCompleted,
          'streak': streak,
        },
      );
    } catch (error) {
      debugPrint('Analytics level_complete skipped: $error');
    }
  }

  Future<void> logLanguageChange(String language) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'language_change',
        parameters: <String, Object>{
          'language': language,
        },
      );
    } catch (error) {
      debugPrint('Analytics language_change skipped: $error');
    }
  }

  Future<void> logProfileEdit() async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'profile_edit',
      );
    } catch (error) {
      debugPrint('Analytics profile_edit skipped: $error');
    }
  }

  Future<void> setPlayerProperties({
    required int level,
    required String league,
    required String language,
  }) async {
    unawaited(
      _errors.setPlayerContext(
        levelGroup: _levelGroup(level),
        league: league,
        language: language,
      ),
    );
    if (!_enabled) return;

    try {
      await _analytics.setUserProperty(
        name: 'player_level_group',
        value: _levelGroup(level),
      );

      await _analytics.setUserProperty(
        name: 'league',
        value: league.toLowerCase(),
      );

      await _analytics.setUserProperty(
        name: 'app_language',
        value: language,
      );
    } catch (error) {
      debugPrint('Analytics user properties skipped: $error');
    }
  }

  String _levelGroup(int level) {
    if (level >= 40) return '40_50';
    if (level >= 30) return '30_39';
    if (level >= 20) return '20_29';
    if (level >= 10) return '10_19';
    return '1_9';
  }
}
