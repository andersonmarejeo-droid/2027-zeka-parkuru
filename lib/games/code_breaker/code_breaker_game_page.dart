import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'code_breaker_puzzle.dart';

class CodeBreakerGamePage extends StatelessWidget {
  const CodeBreakerGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = CodeBreakerPuzzle.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Kod Kırıcı ${level.toString().padLeft(2, '0')}',
        titleEn: 'Code Breaker ${level.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: switch (stage) {
          <= 6 => chapter == 1 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.password_rounded,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'More code slots and symbols; preserve every deduction.'
          : 'Daha fazla kod gözü ve sembol; her çıkarımı koru.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Use exact-position and wrong-position feedback.'
            : 'Doğru yerdeki ve yanlış yerdeki işaretleri birlikte kullan.',
      <= 6 =>
        english
            ? 'Test a theory, then eliminate every inconsistent code.'
            : 'Bir varsayımı dene; uymayan kodları ele.',
      7 || 8 =>
        english
            ? 'Advanced: repeated symbols create overlapping counts.'
            : 'İleri: tekrar eden semboller sayımları iç içe geçirir.',
      9 =>
        english
            ? 'Expert: solve a larger palette with no duplicate pegs.'
            : 'Uzman: tekrarsız taşlarla geniş paleti çöz.',
      _ =>
        english
            ? 'Master code: reason across six slots and ten symbols.'
            : 'Usta kodu: altı göz ve on sembol boyunca çıkarım yap.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.logic);
    return ParkurLevelHub(
      gameId: 'code_breaker',
      progressPrefix: 'code_breaker',
      titleTr: 'Kod Kırıcı',
      titleEn: 'Code Breaker',
      taglineTr: 'Tahmin et • İşaretleri çöz • Kodu ele geçir',
      taglineEn: 'Guess • Read the clues • Break the code',
      accent: skin.accent,
      icon: Icons.password_rounded,
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
          ) => CodeBreakerPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class CodeBreakerPlayPage extends StatefulWidget {
  const CodeBreakerPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<CodeBreakerPlayPage> createState() => _CodeBreakerPlayPageState();
}

class _CodeBreakerPlayPageState extends State<CodeBreakerPlayPage> {
  static const Color _accent = Color(0xFF647F78);
  static const Color _ink = Color(0xFF29373A);
  static const List<Color> _palette = <Color>[
    Color(0xFF3B6FA3),
    Color(0xFFBA625A),
    Color(0xFF5D8C70),
    Color(0xFF8A6CAA),
    Color(0xFFD39B41),
    Color(0xFF4F9B9D),
    Color(0xFFC57491),
    Color(0xFF687783),
    Color(0xFFA87955),
    Color(0xFF333D44),
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  final List<_CodeGuess> _history = <_CodeGuess>[];
  final Map<int, int> _revealedSlots = <int, int>{};

  late CodeBreakerPuzzle _puzzle;
  late StudioGameSession _session;
  late List<int?> _draft;
  int _activeSlot = 0;
  int _mistakes = 0;
  bool _ready = false;
  bool _finished = false;
  bool _exhausted = false;
  bool _failureDialogOpen = false;
  bool _english = false;
  String? _notice;

  int get _score => math.max(
    0,
    5000 - _history.length * 110 - _revealedSlots.length * 320 - _mistakes * 80,
  );

  int get _maxRevealHints => math.min(
    StudioGameSession.defaultMaxHints,
    math.max(0, _puzzle.slots - 1),
  ).toInt();

  int get _stars {
    if (_revealedSlots.isEmpty && _history.length <= 3) return 3;
    if (_revealedSlots.length <= 1 && _history.length <= 7) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_preparePuzzle());
  }

  Future<void> _preparePuzzle() async {
    CodeBreakerPuzzle puzzle = CodeBreakerPuzzle.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'code_breaker_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('code_breaker_practice_index') ?? 0;
        if (index < CodeBreakerPuzzle.maximumVerifiedBoards) {
          final int next = index + 1;
          await preferences.setInt('code_breaker_practice_index', next);
          puzzle = CodeBreakerPuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = CodeBreakerPuzzle.forLevel(widget.level.number);
    }
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: puzzle.seed,
      )..start();
      _draft = List<int?>.filled(puzzle.slots, null);
      _history.clear();
      _revealedSlots.clear();
      _activeSlot = 0;
      _mistakes = 0;
      _notice = null;
      _finished = false;
      _exhausted = false;
      _failureDialogOpen = false;
      _ready = true;
    });
  }

  void _selectSlot(int slot) {
    if (!_ready || _finished || _exhausted) return;
    setState(() {
      _activeSlot = slot;
      _notice = null;
    });
    _audio.hapticSelection();
  }

  void _chooseSymbol(int symbol) {
    if (!_ready || _finished || _exhausted) return;
    if (_revealedSlots.containsKey(_activeSlot)) {
      setState(() {
        _notice = _english
            ? 'That symbol is fixed by your certified hint.'
            : 'Doğrulanmış ipucu bu gözdeki sembolü sabitledi.';
      });
      return;
    }
    if (!_puzzle.repeatsAllowed &&
        _draft.asMap().entries.any(
          (MapEntry<int, int?> entry) =>
              entry.key != _activeSlot && entry.value == symbol,
        )) {
      _session.recordMistake();
      setState(() {
        _mistakes++;
        _notice = _english
            ? 'This code uses distinct symbols; choose a different unused one.'
            : 'Bu kodda semboller tekrarsız; kullanılmamış başka birini seç.';
      });
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
      return;
    }
    setState(() {
      _draft[_activeSlot] = symbol;
      _notice = null;
      final int nextEmpty = _draft.indexWhere((int? value) => value == null);
      if (nextEmpty >= 0) _activeSlot = nextEmpty;
    });
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .14));
  }

  void _undo() {
    if (!_ready || _finished || _exhausted) return;
    final int last = List<int>.generate(_draft.length, (int index) => index)
        .lastWhere(
          (int index) =>
              _draft[index] != null && !_revealedSlots.containsKey(index),
          orElse: () => -1,
        );
    if (last < 0) return;
    setState(() {
      _draft[last] = null;
      _activeSlot = last;
      _notice = _english ? 'Last symbol removed.' : 'Son sembol silindi.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _submit() {
    if (!_ready || _finished || _exhausted) return;
    if (_draft.any((int? value) => value == null)) {
      setState(() {
        _notice = _english
            ? 'Fill every slot before submitting the code.'
            : 'Kodu göndermeden önce bütün gözleri doldur.';
      });
      _audio.hapticLight();
      return;
    }
    final List<int> guess = _draft.cast<int>().toList(growable: false);
    if (!_puzzle.isValidGuess(guess)) {
      setState(() {
        _notice = _english
            ? 'This level does not allow duplicate symbols.'
            : 'Bu seviyede yinelenen sembol kullanılamaz.';
      });
      return;
    }
    final CodeFeedback feedback = _puzzle.evaluate(guess);
    setState(() {
      _history.add(_CodeGuess(guess: guess, feedback: feedback));
      _draft = List<int?>.filled(_puzzle.slots, null);
      _activeSlot = 0;
      _notice = _english
          ? '${feedback.exact} exact · ${feedback.misplaced} correct symbol(s) in another slot.'
          : '${feedback.exact} doğru yerde · ${feedback.misplaced} doğru sembol başka gözde.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
    if (_puzzle.isSolved(guess)) {
      _session.recordAccepted(points: 60);
      unawaited(_finish());
    } else if (_history.length >= _puzzle.maximumGuesses) {
      setState(() => _exhausted = true);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .25));
    }
  }

  void _showHint() {
    if (!_ready || _finished || _exhausted || !_session.canUseHint) return;
    if (_revealedSlots.length >= _maxRevealHints) return;
    final List<int> hidden = <int>[
      for (int index = 0; index < _puzzle.slots; index++)
        if (!_revealedSlots.containsKey(index)) index,
    ];
    final int slot = hidden.first;
    _session.useHint(pointCost: 320);
    setState(() {
      _revealedSlots[slot] = _puzzle.secret[slot];
      _draft[slot] = _puzzle.secret[slot];
      _activeSlot = _draft.indexWhere((int? value) => value == null);
      if (_activeSlot < 0) _activeSlot = slot;
      _notice = _english
          ? 'Certified hint: slot ${slot + 1} is locked to this symbol.'
          : 'Doğrulanmış ipucu: ${slot + 1}. gözdeki sembol kesinleşti.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .25));
  }

  Future<void> _confirmReset() async {
    if (!_ready || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'Reset this code?' : 'Bu kod sıfırlansın mı?'),
        content: Text(
          _english
              ? 'The same secret and the same rule set will be restored.'
              : 'Aynı gizli kod ve aynı kural seti yeniden kurulacak.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep solving' : 'Çözmeye devam et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_english ? 'Reset' : 'Sıfırla'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _resetBoard());
  }

  void _resetBoard() {
    _history.clear();
    _draft = List<int?>.filled(_puzzle.slots, null);
    for (final MapEntry<int, int> reveal in _revealedSlots.entries) {
      _draft[reveal.key] = reveal.value;
    }
    _activeSlot = _draft.indexWhere((int? value) => value == null);
    if (_activeSlot < 0) _activeSlot = 0;
    _mistakes = 0;
    _notice = null;
    _exhausted = false;
  }

  Future<void> _finish() async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.complete(
      stars: stars,
      action: widget.level.number < CodeBreakerGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
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
      titleTr: 'KOD KIRILDI',
      titleEn: 'CODE CRACKED',
      detailTr: '${_history.length} tahmin · ${_puzzle.searchSpace} olasılık.',
      detailEn:
          '${_history.length} guesses · ${_puzzle.searchSpace} possibilities.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < CodeBreakerGamePage.totalCases,
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

  Future<void> _showCodeAfterFailure() async {
    if (!mounted || _failureDialogOpen) return;
    _failureDialogOpen = true;
    final String code = _puzzle.secret
        .map((int symbol) => '${symbol + 1}')
        .join(' · ');
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'Code remained sealed' : 'Kod kapalı kaldı'),
        content: Text(
          _english
              ? 'The secret code was $code. Reset and read the clues again.'
              : 'Gizli kod $code idi. Sıfırlayıp ipuçlarını yeniden oku.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_english ? 'Try again' : 'Yeniden dene'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _failureDialogOpen = false;
      _resetBoard();
    });
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          backgroundColor: StudioVisuals.canvas,
          foregroundColor: StudioVisuals.ink,
          title: Text(_english ? 'CODE BREAKER' : 'KOD KIRICI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_exhausted) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showCodeAfterFailure(),
      );
    }
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 14,
        title: Text(
          _english ? 'CODE BREAKER' : 'KOD KIRICI',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(child: _CodeLevelPill(level: widget.level.number)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 3, 14, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CodeStatus(
                level: widget.level.number,
                tier: _puzzle.difficultyTier,
                guesses: _puzzle.maximumGuesses - _history.length,
                searchSpace: _puzzle.searchSpace,
                english: _english,
              ),
              const SizedBox(height: 9),
              _CodeRuleCard(
                slots: _puzzle.slots,
                paletteSize: _puzzle.paletteSize,
                repeatsAllowed: _puzzle.repeatsAllowed,
                english: _english,
              ),
              const SizedBox(height: 9),
              _CodeHistory(
                history: _history,
                slots: _puzzle.slots,
                palette: _palette,
                english: _english,
              ),
              const SizedBox(height: 9),
              _DraftRow(
                draft: _draft,
                activeSlot: _activeSlot,
                revealedSlots: _revealedSlots,
                palette: _palette,
                english: _english,
                onTapSlot: _selectSlot,
              ),
              const SizedBox(height: 9),
              _SymbolPalette(
                count: _puzzle.paletteSize,
                activeSlot: _activeSlot,
                colors: _palette,
                english: _english,
                onChoose: _chooseSymbol,
              ),
              const SizedBox(height: 9),
              _CodeActions(
                canUndo: List<int>.generate(_draft.length, (int index) => index)
                    .any(
                      (int index) =>
                          _draft[index] != null &&
                          !_revealedSlots.containsKey(index),
                    ),
                canSubmit: _draft.every((int? value) => value != null),
                canHint: _revealedSlots.length < _maxRevealHints,
                busy: _finished || _exhausted,
                english: _english,
                onUndo: _undo,
                onSubmit: _submit,
                onHint: _showHint,
                onReset: _confirmReset,
              ),
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _CodeNotice(text: _notice!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeGuess {
  _CodeGuess({required List<int> guess, required this.feedback})
    : guess = List<int>.unmodifiable(guess);

  final List<int> guess;
  final CodeFeedback feedback;
}

class _CodeStatus extends StatelessWidget {
  const _CodeStatus({
    required this.level,
    required this.tier,
    required this.guesses,
    required this.searchSpace,
    required this.english,
  });

  final int level;
  final String tier;
  final int guesses;
  final int searchSpace;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7E3DC)),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${english ? 'CODE' : 'KOD'} ${level.toString().padLeft(2, '0')}  ·  $tier',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF76817F),
                  fontSize: 9,
                  letterSpacing: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                english ? '$guesses guesses left' : '$guesses tahmin kaldı',
                style: const TextStyle(
                  color: _CodeBreakerPlayPageState._ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            searchSpace >= 1000000
                ? '${(searchSpace / 1000000).toStringAsFixed(1)}M'
                : searchSpace >= 1000
                ? '${(searchSpace / 1000).round()}K'
                : '$searchSpace',
            style: const TextStyle(
              color: _CodeBreakerPlayPageState._accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CodeRuleCard extends StatelessWidget {
  const _CodeRuleCard({
    required this.slots,
    required this.paletteSize,
    required this.repeatsAllowed,
    required this.english,
  });

  final int slots;
  final int paletteSize;
  final bool repeatsAllowed;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F5F0),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE8E3D9)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.info_outline_rounded,
          color: _CodeBreakerPlayPageState._accent,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            english
                ? '$slots slots · $paletteSize symbols · ${repeatsAllowed ? 'repeats allowed' : 'no repeats'}'
                : '$slots göz · $paletteSize sembol · ${repeatsAllowed ? 'tekrar serbest' : 'tekrar yasak'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _CodeBreakerPlayPageState._ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          english ? '● exact  ○ other slot' : '● yerinde  ○ diğer göz',
          style: const TextStyle(
            color: Color(0xFF77817F),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CodeHistory extends StatelessWidget {
  const _CodeHistory({
    required this.history,
    required this.slots,
    required this.palette,
    required this.english,
  });

  final List<_CodeGuess> history;
  final int slots;
  final List<Color> palette;
  final bool english;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7E3DC)),
        ),
        child: Text(
          english
              ? 'Your deduction trail will appear here.'
              : 'Çıkarım geçmişin burada sıralanacak.',
          style: const TextStyle(color: Color(0xFF87908D), fontSize: 11),
        ),
      );
    }
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(10, 7, 7, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E3DC)),
      ),
      child: ListView.separated(
        reverse: true,
        itemCount: history.length,
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1, color: Color(0xFFF0EEE9)),
        itemBuilder: (BuildContext context, int index) {
          final _CodeGuess entry = history[history.length - index - 1];
          return _CodeGuessRow(entry: entry, palette: palette);
        },
      ),
    );
  }
}

class _CodeGuessRow extends StatelessWidget {
  const _CodeGuessRow({required this.entry, required this.palette});

  final _CodeGuess entry;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 37,
    child: Row(
      children: <Widget>[
        ...entry.guess.map(
          (int symbol) => Padding(
            padding: const EdgeInsets.only(right: 5),
            child: _CodeToken(
              color: palette[symbol],
              label: '${symbol + 1}',
              size: 23,
              border: false,
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 46,
          height: 28,
          child: Wrap(
            spacing: 3,
            runSpacing: 3,
            children: <Widget>[
              for (int index = 0; index < entry.feedback.exact; index++)
                const _FeedbackPeg(color: Color(0xFF29373A)),
              for (int index = 0; index < entry.feedback.misplaced; index++)
                const _FeedbackPeg(color: Color(0xFFC4974E)),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${entry.feedback.exact}+${entry.feedback.misplaced}',
          style: const TextStyle(
            color: Color(0xFF66716E),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({
    required this.draft,
    required this.activeSlot,
    required this.revealedSlots,
    required this.palette,
    required this.english,
    required this.onTapSlot,
  });

  final List<int?> draft;
  final int activeSlot;
  final Map<int, int> revealedSlots;
  final List<Color> palette;
  final bool english;
  final ValueChanged<int> onTapSlot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFDCE5DF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          english ? 'CURRENT THEORY' : 'MEVCUT TAHMİN',
          style: const TextStyle(
            color: Color(0xFF76817F),
            fontSize: 8,
            letterSpacing: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            for (int index = 0; index < draft.length; index++)
              InkWell(
                key: ValueKey<String>('code-slot-$index'),
                onTap: () => onTapSlot(index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: math.min(43.0, 220 / draft.length),
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: draft[index] == null
                        ? const Color(0xFFF4F2ED)
                        : palette[draft[index]!].withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: index == activeSlot
                          ? _CodeBreakerPlayPageState._accent
                          : revealedSlots.containsKey(index)
                          ? const Color(0xFFC4974E)
                          : const Color(0xFFE4E1DA),
                      width:
                          index == activeSlot ||
                              revealedSlots.containsKey(index)
                          ? 2
                          : 1,
                    ),
                  ),
                  child: draft[index] == null
                      ? Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Color(0xFF9CA4A0),
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : _CodeToken(
                          color: palette[draft[index]!],
                          label: '${draft[index]! + 1}',
                          size: 28,
                          border: false,
                        ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _SymbolPalette extends StatelessWidget {
  const _SymbolPalette({
    required this.count,
    required this.activeSlot,
    required this.colors,
    required this.english,
    required this.onChoose,
  });

  final int count;
  final int activeSlot;
  final List<Color> colors;
  final bool english;
  final ValueChanged<int> onChoose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F5F0),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8E3D9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          english
              ? 'CHOOSE SYMBOL FOR SLOT ${activeSlot + 1}'
              : '${activeSlot + 1}. GÖZ İÇİN SEMBOL SEÇ',
          style: const TextStyle(
            color: Color(0xFF76817F),
            fontSize: 8,
            letterSpacing: .75,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 3,
          children: <Widget>[
            for (int symbol = 0; symbol < count; symbol++)
              Semantics(
                button: true,
                label: english
                    ? 'Symbol ${symbol + 1}'
                    : '${symbol + 1}. sembol',
                child: InkWell(
                  key: ValueKey<String>('code-symbol-$symbol'),
                  onTap: () => onChoose(symbol),
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 37,
                    height: 37,
                    child: Center(
                      child: _CodeToken(
                        color: colors[symbol],
                        label: '${symbol + 1}',
                        size: 29,
                        border: false,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _CodeActions extends StatelessWidget {
  const _CodeActions({
    required this.canUndo,
    required this.canSubmit,
    required this.canHint,
    required this.busy,
    required this.english,
    required this.onUndo,
    required this.onSubmit,
    required this.onHint,
    required this.onReset,
  });

  final bool canUndo;
  final bool canSubmit;
  final bool canHint;
  final bool busy;
  final bool english;
  final VoidCallback onUndo;
  final VoidCallback onSubmit;
  final VoidCallback onHint;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: OutlinedButton.icon(
          onPressed: canUndo && !busy ? onUndo : null,
          icon: const Icon(Icons.undo_rounded, size: 17),
          label: Text(english ? 'UNDO' : 'SİL'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: _CodeBreakerPlayPageState._ink,
            side: const BorderSide(color: Color(0xFFDCD9D2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        flex: 2,
        child: FilledButton.icon(
          key: const ValueKey<String>('code-submit'),
          onPressed: canSubmit && !busy ? onSubmit : null,
          icon: const Icon(Icons.lock_open_rounded, size: 17),
          label: Text(english ? 'SUBMIT' : 'KODU DENE'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: _CodeBreakerPlayPageState._accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ),
      const SizedBox(width: 6),
      IconButton.outlined(
        tooltip: english ? 'Hint' : 'İpucu',
        onPressed: busy || !canHint ? null : onHint,
        icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: _CodeBreakerPlayPageState._ink,
          side: const BorderSide(color: Color(0xFFDCD9D2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      const SizedBox(width: 4),
      IconButton.outlined(
        tooltip: english ? 'Reset' : 'Sıfırla',
        onPressed: busy ? null : onReset,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: _CodeBreakerPlayPageState._ink,
          side: const BorderSide(color: Color(0xFFDCD9D2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    ],
  );
}

class _CodeToken extends StatelessWidget {
  const _CodeToken({
    required this.color,
    required this.label,
    required this.size,
    required this.border,
  });

  final Color color;
  final String label;
  final double size;
  final bool border;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(
        color: Colors.black.withValues(alpha: border ? .15 : .08),
        width: border ? 1.4 : 1,
      ),
      boxShadow: size > 25
          ? <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ]
          : const <BoxShadow>[],
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color.computeLuminance() > .38
            ? const Color(0xFF28363A)
            : Colors.white,
        fontSize: size > 25 ? 10 : 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _FeedbackPeg extends StatelessWidget {
  const _FeedbackPeg({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: Colors.white.withValues(alpha: .8), width: .6),
    ),
  );
}

class _CodeNotice extends StatelessWidget {
  const _CodeNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4F1),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFD9E6DE)),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFF54766B),
        fontSize: 10,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _CodeLevelPill extends StatelessWidget {
  const _CodeLevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F4F1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '${level.toString().padLeft(2, '0')} / 20',
      style: const TextStyle(
        color: _CodeBreakerPlayPageState._accent,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
