import 'dart:math' as math;

import '../shared/content_seed.dart';
import '../shared/studio_game_contracts.dart';

enum Target24Operator { add, subtract, multiply, divide }

extension Target24OperatorPresentation on Target24Operator {
  String get symbol => switch (this) {
    Target24Operator.add => '+',
    Target24Operator.subtract => '−',
    Target24Operator.multiply => '×',
    Target24Operator.divide => '÷',
  };

  bool get isCommutative =>
      this == Target24Operator.add || this == Target24Operator.multiply;
}

/// "Bir İşlem" oyununda tüm hesaplamalar kesinlikle pozitif tam sayılarla yapılır.
/// Küsüratlı/kesirli sayılara izin verilmez.
class Target24Rational implements Comparable<Target24Rational> {
  factory Target24Rational(int numerator, [int denominator = 1]) {
    if (denominator == 0) throw ArgumentError.value(denominator, 'denominator');
    if (denominator == 1) return Target24Rational._(numerator, 1);
    if (numerator % denominator == 0) {
      return Target24Rational._(numerator ~/ denominator, 1);
    }
    // Tam bölünmeyen durumlarda dahi pozitif tam kısmı korur
    return Target24Rational._(numerator ~/ denominator, 1);
  }

  const Target24Rational._(this.numerator, this.denominator);

  static const Target24Rational zero = Target24Rational._(0, 1);

  final int numerator;
  final int denominator;

  bool get isZero => numerator == 0;
  bool get isInteger => true;

  Target24Rational apply(Target24Operator operation, Target24Rational other) {
    return switch (operation) {
      Target24Operator.add => Target24Rational._(numerator + other.numerator, 1),
      Target24Operator.subtract => () {
        if (numerator <= other.numerator) {
          throw ArgumentError('Çıkarma işlemi pozitif bir tam sayı vermelidir.');
        }
        return Target24Rational._(numerator - other.numerator, 1);
      }(),
      Target24Operator.multiply => Target24Rational._(numerator * other.numerator, 1),
      Target24Operator.divide => () {
        if (other.isZero) {
          throw ArgumentError('Sıfıra bölme yapılamaz.');
        }
        if (numerator % other.numerator != 0) {
          throw ArgumentError('Yalnızca tam bölünen pozitif sayılar bölünebilir.');
        }
        return Target24Rational._(numerator ~/ other.numerator, 1);
      }(),
    };
  }

  @override
  int compareTo(Target24Rational other) => numerator.compareTo(other.numerator);

  @override
  bool operator ==(Object other) =>
      other is Target24Rational && numerator == other.numerator;

  @override
  int get hashCode => numerator.hashCode;

  @override
  String toString() => '$numerator';
}

class Target24Expression {
  const Target24Expression.card({required this.cardId, required this.value})
    : operation = null,
      first = null,
      second = null;

  const Target24Expression.combine({
    required this.operation,
    required this.first,
    required this.second,
    required this.value,
  }) : cardId = null;

  final int? cardId;
  final Target24Operator? operation;
  final Target24Expression? first;
  final Target24Expression? second;
  final Target24Rational value;

  bool get isCard => cardId != null;

  String get signature {
    if (isCard) return 'C$cardId=$value';
    String left = first!.signature;
    String right = second!.signature;
    if (operation!.isCommutative && left.compareTo(right) > 0) {
      final String swap = left;
      left = right;
      right = swap;
    }
    return '($left${operation!.symbol}$right)';
  }

  String expressionText({required bool english}) {
    if (isCard) return value.toString();
    final String left = first!.expressionText(english: english);
    final String right = second!.expressionText(english: english);
    return '($left ${operation!.symbol} $right)';
  }

  List<int> get cardIds =>
      isCard ? <int>[cardId!] : <int>[...first!.cardIds, ...second!.cardIds];
}

class Target24Step {
  const Target24Step({
    required this.first,
    required this.second,
    required this.operation,
    required this.result,
    required this.expressionSignature,
  });

  final Target24Expression first;
  final Target24Expression second;
  final Target24Operator operation;
  final Target24Rational result;
  final String expressionSignature;
}

class Target24Puzzle {
  static const int maximumUniqueCases = 300;
  static const List<String> cardLetters = <String>['A', 'B', 'C', 'D'];
  static final Map<int, Target24Puzzle> _cache = <int, Target24Puzzle>{};

  const Target24Puzzle({
    required this.level,
    required this.localStage,
    required this.maximumCardValue,
    required this.target,
    required this.cards,
    required this.solution,
  });

  final int level;
  final int localStage;
  final int maximumCardValue;
  final Target24Rational target;
  final List<Target24Card> cards;
  final Target24Expression solution;

  int get targetValue => target.numerator;

  String get difficultyTier => switch (localStage) {
    <= 6 => 'MASTERY',
    <= 8 => 'ADVANCED',
    _ => 'EXPERT',
  };

  String get boardSignature =>
      '$targetValue#${cards.map((Target24Card card) => card.value).join('|')}';

  List<Target24Step> get solutionSteps {
    final List<Target24Step> steps = <Target24Step>[];
    void visit(Target24Expression expression) {
      if (expression.isCard) return;
      visit(expression.first!);
      visit(expression.second!);
      steps.add(
        Target24Step(
          first: expression.first!,
          second: expression.second!,
          operation: expression.operation!,
          result: expression.value,
          expressionSignature: expression.signature,
        ),
      );
    }

    visit(solution);
    return List<Target24Step>.unmodifiable(steps);
  }

  bool get hasUniqueSolution => solve().length == 1;

  bool isSolved(Target24Expression expression) {
    final List<int> ids = expression.cardIds;
    return expression.value == target &&
        ids.length == cards.length &&
        ids.toSet().length == cards.length &&
        ids.every((int id) => id >= 0 && id < cards.length) &&
        ids.every(
          (int id) =>
              expression.cardIds.contains(id) &&
              _cardValueForId(expression, id) == cards[id].value,
        );
  }

  int? _cardValueForId(Target24Expression expression, int id) {
    if (expression.isCard) {
      return expression.cardId == id ? expression.value.numerator : null;
    }
    final int? left = _cardValueForId(expression.first!, id);
    return left ?? _cardValueForId(expression.second!, id);
  }

  List<Target24Expression> solve({int limit = 2}) {
    final List<Target24Expression> results = <Target24Expression>[];
    final Set<String> resultSignatures = <String>{};
    final Set<String> visitedStates = <String>{};

    void search(List<Target24Expression> terms) {
      if (results.length >= limit) return;
      if (terms.length == 1) {
        final Target24Expression result = terms.single;
        if (result.value == target && resultSignatures.add(result.signature)) {
          results.add(result);
        }
        return;
      }

      final List<String> stateTerms =
          terms
              .map((Target24Expression expression) => expression.signature)
              .toList()
            ..sort();
      if (!visitedStates.add(stateTerms.join('~'))) return;

      void tryOperation(
        Target24Expression first,
        Target24Expression second,
        Target24Operator operation,
        int usedFirstIndex,
        int usedSecondIndex,
      ) {
        // Tam sayı kuralları: Sıfıra bölme ve kalanlı bölme yapılamaz
        if (operation == Target24Operator.divide) {
          if (second.value.isZero) return;
          if (first.value.numerator % second.value.numerator != 0) return;
        }
        // Çıkarma işlemi pozitif tam sayı vermelidir
        if (operation == Target24Operator.subtract) {
          if (first.value.numerator <= second.value.numerator) return;
        }

        final Target24Expression combined = Target24Expression.combine(
          operation: operation,
          first: first,
          second: second,
          value: first.value.apply(operation, second.value),
        );
        final List<Target24Expression> next = <Target24Expression>[
          for (int index = 0; index < terms.length; index++)
            if (index != usedFirstIndex && index != usedSecondIndex)
              terms[index],
          combined,
        ];
        search(next);
      }

      for (int firstIndex = 0; firstIndex < terms.length; firstIndex++) {
        for (
          int secondIndex = firstIndex + 1;
          secondIndex < terms.length;
          secondIndex++
        ) {
          final Target24Expression first = terms[firstIndex];
          final Target24Expression second = terms[secondIndex];
          for (final Target24Operator operation in Target24Operator.values) {
            tryOperation(first, second, operation, firstIndex, secondIndex);
            if (!operation.isCommutative) {
              tryOperation(second, first, operation, firstIndex, secondIndex);
            }
          }
        }
      }
    }

    search(<Target24Expression>[
      for (final Target24Card card in cards)
        Target24Expression.card(
          cardId: card.id,
          value: Target24Rational(card.value),
        ),
    ]);
    return results;
  }

  static int stageForLevel(int level) {
    final int safeLevel = GameContentPolicy.endlessHighChapter(level);
    return ((safeLevel - 1) % 10) + 1;
  }

  static int maximumForStage(int stage) => switch (stage) {
    <= 2 => 15,
    <= 6 => 25,
    _ => 40,
  };

  static int targetNumberForLevel(int level) {
    if (level <= 5) return 24;
    if (level <= 10) {
      const List<int> list = <int>[24, 28, 30, 36, 40];
      return list[(level - 6) % list.length];
    }
    if (level <= 20) {
      const List<int> list = <int>[48, 50, 60, 72, 80, 84, 90, 96, 100, 108];
      return list[(level - 11) % list.length];
    }
    if (level <= 30) {
      const List<int> list = <int>[100, 120, 125, 140, 144, 150, 160, 175, 180, 200];
      return list[(level - 21) % list.length];
    }
    const List<int> list = <int>[120, 144, 150, 160, 180, 200, 220, 240, 250, 300];
    return list[(level - 31) % list.length];
  }

  Map<String, Object?> toCampaignMap() => {
    'level': level,
    'localStage': localStage,
    'maximumCardValue': maximumCardValue,
    'target': targetValue,
    'cards': cards.map((card) => [card.id, card.value]).toList(),
    'solution': _encodeExpression(solution),
  };

  static List<Object?> _encodeExpression(Target24Expression e) => [
    e.cardId,
    e.operation?.index,
    e.value.numerator,
    e.value.denominator,
    e.first == null ? null : _encodeExpression(e.first!),
    e.second == null ? null : _encodeExpression(e.second!),
  ];

  static Target24Expression _decodeExpression(dynamic source) {
    final e = source as List;
    final value = Target24Rational(e[2] as int, (e[3] as int?) ?? 1);
    return e[0] != null
        ? Target24Expression.card(cardId: e[0] as int, value: value)
        : Target24Expression.combine(
            operation: Target24Operator.values[e[1] as int],
            first: _decodeExpression(e[4]),
            second: _decodeExpression(e[5]),
            value: value,
          );
  }

  static void installCampaignBank(List<dynamic> boards) {
    if (boards.length != 300) {
      throw const FormatException('Invalid target_24 bank');
    }
    for (int i = 0; i < boards.length; i++) {
      final m = Map<String, dynamic>.from(boards[i] as Map);
      final int tgt = (m['target'] as int?) ?? 24;
      _cache[i + 1] = Target24Puzzle(
        level: m['level'] as int,
        localStage: m['localStage'] as int,
        maximumCardValue: m['maximumCardValue'] as int,
        target: Target24Rational(tgt),
        cards: (m['cards'] as List)
            .map((e) => Target24Card(id: e[0] as int, value: e[1] as int))
            .toList(),
        solution: _decodeExpression(m['solution']),
      );
    }
  }

  static Target24Puzzle forLevel(int level) {
    if (level < 1) {
      throw RangeError.range(level, 1, null, 'level');
    }
    if (_cache.containsKey(level)) {
      return _cache[level]!;
    }
    // 300'e kadar olan seviyeleri bankadan veya önceden üret
    for (int nextLevel = 1; nextLevel <= level; nextLevel++) {
      if (_cache.containsKey(nextLevel)) continue;
      _cache[nextLevel] = _generate(
        nextLevel,
        usedSignatures: _cache.values
            .map((Target24Puzzle puzzle) => puzzle.boardSignature)
            .toSet(),
      );
    }
    return _cache[level]!;
  }

  static Target24Puzzle _generate(
    int level, {
    required Set<String> usedSignatures,
  }) {
    final int safeLevel = GameContentPolicy.endlessHighChapter(level);
    final int localStage = stageForLevel(safeLevel);
    final int maximumCardValue = maximumForStage(localStage);
    final int targetNum = targetNumberForLevel(level);

    for (int attempt = 0; attempt < 50000; attempt++) {
      final math.Random random = ContentSeed.randomFor(
        gameId: 'target_24',
        level: level,
        attempt: attempt,
      );
      final List<int> values = <int>[];
      while (values.length < 4) {
        int v;
        if (targetNum >= 100 && random.nextDouble() < 0.35 && !values.contains(25)) {
          v = 25;
        } else if (targetNum >= 140 && random.nextDouble() < 0.25 && !values.contains(50)) {
          v = 50;
        } else {
          v = 1 + random.nextInt(maximumCardValue);
        }
        if (!values.contains(v)) values.add(v);
      }
      values.sort();

      final String sig = '$targetNum#${values.join('|')}';
      if (usedSignatures.contains(sig)) continue;

      final List<Target24Card> cards = List<Target24Card>.generate(
        values.length,
        (int index) => Target24Card(id: index, value: values[index]),
        growable: false,
      );
      final Target24Puzzle candidate = Target24Puzzle(
        level: level,
        localStage: localStage,
        maximumCardValue: maximumCardValue,
        target: Target24Rational(targetNum),
        cards: List<Target24Card>.unmodifiable(cards),
        solution: Target24Expression.card(cardId: -1, value: Target24Rational(targetNum)),
      );
      final List<Target24Expression> solutions = candidate.solve(limit: 2);
      if (solutions.isEmpty) continue;

      return Target24Puzzle(
        level: level,
        localStage: localStage,
        maximumCardValue: maximumCardValue,
        target: Target24Rational(targetNum),
        cards: List<Target24Card>.unmodifiable(cards),
        solution: solutions.first,
      );
    }
    throw StateError('Could not generate an integer target puzzle for level $level.');
  }
}

class Target24Card {
  const Target24Card({required this.id, required this.value});

  final int id;
  final int value;
}
