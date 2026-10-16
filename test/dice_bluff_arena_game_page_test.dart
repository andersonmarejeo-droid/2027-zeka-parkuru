import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/dice_bluff_arena/dice_bluff_arena_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Zar Masası 10',
  titleEn: 'Dice Table 10',
  subtitleTr: 'Blöfü bul.',
  subtitleEn: 'Call the bluff.',
  difficulty: 'UZMAN',
  icon: Icons.casino_rounded,
);

Future<void> _mount(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.light(useMaterial3: true),
      home: DiceBluffPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    'local hidden dice are passed privately then enter legal bidding',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _mount(
        tester,
        size: const Size(320, 600),
        locale: const Locale('tr'),
      );
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_table')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('dice_bluff_mode_local')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('dice_bluff_start')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('dice_bluff_reveal')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_private_roll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_dice_hand')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('dice_bluff_hide_roll')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_private_roll')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey<String>('dice_bluff_reveal')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('dice_bluff_hide_roll')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_bidding')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_faces')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_raise')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'English tablet keeps mode selection and computer duel controls visible',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _mount(
        tester,
        size: const Size(800, 1280),
        locale: const Locale('en'),
      );
      expect(find.textContaining('SEALED DICE TABLE'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_mode_ai')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_mode_local')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey<String>('dice_bluff_start')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('dice_bluff_reveal')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('dice_bluff_hide_roll')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_bidding')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('dice_bluff_challenge')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
