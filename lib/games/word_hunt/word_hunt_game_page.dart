import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';



import '../../theme/studio_visuals.dart';

import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../services/replayability_service.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import 'word_hunt_locale_data.dart';

class WordHuntGamePage extends StatelessWidget {
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const WordHuntGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  static const List<WordHuntLevel> levels = <WordHuntLevel>[
    WordHuntLevel(
      number: 1,
      titleTr: 'İlk Kelimeler',
      titleEn: 'First Words',
      subtitleTr: '2 tabloda toplam 6 kısa kelime',
      subtitleEn: '6 short words across 2 boards',
      difficulty: 'KOLAY',
      size: 4,
      wordCount: 3,
      boardCount: 2,
      directions: 2,
      targetSeconds: 42,
    ),
    WordHuntLevel(
      number: 2,
      titleTr: 'Dikey İzler',
      titleEn: 'Vertical Trails',
      subtitleTr: '2 farklı 5×5 tabloda kelimeleri ara',
      subtitleEn: 'Search across 2 different 5×5 boards',
      difficulty: 'KOLAY',
      size: 5,
      wordCount: 4,
      boardCount: 2,
      directions: 2,
      targetSeconds: 55,
    ),
    WordHuntLevel(
      number: 3,
      titleTr: 'Ters Köşe',
      titleEn: 'Reverse Corner',
      subtitleTr: '2 tabloda tersten saklananları bul',
      subtitleEn: 'Find reversed words across 2 boards',
      difficulty: 'ORTA',
      size: 5,
      wordCount: 5,
      boardCount: 2,
      directions: 4,
      targetSeconds: 65,
    ),
    WordHuntLevel(
      number: 4,
      titleTr: 'Çapraz Bakış',
      titleEn: 'Diagonal Vision',
      subtitleTr: '2 farklı 6×6 tabloda çapraz yollar',
      subtitleEn: 'Diagonal paths across 2 different boards',
      difficulty: 'ORTA',
      size: 6,
      wordCount: 5,
      boardCount: 2,
      directions: 8,
      targetSeconds: 72,
    ),
    WordHuntLevel(
      number: 5,
      titleTr: 'Kelime Ağı',
      titleEn: 'Word Network',
      subtitleTr: '2 tabloda kesişen 12 kelimeyi yakala',
      subtitleEn: 'Catch 12 intersecting words across 2 boards',
      difficulty: 'ORTA',
      size: 6,
      wordCount: 6,
      boardCount: 2,
      directions: 8,
      targetSeconds: 78,
    ),
    WordHuntLevel(
      number: 6,
      titleTr: 'Harf Ormanı',
      titleEn: 'Letter Forest',
      subtitleTr: '2 farklı 7×7 tabloda dikkatini koru',
      subtitleEn: 'Stay focused across 2 different boards',
      difficulty: 'ZOR',
      size: 7,
      wordCount: 6,
      boardCount: 2,
      directions: 8,
      targetSeconds: 86,
    ),
    WordHuntLevel(
      number: 7,
      titleTr: 'Gizli Rotalar',
      titleEn: 'Hidden Routes',
      subtitleTr: '2 tabloda 14 kelime, sekiz farklı yön',
      subtitleEn: '14 words in eight directions across 2 boards',
      difficulty: 'ZOR',
      size: 7,
      wordCount: 7,
      boardCount: 2,
      directions: 8,
      targetSeconds: 94,
    ),
    WordHuntLevel(
      number: 8,
      titleTr: 'Usta Izgarası',
      titleEn: 'Master Grid',
      subtitleTr: '2 farklı 8×8 tabloda uzun kelimeler',
      subtitleEn: 'Long words across 2 different 8×8 boards',
      difficulty: 'ZOR',
      size: 8,
      wordCount: 7,
      boardCount: 2,
      directions: 8,
      targetSeconds: 105,
    ),
    WordHuntLevel(
      number: 9,
      titleTr: 'Keskin Göz',
      titleEn: 'Sharp Eye',
      subtitleTr: '2 tabloda toplam 16 kelimeyi bul',
      subtitleEn: 'Find 16 words across 2 boards',
      difficulty: 'ZOR',
      size: 8,
      wordCount: 8,
      boardCount: 2,
      directions: 8,
      targetSeconds: 118,
    ),
    WordHuntLevel(
      number: 10,
      titleTr: 'Kelime Avcısı',
      titleEn: 'Word Hunter',
      subtitleTr: '2 farklı 9×9 final tablosunu temizle',
      subtitleEn: 'Clear 2 different final 9×9 boards',
      difficulty: 'BOSS',
      size: 9,
      wordCount: 9,
      boardCount: 2,
      directions: 8,
      targetSeconds: 135,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ParkurLevelHub(
      gameId: 'word_hunt',
      progressPrefix: 'word_hunt',
      titleTr: 'KELİME AVI',
      titleEn: 'WORD HUNT',
      taglineTr: 'Bul • Sürükle • Tamamla',
      taglineEn: 'Find • Swipe • Complete',
      accent: const Color(0xFF34715D),
      icon: Icons.travel_explore_rounded,
      levels: levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? fixedSessionSeed,
            bool competitionMode,
          ) {
            return WordHuntPlayPage(
              level: level as WordHuntLevel,
              previousBestScore: previousBestScore,
              fixedSessionSeed: fixedSessionSeed ?? level.poolIndex,
              competitionMode: competitionMode,
            );
          },
    );
  }
}

class WordHuntLevel extends ParkurLevelSpec {
  final int size;
  final int wordCount;
  final int boardCount;
  final int directions;
  final int targetSeconds;

  const WordHuntLevel({
    super.sourceNumber,
    super.poolIndex,
    required super.number,
    required super.titleTr,
    required super.titleEn,
    required super.subtitleTr,
    required super.subtitleEn,
    required super.difficulty,
    required this.size,
    required this.wordCount,
    required this.boardCount,
    required this.directions,
    required this.targetSeconds,
  }) : super(icon: Icons.grid_on_rounded);
  @override
  WordHuntLevel campaignCopy({
    required int number,
    int? sourceNumber,
    int? poolIndex,
    String? titleTr,
    String? titleEn,
    String? difficulty,
  }) => WordHuntLevel(
    number: number,
    sourceNumber: sourceNumber,
    poolIndex: poolIndex,
    titleTr: titleTr ?? this.titleTr,
    titleEn: titleEn ?? this.titleEn,
    subtitleTr: subtitleTr,
    subtitleEn: subtitleEn,
    difficulty: difficulty ?? this.difficulty,
    size: size,
    wordCount: wordCount,
    boardCount: boardCount,
    directions: directions,
    targetSeconds: targetSeconds,
  );
}

class _WordPuzzle {
  final List<List<String>> grid;
  final List<String> words;
  final Map<String, List<Point<int>>> placements;

  const _WordPuzzle({
    required this.grid,
    required this.words,
    required this.placements,
  });
}

class WordHuntPlayPage extends StatefulWidget {
  final WordHuntLevel level;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const WordHuntPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<WordHuntPlayPage> createState() => _WordHuntPlayPageState();
}

class _WordHuntPlayPageState extends State<WordHuntPlayPage> {
  static const Color _accent = Color(0xFF34715D);
  static String? _lastGeneratedSignature;
  static const List<String> _alphabetTr = <String>[
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
  ];
  static const List<String> _alphabetEn = <String>[
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
  static const List<String> _wordBankTr = <String>[
    'KOD',
    'HIZ',
    'AKIL',
    'ZEKA',
    'OYUN',
    'RENK',
    'ROTA',
    'KULE',
    'HEDEF',
    'SAYI',
    'BLOK',
    'ODAK',
    'DESEN',
    'ŞEKİL',
    'HALKA',
    'GÖREV',
    'MANTIK',
    'HAFIZA',
    'PARKUR',
    'YILDIZ',
    'ÇÖZÜM',
    'BAŞARI',
    'DÜŞÜN',
    'USTALIK',
    'ADA',
    'AYI',
    'BAL',
    'CAM',
    'DAL',
    'DİL',
    'GÖL',
    'KAR',
    'KUŞ',
    'MUM',
    'NAR',
    'OK',
    'TAŞ',
    'YOL',
    'YÜZ',
    'ARI',
    'AT',
    'ÇAY',
    'ÇİM',
    'DÜŞ',
    'ELMA',
    'ARMUT',
    'KİRAZ',
    'ÜZÜM',
    'KAVUN',
    'LİMON',
    'İNCİR',
    'ERİK',
    'MUZ',
    'VİŞNE',
    'CEVİZ',
    'FINDIK',
    'BADEM',
    'ZEYTİN',
    'DOMATES',
    'KEDİ',
    'KÖPEK',
    'TAVŞAN',
    'ASLAN',
    'KAPLAN',
    'ZEBRA',
    'PANDA',
    'BALIK',
    'YUNUS',
    'MARTI',
    'SERÇE',
    'KARTAL',
    'LEYLEK',
    'KARGA',
    'ORMAN',
    'DENİZ',
    'NEHİR',
    'IRMAK',
    'DAĞ',
    'OVA',
    'VADİ',
    'ŞELALE',
    'BULUT',
    'YAĞMUR',
    'RÜZGAR',
    'GÜNEŞ',
    'AY',
    'DÜNYA',
    'ASTEROİT',
    'UZAY',
    'ROKET',
    'GEZEGEN',
    'METEOR',
    'UYDU',
    'GALAKSİ',
    'EVREN',
    'KUTUP',
    'KİTAP',
    'KALEM',
    'SİLGİ',
    'DEFTER',
    'MASA',
    'SINIF',
    'OKUL',
    'DERS',
    'BİLGİ',
    'BİLİM',
    'DENEY',
    'MERAK',
    'FİKİR',
    'SORU',
    'YANIT',
    'ÖĞREN',
    'YAZILIM',
    'ROBOT',
    'EKRAN',
    'KLAVYE',
    'FARE',
    'PİKSEL',
    'VERİ',
    'KAMERA',
    'SENSÖR',
    'MOTOR',
    'KABLO',
    'DEVRE',
    'ENERJİ',
    'İNTERNET',
    'FUTBOL',
    'VOLEYBOL',
    'TENİS',
    'YÜZME',
    'KOŞU',
    'TAKIM',
    'MAÇ',
    'KALE',
    'TOP',
    'RAKET',
    'SPOR',
    'ANTRENÖR',
    'MADALYA',
    'ŞAMPİYON',
    'MÜZİK',
    'NOTA',
    'RİTİM',
    'ŞARKI',
    'RESİM',
    'BOYA',
    'FIRÇA',
    'SAHNE',
    'TİYATRO',
    'SİNEMA',
    'MASAL',
    'ŞİİR',
    'ROMAN',
    'SANAT',
    'DANS',
    'DOST',
    'SEVGİ',
    'UMUT',
    'NEŞE',
    'SABIR',
    'CESUR',
    'GÜVEN',
    'EMEK',
    'SAYGI',
    'YARDIM',
    'BARIŞ',
    'İYİLİK',
    'GÜLÜMSE',
    'MUTLU',
    'SAKİN',
    'ŞEHİR',
    'KÖY',
    'SOKAK',
    'PARK',
    'BAHÇE',
    'KÖPRÜ',
    'İSTASYON',
    'TREN',
    'VAPUR',
    'OTOBÜS',
    'BİSİKLET',
    'UÇAK',
    'LİMAN',
    'MEYDAN',
    'DOKTOR',
    'ÖĞRETMEN',
    'MİMAR',
    'PİLOT',
    'AŞÇI',
    'ÇİFTÇİ',
    'YAZAR',
    'RESSAM',
    'MÜHENDİS',
    'HAKİM',
    'TERZİ',
    'ECZACI',
    'SPİKER',
    'KAPTAN',
    'SAAT',
    'TAKVİM',
    'SABAH',
    'AKŞAM',
    'BUGÜN',
    'YARIN',
    'HAFTA',
    'MEVSİM',
    'İLKBAHAR',
    'YAZ',
    'SONBAHAR',
    'KIŞ',
    'PAZAR',
    'TATİL',
    'ZAMAN',
    'ÜÇGEN',
    'KARE',
    'DAİRE',
    'KÜRE',
    'KÜP',
    'ÇİZGİ',
    'NOKTA',
    'AÇI',
    'KENAR',
    'ALAN',
    'UZUN',
    'KISA',
    'BÜYÜK',
    'KÜÇÜK',
    'EŞİT',
    'ÖLÇÜ',
  ];
  static const List<String> _wordBankEn = <String>[
    'CODE',
    'FAST',
    'MIND',
    'BRAIN',
    'GAME',
    'COLOR',
    'ROUTE',
    'TOWER',
    'TARGET',
    'NUMBER',
    'BLOCK',
    'FOCUS',
    'PATTERN',
    'SHAPE',
    'RING',
    'TASK',
    'LOGIC',
    'MEMORY',
    'COURSE',
    'STAR',
    'ANSWER',
    'SUCCESS',
    'THINK',
    'MASTER',
    'CAT',
    'DOG',
    'RABBIT',
    'LION',
    'TIGER',
    'ZEBRA',
    'PANDA',
    'FISH',
    'WHALE',
    'DOLPHIN',
    'EAGLE',
    'ROBIN',
    'CROW',
    'SWAN',
    'APPLE',
    'PEAR',
    'CHERRY',
    'GRAPE',
    'MELON',
    'LEMON',
    'FIG',
    'PLUM',
    'BANANA',
    'BERRY',
    'WALNUT',
    'HAZEL',
    'ALMOND',
    'OLIVE',
    'TOMATO',
    'FOREST',
    'OCEAN',
    'RIVER',
    'LAKE',
    'HILL',
    'PLAIN',
    'VALLEY',
    'FALLS',
    'CLOUD',
    'RAIN',
    'WIND',
    'SUN',
    'MOON',
    'EARTH',
    'SPACE',
    'ROCKET',
    'PLANET',
    'METEOR',
    'ORBIT',
    'GALAXY',
    'COMET',
    'POLAR',
    'NATURE',
    'BOOK',
    'PENCIL',
    'ERASER',
    'PAPER',
    'TABLE',
    'CLASS',
    'SCHOOL',
    'LESSON',
    'STUDY',
    'SCIENCE',
    'TEST',
    'IDEA',
    'QUERY',
    'LEARN',
    'READ',
    'WRITE',
    'ROBOT',
    'SCREEN',
    'KEYBOARD',
    'MOUSE',
    'PIXEL',
    'DATA',
    'CAMERA',
    'SENSOR',
    'MOTOR',
    'CABLE',
    'CIRCUIT',
    'ENERGY',
    'NETWORK',
    'DIGITAL',
    'SOCCER',
    'TENNIS',
    'SWIM',
    'RUN',
    'TEAM',
    'MATCH',
    'GOAL',
    'BALL',
    'RACKET',
    'SPORT',
    'COACH',
    'MEDAL',
    'CHAMPION',
    'RACE',
    'PLAYER',
    'MUSIC',
    'NOTE',
    'RHYTHM',
    'SONG',
    'IMAGE',
    'PAINT',
    'BRUSH',
    'STAGE',
    'THEATER',
    'MOVIE',
    'STORY',
    'POEM',
    'NOVEL',
    'ART',
    'DANCE',
    'DRAMA',
    'FRIEND',
    'LOVE',
    'HOPE',
    'JOY',
    'PATIENCE',
    'BRAVE',
    'TRUST',
    'EFFORT',
    'RESPECT',
    'HELP',
    'PEACE',
    'KIND',
    'SMILE',
    'HAPPY',
    'CALM',
    'HONEST',
    'CITY',
    'VILLAGE',
    'STREET',
    'PARK',
    'GARDEN',
    'BRIDGE',
    'STATION',
    'TRAIN',
    'FERRY',
    'BUS',
    'BIKE',
    'PLANE',
    'PORT',
    'SQUARE',
    'ROAD',
    'DOCTOR',
    'TEACHER',
    'ARCHITECT',
    'PILOT',
    'CHEF',
    'FARMER',
    'WRITER',
    'ARTIST',
    'ENGINEER',
    'JUDGE',
    'TAILOR',
    'NURSE',
    'REPORTER',
    'CAPTAIN',
    'CLOCK',
    'DATE',
    'MORNING',
    'EVENING',
    'TODAY',
    'TOMORROW',
    'WEEK',
    'TRIANGLE',
    'CIRCLE',
    'SPHERE',
    'CUBE',
    'LINE',
    'POINT',
    'ANGLE',
    'EDGE',
    'AREA',
    'LONG',
    'SHORT',
    'LARGE',
    'SMALL',
    'EQUAL',
    'MEASURE',
    'CENTER',
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final ReplayabilityService _replayability = ReplayabilityService();
  late Random _random;
  Timer? _timer;

  late _WordPuzzle _puzzle;
  final Set<String> _sessionPuzzleSignatures = <String>{};
  final Set<String> _sessionWords = <String>{};
  final Set<String> _foundWords = <String>{};
  final Map<String, List<Point<int>>> _foundPaths =
      <String, List<Point<int>>>{};
  List<Point<int>> _selection = <Point<int>>[];
  Point<int>? _startCell;
  Point<int>? _hintCell;
  int? _activePointer;
  bool _pointerMoved = false;
  bool _cancelPendingTap = false;
  int _elapsed = 0;
  int _mistakes = 0;
  int _hints = 0;
  int _boardHints = 0;
  int _boardIndex = 0;
  int _sessionToken = 0;
  late int _sessionBestScore;
  int _sessionBestStars = 0;
  bool _completed = false;
  bool _transitioning = false;
  bool _ready = false;
  bool _initialized = false;
  String _languageCode = 'en';

  List<String> get _alphabet {
    if (_languageCode == 'tr') return _alphabetTr;
    if (_languageCode == 'en') return _alphabetEn;
    return WordHuntLocaleData.alphabet(_languageCode);
  }

  List<String> get _wordBank {
    if (_languageCode == 'tr') return _wordBankTr;
    if (_languageCode == 'en') return _wordBankEn;
    return WordHuntLocaleData.words(_languageCode);
  }

  @override
  void initState() {
    super.initState();
    _random = Random(widget.fixedSessionSeed);
    _sessionBestScore = widget.previousBestScore;
    unawaited(_audio.preload(GameAudioGroup.ui));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _languageCode = Localizations.localeOf(context).languageCode.toLowerCase();
    unawaited(_initializeSession());
  }

  Future<void> _initializeSession() async {
    final int seed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'word_hunt',
          level: widget.level.number,
        );
    _random = _replayability.randomFor(sessionSeed: seed, round: 0, salt: 401);
    if (!mounted) return;
    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _timer?.cancel();
    _sessionToken++;
    _sessionPuzzleSignatures.clear();
    _sessionWords.clear();
    _boardIndex = 0;
    _elapsed = 0;
    _mistakes = 0;
    _hints = 0;
    _completed = false;
    _transitioning = false;
    _ready = true;
    _prepareBoard();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted || _completed) return;
      setState(() => _elapsed++);
    });
    if (mounted) setState(() {});
  }

  void _prepareBoard() {
    _puzzle = _generateFreshPuzzle();
    _sessionWords.addAll(_puzzle.words);
    if (widget.fixedSessionSeed == null) {
      unawaited(
        _replayability.registerFingerprint(
          gameId: 'word_hunt',
          level: widget.level.number,
          fingerprint: _puzzleSignature(_puzzle),
          historyLimit: 100,
        ),
      );
    }
    _foundWords.clear();
    _foundPaths.clear();
    _selection = <Point<int>>[];
    _startCell = null;
    _hintCell = null;
    _activePointer = null;
    _pointerMoved = false;
    _cancelPendingTap = false;
    _boardHints = 0;
  }

  _WordPuzzle _generateFreshPuzzle() {
    _WordPuzzle nextPuzzle = _generatePuzzle(widget.level, _random);
    String signature = _puzzleSignature(nextPuzzle);
    for (
      int attempt = 0;
      attempt < 12 &&
          ((widget.fixedSessionSeed == null &&
                  signature == _lastGeneratedSignature) ||
              _sessionPuzzleSignatures.contains(signature));
      attempt++
    ) {
      nextPuzzle = _generatePuzzle(widget.level, _random);
      signature = _puzzleSignature(nextPuzzle);
    }
    _lastGeneratedSignature = signature;
    _sessionPuzzleSignatures.add(signature);
    return nextPuzzle;
  }

  String _puzzleSignature(_WordPuzzle puzzle) {
    return '${puzzle.words.join('|')}::'
        '${puzzle.grid.expand((List<String> row) => row).join()}';
  }

  _WordPuzzle _generatePuzzle(WordHuntLevel level, Random random) {
    for (int boardAttempt = 0; boardAttempt < 60; boardAttempt++) {
      final List<String> candidates =
          _wordBank
              .where(
                (String word) =>
                    word.runes.length <= level.size &&
                    !_sessionWords.contains(word),
              )
              .toList(growable: true)
            ..shuffle(random);
      final List<String> chosen = candidates
          .take(level.wordCount)
          .toList(growable: false);
      final List<List<String?>> board = List<List<String?>>.generate(
        level.size,
        (_) => List<String?>.filled(level.size, null),
      );
      final Map<String, List<Point<int>>> placements =
          <String, List<Point<int>>>{};

      bool failed = false;
      for (final String word in chosen) {
        bool placed = false;
        final List<_Direction> directions = _directionsFor(level.directions)
          ..shuffle(random);

        for (int attempt = 0; attempt < 140 && !placed; attempt++) {
          final _Direction direction =
              directions[random.nextInt(directions.length)];
          final int row = random.nextInt(level.size);
          final int column = random.nextInt(level.size);
          final List<String> letters = word.runes
              .map((int rune) => String.fromCharCode(rune))
              .toList(growable: false);
          final int endRow = row + direction.row * (letters.length - 1);
          final int endColumn =
              column + direction.column * (letters.length - 1);
          if (endRow < 0 ||
              endRow >= level.size ||
              endColumn < 0 ||
              endColumn >= level.size) {
            continue;
          }

          final List<Point<int>> cells = <Point<int>>[];
          bool fits = true;
          for (int index = 0; index < letters.length; index++) {
            final int targetRow = row + direction.row * index;
            final int targetColumn = column + direction.column * index;
            final String? current = board[targetRow][targetColumn];
            if (current != null && current != letters[index]) {
              fits = false;
              break;
            }
            cells.add(Point<int>(targetColumn, targetRow));
          }
          if (!fits) continue;

          for (int index = 0; index < cells.length; index++) {
            board[cells[index].y][cells[index].x] = letters[index];
          }
          placements[word] = cells;
          placed = true;
        }

        if (!placed) {
          failed = true;
          break;
        }
      }

      if (failed || placements.length != chosen.length) continue;

      final List<List<String>> completed = List<List<String>>.generate(
        level.size,
        (int row) => List<String>.generate(
          level.size,
          (int column) =>
              board[row][column] ?? _alphabet[random.nextInt(_alphabet.length)],
        ),
      );

      return _WordPuzzle(
        grid: completed,
        words: chosen,
        placements: placements,
      );
    }

    final List<String> fallbackWords = _wordBank
        .where((String word) => word.runes.length <= level.size)
        .take(level.wordCount)
        .toList(growable: false);
    final List<List<String>> fallbackGrid = List<List<String>>.generate(
      level.size,
      (_) => List<String>.generate(
        level.size,
        (_) => _alphabet[random.nextInt(_alphabet.length)],
      ),
    );
    final Map<String, List<Point<int>>> fallbackPlacements =
        <String, List<Point<int>>>{};
    for (int wordIndex = 0; wordIndex < fallbackWords.length; wordIndex++) {
      final String word = fallbackWords[wordIndex];
      final List<String> letters = word.runes
          .map((int rune) => String.fromCharCode(rune))
          .toList(growable: false);
      final int row = wordIndex;
      final int startColumn = random.nextInt(level.size - letters.length + 1);
      final List<Point<int>> cells = <Point<int>>[];
      for (int index = 0; index < letters.length; index++) {
        fallbackGrid[row][startColumn + index] = letters[index];
        cells.add(Point<int>(startColumn + index, row));
      }
      fallbackPlacements[word] = cells;
    }
    return _WordPuzzle(
      grid: fallbackGrid,
      words: fallbackWords,
      placements: fallbackPlacements,
    );
  }

  List<_Direction> _directionsFor(int count) {
    const List<_Direction> all = <_Direction>[
      _Direction(0, 1),
      _Direction(1, 0),
      _Direction(0, -1),
      _Direction(-1, 0),
      _Direction(1, 1),
      _Direction(-1, -1),
      _Direction(1, -1),
      _Direction(-1, 1),
    ];
    return all.take(count.clamp(2, 8).toInt()).toList(growable: true);
  }

  Point<int>? _cellAt(Offset localPosition, double boardSize) {
    const double boardInset = 5;
    final double playableSize = boardSize - boardInset * 2;
    if (localPosition.dx < boardInset ||
        localPosition.dy < boardInset ||
        localPosition.dx >= boardSize - boardInset ||
        localPosition.dy >= boardSize - boardInset) {
      return null;
    }

    // Yalnızca gerçek oyun ızgarasının içindeki dokunuşları hücreye çevir.
    // Tahta kenarındaki veya dışındaki rastgele dokunuşları en yakın harfe
    // yuvarlamak, istemeden kelime seçilmesine neden olur.
    final double adjustedX = localPosition.dx - boardInset;
    final double adjustedY = localPosition.dy - boardInset;
    final double cellSize = playableSize / widget.level.size;
    return Point<int>(
      (adjustedX / cellSize).floor(),
      (adjustedY / cellSize).floor(),
    );
  }

  List<Point<int>> _lineBetween(Point<int> start, Point<int> end) {
    final int dx = end.x - start.x;
    final int dy = end.y - start.y;
    final int absX = dx.abs();
    final int absY = dy.abs();
    int stepX = 0;
    int stepY = 0;
    int steps = 0;

    if (absY == 0 || (absX > 0 && absX >= absY * 1.65)) {
      stepX = dx.sign;
      steps = absX;
    } else if (absX == 0 || absY >= absX * 1.65) {
      stepY = dy.sign;
      steps = absY;
    } else {
      stepX = dx.sign;
      stepY = dy.sign;
      steps = max(absX, absY);
    }
    if (steps == 0) return <Point<int>>[start];
    final List<Point<int>> cells = <Point<int>>[];
    for (int index = 0; index <= steps; index++) {
      final Point<int> cell = Point<int>(
        start.x + stepX * index,
        start.y + stepY * index,
      );
      if (cell.x < 0 ||
          cell.x >= widget.level.size ||
          cell.y < 0 ||
          cell.y >= widget.level.size) {
        break;
      }
      cells.add(cell);
    }
    return cells;
  }

  List<Point<int>> _selectionBetween(Point<int> start, Point<int> end) {
    // Seçimi yakındaki gizli bir kelimeye otomatik olarak kilitleme. Kullanıcı
    // hangi hücrelerde başladı ve bitirdiyse yalnızca o gerçek yol sınanır.
    return _lineBetween(start, end);
  }

  void _onPointerDown(PointerDownEvent event, double boardSize) {
    if (_completed || _transitioning || _activePointer != null) return;
    final Point<int>? cell = _cellAt(event.localPosition, boardSize);
    if (cell == null) return;

    final bool hasPendingTap = _startCell != null && _selection.length == 1;
    _activePointer = event.pointer;
    _pointerMoved = false;
    _cancelPendingTap = hasPendingTap && cell == _startCell;

    unawaited(_audio.play(GameSound.uiClick, gain: 0.55));
    HapticFeedback.selectionClick();
    setState(() {
      if (!hasPendingTap) {
        _startCell = cell;
        _selection = <Point<int>>[cell];
      } else if (cell != _startCell) {
        _selection = _selectionBetween(_startCell!, cell);
      }
      _hintCell = null;
    });
  }

  void _onPointerMove(PointerMoveEvent event, double boardSize) {
    if (_activePointer != event.pointer) return;
    final Point<int>? start = _startCell;
    if (start == null || _completed || _transitioning) return;
    final Point<int>? end = _cellAt(event.localPosition, boardSize);
    if (end == null) return;
    if (end != _selection.last) {
      _pointerMoved = true;
      _cancelPendingTap = false;
    }
    final List<Point<int>> next = _selectionBetween(start, end);
    if (_sameCells(next, _selection)) return;
    if (next.length != _selection.length) {
      HapticFeedback.selectionClick();
    }
    setState(() => _selection = next);
  }

  bool _sameCells(List<Point<int>> a, List<Point<int>> b) {
    if (a.length != b.length) return false;
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_activePointer != event.pointer) return;
    _activePointer = null;

    if (_selection.length >= 2) {
      unawaited(_submitSelection());
      return;
    }

    if (_cancelPendingTap && !_pointerMoved) {
      setState(() {
        _startCell = null;
        _selection = <Point<int>>[];
      });
    }
    _cancelPendingTap = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_activePointer != event.pointer) return;
    _activePointer = null;
    _pointerMoved = false;
    _cancelPendingTap = false;
    if (!mounted) return;
    setState(() {
      _startCell = null;
      _selection = <Point<int>>[];
    });
  }

  Future<void> _submitSelection() async {
    if (_completed || _transitioning || _selection.length < 2) {
      if (mounted) {
        setState(() {
          _selection = <Point<int>>[];
          _startCell = null;
        });
      }
      return;
    }

    String? matchedWord;
    for (final String word in _puzzle.words) {
      if (_foundWords.contains(word)) continue;
      final List<Point<int>> placement = _puzzle.placements[word]!;
      if (_sameCells(_selection, placement) ||
          _sameCells(_selection, placement.reversed.toList())) {
        matchedWord = word;
        break;
      }
    }

    if (matchedWord != null) {
      _foundWords.add(matchedWord);
      _foundPaths[matchedWord] = List<Point<int>>.from(_selection);
      unawaited(_audio.play(GameSound.success));
      HapticFeedback.mediumImpact();
    } else {
      _mistakes++;
      unawaited(_audio.play(GameSound.numberWrong));
      HapticFeedback.lightImpact();
    }

    if (mounted) {
      setState(() {
        _selection = <Point<int>>[];
        _startCell = null;
      });
    }

    if (_foundWords.length == _puzzle.words.length) {
      await _completeBoard();
    }
  }

  Future<void> _completeBoard() async {
    if (_completed || _transitioning) return;
    if (_boardIndex + 1 >= widget.level.boardCount) {
      await _finish();
      return;
    }

    final int activeSessionToken = _sessionToken;
    setState(() => _transitioning = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted || _completed || activeSessionToken != _sessionToken) {
      return;
    }

    setState(() {
      _boardIndex++;
      _prepareBoard();
      _transitioning = false;
    });
  }

  Future<void> _showHint() async {
    if (_completed || _transitioning || _boardHints >= 2) return;
    String? word;
    for (final String candidate in _puzzle.words) {
      if (!_foundWords.contains(candidate)) {
        word = candidate;
        break;
      }
    }
    if (word == null) return;
    _hints++;
    _boardHints++;
    unawaited(_audio.play(GameSound.uiHint));
    setState(() => _hintCell = _puzzle.placements[word]!.first);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted && !_completed) setState(() => _hintCell = null);
  }

  Future<void> _finish() async {
    if (_completed) return;
    _completed = true;
    _timer?.cancel();
    final int totalTargetSeconds =
        widget.level.targetSeconds * widget.level.boardCount;
    final int totalWords = widget.level.wordCount * widget.level.boardCount;
    final int stars =
        _mistakes == 0 && _hints == 0 && _elapsed <= totalTargetSeconds
        ? 3
        : _mistakes <= 2 * widget.level.boardCount &&
              _hints <= widget.level.boardCount
        ? 2
        : 1;
    final int speedBonus = max(0, totalTargetSeconds - _elapsed) * 12;
    final int score = max(
      200,
      widget.level.number * 260 +
          totalWords * 190 +
          speedBonus -
          _mistakes * 85 -
          _hints * 140,
    );

    unawaited(
      _audio.playLevelComplete(levelNumber: widget.level.number),
    );
    _sessionBestScore = max(_sessionBestScore, score);
    _sessionBestStars = max(_sessionBestStars, stars);
    if (!mounted) return;
    if (widget.competitionMode) {
      Navigator.pop(
        context,
        ParkurGameResult(
          completed: true,
          stars: _sessionBestStars,
          score: _sessionBestScore,
          nextLevel: false,
        ),
      );
      return;
    }
    final ParkurResultAction? action = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'Kelime Tablosu Temizlendi!',
      titleEn: 'Word Board Cleared!',
      detailTr:
          '${widget.level.boardCount} tablo • $totalWords kelime • $_elapsed sn • $_mistakes hatalı seçim',
      detailEn:
          '${widget.level.boardCount} boards • $totalWords words • $_elapsed sec • $_mistakes misses',
      stars: stars,
      score: score,
      previousBestScore: _sessionBestScore,
      canGoNext: widget.level.number < GameContentPolicy.campaignLevels,
    );
    if (!mounted || action == null) return;
    if (action == ParkurResultAction.replay) {
      Navigator.pop(
        context,
        ParkurGameResult(
          completed: true,
          stars: _sessionBestStars,
          score: _sessionBestScore,
          nextLevel: false,
          replayLevel: true,
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      ParkurGameResult(
        completed: true,
        stars: _sessionBestStars,
        score: _sessionBestScore,
        nextLevel: action == ParkurResultAction.next,
      ),
    );
  }

  bool _isFoundCell(Point<int> cell) {
    for (final String word in _foundWords) {
      if ((_foundPaths[word] ?? _puzzle.placements[word]!).contains(cell)) {
        return true;
      }
    }
    return false;
  }

  String _targetLabel(String word, {required bool found}) {
    if (found || widget.level.number <= 3) return word;
    final List<int> letters = word.runes.toList(growable: false);
    return <String>[
      String.fromCharCode(letters.first),
      for (int index = 1; index < letters.length; index++) '•',
    ].join(' ');
  }

  void _showHowToPlay(BuildContext context, bool english) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: StudioVisuals.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.help_outline_rounded, color: _accent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    english ? 'How to Play?' : 'Nasıl Oynanır?',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: StudioVisuals.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                english
                    ? '• Find the target words hidden in the grid (horizontal, vertical, diagonal).\n'
                      '• Drag through the word or tap the first and last letters.\n'
                      '• Use the hint button if you get stuck on a tricky word.\n'
                      '• Clear all words on all boards to complete the level!'
                    : '• Tabloda gizlenmiş hedef kelimeleri bul (yatay, dikey veya çapraz).\n'
                      '• Kelimenin harfleri üzerinde parmağını kaydır veya ilk ve son harfe dokun.\n'
                      '• Takıldığın yerde ipucu butonuna basarak ilk harfin yerini görebilirsin.\n'
                      '• Tüm tahtalardaki kelimeleri bularak seviyeyi tamamla!',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  height: 1.5,
                  color: StudioVisuals.ink,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    english ? 'GOT IT' : 'ANLADIM',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    final ColorScheme colors = Theme.of(context).colorScheme;
    if (!_ready) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${context.l10n.gameUi(english ? widget.level.titleEn : widget.level.titleTr)}  •  ${widget.level.number}/${GameContentPolicy.campaignLevels}',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        actions: [
          IconButton(
            tooltip: english ? 'How to play' : 'Nasıl Oynanır?',
            onPressed: () => _showHowToPlay(context, english),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Kompakt durum çubuğu (38px)
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      '${english ? 'Words' : 'Kelime'}: ${_foundWords.length}/${_puzzle.words.length}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: StudioVisuals.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${english ? 'Board' : 'Tahta'} ${_boardIndex + 1}/${widget.level.boardCount}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (_mistakes > 0) ...<Widget>[
                      const SizedBox(width: 8),
                      Text(
                        '•  ✕ $_mistakes',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Color(0xFFD64F63),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.timer_outlined, size: 14, color: StudioVisuals.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${_elapsed}s',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: StudioVisuals.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Aranan Kelimeler (Kaydırmasız - Tüm Kelimeler Ekranda Görünür)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Center(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      for (int index = 0; index < _puzzle.words.length; index++) ...<Widget>[
                        Builder(
                          builder: (BuildContext context) {
                            final String word = _puzzle.words[index];
                            final bool found = _foundWords.contains(word);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: found ? colors.primary.withValues(alpha: 0.12) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: found ? colors.primary : const Color(0xFFD9E2EC),
                                ),
                              ),
                              child: Text(
                                _targetLabel(word, found: found),
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: found ? colors.primary : colors.onSurface,
                                  decoration: found ? TextDecoration.lineThrough : null,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Ana Harf Izgarası (Expanded ile Kaydırmasız Maksimum Boyut)
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints space) {
                    final double boardSize = min(
                      min(space.maxWidth, space.maxHeight),
                      430,
                    );
                    return Center(
                      child: SizedBox(
                        width: boardSize,
                        height: boardSize,
                        child: RawGestureDetector(
                          key: const ValueKey<String>('word_hunt_board'),
                          behavior: HitTestBehavior.opaque,
                          gestures: <Type, GestureRecognizerFactory>{
                            EagerGestureRecognizer:
                                GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                              (EagerGestureRecognizer recognizer) {},
                            ),
                          },
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (PointerDownEvent event) =>
                                _onPointerDown(event, boardSize),
                            onPointerMove: (PointerMoveEvent event) =>
                                _onPointerMove(event, boardSize),
                            onPointerUp: _onPointerUp,
                            onPointerCancel: _onPointerCancel,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[Color(0xFFFFFFFF), Color(0xFFEEF3F0)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _accent.withValues(alpha: 0.48)),
                              ),
                              child: IgnorePointer(
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: widget.level.size * widget.level.size,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: widget.level.size,
                                    crossAxisSpacing: 3,
                                    mainAxisSpacing: 3,
                                  ),
                                  itemBuilder: (BuildContext context, int index) {
                                    final int row = index ~/ widget.level.size;
                                    final int column = index % widget.level.size;
                                    final Point<int> cell = Point<int>(column, row);
                                    final bool selected = _selection.contains(cell);
                                    final bool found = _isFoundCell(cell);
                                    final bool hinted = _hintCell == cell;
                                    return AnimatedContainer(
                                      key: ValueKey<String>('word_cell_${row}_$column'),
                                      duration: const Duration(milliseconds: 130),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: hinted
                                            ? const Color(0xFF8B622C).withValues(alpha: 0.30)
                                            : selected
                                                ? _accent.withValues(alpha: 0.42)
                                                : found
                                                    ? const Color(0xFF34715D).withValues(alpha: 0.20)
                                                    : Colors.white.withValues(alpha: 0.045),
                                        borderRadius: BorderRadius.circular(
                                          widget.level.size >= 8 ? 6 : 9,
                                        ),
                                        border: Border.all(
                                          color: hinted
                                              ? const Color(0xFF8B622C)
                                              : selected || found
                                                  ? _accent
                                                  : StudioVisuals.line,
                                        ),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _puzzle.grid[row][column],
                                          style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: widget.level.size >= 8 ? 15 : 19,
                                            color: StudioVisuals.ink,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Alt Aksiyon Butonları (40px)
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _boardHints >= 2 || _transitioning ? null : _showHint,
                      icon: const Icon(Icons.lightbulb_rounded, size: 16),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${context.l10n.gameUi(english ? 'HINT' : 'İPUCU')} ${2 - _boardHints}/2',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _startRound,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          context.l10n.gameUi(english ? 'NEW BOARD' : 'YENİ TABLO'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Direction {
  final int row;
  final int column;

  const _Direction(this.row, this.column);
}
