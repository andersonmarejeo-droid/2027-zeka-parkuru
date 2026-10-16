import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/museum_curator/museum_curator_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Sergi 10',
  titleEn: 'Exhibit 10',
  subtitleTr: 'Tutarlı bir sergi kur.',
  subtitleEn: 'Curate a coherent exhibition.',
  difficulty: 'UZMAN',
  icon: Icons.museum_rounded,
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
      home: MuseumCuratorPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('gallery, collection and edit history fit a small phone', (
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
      find.byKey(const ValueKey<String>('museum_curator_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('museum_curator_brief')),
      findsOneWidget,
    );
    final Finder gallery = find.byKey(
      const ValueKey<String>('museum_curator_gallery'),
    );
    expect(gallery, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('museum_curator_collection')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('museum_curator_open')),
      findsOneWidget,
    );
    expect(tester.getSize(gallery).width, greaterThan(220));
    final Offset topLeft = tester.getTopLeft(gallery);
    final Size size = tester.getSize(gallery);
    await tester.tapAt(topLeft + Offset(size.width * .16, size.height * .52));
    await tester.pump();
    expect(find.textContaining('yerleşti'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('museum_curator_undo')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('museum_curator_redo')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet keeps exhibit brief and collection accessible', (
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
    expect(find.text('EXHIBIT · 10'), findsOneWidget);
    expect(find.textContaining('EXPLORATION'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('museum_artifact_diver_helmet')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
