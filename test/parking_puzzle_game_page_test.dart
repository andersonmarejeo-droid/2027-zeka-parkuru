import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/parking_puzzle/parking_puzzle.dart';
import 'package:zeka_parkuru/games/parking_puzzle/parking_puzzle_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('cars slide on a compact phone and the route can be cleared', (
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
        home: ParkingPuzzlePlayPage(
          level: const ParkurLevelSpec(
            number: 1,
            titleTr: 'Parkur 1',
            titleEn: 'Route 1',
            subtitleTr: 'Paket 1 · Aşama 1 / 10',
            subtitleEn: 'Chapter 1 · Stage 1 / 10',
            difficulty: 'PLANLA',
            icon: Icons.directions_car_filled_rounded,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final Size boardSize = tester.getSize(
      find.byKey(const ValueKey<String>('parking_board_surface')),
    );
    expect(boardSize.width / ParkingPuzzle.boardSize, greaterThanOrEqualTo(48));

    final ParkingPuzzle puzzle = ParkingPuzzle.forLevel(1);
    final ParkingMove firstMove = puzzle.solution.first;
    final ParkingVehicle vehicle = puzzle.vehicles[firstMove.vehicleIndex];
    final Finder firstCar = find.byKey(
      ValueKey<String>('parking_vehicle_${firstMove.vehicleIndex}'),
    );
    await tester.ensureVisible(firstCar);
    await tester.pumpAndSettle();
    final Size carSize = tester.getSize(firstCar);
    final double carAxisExtent = vehicle.axis == ParkingAxis.horizontal
        ? carSize.width
        : carSize.height;
    final double cellExtent = carAxisExtent / vehicle.length;
    final double delta =
        (firstMove.toOffset - firstMove.fromOffset) * cellExtent;
    await tester.drag(
      firstCar,
      vehicle.axis == ParkingAxis.horizontal
          ? Offset(delta, 0)
          : Offset(0, delta),
    );
    await tester.pumpAndSettle();
    expect(find.text('HAMLE 1'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (
      int remaining = puzzle.solution.length - 1;
      remaining > 0;
      remaining--
    ) {
      final Finder hint = find.byKey(const ValueKey<String>('parking_hint'));
      await tester.ensureVisible(hint);
      await tester.pumpAndSettle();
      await tester.tap(hint);
      await tester.pump(const Duration(milliseconds: 220));
      if (remaining > 1) await tester.pumpAndSettle();
    }
    await tester.pumpAndSettle();

    expect(find.text('YOL AÇILDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'level hub fits an English tablet and exposes the ten-stage map',
    (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const ParkingPuzzleGamePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parking Puzzle'), findsOneWidget);
      expect(find.textContaining('Route 01'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
