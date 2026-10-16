import 'package:flutter/material.dart';

/// Crops one of the twelve realistic focus-filter stimuli from the 4x3 sheet.
class FocusShapeIcon extends StatelessWidget {
  const FocusShapeIcon(
    this.index, {
    super.key,
    this.size = 132,
  });

  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final int safeIndex = index % 12;
    final int row = safeIndex ~/ 4;
    final int column = safeIndex % 4;
    return ClipRect(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              left: -column * size,
              top: -row * size,
              width: size * 4,
              height: size * 3,
              child: Image.asset(
                'assets/focus_filter/focus_shapes_sheet.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
