import 'dart:math' as math;

import '../shared/content_seed.dart';
import 'tavla_engine.dart';

class TavlaScenario {
  const TavlaScenario({
    required this.level,
    required this.seed,
    required this.position,
    required this.sideToMove,
    required this.dieA,
    required this.dieB,
    required this.playedTurns,
  });

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static final Map<int, TavlaScenario> _campaign = <int, TavlaScenario>{};
  static final Map<int, TavlaScenario> _practice = <int, TavlaScenario>{};

  final int level;
  final int seed;
  final TavlaPosition position;
  final int sideToMove;
  final int dieA;
  final int dieB;
  final int playedTurns;

  String get signature => '${position.signature}|$sideToMove|$dieA,$dieB';

  String get difficultyTier {
    if (level <= 6) return 'MASTERY';
    if (level <= 8) return 'ADVANCED';
    if (level <= 16) return 'EXPERT';
    return 'MASTER';
  }

  static TavlaScenario forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return _campaign.putIfAbsent(level, () => _generate(level));
  }

  /// 300 reachable, distinct training positions for replayed levels.
  static TavlaScenario forPracticeBoard(int index) {
    if (index < 1 || index > maximumVerifiedBoards) {
      throw RangeError.range(index, 1, maximumVerifiedBoards, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      _campaign.putIfAbsent(level, () => _generate(level));
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      TavlaScenario? accepted;
      for (int cycle = next; accepted == null; cycle++) {
        final TavlaScenario candidate = _generate(
          level,
          contentCycle: 1000 + cycle,
        );
        final bool repeated = <TavlaScenario>[
          ..._campaign.values,
          ..._practice.values,
        ].any((TavlaScenario prior) => prior.signature == candidate.signature);
        if (!repeated) accepted = candidate;
      }
      _practice[next] = accepted;
    }
    return _practice[index]!;
  }

  static TavlaScenario _generate(int level, {int contentCycle = 0}) {
    for (int attempt = 0; attempt < 200; attempt++) {
      final int seed = ContentSeed.forLevel(
        gameId: 'tavla_master:$contentCycle',
        level: level,
        attempt: attempt,
      );
      final math.Random random = math.Random(seed);
      TavlaPosition position = TavlaPosition.standard();
      int side = TavlaSide.white;
      final int turns = 1 + level + contentCycle % 5;
      int playedTurns = 0;
      for (int turn = 0; turn < turns; turn++) {
        final int dieA = random.nextInt(6) + 1;
        final int dieB = random.nextInt(6) + 1;
        final List<List<TavlaMove>> legal = position.legalTurnSequences(
          side,
          dieA,
          dieB,
        );
        final List<TavlaMove> chosen = legal[random.nextInt(legal.length)];
        for (final TavlaMove move in chosen) {
          position = position.play(move, side);
        }
        playedTurns++;
        if (position.whiteWon || position.blackWon) break;
        side = -side;
      }
      if (position.whiteWon || position.blackWon) continue;
      if (side != TavlaSide.white) {
        final int dieA = random.nextInt(6) + 1;
        final int dieB = random.nextInt(6) + 1;
        final List<List<TavlaMove>> legal = position.legalTurnSequences(
          side,
          dieA,
          dieB,
        );
        for (final TavlaMove move in legal[random.nextInt(legal.length)]) {
          position = position.play(move, side);
        }
        playedTurns++;
        side = TavlaSide.white;
      }
      if (position.whiteWon || position.blackWon) continue;
      for (int diceAttempt = 0; diceAttempt < 24; diceAttempt++) {
        final int dieA = random.nextInt(6) + 1;
        final int dieB = random.nextInt(6) + 1;
        final List<List<TavlaMove>> openingMoves = position.legalTurnSequences(
          side,
          dieA,
          dieB,
        );
        if (openingMoves.every((List<TavlaMove> moves) => moves.isEmpty)) {
          continue;
        }
        return TavlaScenario(
          level: level,
          seed: seed,
          position: position,
          sideToMove: side,
          dieA: dieA,
          dieB: dieB,
          playedTurns: playedTurns,
        );
      }
    }
    throw StateError('Could not build a fair Tavla scenario for level $level.');
  }
}
