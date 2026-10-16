import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/beam_director/beam_director_game_page.dart';
import 'package:zeka_parkuru/games/beam_director/beam_director_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('first Beam Director board reaches its light result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BeamDirectorPlayPage(
          level: const ParkurLevelSpec(
            number: 1,
            titleTr: 'Işın 1',
            titleEn: 'Beam 1',
            subtitleTr: 'Yönlendir',
            subtitleEn: 'Direct',
            difficulty: 'BAŞLANGIÇ',
            icon: Icons.light_mode_rounded,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();

    final BeamDirectorPuzzle puzzle = BeamDirectorPuzzle.forLevel(1);
    final Rect board = tester.getRect(
      find.byKey(const ValueKey<String>('beam_director_board')),
    );
    final double cell = board.width / puzzle.width;
    for (int index = 0; index < puzzle.mirrors.length; index++) {
      if (puzzle.initialStates[index] == puzzle.solvedStates[index]) continue;
      final int mirrorCell = puzzle.mirrors[index].cell;
      await tester.tapAt(
        Offset(
          board.left + (mirrorCell % puzzle.width + .5) * cell,
          board.top + (mirrorCell ~/ puzzle.width + .5) * cell,
        ),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('IŞIN HEDEFTE'), findsOneWidget);
  });
}
