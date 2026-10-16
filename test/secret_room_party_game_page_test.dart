import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/secret_room_party/secret_room_party_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Gizli Oda 10',
  titleEn: 'Secret Room 10',
  subtitleTr: 'Birlikte çıkarım yap.',
  subtitleEn: 'Investigate together.',
  difficulty: 'UZMAN',
  icon: Icons.visibility_off_rounded,
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
      home: SecretRoomPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('role secrecy, sealed ballot and discussion fit small phone', (
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
    expect(tester.takeException(), isNull, reason: 'initial layout');
    expect(
      find.byKey(const ValueKey<String>('secret_room_scene')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('secret_room_setup')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('secret_room_player_count_3')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'player count');
    await tester.tap(find.byKey(const ValueKey<String>('secret_room_start')));
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'role handoff');
    await tester.tap(
      find.byKey(const ValueKey<String>('secret_room_show_role')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'private role');
    expect(
      find.byKey(const ValueKey<String>('secret_room_private_card')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('secret_room_hide_pass')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'role hidden');
    expect(
      find.byKey(const ValueKey<String>('secret_room_private_card')),
      findsNothing,
    );
    expect(find.textContaining('OYUNCU 2'), findsOneWidget);
    for (int player = 1; player < 3; player++) {
      await tester.tap(
        find.byKey(const ValueKey<String>('secret_room_show_role')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'next private role');
      await tester.tap(
        find.byKey(const ValueKey<String>('secret_room_hide_pass')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'next role hidden');
    }
    expect(
      find.byKey(const ValueKey<String>('secret_room_discussion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('secret_room_evidence_list')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('secret_room_start_vote')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'vote handoff');
    expect(
      find.byKey(const ValueKey<String>('secret_room_vote_handoff')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('secret_room_open_ballot')),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'ballot open');
    expect(
      find.byKey(const ValueKey<String>('secret_room_suspects')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet presents privacy setup and room brief cleanly', (
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
    expect(find.textContaining('PRIVATE CASE FILE'), findsOneWidget);
    expect(find.textContaining('PASS-AND-PLAY'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('secret_room_start')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
