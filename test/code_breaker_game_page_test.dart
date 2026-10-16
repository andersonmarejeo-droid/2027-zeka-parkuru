import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/code_breaker/code_breaker_game_page.dart';
import 'package:zeka_parkuru/games/code_breaker/code_breaker_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Kod Kırıcı $number',
  titleEn: 'Code Breaker $number',
  subtitleTr: 'Geri bildirimi çöz',
  subtitleEn: 'Read the feedback',
  difficulty: 'USTALAŞMA',
  icon: Icons.password_rounded,
);

Future<void> _mount(
  WidgetTester tester, {
  required Widget home,
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
      home: home,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('level hub opens on a compact phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const CodeBreakerGamePage(),
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
    expect(find.text('Kod Kırıcı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('secret can be entered and cracked on a compact phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: CodeBreakerPlayPage(level: _level(1), previousBestScore: 0),
      size: const Size(360, 740),
      locale: const Locale('tr'),
    );
    final CodeBreakerPuzzle puzzle = CodeBreakerPuzzle.forLevel(1);
    for (final int symbol in puzzle.secret) {
      await tester.tap(find.byKey(ValueKey<String>('code-symbol-$symbol')));
      await tester.pump(const Duration(milliseconds: 25));
    }
    final Finder submit = find.byKey(const ValueKey<String>('code-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.text('KOD KIRILDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English code hub fits a tablet viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(
      tester,
      home: const CodeBreakerGamePage(),
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
    expect(find.text('Code Breaker'), findsOneWidget);
    expect(CodeBreakerGamePage.totalCases, 20);
    expect(tester.takeException(), isNull);
  });
}
