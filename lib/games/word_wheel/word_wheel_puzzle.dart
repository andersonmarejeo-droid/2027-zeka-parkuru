import 'dart:math' as math;

import '../shared/content_seed.dart';
import '../shared/studio_game_contracts.dart';
import 'word_wheel_vocabulary.dart';

class WordWheelPuzzle {
  const WordWheelPuzzle({
    required this.level,
    required this.languageCode,
    required this.anchor,
    required this.wheelLetters,
    required this.answers,
    required this.validWords,
    required this.chapter,
    required this.stageInChapter,
  });

  static const int maximumLevels = 20;
  static const int poolSize = GameContentPolicy.wordWheelPoolSize;
  static final Map<String, List<WordWheelPuzzle>> _poolCache = {};

  static WordWheelPuzzle forPool(int index, {String languageCode = 'tr'}) {
    RangeError.checkValueInInterval(index, 1, poolSize, 'index');
    final locale = languageCode.toLowerCase() == 'tr' ? 'tr' : 'en';
    final pool = _poolCache.putIfAbsent(locale, () => <WordWheelPuzzle>[]);
    final templates =
        List<WordWheelPuzzle>.generate(
          maximumLevels,
          (i) => forLevel(i + 1, languageCode: locale),
        )..sort((a, b) {
          final score = (a.targetCount * 10 + a.wheelLetters.length).compareTo(
            b.targetCount * 10 + b.wheelLetters.length,
          );
          return score != 0 ? score : a.level.compareTo(b.level);
        });
    final signatures = pool.map((puzzle) => puzzle.contentSignature).toSet();
    for (int next = pool.length + 1; next <= index; next++) {
      final int templateIndex = ((next - 1) * maximumLevels ~/ poolSize)
          .clamp(0, maximumLevels - 1)
          .toInt();
      final base = templates[templateIndex];
      final int difficultyStage =
          1 + ((next - 1) * 10 ~/ poolSize).clamp(0, 9).toInt();
      final int poolChapter =
          1 + ((next - 1) * 30 ~/ poolSize).clamp(0, 29).toInt();
      WordWheelPuzzle? accepted;
      for (int attempt = 0; accepted == null && attempt < 10000; attempt++) {
        final random = ContentSeed.randomFor(
          gameId: 'word_wheel:pool:$locale',
          level: next,
          attempt: attempt,
        );
        final packs = (locale == 'tr' ? _turkishPacks : _englishPacks)
            .where(
              (pack) =>
                  _letters(pack.anchor).length ==
                      _letters(base.anchor).length &&
                  pack.words.length >= base.targetCount,
            )
            .toList();
        final pack = packs[random.nextInt(packs.length)];
        final answers = _selectWheelWords(
          anchor: pack.anchor,
          candidates: pack.words,
          targetCount: base.targetCount,
          random: random,
        );
        if (answers == null) continue;
        final letters = _letters(pack.anchor).toList();
        final int desiredDecoys = 1 + ((difficultyStage - 1) ~/ 4);
        final List<String> decoys = _alphabetFor(locale)
            .where((letter) => !letters.contains(letter))
            .toList();
        for (int decoy = 0; decoy < desiredDecoys; decoy++) {
          final String letter = decoys.removeAt(random.nextInt(decoys.length));
          letters.add(letter);
        }
        _shuffle(letters, random);
        final candidate = WordWheelPuzzle(
          level: next,
          languageCode: locale,
          anchor: pack.anchor,
          wheelLetters: List.unmodifiable(letters),
          answers: List.unmodifiable(answers),
          validWords: List.unmodifiable(_validWords(pack)),
          chapter: poolChapter,
          stageInChapter: difficultyStage,
        );
        if (signatures.add(candidate.contentSignature)) accepted = candidate;
      }
      if (accepted == null) {
        throw StateError('Cannot build unique wheel $next ($locale).');
      }
      pool.add(accepted);
    }
    return pool[index - 1];
  }

  static final Map<String, List<WordWheelPuzzle>> _campaignCache =
      <String, List<WordWheelPuzzle>>{};

  final int level;
  final String languageCode;
  final String anchor;
  final List<String> wheelLetters;

  /// Required words that complete this round.
  final List<String> answers;

  /// Campaign bonus words generated for this pack.
  ///
  /// [isKnownWord] also consults the wider language lexicon so players can
  /// submit additional valid words without changing the target list.
  final List<String> validWords;
  final int chapter;
  final int stageInChapter;

  int get targetCount => answers.length;

  String get difficultyTier => switch (stageInChapter) {
    <= 6 => 'MASTERY',
    _ => 'EXPERT',
  };

  String get boardSignature => contentSignature;

  String get contentSignature {
    final List<String> sortedLetters = List<String>.from(wheelLetters)..sort();
    final List<String> sortedAnswers = List<String>.from(answers)..sort();
    final List<String> sortedValidWords = List<String>.from(validWords)..sort();
    return '${sortedLetters.join()}#${sortedAnswers.join('|')}#${sortedValidWords.join('|')}';
  }

  static int stageForLevel(int level) => ((level - 1) % 10) + 1;

  static WordWheelPuzzle forLevel(int level, {String languageCode = 'tr'}) {
    if (level < 1 || level > maximumLevels) {
      throw RangeError.range(level, 1, maximumLevels, 'level');
    }
    final String locale = languageCode.toLowerCase() == 'tr' ? 'tr' : 'en';
    final List<WordWheelPuzzle> campaign = _campaignCache.putIfAbsent(
      locale,
      () => _generateCampaign(locale),
    );
    return campaign[level - 1];
  }

  bool containsWord(String value) => isKnownWord(value);

  /// Returns true for a target or bonus word in the wider language pool.
  /// Target words remain separate in [answers] and still control completion.
  bool isKnownWord(String value) {
    final String normalized = _normalize(value, languageCode);
    return validWords.contains(normalized) ||
        wordWheelLexicon(languageCode).contains(normalized);
  }

  /// Checks that a known word can be made from this wheel.
  ///
  /// When [jokerLetter] is supplied it is added as the single wildcard tile,
  /// so a joker cannot silently create more than one missing letter.
  bool canBuildWord(String value, {String? jokerLetter}) {
    final String normalized = _normalize(value, languageCode);
    if (normalized.runes.length < 2 || !isKnownWord(normalized)) return false;
    final List<String> available = <String>[...wheelLetters];
    if (jokerLetter != null && jokerLetter.isNotEmpty) {
      available.add(_normalize(jokerLetter, languageCode));
    }
    return _canBuild(normalized, available);
  }

  String normalizeWord(String value) => _normalize(value, languageCode);

  bool isTargetWord(String value) =>
      answers.contains(_normalize(value, languageCode));

  static List<String> _validWords(_WheelPack pack) => pack.words
      .where(
        (String word) =>
            _letters(word).length >= 2 &&
            _canBuild(word, _letters(pack.anchor)),
      )
      .toSet()
      .toList(growable: false);

  static List<WordWheelPuzzle> _generateCampaign(String locale) {
    final List<_WheelPack> packs = locale == 'tr'
        ? _turkishPacks
        : _englishPacks;
    final List<WordWheelPuzzle> puzzles = <WordWheelPuzzle>[];
    final Set<String> usedAnchors = <String>{};
    final Set<String> signatures = <String>{};

    for (int level = 1; level <= maximumLevels; level++) {
      final int stage = stageForLevel(level);
      final int chapter = ((level - 1) ~/ 10) + 1;
      final int requestedTargets = switch (stage) {
        <= 3 => chapter == 1 ? 4 : 5,
        <= 6 => chapter == 1 ? 5 : 6,
        <= 8 => chapter == 1 ? 6 : 7,
        _ => chapter == 1 ? 7 : 8,
      };
      bool added = false;
      final math.Random random = ContentSeed.randomFor(
        gameId: 'word_wheel:$locale',
        level: level,
      );
      final List<_WheelPack> orderedPacks = List<_WheelPack>.from(packs);

      for (final _WheelPack pack in orderedPacks) {
        if (usedAnchors.contains(pack.anchor)) continue;
        final int maximumTargetCount = math.min(
          requestedTargets,
          math.min(pack.words.length, _letters(pack.anchor).length + 1),
        );
        if (maximumTargetCount < 4) continue;
        for (
          int targetCount = maximumTargetCount;
          targetCount >= 4 && !added;
          targetCount--
        ) {
          final List<String>? selected = _selectWheelWords(
            anchor: pack.anchor,
            candidates: pack.words,
            targetCount: targetCount,
          );
          if (selected == null) continue;

          final List<String> wheel = _letters(pack.anchor).toList();
          if (chapter == 2) {
            final List<String> decoys = _alphabetFor(locale)
                .where((String letter) => !wheel.contains(letter))
                .toList(growable: false);
            if (decoys.isNotEmpty) {
              wheel.add(decoys[random.nextInt(decoys.length)]);
            }
          }
          _shuffle(wheel, random);
          final WordWheelPuzzle puzzle = WordWheelPuzzle(
            level: level,
            languageCode: locale,
            anchor: pack.anchor,
            wheelLetters: List<String>.unmodifiable(wheel),
            answers: List<String>.unmodifiable(selected),
            validWords: List<String>.unmodifiable(_validWords(pack)),
            chapter: chapter,
            stageInChapter: stage,
          );
          if (!signatures.add(puzzle.boardSignature)) continue;
          usedAnchors.add(pack.anchor);
          puzzles.add(puzzle);
          added = true;
        }
        if (added) break;
      }
      if (!added) {
        throw StateError(
          'Could not create unique word-wheel level $level for $locale.',
        );
      }
    }
    return List<WordWheelPuzzle>.unmodifiable(puzzles);
  }

  static List<String>? _selectWheelWords({
    required String anchor,
    required List<String> candidates,
    required int targetCount,
    math.Random? random,
  }) {
    final List<String> anchorLetters = _letters(anchor);
    final List<String> branchCandidates = candidates
        .where(
          (String word) =>
              word != anchor &&
              _letters(word).length >= 2 &&
              _canBuild(word, anchorLetters),
        )
        .toSet()
        .toList();
    branchCandidates.sort((String a, String b) {
      final int length = _letters(b).length.compareTo(_letters(a).length);
      return length == 0 ? a.compareTo(b) : length;
    });
    if (random != null) _shuffleEqualLengthWords(branchCandidates, random);
    final List<String> chosen = <String>[anchor];
    chosen.addAll(branchCandidates.take(targetCount - 1));
    if (chosen.length != targetCount) return null;
    return chosen;
  }

  static void _shuffleEqualLengthWords(List<String> words, math.Random random) {
    int first = 0;
    while (first < words.length) {
      int end = first + 1;
      final int length = _letters(words[first]).length;
      while (end < words.length && _letters(words[end]).length == length) {
        end++;
      }
      if (end - first > 1) {
        final List<String> group = words.sublist(first, end);
        _shuffle(group, random);
        words.replaceRange(first, end, group);
      }
      first = end;
    }
  }

  static bool _canBuild(String word, List<String> wheel) {
    final Map<String, int> counts = <String, int>{};
    for (final String letter in wheel) {
      counts.update(letter, (int count) => count + 1, ifAbsent: () => 1);
    }
    for (final String letter in _letters(word)) {
      final int remaining = counts[letter] ?? 0;
      if (remaining == 0) return false;
      counts[letter] = remaining - 1;
    }
    return true;
  }

  static List<String> _letters(String value) =>
      value.runes.map(String.fromCharCode).toList(growable: false);

  static String _normalize(String value, String locale) {
    final String trimmed = value.trim();
    if (locale.toLowerCase() != 'tr') return trimmed.toUpperCase();

    // Dart's Unicode uppercasing is locale-independent: lowercase `i` would
    // become `I`, which merges it with Turkish dotless `ı`. Keep both letters
    // distinct so the Turkish wheel accepts the spelling represented by its
    // actual tiles.
    return trimmed.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }

  static List<String> _alphabetFor(String locale) => locale == 'tr'
      ? const <String>[
          'A',
          'B',
          'C',
          'Ç',
          'D',
          'E',
          'F',
          'G',
          'Ğ',
          'H',
          'I',
          'İ',
          'J',
          'K',
          'L',
          'M',
          'N',
          'O',
          'Ö',
          'P',
          'R',
          'S',
          'Ş',
          'T',
          'U',
          'Ü',
          'V',
          'Y',
          'Z',
        ]
      : const <String>[
          'A',
          'B',
          'C',
          'D',
          'E',
          'F',
          'G',
          'H',
          'I',
          'J',
          'K',
          'L',
          'M',
          'N',
          'O',
          'P',
          'Q',
          'R',
          'S',
          'T',
          'U',
          'V',
          'W',
          'X',
          'Y',
          'Z',
        ];

  static void _shuffle<T>(List<T> values, math.Random random) {
    for (int index = values.length - 1; index > 0; index--) {
      final int swap = random.nextInt(index + 1);
      final T value = values[index];
      values[index] = values[swap];
      values[swap] = value;
    }
  }
}

class _WheelPack {
  const _WheelPack({required this.anchor, required this.words});

  final String anchor;
  final List<String> words;
}

const List<_WheelPack> _turkishPacks = <_WheelPack>[
  _WheelPack(
    anchor: 'KALEM',
    words: <String>['KALEM', 'ELMA', 'KELAM', 'KAL', 'KEL', 'KAM', 'ELA'],
  ),
  _WheelPack(
    anchor: 'KARTON',
    words: <String>[
      'KARTON',
      'KART',
      'KOR',
      'TON',
      'TAR',
      'NAR',
      'KOT',
      'NOT',
      'KAN',
    ],
  ),
  _WheelPack(
    anchor: 'KAMERA',
    words: <String>['KAMERA', 'KARE', 'KARA', 'KAMA', 'ARMA', 'KREM', 'KAMER'],
  ),
  _WheelPack(
    anchor: 'KAPLAN',
    words: <String>[
      'KAPLAN',
      'KAPAN',
      'KANAL',
      'PLAN',
      'KAP',
      'KAN',
      'KAL',
      'PAL',
      'ALAN',
    ],
  ),
  _WheelPack(
    anchor: 'PARMAK',
    words: <String>[
      'PARMAK',
      'PARA',
      'KARA',
      'PARK',
      'KAP',
      'KAR',
      'RAM',
      'ARP',
    ],
  ),
  _WheelPack(
    anchor: 'ARABA',
    words: <String>['ARABA', 'BARA', 'ARA', 'ABA', 'BAR', 'AR', 'BA'],
  ),
  _WheelPack(
    anchor: 'SATIR',
    words: <String>[
      'SATIR',
      'SIRT',
      'SARI',
      'SIRA',
      'ART',
      'TAR',
      'ARI',
      'TAS',
      'TIR',
    ],
  ),
  _WheelPack(
    anchor: 'MANTIK',
    words: <String>[
      'MANTIK',
      'AKIT',
      'KAT',
      'MAT',
      'TAM',
      'TAN',
      'ANT',
      'KIN',
      'KAN',
    ],
  ),
  _WheelPack(
    anchor: 'DENİZ',
    words: <String>['DENİZ', 'DİN', 'DİZ', 'İZ', 'DEN', 'ZEN', 'NEZ', 'İN'],
  ),
  _WheelPack(
    anchor: 'BAHÇELİ',
    words: <String>[
      'BAHÇELİ',
      'BAHÇE',
      'BAL',
      'BEL',
      'İLE',
      'ÇİL',
      'EL',
      'BAH',
      'AÇ',
    ],
  ),
  _WheelPack(
    anchor: 'GÖLGE',
    words: <String>['GÖLGE', 'GÖL', 'GÖLE', 'GEL', 'EGE', 'ÖL', 'EL'],
  ),
  _WheelPack(
    anchor: 'GÜNEŞ',
    words: <String>['GÜNEŞ', 'GÜN', 'ŞEN', 'EŞ', 'ÜN', 'NEŞE', 'EŞE'],
  ),
  _WheelPack(
    anchor: 'KÖPRÜ',
    words: <String>['KÖPRÜ', 'KÖR', 'KÜR', 'KÖP', 'ÖP', 'KÜP'],
  ),
  _WheelPack(
    anchor: 'SÖZLÜK',
    words: <String>['SÖZLÜK', 'SÖZ', 'ÖZ', 'KÖZ', 'KÜL', 'SÖK', 'KÜS'],
  ),
  _WheelPack(
    anchor: 'KELEBEK',
    words: <String>['KELEBEK', 'LEKE', 'KEK', 'BEL', 'KEL', 'EKE', 'EKLE'],
  ),
  _WheelPack(
    anchor: 'KİTAP',
    words: <String>['KİTAP', 'KAT', 'KAP', 'TAK', 'PAT', 'PAK', 'PİK'],
  ),
  _WheelPack(
    anchor: 'YELKEN',
    words: <String>['YELKEN', 'YEL', 'EL', 'KEL', 'EK', 'KEN', 'YEN', 'KENE'],
  ),
  _WheelPack(
    anchor: 'SANDAL',
    words: <String>[
      'SANDAL',
      'DANA',
      'ALAN',
      'SANA',
      'DAL',
      'SAL',
      'AND',
      'NAL',
      'ANA',
    ],
  ),
  _WheelPack(
    anchor: 'OYUNCAK',
    words: <String>['OYUNCAK', 'OYUN', 'CAN', 'YOK', 'KAN', 'ONA', 'KAY'],
  ),
  _WheelPack(
    anchor: 'KAVUN',
    words: <String>['KAVUN', 'KAN', 'VAN', 'UN', 'AV', 'AK', 'AN'],
  ),
];

const List<_WheelPack> _englishPacks = <_WheelPack>[
  _WheelPack(
    anchor: 'CARES',
    words: <String>['CARES', 'SCARE', 'RACE', 'CASE', 'ACRES', 'SCAR', 'CARE'],
  ),
  _WheelPack(
    anchor: 'STONER',
    words: <String>[
      'STONER',
      'TONER',
      'SNORE',
      'STORE',
      'TENOR',
      'NOTES',
      'TONES',
      'STERN',
    ],
  ),
  _WheelPack(
    anchor: 'SILENT',
    words: <String>[
      'SILENT',
      'LISTEN',
      'ENLIST',
      'INLETS',
      'LINES',
      'TILES',
      'TINS',
      'TIES',
    ],
  ),
  _WheelPack(
    anchor: 'STARED',
    words: <String>[
      'STARED',
      'TRADES',
      'TREADS',
      'RATED',
      'TREAD',
      'TARES',
      'RATES',
      'STAR',
    ],
  ),
  _WheelPack(
    anchor: 'PLANET',
    words: <String>[
      'PLANET',
      'PLAN',
      'PLANE',
      'PANEL',
      'PLANT',
      'LATE',
      'LEAP',
      'PANE',
      'PANT',
      'TEAL',
    ],
  ),
  _WheelPack(
    anchor: 'RESCUE',
    words: <String>[
      'RESCUE',
      'SECURE',
      'RECUSE',
      'CURSE',
      'CURES',
      'USER',
      'SURE',
      'CUES',
    ],
  ),
  _WheelPack(
    anchor: 'STREAM',
    words: <String>[
      'STREAM',
      'MASTER',
      'TAMERS',
      'TAMES',
      'TEAMS',
      'SMART',
      'STARE',
      'TEARS',
      'STAR',
    ],
  ),
  _WheelPack(
    anchor: 'RATION',
    words: <String>[
      'RATION',
      'RATIO',
      'TRAIN',
      'INTRO',
      'RAIN',
      'IRON',
      'RANT',
      'TORN',
      'TARO',
    ],
  ),
  _WheelPack(
    anchor: 'CORALS',
    words: <String>[
      'CORALS',
      'CAROLS',
      'SOLAR',
      'CORAL',
      'SCAR',
      'ORAL',
      'ALSO',
      'COAL',
    ],
  ),
  _WheelPack(
    anchor: 'SPARKER',
    words: <String>[
      'SPARKER',
      'SPEAK',
      'PEARS',
      'SPEAR',
      'SPARE',
      'PEAK',
      'PARK',
      'RASP',
      'PEAR',
    ],
  ),
  _WheelPack(
    anchor: 'CHAIRS',
    words: <String>[
      'CHAIRS',
      'CHAIR',
      'CHARS',
      'CRASH',
      'HAIRS',
      'SCAR',
      'AIRS',
      'RASH',
      'CASH',
    ],
  ),
  _WheelPack(
    anchor: 'BRIGHT',
    words: <String>[
      'BRIGHT',
      'BIRTH',
      'RIGHT',
      'GIRTH',
      'RIG',
      'BIG',
      'RIB',
      'HIT',
      'GRIT',
    ],
  ),
  _WheelPack(
    anchor: 'PROUDLY',
    words: <String>[
      'PROUDLY',
      'POUR',
      'YOUR',
      'PLOY',
      'POLY',
      'LORD',
      'LOUD',
      'OLD',
    ],
  ),
  _WheelPack(
    anchor: 'TRACED',
    words: <String>[
      'TRACED',
      'CRATED',
      'CARTED',
      'CATER',
      'TRACE',
      'TRADE',
      'CARED',
      'RATED',
      'TREAD',
    ],
  ),
  _WheelPack(
    anchor: 'EARTHS',
    words: <String>[
      'EARTHS',
      'HEARTS',
      'HATERS',
      'RATES',
      'SHARE',
      'HEART',
      'SHEAR',
      'TEARS',
      'STAR',
    ],
  ),
  _WheelPack(
    anchor: 'CLOUDS',
    words: <String>[
      'CLOUDS',
      'COULD',
      'CLOUD',
      'COLD',
      'LOUD',
      'SOUL',
      'OLD',
      'CLOD',
      'COD',
    ],
  ),
  _WheelPack(
    anchor: 'MARINE',
    words: <String>[
      'MARINE',
      'REMAIN',
      'MINER',
      'RAIN',
      'MAIN',
      'NAME',
      'MEAN',
      'MARE',
      'NEAR',
    ],
  ),
  _WheelPack(
    anchor: 'PAINTS',
    words: <String>[
      'PAINTS',
      'PAINT',
      'SAINT',
      'PANTS',
      'STAIN',
      'PAINS',
      'PATS',
      'PINS',
      'TAPS',
    ],
  ),
  _WheelPack(
    anchor: 'GARDEN',
    words: <String>[
      'GARDEN',
      'DANGER',
      'RANGE',
      'GRADE',
      'GEAR',
      'NEAR',
      'DARE',
      'DEAR',
      'READ',
    ],
  ),
  _WheelPack(
    anchor: 'CRATER',
    words: <String>[
      'CRATER',
      'CATER',
      'TRACE',
      'REACT',
      'CRATE',
      'RACE',
      'CARE',
      'RATE',
      'TEAR',
      'CART',
    ],
  ),
];
