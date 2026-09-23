import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/games/blocks/block_game_page.dart';
import 'package:zeka_parkuru/games/candy_sort/candy_sort_game_page.dart';
import 'package:zeka_parkuru/games/hanoi/hanoi_game_page.dart';
import 'package:zeka_parkuru/games/logic/logic_game_page.dart';
import 'package:zeka_parkuru/games/memory/memory_game_page.dart';
import 'package:zeka_parkuru/games/number_sort/number_sort_game_page.dart';
import 'package:zeka_parkuru/games/numbers/number_game_page.dart';
import 'package:zeka_parkuru/games/picture_iq/picture_iq_game_page.dart';
import 'package:zeka_parkuru/games/reflex/reflex_game_page.dart';
import 'package:zeka_parkuru/games/shape_puzzle/shape_puzzle_game_page.dart';
import 'package:zeka_parkuru/games/word_hunt/word_hunt_game_page.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const List<(String, Widget)> _gameHubs = <(String, Widget)>[
  ('Mantık Labirenti', LogicGamePage()),
  ('Sayı Ustası', NumberGamePage()),
  ('Blok Atölyesi', BlockGamePage()),
  ('Hafıza Labirenti', MemoryGamePage()),
  ('Hanoi Kulesi', HanoiGamePage()),
  ('Kelime Avı', WordHuntGamePage()),
  ('Görsel IQ', PictureIqGamePage()),
  ('Şeker Sıralama', CandySortGamePage()),
  ('Sayı Peteği', NumberSortGamePage()),
  ('Şekil Birleştir', ShapePuzzleGamePage()),
  ('Refleks Avı', ReflexGamePage()),
];

Future<void> _openEveryGame(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;

  for (final (String name, Widget page) in _gameHubs) {
    await resetTestPreferences();

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData.dark(useMaterial3: true),
        home: page,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      tester.takeException(),
      isNull,
      reason: '$name açılırken Flutter hatası oluştu.',
    );
    expect(find.byType(Scaffold), findsWidgets, reason: name);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('11 oyun küçük Android ekranda taşmadan açılır',
      (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _openEveryGame(
      tester,
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
  });

  testWidgets('11 oyun İngilizce ve tablet boyutunda açılır',
      (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _openEveryGame(
      tester,
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
  });
}
