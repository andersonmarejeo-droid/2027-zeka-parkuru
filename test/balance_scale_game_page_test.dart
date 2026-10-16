import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/balance_scale/balance_scale_game_page.dart';
import 'package:zeka_parkuru/games/balance_scale/balance_scale_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('compact phone can place each weight and complete the balance', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: BalanceScalePlayPage(
          level: const ParkurLevelSpec(
            number: 1,
            titleTr: 'Terazi 1',
            titleEn: 'Balance 1',
            subtitleTr: 'Kütleleri ve ipuçlarını eşleştir',
            subtitleEn: 'Match weights and clues',
            difficulty: 'USTALAŞMA',
            icon: Icons.balance_rounded,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final BalanceScalePuzzle puzzle = BalanceScalePuzzle.forLevel(1);
    for (int index = 0; index < puzzle.stationCount; index++) {
      final BalancePlacement answer = puzzle.solution[index];
      for (final (int weightId, bool leftSide) in <(int, bool)>[
        (answer.leftWeight, true),
        (answer.rightWeight, false),
      ]) {
        final Finder weight = find.byKey(
          ValueKey<String>('balance_scale_weight_$weightId'),
        );
        await tester.scrollUntilVisible(
          weight,
          260,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.getSize(weight).height, greaterThanOrEqualTo(48));
        await tester.tap(weight);
        await tester.pump();

        // The rack follows the board in the compact layout; return to the
        // upper balance lanes before moving down to the requested station.
        await tester.drag(
          find.byKey(const ValueKey<String>('balance_scale_scroll')),
          const Offset(0, 2400),
        );
        await tester.pumpAndSettle();

        final Finder pan = find.byKey(
          ValueKey<String>(
            'balance_scale_pan_${index}_${leftSide ? 'left' : 'right'}',
          ),
        );
        await tester.scrollUntilVisible(
          pan,
          260,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.getSize(pan).height, greaterThanOrEqualTo(48));
        await tester.tap(pan);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }

    final Finder check = find.byKey(
      const ValueKey<String>('balance_scale_check'),
    );
    await tester.scrollUntilVisible(
      check,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();

    expect(find.text('DENGE SAĞLANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet hub presents all ten-stage balance levels', (
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
        home: BalanceScaleGamePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Balance Scale'), findsOneWidget);
    expect(find.textContaining('Balance 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('partially filled scales keep global clues safe to inspect', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: BalanceScalePlayPage(
          level: const ParkurLevelSpec(
            number: 1,
            titleTr: 'Terazi 1',
            titleEn: 'Balance 1',
            subtitleTr: 'Kütleleri ve ipuçlarını eşleştir',
            subtitleEn: 'Match weights and clues',
            difficulty: 'USTALAŞMA',
            icon: Icons.balance_rounded,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();

    for (int station = 0; station < 3; station++) {
      final Finder weight = find.byKey(
        ValueKey<String>('balance_scale_weight_$station'),
      );
      await tester.scrollUntilVisible(
        weight,
        280,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(weight);
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey<String>('balance_scale_scroll')),
        const Offset(0, 2400),
      );
      await tester.pumpAndSettle();

      final Finder pan = find.byKey(
        ValueKey<String>('balance_scale_pan_${station}_left'),
      );
      await tester.scrollUntilVisible(
        pan,
        280,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(pan);
      await tester.pump();
    }

    final Finder check = find.byKey(
      const ValueKey<String>('balance_scale_check'),
    );
    await tester.scrollUntilVisible(
      check,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
