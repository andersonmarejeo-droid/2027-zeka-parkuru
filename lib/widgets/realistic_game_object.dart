import 'package:flutter/material.dart';

/// A crop from the shared premium game-object sheets.
///
/// The sheets keep the visual language consistent across the lower game
/// screens without changing any puzzle rules or the launcher artwork.
enum RealisticObjectSheet { memory, weights, tokens }

class RealisticGameObject extends StatelessWidget {
  const RealisticGameObject({
    super.key,
    required this.sheet,
    required this.index,
    this.borderRadius = 16,
    this.overlayColor,
  });

  final RealisticObjectSheet sheet;
  final int index;
  final double borderRadius;
  final Color? overlayColor;

  String get _asset => switch (sheet) {
    RealisticObjectSheet.memory =>
      'assets/game_visuals/memory_objects_sheet.webp',
    RealisticObjectSheet.weights =>
      'assets/game_visuals/weight_objects_sheet.webp',
    RealisticObjectSheet.tokens =>
      'assets/game_visuals/realistic_tokens_sheet.webp',
  };

  int get _columns => switch (sheet) {
    RealisticObjectSheet.memory => 4,
    RealisticObjectSheet.weights => 3,
    RealisticObjectSheet.tokens => 4,
  };

  int get _rows => switch (sheet) {
    RealisticObjectSheet.memory => 4,
    RealisticObjectSheet.weights => 3,
    RealisticObjectSheet.tokens => 3,
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final double width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : 96;
      final double height = constraints.hasBoundedHeight
          ? constraints.maxHeight
          : width;
      final int safeIndex = index.clamp(0, _columns * _rows - 1).toInt();
      final int column = safeIndex % _columns;
      final int row = safeIndex ~/ _columns;
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              left: -column * width,
              top: -row * height,
              width: width * _columns,
              height: height * _rows,
              child: Image.asset(
                _asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
            if (overlayColor != null)
              Positioned.fill(child: ColoredBox(color: overlayColor!)),
          ],
        ),
      );
    },
  );
}
