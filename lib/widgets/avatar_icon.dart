import 'package:flutter/material.dart';

/// Displays a profile avatar from the realistic sprite sheet, while keeping
/// backwards compatibility with the emoji avatars saved by older versions.
class AvatarIcon extends StatelessWidget {
  const AvatarIcon(this.avatar, {super.key, this.size = 40, this.borderRadius});

  final String avatar;
  final double size;
  final double? borderRadius;

  static const List<String> sheetAvatars = <String>[
    'animal_fox',
    'animal_panda',
    'animal_dog',
    'animal_owl',
    'animal_snow_leopard',
    'animal_sea_turtle',
    'animal_rabbit',
    'animal_eagle',
    'animal_cat',
    'animal_wolf',
    'animal_penguin',
    'animal_chameleon',
    'object_robot',
    'object_compass',
    'object_puzzle',
    'object_brain',
  ];

  @override
  Widget build(BuildContext context) {
    final int index = sheetAvatars.indexOf(avatar);
    if (index < 0) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(avatar, style: TextStyle(fontSize: size * .58)),
        ),
      );
    }

    final int row = index ~/ 4;
    final int column = index % 4;
    final double radius = borderRadius ?? size * .24;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: size * 4,
            maxWidth: size * 4,
            minHeight: size * 4,
            maxHeight: size * 4,
            child: Transform.translate(
              offset: Offset(-column * size, -row * size),
              child: Image.asset(
                'assets/avatars/avatar_sheet.webp',
                width: size * 4,
                height: size * 4,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
