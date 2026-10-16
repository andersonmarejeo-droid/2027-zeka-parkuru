import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/flow_connect/flow_connect_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets(
    'first Flow Connect board completes with two non-crossing paths',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlowConnectPlayPage(
            level: const ParkurLevelSpec(
              number: 1,
              titleTr: 'Bağlantı 1',
              titleEn: 'Connection 1',
              subtitleTr: 'Bağla',
              subtitleEn: 'Connect',
              difficulty: 'BAŞLANGIÇ',
              icon: Icons.device_hub_rounded,
            ),
            previousBestScore: 0,
          ),
        ),
      );
      await tester.pump();

      final Rect board = tester.getRect(
        find.byKey(const ValueKey<String>('flow_connect_board')),
      );
      final double cell = board.width / 5;

      Future<void> drawRow(int row) async {
        final TestGesture gesture = await tester.startGesture(
          Offset(board.left + cell / 2, board.top + cell * (row + .5)),
        );
        for (int column = 1; column < 5; column++) {
          await gesture.moveTo(
            Offset(
              board.left + cell * (column + .5),
              board.top + cell * (row + .5),
            ),
          );
        }
        await gesture.up();
      }

      await drawRow(0);
      await drawRow(4);
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.text('AKIŞ TAMAMLANDI'), findsOneWidget);
      expect(find.text('SONRAKİ'), findsOneWidget);
    },
  );
}
