import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'word_wheel_puzzle.dart';

@visibleForTesting
List<int> wordWheelDisplayPath(
  List<int> wheelOrder,
  List<int> selectedWheelIndices,
) => selectedWheelIndices
    .map(wheelOrder.indexOf)
    .where((int displayIndex) => displayIndex >= 0)
    .toList(growable: false);

class WordWheelGamePage extends StatelessWidget {
  const WordWheelGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = GameContentPolicy.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    GameContentPolicy.nativeStages('word_wheel'),
    (int index) {
      final int number = index + 1;
      final int stage = (index % 10) + 1;
      return ParkurLevelSpec(
        number: number,
        titleTr: 'Harf Çarkı ${number.toString().padLeft(2, '0')}',
        titleEn: 'Letter Wheel ${number.toString().padLeft(2, '0')}',
        subtitleTr: _stageSubtitle(stage, english: false),
        subtitleEn: _stageSubtitle(stage, english: true),
        difficulty: stage <= 6 ? 'USTALAŞMA' : 'UZMAN',
        icon: Icons.casino_outlined,
      );
    },
    growable: false,
  );

  static String _stageSubtitle(int stage, {required bool english}) =>
      switch (stage) {
        <= 3 =>
          english
              ? 'Find several words from the wheel.'
              : 'Çarktaki harflerden kelimeler bul.',
        <= 6 =>
          english
              ? 'Longer words earn more points.'
              : 'Uzun kelimeler daha çok puan kazandırır.',
        <= 8 =>
          english
              ? 'Choose letters carefully; the wheel gets trickier.'
              : 'Harfleri dikkatle seç; çark giderek zorlaşır.',
        9 =>
          english
              ? 'Find every word in the wheel.'
              : 'Çarktaki tüm kelimeleri bul.',
        _ =>
          english
              ? 'Master the expert letter wheel.'
              : 'Uzman harf çarkını çöz.',
      };

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('word_wheel');
    return ParkurLevelHub(
      gameId: 'word_wheel',
      progressPrefix: 'word_wheel',
      titleTr: 'Kelime Çarkı',
      titleEn: 'Word Wheel',
      taglineTr: 'Çarktan kelime üret • Uzun kelimelerle puanını artır',
      taglineEn: 'Find words in the wheel • Score more with longer words',
      accent: skin.accent,
      icon: Icons.casino_outlined,
      levels: _levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => WordWheelPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class WordWheelPlayPage extends StatefulWidget {
  const WordWheelPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<WordWheelPlayPage> createState() => _WordWheelPlayPageState();
}

class _WordWheelPlayPageState extends State<WordWheelPlayPage> {
  static const Color _accent = Color(0xFF34715D);
  static const Color _accentDark = Color(0xFF3C659D);
  static const Color _jokerOrangeDark = Color(0xFF934612);
  static const int _minimumWordsToComplete = 4;
  static int _pointsForLength(int length) => length * length * 24;

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.language,
  );
  final Set<String> _foundWords = <String>{};
  late final StudioGameSession _session;
  WordWheelPuzzle? _puzzle;
  List<int> _wheelOrder = <int>[];
  final List<int> _selectedLetters = <int>[];
  String? _jokerLetter;
  String? _notice;
  bool _english = false;
  bool _finished = false;
  bool _dragging = false;
  int _hints = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _english = context.l10n.isEnglish;
    if (_puzzle != null) return;
    final String locale = _english ? 'en' : 'tr';
    _puzzle = widget.level.poolIndex == null
        ? WordWheelPuzzle.forLevel(
            widget.level.contentLevel,
            languageCode: locale,
          )
        : WordWheelPuzzle.forPool(
            widget.level.contentIndex,
            languageCode: locale,
          );
    _wheelOrder = List<int>.generate(
      _puzzle!.wheelLetters.length + 1,
      (int i) => i,
    );
  }

  WordWheelPuzzle get _currentPuzzle => _puzzle!;

  int get _jokerIndex => _currentPuzzle.wheelLetters.length;

  List<String> get _wheelLetters => <String>[
    ..._currentPuzzle.wheelLetters,
    '?',
  ];

  List<String> get _jokerKeyboardLetters => _english
      ? const <String>[
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
        ]
      : const <String>[
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

  int get _foundTargetCount =>
      _foundWords.where(_currentPuzzle.isTargetWord).length;

  bool get _canComplete =>
      _foundTargetCount >= _minimumWordsToComplete;

  String? _jokerReplacement() {
    if (!_selectedLetters.contains(_jokerIndex)) return null;
    return _jokerLetter;
  }

  String _letterForSelection(int index) {
    if (index != _jokerIndex) return _currentPuzzle.wheelLetters[index];
    return _jokerReplacement() ?? '?';
  }

  String get _draft => _selectedLetters.map(_letterForSelection).join();

  int get _score => math.max(
    250,
    2600 +
        _foundWords.fold<int>(
          0,
          (int total, String word) =>
              total + _pointsForLength(word.runes.length),
        ) -
        _hints * 180 -
        _session.mistakes * 190 -
        _attempts * 8,
  );

  int get _stars {
    if (_hints == 0 && _session.mistakes <= 1) return 3;
    if (_hints <= 2 && _session.mistakes <= 4) return 2;
    return 1;
  }

  void _appendLetter(int index) {
    if (_finished || _selectedLetters.contains(index)) return;
    setState(() {
      _selectedLetters.add(index);
      _notice = null;
    });
    _audio.hapticLight();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .22),
    );
  }

  void _beginWheelDrag(int index) {
    if (_finished) return;
    setState(() {
      _dragging = true;
      _selectedLetters.clear();
      _jokerLetter = null;
      _selectedLetters.add(index);
      _notice = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .2),
    );
  }

  void _finishWheelDrag() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    _submitWord();
  }

  void _selectWheelIndex(int displayedIndex, {required bool startDrag}) {
    if (displayedIndex < 0 || displayedIndex >= _wheelOrder.length) return;
    final int wheelIndex = _wheelOrder[displayedIndex];
    if (wheelIndex == _jokerIndex) {
      // Joker harfi özellikle dokunarak seçilir; sürükleme sırasında klavye
      // açmak, kelime çizgisini istemeden keser.
      if (!startDrag) _selectJoker();
      return;
    }
    if (startDrag) {
      _beginWheelDrag(wheelIndex);
    } else if (_dragging) {
      _appendLetter(wheelIndex);
    } else {
      _appendLetter(wheelIndex);
    }
  }

  void _removeLastLetter() {
    if (_selectedLetters.isEmpty || _finished) return;
    setState(() {
      final int removed = _selectedLetters.removeLast();
      if (removed == _jokerIndex) _jokerLetter = null;
      _notice = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .22));
  }

  void _shuffleWheel() {
    if (_finished) return;
    setState(() {
      _selectedLetters.clear();
      _jokerLetter = null;
      _wheelOrder = <int>[..._wheelOrder.skip(1), _wheelOrder.first];
      _notice = null;
    });
    unawaited(_audio.play(GameSound.uiClick, gain: .26));
  }

  void _selectJoker() {
    if (_finished || !_session.acceptsInput ||
        _selectedLetters.contains(_jokerIndex)) {
      return;
    }
    setState(() {
      _selectedLetters.add(_jokerIndex);
      _jokerLetter = null;
      _notice = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .2),
    );
    unawaited(_openJokerKeyboard());
  }

  Future<void> _openJokerKeyboard() async {
    final String? letter = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => _JokerLetterKeyboard(
        letters: _jokerKeyboardLetters,
        english: _english,
      ),
    );
    if (!mounted) return;
    if (letter == null) {
      setState(() {
        _selectedLetters.remove(_jokerIndex);
        _jokerLetter = null;
      });
      return;
    }
    setState(() {
      _jokerLetter = letter;
      _notice = _english
          ? 'Joker is now $letter.'
          : 'Joker harfi artık $letter.';
    });
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .22));
  }

  void _showNotice(String message) {
    if (!mounted) return;
    setState(() => _notice = message);
  }

  void _submitWord() {
    if (_finished || _draft.length < 2) {
      if (_draft.isNotEmpty && _draft.length < 2) {
        _showNotice(
          _english ? 'Use at least 2 letters.' : 'En az 2 harf kullan.',
        );
      }
      return;
    }
    if (_selectedLetters.contains(_jokerIndex) && _jokerReplacement() == null) {
      _showNotice(
        _english
            ? 'Choose a few more letters so the joker can complete a word.'
            : 'Joker harfin tamamlayacağı kelimeyi anlayabilmesi için birkaç harf daha seç.',
      );
      return;
    }
    final String word = _draft;
    final String? jokerLetter = _jokerReplacement();
    setState(() {
      _attempts++;
      _selectedLetters.clear();
      _jokerLetter = null;
    });
    if (_foundWords.contains(word)) {
      _showNotice(
        _english ? 'You already found that word.' : 'Bu kelimeyi zaten buldun.',
      );
      return;
    }
    if (!_currentPuzzle.canBuildWord(word, jokerLetter: jokerLetter)) {
      _session.recordMistake();
      _showNotice(
        _english
            ? 'That is not a valid word for these letters. Try another.'
            : 'Bu harflerle kurulabilen geçerli bir kelime değil. Başka bir kelime dene.',
      );
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .24));
      return;
    }

    final bool requiredWord = _currentPuzzle.isTargetWord(word);
    setState(() {
      _foundWords.add(word);
      _notice = _english
          ? 'Nice find — +${_pointsForLength(word.runes.length)} points${requiredWord ? '' : ' · bonus word'}.'
          : 'Güzel buluş — +${_pointsForLength(word.runes.length)} puan${requiredWord ? '' : ' · bonus kelime'}.';
    });
    _session.recordAccepted(points: _pointsForLength(word.runes.length));
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .34));
    if (_canComplete) {
      setState(() {
        _notice = _english
            ? 'Four words found. You can finish the level now.'
            : 'Dört hedef kelime bulundu. Artık bölümü geçebilirsin.';
      });
    }
  }

  void _showHint() {
    if (_finished || !_session.canUseHint) return;
    final List<String> remaining =
        _currentPuzzle.answers
            .where((String word) => !_foundWords.contains(word))
            .toList()
          ..sort(
            (String a, String b) => b.runes.length.compareTo(a.runes.length),
          );
    if (remaining.isEmpty) return;
    final String word = remaining.first;
    final String firstLetter = String.fromCharCode(word.runes.first);
    setState(() {
      _hints++;
      _notice = _english
          ? 'Hint: the longest remaining word has ${word.runes.length} letters and starts with $firstLetter.'
          : 'İpucu: Bulunmamış en uzun kelime ${word.runes.length} harfli ve “$firstLetter” ile başlıyor.';
    });
    _session.useHint(pointCost: 180);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .3));
    _audio.hapticSelection();
  }

  Future<void> _complete() async {
    if (_finished || !_session.acceptsInput || !_canComplete) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.recordAccepted(points: score);
    _session.complete(
      stars: stars,
      action: widget.level.number < WordWheelGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticMedium();
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'KELİME ÇARKI TAMAMLANDI',
      titleEn: 'WORD WHEEL COMPLETE',
      detailTr:
          '${_foundWords.length} kelime bulundu · $_attempts deneme · $_hints ipucu.',
      detailEn:
          '${_foundWords.length} words found · $_attempts attempts · $_hints hints.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < WordWheelGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: score,
        stars: stars,
        action: action,
      ).toParkurResult(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_puzzle == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'WORD WHEEL' : 'KELİME ÇARKI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            Text(
              '${_english ? 'LEVEL' : 'BÖLÜM'} ${widget.level.number} / ${GameContentPolicy.campaignLevels}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('word_wheel_undo'),
            tooltip: _english ? 'Remove last letter' : 'Son harfi sil',
            onPressed: _selectedLetters.isEmpty ? null : _removeLastLetter,
            icon: const Icon(Icons.backspace_outlined),
          ),
          IconButton(
            key: const ValueKey<String>('word_wheel_hint'),
            tooltip: _english ? 'Get a word hint' : 'Kelime ipucu al',
            onPressed: _showHint,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 660,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints limits) {
              final bool compact =
                  limits.maxWidth < 380 || limits.maxHeight < 620;
              final double horizontal = compact ? 12 : 18;
              return Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 2, horizontal, 8),
                child: Column(
                  children: <Widget>[
                    _WordWheelStatus(
                      found: _foundTargetCount,
                      completionTarget: _minimumWordsToComplete,
                      score: _score,
                      bestScore: widget.previousBestScore,
                      english: _english,
                    ),
                    SizedBox(height: compact ? 7 : 10),
                    _FoundWordsCard(
                      words: _foundWords.toList()
                        ..sort(
                          (String a, String b) =>
                              b.runes.length.compareTo(a.runes.length),
                        ),
                      foundTargets: _foundTargetCount,
                      target: _minimumWordsToComplete,
                      english: _english,
                    ),
                    SizedBox(height: compact ? 7 : 10),
                    _DraftWordCard(
                      draft: _draft,
                      notice: _notice,
                      english: _english,
                      draftPoints: _draft.length < 2
                          ? 0
                          : _pointsForLength(_draft.runes.length),
                      onSubmit: _submitWord,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints space) {
                          final double wheelExtent = math.min(
                            math.min(space.maxWidth, space.maxHeight),
                            300,
                          );
                          return Center(
                            child: SizedBox.square(
                              dimension: wheelExtent,
                              child: _LetterWheel(
                                letters: _wheelLetters,
                                jokerIndex: _jokerIndex,
                                jokerReplacement: _jokerReplacement(),
                                order: _wheelOrder,
                                selectedIndices: _selectedLetters,
                                english: _english,
                                onIndex: _selectWheelIndex,
                                onDragEnd: _finishWheelDrag,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _WheelActionButton(
                          key: const ValueKey<String>('word_wheel_shuffle'),
                          icon: Icons.shuffle_rounded,
                          label: _english ? 'SHUFFLE' : 'KARIŞTIR',
                          onTap: _shuffleWheel,
                        ),
                        const SizedBox(width: 10),
                        _WheelActionButton(
                          icon: Icons.backspace_outlined,
                          label: _english ? 'ERASE' : 'SİL',
                          onTap: _removeLastLetter,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _english
                          ? 'Swipe through letters without lifting your finger.'
                          : 'Parmağını kaldırmadan harflerin üzerinden sürükle.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: StudioVisuals.muted,
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _canComplete
                          ? Padding(
                              key: const ValueKey<String>(
                                'word_wheel_complete_button',
                              ),
                              padding: const EdgeInsets.only(top: 7),
                              child: SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: FilledButton.icon(
                                  onPressed: () => unawaited(_complete()),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.flag_rounded),
                                  label: Text(
                                    _english ? 'FINISH LEVEL' : 'BÖLÜMÜ GEÇ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .3,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WordWheelStatus extends StatelessWidget {
  const _WordWheelStatus({
    required this.found,
    required this.completionTarget,
    required this.score,
    required this.bestScore,
    required this.english,
  });

  final int found;
  final int completionTarget;
  final int score;
  final int bestScore;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: StudioVisuals.cardRadius,
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _WordWheelPlayPageState._accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.casino_outlined,
            color: _WordWheelPlayPageState._accent,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'FIND THE WORDS' : 'KELİMELERİ BUL',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .45,
                ),
              ),
              Text(
                '${english ? 'WORDS' : 'KELİME'} $found/$completionTarget · ${english ? 'BEST' : 'REKOR'} $bestScore',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: StudioVisuals.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: <Widget>[
              Text(
                '$score',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _WordWheelPlayPageState._accentDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                english ? 'SCORE' : 'PUAN',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FoundWordsCard extends StatelessWidget {
  const _FoundWordsCard({
    required this.words,
    required this.foundTargets,
    required this.target,
    required this.english,
  });

  final List<String> words;
  final int foundTargets;
  final int target;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    height: 70,
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.auto_awesome_rounded,
              color: _WordWheelPlayPageState._accent,
              size: 15,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                english ? 'FOUND WORDS' : 'BULUNAN KELİMELER',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                ),
              ),
            ),
            Text(
              '$foundTargets/$target',
              key: const ValueKey<String>('word_wheel_found_count'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Expanded(
          child: words.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    english
                        ? 'Longer words score more; extras are bonus.'
                        : 'Uzun kelime daha çok, ek kelime bonus puan.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (
                        int index = 0;
                        index < words.length;
                        index++
                      ) ...<Widget>[
                        if (index > 0) const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _WordWheelPlayPageState._accent.withValues(
                              alpha: .1,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '${words[index]}  +${_WordWheelPlayPageState._pointsForLength(words[index].runes.length)}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: _WordWheelPlayPageState._accentDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
}

class _DraftWordCard extends StatelessWidget {
  const _DraftWordCard({
    required this.draft,
    required this.notice,
    required this.english,
    required this.draftPoints,
    required this.onSubmit,
  });

  final String draft;
  final String? notice;
  final bool english;
  final int draftPoints;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(13, 9, 9, 9),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                draft.isEmpty
                    ? (english ? 'BUILD A WORD' : 'KELİME OLUŞTUR')
                    : draft,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: draft.isEmpty
                      ? StudioVisuals.muted
                      : StudioVisuals.ink,
                  fontSize: draft.isEmpty ? 10 : 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: draft.isEmpty ? .8 : 2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                notice ??
                    (english
                        ? (draftPoints > 0
                              ? '${draft.runes.length} letters · up to +$draftPoints points'
                              : 'Longer words earn more points.')
                        : (draftPoints > 0
                              ? '${draft.runes.length} harf · +$draftPoints puana kadar'
                              : 'Uzun kelimeler daha çok puan kazandırır.')),
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: notice == null
                      ? StudioVisuals.muted
                      : _WordWheelPlayPageState._accentDark,
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 48,
          child: FilledButton(
            key: const ValueKey<String>('word_wheel_submit'),
            onPressed: draft.length < 2 ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: _WordWheelPlayPageState._accent,
              disabledBackgroundColor: StudioVisuals.surfaceSoft,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: draft.length < 2 ? StudioVisuals.muted : Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

class _LetterWheel extends StatelessWidget {
  const _LetterWheel({
    required this.letters,
    required this.jokerIndex,
    required this.jokerReplacement,
    required this.order,
    required this.selectedIndices,
    required this.english,
    required this.onIndex,
    required this.onDragEnd,
  });

  final List<String> letters;
  final int jokerIndex;
  final String? jokerReplacement;
  final List<int> order;
  final List<int> selectedIndices;
  final bool english;
  final void Function(int displayedIndex, {required bool startDrag}) onIndex;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final Size size = Size(constraints.maxWidth, constraints.maxHeight);
      final double minSide = math.min(size.width, size.height);
      final Offset center = Offset(size.width / 2, size.height / 2);
      final double radius = minSide * .35;
      final double nodeSpacing = 2 * radius * math.sin(math.pi / order.length);
      final double tileExtent = math
          .min(48, math.min(minSide * .26, nodeSpacing * .88))
          .clamp(36, 48)
          .toDouble();
      final List<Offset> centers = List<Offset>.generate(order.length, (
        int index,
      ) {
        final double angle =
            -math.pi / 2 + (2 * math.pi * index / order.length);
        return Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );
      }, growable: false);
      int? letterAt(Offset local) {
        for (int index = 0; index < centers.length; index++) {
          if ((centers[index] - local).distance <= tileExtent * .62) {
            return index;
          }
        }
        return null;
      }

      // Keep the line in the order in which the player selected the tiles.
      // Sorting by screen position loses links when the wheel is rotated.
      final List<int> shownSelected = wordWheelDisplayPath(
        order,
        selectedIndices,
      );
      return Semantics(
        label: english
            ? 'Letter wheel. Swipe or tap each letter once.'
            : 'Harf çarkı. Harflere bir kez dokun ya da sürükle.',
        child: GestureDetector(
          key: const ValueKey<String>('word_wheel_letter_wheel'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (TapUpDetails details) {
            final int? index = letterAt(details.localPosition);
            if (index != null) onIndex(index, startDrag: false);
          },
          onPanStart: (DragStartDetails details) {
            final int? index = letterAt(details.localPosition);
            if (index != null) onIndex(index, startDrag: true);
          },
          onPanUpdate: (DragUpdateDetails details) {
            final int? index = letterAt(details.localPosition);
            if (index != null) onIndex(index, startDrag: false);
          },
          onPanEnd: (_) => onDragEnd(),
          child: CustomPaint(
            painter: _LetterWheelPainter(
              centers: centers,
              selected: shownSelected,
            ),
            child: Stack(
              children: <Widget>[
                for (
                  int displayIndex = 0;
                  displayIndex < order.length;
                  displayIndex++
                )
                  Positioned(
                    left: centers[displayIndex].dx - tileExtent / 2,
                    top: centers[displayIndex].dy - tileExtent / 2,
                    child: IgnorePointer(
                      child: Container(
                        key: ValueKey<String>(
                          'word_wheel_letter_${order[displayIndex]}',
                        ),
                        width: tileExtent,
                        height: tileExtent,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors:
                                selectedIndices.contains(order[displayIndex])
                                ? const <Color>[
                                    Color(0xFF5B88C8),
                                    Color(0xFF3C659D),
                                  ]
                                : order[displayIndex] == jokerIndex
                                ? const <Color>[
                                    Color(0xFFFFB45B),
                                    Color(0xFFD97726),
                                  ]
                                : const <Color>[
                                    Colors.white,
                                    Color(0xFFF0F4F8),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedIndices.contains(order[displayIndex])
                                ? _WordWheelPlayPageState._accentDark
                                : order[displayIndex] == jokerIndex
                                ? _WordWheelPlayPageState._jokerOrangeDark
                                : const Color(0xFFD9E2EC),
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x1534475A),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          order[displayIndex] == jokerIndex
                              ? (jokerReplacement ?? '?')
                              : letters[order[displayIndex]],
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: selectedIndices.contains(order[displayIndex])
                                ? Colors.white
                                : StudioVisuals.ink,
                            fontSize: tileExtent * .44,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _LetterWheelPainter extends CustomPainter {
  const _LetterWheelPainter({required this.centers, required this.selected});

  final List<Offset> centers;
  final List<int> selected;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = centers.isEmpty
        ? 0
        : (centers.first - center).distance;
    canvas.drawCircle(
      center,
      radius + 28,
      Paint()..color = _WordWheelPlayPageState._accent.withValues(alpha: .045),
    );
    canvas.drawCircle(
      center,
      radius + 27,
      Paint()
        ..color = _WordWheelPlayPageState._jokerOrangeDark.withValues(alpha: .86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );
    if (selected.length < 2) return;
    final Paint line = Paint()
      ..color = _WordWheelPlayPageState._accent.withValues(alpha: .58)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(centers[selected.first].dx, centers[selected.first].dy);
    for (final int index in selected.skip(1)) {
      path.lineTo(centers[index].dx, centers[index].dy);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(_LetterWheelPainter oldDelegate) =>
      oldDelegate.centers != centers || oldDelegate.selected != selected;
}

class _JokerLetterKeyboard extends StatelessWidget {
  const _JokerLetterKeyboard({required this.letters, required this.english});

  final List<String> letters;
  final bool english;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: StudioVisuals.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB45B),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _WordWheelPlayPageState._jokerOrangeDark,
                    width: 2,
                  ),
                ),
                child: const Text(
                  '?',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      english ? 'CHOOSE JOKER LETTER' : 'JOKER HARFİ SEÇ',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: StudioVisuals.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      english
                          ? 'The selected uppercase letter replaces the joker.'
                          : 'Seçtiğin büyük harf jokerin yerine geçer.',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: StudioVisuals.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: letters.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (BuildContext context, int index) {
              final String letter = letters[index];
              return Semantics(
                button: true,
                label: '${english ? 'Joker letter' : 'Joker harfi'} $letter',
                child: FilledButton(
                  key: ValueKey<String>('word_wheel_joker_key_$letter'),
                  onPressed: () => Navigator.of(context).pop(letter),
                  style: FilledButton.styleFrom(
                    backgroundColor: StudioVisuals.surfaceSoft,
                    foregroundColor: StudioVisuals.ink,
                    side: const BorderSide(color: StudioVisuals.line),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _WheelActionButton extends StatelessWidget {
  const _WheelActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: .35,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _WordWheelPlayPageState._accentDark,
        side: const BorderSide(color: Color(0xFFD6E0EB)),
        backgroundColor: StudioVisuals.surface,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
