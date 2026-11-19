import 'package:flutter/material.dart';

/// Renders one of the twelve clean vector focus-filter shapes without any image asset.
class FocusShapeIcon extends StatelessWidget {
  const FocusShapeIcon(
    this.index, {
    super.key,
    this.size = 132,
    this.color,
  });

  final int index;
  final double size;
  final Color? color;

  static const List<IconData> _shapeIcons = <IconData>[
    Icons.change_history_rounded, // 0: Üçgen
    Icons.circle_rounded,         // 1: Daire
    Icons.square_rounded,         // 2: Kare
    Icons.star_rounded,           // 3: Yıldız
    Icons.diamond_rounded,        // 4: Elmas
    Icons.nightlight_round,       // 5: Hilal
    Icons.hexagon_rounded,        // 6: Altıgen
    Icons.local_florist_rounded,  // 7: Çiçek
    Icons.water_drop_rounded,     // 8: Damla
    Icons.cloud_rounded,          // 9: Bulut
    Icons.eco_rounded,            // 10: Yaprak
    Icons.bolt_rounded,           // 11: Şimşek
  ];

  @override
  Widget build(BuildContext context) {
    final int safeIndex = index % _shapeIcons.length;
    final IconData icon = _shapeIcons[safeIndex];
    final Color iconColor = color ?? const Color(0xFF354458);

    return Center(
      child: Icon(
        icon,
        size: size * 0.72,
        color: iconColor,
      ),
    );
  }
}
