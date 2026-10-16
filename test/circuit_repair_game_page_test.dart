import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/circuit_repair/circuit_repair_game_page.dart';
import 'package:zeka_parkuru/games/circuit_repair/circuit_repair_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('first Circuit Repair board reaches its energy result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CircuitRepairPlayPage(
          level: const ParkurLevelSpec(
            number: 1,
            titleTr: 'Devre 1',
            titleEn: 'Circuit 1',
            subtitleTr: 'Onar',
            subtitleEn: 'Repair',
            difficulty: 'BAŞLANGIÇ',
            icon: Icons.electric_bolt_rounded,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();

    final CircuitPuzzle puzzle = CircuitPuzzle.forLevel(1);
    final Rect board = tester.getRect(
      find.byKey(const ValueKey<String>('circuit_repair_board')),
    );
    final double cell = board.width / puzzle.size;
    for (int index = 0; index < puzzle.cellCount; index++) {
      final int turns = puzzle.tiles[index].isEmpty
          ? 0
          : (4 - puzzle.tiles[index].initialTurns) % 4;
      for (int count = 0; count < turns; count++) {
        await tester.tapAt(
          Offset(
            board.left + (index % puzzle.size + .5) * cell,
            board.top + (index ~/ puzzle.size + .5) * cell,
          ),
        );
        await tester.pump();
      }
    }
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('DEVRE ÇALIŞIYOR'), findsOneWidget);
  });
}
