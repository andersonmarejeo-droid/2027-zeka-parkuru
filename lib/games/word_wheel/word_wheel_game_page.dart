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
  final Set<String> _bonusWords = <String>{};
  final Set<String> _hintedWords = <String>{};
  late final StudioGameSession _session;
  WordWheelPuzzle? _puzzle;
  List<int> _wheelOrder = <int>[];
  final List<int> _selectedLetters = <int>[];
  String? _jokerLetter;
  String? _notice;
  bool _english = false;
  String _languageCode = 'tr';
  bool _finished = false;
  bool _dragging = false;
  int _hints = 0;
  int _attempts = 0;
  Timer? _autoSubmitTimer;

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
  void dispose() {
    _autoSubmitTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _english = context.l10n.isEnglish;
    final String rawCode = Localizations.localeOf(context).languageCode;
    _languageCode = WordWheelPuzzle.canonicalLocale(rawCode);
    if (_puzzle != null) return;
    _puzzle = widget.level.poolIndex == null
        ? WordWheelPuzzle.forLevel(
            widget.level.contentLevel,
            languageCode: _languageCode,
          )
        : WordWheelPuzzle.forPool(
            widget.level.contentIndex,
            languageCode: _languageCode,
          );
    _wheelOrder = List<int>.generate(
      _puzzle!.wheelLetters.length + 1,
      (int i) => i,
    );
  }

  String _t({required String tr, required String en, required String ar}) {
    if (_languageCode == 'ar') return ar;
    if (_languageCode == 'tr') return tr;
    return en;
  }

  WordWheelPuzzle get _currentPuzzle => _puzzle!;

  int get _jokerIndex => _currentPuzzle.wheelLetters.length;

  List<String> get _wheelLetters => <String>[
    ..._currentPuzzle.wheelLetters,
    '?',
  ];

  List<String> get _jokerKeyboardLetters => switch (_languageCode) {
    'tr' => const <String>[
      'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H', 'I', 'İ',
      'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', 'S', 'Ş', 'T',
      'U', 'Ü', 'V', 'Y', 'Z',
    ],
    'ar' => const <String>[
      'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س',
      'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م',
      'ن', 'ه', 'و', 'ي', 'ة',
    ],
    _ => const <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
      'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
      'Y', 'Z',
    ],
  };

  bool get _canComplete =>
      _foundWords.length >= _minimumWordsToComplete;

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

  void _cancelAutoSubmit() {
    _autoSubmitTimer?.cancel();
    _autoSubmitTimer = null;
  }

  void _scheduleAutoSubmit() {
    _cancelAutoSubmit();
    if (_finished || _draft.runes.length < 4) return;
    final String word = _draft;
    final String? jokerLetter = _jokerReplacement();
    if (!_currentPuzzle.canBuildWord(word, jokerLetter: jokerLetter)) return;
    final String normalizedWord = _currentPuzzle.normalizeWord(word);
    if (_foundWords.contains(normalizedWord)) return;

    final bool isAnswer = _currentPuzzle.answers.contains(normalizedWord);
    final bool hasLongerAnswer = _currentPuzzle.answers.any(
      (String a) =>
          a.length > normalizedWord.length &&
          a.startsWith(normalizedWord) &&
          !_foundWords.contains(a),
    );

    final Duration delay = isAnswer && !hasLongerAnswer
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 700);

    _autoSubmitTimer = Timer(delay, () {
      if (!mounted || _finished) return;
      _submitWord();
    });
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
    if (!_dragging) {
      _scheduleAutoSubmit();
    }
  }

  void _beginWheelDrag(int index) {
    if (_finished) return;
    _cancelAutoSubmit();
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
    _cancelAutoSubmit();
    setState(() {
      final int removed = _selectedLetters.removeLast();
      if (removed == _jokerIndex) _jokerLetter = null;
      _notice = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .22));
    _scheduleAutoSubmit();
  }

  void _shuffleWheel() {
    if (_finished) return;
    _cancelAutoSubmit();
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
        title: _t(
          tr: 'JOKER HARFİ SEÇ',
          en: 'CHOOSE JOKER LETTER',
          ar: 'اختر الحرف البديل',
        ),
        subtitle: _t(
          tr: 'Seçtiğin harf jokerin yerine geçer.',
          en: 'The selected letter replaces the joker.',
          ar: 'الحرف المحدد سيحل محل الحرف البديل.',
        ),
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
      _notice = _t(
        tr: 'Joker harfi artık $letter.',
        en: 'Joker is now $letter.',
        ar: 'الحرف البديل الآن هو $letter.',
      );
    });
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .22));
    _scheduleAutoSubmit();
  }

  void _showNotice(String message) {
    if (!mounted) return;
    setState(() => _notice = message);
  }

  void _submitWord() {
    _cancelAutoSubmit();
    if (_finished || _draft.runes.length < 4) {
      if (_draft.isNotEmpty && _draft.runes.length < 4) {
        _showNotice(
          _t(
            tr: 'En az 4 harf kullan. (2 ve 3 harfliler kabul edilmez)',
            en: 'Use at least 4 letters. (2 and 3-letter words are not accepted)',
            ar: 'استخدم 4 أحرف على الأقل. (لا تقبل الكلمات من حرفين أو 3)',
          ),
        );
        _audio.hapticLight();
        unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      }
      return;
    }
    if (_selectedLetters.contains(_jokerIndex) && _jokerReplacement() == null) {
      _showNotice(
        _t(
          tr: 'Joker harfin tamamlayacağı kelimeyi anlayabilmesi için birkaç harf daha seç.',
          en: 'Choose a few more letters so the joker can complete a word.',
          ar: 'اختر المزيد من الأحرف ليكتمل الحرف البديل.',
        ),
      );
      return;
    }
    final String word = _draft;
    final String normalizedWord = _currentPuzzle.normalizeWord(word);
    final String? jokerLetter = _jokerReplacement();
    setState(() {
      _selectedLetters.clear();
      _jokerLetter = null;
    });

    // AYNI KELİME KONTROLÜ: Tekrar girilen kelimelere asla puan verilmez
    if (_foundWords.contains(normalizedWord)) {
      _showNotice(
        _t(
          tr: 'Bu kelimeyi zaten buldun! (Tekrar puan verilmez)',
          en: 'You already found that word! (No points awarded)',
          ar: 'لقد وجدت هذه الكلمة بالفعل! (لن تمنح نقاط مكررة)',
        ),
      );
      _audio.hapticLight();
      unawaited(_audio.play(GameSound.uiClick, gain: .24));
      return;
    }

    _attempts++;
    if (!_currentPuzzle.canBuildWord(word, jokerLetter: jokerLetter)) {
      _session.recordMistake();
      _showNotice(
        _t(
          tr: 'Bu harflerle kurulabilen geçerli bir kelime değil. Başka bir kelime dene.',
          en: 'That is not a valid word for these letters. Try another.',
          ar: 'هذه الكلمة غير صالحة من هذه الأحرف. جرب كلمة أخرى.',
        ),
      );
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .24));
      return;
    }

    final bool isAnswer = _currentPuzzle.answers.contains(normalizedWord);
    setState(() {
      _foundWords.add(normalizedWord);
      if (!isAnswer) {
        _bonusWords.add(normalizedWord);
      }
      _notice = isAnswer
          ? _t(
              tr: '$normalizedWord bulundu — +${_pointsForLength(normalizedWord.runes.length)} puan.',
              en: '$normalizedWord found — +${_pointsForLength(normalizedWord.runes.length)} points.',
              ar: 'تم العثور على $normalizedWord — +${_pointsForLength(normalizedWord.runes.length)} نقطة.',
            )
          : _t(
              tr: 'Tebrikler! $normalizedWord bonus kelime olarak eklendi (+${_pointsForLength(normalizedWord.runes.length)} puan).',
              en: 'Bonus word! $normalizedWord added (+${_pointsForLength(normalizedWord.runes.length)} points).',
              ar: 'كلمة إضافية! تمت إضافة $normalizedWord (+${_pointsForLength(normalizedWord.runes.length)} نقطة).',
            );
    });
    _session.recordAccepted(points: _pointsForLength(normalizedWord.runes.length));
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .34));
    if (_canComplete) {
      setState(() {
        _notice = _t(
          tr: 'Tebrikler! Dört hedef kelime bulundu, geçiliyor...',
          en: 'Level completed! Advancing...',
          ar: 'تهانينا! تم العثور على الكلمات المطلوبة، جاري الانتقال...',
        );
      });
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted && !_finished) {
          unawaited(_complete());
        }
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
      _hintedWords.add(word);
      _notice = _t(
        tr: 'İpucu: Bulunmamış en uzun kelime ${word.runes.length} harfli ve “$firstLetter” ile başlıyor.',
        en: 'Hint: the longest remaining word has ${word.runes.length} letters and starts with $firstLetter.',
        ar: 'تلميح: أطول كلمة متبقية تتكون من ${word.runes.length} أحرف وتبدأ بـ "$firstLetter".',
      );
    });
    _session.useHint(pointCost: 180);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .3));
    _audio.hapticSelection();
  }

  void _showBonusWordsSheet() {
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
                  const Icon(Icons.stars_rounded, color: Color(0xFFD97726), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    _english ? 'BONUS WORDS' : 'BONUS KELİMELER',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: StudioVisuals.ink,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_bonusWords.length} ${_english ? 'words' : 'kelime'}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: Color(0xFF934612),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _english
                    ? 'Extra valid words found that are not in the main target slots:'
                    : 'Ana hedef kutularında yer almayan fakat çarktan ürettiğin ekstra geçerli kelimeler:',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: StudioVisuals.muted,
                ),
              ),
              const SizedBox(height: 14),
              if (_bonusWords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text(
                    _english
                        ? 'No bonus words found yet. Try finding extra words!'
                        : 'Henüz bonus kelime bulunmadı. Çarktan ek kelimeler türeterek bonus kazan!',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: StudioVisuals.muted,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _bonusWords.map((String word) {
                    final int points = _pointsForLength(word.runes.length);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: StudioVisuals.surfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE0B2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: StudioVisuals.ink,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$points',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97726),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
                    _english ? 'CONTINUE' : 'DEVAM ET',
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

  void _showHowToPlay() {
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
                    _english ? 'How to Play?' : 'Nasıl Oynanır?',
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
                _english
                    ? '• Swipe through adjacent letters on the wheel to form valid words.\n'
                      '• Tap or drag into the center joker to replace it with any letter.\n'
                      '• Reach the target word count to complete the course.\n'
                      '• Longer words award higher scores!'
                    : '• Parmağını harflerin üzerinde kaydırarak anlamlı Türkçe kelimeler üret.\n'
                      '• Ortadaki joker harfi istediğin harfin yerine kullanabilirsin.\n'
                      '• Hedef kelime sayısına ulaşarak parkuru tamamla.\n'
                      '• Daha uzun kelimeler çok daha fazla puan kazandırır!',
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
                    _english ? 'GOT IT' : 'ANLADIM',
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
                fontSize: 14,
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
            tooltip: _english ? 'How to play' : 'Nasıl Oynanır?',
            onPressed: _showHowToPlay,
            icon: const Icon(Icons.help_outline_rounded),
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
          maxContentWidth: 620,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: <Widget>[
                // Kompakt durum çubuğu (38px)
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudioVisuals.line),
                  ),
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          _english ? 'FOUND WORDS' : 'BULUNAN KELİMELER',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.muted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_foundWords.length}/$_minimumWordsToComplete',
                        key: const ValueKey<String>('word_wheel_found_count'),
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: StudioVisuals.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (_bonusWords.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 8),
                        GestureDetector(
                          key: const ValueKey<String>('word_wheel_bonus_badge'),
                          onTap: _showBonusWordsSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4E5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFB45B)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97726)),
                                const SizedBox(width: 2),
                                Text(
                                  '+${_bonusWords.length} Bonus',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    color: Color(0xFF934612),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '🏆 $_score',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: _accentDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (widget.previousBestScore > 0) ...<Widget>[
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.previousBestScore})',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Hedef Kelime Kutuları Tablosu (Wordscapes tarzı boşluk doldurma)
                _WordSlotsBoard(
                  answers: _currentPuzzle.answers,
                  foundWords: _foundWords,
                  hintedWords: _hintedWords,
                ),
                const SizedBox(height: 6),

                // Taslak Kelime Giriş Kartı (Kompakt)
                _DraftWordCard(
                  draft: _draft,
                  notice: _notice,
                  english: _english,
                  draftPoints: _draft.length < 2
                      ? 0
                      : _pointsForLength(_draft.runes.length),
                  onSubmit: _submitWord,
                ),
                const SizedBox(height: 6),

                // Ana Çark Alanı (Expanded ile ferah ve kaydırmasız)
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints space) {
                      // Çember boyutu kullanıcının ekranına tam oturacak şekilde optimize edildi
                      final double wheelExtent = math.min(
                        math.min(space.maxWidth, space.maxHeight),
                        288,
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
                const SizedBox(height: 6),

                // Alt Aksiyon Butonları (Kompakt 40px, taşmasız)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
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
                      if (_canComplete) ...<Widget>[
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          key: const ValueKey<String>('word_wheel_complete_button'),
                          onPressed: () => unawaited(_complete()),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.flag_rounded, size: 16),
                          label: Text(
                            _english ? 'FINISH' : 'GEÇ',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _WordSlotsBoard extends StatelessWidget {
  const _WordSlotsBoard({
    required this.answers,
    required this.foundWords,
    required this.hintedWords,
  });

  final List<String> answers;
  final Set<String> foundWords;
  final Set<String> hintedWords;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StudioVisuals.line),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 5,
          children: answers.map((String answer) {
            final bool isFound = foundWords.contains(answer);
            final bool isHinted = hintedWords.contains(answer);
            final List<String> chars = answer.runes
                .map((int r) => String.fromCharCode(r).toUpperCase())
                .toList();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                color: isFound
                    ? const Color(0xFFE8F5E9)
                    : StudioVisuals.surfaceSoft,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isFound
                      ? const Color(0xFF81C784)
                      : const Color(0xFFD6E0EB),
                  width: isFound ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(chars.length, (int i) {
                  final String char = chars[i];
                  final bool showChar = isFound || (isHinted && i == 0);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 17,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFound
                          ? _WordWheelPlayPageState._accent
                          : (showChar ? const Color(0xFFFFECC8) : Colors.white),
                      borderRadius: BorderRadius.circular(3.5),
                      border: Border.all(
                        color: isFound
                            ? _WordWheelPlayPageState._accent
                            : (showChar ? const Color(0xFFFFB45B) : const Color(0xFFCFD8DC)),
                        width: 1,
                      ),
                      boxShadow: isFound
                          ? const [
                              BoxShadow(
                                color: Color(0x2034715D),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      showChar ? char : '',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isFound
                            ? Colors.white
                            : (showChar ? const Color(0xFFB25E00) : Colors.transparent),
                      ),
                    ),
                  );
                }),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
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
      // Çemberi biraz daha daraltıyoruz
      final double wheelRadius = minSide * .325;
      // Harf butonunun boyutu: orantılı şekilde daraltıldı (36 - 42 px)
      final double tileExtent = (wheelRadius * .35).clamp(36.0, 42.0);
      final double tileRadius = tileExtent / 2;
      // Harflerin çembere binmeyip tamamen içeride kalması için:
      const double marginInside = 8.0;
      final double letterRadius = wheelRadius - tileRadius - marginInside;
      final List<Offset> centers = List<Offset>.generate(order.length, (
        int index,
      ) {
        final double angle =
            -math.pi / 2 + (2 * math.pi * index / order.length);
        return Offset(
          center.dx + math.cos(angle) * letterRadius,
          center.dy + math.sin(angle) * letterRadius,
        );
      }, growable: false);
      int? letterAt(Offset local) {
        for (int index = 0; index < centers.length; index++) {
          if ((centers[index] - local).distance <= tileExtent * .75) {
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
              wheelRadius: wheelRadius,
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
  const _LetterWheelPainter({
    required this.centers,
    required this.selected,
    required this.wheelRadius,
  });

  final List<Offset> centers;
  final List<int> selected;
  final double wheelRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Radyal degrade arka plan diski
    final Paint bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _WordWheelPlayPageState._accent.withValues(alpha: .015),
          _WordWheelPlayPageState._accent.withValues(alpha: .065),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: wheelRadius));
    canvas.drawCircle(center, wheelRadius, bgPaint);

    // Çift katmanlı dış sınır çerçevesi
    canvas.drawCircle(
      center,
      wheelRadius,
      Paint()
        ..color = _WordWheelPlayPageState._jokerOrangeDark.withValues(alpha: .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    canvas.drawCircle(
      center,
      wheelRadius - 3.5,
      Paint()
        ..color = _WordWheelPlayPageState._jokerOrangeDark.withValues(alpha: .2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    if (selected.length < 2) return;

    // Glowing parlama katmanı
    final Paint glowLine = Paint()
      ..color = _WordWheelPlayPageState._accentDark.withValues(alpha: .22)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(centers[selected.first].dx, centers[selected.first].dy);
    for (final int index in selected.skip(1)) {
      path.lineTo(centers[index].dx, centers[index].dy);
    }
    canvas.drawPath(path, glowLine);

    // Ana canlı kaydırma yolu
    final Paint coreLine = Paint()
      ..color = _WordWheelPlayPageState._accentDark.withValues(alpha: .85)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, coreLine);
  }

  @override
  bool shouldRepaint(_LetterWheelPainter oldDelegate) =>
      oldDelegate.centers != centers ||
      oldDelegate.selected != selected ||
      oldDelegate.wheelRadius != wheelRadius;
}

class _JokerLetterKeyboard extends StatelessWidget {
  const _JokerLetterKeyboard({
    required this.letters,
    this.title,
    this.subtitle,
  });

  final List<String> letters;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    return SafeArea(
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
                      title ?? (english ? 'CHOOSE JOKER LETTER' : 'JOKER HARFİ SEÇ'),
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
                      subtitle ??
                          (english
                              ? 'The selected uppercase letter replaces the joker.'
                              : 'Seçtiğin büyük harf jokerin yerine geçer.'),
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
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .35,
          ),
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
