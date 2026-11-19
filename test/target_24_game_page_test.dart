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
    tester.view.physicalSize = const Size(360, 640);
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

    for (final Target24Step step in puzzle.solutionSteps) {
      final Finder operation = find.byKey(
        ValueKey<String>('target24_op_${step.operation.name}'),
      );
      expect(operation, findsOneWidget);
      await tester.tap(operation);
      await tester.pump();

      for (final Target24Expression operand in <Target24Expression>[
        step.first,
        step.second,
      ]) {
        final Finder card = find.byKey(
          ValueKey<String>(_expressionKey(operand)),
        );
        expect(card, findsOneWidget);
        await tester.tap(card);
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    }

    final Finder check = find.byKey(const ValueKey<String>('target24_check'));
    expect(check, findsOneWidget);
    await tester.tap(check);
    await tester.pumpAndSettle();

    expect(find.text('HEDEF YAKALANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English tablet shows the level hub', (
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
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Target Number'), findsOneWidget);
    expect(find.textContaining('Target 01'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

String _expressionKey(Target24Expression expression) => expression.isCard
    ? 'target24_card_${expression.cardId}'
    : 'target24_expression_${expression.signature}';

ParkurLevelSpec _level(int number) => ParkurLevelSpec(
  number: number,
  titleTr: 'Hedef 24',
  titleEn: 'Target 24',
  subtitleTr: 'Dört kartı birleştir',
  subtitleEn: 'Combine four cards',
  difficulty: 'USTALAŞMA',
  icon: Icons.functions_rounded,
);
