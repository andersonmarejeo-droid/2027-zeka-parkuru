import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/pet_rescue_clinic/pet_case_scenario.dart';
import 'package:zeka_parkuru/games/pet_rescue_clinic/pet_rescue_clinic_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 1,
  titleTr: 'Ziyaret 01',
  titleEn: 'Visit 01',
  subtitleTr: 'İpuçlarını sırala.',
  subtitleEn: 'Sequence the clues.',
  difficulty: 'KARŞILAMA',
  icon: Icons.pets_rounded,
);

Future<void> _mount(WidgetTester tester, Size size, Locale locale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.light(useMaterial3: true),
      home: PetRescueClinicPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('care station sequence and disclaimer fit a small phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(tester, const Size(320, 600), const Locale('tr'));
    expect(
      find.byKey(const ValueKey<String>('pet_rescue_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('pet_rescue_prompt')),
      findsOneWidget,
    );
    expect(find.textContaining('VETERİNER ÖNERİSİ DEĞİLDİR'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('pet_tool_quietRoom')));
    await tester.pump();
    expect(find.text('0/3'), findsOneWidget);
    await tester.tap(
      find.byKey(
        ValueKey<String>(
          'pet_tool_${PetCaseScenario.forLevel(1).steps.first.name}',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('1/3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English pet visit fits tablet', (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _mount(tester, const Size(800, 1280), const Locale('en'));
    expect(find.text('VISIT · 1'), findsOneWidget);
    expect(find.textContaining('NOT VETERINARY ADVICE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
