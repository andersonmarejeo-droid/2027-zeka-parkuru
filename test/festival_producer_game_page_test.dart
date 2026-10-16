import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/festival_producer/festival_producer_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Festival 10',
  titleEn: 'Festival 10',
  subtitleTr: 'Dengeli bir gün programı kur.',
  subtitleEn: 'Build a balanced schedule.',
  difficulty: 'UZMAN',
  icon: Icons.event_rounded,
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
      home: FestivalProducerPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('timeline, setlist and history fit a small phone', (
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
      find.byKey(const ValueKey<String>('festival_producer_hud')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('festival_producer_brief')),
      findsOneWidget,
    );
    final Finder timeline = find.byKey(
      const ValueKey<String>('festival_producer_timeline'),
    );
    expect(timeline, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('festival_producer_setlist')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('festival_producer_publish')),
      findsOneWidget,
    );
    expect(tester.getSize(timeline).width, greaterThan(220));
    final Offset topLeft = tester.getTopLeft(timeline);
    final Size size = tester.getSize(timeline);
    await tester.tapAt(topLeft + Offset(size.width * .18, size.height * .36));
    await tester.pump();
    expect(find.textContaining('yerleşti'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('festival_producer_undo')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('festival_producer_redo')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet displays stage plan and performance choices', (
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
    expect(find.text('RUN OF SHOW · 10'), findsOneWidget);
    expect(find.textContaining('covered stage 1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('festival_set_paper_sky')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
