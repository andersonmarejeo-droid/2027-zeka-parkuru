import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/shared/game_instruction_catalog.dart';

void main() {
  test('every active game has a localized, actionable guide', () {
    final Set<String> activeIds = StudioGameCatalog.games
        .where((game) => game.isPlayable)
        .map((game) => game.id)
        .toSet();

    expect(GameInstructionCatalog.gameIds, activeIds);
    for (final String id in activeIds) {
      final GameInstruction guide = GameInstructionCatalog.forGame(id)!;
      expect(
        guide.summaryTr.length,
        greaterThan(50),
        reason: '$id Turkish summary',
      );
      expect(
        guide.summaryEn.length,
        greaterThan(50),
        reason: '$id English summary',
      );
      expect(guide.stepsTr, hasLength(2), reason: '$id Turkish steps');
      expect(guide.stepsEn, hasLength(2), reason: '$id English steps');
      expect(
        guide.stepsTr.every((step) => step.length > 25),
        isTrue,
        reason: id,
      );
      expect(
        guide.stepsEn.every((step) => step.length > 25),
        isTrue,
        reason: id,
      );
    }
  });

  testWidgets('game guide shows numbered steps before the first level', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GameInstructionCard(
              gameId: 'picross_master',
              english: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('NASIL OYNANIR?'), findsOneWidget);
    expect(
      find.textContaining('Satır ve sütun ipuçlarındaki sayıları'),
      findsOneWidget,
    );
    expect(find.textContaining('Sayılar, ilgili çizgide'), findsOneWidget);
    expect(find.textContaining('DOLDUR ile dolu'), findsOneWidget);

    await tester.tap(find.byType(GameInstructionCard));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sayılar, ilgili çizgide'), findsNothing);
    expect(find.textContaining('DOLDUR ile dolu'), findsNothing);

    await tester.tap(find.byType(GameInstructionCard));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sayılar, ilgili çizgide'), findsOneWidget);
    expect(find.textContaining('DOLDUR ile dolu'), findsOneWidget);
  });
}
