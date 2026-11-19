import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'atlas_puzzle.dart';

class _AtlasRenderCache {
  const _AtlasRenderCache({
    required this.baseMapPicture,
    required this.featurePaths,
    required this.featureCenters,
    required this.featureColors,
  });

  final ui.Picture baseMapPicture;
  final Map<String, List<Path>> featurePaths;
  final Map<String, Offset> featureCenters;
  final Map<String, Color> featureColors;
}

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

  static final Map<String, _AtlasRenderCache> _cache = <String, _AtlasRenderCache>{};

  AtlasMapPainter({
    required this.kind,
    required this.features,
    this.revealCode,
    this.revealProgress = 0,
    this.revealAnimation,
  }) : super(repaint: revealAnimation);

  final AtlasKind kind;
  final List<AtlasFeature> features;
  final String? revealCode;
  final double revealProgress;
  final Animation<double>? revealAnimation;

  double get _minLon => kind == AtlasKind.turkey ? 25.4 : -180;
  double get _maxLon => kind == AtlasKind.turkey ? 45.0 : 180;
  double get _minLat => kind == AtlasKind.turkey ? 35.6 : -60;
  double get _maxLat => kind == AtlasKind.turkey ? 42.3 : 85;

  Offset project(double longitude, double latitude, Size size) => Offset(
    ((longitude - _minLon) / (_maxLon - _minLon)) * size.width,
    ((_maxLat - latitude) / (_maxLat - _minLat)) * size.height,
  );

  _AtlasRenderCache _buildCache(Size size) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

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

    final Map<String, List<Path>> featurePaths = <String, List<Path>>{};
    final Map<String, Offset> featureCenters = <String, Offset>{};
    final Map<String, Color> featureColors = <String, Color>{};

    for (final AtlasFeature feature in features) {
      final Offset center = feature.center.length >= 2
          ? project(feature.center[0], feature.center[1], size)
          : size.center(Offset.zero);
      featureCenters[feature.code] = center;

      final Color regionColor = _regionColor(feature);
      featureColors[feature.code] = regionColor;

      final Paint fillPaint = Paint()
        ..color = regionColor
        ..style = PaintingStyle.fill;
      final Paint outlinePaint = Paint()
        ..color = Color.lerp(regionColor, const Color(0xFF203D3C), .58)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = kind == AtlasKind.turkey ? 1.15 : .65
        ..strokeJoin = StrokeJoin.round;

      final List<Path> paths = <Path>[];
      for (final List<List<double>> ring in feature.rings) {
        if (ring.length < 4) continue;
        Path path = Path();
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
              paths.add(path);
              canvas.drawPath(path, fillPaint);
              canvas.drawPath(path, outlinePaint);
              path = Path();
            }
            path.moveTo(next.dx, next.dy);
            started = true;
          } else {
            path.lineTo(next.dx, next.dy);
          }
          previous = next;
        }
        path.close();
        paths.add(path);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, outlinePaint);
      }
      featurePaths[feature.code] = paths;
    }
    canvas.restore();

    final ui.Picture picture = recorder.endRecording();
    return _AtlasRenderCache(
      baseMapPicture: picture,
      featurePaths: featurePaths,
      featureCenters: featureCenters,
      featureColors: featureColors,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final String cacheKey =
        '${kind.name}_${features.length}_${size.width.round()}_${size.height.round()}';
    _AtlasRenderCache? cache = _cache[cacheKey];
    if (cache == null) {
      if (_cache.length > 6) {
        _cache.clear();
      }
      cache = _buildCache(size);
      _cache[cacheKey] = cache;
    }

    // 1. Statik temel haritayı tek bir GPU komutu ile anında çiz
    canvas.drawPicture(cache.baseMapPicture);

    // 2. Eğer doğru cevap bulunup bir bölge vurgulanacaksa, yalnızca o tek bölgeyi üstte animasyonla göster
    if (revealCode != null) {
      final List<Path>? paths = cache.featurePaths[revealCode];
      if (paths != null && paths.isNotEmpty) {
        final double progress = revealAnimation?.value ?? revealProgress;
        final double pulse = .5 + .5 * math.sin(progress * math.pi * 6);
        final double revealScale = 1 + 4 * math.sin(progress * math.pi);
        final Offset center =
            cache.featureCenters[revealCode] ?? size.center(Offset.zero);

        final RRect bounds = RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(22),
        );
        canvas.save();
        canvas.clipRRect(bounds);

        if (revealScale > 1.001) {
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.scale(revealScale);
          canvas.translate(-center.dx, -center.dy);
        }

        final Color baseColor =
            cache.featureColors[revealCode] ?? const Color(0xFF0E9F87);
        final Color fill = Color.lerp(
          baseColor,
          const Color(0xFFFFD166),
          .20 + .42 * pulse,
        )!;
        final Color outlineColor = const Color(0xFF155F55);

        final Paint fillPaint = Paint()
          ..color = fill
          ..style = PaintingStyle.fill;
        final Paint outlinePaint = Paint()
          ..color = outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = kind == AtlasKind.turkey ? 2.2 : 1.5
          ..strokeJoin = StrokeJoin.round;
        final Paint haloPaint = Paint()
          ..color = const Color(0xFF22B58E).withValues(alpha: .22 + .25 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = kind == AtlasKind.turkey ? 6.5 : 4.5
          ..strokeJoin = StrokeJoin.round;

        for (final Path path in paths) {
          canvas.drawPath(path, haloPaint);
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, outlinePaint);
        }

        if (revealScale > 1.001) {
          canvas.restore();
        }
        canvas.restore();
      }
    }
  }

  Color _regionColor(AtlasFeature feature) {
    int hash = 17;
    for (final int codeUnit in feature.code.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    final Color base = _regionPalette[hash % _regionPalette.length];
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
  bool shouldRepaint(covariant AtlasMapPainter oldDelegate) {
    if (oldDelegate.kind != kind ||
        oldDelegate.features.length != features.length ||
        oldDelegate.revealCode != revealCode) {
      return true;
    }
    if (revealCode != null) {
      return oldDelegate.revealProgress != revealProgress;
    }
    return false;
  }
}

