import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zeka_parkuru/theme/studio_visuals.dart';

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
      backgroundColor: StudioVisuals.canvas,
      body: AnimatedZpLogo(onCompleted: _openNextPage),
    );
  }
}

/// Zekâ Parkuru için sakin, dokunsal 3B açılış animasyonu.
///
/// Akış:
/// 1. İlk Flutter karesinde 3B puzzle nesnesi görünür; boş siyah kare oluşmaz.
/// 2. Nesne native açılıştaki boyutundan yumuşakça büyür ve yukarı yerleşir.
/// 3. Önce ZEKÂ PARKURU, ardından küçük ZP GAMES metni belirir.
class AnimatedZpLogo extends StatefulWidget {
  const AnimatedZpLogo({
    super.key,
    this.onCompleted,
    this.duration = const Duration(milliseconds: 1400),
    this.backgroundColor = StudioVisuals.canvas,
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
  static const String _heroAsset =
      'assets/branding/studio_daily_puzzle_hero.png';

  late final AnimationController _controller;
  late final Animation<double> _logoLift;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleReveal;
  late final Animation<double> _studioReveal;
  late final Animation<Offset> _titleSlide;
  late final Animation<Offset> _studioSlide;

  bool _startScheduled = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _logoLift = Tween<double>(begin: 0.13, end: -0.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.02, 0.56, curve: Curves.easeInOutCubic),
      ),
    );

    _logoScale = Tween<double>(begin: 0.48, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _titleReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.16, 0.72, curve: Curves.easeInOutCubic),
    );

    _studioReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.31, 0.88, curve: Curves.easeInOutCubic),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(_titleReveal);
    _studioSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(_studioReveal);

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });
  }

  void _startAfterImageFrame() {
    if (_startScheduled) return;
    _startScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _controller.duration = const Duration(milliseconds: 700);
      }
      unawaited(_controller.forward(from: 0));
    });
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
                animation: _logoLift,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ScaleTransition(
                      scale: _logoScale,
                      child: RepaintBoundary(
                        child: SizedBox.square(
                          dimension: logoSize,
                          child: Image.asset(
                            _heroAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            semanticLabel: 'Zekâ Parkuru',
                            frameBuilder:
                                (
                                  BuildContext context,
                                  Widget child,
                                  int? frame,
                                  bool wasSynchronouslyLoaded,
                                ) {
                                  if (wasSynchronouslyLoaded || frame != null) {
                                    _startAfterImageFrame();
                                    return child;
                                  }
                                  return const _CubeLoadingPlaceholder();
                                },
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  _startAfterImageFrame();
                                  return const _CubeLoadingPlaceholder();
                                },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: logoSize * 0.025),
                    SizedBox(
                      width: logoSize,
                      height: logoSize * 0.25,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SlideTransition(
                              position: _titleSlide,
                              child: FadeTransition(
                                opacity: _titleReveal,
                                child: const Text(
                                  'ZEKÂ PARKURU',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: StudioVisuals.tealInk,
                                    fontSize: 34,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: logoSize * 0.018),
                            SlideTransition(
                              position: _studioSlide,
                              child: FadeTransition(
                                opacity: _studioReveal,
                                child: const Text(
                                  'ZP GAMES',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: StudioVisuals.ink,
                                    fontSize: 18,
                                    height: 1.1,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                builder: (BuildContext context, Widget? child) {
                  return Transform.translate(
                    offset: Offset(0, logoSize * _logoLift.value),
                    child: child,
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

/// Hero görseli diskten okunurken ilk Flutter karesini boş bırakmaz.
class _CubeLoadingPlaceholder extends StatelessWidget {
  const _CubeLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CubeLoadingPlaceholderPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _CubeLoadingPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.shortestSide;
    final Offset center = Offset(size.width / 2, size.height * 0.49);
    final double half = unit * 0.31;
    final double rise = unit * 0.17;
    final double depth = unit * 0.33;

    final Offset top = center.translate(0, -rise);
    final Offset left = center.translate(-half, 0);
    final Offset right = center.translate(half, 0);
    final Offset bottom = center.translate(0, rise);
    final Offset leftBottom = left.translate(0, depth);
    final Offset centerBottom = bottom.translate(0, depth);
    final Offset rightBottom = right.translate(0, depth);

    final Paint leftPaint = Paint()..color = const Color(0xFFD8C6AE);
    final Paint rightPaint = Paint()..color = const Color(0xFFFAF0DF);
    final Paint topPaint = Paint()..color = const Color(0xFFF1E5D3);
    final Paint routePaint = Paint()..color = const Color(0xFF258C8C);
    final Paint ballPaint = Paint()..color = const Color(0xFFE7A435);

    canvas.drawPath(
      Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(bottom.dx, bottom.dy)
        ..lineTo(centerBottom.dx, centerBottom.dy)
        ..lineTo(leftBottom.dx, leftBottom.dy)
        ..close(),
      leftPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(bottom.dx, bottom.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(rightBottom.dx, rightBottom.dy)
        ..lineTo(centerBottom.dx, centerBottom.dy)
        ..close(),
      rightPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(bottom.dx, bottom.dy)
        ..lineTo(left.dx, left.dy)
        ..close(),
      topPaint,
    );

    routePaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy + unit * 0.02)
        ..lineTo(center.dx, center.dy - unit * 0.02)
        ..lineTo(left.dx + unit * 0.07, left.dy + unit * 0.03),
      routePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - unit * 0.02)
        ..lineTo(right.dx - unit * 0.07, right.dy + unit * 0.03),
      routePaint,
    );

    canvas.drawCircle(
      Offset(center.dx, centerBottom.dy - unit * 0.04),
      unit * 0.065,
      ballPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
