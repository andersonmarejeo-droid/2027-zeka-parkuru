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

  static String canonicalLocale(String languageCode) {
    final String code = languageCode.toLowerCase();
    if (code == 'tr') return 'tr';
    if (code == 'ar') return 'ar';
    return 'en';
  }

  static WordWheelPuzzle forPool(int index, {String languageCode = 'tr'}) {
    RangeError.checkValueInInterval(index, 1, poolSize, 'index');
    final locale = canonicalLocale(languageCode);
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
        final packs = _packsFor(locale)
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
    final String locale = canonicalLocale(languageCode);
    final List<WordWheelPuzzle> campaign = _campaignCache.putIfAbsent(
      locale,
      () => _generateCampaign(locale),
    );
    return campaign[level - 1];
  }

  bool containsWord(String value) => isKnownWord(value);

  /// Returns true for a target or bonus word in the wider language pool.
  /// Target words remain separate in [answers] and still control completion.
  ///
  /// Words with fewer than 4 letters are strictly rejected.
  bool isKnownWord(String value) {
    final String normalized = _normalize(value, languageCode);
    if (normalized.runes.length < 4) return false;
    return answers.contains(normalized) ||
        validWords.contains(normalized) ||
        wordWheelLexicon(languageCode).contains(normalized) ||
        _allPacksWordSet(languageCode).contains(normalized);
  }

  static final Map<String, Set<String>> _packsWordCache = {};
  static Set<String> _allPacksWordSet(String locale) {
    final String canon = canonicalLocale(locale);
    return _packsWordCache.putIfAbsent(canon, () {
      final packs = _packsFor(canon);
      final set = <String>{};
      for (final pack in packs) {
        set.add(_normalize(pack.anchor, canon));
        for (final w in pack.words) {
          set.add(_normalize(w, canon));
        }
      }
      return set;
    });
  }

  /// Checks that a known word can be made from this wheel.
  ///
  /// Words with fewer than 4 letters are never accepted.
  /// When [jokerLetter] is supplied it is added as the single wildcard tile,
  /// so a joker cannot silently create more than one missing letter.
  bool canBuildWord(String value, {String? jokerLetter}) {
    final String normalized = _normalize(value, languageCode);
    if (normalized.runes.length < 4 || !isKnownWord(normalized)) return false;
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
            _letters(word).length >= 4 &&
            _canBuild(word, _letters(pack.anchor)),
      )
      .toSet()
      .toList(growable: false);

  static List<WordWheelPuzzle> _generateCampaign(String locale) {
    final String canon = canonicalLocale(locale);
    final List<_WheelPack> packs = _packsFor(canon);
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
        gameId: 'word_wheel:$canon',
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
            final List<String> decoys = _alphabetFor(canon)
                .where((String letter) => !wheel.contains(letter))
                .toList(growable: false);
            if (decoys.isNotEmpty) {
              wheel.add(decoys[random.nextInt(decoys.length)]);
            }
          }
          _shuffle(wheel, random);
          final WordWheelPuzzle puzzle = WordWheelPuzzle(
            level: level,
            languageCode: canon,
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
          'Could not create unique word-wheel level $level for $canon.',
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
              _letters(word).length >= 4 &&
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
    final String canon = canonicalLocale(locale);
    if (canon == 'tr') {
      return trimmed.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
    }
    if (canon == 'ar') {
      return trimmed
          .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
          .replaceAll(RegExp(r'[أإآ]'), 'ا');
    }
    return trimmed.toUpperCase();
  }

  static List<String> _alphabetFor(String locale) {
    final String canon = canonicalLocale(locale);
    if (canon == 'tr') {
      return const <String>[
        'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H', 'I', 'İ',
        'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T',
        'U', 'Ü', 'V', 'Y', 'Z',
      ];
    }
    if (canon == 'ar') {
      return const <String>[
        'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س',
        'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م',
        'ن', 'ه', 'و', 'ي', 'ة',
      ];
    }
    return const <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
      'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
      'Y', 'Z',
    ];
  }

  static List<_WheelPack> _packsFor(String locale) {
    final String canon = canonicalLocale(locale);
    if (canon == 'tr') return _turkishPacks;
    if (canon == 'ar') return _arabicPacks;
    return _englishPacks;
  }

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
    words: <String>['KALEM', 'ELMA', 'KELAM', 'KALE', 'MEAL', 'AMEL', 'KAME', 'KEMAL'],
  ),
  _WheelPack(
    anchor: 'KARTON',
    words: <String>[
      'KARTON',
      'KART',
      'KOTRA',
      'KANTO',
      'NOKTA',
      'ORTAK',
      'TORNA',
      'AKOR',
      'KOTA',
      'ORTA',
      'ROTA',
      'TANK',
      'ORAN',
    ],
  ),
  _WheelPack(
    anchor: 'KAMERA',
    words: <String>[
      'KAMERA',
      'KARE',
      'KARA',
      'KAMA',
      'ARMA',
      'KREM',
      'KAMER',
      'MARKA',
      'RAKAM',
      'MERAK',
      'KREMA',
      'ARKA',
      'ARAK',
    ],
  ),
  _WheelPack(
    anchor: 'KAPLAN',
    words: <String>[
      'KAPLAN',
      'KAPAN',
      'KANAL',
      'PLAN',
      'ALAN',
      'PALAN',
      'PLAKA',
      'APAK',
      'ANKA',
      'LAPA',
      'PALA',
    ],
  ),
  _WheelPack(
    anchor: 'PARMAK',
    words: <String>[
      'PARMAK',
      'PARA',
      'KARA',
      'PARK',
      'ARPA',
      'ARKA',
      'MARKA',
      'RAKAM',
      'RAMP',
      'KRAMP',
      'ARMA',
      'KAMA',
      'ARAK',
    ],
  ),
  _WheelPack(
    anchor: 'KESTANE',
    words: <String>[
      'KESTANE',
      'TANE',
      'KASE',
      'KAST',
      'KESAT',
      'TANK',
      'KANTE',
      'KESEN',
      'ENSE',
      'SENET',
      'ETEN',
      'TEKE',
      'ETEK',
      'KENE',
    ],
  ),
  _WheelPack(
    anchor: 'SATIR',
    words: <String>[
      'SATIR',
      'SIRT',
      'SARI',
      'SIRA',
      'ARTI',
      'ASIR',
    ],
  ),
  _WheelPack(
    anchor: 'MANTIK',
    words: <String>[
      'MANTIK',
      'MANTI',
      'TAKIM',
      'TIKMA',
      'TANIK',
      'KANIT',
      'AKIT',
      'ATIK',
      'KATI',
      'KITA',
      'ATKI',
      'TANI',
      'TANK',
      'KANI',
    ],
  ),
  _WheelPack(
    anchor: 'MERSİN',
    words: <String>[
      'MERSİN',
      'RESMİ',
      'SİREN',
      'İSME',
      'SİNE',
      'EMİR',
      'ESİR',
      'ESİN',
      'ERİN',
      'REİS',
      'SERİ',
      'MİNE',
      'MENİ',
    ],
  ),
  _WheelPack(
    anchor: 'BAHÇELİ',
    words: <String>[
      'BAHÇELİ',
      'BAHÇE',
      'BİLE',
      'BALE',
      'İLÇE',
      'İHALE',
      'İLAH',
      'ÇİLE',
      'HEBA',
      'HALE',
      'HELA',
      'ALİÇ',
      'ÇALİ',
    ],
  ),
  _WheelPack(
    anchor: 'TOPRAK',
    words: <String>[
      'TOPRAK',
      'ORTAK',
      'KORAT',
      'PARKO',
      'PARK',
      'KART',
      'ORTA',
      'ROTA',
      'AKOR',
      'KOTA',
      'POTA',
      'TOKA',
      'TRAP',
    ],
  ),
  _WheelPack(
    anchor: 'MARKET',
    words: <String>[
      'MARKET',
      'MERAK',
      'MAKET',
      'MATER',
      'KREMA',
      'KAMER',
      'KARE',
      'KREM',
      'MERT',
      'MERA',
      'META',
      'TERK',
      'TEMA',
      'KART',
    ],
  ),
  _WheelPack(
    anchor: 'BARDAK',
    words: <String>[
      'BARDAK',
      'KABRA',
      'ARDA',
      'DARA',
      'KABA',
      'BARA',
      'KARA',
      'ARKA',
      'ARAK',
      'BARK',
      'ABRA',
    ],
  ),
  _WheelPack(
    anchor: 'KARDELEN',
    words: <String>[
      'KARDELEN',
      'KADER',
      'DEKAN',
      'ERKAN',
      'KANEL',
      'KALE',
      'KARE',
      'KENE',
      'KLAN',
      'DERE',
      'DANE',
      'EDER',
      'ELAN',
      'EREN',
      'ELEK',
    ],
  ),
  _WheelPack(
    anchor: 'PORTAKAL',
    words: <String>[
      'PORTAKAL',
      'ORTAK',
      'POLAR',
      'TOPAL',
      'PARKA',
      'TARLA',
      'PARK',
      'KART',
      'ORTA',
      'ROTA',
      'POTA',
      'TOKA',
      'KOLA',
      'ALTO',
      'LAPA',
      'PALA',
      'KOTA',
      'ARAP',
      'ARPA',
      'ARKA',
      'KARA',
      'ORAL',
    ],
  ),
  _WheelPack(
    anchor: 'SANDAL',
    words: <String>[
      'SANDAL',
      'ALAN',
      'DANA',
      'SANA',
      'SALA',
      'ASLA',
      'ASAL',
      'ANAS',
      'NALA',
      'ASAN',
      'ADAN',
    ],
  ),
  _WheelPack(
    anchor: 'BAYRAK',
    words: <String>[
      'BAYRAK',
      'KABRA',
      'BARA',
      'KARA',
      'KABA',
      'ARKA',
      'ARAK',
      'AYAR',
      'AYAK',
      'KAYA',
      'YAKA',
      'ABRA',
      'BARK',
    ],
  ),
  _WheelPack(
    anchor: 'MANDALİNA',
    words: <String>[
      'MANDALİNA',
      'MANDAL',
      'ADANA',
      'DAMA',
      'DANA',
      'ALAN',
      'İMAN',
      'İNAL',
      'AMAN',
      'ANAM',
      'MANA',
      'MANİ',
      'MAİN',
      'MİNA',
    ],
  ),
  _WheelPack(
    anchor: 'KAYNAK',
    words: <String>[
      'KAYNAK',
      'KANAK',
      'KAYAN',
      'YANAK',
      'AKAN',
      'ANKA',
      'AYAN',
      'AYAK',
      'KAYA',
      'YAKA',
      'KANA',
    ],
  ),
  _WheelPack(
    anchor: 'BALIKÇI',
    words: <String>[
      'BALIKÇI',
      'BALIK',
      'BALÇIK',
      'ÇALIK',
      'BIÇAK',
      'AÇLIK',
      'AKIL',
      'ALIK',
      'ILIK',
      'AÇIK',
      'AÇKI',
      'ÇAKI',
      'ÇALI',
      'KALI',
      'BAKI',
    ],
  ),
  _WheelPack(
    anchor: 'ZEYTİNLİK',
    words: <String>[
      'ZEYTİNLİK',
      'ZEYTİN',
      'YETKİ',
      'TEKİN',
      'ETKİN',
      'KİTLE',
      'KİLİT',
      'İNTEL',
      'İLKE',
      'EKİN',
      'KİLE',
      'NİTEL',
      'EZİK',
    ],
  ),
  _WheelPack(
    anchor: 'ÇİKOLATA',
    words: <String>[
      'ÇİKOLATA',
      'ÇATAL',
      'ALTO',
      'KOLA',
      'ATOL',
      'TOKA',
      'TAKO',
      'ATİK',
      'LATA',
      'ÇİTA',
      'KİLO',
      'AKİT',
    ],
  ),
];

const List<_WheelPack> _englishPacks = <_WheelPack>[
  _WheelPack(
    anchor: 'CARES',
    words: <String>['CARES', 'SCARE', 'RACE', 'CASE', 'ACRES', 'SCAR', 'CARE', 'EARS', 'SEAR', 'ARCS'],
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
      'ROTE',
      'NOSE',
      'TORE',
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
      'SITE',
      'LINT',
      'LENT',
      'NEST',
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
      'DATE',
      'DEAR',
      'REST',
      'TEAR',
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
      'PALE',
      'LEAN',
      'NEAT',
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
      'SEER',
      'CURE',
      'RUSE',
      'ECRU',
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
      'TEAM',
      'MEAT',
      'STEM',
      'MATE',
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
      'ROAN',
      'ANTI',
      'INTO',
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
      'SOAR',
      'COLA',
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
      'REAP',
      'RAKE',
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
      'RICH',
      'ARCH',
    ],
  ),
  _WheelPack(
    anchor: 'BRIGHT',
    words: <String>[
      'BRIGHT',
      'BIRTH',
      'RIGHT',
      'GIRTH',
      'GRIT',
      'GIRT',
      'BRIG',
      'TRIG',
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
      'DROP',
      'ROUP',
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
      'CARD',
      'DARE',
      'DEAR',
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
      'HEAT',
      'HATE',
      'HEAR',
      'REST',
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
      'CLOD',
      'COLDS',
      'SCUD',
      'DUOS',
      'LUDO',
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
      'MINE',
      'EARN',
      'RAMI',
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
      'SPAT',
      'PAST',
      'SPIT',
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
      'RANG',
      'AGED',
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
      'RARE',
      'REAR',
    ],
  ),
];

const List<_WheelPack> _arabicPacks = <_WheelPack>[
  _WheelPack(
    anchor: 'مسافر',
    words: <String>['مسافر', 'مسار', 'فارس', 'سامر', 'سافر', 'فراس', 'مفرس', 'سمار', 'رسام'],
  ),
  _WheelPack(
    anchor: 'اشجارة',
    words: <String>['اشجارة', 'اشجار', 'شجار', 'شارج', 'جاشر', 'اشرا', 'راجش', 'جارا', 'راجا', 'جارة', 'راجة'],
  ),
  _WheelPack(
    anchor: 'حاسوبات',
    words: <String>['حاسوبات', 'حاسوب', 'حساب', 'سحاب', 'سباح', 'سواح', 'حسوب', 'سبات', 'سابت'],
  ),
  _WheelPack(
    anchor: 'بساتين',
    words: <String>['بساتين', 'بستان', 'نبات', 'سبات', 'بانت', 'تاسن', 'سابت', 'تبيان', 'بنات'],
  ),
  _WheelPack(
    anchor: 'مكتوبات',
    words: <String>['مكتوبات', 'مكتوب', 'كتاب', 'كاتب', 'مكتب', 'مكاتب', 'تواب', 'كواب', 'بكات'],
  ),
  _WheelPack(
    anchor: 'معماريون',
    words: <String>['معماريون', 'معماري', 'عامر', 'معمار', 'عمار', 'مرام', 'عمري', 'رميم', 'موران'],
  ),
  _WheelPack(
    anchor: 'صداقات',
    words: <String>['صداقات', 'صادق', 'قاصد', 'صداق', 'قصاد', 'صدقا', 'صادقا', 'دقات'],
  ),
  _WheelPack(
    anchor: 'صناعات',
    words: <String>['صناعات', 'صانع', 'ناصع', 'ناعص', 'صناع', 'عانص', 'عصات', 'نعات'],
  ),
  _WheelPack(
    anchor: 'تجارات',
    words: <String>['تجارات', 'تاجر', 'تارات', 'جارا', 'راجا', 'تجار', 'تراج', 'رتاج'],
  ),
  _WheelPack(
    anchor: 'سيارات',
    words: <String>['سيارات', 'يسار', 'ياسر', 'ساري', 'ساير', 'تيسار', 'سيرات', 'تيار'],
  ),
  _WheelPack(
    anchor: 'انهارات',
    words: <String>['انهارات', 'انهار', 'نهار', 'راهن', 'اهران', 'ناهر', 'هانر', 'رانها', 'انها', 'تهار', 'ناهت'],
  ),
  _WheelPack(
    anchor: 'مسافرات',
    words: <String>['مسافرات', 'مسافر', 'مسار', 'فارس', 'سامر', 'سافر', 'فراس', 'مفرس', 'سمار', 'رسام', 'سفارات', 'مسرات'],
  ),
  _WheelPack(
    anchor: 'شريعات',
    words: <String>['شريعات', 'شريع', 'شعير', 'عشرات', 'شارع', 'رعيات', 'عاشر'],
  ),
  _WheelPack(
    anchor: 'ميادين',
    words: <String>['ميادين', 'مدين', 'ميدان', 'دينام', 'نامي', 'يمان', 'ناديم', 'ديام'],
  ),
  _WheelPack(
    anchor: 'زراعات',
    words: <String>['زراعات', 'زارع', 'عزار', 'عازر', 'زعات', 'تارع', 'عزات'],
  ),
  _WheelPack(
    anchor: 'جامعات',
    words: <String>['جامعات', 'جامع', 'عاجات', 'تاجع', 'متاع', 'جماعات', 'عجام'],
  ),
  _WheelPack(
    anchor: 'قناديل',
    words: <String>['قناديل', 'قنديل', 'نادي', 'لادن', 'داني', 'قلند', 'قيان', 'ليندا', 'نديل'],
  ),
  _WheelPack(
    anchor: 'حديقات',
    words: <String>['حديقات', 'حديق', 'قادت', 'حادق', 'تادي', 'حداق', 'قتاد'],
  ),
  _WheelPack(
    anchor: 'كواكبنا',
    words: <String>['كواكبنا', 'كواكب', 'كوكب', 'كابك', 'واكب', 'كواب', 'بنوك', 'كاوان'],
  ),
  _WheelPack(
    anchor: 'زهورنا',
    words: <String>['زهورنا', 'زهور', 'زاهر', 'هارون', 'واهن', 'واهر', 'زاهن', 'نهور'],
  ),
];
