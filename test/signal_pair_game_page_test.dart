import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/signal_pair/signal_pair_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

const ParkurLevelSpec _level = ParkurLevelSpec(
  number: 10,
  titleTr: 'Sinyal Ortağı 10',
  titleEn: 'Signal Partner 10',
  subtitleTr: 'Birlikte aktar.',
  subtitleEn: 'Transmit together.',
  difficulty: 'UZMAN',
  icon: Icons.sensors_rounded,
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
      home: SignalPairPlayPage(level: _level, previousBestScore: 0),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('phone hides navigator route before operator control screen', (
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
      find.byKey(const ValueKey<String>('signal_pair_board')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('signal_pair_open_map')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('signal_pair_private_route')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('signal_pair_hide_map')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('signal_pair_private_route')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('signal_pair_open_panel')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('signal_pair_operator_panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('signal_pair_controls')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('signal_pair_submit')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('signal_pair_button_0')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('signal_pair_operator_input')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet private route is absent from operator role', (
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
    await tester.tap(
      find.byKey(const ValueKey<String>('signal_pair_open_map')),
    );
    await tester.pump();
    expect(find.textContaining('TRANSMIT THESE PULSES'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('signal_pair_hide_map')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('signal_pair_open_panel')),
    );
    await tester.pump();
    expect(find.textContaining('CONTROL PANEL'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('signal_pair_private_route')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('signal_pair_button_3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
