import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/content_seed.dart';
import 'package:zeka_parkuru/games/shared/studio_game_session.dart';

void main() {
  test('session ignores taps while paused and cannot complete twice', () {
    final StudioGameSession session = StudioGameSession(level: 3, seed: 42);
    session.start();
    expect(session.recordAccepted(points: 120), isTrue);
    session.pause();
    expect(session.recordMistake(), isFalse);
    session.resume();

    final StudioGameResult result = session.complete(
      stars: 4,
      action: StudioResultAction.next,
    );
    expect(result.completed, isTrue);
    expect(result.stars, 3);
    expect(result.score, 120);
    expect(session.complete(stars: 3).completed, isFalse);
  });

  test('hint use is capped at three per level', () {
    final StudioGameSession session = StudioGameSession(level: 3, seed: 42)
      ..start();

    expect(session.remainingHints, 3);
    expect(session.useHint(), isTrue);
    expect(session.useHint(), isTrue);
    expect(session.useHint(), isTrue);
    expect(session.useHint(), isFalse);
    expect(session.hintsUsed, 3);
    expect(session.remainingHints, 0);
  });

  test('custom hint cap supports the atlas six-step clue ladder', () {
    final StudioGameSession session = StudioGameSession(
      level: 1,
      seed: 7,
      maxHints: 6,
    )..start();

    for (int hint = 0; hint < 6; hint++) {
      expect(session.useHint(), isTrue);
    }
    expect(session.useHint(), isFalse);
    expect(session.hintsUsed, 6);
    expect(session.remainingHints, 0);
  });

  test(
    'result routes normalize values for the established Parkur contract',
    () {
      final StudioGameResult result = StudioGameResult.completed(
        score: -20,
        stars: 9,
        action: StudioResultAction.replay,
      );

      final parkur = result.toParkurResult();
      expect(parkur.completed, isTrue);
      expect(parkur.score, 0);
      expect(parkur.stars, 3);
      expect(parkur.replayLevel, isTrue);
      expect(parkur.nextLevel, isFalse);
    },
  );

  test('content seed reproduces the same level and changes by attempt', () {
    expect(
      ContentSeed.forLevel(gameId: 'flow_connect', level: 4),
      ContentSeed.forLevel(gameId: 'flow_connect', level: 4),
    );
    expect(
      ContentSeed.forLevel(gameId: 'flow_connect', level: 4),
      isNot(ContentSeed.forLevel(gameId: 'flow_connect', level: 4, attempt: 1)),
    );
  });
}
