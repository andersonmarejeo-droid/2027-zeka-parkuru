import 'dart:async';

import 'package:flutter/material.dart';

typedef DeferredGameBuilder = Widget Function();

/// Shows a painted brand frame before mounting a potentially expensive game.
///
/// This prevents Android/Flutter from exposing the route's empty background
/// while the destination game prepares its first widget tree.
Route<T> buildFastGameRoute<T>({
  required DeferredGameBuilder gameBuilder,
  required String gameTitle,
  required IconData gameIcon,
  required Color accentColor,
  bool reduceMotion = false,
  double animationScale = 1,
  RouteSettings? settings,
}) {
  final double safeAnimationScale = reduceMotion
      ? 0
      : animationScale.clamp(0.0, 1.0).toDouble();
  return PageRouteBuilder<T>(
    settings: settings,
    opaque: true,
    barrierDismissible: false,
    transitionDuration: Duration(
      milliseconds: (190 * safeAnimationScale).round(),
    ),
    reverseTransitionDuration: Duration(
      milliseconds: (150 * safeAnimationScale).round(),
    ),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _DeferredGameHost(
        gameBuilder: gameBuilder,
        gameTitle: gameTitle,
        gameIcon: gameIcon,
        accentColor: accentColor,
        animationScale: safeAnimationScale,
      );
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.018, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _DeferredGameHost extends StatefulWidget {
  const _DeferredGameHost({
    required this.gameBuilder,
    required this.gameTitle,
    required this.gameIcon,
    required this.accentColor,
    required this.animationScale,
  });

  final DeferredGameBuilder gameBuilder;
  final String gameTitle;
  final IconData gameIcon;
  final Color accentColor;
  final double animationScale;

  @override
  State<_DeferredGameHost> createState() => _DeferredGameHostState();
}

class _DeferredGameHostState extends State<_DeferredGameHost> {
  Timer? _mountTimer;
  Widget? _gamePage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Birkaç karelik kısa aralık, markalı yüzeyin mutlaka çizilmesini sağlar.
      _mountTimer = Timer(
        Duration(milliseconds: (48 * widget.animationScale).round()),
        _mountGame,
      );
    });
  }

  void _mountGame() {
    if (!mounted || _gamePage != null) return;

    final Widget page = widget.gameBuilder();
    setState(() => _gamePage = page);
  }

  @override
  void dispose() {
    _mountTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? gamePage = _gamePage;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: (120 * widget.animationScale).round()),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child:
            gamePage ??
            _GameLaunchSurface(
              key: const ValueKey<String>('zp_fast_game_launch_surface'),
              gameTitle: widget.gameTitle,
              gameIcon: widget.gameIcon,
              accentColor: widget.accentColor,
            ),
      ),
    );
  }
}

class _GameLaunchSurface extends StatelessWidget {
  const _GameLaunchSurface({
    required this.gameTitle,
    required this.gameIcon,
    required this.accentColor,
    super.key,
  });

  final String gameTitle;
  final IconData gameIcon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final bool isTurkish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'tr';

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Semantics(
              liveRegion: true,
              label: isTurkish
                  ? '$gameTitle hazırlanıyor'
                  : 'Preparing $gameTitle',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(27),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.70),
                        width: 1.6,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.24),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(gameIcon, color: accentColor, size: 44),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    gameTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTurkish ? 'PARKUR HAZIRLANIYOR' : 'PREPARING COURSE',
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.90),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
