import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shared/game_visual_design.dart';

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
                fontSize: 18,
              ),
            ),
            Text(
              _practice
                  ? (_english
                        ? 'PRACTICE  •  ${widget.practiceRound} / 300'
                        : 'PRATİK  •  ${widget.practiceRound} / 300')
                  : (_english
                        ? 'CAMPAIGN  •  ${widget.level.number} / ${GameContentPolicy.campaignLevels}'
                        : 'KAMPANYA  •  ${widget.level.number} / ${GameContentPolicy.campaignLevels}'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _english
                            ? 'Pick the closest meaning that fits the sentence—not just a dictionary synonym.'
                            : 'Sözlük ezberine değil, cümlenin bağlamına uyan en yakın anlama odaklan.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: StudioVisuals.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _NuanceStat(
                      icon: Icons.favorite_outline_rounded,
                      label: '$errorsLeft/$_mistakeLimit',
                      accent: errorsLeft <= 1
                          ? StudioVisuals.danger
                          : skin.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value:
                        (_question + (_solved ? 1 : 0)) /
                        _scenario.cards.length,
                    minHeight: 5,
                    color: skin.accent,
                    backgroundColor: skin.accentSoft,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints limits) =>
                        SingleChildScrollView(
                          key: const ValueKey<String>('near_meaning_scroll'),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: limits.maxHeight,
                            ),
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
                                const SizedBox(height: 11),
                                if (!_solved)
                                  _MeaningOptions(
                                    optionOrder: _boardCard.optionOrder,
                                    options: _options,
                                    selected: _selectedOption,
                                    accent: skin.accent,
                                    onSelect: _selectOption,
                                  )
                                else
                                  _NuanceExplanation(
                                    card: _card,
                                    english: _english,
                                    accent: skin.accent,
                                  ),
                                if (_feedback != null) ...<Widget>[
                                  const SizedBox(height: 8),
                                  _NuanceFeedback(
                                    message: _feedback!,
                                    accent:
                                        _feedback!.startsWith(
                                          _english
                                              ? 'Near-word clue:'
                                              : 'Yakın sözcük ipucu:',
                                        )
                                        ? skin.accent
                                        : StudioVisuals.danger,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                StudioGameActions(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _solved ? null : _useHint,
                                        icon: const Icon(
                                          Icons.lightbulb_outline_rounded,
                                          size: 17,
                                        ),
                                        label: Text(
                                          _english ? 'CLUE' : 'İPUCU',
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: skin.accent,
                                          minimumSize: const Size.fromHeight(
                                            46,
                                          ),
                                          textStyle: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      flex: 2,
                                      child: FilledButton.icon(
                                        key: const ValueKey<String>(
                                          'near_meaning_submit',
                                        ),
                                        onPressed: _solved
                                            ? _continue
                                            : _selectedOption == null
                                            ? null
                                            : _checkAnswer,
                                        icon: Icon(
                                          _solved
                                              ? Icons.arrow_forward_rounded
                                              : Icons.fact_check_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _solved
                                              ? _question ==
                                                        _scenario.cards.length -
                                                            1
                                                    ? (_english
                                                          ? 'FINISH BOARD'
                                                          : 'TAHTAYI TAMAMLA')
                                                    : (_english
                                                          ? 'NEXT WORD'
                                                          : 'SONRAKİ SÖZCÜK')
                                              : (_english
                                                    ? 'CHECK MEANING'
                                                    : 'ANLAMI KONTROL ET'),
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: skin.accent,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size.fromHeight(
                                            46,
                                          ),
                                          textStyle: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 11,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: accent.withValues(alpha: .2)),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.manage_search_rounded, color: accent, size: 19),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  english
                      ? 'NUANCE $question OF $total'
                      : '$total NÜANSTAN $question.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .55,
                  ),
                ),
              ),
              Icon(
                Icons.language_rounded,
                color: StudioVisuals.muted,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                english ? 'English' : 'Türkçe',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            english ? card.contextEn : card.contextTr,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            key: const ValueKey<String>('near_meaning_sentence'),
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontSize: 17,
                height: 1.35,
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
                    backgroundColor: accent.withValues(alpha: .1),
                    decoration: TextDecoration.underline,
                    decorationColor: accent.withValues(alpha: .55),
                    decorationThickness: 2,
                  ),
                ),
                TextSpan(text: suffix),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            english
                ? 'Which definition best preserves the highlighted word’s meaning here?'
                : 'Vurgulu sözcüğün bu cümledeki anlamını en iyi hangi açıklama koruyor?',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: accent,
              fontSize: 11,
              height: 1.3,
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
    return Column(
      key: const ValueKey<String>('near_meaning_options'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 7),
          child: Text(
            context.l10n.isEnglish
                ? 'CLOSE MEANINGS'
                : 'YAKIN ANLAM AÇIKLAMALARI',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: accent,
              fontSize: 12,
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
          if (viewIndex > 0) const SizedBox(height: 7),
          _MeaningOptionCard(
            viewIndex: viewIndex,
            text: options[optionOrder[viewIndex]],
            selected: selected == viewIndex,
            accent: accent,
            onTap: () => onSelect(viewIndex),
          ),
        ],
      ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lightbulb_outline_rounded, size: 17, color: accent),
              const SizedBox(width: 7),
              Text(
                english ? 'WHY IT FITS' : 'NEDEN UYUYOR?',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            english ? card.explanationEn : card.explanationTr,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${english ? 'Nearby words' : 'Yakın sözcükler'}: ${nearWords.join(' • ')}',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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

class _NuanceStat extends StatelessWidget {
  const _NuanceStat({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
