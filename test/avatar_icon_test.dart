import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/services/player_profile_service.dart';
import 'package:zeka_parkuru/widgets/avatar_icon.dart';

void main() {
  testWidgets(
    'sprite avatars keep a real sheet crop instead of squashing the sheet',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AvatarIcon('animal_panda', size: 54)),
        ),
      );
      await tester.pumpAndSettle();

      final OverflowBox crop = tester.widget<OverflowBox>(
        find.byType(OverflowBox),
      );
      expect(crop.minWidth, 216);
      expect(crop.maxWidth, 216);
      expect(crop.minHeight, 216);
      expect(crop.maxHeight, 216);

      final RenderBox viewport = tester.renderObject<RenderBox>(
        find.byType(ClipRRect),
      );
      expect(viewport.size, const Size(54, 54));
      expect(find.byType(Image), findsOneWidget);
    },
  );

  testWidgets('legacy emoji avatars still render when no sprite is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AvatarIcon('🧠', size: 40))),
    );

    expect(find.text('🧠'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  test('profile choices and sprite sheet remain in sync', () {
    expect(
      PlayerProfileService.avatars
          .take(AvatarIcon.sheetAvatars.length)
          .toList(),
      AvatarIcon.sheetAvatars,
    );
  });
}
