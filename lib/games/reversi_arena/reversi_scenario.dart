import 'dart:math' as math;

import '../shared/content_seed.dart';
import 'reversi_engine.dart';

/// Twenty reproducible mid-game starts, each reached only through legal play
/// from the standard Othello opening. Color orientation keeps the learner dark.
class ReversiScenario {
  const ReversiScenario({
    required this.level,
    required this.chapter,
    required this.stageInChapter,
    required this.position,
    required this.openingMoves,
    required this.seed,
  });

  static const int maximumLevels = 20;
  static final List<ReversiScenario> _campaign = _buildCampaign();
  static final List<ReversiScenario> _pool = _buildCampaign(
    count: 300,
    pool: true,
  );
  static ReversiScenario forPool(int index) {
    RangeError.checkValueInInterval(index, 1, 300, 'index');
    return _pool[index - 1];
  }

  final int level;
  final int chapter;
  final int stageInChapter;
  final ReversiPosition position;
  final int openingMoves;
  final int seed;

  int get difficulty => level;
  String get boardSignature => position.signature;
  String get difficultyTier => switch (stageInChapter) {
    <= 6 => chapter == 1 ? 'USTALAŞMA' : 'İLERİ',
    <= 8 => 'İLERİ',
    _ => 'UZMAN',
  };

  static ReversiScenario forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, 20);
    }
    return _campaign[level - 1];
  }

  static List<ReversiScenario> _buildCampaign({
    int count = maximumLevels,
    bool pool = false,
  }) {
    final List<ReversiScenario> scenarios = <ReversiScenario>[];
    final Set<String> signatures = <String>{};
    for (int index = 1; index <= count; index++) {
      final int level = pool ? (index - 1) % maximumLevels + 1 : index;
      final int targetPlacements = 4 + 4 + level;
      ReversiScenario? accepted;
      for (int attempt = 0; attempt < 128; attempt++) {
        final math.Random random = ContentSeed.randomFor(
          gameId: pool ? 'reversi_arena:pool' : 'reversi_arena',
          level: index,
          attempt: attempt,
        );
        ReversiPosition position = ReversiPosition.standard();
        int actualOpeningMoves = 0;
        while (position.occupiedCount < targetPlacements &&
            !position.isTerminal &&
            actualOpeningMoves < 56) {
          final List<int> moves = position.legalMoves();
          if (moves.isEmpty) {
            position = resolveReversiTurn(position).position;
            continue;
          }
          position = resolveReversiTurn(
            position.play(moves[random.nextInt(moves.length)]),
          ).position;
          actualOpeningMoves++;
        }
        if (position.isTerminal) continue;

        // A color swap is a valid symmetry: it preserves the board and turn
        // rules while ensuring a consistent human-vs-engine orientation.
        if (position.toMove == ReversiStone.light) {
          position = ReversiPosition(
            board: position.board.map((int stone) => -stone).toList(),
            toMove: ReversiStone.dark,
          );
        }
        final String signature = position.signature;
        if (!signatures.add(signature)) continue;
        accepted = ReversiScenario(
          level: level,
          chapter: (level - 1) ~/ 10 + 1,
          stageInChapter: (level - 1) % 10 + 1,
          position: position,
          openingMoves: actualOpeningMoves,
          seed: ContentSeed.forLevel(
            gameId: pool ? 'reversi_arena:pool' : 'reversi_arena',
            level: index,
            attempt: attempt,
          ),
        );
        break;
      }
      if (accepted == null) {
        throw StateError('Could not build distinct Reversi board $level.');
      }
      scenarios.add(accepted);
    }
    return List<ReversiScenario>.unmodifiable(scenarios);
  }
}
