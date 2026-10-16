import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/secret_room_party/secret_room_scenario.dart';

void main() {
  test('20 authored cases stay fair from three to six players', () {
    for (int level = 1; level <= SecretRoomScenario.campaignLevels; level++) {
      final SecretRoomScenario scenario = SecretRoomScenario.forLevel(level);
      expect(scenario.playerCards, hasLength(4));
      expect(scenario.saboteurCount, 1);
      expect(scenario.requiredVotes, 2);
      expect(scenario.publicEvidenceTr, hasLength(4 - ((level - 1) ~/ 5)));
      expect(scenario.signature(), isNotEmpty);
    }
    for (int players = 3; players <= 6; players++) {
      final SecretRoomScenario scenario = SecretRoomScenario.forLevel(
        20,
        playerCount: players,
      );
      expect(scenario.playerCards, hasLength(players));
      expect(scenario.saboteurCount, 1);
      expect(scenario.requiredVotes, (players + 1) ~/ 2);
      expect(
        scenario.playerCards.map((card) => card.persona).toSet(),
        hasLength(players),
      );
    }
  });

  test(
    '300 practice case and role combinations are deterministic and unique',
    () {
      final List<SecretRoomScenario> cases = <SecretRoomScenario>[
        for (int index = 1; index <= SecretRoomScenario.practiceCases; index++)
          SecretRoomScenario.forPractice(index, playerCount: 5),
      ];
      expect(
        cases.map((scenario) => scenario.signature()).toSet(),
        hasLength(300),
      );
      for (int index = 1; index <= 300; index++) {
        expect(
          SecretRoomScenario.forPractice(index, playerCount: 5).signature(),
          cases[index - 1].signature(),
        );
      }
    },
  );

  test('player count and case index are guarded', () {
    expect(
      () => SecretRoomScenario.forLevel(1, playerCount: 2),
      throwsRangeError,
    );
    expect(() => SecretRoomScenario.forLevel(21), throwsRangeError);
    expect(() => SecretRoomScenario.forPractice(301), throwsRangeError);
  });
}
