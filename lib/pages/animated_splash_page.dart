import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zeka_parkuru/animated_zp_logo.dart';
import 'package:zeka_parkuru/pages/first_run_profile_page.dart';
import 'package:zeka_parkuru/services/app_analytics_service.dart';
import 'package:zeka_parkuru/services/app_error_monitoring_service.dart';
import 'package:zeka_parkuru/services/app_language_controller.dart';
import 'package:zeka_parkuru/services/firebase_bootstrap_service.dart';
import 'package:zeka_parkuru/services/game_audio_service.dart';
import 'package:zeka_parkuru/services/onboarding_preference_service.dart';
import 'package:zeka_parkuru/theme/studio_visuals.dart';

/// Native açılış ekranından sonra çalışan hareketli ZP GAMES marka ekranı.
/// Mevcut `AnimatedSplashPage(destination: AnaSayfa())` API'sini korur.
class AnimatedSplashPage extends StatefulWidget {
  const AnimatedSplashPage({required this.destination, super.key});

  final Widget destination;

  @override
  State<AnimatedSplashPage> createState() => _AnimatedSplashPageState();
}

class _AnimatedSplashPageState extends State<AnimatedSplashPage> {
  bool _transitionStarted = false;
  late final Future<bool> _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    final Completer<bool> onboarding = Completer<bool>();
    _onboardingCompleted = onboarding.future;
    // İlk Flutter karesi hazır olduktan sonra yalnızca yerel tercihleri oku.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadOnboardingState().then(onboarding.complete));
      unawaited(_loadLanguage());
    });
  }

  Future<void> _loadLanguage() async {
    try {
      await AppLanguageController.instance.init();
    } catch (error) {
      debugPrint('Startup language preference skipped: $error');
    }
  }

  Future<bool> _loadOnboardingState() async {
    try {
      return await OnboardingPreferenceService.instance.isComplete().timeout(
        const Duration(seconds: 2),
      );
    } on TimeoutException {
      debugPrint('Onboarding preference read timed out.');
      return false;
    } catch (error, stackTrace) {
      debugPrint('Onboarding preference read skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _initializeServices() async {
    final Future<void> firebaseInitialization = FirebaseBootstrapService
        .instance
        .initialize();

    unawaited(() async {
      try {
        await firebaseInitialization;
        await AppErrorMonitoringService.instance.initialize();
      } catch (_) {
        // Ana başlangıç akışı aşağıda hatayı güvenli biçimde ele alır.
      }
    }());

    try {
      await Future.wait<void>(<Future<void>>[
        GameAudioService.instance.init(),
        firebaseInitialization,
      ]).timeout(const Duration(seconds: 4));

      unawaited(AppAnalyticsService.instance.logAppOpen());
    } on TimeoutException {
      debugPrint('Startup services continued in the background.');
    } catch (error, stackTrace) {
      debugPrint('Startup service skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openDestination() async {
    if (_transitionStarted || !mounted) return;
    _transitionStarted = true;

    final bool onboardingCompleted = await _onboardingCompleted;
    if (!mounted) return;

    final Widget target = onboardingCompleted
        ? widget.destination
        : FirstRunProfilePage(destination: widget.destination);

    // Ağ ve ses ön yüklemesi marka animasyonu ile sayfa geçişini bölmesin.
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 350))
          .then((_) => _initializeServices()),
    );

    await Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return target;
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: StudioVisuals.canvas,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: StudioVisuals.canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: StudioVisuals.canvas,
          body: RepaintBoundary(
            child: AnimatedZpLogo(onCompleted: _openDestination),
          ),
        ),
      ),
    );
  }
}
