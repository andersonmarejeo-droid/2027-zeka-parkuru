import 'dart:math' as math;

import 'deckforge_scenario.dart';

enum DeckforgeMode { computer, local }

enum DeckforgePhase { planning, handoff, finished }

enum DeckforgeOutcome { playerOne, playerTwo, draw }

class DeckforgeRoundReport {
  const DeckforgeRoundReport({
    required this.round,
    required this.playerOneCards,
    required this.playerTwoCards,
    required this.playerOneDamage,
    required this.playerTwoDamage,
    required this.playerOneHealth,
    required this.playerTwoHealth,
  });

  final int round;
  final List<DeckforgeCard> playerOneCards;
  final List<DeckforgeCard> playerTwoCards;
  final int playerOneDamage;
  final int playerTwoDamage;
  final int playerOneHealth;
  final int playerTwoHealth;
}

class _DeckforgeSide {
  _DeckforgeSide(List<DeckforgeCard> deck, this.health)
    : drawPile = List<DeckforgeCard>.from(deck) {
    _drawToFive();
  }

  final List<DeckforgeCard> drawPile;
  final List<DeckforgeCard> hand = <DeckforgeCard>[];
  final List<DeckforgeCard> discard = <DeckforgeCard>[];
  int health;
  int nextEnergyTax = 0;
  int jammedEnergy = 0;

  void _drawToFive() {
    while (hand.length < 5) {
      if (drawPile.isEmpty) {
        if (discard.isEmpty) return;
        drawPile.addAll(discard);
        discard.clear();
      }
      hand.add(drawPile.removeAt(0));
    }
  }

  void discardCards(List<int> indices) {
    final List<int> sorted = List<int>.from(indices)..sort();
    for (final int index in sorted.reversed) {
      discard.add(hand.removeAt(index));
    }
    _drawToFive();
  }
}

class _DeckforgeEffects {
  int damage = 0;
  int piercing = 0;
  int shield = 0;
  int heal = 0;
  int focus = 0;
  int counter = 0;
  int jam = 0;
  int energyTax = 0;

  void add(DeckforgeCard card) {
    final DeckforgeCardRule rule = card.rule;
    damage += rule.damage;
    piercing += rule.piercing;
    shield += rule.shield;
    heal += rule.heal;
    focus += rule.focus;
    counter += rule.counter;
    jam += rule.jam;
    energyTax += rule.energyTax;
  }
}

/// Simultaneous-planning duel. During handoff the other player's hand and
/// sealed cards are never exposed through the public view.
class DeckforgeBattleEngine {
  DeckforgeBattleEngine({required this.scenario, required this.mode})
    : _sides = <_DeckforgeSide>[
        _DeckforgeSide(scenario.playerDeck, scenario.playerHealth),
        _DeckforgeSide(
          scenario.opponentDeck,
          mode == DeckforgeMode.local
              ? scenario.playerHealth
              : scenario.opponentHealth,
        ),
      ];

  final DeckforgeScenario scenario;
  final DeckforgeMode mode;
  final List<_DeckforgeSide> _sides;
  final List<List<int>> _sealedIndices = <List<int>>[<int>[], <int>[]];
  List<int> _selection = <int>[];
  List<DeckforgeCard> lastComputerCards = const <DeckforgeCard>[];
  DeckforgeRoundReport? lastReport;
  DeckforgeOutcome? outcome;
  DeckforgePhase phase = DeckforgePhase.planning;
  int round = 1;
  int currentPlayer = 0;
  int mistakeCount = 0;
  bool get isComplete => phase == DeckforgePhase.finished;
  int get playerHealth => _sides[0].health;
  int get opponentHealth => _sides[1].health;
  int get playerEnergy => _energyFor(0);
  int get opponentEnergy => _energyFor(1);
  DeckforgeIntent get opponentIntent =>
      scenario.intentPattern[(round - 1) % scenario.intentPattern.length];
  List<DeckforgeCard> get visibleHand => phase == DeckforgePhase.planning
      ? List<DeckforgeCard>.unmodifiable(_sides[currentPlayer].hand)
      : const <DeckforgeCard>[];
  List<int> get selectedHandIndices => List<int>.unmodifiable(_selection);
  List<DeckforgeCard> get selectedCards => List<DeckforgeCard>.unmodifiable(
    _selection.map((int index) => _sides[currentPlayer].hand[index]),
  );
  int get selectedEnergy => selectedCards.fold<int>(
    0,
    (int total, DeckforgeCard card) => total + card.rule.cost,
  );

  int _energyFor(int side) {
    final int cap = mode == DeckforgeMode.computer && side == 1
        ? scenario.opponentEnergyCap
        : 3;
    return math.max(
      1,
      cap - _sides[side].jammedEnergy - _sides[side].nextEnergyTax,
    );
  }

  bool toggleCard(int handIndex) {
    if (phase != DeckforgePhase.planning ||
        handIndex < 0 ||
        handIndex >= _sides[currentPlayer].hand.length) {
      return false;
    }
    if (_selection.contains(handIndex)) {
      _selection.remove(handIndex);
      return true;
    }
    final DeckforgeCard card = _sides[currentPlayer].hand[handIndex];
    if (selectedEnergy + card.rule.cost > _energyFor(currentPlayer)) {
      mistakeCount++;
      return false;
    }
    _selection.add(handIndex);
    return true;
  }

  bool undoSelection() {
    if (phase != DeckforgePhase.planning || _selection.isEmpty) return false;
    _selection.removeLast();
    return true;
  }

  bool sealPlan() {
    if (phase != DeckforgePhase.planning) return false;
    _sealedIndices[currentPlayer] = List<int>.from(_selection);
    _selection = <int>[];
    if (mode == DeckforgeMode.computer) {
      final List<int> computerPlan = _chooseComputerPlan();
      _sealedIndices[1] = computerPlan;
      lastComputerCards = List<DeckforgeCard>.unmodifiable(
        computerPlan.map((int index) => _sides[1].hand[index]),
      );
      _resolveRound();
      return true;
    }
    if (currentPlayer == 0) {
      currentPlayer = 1;
      phase = DeckforgePhase.handoff;
      return true;
    }
    _resolveRound();
    return true;
  }

  bool confirmHandoff() {
    if (phase != DeckforgePhase.handoff) return false;
    phase = DeckforgePhase.planning;
    return true;
  }

  List<int> _chooseComputerPlan() {
    final List<int> available = List<int>.generate(
      _sides[1].hand.length,
      (int index) => index,
    );
    final DeckforgeIntent intent = opponentIntent;
    available.sort((int a, int b) {
      final DeckforgeCard cardA = _sides[1].hand[a];
      final DeckforgeCard cardB = _sides[1].hand[b];
      final int score = _botScore(
        cardB,
        intent,
      ).compareTo(_botScore(cardA, intent));
      return score != 0 ? score : a.compareTo(b);
    });
    int energy = _energyFor(1);
    final List<int> plan = <int>[];
    for (final int index in available) {
      final int cost = _sides[1].hand[index].rule.cost;
      if (cost <= energy) {
        plan.add(index);
        energy -= cost;
      }
    }
    return plan;
  }

  int _botScore(DeckforgeCard card, DeckforgeIntent intent) {
    final DeckforgeCardRule rule = card.rule;
    final int aggression = rule.damage * 3 + rule.piercing * 2 + rule.jam;
    final int defense = rule.shield * 2 + rule.heal * 2 + rule.counter * 3;
    final int setup = rule.focus * 2 + rule.energyTax;
    return switch (intent) {
              DeckforgeIntent.assault => aggression + defense ~/ 3 + setup ~/ 2,
              DeckforgeIntent.guard => defense + aggression ~/ 2,
              DeckforgeIntent.focus =>
                setup * 2 + aggression ~/ 2 + defense ~/ 3,
            } *
            10 -
        rule.cost;
  }

  void _resolveRound() {
    final List<DeckforgeCard> cardsOne = _cardsFor(0);
    final List<DeckforgeCard> cardsTwo = _cardsFor(1);
    final _DeckforgeEffects one = _effects(cardsOne);
    final _DeckforgeEffects two = _effects(cardsTwo);
    final int attackOnOne = _incoming(two, one);
    final int attackOnTwo = _incoming(one, two);
    final int oldOne = _sides[0].health;
    final int oldTwo = _sides[1].health;
    final int healedOne = math.min(scenario.playerHealth, oldOne + one.heal);
    final int healedTwo = math.min(
      mode == DeckforgeMode.local
          ? scenario.playerHealth
          : scenario.opponentHealth,
      oldTwo + two.heal,
    );
    final int counterOnOne = one.counter > 0 && two.damage > 0
        ? one.counter
        : 0;
    final int counterOnTwo = two.counter > 0 && one.damage > 0
        ? two.counter
        : 0;
    _sides[0].health = math.max(0, healedOne - attackOnOne - counterOnTwo);
    _sides[1].health = math.max(0, healedTwo - attackOnTwo - counterOnOne);
    _sides[0].jammedEnergy = two.jam;
    _sides[1].jammedEnergy = one.jam;
    _sides[0].nextEnergyTax = one.energyTax;
    _sides[1].nextEnergyTax = two.energyTax;
    _sides[0].discardCards(_sealedIndices[0]);
    _sides[1].discardCards(_sealedIndices[1]);
    lastReport = DeckforgeRoundReport(
      round: round,
      playerOneCards: List<DeckforgeCard>.unmodifiable(cardsOne),
      playerTwoCards: List<DeckforgeCard>.unmodifiable(cardsTwo),
      playerOneDamage: attackOnOne + counterOnTwo,
      playerTwoDamage: attackOnTwo + counterOnOne,
      playerOneHealth: _sides[0].health,
      playerTwoHealth: _sides[1].health,
    );
    _sealedIndices[0] = <int>[];
    _sealedIndices[1] = <int>[];
    if (_sides[0].health == 0 || _sides[1].health == 0 || round >= 12) {
      outcome = switch (_sides[0].health.compareTo(_sides[1].health)) {
        > 0 => DeckforgeOutcome.playerOne,
        < 0 => DeckforgeOutcome.playerTwo,
        _ => DeckforgeOutcome.draw,
      };
      phase = DeckforgePhase.finished;
      return;
    }
    round++;
    currentPlayer = 0;
    phase = DeckforgePhase.planning;
  }

  List<DeckforgeCard> _cardsFor(int side) => List<DeckforgeCard>.unmodifiable(
    _sealedIndices[side].map((int index) => _sides[side].hand[index]),
  );

  _DeckforgeEffects _effects(List<DeckforgeCard> cards) {
    final _DeckforgeEffects effects = _DeckforgeEffects();
    for (final DeckforgeCard card in cards) {
      effects.add(card);
    }
    if (effects.damage > 0 && effects.focus > 0) {
      effects.damage += math.min(6, effects.focus * 2);
    }
    return effects;
  }

  int _incoming(_DeckforgeEffects attack, _DeckforgeEffects defense) {
    if (attack.damage <= 0) return 0;
    final int bypass = math.min(attack.damage, attack.piercing);
    final int blocked = math.min(defense.shield, attack.damage - bypass);
    return attack.damage - blocked;
  }
}
