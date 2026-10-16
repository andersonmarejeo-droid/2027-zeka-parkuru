import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/hidden_masses/hidden_masses_game_page.dart';
import 'package:zeka_parkuru/games/hidden_masses/hidden_masses_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 phone can deduce and answer the first hidden mass', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: HiddenMassesPlayPage(
          level: ParkurLevelSpec(
            number: 1,
            titleTr: 'Gizli Kütle 01',
            titleEn: 'Hidden Mass 01',
            subtitleTr: 'Üç ölçümü karşılaştır',
            subtitleEn: 'Compare three measurements',
            difficulty: 'USTALAŞMA',
            icon: Icons.scale_outlined,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('DENGELİ ÖLÇÜMLER'), findsOneWidget);

    final HiddenMassPuzzle puzzle = HiddenMassPuzzle.forLevel(1);
    final Finder answer = find.byKey(
      ValueKey<String>('hidden_mass_choice_${puzzle.answerGrams}'),
    );
    await tester.scrollUntilVisible(
      answer,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(answer);
    await tester.pump();

    final Finder submit = find.byKey(
      const ValueKey<String>('hidden_mass_submit'),
    );
    await tester.scrollUntilVisible(
      submit,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('DENGE ÇÖZÜLDÜ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English campaign hub exposes all 20 levels', (
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
        home: HiddenMassesGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hidden Masses'), findsOneWidget);
    expect(find.textContaining('Hidden Mass 01'), findsOneWidget);
    expect(HiddenMassesGamePage.totalCases, 30);
    expect(tester.takeException(), isNull);
  });
}
