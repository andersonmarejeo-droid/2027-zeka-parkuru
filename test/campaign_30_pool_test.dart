import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/services/unified_progress_service.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';
import 'package:zeka_parkuru/games/shared/campaign_round_store.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/hanoi/hanoi_game_page.dart';
import 'package:zeka_parkuru/games/hidden_masses/hidden_masses_puzzle.dart';
import 'package:zeka_parkuru/games/kakuro/kakuro_puzzle.dart';
import 'package:zeka_parkuru/games/word_wheel/word_wheel_puzzle.dart';
import 'package:zeka_parkuru/games/reversi_arena/reversi_scenario.dart';
import 'package:zeka_parkuru/games/mine_detector/mine_detector_puzzle.dart';
import 'package:zeka_parkuru/games/kenken_cube/kenken_cube_puzzle.dart';
import 'package:zeka_parkuru/games/mini_sudoku/mini_sudoku_puzzle.dart';
import 'package:zeka_parkuru/games/balance_scale/balance_scale_puzzle.dart';
import 'package:zeka_parkuru/games/target_24/target_24_puzzle.dart';
import 'package:zeka_parkuru/games/parking_puzzle/parking_puzzle.dart';
import 'package:zeka_parkuru/games/reference_games/katamino_puzzle.dart';
import 'package:zeka_parkuru/games/reference_games/single_stroke_puzzle.dart';
import 'package:zeka_parkuru/games/reference_games/arrow_maze_puzzle.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  test(
    'active campaigns use 30 chapters and unique game-specific pool addresses',
    () {
      expect(
        GameContentPolicy.standardGames,
        StudioGameCatalog.games
            .where((game) => game.isPlayable)
            .map((game) => game.id)
            .toSet(),
      );
      for (final id in GameContentPolicy.standardGames) {
        final stages = GameContentPolicy.nativeStages(id);
        final int poolSize = id == 'word_wheel'
            ? GameContentPolicy.wordWheelPoolSize
            : GameContentPolicy.minimumUniqueRounds;
        final all = <int>{};
        int lastStage = 0;
        for (int chapter = 1; chapter <= 30; chapter++) {
          final entries = List.generate(
            GameContentPolicy.variantsForChapter(id, chapter),
            (variant) =>
                GameContentPolicy.poolIndexForGame(
                  id,
                  chapter,
                  variant,
                  stages: stages,
                ),
          );
          expect(
            entries.toSet(),
            hasLength(GameContentPolicy.variantsForChapter(id, chapter)),
            reason: '$id chapter $chapter',
          );
          for (final index in entries) {
            expect(
              all.add(index),
              isTrue,
              reason: '$id chapter $chapter overlaps',
            );
            final stage = id == 'word_wheel'
                ? WordWheelPuzzle.forPool(index).stageInChapter
                : (index - 1) % stages + 1;
            expect(
              stage,
              greaterThanOrEqualTo(lastStage),
              reason: '$id gets easier at $chapter',
            );
            lastStage = stage;
          }
        }
        expect(all, {for (int i = 1; i <= poolSize; i++) i});
      }
    },
  );

  test(
    'persisted chapter cursor consumes each chapter variant before wrapping',
    () async {
      for (final id in GameContentPolicy.standardGames) {
        final int variants = GameContentPolicy.variantsForChapter(id, 30);
        final values = <int>[];
        for (int i = 0; i <= variants; i++) {
          values.add(await CampaignRoundStore.reserve(id, 30));
        }
        expect(values.take(variants).toSet(), hasLength(variants), reason: id);
        expect(values.last, values.first, reason: id);
      }
    },
  );

  test(
    '300-unlocked migration opens the visible 30 and keeps archived scores',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('kakuro_unlocked_level', 300);
      final stars = List.generate(
        300,
        (i) => i < 6
            ? '3'
            : i == 250
            ? '2'
            : '0',
      );
      final scores = List.generate(300, (i) => '${i * 10}');
      await prefs.setStringList('kakuro_stars', stars);
      await prefs.setStringList('kakuro_best_scores', scores);
      final store = ParkurProgressStore(prefix: 'kakuro', levelCount: 30);
      final progress = await store.load();
      expect(progress.unlockedLevel, 30);
      expect(progress.stars, hasLength(30));
      expect(progress.bestScores[29], 290);
      await store.save(progress);
      expect((await prefs.getStringList('kakuro_stars'))![250], '2');
      expect((await prefs.getStringList('kakuro_best_scores'))![299], '2990');
      expect((await store.load()).unlockedLevel, 30);
    },
  );

  test(
    'active campaign totals include all 44 games and preserve retired awards',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setStringList('number_yildizlar', List.filled(30, '3'));
      await prefs.setStringList('kenken_cube_stars', ['2']);
      await prefs.setInt('kenken_cube_unlocked_level', 300);
      await prefs.setStringList('logic_yildizlar', ['3']);
      await prefs.setStringList('candy_sort_stars', ['2']);
      final data = await UnifiedProgressService().genelIlerlemeyiYukle();
      // The legacy Mantık parkur remains in lifetime totals, while the
      // active 44-game campaign has Şeker Sıralama in the fixed set.
      expect(data.parkurlar, hasLength(45));
      expect(data.additionalGames, hasLength(34));
      expect(
        data.additionalGames.every((game) => game.yildizlar.length == 30),
        isTrue,
      );
      expect(data.toplamYildiz, 97);
      expect(data.kampanyaYildizlari, 92);
      expect(data.tamamlananSeviye, 33);
      expect(data.kampanyaTamamlananSeviye, 31);
      expect(UnifiedProgressData.maksimumSeviye, 1320);
      expect(UnifiedProgressData.maksimumYildiz, 3960);
      expect(data.genelIlerlemeOrani, closeTo(92 / 3960, .000001));
      expect(await prefs.getStringList('logic_yildizlar'), ['3']);
    },
  );

  test(
    'Hanoi has 300 legal, distinct boards with monotonic optimal distances',
    () {
      final signatures = <String>{};
      int previous = 0;
      for (int i = 1; i <= 300; i++) {
        final board = HanoiCampaignBoard.forPool(i);
        expect(signatures.add(board.signature), isTrue, reason: 'Hanoi $i');
        expect(board.optimalMoves, greaterThanOrEqualTo(previous));
        expect(
          HanoiSolver.minimumMoves(
            pegs: board.pegs,
            diskCount: board.diskCount,
            targetPeg: board.targetPeg,
          ),
          board.optimalMoves,
        );
        previous = board.optimalMoves;
      }
    },
  );

  final factories = <String, String Function(int)>{
    'hidden_masses': (i) => HiddenMassPuzzle.forPool(i).boardSignature,
    'kakuro': (i) => KakuroPuzzle.forPool(i).boardSignature,
    'word_wheel_tr': (i) => WordWheelPuzzle.forPool(i).boardSignature,
    'word_wheel_en': (i) =>
        WordWheelPuzzle.forPool(i, languageCode: 'en').boardSignature,
    'reversi': (i) => ReversiScenario.forPool(i).boardSignature,
    'mine_detective': (i) => MineDetectorPuzzle.forLevel(i).boardSignature,
    'kenken': (i) => KenKenPuzzle.forLevel(i).boardSignature,
    'mini_sudoku': (i) => MiniSudokuPuzzle.forLevel(i).boardSignature,
    'balance_scale': (i) => BalanceScalePuzzle.forLevel(i).boardSignature,
    'target_24': (i) => Target24Puzzle.forLevel(i).boardSignature,
    'parking': (i) => ParkingPuzzle.forLevel(i).boardSignature,
    'katamino': (i) => KataminoPuzzle.generate((i - 1) % 10 + 1, i).signature,
    'single_stroke': (i) =>
        SingleStrokePuzzle.generate((i - 1) % 10 + 1, i).signature,
    'arrow_maze': (i) =>
        ArrowMazePuzzle.generate((i - 1) % 10 + 1, i).signature,
  };
  for (final entry in factories.entries) {
    final int expectedSize = entry.key.startsWith('word_wheel_') ? 700 : 300;
    test('${entry.key}: all $expectedSize playable content signatures are unique', () {
      final watch = Stopwatch()..start();
      final signatures = <String>{};
      for (int i = 1; i <= expectedSize; i++) {
        expect(
          signatures.add(entry.value(i)),
          isTrue,
          reason: '${entry.key} content $i',
        );
      }
      expect(signatures, hasLength(expectedSize));
      // Visible in the QA report to catch unexpectedly expensive banks.
      // ignore: avoid_print
      print('${entry.key}: $expectedSize entries in ${watch.elapsedMilliseconds} ms');
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
