import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/deckforge_duel/deckforge_duel_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Deste Ustası 10',
  titleEn: 'Deckforge Duel 10',
  subtitleTr: 'Enerjini ve savunmanı yönet.',
  subtitleEn: 'Manage energy and defense.',
  difficulty: 'USTA',
  icon: Icons.style_rounded,
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
      home: DeckforgeDuelPlayPage(
        key: UniqueKey(),
        level: _level,
        previousBestScore: 0,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('small phone supports private local pass-and-play handoff', (
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
    await tester.tap(
      find.byKey(const ValueKey<String>('deckforge_mode_local')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('deckforge_card_0')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('deckforge_card_0')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('deckforge_commit')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('deckforge_handoff')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('deckforge_card_0')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('deckforge_confirm_handoff')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('deckforge_card_0')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'English tablet starts a tactical computer match without overflow',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await _mount(
        tester,
        size: const Size(800, 1280),
        locale: const Locale('en'),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('deckforge_mode_computer')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('RIVAL INTENT'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('deckforge_commit')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('replaying a level advances through distinct practice layouts', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const Size phone = Size(360, 720);
    await _mount(tester, size: phone, locale: const Locale('tr'));
    await tester.tap(
      find.byKey(const ValueKey<String>('deckforge_mode_computer')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kuzey Kürsüsü'), findsOneWidget);

    await _mount(tester, size: phone, locale: const Locale('tr'));
    await tester.tap(
      find.byKey(const ValueKey<String>('deckforge_mode_computer')),
    );
    await tester.pumpAndSettle();
    expect(find.text('PRATİK 001'), findsOneWidget);
    expect(find.text('Kuzey Kürsüsü'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
