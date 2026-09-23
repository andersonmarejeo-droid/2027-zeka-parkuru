import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/game_audio_service.dart';

class ChampionCelebrationCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool celebrate;

  const ChampionCelebrationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.celebrate,
  });

  @override
  State<ChampionCelebrationCard> createState() =>
      _ChampionCelebrationCardState();
}

class _ChampionCelebrationCardState extends State<ChampionCelebrationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    if (widget.celebrate) {
      _controller.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final GameAudioService audio = GameAudioService.instance;
        unawaited(audio.play(GameSound.applause));
        unawaited(audio.playMashallahCelebration());
        audio.hapticHeavy();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> gradient = widget.celebrate
        ? const <Color>[Color(0xFF7A5200), Color(0xFF1E5C52)]
        : const <Color>[Color(0xFF4D2940), Color(0xFF172D50)];

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 142),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: widget.celebrate
                    ? const Color(0xAAFFD93D)
                    : const Color(0x55FFFFFF),
              ),
              boxShadow: widget.celebrate
                  ? <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFFFFD93D).withValues(alpha: 0.20),
                        blurRadius: 22,
                        offset: const Offset(0, 9),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (widget.celebrate)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CelebrationConfettiPainter(
                          progress: Curves.easeOut.transform(_controller.value),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.celebrate ? '🏆' : '⚔️',
                        style: const TextStyle(fontSize: 34),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.celebrate
                              ? const Color(0xFFFFE06B)
                              : Colors.white,
                          fontSize: widget.celebrate ? 26 : 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: widget.celebrate ? 1.1 : 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CelebrationConfettiPainter extends CustomPainter {
  final double progress;

  const _CelebrationConfettiPainter({required this.progress});

  static const List<Color> _colors = <Color>[
    Color(0xFFFFD93D),
    Color(0xFF6CFF9B),
    Color(0xFF5CD7FF),
    Color(0xFFFF6BB5),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double opacity = (1 - math.max(0, progress - 0.72) / 0.28)
        .clamp(0.0, 1.0)
        .toDouble();

    for (int index = 0; index < 34; index++) {
      final double originX = ((index * 47) % 101) / 100 * size.width;
      final double drift = math.sin(progress * 8 + index) * 15;
      final double y = -18 + progress * (size.height + 42) + (index % 7) * 5;
      final double rotation = progress * math.pi * (2 + index % 4);
      final double width = index.isEven ? 7 : 5;
      final double height = index.isEven ? 12 : 8;

      paint.color = _colors[index % _colors.length].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(originX + drift, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
