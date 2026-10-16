import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'atlas_puzzle.dart';

class AtlasMapPainter extends CustomPainter {
  static const List<Color> _regionPalette = <Color>[
    Color(0xFF0E9F87),
    Color(0xFFF28C28),
    Color(0xFFE34F5F),
    Color(0xFF3C82D8),
    Color(0xFF7B5BD6),
    Color(0xFFE0A51A),
    Color(0xFFD6538A),
    Color(0xFF3EAD68),
    Color(0xFF2E9EB5),
    Color(0xFFB45AC5),
    Color(0xFFE4663E),
    Color(0xFF4C76C8),
  ];

  AtlasMapPainter({
    required this.kind,
    required this.features,
    this.revealCode,
    this.revealProgress = 0,
  });

  final AtlasKind kind;
  final List<AtlasFeature> features;
  final String? revealCode;
  final double revealProgress;

  double get _minLon => kind == AtlasKind.turkey ? 25.4 : -180;
  double get _maxLon => kind == AtlasKind.turkey ? 45.0 : 180;
  double get _minLat => kind == AtlasKind.turkey ? 35.6 : -60;
  double get _maxLat => kind == AtlasKind.turkey ? 42.3 : 85;

  Offset project(double longitude, double latitude, Size size) => Offset(
    ((longitude - _minLon) / (_maxLon - _minLon)) * size.width,
    ((_maxLat - latitude) / (_maxLat - _minLat)) * size.height,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final RRect bounds = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.drawRRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFE5EFF0),
            Color(0xFFD6E7EA),
            Color(0xFFEAF1F0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.clipRRect(bounds);
    _paintGrid(canvas, size);
    final List<AtlasFeature> sorted = features.toList()
      ..sort(
        (AtlasFeature a, AtlasFeature b) =>
            _emphasis(a).compareTo(_emphasis(b)),
      );
    for (final AtlasFeature feature in sorted) {
      final bool isRevealed = feature.code == revealCode;
      final double pulse = isRevealed
          ? .5 + .5 * math.sin(revealProgress * math.pi * 6)
          : 0;
      // Doğru bölgeyi kısa süreliğine 5 kata kadar öne çıkarıp yerine geri
      // döndür. Böylece özellikle küçük şehir/ülke şekilleri de net biçimde
      // takip edilebilir; haritanın dışına taşan kısım kliplenir.
      final double revealScale = isRevealed
          ? 1 + 4 * math.sin(revealProgress * math.pi)
          : 1;
      if (isRevealed && revealScale > 1.001) {
        final Offset center = feature.center.length >= 2
            ? project(feature.center[0], feature.center[1], size)
            : size.center(Offset.zero);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.scale(revealScale);
        canvas.translate(-center.dx, -center.dy);
      }
      final Color regionColor = _regionColor(feature);
      final Color fill = isRevealed
          ? Color.lerp(regionColor, const Color(0xFFFFD166), .20 + .42 * pulse)!
          : regionColor;
      final Color outlineColor = isRevealed
          ? const Color(0xFF155F55)
          : Color.lerp(regionColor, const Color(0xFF203D3C), .58)!;
      final Paint fillPaint = Paint()
        ..color = fill
        ..style = PaintingStyle.fill;
      final Paint outline = Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isRevealed
            ? (kind == AtlasKind.turkey ? 2.2 : 1.5)
            : (kind == AtlasKind.turkey ? 1.15 : .65)
        ..strokeJoin = StrokeJoin.round;
      for (final List<List<double>> ring in feature.rings) {
        if (ring.length < 4) continue;
        final Path path = Path();
        Offset? previous;
        bool started = false;
        for (final List<double> point in ring) {
          final double lon = point[0], lat = point[1];
          final Offset next = project(lon, lat, size);
          final bool wraps =
              kind == AtlasKind.world &&
              previous != null &&
              (next.dx - previous.dx).abs() > size.width * .5;
          if (!started || wraps) {
            if (wraps) {
              path.close();
              _drawRegion(
                canvas,
                path,
                fillPaint,
                outline,
                revealed: isRevealed,
                pulse: pulse,
              );
            }
            path.moveTo(next.dx, next.dy);
            started = true;
          } else {
            path.lineTo(next.dx, next.dy);
          }
          previous = next;
        }
        path.close();
        _drawRegion(
          canvas,
          path,
          fillPaint,
          outline,
          revealed: isRevealed,
          pulse: pulse,
        );
      }
      if (isRevealed && revealScale > 1.001) {
        canvas.restore();
      }
    }
    canvas.restore();
  }

  void _drawRegion(
    Canvas canvas,
    Path path,
    Paint fill,
    Paint outline, {
    required bool revealed,
    required double pulse,
  }) {
    if (revealed) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF22B58E).withValues(alpha: .20 + .22 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
  }

  int _emphasis(AtlasFeature feature) => feature.code == revealCode ? 1 : 0;

  Color _regionColor(AtlasFeature feature) {
    int hash = 17;
    for (final int codeUnit in feature.code.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    final Color base = _regionPalette[hash % _regionPalette.length];
    // Keep the map vivid while leaving enough contrast for the boundaries.
    return Color.lerp(base, Colors.white, kind == AtlasKind.turkey ? .16 : .21)!;
  }

  void _paintGrid(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = const Color(0x427FA99E)
      ..strokeWidth = .7;
    final int horizontalLines = kind == AtlasKind.turkey ? 7 : 6;
    final int verticalLines = kind == AtlasKind.turkey ? 8 : 12;
    for (int i = 1; i < horizontalLines; i++) {
      final double y = size.height * i / horizontalLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (int i = 1; i < verticalLines; i++) {
      final double x = size.width * i / verticalLines;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
  }

  @override
  bool shouldRepaint(covariant AtlasMapPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.features != features ||
      oldDelegate.revealCode != revealCode ||
      oldDelegate.revealProgress != revealProgress;
}
