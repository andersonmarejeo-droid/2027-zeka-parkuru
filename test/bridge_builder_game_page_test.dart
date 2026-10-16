import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/bridge_builder/bridge_builder_game_page.dart';
import 'package:zeka_parkuru/games/bridge_builder/bridge_builder_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('advanced bridge network solves on a compact phone', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: BridgeBuilderPlayPage(
          level: const ParkurLevelSpec(
            number: 1,
            titleTr: 'Ada 1',
            titleEn: 'Network 1',
            subtitleTr: 'Bağla',
            subtitleEn: 'Connect',
            difficulty: 'MÜHENDİS ADAYI',
            icon: Icons.account_tree_rounded,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final Finder boardFinder = find.byKey(
      const ValueKey<String>('bridge_builder_board'),
    );
    await tester.ensureVisible(boardFinder);
    final BridgeBuilderPuzzle puzzle = BridgeBuilderPuzzle.forLevel(1);
    int moveCount = 0;
    for (int linkIndex = 0; linkIndex < puzzle.links.length; linkIndex++) {
      final int bridges = puzzle.solution[linkIndex];
      if (bridges == 0) continue;
      final link = puzzle.links[linkIndex];
      for (int bridge = 0; bridge < bridges; bridge++) {
        final Rect boardRect = tester.getRect(boardFinder);
        final List<Offset> points = BridgeBoardGeometry.positions(
          puzzle,
          boardRect.size,
        );
        final Offset midpoint = (points[link.first] + points[link.second]) / 2;
        await tester.tapAt(boardRect.topLeft + midpoint);
        await tester.pump();
        moveCount++;
        expect(
          find.text('HAMLE $moveCount'),
          findsOneWidget,
          reason: 'link $linkIndex, intended count $bridges',
        );
      }
    }
    final Finder verify = find.byKey(
      const ValueKey<String>('bridge_builder_check'),
    );
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('AĞ TAMAMLANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
