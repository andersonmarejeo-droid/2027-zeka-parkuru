import 'dart:math' as math;

import '../shared/content_seed.dart';

class CodeFeedback {
  const CodeFeedback({required this.exact, required this.misplaced});

  final int exact;
  final int misplaced;

  @override
  bool operator ==(Object other) =>
      other is CodeFeedback &&
      other.exact == exact &&
      other.misplaced == misplaced;

  @override
  int get hashCode => Object.hash(exact, misplaced);
}

class CodeBreakerPuzzle {
  const CodeBreakerPuzzle._({
    required this.level,
    required this.seed,
    required this.slots,
    required this.paletteSize,
    required this.repeatsAllowed,
    required this.maximumGuesses,
    required this.secret,
  });

  static const int maximumLevels = 20;
  static const int maximumVerifiedBoards = 300;
  static final Map<int, CodeBreakerPuzzle> _campaign =
      <int, CodeBreakerPuzzle>{};
  static final Map<int, CodeBreakerPuzzle> _practice =
      <int, CodeBreakerPuzzle>{};

  final int level;
  final int seed;
  final int slots;
  final int paletteSize;
  final bool repeatsAllowed;
  final int maximumGuesses;
  final List<int> secret;

  String get signature =>
      '$slots/$paletteSize/${repeatsAllowed ? 'R' : 'D'}:$secret';

  int get searchSpace {
    int count = 1;
    for (int slot = 0; slot < slots; slot++) {
      count *= repeatsAllowed ? paletteSize : paletteSize - slot;
    }
    return count;
  }

  String get difficultyTier => switch (level) {
    <= 6 => 'FOUNDATION',
    7 || 8 => 'ADVANCED',
    9 || 10 => 'EXPERT',
    <= 16 => 'DEEP DEDUCTION',
    _ => 'MASTER CODE',
  };

  bool isValidGuess(List<int> guess) {
    if (guess.length != slots ||
        guess.any((int value) => value < 0 || value >= paletteSize)) {
      return false;
    }
    return repeatsAllowed || guess.toSet().length == guess.length;
  }

  CodeFeedback evaluate(List<int> guess) {
    if (!isValidGuess(guess)) {
      throw ArgumentError.value(guess, 'guess', 'Invalid code guess.');
    }
    return scoreGuess(secret: secret, guess: guess, paletteSize: paletteSize);
  }

  static CodeFeedback scoreGuess({
    required List<int> secret,
    required List<int> guess,
    required int paletteSize,
  }) {
    if (secret.length != guess.length ||
        secret.any((int value) => value < 0 || value >= paletteSize) ||
        guess.any((int value) => value < 0 || value >= paletteSize)) {
      throw ArgumentError('Secret and guess must be valid equal-length codes.');
    }
    int exact = 0;
    final List<int> secretRemainder = List<int>.filled(paletteSize, 0);
    final List<int> guessRemainder = List<int>.filled(paletteSize, 0);
    for (int index = 0; index < secret.length; index++) {
      if (guess[index] == secret[index]) {
        exact++;
      } else {
        secretRemainder[secret[index]]++;
        guessRemainder[guess[index]]++;
      }
    }
    int misplaced = 0;
    for (int color = 0; color < paletteSize; color++) {
      misplaced += math.min(secretRemainder[color], guessRemainder[color]);
    }
    return CodeFeedback(exact: exact, misplaced: misplaced);
  }

  bool isSolved(List<int> guess) =>
      isValidGuess(guess) && evaluate(guess).exact == slots;

  static CodeBreakerPuzzle forLevel(int level) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    return _campaign.putIfAbsent(level, () {
      for (int attempt = 0; attempt < 1000; attempt++) {
        final CodeBreakerPuzzle candidate = _generate(level, attempt: attempt);
        if (_allContent.every(
          (CodeBreakerPuzzle previous) =>
              previous.signature != candidate.signature,
        )) {
          return candidate;
        }
      }
      throw StateError('Could not make a unique code for level $level.');
    });
  }

  static CodeBreakerPuzzle forPracticeBoard(int index) {
    if (index < 1 || index > maximumVerifiedBoards) {
      throw RangeError.range(index, 1, maximumVerifiedBoards, 'index');
    }
    for (int level = 1; level <= maximumLevels; level++) {
      _campaign.putIfAbsent(level, () => _generate(level));
    }
    for (int next = _practice.length + 1; next <= index; next++) {
      final int level = ((next - 1) % maximumLevels) + 1;
      CodeBreakerPuzzle? accepted;
      for (int cycle = next; accepted == null; cycle++) {
        final CodeBreakerPuzzle candidate = _generate(
          level,
          contentCycle: cycle,
        );
        if (_allContent.every(
          (CodeBreakerPuzzle previous) =>
              previous.signature != candidate.signature,
        )) {
          accepted = candidate;
        }
      }
      _practice[next] = accepted;
    }
    return _practice[index]!;
  }

  static List<CodeBreakerPuzzle> get _allContent => <CodeBreakerPuzzle>[
    ..._campaign.values,
    ..._practice.values,
  ];

  static CodeBreakerPuzzle _generate(
    int level, {
    int contentCycle = 0,
    int attempt = 0,
  }) {
    final (int slots, int palette, bool repeats, int guesses) = _configuration(
      level,
    );
    final int seed = ContentSeed.forLevel(
      gameId: 'code_breaker:$contentCycle',
      level: level,
      attempt: attempt,
    );
    final math.Random random = math.Random(seed);
    final List<int> secret = <int>[];
    while (secret.length < slots) {
      final int color = random.nextInt(palette);
      if (!repeats && secret.contains(color)) continue;
      secret.add(color);
    }
    return CodeBreakerPuzzle._(
      level: level,
      seed: seed,
      slots: slots,
      paletteSize: palette,
      repeatsAllowed: repeats,
      maximumGuesses: guesses,
      secret: List<int>.unmodifiable(secret),
    );
  }

  static (int, int, bool, int) _configuration(int level) => switch (level) {
    <= 3 => (4, 5, false, 8),
    <= 6 => (4, 7, false, 9),
    7 || 8 => (5, 6, true, 10),
    9 || 10 => (6, 8, false, 10),
    <= 13 => (5, 8, true, 11),
    <= 16 => (6, 9, true, 12),
    <= 18 => (6, 10, true, 12),
    _ => (7, 10, true, 13),
  };
}
