import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ZpBrandIntroPage extends StatefulWidget {
  const ZpBrandIntroPage({required this.nextPage, super.key});

  final Widget nextPage;

  @override
  State<ZpBrandIntroPage> createState() => _ZpBrandIntroPageState();
}

class _ZpBrandIntroPageState extends State<ZpBrandIntroPage> {
  bool _transitionStarted = false;

  void _openNextPage() {
    if (_transitionStarted || !mounted) return;
    _transitionStarted = true;

    Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) {
          return widget.nextPage;
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
    return Scaffold(
      backgroundColor: const Color(0xFF000322),
      body: AnimatedZpLogo(onCompleted: _openNextPage),
    );
  }
}

/// ZP GAMES açılış animasyonu.
///
/// Akış:
/// 1. İlk Flutter karesinde logo hemen görünür; boş siyah kare oluşmaz.
/// 2. 0.2 saniye sonra turuncu beyin iki güçlü ışık nabzı verir.
/// 3. Kafa yukarı kayarken ZP GAMES yazısı Z harfinden sağa doğru açılır.
class AnimatedZpLogo extends StatefulWidget {
  const AnimatedZpLogo({
    super.key,
    this.onCompleted,
    this.duration = const Duration(milliseconds: 1650),
    this.backgroundColor = const Color(0xFF000322),
    this.maximumLogoSize = 420,
  });

  final VoidCallback? onCompleted;
  final Duration duration;
  final Color backgroundColor;
  final double maximumLogoSize;

  @override
  State<AnimatedZpLogo> createState() => _AnimatedZpLogoState();
}

class _AnimatedZpLogoState extends State<AnimatedZpLogo>
    with SingleTickerProviderStateMixin {
  static const String _brandText = 'ZP GAMES';
  static const String _baseAsset = 'assets/branding/zp_icon_dim.png';
  static const String _brainAsset = 'assets/branding/zp_brain_glow.png';
  static const Color _orange = Color(0xFFFF7200);

  late final AnimationController _controller;
  late final Animation<double> _entrance;
  late final Animation<double> _logoLift;
  late final Animation<double> _logoScale;
  late final Animation<double> _brainPulse;
  late final Animation<double> _textReveal;
  late final Animation<double> _textGlow;

  bool _startScheduled = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _entrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.14, curve: Curves.easeOutCubic),
    );

    _logoLift = Tween<double>(begin: 0.055, end: -0.055).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.52, curve: Curves.easeInOutCubic),
      ),
    );

    _logoScale =
        TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(
              begin: 0.94,
              end: 1.015,
            ).chain(CurveTween(curve: Curves.easeOutBack)),
            weight: 52,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(
              begin: 1.015,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 48,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.00, 0.60),
          ),
        );

    _brainPulse =
        TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: ConstantTween<double>(0.18),
            weight: 14,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(
              begin: 0.18,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 15,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(
              begin: 1.0,
              end: 0.16,
            ).chain(CurveTween(curve: Curves.easeInCubic)),
            weight: 13,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(
              begin: 0.16,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 15,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(
              begin: 1.0,
              end: 0.58,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 18,
          ),
          TweenSequenceItem<double>(
            tween: ConstantTween<double>(0.58),
            weight: 25,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.05, 0.78),
          ),
        );

    _textReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.38, 0.77, curve: Curves.easeOutCubic),
    );

    _textGlow = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.86, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startScheduled) return;
    _startScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_precacheAndStart());
    });
  }

  Future<void> _precacheAndStart() async {
    try {
      await Future.wait<void>(<Future<void>>[
        precacheImage(const AssetImage(_baseAsset), context),
        precacheImage(const AssetImage(_brainAsset), context),
      ]).timeout(const Duration(seconds: 2));
    } catch (_) {
      // Varlık hatası Flutter tarafından ayrıca raporlanır; animasyon beklemez.
    }

    if (!mounted) return;

    // İlk statik kareyi kesin olarak çizdikten sonra zaman çizgisini başlat.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.duration = const Duration(milliseconds: 700);
    }
    await _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double availableWidth = constraints.maxWidth * 0.86;
            final double availableHeight = constraints.maxHeight * 0.57;
            final double logoSize = math
                .min(
                  widget.maximumLogoSize,
                  math.min(availableWidth, availableHeight),
                )
                .toDouble();

            return Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  final double visibleOpacity = 0.42 + (_entrance.value * 0.58);
                  final double pulseScale = 0.985 + (_brainPulse.value * 0.025);
                  final int visibleCharacterCount = math
                      .min(
                        _brandText.length,
                        (_textReveal.value * _brandText.length).ceil(),
                      )
                      .toInt();
                  final String visibleText = _brandText.substring(
                    0,
                    visibleCharacterCount,
                  );

                  return Transform.translate(
                    offset: Offset(0, logoSize * _logoLift.value),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Opacity(
                          opacity: visibleOpacity,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: SizedBox.square(
                              dimension: logoSize,
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  Image.asset(
                                    _baseAsset,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                  Transform.scale(
                                    scale: pulseScale,
                                    child: ImageFiltered(
                                      imageFilter: ui.ImageFilter.blur(
                                        sigmaX: 2 + (_brainPulse.value * 12),
                                        sigmaY: 2 + (_brainPulse.value * 12),
                                      ),
                                      child: Opacity(
                                        opacity: _brainPulse.value * 0.58,
                                        child: Image.asset(
                                          _brainAsset,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: pulseScale,
                                    child: Opacity(
                                      opacity:
                                          0.10 + (_brainPulse.value * 0.90),
                                      child: Image.asset(
                                        _brainAsset,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: logoSize * 0.025),
                        SizedBox(
                          width: logoSize * 0.86,
                          height: logoSize * 0.17,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Transform.scale(
                              alignment: Alignment.centerLeft,
                              scaleX: 0.72 + (_textReveal.value * 0.28),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  visibleText,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: _orange,
                                    fontSize: 64,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    shadows: <Shadow>[
                                      Shadow(
                                        color: Color.fromRGBO(
                                          255,
                                          114,
                                          0,
                                          0.42 + (_textGlow.value * 0.38),
                                        ),
                                        blurRadius: 8 + (_textGlow.value * 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
