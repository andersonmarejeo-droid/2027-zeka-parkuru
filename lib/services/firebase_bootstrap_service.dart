import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'firebase_reachability.dart';

class FirebaseBootstrapService {
  FirebaseBootstrapService._();

  static final FirebaseBootstrapService instance =
      FirebaseBootstrapService._();

  // A locally sideloaded release APK cannot obtain a production Play
  // Integrity verdict. Keep production builds on Play Integrity by default,
  // while allowing an explicitly opted-in QA build to use the Firebase debug
  // provider after its debug token has been registered in the Console.
  static const bool _useDebugAppCheck = bool.fromEnvironment(
    'FIREBASE_APP_CHECK_DEBUG',
    defaultValue: false,
  );

  bool _ready = false;
  bool _configured = false;
  bool _appCheckActivated = false;
  String? _lastError;
  Future<void>? _initializationFuture;
  DateTime? _automaticRetryAfter;

  bool get ready => _ready;
  bool get configured => _configured;
  String? get lastError => _lastError;

  String? get uid =>
      _ready ? FirebaseAuth.instance.currentUser?.uid : null;

  Future<void> initialize({bool forceRetry = false}) {
    if (_ready) return Future<void>.value();

    final Future<void>? active = _initializationFuture;
    if (active != null) return active;

    final DateTime? retryAfter = _automaticRetryAfter;
    if (!forceRetry &&
        retryAfter != null &&
        DateTime.now().isBefore(retryAfter)) {
      return Future<void>.value();
    }

    final Future<void> operation = _initializeOnce();
    _initializationFuture = operation;

    return operation.whenComplete(() {
      if (identical(_initializationFuture, operation)) {
        _initializationFuture = null;
      }
    });
  }

  Future<void> _initializeOnce() async {
    _ready = false;
    _lastError = null;

    try {
      final FirebaseOptions options =
          DefaultFirebaseOptions.currentPlatform;

      final bool hasDartDefineOptions =
          options.apiKey.trim().isNotEmpty &&
          options.appId.trim().isNotEmpty &&
          options.projectId.trim().isNotEmpty &&
          options.messagingSenderId.trim().isNotEmpty;

      if (Firebase.apps.isEmpty) {
        if (hasDartDefineOptions) {
          await Firebase.initializeApp(options: options);
        } else if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android) {
          // Android'de google-services.json dosyası Gradle tarafından yerel
          // kaynaklara dönüştürülür. Normal flutter run / release kurulumunda
          // ayrıca --dart-define istemeden bu yapılandırmayı kullan.
          await Firebase.initializeApp();
        } else {
          _lastError =
              'Firebase yapılandırması bulunamadı. flutterfire configure çalıştır.';
          _deferAutomaticRetry(const Duration(minutes: 5));
          return;
        }
      }

      _configured = Firebase.apps.isNotEmpty;

      if (!await canResolveFirebaseServices()) {
        _lastError = 'Firebase sunucularının adresi çözümlenemiyor. '
            'İnterneti, Özel DNS ayarını, VPN veya reklam engelleyiciyi '
            'kontrol edip tekrar dene.';
        _deferAutomaticRetry(const Duration(seconds: 20));
        return;
      }

      // App Check: development builds use the Debug provider. Release Android
      // builds use Play Integrity unless the caller explicitly opts into a
      // registered debug token for a locally sideloaded QA build. Never set
      // FIREBASE_APP_CHECK_DEBUG for a Play-distributed production artifact.
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android) {
        try {
          if (!_appCheckActivated) {
            await FirebaseAppCheck.instance.activate(
              providerAndroid: (kDebugMode || _useDebugAppCheck)
                  ? const AndroidDebugProvider()
                  : const AndroidPlayIntegrityProvider(),
            );
            _appCheckActivated = true;
          }
        } catch (error) {
          _lastError = 'App Check doğrulaması başlatılamadı. İnternet veya '
              'Google Play bağlantısını kontrol edip tekrar dene.';
          _deferAutomaticRetry(const Duration(seconds: 20));
          debugPrint('Firebase App Check unavailable: $error');
          return;
        }
      }

      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      await FirebaseAnalytics.instance
          .setAnalyticsCollectionEnabled(true);

      _ready = FirebaseAuth.instance.currentUser != null;
      _automaticRetryAfter = null;
      _lastError = null;
    } catch (error, stackTrace) {
      _ready = false;
      _lastError = 'Firebase bağlantısı kurulamadı. İnternet ve proje '
          'yapılandırmasını kontrol edip tekrar dene.';
      _deferAutomaticRetry(const Duration(seconds: 20));

      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _deferAutomaticRetry(Duration delay) {
    _automaticRetryAfter = DateTime.now().add(delay);
  }
}
