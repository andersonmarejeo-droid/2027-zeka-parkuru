import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/boardwalk_builder/boardwalk_builder_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Park 10',
  titleEn: 'Park 10',
  subtitleTr: 'Bir sahil parkı kur.',
  subtitleEn: 'Build a boardwalk park.',
  difficulty: 'UZMAN',
  icon: Icons.attractions_rounded,
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
      home: BoardwalkBuilderPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('park plan, selector and edit history fit a small phone', (
    WidgetTester tester,
  ) async {
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
      find.byKey(const ValueKey<String>('boardwalk_builder_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('boardwalk_builder_brief')),
      findsOneWidget,
    );
    final Finder board = find.byKey(
      const ValueKey<String>('boardwalk_builder_park'),
    );
    expect(board, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('boardwalk_build_path')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('boardwalk_builder_open')),
      findsOneWidget,
    );
    expect(tester.getSize(board).width, greaterThan(220));

    final Offset topLeft = tester.getTopLeft(board);
    final Size boardSize = tester.getSize(board);
    await tester.tapAt(
      topLeft + Offset(boardSize.width * .5, boardSize.height * .77),
    );
    await tester.pump();
    expect(find.textContaining('yerleşti'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('boardwalk_builder_undo')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('boardwalk_builder_redo')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet has visible facilities and stable layout', (
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
    expect(find.text('PARK · 10'), findsOneWidget);
    expect(find.textContaining('BRIEF'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('boardwalk_build_pierWheel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('boardwalk_build_shadeCanopy')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
