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
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'near_meaning_scenario.dart';

class NearMeaningGamePage extends StatefulWidget {
  const NearMeaningGamePage({
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
    GameContentPolicy.nativeStages('near_meaning'),
    (int index) {
      final int level = index + 1;
      final String difficulty = level <= 6
          ? 'USTALAŞMA'
          : level <= 10
          ? 'İLERİ'
          : level <= 15
          ? 'UZMAN'
          : 'USTA';
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Nüans ${level.toString().padLeft(2, '0')}',
        titleEn: 'Nuance ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Sözcüğü cümledeki ipucuyla çöz',
          <= 6 => 'Yakın anlamların sınırını ayırt et',
          <= 10 => 'Ton, kanıt ve niyet nüanslarını tart',
          <= 15 => 'Bağlama uyan en kesin açıklamayı seç',
          <= 19 => 'İnce ayrımları kanıta dayandır',
          _ => 'Usta finali • dört sözcük nüansı',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Use sentence clues to read each word',
          <= 6 => 'Separate neighboring shades of meaning',
          <= 10 => 'Weigh tone, evidence and intent',
          <= 15 => 'Choose the most precise contextual meaning',
          <= 19 => 'Support subtle distinctions with evidence',
          _ => 'Master finale • four lexical nuances',
        },
        difficulty: difficulty,
        icon: Icons.manage_search_rounded,
      );
    },
    growable: false,
  );

  @override
  State<NearMeaningGamePage> createState() => _NearMeaningGamePageState();
}

class _NearMeaningGamePageState extends State<NearMeaningGamePage> {
  static const String _practiceKey = 'near_meaning_next_practice_round';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  bool _practiceLoading = true;
  int _nextPracticeRound = 1;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPracticeRound());
  }

  Future<void> _loadPracticeRound() async {
    final int stored = await _preferences.getInt(_practiceKey) ?? 1;
    if (!mounted) return;
    setState(() {
      _nextPracticeRound = stored
          .clamp(1, NearMeaningScenario.uniquePracticeRounds)
          .toInt();
      _practiceLoading = false;
    });
  }

  Future<void> _openPractice() async {
    final bool english = context.l10n.isEnglish;
    final int round = _nextPracticeRound;
    final ParkurGameResult? result = await Navigator.of(context)
        .push<ParkurGameResult>(
          MaterialPageRoute<ParkurGameResult>(
            builder: (BuildContext context) => NearMeaningPlayPage(
              level: ParkurLevelSpec(
                number: ((round - 1) % NearMeaningScenario.campaignLevels) + 1,
                titleTr: 'Serbest Nüans Turu',
                titleEn: 'Open Nuance Round',
                subtitleTr: 'Yeni bağlamlarda anlamı çöz',
                subtitleEn: 'Read fresh words in context',
                difficulty: 'PRATİK',
                icon: Icons.shuffle_rounded,
              ),
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == NearMeaningScenario.uniquePracticeRounds
        ? 1
        : round + 1;
    await _preferences.setInt(_practiceKey, next);
    if (!mounted) return;
    setState(() => _nextPracticeRound = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          english
              ? 'Board cleared • next unique set: $next / 300'
              : 'Tahta çözüldü • sıradaki farklı set: $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('near_meaning');
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'near_meaning',
      progressPrefix: 'near_meaning',
      titleTr: 'Yakın Anlam',
      titleEn: 'Near Meaning',
      taglineTr: 'Bağlamı oku • nüansı seç • gerekçeyi gör',
      taglineEn: 'Read the context • choose the nuance • see why',
      accent: skin.accent,
      icon: Icons.manage_search_rounded,
      levels: NearMeaningGamePage._levels,
      dailyCourseMode: widget.dailyCourseMode,
      competitionLevel: widget.competitionLevel,
      competitionLayoutCode: widget.competitionLayoutCode,
      hubAction: widget.competitionLevel != null
          ? null
          : OutlinedButton.icon(
              onPressed: _practiceLoading ? null : _openPractice,
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(
                _practiceLoading
                    ? (english ? 'Loading…' : 'Yükleniyor…')
                    : english
                    ? 'UNIQUE PRACTICE  •  $_nextPracticeRound / 300'
                    : 'FARKLI PRATİK  •  $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => NearMeaningPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          NearMeaningScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class NearMeaningPlayPage extends StatefulWidget {
  const NearMeaningPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<NearMeaningPlayPage> createState() => _NearMeaningPlayPageState();
}

class _NearMeaningPlayPageState extends State<NearMeaningPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.language,
  );

  late StudioGameSession _session;
  late NearMeaningScenario _scenario;
  bool _initialized = false;
  bool _failureDialogOpen = false;
  int _question = 0;
  int? _selectedOption;
  int _hints = 0;
  String? _feedback;
  String? _explanation;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  bool get _solved => _explanation != null;
  int get _mistakeLimit => widget.level.number <= 3
      ? 5
      : widget.level.number <= 6
      ? 4
      : widget.level.number <= 15
      ? 3
      : 2;

  NearMeaningBoardCard get _boardCard => _scenario.cards[_question];
  NearMeaningCard get _card => _boardCard.card;
  List<String> get _options => _english ? _card.optionsEn : _card.optionsTr;

  @override
  void initState() {
    super.initState();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.practiceRound ?? widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _scenario = _practice
        ? NearMeaningScenario.forPracticeRound(widget.practiceRound!)
        : (widget.level.poolIndex != null
              ? NearMeaningScenario.forPracticeRound(widget.level.contentIndex)
              : NearMeaningScenario.forCampaignLevel(
                  widget.level.contentLevel,
                ));
  }

  String _prefix() => _english ? _card.prefixEn : _card.prefixTr;
  String _targetWord() => _english ? _card.targetEn : _card.targetTr;
  String _suffix() => _english ? _card.suffixEn : _card.suffixTr;

  void _selectOption(int index) {
    if (_solved || _session.phase != StudioGamePhase.playing) return;
    setState(() {
      _selectedOption = index;
      _feedback = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .16),
    );
  }

  void _checkAnswer() {
    final int? selected = _selectedOption;
    if (selected == null || _solved) return;
    if (selected != _boardCard.correctOptionIndex) {
      _session.recordMistake();
      final int left = math.max(0, _mistakeLimit - _session.mistakes).toInt();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .3));
      setState(() {
        _feedback = _english
            ? 'That is close, but it misses this context. Re-read the highlighted word. $left ${left == 1 ? 'try' : 'tries'} left.'
            : 'Yakın bir anlam; fakat bu bağlamı tam karşılamıyor. Vurgulu sözcüğü yeniden oku. $left deneme hakkın kaldı.';
        _selectedOption = null;
      });
      if (left == 0 && !_failureDialogOpen) unawaited(_showFailure());
      return;
    }

    _session.recordAccepted(points: 190 + widget.level.number * 16);
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .43));
    setState(() {
      _explanation = _english ? _card.explanationEn : _card.explanationTr;
      _feedback = null;
      _selectedOption = null;
    });
  }

  Future<void> _showFailure() async {
    _failureDialogOpen = true;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'Round closed' : 'Tur sona erdi'),
        content: Text(
          _english
              ? 'The attempt limit is used. Compare the highlighted word with the sentence evidence and retry.'
              : 'Deneme hakkın doldu. Vurgulu sözcüğü cümledeki kanıtla karşılaştırıp yeniden deneyebilirsin.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) _resetRound();
            },
            child: Text(_english ? 'TRY AGAIN' : 'YENİDEN DENE'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) {
                Navigator.of(context).pop(
                  const ParkurGameResult(
                    completed: false,
                    stars: 0,
                    score: 0,
                    nextLevel: false,
                  ),
                );
              }
            },
            child: Text(_english ? 'LEVEL MAP' : 'BÖLÜM HARİTASI'),
          ),
        ],
      ),
    );
    _failureDialogOpen = false;
  }

  void _resetRound() {
    setState(() {
      _question = 0;
      _selectedOption = null;
      _hints = 0;
      _feedback = null;
      _explanation = null;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _useHint() {
    if (_solved || !_session.useHint(pointCost: 110)) return;
    final List<String> words = _english ? _card.nearWordsEn : _card.nearWordsTr;
    setState(() {
      _hints++;
      _feedback = _english
          ? 'Near-word clue: ${words.join(' • ')}'
          : 'Yakın sözcük ipucu: ${words.join(' • ')}';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .3));
  }

  void _continue() {
    if (!_solved) return;
    if (_question == _scenario.cards.length - 1) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _question++;
      _selectedOption = null;
      _feedback = null;
      _explanation = null;
    });
  }

  Future<void> _finish() async {
    if (_session.phase != StudioGamePhase.playing) return;
    final int stars = _hints == 0 && _session.mistakes == 0
        ? 3
        : _hints <= 1 && _session.mistakes <= 2
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: !_practice && widget.level.number < NearMeaningGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(
      _audioProfile.play(
        _audio,
        GameAudioEvent.levelComplete,
        gain: .42,
        levelNumber: widget.level.number,
      ),
    );
    if (mounted) Navigator.of(context).pop(result.toParkurResult());
  }

  void _showHowToPlay() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final StudioGameSkin skin = StudioGameSkin.forId('near_meaning');
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
                  Icon(Icons.help_outline_rounded, color: skin.accent, size: 22),
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
                    ? '• Choose the closest nuance that fits the sentence context—not just dictionary synonyms.\n'
                      '• Tap an option and press "CHECK MEANING" to lock your answer.\n'
                      '• Review subtle shades of meaning in the post-answer explanation note.\n'
                      '• Clear all cards before exceeding your mistake limit!'
                    : '• Yalnızca sözlük anlamı değil, cümlenin bağlamına en uygun düşen yakın anlamı seç.\n'
                      '• Seçeneğe dokun ve "ANLAMI KONTROL ET" butonuyla cevabını onayla.\n'
                      '• Doğru cevabın ardından kelimenin inceliklerini ve kullanım nüansını öğren.\n'
                      '• Hata hakkın tükenmeden parkurdaki tüm kelimeleri tamamla!',
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
                    backgroundColor: skin.accent,
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
    final StudioGameSkin skin = StudioGameSkin.forId('near_meaning');
    final int errorsLeft = math
        .max(0, _mistakeLimit - _session.mistakes)
        .toInt();

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.gameTitle('near_meaning'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              _practice
                  ? (_english
                        ? 'PRACTICE  •  ${widget.practiceRound} / 300'
                        : 'PRATİK  •  ${widget.practiceRound} / 300')
                  : (_english
                        ? 'LEVEL ${widget.level.number} / ${GameContentPolicy.campaignLevels}'
                        : 'BÖLÜM ${widget.level.number} / ${GameContentPolicy.campaignLevels}'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _english ? 'How to play' : 'Nasıl Oynanır?',
            onPressed: _showHowToPlay,
            icon: const Icon(Icons.help_outline_rounded),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudioVisuals.line),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '${_english ? 'Word' : 'Sözcük'} ${_question + 1}/${_scenario.cards.length}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ❤️ $errorsLeft/$_mistakeLimit',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: errorsLeft <= 1 ? StudioVisuals.danger : skin.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          height: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (_question + (_solved ? 1 : 0)) / _scenario.cards.length,
                              minHeight: 6,
                              color: skin.accent,
                              backgroundColor: skin.accentSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Ana Oyun Alanı: Kaydırmasız (Zero-Scroll)
                Expanded(
                  child: Column(
                    children: <Widget>[
                      _NuancePrompt(
                        card: _card,
                        question: _question + 1,
                        total: _scenario.cards.length,
                        english: _english,
                        accent: skin.accent,
                        prefix: _prefix(),
                        target: _targetWord(),
                        suffix: _suffix(),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: !_solved
                              ? _MeaningOptions(
                                  optionOrder: _boardCard.optionOrder,
                                  options: _options,
                                  selected: _selectedOption,
                                  accent: skin.accent,
                                  onSelect: _selectOption,
                                )
                              : _NuanceExplanation(
                                  card: _card,
                                  english: _english,
                                  accent: skin.accent,
                                ),
                        ),
                      ),
                      if (_feedback != null) ...<Widget>[
                        const SizedBox(height: 6),
                        _NuanceFeedback(
                          message: _feedback!,
                          accent: _feedback!.startsWith(
                            _english ? 'Near-word clue:' : 'Yakın sözcük ipucu:',
                          )
                              ? skin.accent
                              : StudioVisuals.danger,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Alt Aksiyon Butonları (42px)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _solved ? null : _useHint,
                        icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_english ? 'CLUE' : 'İPUCU'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: skin.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                          side: BorderSide(color: skin.accent.withValues(alpha: .4)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        key: const ValueKey<String>('near_meaning_submit'),
                        onPressed: _solved
                            ? _continue
                            : _selectedOption == null
                                ? null
                                : _checkAnswer,
                        icon: Icon(
                          _solved ? Icons.arrow_forward_rounded : Icons.fact_check_outlined,
                          size: 16,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _solved
                                ? _question == _scenario.cards.length - 1
                                    ? (_english ? 'FINISH BOARD' : 'TAHTAYI TAMAMLA')
                                    : (_english ? 'NEXT WORD' : 'SONRAKİ SÖZCÜK')
                                : (_english ? 'CHECK MEANING' : 'ANLAMI KONTROL ET'),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: skin.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
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
      ),
    );
  }
}

class _NuancePrompt extends StatelessWidget {
  const _NuancePrompt({
    required this.card,
    required this.question,
    required this.total,
    required this.english,
    required this.accent,
    required this.prefix,
    required this.target,
    required this.suffix,
  });

  final NearMeaningCard card;
  final int question;
  final int total;
  final bool english;
  final Color accent;
  final String prefix;
  final String target;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('near_meaning_prompt'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: .2)),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.manage_search_rounded, color: accent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  english
                      ? 'NUANCE $question OF $total'
                      : '$total NÜANSTAN $question.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .55,
                  ),
                ),
              ),
              Icon(
                Icons.language_rounded,
                color: StudioVisuals.muted,
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                english ? 'English' : 'Türkçe',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            english ? card.contextEn : card.contextTr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .085),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: accent,
                width: 2.0,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: .12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: RichText(
              key: const ValueKey<String>('near_meaning_sentence'),
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.ink,
                  fontSize: 15.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
                children: <InlineSpan>[
                  TextSpan(text: prefix),
                  TextSpan(
                    text: target,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: accent,
                      fontWeight: FontWeight.w900,
                      backgroundColor: accent.withValues(alpha: .18),
                      decoration: TextDecoration.underline,
                      decorationColor: accent,
                      decorationThickness: 2.5,
                    ),
                  ),
                  TextSpan(text: suffix),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            english
                ? 'Which definition best preserves the highlighted word’s meaning here?'
                : 'Vurgulu sözcüğün bu cümledeki anlamını en iyi hangi açıklama koruyor?',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: accent,
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeaningOptions extends StatelessWidget {
  const _MeaningOptions({
    required this.optionOrder,
    required this.options,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  final List<int> optionOrder;
  final List<String> options;
  final int? selected;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        key: const ValueKey<String>('near_meaning_options'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 6),
            child: Text(
              context.l10n.isEnglish
                  ? 'CLOSE MEANINGS'
                  : 'YAKIN ANLAM AÇIKLAMALARI',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ),
          for (
            int viewIndex = 0;
            viewIndex < optionOrder.length;
            viewIndex++
          ) ...<Widget>[
            if (viewIndex > 0) const SizedBox(height: 6),
            _MeaningOptionCard(
              viewIndex: viewIndex,
              text: options[optionOrder[viewIndex]],
              selected: selected == viewIndex,
              accent: accent,
              onTap: () => onSelect(viewIndex),
            ),
          ],
        ],
      ),
    );
  }
}

class _MeaningOptionCard extends StatelessWidget {
  const _MeaningOptionCard({
    required this.viewIndex,
    required this.text,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final int viewIndex;
  final String text;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: .09) : StudioVisuals.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey<String>('near_meaning_option_$viewIndex'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : StudioVisuals.line,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? const <BoxShadow>[]
                : StudioVisuals.softShadow,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  String.fromCharCode(65 + viewIndex),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? accent : StudioVisuals.muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NuanceExplanation extends StatelessWidget {
  const _NuanceExplanation({
    required this.card,
    required this.english,
    required this.accent,
  });

  final NearMeaningCard card;
  final bool english;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final List<String> nearWords = english
        ? card.nearWordsEn
        : card.nearWordsTr;
    return Container(
      key: const ValueKey<String>('near_meaning_explanation'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: .2)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.lightbulb_outline_rounded, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  english ? 'WHY IT FITS' : 'NEDEN UYUYOR?',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              english ? card.explanationEn : card.explanationTr,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${english ? 'Nearby words' : 'Yakın sözcükler'}: ${nearWords.join(' • ')}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 10.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NuanceFeedback extends StatelessWidget {
  const _NuanceFeedback({required this.message, required this.accent});

  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: accent,
          fontSize: 11,
          height: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


