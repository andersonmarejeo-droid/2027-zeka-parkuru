import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/deckforge_duel/deckforge_engine.dart';
import 'package:zeka_parkuru/games/deckforge_duel/deckforge_scenario.dart';

double _tacticalValue(DeckforgeBattleEngine engine, DeckforgeCard card) {
  final DeckforgeCardRule rule = card.rule;
  final DeckforgeIntent intent = engine.opponentIntent;
  final double healthPressure = engine.playerHealth <= 15 ? 2.5 : 1;
  final double finishingPressure = engine.opponentHealth <= 14 ? 1.35 : 1;
  double value = rule.damage * 2.1 * finishingPressure;
  value += rule.piercing * 2.4;
  value += rule.shield * (intent == DeckforgeIntent.assault ? 1.35 : .15);
  value += rule.heal * (engine.playerHealth <= 15 ? 2.1 : .1) * healthPressure;
  value += rule.counter * (intent == DeckforgeIntent.assault ? 3.2 : .1);
  value += rule.focus * .15;
  value += rule.jam * (intent == DeckforgeIntent.focus ? 1.4 : .2);
  value += rule.energyTax * (engine.playerHealth <= 15 ? 1 : .1);
  return value / rule.cost;
}

int _simulateCampaignLevel(int level) {
  final DeckforgeBattleEngine engine = DeckforgeBattleEngine(
    scenario: DeckforgeScenario.forLevel(level),
    mode: DeckforgeMode.computer,
  );
  while (!engine.isComplete) {
    final List<int> candidates = List<int>.generate(
      engine.visibleHand.length,
      (int index) => index,
    );
    candidates.sort((int a, int b) {
      final int score = _tacticalValue(
        engine,
        engine.visibleHand[b],
      ).compareTo(_tacticalValue(engine, engine.visibleHand[a]));
      return score != 0 ? score : a.compareTo(b);
    });
    int energy = engine.playerEnergy;
    for (final int index in candidates) {
      final DeckforgeCard card = engine.visibleHand[index];
      if (card.rule.cost <= energy && engine.toggleCard(index)) {
        energy -= card.rule.cost;
      }
    }
    engine.sealPlan();
  }
  return engine.outcome == DeckforgeOutcome.playerOne ? 1 : 0;
}

void main() {
  test(
    'plans cannot exceed three energy and an empty plan can pass safely',
    () {
      final DeckforgeBattleEngine engine = DeckforgeBattleEngine(
        scenario: DeckforgeScenario.forLevel(7),
        mode: DeckforgeMode.computer,
      );
      for (int index = 0; index < engine.visibleHand.length; index++) {
        engine.toggleCard(index);
        expect(engine.selectedEnergy, lessThanOrEqualTo(3));
      }
      while (engine.selectedCards.isNotEmpty) {
        engine.undoSelection();
      }
      expect(engine.sealPlan(), isTrue);
      expect(engine.lastReport, isNotNull);
      expect(engine.round, 2);
    },
  );

  test('computer choices do not depend on the player hidden plan', () {
    DeckforgeBattleEngine build() => DeckforgeBattleEngine(
      scenario: DeckforgeScenario.forLevel(9),
      mode: DeckforgeMode.computer,
    );
    final DeckforgeBattleEngine first = build();
    final DeckforgeBattleEngine second = build();
    final List<DeckforgeCard> hand = first.visibleHand;
    final int firstChoice = hand.indexWhere(
      (DeckforgeCard card) => card.rule.damage > 0,
    );
    final int secondChoice = hand.indexWhere(
      (DeckforgeCard card) => card.rule.shield > 0,
    );
    first.toggleCard(firstChoice < 0 ? 0 : firstChoice);
    second.toggleCard(secondChoice < 0 ? 0 : secondChoice);
    expect(first.sealPlan(), isTrue);
    expect(second.sealPlan(), isTrue);
    expect(first.lastComputerCards, isNotEmpty);
    expect(first.lastComputerCards, equals(second.lastComputerCards));
  });

  test(
    'pass-and-play hides both hands and the sealed selection at handoff',
    () {
      final DeckforgeBattleEngine engine = DeckforgeBattleEngine(
        scenario: DeckforgeScenario.forLevel(12),
        mode: DeckforgeMode.local,
      );
      expect(engine.playerHealth, engine.opponentHealth);
      expect(engine.visibleHand, hasLength(5));
      engine.toggleCard(0);
      expect(engine.sealPlan(), isTrue);
      expect(engine.phase, DeckforgePhase.handoff);
      expect(engine.visibleHand, isEmpty);
      expect(engine.selectedCards, isEmpty);
      expect(engine.confirmHandoff(), isTrue);
      expect(engine.currentPlayer, 1);
      expect(engine.visibleHand, hasLength(5));
      engine.toggleCard(0);
      expect(engine.sealPlan(), isTrue);
      expect(engine.lastReport, isNotNull);
      expect(engine.round, 2);
      expect(engine.playerHealth, lessThan(38));
      expect(engine.opponentHealth, lessThan(38));
    },
  );

  test('energy pressure never traps the player in a non-committable state', () {
    final DeckforgeBattleEngine engine = DeckforgeBattleEngine(
      scenario: DeckforgeScenario.forPractice(154),
      mode: DeckforgeMode.computer,
    );
    for (int turn = 0; turn < 12 && !engine.isComplete; turn++) {
      if (engine.visibleHand.isNotEmpty) {
        engine.toggleCard(0);
      }
      expect(engine.sealPlan(), isTrue);
    }
    expect(engine.isComplete, isTrue);
    expect(engine.outcome, isNotNull);
  });

  test(
    'the campaign eases in, then punishes shallow tactics at expert tiers',
    () {
      final List<int> wins = List<int>.generate(
        DeckforgeScenario.campaignLevels,
        (int index) => _simulateCampaignLevel(index + 1),
      );
      expect(wins.take(6), everyElement(1));
      expect(
        wins.skip(6).take(4).where((int result) => result == 1),
        isNotEmpty,
      );
      expect(wins.skip(6).take(4), isNot(everyElement(1)));
    },
  );
}
