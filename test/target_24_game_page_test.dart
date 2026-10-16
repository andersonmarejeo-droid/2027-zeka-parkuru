import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/target_24/target_24_game_page.dart';
import 'package:zeka_parkuru/games/target_24/target_24_puzzle.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('compact phone can solve a complete deal without overflow', (
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
        home: Target24PlayPage(level: _level(1), previousBestScore: 0),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final Target24Puzzle puzzle = Target24Puzzle.forLevel(1);
    final Finder scroll = find.byKey(const ValueKey<String>('target24_scroll'));

    for (final Target24Step step in puzzle.solutionSteps) {
      await tester.drag(scroll, const Offset(0, -2400));
      await tester.pumpAndSettle();
      final Finder operation = find.byKey(
        ValueKey<String>('target24_op_${step.operation.name}'),
      );
      await tester.scrollUntilVisible(
        operation,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(operation);
      await tester.pump();

      for (final Target24Expression operand in <Target24Expression>[
        step.first,
        step.second,
      ]) {
        final Finder card = find.byKey(
          ValueKey<String>(_expressionKey(operand)),
        );
        await tester.scrollUntilVisible(
          card,
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    }

    final Finder check = find.byKey(const ValueKey<String>('target24_check'));
    await tester.scrollUntilVisible(
      check,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();

    expect(find.text('HEDEF YAKALANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet shows the 300-deal level hub', (
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
        home: Target24GamePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Target 24'), findsOneWidget);
    expect(find.textContaining('Target 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

String _expressionKey(Target24Expression expression) => expression.isCard
    ? 'target24_card_${expression.cardId}'
    : 'target24_expression_${expression.signature}';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Hedef ${number.toString().padLeft(3, '0')}',
  titleEn: 'Target ${number.toString().padLeft(3, '0')}',
  subtitleTr: 'Dört kartı birleştir',
  subtitleEn: 'Combine four cards',
  difficulty: 'USTALAŞMA',
  icon: Icons.functions_rounded,
);
