import 'dart:math' as math;

import 'package:flutter/material.dart';

/// High quality, deterministic puzzle artwork.
///
/// The figures are intentionally drawn with Canvas instead of emoji/font glyphs.
/// That keeps every option pixel-stable across Android devices and lets the
/// reasoning engine know exactly when two choices are visually equivalent.
class ProfessionalIqMotif extends StatelessWidget {
  static const List<Color> palette = <Color>[
    Color(0xFF1976D2),
    Color(0xFFF39C12),
    Color(0xFF20A464),
    Color(0xFFE64B5D),
    Color(0xFF7C4DCC),
  ];

  final int motif;
  final int colorIndex;
  final int rotation;
  final bool mirrored;
  final double size;

  const ProfessionalIqMotif({
    super.key,
    required this.motif,
    required this.colorIndex,
    required this.rotation,
    required this.mirrored,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MotifPainter(
          motif: motif,
          color: palette[colorIndex % palette.length],
        ),
      ),
    );
    if (mirrored) {
      child = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1, 1, 1),
        child: child,
      );
    }
    if (!const <int>{0, 2, 8, 10}.contains(motif % 20)) {
      child = Transform.rotate(angle: rotation * math.pi / 2, child: child);
    }
    return child;
  }
}

class _MotifPainter extends CustomPainter {
  final int motif;
  final Color color;

  const _MotifPainter({required this.motif, required this.color});

  Paint get _fill => Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint get _stroke => Paint()
    ..color = const Color(0xFF17324D).withValues(alpha: .72)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  Paint get _detail => Paint()
    ..color = Colors.white.withValues(alpha: .92)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;
    canvas.save();
    canvas.translate(r.center.dx, r.center.dy);
    final double s = math.min(size.width, size.height);
    canvas.scale(s / 64, s / 64);

    switch (motif % 20) {
      case 0:
        _orb(canvas);
      case 1:
        _kite(canvas);
      case 2:
        _rosette(canvas);
      case 3:
        _shield(canvas);
      case 4:
        _drop(canvas);
      case 5:
        _puzzle(canvas);
      case 6:
        _leaf(canvas);
      case 7:
        _ribbon(canvas);
      case 8:
        _gem(canvas);
      case 9:
        _bolt(canvas);
      case 10:
        _pinwheel(canvas);
      case 11:
        _key(canvas);
      case 12:
        _fish(canvas);
      case 13:
        _bird(canvas);
      case 14:
        _sailboat(canvas);
      case 15:
        _umbrella(canvas);
      case 16:
        _flag(canvas);
      case 17:
        _rocket(canvas);
      case 18:
        _crescent(canvas);
      default:
        _cup(canvas);
    }
    canvas.restore();
  }

  void _orb(Canvas c) {
    c.drawCircle(Offset.zero, 21, _fill);
    c.drawCircle(Offset.zero, 21, _stroke);
    c.drawCircle(
      Offset.zero,
      10,
      Paint()..color = Colors.white.withValues(alpha: .92),
    );
    c.drawCircle(Offset.zero, 5, Paint()..color = color.withValues(alpha: .92));
  }

  void _kite(Canvas c) {
    final Path p = Path()
      ..moveTo(0, -24)
      ..lineTo(22, -3)
      ..lineTo(4, 22)
      ..lineTo(-18, 7)
      ..lineTo(-7, -4)
      ..close();
    c.drawPath(p, _fill);
    c.drawPath(p, _stroke);
    c.drawLine(const Offset(-6, -4), const Offset(4, 22), _detail);
    c.drawCircle(const Offset(-8, 6), 3.2, Paint()..color = Colors.white);
  }

  void _rosette(Canvas c) {
    for (int i = 0; i < 6; i++) {
      c.save();
      c.rotate(i * math.pi / 3);
      c.drawOval(const Rect.fromLTWH(-7, -25, 14, 25), _fill);
      c.restore();
    }
    c.drawCircle(
      Offset.zero,
      9,
      Paint()..color = Colors.white.withValues(alpha: .94),
    );
    c.drawCircle(Offset.zero, 4.5, Paint()..color = color);
  }

  void _shield(Canvas c) {
    final Path p = Path()
      ..moveTo(-22, -20)
      ..lineTo(22, -20)
      ..lineTo(18, 7)
      ..quadraticBezierTo(8, 21, 0, 25)
      ..quadraticBezierTo(-8, 21, -18, 7)
      ..close();
    c.drawPath(p, _fill);
    c.drawPath(p, _stroke);
    c.drawPath(
      Path()
        ..moveTo(-11, -8)
        ..lineTo(0, 3)
        ..lineTo(12, -10),
      _detail..strokeWidth = 3,
    );
  }

  void _drop(Canvas c) {
    final Path p = Path()
      ..moveTo(0, -26)
      ..cubicTo(16, -8, 23, 2, 20, 13)
      ..cubicTo(17, 25, 3, 29, -7, 23)
      ..cubicTo(-21, 15, -21, 1, 0, -26)
      ..close();
    c.drawPath(p, _fill);
    c.drawPath(p, _stroke);
    c.drawArc(const Rect.fromLTWH(-11, -3, 18, 20), .4, 1.5, false, _detail);
  }

  void _puzzle(Canvas c) {
    final RRect body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-21, -21, 42, 42),
      const Radius.circular(7),
    );
    c.drawRRect(body, _fill);
    c.drawRRect(body, _stroke);
    c.drawCircle(const Offset(0, -21), 8, _fill);
    c.drawCircle(const Offset(0, -21), 8, _stroke);
    c.drawCircle(
      const Offset(21, 8),
      7,
      Paint()..color = const Color(0xFFF7FAFD),
    );
    c.drawArc(
      const Rect.fromLTWH(14, 1, 14, 14),
      math.pi / 2,
      math.pi,
      false,
      _stroke,
    );
  }

  void _leaf(Canvas c) {
    final Path p = Path()
      ..moveTo(-24, 13)
      ..cubicTo(-17, -15, 8, -27, 25, -20)
      ..cubicTo(26, 2, 8, 24, -24, 13)
      ..close();
    c.drawPath(p, _fill);
    c.drawPath(p, _stroke);
    c.drawLine(const Offset(-16, 11), const Offset(17, -15), _detail);
    c.drawLine(
      const Offset(1, -2),
      const Offset(13, -2),
      _detail..strokeWidth = 1.5,
    );
  }

  void _ribbon(Canvas c) {
    final Path left = Path()
      ..moveTo(-2, 0)
      ..cubicTo(-12, -20, -27, -18, -25, -3)
      ..cubicTo(-22, 10, -10, 13, -2, 0)
      ..close();
    final Path right = Path()
      ..moveTo(2, 0)
      ..cubicTo(12, -14, 26, -10, 24, 4)
      ..cubicTo(22, 16, 10, 18, 2, 0)
      ..close();
    c.drawPath(left, _fill);
    c.drawPath(right, Paint()..color = color.withValues(alpha: .76));
    c.drawPath(left, _stroke);
    c.drawPath(right, _stroke);
    c.drawCircle(Offset.zero, 6, Paint()..color = Colors.white);
    c.drawLine(const Offset(3, 6), const Offset(15, 24), _stroke);
  }

  void _gem(Canvas c) {
    final Path p = Path()
      ..moveTo(-20, -18)
      ..lineTo(18, -18)
      ..lineTo(27, -3)
      ..lineTo(3, 24)
      ..lineTo(-24, 4)
      ..close();
    c.drawPath(p, _fill);
    c.drawPath(p, _stroke);
    c.drawLine(const Offset(-20, -18), const Offset(3, 24), _detail);
    c.drawLine(const Offset(18, -18), const Offset(3, 24), _detail);
    c.drawLine(const Offset(-24, 4), const Offset(27, -3), _detail);
  }

  void _bolt(Canvas c) {
    final Path p = Path()
      ..moveTo(5, -28)
      ..lineTo(-18, 3)
      ..lineTo(-3, 3)
      ..lineTo(-10, 27)
      ..lineTo(20, -8)
      ..lineTo(5, -8)
      ..close();
    c.drawPath(p, _fill);
    c.drawPath(p, _stroke);
    c.drawCircle(const Offset(12, -14), 3.2, Paint()..color = Colors.white);
  }

  void _pinwheel(Canvas c) {
    for (int i = 0; i < 4; i++) {
      c.save();
      c.rotate(i * math.pi / 2);
      final Path p = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(9, -23, 26, -20)
        ..quadraticBezierTo(22, -5, 0, 0)
        ..close();
      c.drawPath(
        p,
        i == 0 ? _fill : Paint()
          ..color = color.withValues(alpha: .70),
      );
      c.restore();
    }
    c.drawCircle(Offset.zero, 5, Paint()..color = Colors.white);
    c.drawCircle(
      const Offset(18, -15),
      3,
      Paint()..color = const Color(0xFF17324D),
    );
  }

  void _key(Canvas c) {
    c.drawCircle(const Offset(-14, 0), 12, _fill);
    c.drawCircle(const Offset(-14, 0), 12, _stroke);
    c.drawCircle(const Offset(-14, 0), 5, Paint()..color = Colors.white);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2, -4, 28, 8),
        const Radius.circular(4),
      ),
      _fill,
    );
    c.drawLine(const Offset(-2, -4), const Offset(26, -4), _stroke);
    c.drawLine(const Offset(26, -4), const Offset(26, 8), _stroke);
    c.drawLine(const Offset(18, 4), const Offset(18, 12), _stroke);
    c.drawCircle(const Offset(7, 0), 2.5, Paint()..color = Colors.white);
  }

  void _fish(Canvas c) {
    final Path body = Path()
      ..moveTo(-22, 0)
      ..quadraticBezierTo(-5, -18, 16, -8)
      ..quadraticBezierTo(24, -3, 25, 0)
      ..quadraticBezierTo(24, 4, 16, 9)
      ..quadraticBezierTo(-5, 18, -22, 0)
      ..close();
    final Path tail = Path()
      ..moveTo(-20, 0)
      ..lineTo(-31, -12)
      ..lineTo(-28, 0)
      ..lineTo(-31, 12)
      ..close();
    c.drawPath(tail, _fill);
    c.drawPath(body, _fill);
    c.drawPath(tail, _stroke);
    c.drawPath(body, _stroke);
    c.drawCircle(const Offset(14, -2), 3.2, Paint()..color = Colors.white);
    c.drawCircle(
      const Offset(15, -2),
      1.4,
      Paint()..color = const Color(0xFF17324D),
    );
    c.drawArc(
      const Rect.fromLTWH(-5, -8, 16, 16),
      -.8,
      1.6,
      false,
      _detail..strokeWidth = 1.5,
    );
  }

  void _bird(Canvas c) {
    final Path p = Path()
      ..moveTo(-27, 8)
      ..quadraticBezierTo(-10, -12, 3, -5)
      ..quadraticBezierTo(10, -17, 24, -13)
      ..quadraticBezierTo(17, -4, 11, 1)
      ..lineTo(29, 4)
      ..lineTo(13, 9)
      ..quadraticBezierTo(0, 20, -27, 8)
      ..close();
    c.drawPath(p, _fill);
    c.drawPath(p, _stroke);
    c.drawCircle(const Offset(15, -7), 2.5, Paint()..color = Colors.white);
    c.drawLine(const Offset(-8, 5), const Offset(7, -4), _detail);
  }

  void _sailboat(Canvas c) {
    final Path hull = Path()
      ..moveTo(-25, 10)
      ..lineTo(25, 10)
      ..lineTo(14, 22)
      ..lineTo(-16, 22)
      ..close();
    final Path sail = Path()
      ..moveTo(-2, -26)
      ..lineTo(-2, 8)
      ..lineTo(22, 8)
      ..close();
    final Path smallSail = Path()
      ..moveTo(-5, -19)
      ..lineTo(-5, 8)
      ..lineTo(-20, 8)
      ..close();
    c.drawPath(hull, _fill);
    c.drawPath(sail, _fill);
    c.drawPath(smallSail, Paint()..color = color.withValues(alpha: .68));
    c.drawPath(hull, _stroke);
    c.drawPath(sail, _stroke);
    c.drawPath(smallSail, _stroke);
    c.drawLine(const Offset(-3, -27), const Offset(-3, 10), _stroke);
  }

  void _umbrella(Canvas c) {
    final Path canopy = Path()
      ..moveTo(-27, 0)
      ..quadraticBezierTo(0, -30, 27, 0)
      ..quadraticBezierTo(20, -5, 13, 0)
      ..quadraticBezierTo(6, -6, 0, 0)
      ..quadraticBezierTo(-7, -6, -13, 0)
      ..quadraticBezierTo(-20, -5, -27, 0)
      ..close();
    c.drawPath(canopy, _fill);
    c.drawPath(canopy, _stroke);
    c.drawLine(
      const Offset(0, 0),
      const Offset(0, 22),
      _stroke..strokeWidth = 2.5,
    );
    c.drawArc(const Rect.fromLTWH(-1, 14, 14, 14), 0, math.pi, false, _stroke);
    c.drawLine(
      const Offset(0, -20),
      const Offset(0, -1),
      _detail..strokeWidth = 1.4,
    );
  }

  void _flag(Canvas c) {
    c.drawLine(
      const Offset(-14, -26),
      const Offset(-14, 26),
      _stroke..strokeWidth = 3,
    );
    final Path flag = Path()
      ..moveTo(-12, -22)
      ..quadraticBezierTo(5, -29, 23, -18)
      ..quadraticBezierTo(8, -5, -12, -11)
      ..close();
    c.drawPath(flag, _fill);
    c.drawPath(flag, _stroke);
    c.drawCircle(const Offset(-14, 27), 4, _fill);
  }

  void _rocket(Canvas c) {
    final Path body = Path()
      ..moveTo(0, -28)
      ..quadraticBezierTo(18, -12, 14, 10)
      ..lineTo(7, 19)
      ..lineTo(-7, 19)
      ..lineTo(-14, 10)
      ..quadraticBezierTo(-18, -12, 0, -28)
      ..close();
    c.drawPath(body, _fill);
    c.drawPath(body, _stroke);
    c.drawCircle(const Offset(0, -7), 6, Paint()..color = Colors.white);
    c.drawCircle(
      const Offset(0, -7),
      3,
      Paint()..color = color.withValues(alpha: .65),
    );
    final Path flame = Path()
      ..moveTo(-6, 20)
      ..lineTo(0, 31)
      ..lineTo(6, 20)
      ..close();
    c.drawPath(flame, Paint()..color = const Color(0xFFFFC04D));
    c.drawPath(flame, _stroke);
  }

  void _crescent(Canvas c) {
    c.drawCircle(Offset.zero, 24, _fill);
    c.drawCircle(
      const Offset(10, -5),
      22,
      Paint()..color = const Color(0xFFF7FAFD),
    );
    c.drawArc(
      const Rect.fromLTWH(-24, -24, 48, 48),
      .45,
      math.pi * 1.45,
      false,
      _stroke,
    );
    c.drawCircle(
      const Offset(-10, -8),
      2.7,
      Paint()..color = Colors.white.withValues(alpha: .9),
    );
  }

  void _cup(Canvas c) {
    final RRect cup = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-23, -17, 34, 34),
      const Radius.circular(7),
    );
    c.drawRRect(cup, _fill);
    c.drawRRect(cup, _stroke);
    c.drawArc(
      const Rect.fromLTWH(4, -10, 25, 22),
      -math.pi / 2,
      math.pi,
      false,
      _stroke..strokeWidth = 3,
    );
    c.drawLine(
      const Offset(-17, -5),
      const Offset(4, -5),
      _detail..strokeWidth = 1.7,
    );
    c.drawLine(
      const Offset(-17, 3),
      const Offset(-3, 3),
      _detail..strokeWidth = 1.7,
    );
  }

  @override
  bool shouldRepaint(covariant _MotifPainter oldDelegate) {
    return oldDelegate.motif != motif || oldDelegate.color != color;
  }
}
