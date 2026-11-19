import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/reference_games/atlas_find_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/atlas_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  const levelSpec = ParkurLevelSpec(
    number: 1,
    titleTr: 'Dünya 01',
    titleEn: 'World 01',
    subtitleTr: 'Bölüm 1',
    subtitleEn: 'Level 1',
    difficulty: 'TEMEL',
    icon: Icons.public_rounded,
    poolIndex: 0,
  );

  testWidgets('World Atlas supports skip, correct answer, autonomous advance and button advance',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: AtlasPlayPage(
          kind: AtlasKind.world,
          level: levelSpec,
        ),
      ),
    );

    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      if (find.byType(TextField).evaluate().isNotEmpty) break;
    }

    // 1. Soru 1 kontrolü
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Pas Geç'), findsOneWidget);
    expect(find.text('CEVABI KONTROL ET'), findsOneWidget);

    // Pas geç butonuna bas
    await tester.tap(find.text('Pas Geç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Doğru yanıt ve "SONRAKİ SORUYA GEÇ →" butonu görünür olmalı
    expect(find.text('SONRAKİ SORUYA GEÇ →'), findsOneWidget);

    // Butona basarak hemen Soru 2'ye geç
    await tester.tap(find.text('SONRAKİ SORUYA GEÇ →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 2. Soru 2 kontrolü (Variant 0'da 2. soru ITA: İtalya)
    expect(find.textContaining('Soru 2'), findsOneWidget);
    final Finder textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Doğru cevabı yaz ('İtalya')
    await tester.enterText(textField, 'İtalya');
    await tester.pump();

    // Cevabı kontrol et
    final Finder checkButton = find.text('CEVABI KONTROL ET');
    await tester.tap(checkButton);
    await tester.pump();

    // Doğru cevabın onaylandığını gör
    expect(find.textContaining('Doğru: İtalya'), findsOneWidget);

    // Otonom (otomatik) geçiş süresini bekle (850ms)
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pump();

    // Hiçbir butona basmadan otomatik olarak Soru 3'e geçmiş olmalı!
    expect(find.textContaining('Soru 3'), findsOneWidget);
  });
}
