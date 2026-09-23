import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../services/replayability_service.dart';
import '../shared/parkur_game_kit.dart';
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
      accent: const Color(0xFF00D9A6),
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
              fixedSessionSeed: fixedSessionSeed,
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
  static const Color _accent = Color(0xFF00D9A6);
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

    unawaited(_audio.play(GameSound.levelComplete));
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
      canGoNext: widget.level.number < WordHuntGamePage.levels.length,
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

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
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
          '${context.l10n.gameUi(english ? widget.level.titleEn : widget.level.titleTr)}  •  ${widget.level.number}/10',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints limits) {
            final double boardSize = min(limits.maxWidth - 28, 430);
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              children: <Widget>[
                _WordHeader(
                  found: _foundWords.length,
                  total: _puzzle.words.length,
                  boardNumber: _boardIndex + 1,
                  boardTotal: widget.level.boardCount,
                  elapsed: _elapsed,
                  mistakes: _mistakes,
                  english: english,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 7,
                  runSpacing: 7,
                  children: _puzzle.words
                      .map((String word) {
                        final bool found = _foundWords.contains(word);
                        return AnimatedContainer(
                          key: ValueKey<String>('word_target_$word'),
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: found
                                ? _accent.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: found ? _accent : Colors.white12,
                            ),
                          ),
                          child: Text(
                            _targetLabel(word, found: found),
                            style: TextStyle(
                              color: found ? _accent : Colors.white70,
                              decoration: found
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 13),
                Center(
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: RawGestureDetector(
                      key: const ValueKey<String>('word_hunt_board'),
                      behavior: HitTestBehavior.opaque,
                      gestures: <Type, GestureRecognizerFactory>{
                        EagerGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                              EagerGestureRecognizer
                            >(
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
                              colors: <Color>[
                                Color(0xFF102B50),
                                Color(0xFF093E4B),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.48),
                            ),
                          ),
                          child: IgnorePointer(
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.level.size * widget.level.size,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
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
                                  key: ValueKey<String>(
                                    'word_cell_${row}_$column',
                                  ),
                                  duration: const Duration(milliseconds: 130),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: hinted
                                        ? const Color(0xFFFFD334)
                                              .withValues(alpha: 0.30)
                                        : selected
                                        ? _accent.withValues(alpha: 0.42)
                                        : found
                                        ? const Color(0xFF6CFF9B)
                                              .withValues(alpha: 0.20)
                                        : Colors.white.withValues(alpha: 0.045),
                                    borderRadius: BorderRadius.circular(
                                      widget.level.size >= 8 ? 7 : 10,
                                    ),
                                    border: Border.all(
                                      color: hinted
                                          ? const Color(0xFFFFD334)
                                          : selected || found
                                          ? _accent
                                          : Colors.white10,
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _puzzle.grid[row][column],
                                      style: TextStyle(
                                        fontSize: widget.level.size >= 8
                                            ? 15
                                            : 19,
                                        color: hinted
                                            ? const Color(0xFFFFE98A)
                                            : Colors.white,
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
                ),
                const SizedBox(height: 13),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _boardHints >= 2 || _transitioning
                            ? null
                            : _showHint,
                        icon: const Icon(Icons.lightbulb_rounded),
                        label: Text(
                          '${context.l10n.gameUi(english ? 'HINT' : 'İPUCU')} ${2 - _boardHints}/2',
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _startRound,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(
                          context.l10n.gameUi(
                            english ? 'NEW BOARD' : 'YENİ TABLO',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  context.l10n.gameUi(
                    english
                        ? 'Swipe with direction snapping, or tap the first and last letters. Every new round creates a different board.'
                        : 'Kolay seçim için sürükle veya ilk ve son harfe dokun. Her yeni turda farklı tablo oluşur.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WordHeader extends StatelessWidget {
  final int found;
  final int total;
  final int boardNumber;
  final int boardTotal;
  final int elapsed;
  final int mistakes;
  final bool english;

  const _WordHeader({
    required this.found,
    required this.total,
    required this.boardNumber,
    required this.boardTotal,
    required this.elapsed,
    required this.mistakes,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF102B50),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.dashboard_customize_rounded,
                color: Color(0xFF00D9A6),
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                '${context.l10n.gameUi(english ? 'BOARD' : 'TABLO')} $boardNumber/$boardTotal',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _WordStat(
                icon: Icons.search_rounded,
                value: '$found/$total',
                label: context.l10n.gameUi(english ? 'FOUND' : 'BULUNAN'),
                color: const Color(0xFF00D9A6),
              ),
              _WordStat(
                icon: Icons.timer_outlined,
                value: '${elapsed}s',
                label: context.l10n.gameUi(english ? 'TIME' : 'SÜRE'),
                color: const Color(0xFF00D9FF),
              ),
              _WordStat(
                icon: Icons.close_rounded,
                value: '$mistakes',
                label: context.l10n.gameUi(english ? 'MISS' : 'HATA'),
                color: const Color(0xFFFF6B81),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _WordStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w800,
                  fontSize: 7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Direction {
  final int row;
  final int column;

  const _Direction(this.row, this.column);
}
