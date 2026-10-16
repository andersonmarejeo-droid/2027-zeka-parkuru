import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/secret_room_party/secret_room_engine.dart';
import 'package:zeka_parkuru/games/secret_room_party/secret_room_scenario.dart';

void main() {
  test(
    'private role card disappears before the next player receives device',
    () {
      final SecretRoomEngine engine = SecretRoomEngine(
        scenario: SecretRoomScenario.forLevel(4, playerCount: 3),
      );
      expect(engine.phase, SecretRoomPhase.roleHandoff);
      expect(engine.revealRole(), isTrue);
      expect(engine.roleCardVisible, isTrue);
      expect(engine.hideAndPass(), isTrue);
      expect(engine.roleCardVisible, isFalse);
      expect(engine.activePlayer, 1);
      expect(engine.phase, SecretRoomPhase.roleHandoff);
      for (int player = 1; player < 3; player++) {
        expect(engine.revealRole(), isTrue);
        expect(engine.hideAndPass(), isTrue);
      }
      expect(engine.phase, SecretRoomPhase.discussion);
      expect(engine.roleCardVisible, isFalse);
    },
  );

  test(
    'one sealed vote per player; results stay hidden until final ballot',
    () {
      final SecretRoomEngine engine = SecretRoomEngine(
        scenario: SecretRoomScenario.forLevel(1, playerCount: 4),
      );
      for (int player = 0; player < 4; player++) {
        engine.revealRole();
        engine.hideAndPass();
      }
      expect(engine.startVoting(), isTrue);
      final List<int> votes = <int>[1, 0, 1, 0];
      for (int voter = 0; voter < 4; voter++) {
        expect(engine.openBallot(), isTrue);
        expect(engine.submitVote(voter), isFalse);
        expect(engine.submitVote(votes[voter]), isTrue);
        if (voter < 3) expect(engine.revealedVotes, isEmpty);
        if (voter < 3) expect(engine.phase, SecretRoomPhase.voteHandoff);
      }
      expect(engine.phase, SecretRoomPhase.result);
      expect(engine.revealedVotes, votes);
      expect(engine.outcome!.isTie, isTrue);
      expect(engine.outcome!.suspect, isNull);
      expect(engine.outcome!.crewWon, isFalse);
    },
  );

  test('crew wins only when a unique saboteur gets the strict majority', () {
    final SecretRoomScenario scenario = SecretRoomScenario.forLevel(
      8,
      playerCount: 3,
    );
    final int saboteur = scenario.playerCards.indexWhere(
      (card) => card.isSaboteur,
    );
    final SecretRoomEngine engine = SecretRoomEngine(scenario: scenario);
    for (int player = 0; player < 3; player++) {
      engine.revealRole();
      engine.hideAndPass();
    }
    engine.startVoting();
    for (int voter = 0; voter < 3; voter++) {
      engine.openBallot();
      final int suspect = voter == saboteur ? (saboteur + 1) % 3 : saboteur;
      expect(engine.submitVote(suspect), isTrue);
    }
    expect(engine.outcome!.suspect, saboteur);
    expect(engine.outcome!.voteCount, 2);
    expect(engine.outcome!.crewWon, isTrue);
  });
}
