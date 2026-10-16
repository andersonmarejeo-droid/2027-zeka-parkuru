import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';

void main() {
  test('responsive spacing stays usable from narrow phone to tablet', () {
    expect(ResponsiveGameFrame.pagePaddingFor(320).horizontal, 24);
    expect(ResponsiveGameFrame.pagePaddingFor(393).horizontal, 32);
    expect(ResponsiveGameFrame.pagePaddingFor(768).horizontal, 48);
  });

  test(
    'input policy delays drags until the intentional movement threshold',
    () {
      const Offset start = Offset.zero;

      expect(
        GameInputPolicy.shouldStartDrag(start, const Offset(7.9, 0)),
        isFalse,
      );
      expect(
        GameInputPolicy.shouldStartDrag(start, const Offset(8, 0)),
        isTrue,
      );
      expect(
        GameInputPolicy.minimumInteractiveSize(const Size(32, 56)),
        const Size(48, 56),
      );
    },
  );
}
