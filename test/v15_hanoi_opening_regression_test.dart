import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/games/hanoi/hanoi_game_page.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  test(
    'Hanoi no longer gates opening on SharedPreferences or replay history',
    () {
      final String source = File('lib/games/hanoi/hanoi_game_page.dart')
          .readAsStringSync();

      expect(source, contains('bool loading = false'));
      expect(source, contains('_loadProgressInBackground'));
      expect(source, contains('Future.wait<Object?>'));
      expect(source, contains('_progressLoadTimeout'));
      expect(source, contains('_initializeProblemImmediately'));
      expect(source, contains('_registerFingerprintSafely'));
      expect(source, isNot(contains('await _replayability.newSeed')));
    },
  );

  testWidgets('Hanoi hub paints level cards on its first usable frame', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData.dark(useMaterial3: true),
        home: const HanoiGamePage(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.textContaining('İlk Taşıma'), findsOneWidget);
  });

  testWidgets(
    'Hanoi first level opens a playable board without a storage wait',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData.dark(useMaterial3: true),
          home: const HanoiGamePage(),
        ),
      );
      await tester.pump();

      await tester.tap(find.textContaining('İlk Taşıma'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(HanoiPlayPage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('Hanoi ipucu hakkı üç kullanımla sınırlıdır', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData.dark(useMaterial3: true),
        home: const HanoiPlayPage(
          level: HanoiLevel(
            number: 1,
            titleTr: 'İlk Taşıma',
            titleEn: 'First Move',
            subtitleTr: 'Test',
            subtitleEn: 'Test',
            difficulty: 'KOLAY',
            diskCount: 3,
            startPeg: 0,
            targetPeg: 2,
            twoStarLimit: 10,
            tutorial: true,
          ),
          totalLevels: 10,
          savedBestMoves: 0,
          previousBestScore: 0,
          fixedSessionSeed: 104,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('İPUCU 3/3'), findsOneWidget);

    for (int remaining = 2; remaining >= 0; remaining--) {
      await tester.tap(find.byIcon(Icons.lightbulb_rounded));
      await tester.pump();

      expect(
        find.text('İPUCU $remaining/3'),
        findsOneWidget,
        reason: 'Her kullanım tam olarak bir ipucu hakkı tüketmelidir.',
      );
    }

    expect(find.textContaining('Artık ipucu hakkın kalmadı.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.lightbulb_rounded));
    await tester.pump();

    expect(
      find.text('İPUCU 0/3'),
      findsOneWidget,
      reason: 'Dördüncü ipucu isteği kabul edilmemelidir.',
    );

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();

    expect(
      find.text('İPUCU 0/3'),
      findsOneWidget,
      reason: 'Yeniden başlatma ipucu hakkını yenilememelidir.',
    );
    expect(tester.takeException(), isNull);
  });
}
