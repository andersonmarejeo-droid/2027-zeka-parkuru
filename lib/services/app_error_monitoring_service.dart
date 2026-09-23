import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap_service.dart';

class AppErrorMonitoringService {
  AppErrorMonitoringService._();

  static final AppErrorMonitoringService instance =
      AppErrorMonitoringService._();

  static const int _maximumPendingReports = 8;

  final List<_PendingErrorReport> _pendingReports =
      <_PendingErrorReport>[];

  Future<void>? _initializationFuture;
  Timer? _retryTimer;
  bool _handlersInstalled = false;
  bool _enabled = false;
  String _lastArea = 'startup';

  FirebaseCrashlytics get _crashlytics =>
      FirebaseCrashlytics.instance;

  void installGlobalHandlers() {
    if (_handlersInstalled) return;
    _handlersInstalled = true;

    final FlutterExceptionHandler? previousFlutterHandler =
        FlutterError.onError;
    final bool Function(Object, StackTrace)? previousPlatformHandler =
        PlatformDispatcher.instance.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        if (previousFlutterHandler != null) {
          previousFlutterHandler(details);
        } else {
          FlutterError.presentError(details);
        }
      }

      unawaited(recordFlutterFatalError(details));
    };

    PlatformDispatcher.instance.onError = (
      Object error,
      StackTrace stackTrace,
    ) {
      unawaited(
        recordError(
          error,
          stackTrace,
          fatal: true,
          reason: 'uncaught_async_error',
        ),
      );

      if (kDebugMode) {
        return previousPlatformHandler?.call(
              error,
              stackTrace,
            ) ??
            false;
      }

      return true;
    };
  }

  Future<void> initialize() {
    final Future<void>? active = _initializationFuture;
    if (active != null) return active;

    final Future<void> operation = _initializeOnce();
    _initializationFuture = operation;

    return operation.whenComplete(() {
      if (identical(_initializationFuture, operation)) {
        _initializationFuture = null;
      }
    });
  }

  Future<void> _initializeOnce() async {
    if (kDebugMode) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _pendingReports.clear();
      _enabled = false;
      return;
    }

    final FirebaseBootstrapService firebase =
        FirebaseBootstrapService.instance;

    if (!firebase.ready) {
      if (firebase.configured) _scheduleInitializationRetry();
      return;
    }

    _retryTimer?.cancel();
    _retryTimer = null;

    try {
      // Development errors stay on the developer console. Only release builds
      // send real-player reports, so test sessions do not pollute production.
      await _crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);
      _enabled = kReleaseMode;

      if (!_enabled) {
        _pendingReports.clear();
        return;
      }

      // Player names and Firebase UIDs are deliberately not attached.
      await _crashlytics.setUserIdentifier('');
      await _crashlytics.setCustomKey('last_area', _lastArea);
      await _crashlytics.setCustomKey(
        'previous_run_crashed',
        await _crashlytics.didCrashOnPreviousExecution(),
      );

      final List<_PendingErrorReport> pending =
          List<_PendingErrorReport>.from(_pendingReports);
      _pendingReports.clear();

      for (final _PendingErrorReport report in pending) {
        await _sendReport(report);
      }
    } catch (error) {
      _enabled = false;
      debugPrint('Crash reporting initialization skipped: $error');
    }
  }

  void _scheduleInitializationRetry() {
    if (_retryTimer?.isActive == true) return;

    _retryTimer = Timer(const Duration(seconds: 20), () async {
      _retryTimer = null;
      await FirebaseBootstrapService.instance.initialize();
      await initialize();
    });
  }

  Future<void> setArea(String value) async {
    _lastArea = _safeContextValue(value);
    if (!_enabled) return;

    try {
      await _crashlytics.setCustomKey('last_area', _lastArea);
      await _crashlytics.log('area:$_lastArea');
    } catch (error) {
      debugPrint('Crash reporting area update skipped: $error');
    }
  }

  Future<void> setPlayerContext({
    required String levelGroup,
    required String league,
    required String language,
  }) async {
    if (!_enabled) return;

    try {
      await Future.wait<void>(<Future<void>>[
        _crashlytics.setCustomKey(
          'player_level_group',
          _safeContextValue(levelGroup),
        ),
        _crashlytics.setCustomKey(
          'league',
          _safeContextValue(league),
        ),
        _crashlytics.setCustomKey(
          'app_language',
          _safeContextValue(language),
        ),
      ]);
    } catch (error) {
      debugPrint('Crash reporting player context skipped: $error');
    }
  }

  Future<void> logEvent(String value) async {
    if (!_enabled) return;

    try {
      await _crashlytics.log(_safeContextValue(value));
    } catch (error) {
      debugPrint('Crash reporting breadcrumb skipped: $error');
    }
  }

  Future<void> recordFlutterFatalError(
    FlutterErrorDetails details,
  ) async {
    final _PendingErrorReport report = _PendingErrorReport(
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
      fatal: true,
      reason: 'flutter_framework_error',
    );

    if (!_enabled) {
      _enqueueIfNeeded(report);
      return;
    }

    try {
      await _crashlytics.recordFlutterFatalError(details);
    } catch (error) {
      debugPrint('Flutter fatal report skipped: $error');
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
    required String reason,
  }) async {
    final _PendingErrorReport report = _PendingErrorReport(
      error: error,
      stackTrace: stackTrace,
      fatal: fatal,
      reason: _safeContextValue(reason),
    );

    if (!_enabled) {
      _enqueueIfNeeded(report);
      return;
    }

    await _sendReport(report);
  }

  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String area,
  }) async {
    await setArea(area);
    await recordError(
      error,
      stackTrace,
      fatal: false,
      reason: 'handled_non_fatal_error',
    );
  }

  void _enqueueIfNeeded(_PendingErrorReport report) {
    if (!kReleaseMode) return;

    if (_pendingReports.length >= _maximumPendingReports) {
      _pendingReports.removeAt(0);
    }
    _pendingReports.add(report);
  }

  Future<void> _sendReport(_PendingErrorReport report) async {
    try {
      await _crashlytics.recordError(
        report.error,
        report.stackTrace,
        fatal: report.fatal,
        reason: report.reason,
      );
    } catch (error) {
      debugPrint('Crash report skipped: $error');
    }
  }

  String _safeContextValue(String value) {
    final String safe = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (safe.isEmpty) return 'unknown';
    return safe.length > 40 ? safe.substring(0, 40) : safe;
  }
}

class _PendingErrorReport {
  final Object error;
  final StackTrace stackTrace;
  final bool fatal;
  final String reason;

  const _PendingErrorReport({
    required this.error,
    required this.stackTrace,
    required this.fatal,
    required this.reason,
  });
}
