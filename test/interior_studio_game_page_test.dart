import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/interior_studio/interior_studio_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Tasarım 10',
  titleEn: 'Design 10',
  subtitleTr: 'İşlevsel bir oda tasarla.',
  subtitleEn: 'Design a functional room.',
  difficulty: 'UZMAN',
  icon: Icons.chair_alt_rounded,
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
      home: InteriorStudioPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    'fixed brief, room, rotation and edit history fit a small phone',
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
        find.byKey(const ValueKey<String>('interior_studio_hud')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('interior_studio_brief')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('interior_studio_room')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('interior_studio_rotate')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('interior_studio_evaluate')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('interior_studio_room')))
            .width,
        greaterThan(220),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('interior_studio_rotate')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('interior_palette_sage')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('interior_item_desk')),
      );
      await tester.pump();
      final Finder room = find.byKey(
        const ValueKey<String>('interior_studio_room'),
      );
      final Offset topLeft = tester.getTopLeft(room);
      final Size roomSize = tester.getSize(room);
      await tester.tapAt(
        topLeft + Offset(roomSize.width * .14, roomSize.height * .16),
      );
      await tester.pump();
      expect(find.textContaining('yerleşti'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('interior_studio_undo')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('interior_studio_redo')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English tablet shows readable brief and furniture palette', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('STUDIO · DESIGN 10'), findsOneWidget);
    expect(find.textContaining('BRIEF'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('interior_item_diningTable')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
