import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/pin_unlock/pin_unlock_game_page.dart';
import 'package:zeka_parkuru/games/pin_unlock/pin_unlock_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('compact phone can set every pin and release the lock', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: PinUnlockPlayPage(
          level: const ParkurLevelSpec(
            number: 1,
            titleTr: 'Kilit 1',
            titleEn: 'Lock 1',
            subtitleTr: 'Pim kısıtlarını birleştir',
            subtitleEn: 'Combine pin constraints',
            difficulty: 'USTALAŞMA',
            icon: Icons.lock_open_rounded,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('MEKANİK İPUÇLARI'), findsOneWidget);

    final PinUnlockPuzzle puzzle = PinUnlockPuzzle.forLevel(1);
    for (int pin = 0; pin < puzzle.pinCount; pin++) {
      final Finder notch = find.byKey(
        ValueKey<String>(
          'pin_unlock_pin_${pin}_height_${puzzle.solution[pin]}',
        ),
      );
      await tester.scrollUntilVisible(
        notch,
        280,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final Size targetSize = tester.getSize(notch);
      expect(targetSize.width, greaterThanOrEqualTo(48));
      expect(targetSize.height, greaterThanOrEqualTo(48));
      await tester.tap(notch);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'pin ${pin + 1}');
    }

    final Finder verify = find.byKey(
      const ValueKey<String>('pin_unlock_check'),
    );
    await tester.scrollUntilVisible(
      verify,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(verify);
    await tester.pumpAndSettle();

    expect(find.text('KİLİT AÇILDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet hub presents the ten-stage level map', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: PinUnlockGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pin Unlock'), findsOneWidget);
    expect(find.textContaining('Lock 001'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
