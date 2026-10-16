import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Small, literal objects for memory cards. Shape and colour remain separate
/// cues; the supplied accent is never replaced by a decorative random colour.
class StudioObjectArtwork extends StatelessWidget {
  const StudioObjectArtwork({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 80,
  });

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: _ObjectPainter.supports(icon)
        ? RepaintBoundary(
            child: CustomPaint(painter: _ObjectPainter(icon, accent)),
          )
        : Icon(icon, color: accent, size: size * .84),
  );
}

class _ObjectPainter extends CustomPainter {
  const _ObjectPainter(this.icon, this.accent);

  final IconData icon;
  final Color accent;
  static const Color ink = Color(0xFF34443E);
  static const Color cream = Color(0xFFF5EAD7);
  static const Color timber = Color(0xFF9B704E);
  static const Color glass = Color(0xFFCAE1E4);

  static const List<IconData> _supported = [
    Icons.home_rounded,
    Icons.directions_car_filled_rounded,
    Icons.sailing_rounded,
    Icons.park_rounded,
    Icons.eco_rounded,
    Icons.local_florist_rounded,
    Icons.schedule_rounded,
    Icons.key_rounded,
    Icons.lock_outline_rounded,
    Icons.lightbulb_rounded,
    Icons.rocket_launch_rounded,
    Icons.menu_book_rounded,
    Icons.map_outlined,
    Icons.public_rounded,
    Icons.explore_outlined,
    Icons.coffee_rounded,
  ];

  static bool supports(IconData icon) => _supported.contains(icon);

  Paint _paint(Color color) => Paint()..color = color;
  Paint _edge([Color color = ink, double width = 1.5]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _box(Canvas canvas, Rect rect, Color color, [double radius = 3]) {
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(shape, _paint(color));
    canvas.drawRRect(shape, _edge());
  }

  void _path(Canvas canvas, Path path, Color color) {
    canvas.drawPath(path, _paint(color));
    canvas.drawPath(path, _edge());
  }

  void _line(
    Canvas canvas,
    Offset a,
    Offset b, [
    Color color = ink,
    double width = 1.5,
  ]) => canvas.drawLine(a, b, _edge(color, width));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    canvas.drawOval(
      const Rect.fromLTWH(16, 85, 68, 5),
      _paint(ink.withValues(alpha: .1)),
    );
    if (icon == Icons.home_rounded) {
      _box(canvas, const Rect.fromLTWH(23, 38, 54, 47), cream);
      _box(canvas, const Rect.fromLTWH(68, 19, 8, 19), timber, 1);
      _path(
        canvas,
        Path()
          ..moveTo(15, 41)
          ..lineTo(50, 14)
          ..lineTo(85, 41)
          ..close(),
        accent,
      );
      _line(
        canvas,
        const Offset(23, 39),
        const Offset(50, 20),
        cream.withValues(alpha: .5),
      );
      _box(canvas, const Rect.fromLTWH(44, 58, 16, 27), timber, 1);
      _box(canvas, const Rect.fromLTWH(28, 50, 12, 14), glass, 1);
      _box(canvas, const Rect.fromLTWH(63, 50, 10, 14), glass, 1);
      _line(canvas, const Offset(34, 50), const Offset(34, 64));
      _line(canvas, const Offset(28, 57), const Offset(40, 57));
      canvas.drawCircle(const Offset(56, 72), 1.3, _paint(cream));
    } else if (icon == Icons.directions_car_filled_rounded) {
      _path(
        canvas,
        Path()
          ..moveTo(13, 62)
          ..lineTo(22, 55)
          ..lineTo(34, 31)
          ..lineTo(65, 31)
          ..lineTo(78, 55)
          ..lineTo(90, 59)
          ..lineTo(90, 77)
          ..lineTo(12, 77)
          ..close(),
        accent,
      );
      _path(
        canvas,
        Path()
          ..moveTo(29, 53)
          ..lineTo(38, 35)
          ..lineTo(48, 35)
          ..lineTo(48, 53)
          ..close(),
        glass,
      );
      _path(
        canvas,
        Path()
          ..moveTo(53, 35)
          ..lineTo(62, 35)
          ..lineTo(71, 53)
          ..lineTo(53, 53)
          ..close(),
        glass,
      );
      for (final double x in [29.0, 74.0]) {
        canvas.drawCircle(Offset(x, 76), 10, _paint(ink));
        canvas.drawCircle(Offset(x, 76), 4.5, _paint(const Color(0xFFB7C1BE)));
        canvas.drawCircle(Offset(x, 76), 1.5, _paint(ink));
      }
      _box(canvas, const Rect.fromLTWH(83, 61, 7, 6), cream, 1);
      _line(canvas, const Offset(53, 58), const Offset(58, 58), cream, 2);
      _line(
        canvas,
        const Offset(17, 65),
        const Offset(23, 65),
        const Color(0xFFC87B66),
        3,
      );
    } else if (icon == Icons.sailing_rounded) {
      _line(canvas, const Offset(48, 14), const Offset(48, 74), timber, 3);
      _path(
        canvas,
        Path()
          ..moveTo(44, 19)
          ..lineTo(44, 62)
          ..lineTo(13, 62)
          ..close(),
        cream,
      );
      _path(
        canvas,
        Path()
          ..moveTo(53, 24)
          ..lineTo(81, 62)
          ..lineTo(53, 62)
          ..close(),
        accent,
      );
      _path(
        canvas,
        Path()
          ..moveTo(13, 71)
          ..lineTo(88, 71)
          ..lineTo(76, 84)
          ..lineTo(29, 84)
          ..close(),
        timber,
      );
      _line(
        canvas,
        const Offset(21, 76),
        const Offset(81, 76),
        cream.withValues(alpha: .65),
      );
      for (int i = 0; i < 3; i++) {
        canvas.drawArc(
          Rect.fromLTWH(9 + i * 29.0, 83, 26, 9),
          0,
          math.pi,
          false,
          _edge(const Color(0xFF4D8491), 2),
        );
      }
    } else if (icon == Icons.park_rounded) {
      _box(canvas, const Rect.fromLTWH(44, 53, 12, 32), timber, 1);
      _path(
        canvas,
        Path()
          ..moveTo(50, 10)
          ..lineTo(25, 41)
          ..lineTo(34, 41)
          ..lineTo(16, 64)
          ..lineTo(84, 64)
          ..lineTo(66, 41)
          ..lineTo(75, 41)
          ..close(),
        accent,
      );
      _line(
        canvas,
        const Offset(31, 43),
        const Offset(64, 43),
        cream.withValues(alpha: .45),
      );
      _line(
        canvas,
        const Offset(26, 58),
        const Offset(70, 58),
        cream.withValues(alpha: .45),
      );
    } else if (icon == Icons.eco_rounded) {
      final leaf = Path()
        ..moveTo(23, 76)
        ..cubicTo(9, 42, 42, 21, 82, 16)
        ..cubicTo(81, 57, 57, 87, 23, 76)
        ..close();
      _path(canvas, leaf, accent);
      _line(canvas, const Offset(17, 85), const Offset(69, 30), cream, 2);
      for (int i = 0; i < 3; i++) {
        _line(
          canvas,
          Offset(33 + 11.0 * i, 67 - 12.0 * i),
          Offset(55 + 10.0 * i, 65 - 12.0 * i),
          cream.withValues(alpha: .6),
        );
      }
    } else if (icon == Icons.local_florist_rounded) {
      _line(
        canvas,
        const Offset(50, 46),
        const Offset(50, 87),
        const Color(0xFF497553),
        4,
      );
      _path(
        canvas,
        Path()
          ..moveTo(49, 76)
          ..quadraticBezierTo(25, 76, 28, 59)
          ..quadraticBezierTo(49, 60, 49, 76)
          ..close(),
        const Color(0xFF5D855F),
      );
      for (int i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        final p = Offset(50 + math.cos(a) * 18, 35 + math.sin(a) * 18);
        canvas.drawCircle(p, 13, _paint(accent));
        canvas.drawCircle(p, 13, _edge());
      }
      canvas.drawCircle(
        const Offset(50, 35),
        11,
        _paint(const Color(0xFFDAB56B)),
      );
      canvas.drawCircle(const Offset(50, 35), 11, _edge());
    } else if (icon == Icons.schedule_rounded ||
        icon == Icons.explore_outlined) {
      canvas.drawCircle(const Offset(50, 49), 34, _paint(timber));
      canvas.drawCircle(const Offset(50, 49), 29, _paint(cream));
      canvas.drawCircle(const Offset(50, 49), 34, _edge());
      for (int i = 0; i < 12; i++) {
        final angle = i * math.pi / 6;
        _line(
          canvas,
          Offset(50 + math.sin(angle) * 24, 49 + math.cos(angle) * 24),
          Offset(50 + math.sin(angle) * 27, 49 + math.cos(angle) * 27),
        );
      }
      if (icon == Icons.schedule_rounded) {
        _line(canvas, const Offset(50, 49), const Offset(50, 29), accent, 3);
        _line(canvas, const Offset(50, 49), const Offset(68, 58), ink, 3);
      } else {
        _path(
          canvas,
          Path()
            ..moveTo(62, 25)
            ..lineTo(56, 52)
            ..lineTo(39, 74)
            ..lineTo(44, 47)
            ..close(),
          accent,
        );
      }
      canvas.drawCircle(const Offset(50, 49), 3, _paint(ink));
    } else if (icon == Icons.key_rounded) {
      canvas.drawCircle(const Offset(31, 32), 17, _paint(accent));
      canvas.drawCircle(const Offset(31, 32), 17, _edge());
      canvas.drawCircle(const Offset(31, 32), 8, _paint(cream));
      canvas.drawCircle(const Offset(31, 32), 8, _edge());
      _path(
        canvas,
        Path()
          ..moveTo(40, 41)
          ..lineTo(79, 79)
          ..lineTo(71, 86)
          ..lineTo(64, 78)
          ..lineTo(71, 71)
          ..lineTo(62, 63)
          ..lineTo(55, 70)
          ..lineTo(32, 47)
          ..close(),
        accent,
      );
    } else if (icon == Icons.lock_outline_rounded) {
      canvas.drawArc(
        const Rect.fromLTWH(32, 15, 36, 47),
        math.pi,
        math.pi,
        false,
        _edge(ink, 9),
      );
      canvas.drawArc(
        const Rect.fromLTWH(32, 15, 36, 47),
        math.pi,
        math.pi,
        false,
        _edge(const Color(0xFFAEBDB8), 5),
      );
      _box(canvas, const Rect.fromLTWH(23, 43, 54, 41), accent, 6);
      canvas.drawCircle(const Offset(50, 57), 5, _paint(cream));
      _box(canvas, const Rect.fromLTWH(48, 57, 4, 12), cream, 1);
    } else if (icon == Icons.lightbulb_rounded) {
      final bulb = Path()
        ..moveTo(39, 68)
        ..cubicTo(39, 56, 22, 51, 22, 34)
        ..cubicTo(22, 3, 78, 3, 78, 34)
        ..cubicTo(78, 51, 61, 56, 61, 68)
        ..close();
      _path(canvas, bulb, accent);
      _line(canvas, const Offset(41, 65), const Offset(41, 44), cream, 2);
      _line(canvas, const Offset(59, 65), const Offset(59, 44), cream, 2);
      _line(canvas, const Offset(41, 44), const Offset(59, 44), cream, 2);
      _box(
        canvas,
        const Rect.fromLTWH(38, 67, 24, 17),
        const Color(0xFFAEBDB8),
        3,
      );
      _line(canvas, const Offset(39, 73), const Offset(61, 73));
      _line(canvas, const Offset(39, 79), const Offset(61, 79));
    } else if (icon == Icons.rocket_launch_rounded) {
      _path(
        canvas,
        Path()
          ..moveTo(34, 54)
          ..lineTo(20, 72)
          ..lineTo(20, 85)
          ..lineTo(40, 74)
          ..close(),
        timber,
      );
      _path(
        canvas,
        Path()
          ..moveTo(66, 54)
          ..lineTo(80, 72)
          ..lineTo(80, 85)
          ..lineTo(60, 74)
          ..close(),
        timber,
      );
      _path(
        canvas,
        Path()
          ..moveTo(50, 11)
          ..cubicTo(76, 32, 69, 60, 61, 75)
          ..lineTo(39, 75)
          ..cubicTo(31, 60, 24, 32, 50, 11)
          ..close(),
        accent,
      );
      canvas.drawCircle(const Offset(50, 43), 11, _paint(glass));
      canvas.drawCircle(const Offset(50, 43), 11, _edge());
      _path(
        canvas,
        Path()
          ..moveTo(42, 79)
          ..lineTo(50, 94)
          ..lineTo(58, 79)
          ..close(),
        const Color(0xFFD5A354),
      );
    } else if (icon == Icons.menu_book_rounded) {
      _path(
        canvas,
        Path()
          ..moveTo(13, 22)
          ..quadraticBezierTo(31, 17, 50, 26)
          ..quadraticBezierTo(69, 17, 87, 22)
          ..lineTo(87, 77)
          ..quadraticBezierTo(68, 72, 50, 81)
          ..quadraticBezierTo(32, 72, 13, 77)
          ..close(),
        cream,
      );
      _line(canvas, const Offset(50, 26), const Offset(50, 81), timber, 2);
      for (int i = 0; i < 4; i++) {
        _line(
          canvas,
          Offset(22, 36 + i * 9.0),
          Offset(42, 39 + i * 9.0),
          accent,
          2,
        );
        _line(
          canvas,
          Offset(58, 39 + i * 9.0),
          Offset(78, 36 + i * 9.0),
          accent,
          2,
        );
      }
      _path(
        canvas,
        Path()
          ..moveTo(68, 21)
          ..lineTo(68, 46)
          ..lineTo(73, 41)
          ..lineTo(78, 46)
          ..lineTo(78, 21)
          ..close(),
        accent,
      );
    } else if (icon == Icons.map_outlined) {
      _path(
        canvas,
        Path()
          ..moveTo(12, 25)
          ..lineTo(36, 17)
          ..lineTo(64, 25)
          ..lineTo(88, 17)
          ..lineTo(88, 76)
          ..lineTo(64, 84)
          ..lineTo(36, 76)
          ..lineTo(12, 84)
          ..close(),
        cream,
      );
      _line(canvas, const Offset(36, 18), const Offset(36, 76), timber);
      _line(canvas, const Offset(64, 25), const Offset(64, 83), timber);
      canvas.drawPath(
        Path()
          ..moveTo(19, 67)
          ..quadraticBezierTo(36, 48, 52, 56)
          ..quadraticBezierTo(63, 68, 78, 37),
        _edge(accent, 4),
      );
      canvas.drawCircle(const Offset(78, 37), 5, _paint(timber));
      canvas.drawCircle(const Offset(19, 67), 3, _paint(accent));
    } else if (icon == Icons.public_rounded) {
      final globe = Path()..addOval(const Rect.fromLTWH(16, 15, 68, 68));
      canvas.drawPath(globe, _paint(glass));
      canvas.save();
      canvas.clipPath(globe);
      _path(
        canvas,
        Path()
          ..moveTo(19, 20)
          ..lineTo(41, 17)
          ..lineTo(50, 30)
          ..lineTo(42, 45)
          ..lineTo(31, 46)
          ..lineTo(26, 64)
          ..lineTo(15, 53)
          ..close(),
        accent,
      );
      _path(
        canvas,
        Path()
          ..moveTo(66, 41)
          ..lineTo(82, 31)
          ..lineTo(92, 63)
          ..lineTo(65, 77)
          ..lineTo(55, 61)
          ..close(),
        accent,
      );
      canvas.restore();
      canvas.drawPath(globe, _edge());
      canvas.drawOval(
        const Rect.fromLTWH(35, 15, 30, 68),
        _edge(ink.withValues(alpha: .3), 1),
      );
      _line(
        canvas,
        const Offset(17, 49),
        const Offset(83, 49),
        ink.withValues(alpha: .3),
      );
    } else if (icon == Icons.coffee_rounded) {
      canvas.drawOval(const Rect.fromLTWH(13, 74, 74, 12), _paint(cream));
      canvas.drawOval(const Rect.fromLTWH(13, 74, 74, 12), _edge());
      canvas.drawOval(const Rect.fromLTWH(64, 40, 23, 28), _edge(accent, 6));
      _path(
        canvas,
        Path()
          ..moveTo(24, 35)
          ..lineTo(69, 35)
          ..lineTo(66, 67)
          ..quadraticBezierTo(47, 85, 27, 67)
          ..close(),
        accent,
      );
      canvas.drawOval(const Rect.fromLTWH(24, 31, 45, 10), _paint(cream));
      canvas.drawOval(const Rect.fromLTWH(29, 33, 35, 6), _paint(timber));
      for (int i = 0; i < 2; i++) {
        canvas.drawPath(
          Path()
            ..moveTo(38 + i * 14.0, 25)
            ..quadraticBezierTo(31 + i * 14.0, 19, 39 + i * 14.0, 12),
          _edge(ink.withValues(alpha: .35), 2),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ObjectPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.accent != accent;
}
