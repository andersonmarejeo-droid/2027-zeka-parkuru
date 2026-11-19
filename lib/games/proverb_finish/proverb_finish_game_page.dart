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
import 'proverb_finish_scenario.dart';

class ProverbFinishGamePage extends StatefulWidget {
  const ProverbFinishGamePage({
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
    GameContentPolicy.nativeStages('proverb_finish'),
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
        titleTr: 'Söz Ustası ${level.toString().padLeft(2, '0')}',
        titleEn: 'Proverb Craft ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'En bilinen sözleri tamamla',
          <= 6 => 'Sözün anlamını bağlamdan çıkar',
          <= 10 => 'Yakın kalıpları ayırt et',
          <= 15 => 'Eski ve mecazlı söyleyişleri çöz',
          <= 19 => 'Dört ileri kalıbı doğru eşleştir',
          _ => 'Usta finali • dört zor söz',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Complete familiar Turkish sayings',
          <= 6 => 'Use context to understand each saying',
          <= 10 => 'Distinguish closely phrased sayings',
          <= 15 => 'Decode figurative and less familiar forms',
          <= 19 => 'Match four advanced sayings',
          _ => 'Expert finale • four demanding sayings',
        },
        difficulty: difficulty,
        icon: Icons.menu_book_rounded,
      );
    },
    growable: false,
  );

  @override
  State<ProverbFinishGamePage> createState() => _ProverbFinishGamePageState();
}

class _ProverbFinishGamePageState extends State<ProverbFinishGamePage> {
  static const String _practiceKey = 'proverb_finish_next_practice_round';
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
          .clamp(1, ProverbFinishScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => ProverbFinishPlayPage(
              level: ParkurLevelSpec(
                number:
                    ((round - 1) % ProverbFinishScenario.campaignLevels) + 1,
                titleTr: 'Serbest Söz Turu',
                titleEn: 'Open Proverb Round',
                subtitleTr: 'Yeni atasözlerini tamamla',
                subtitleEn: 'Complete a fresh set of sayings',
                difficulty: 'PRATİK',
                icon: Icons.shuffle_rounded,
              ),
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;

    final int next = round == ProverbFinishScenario.uniquePracticeRounds
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
              ? 'Round cleared • next unique set: $next / 300'
              : 'Tur tamamlandı • sıradaki farklı set: $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('proverb_finish');
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'proverb_finish',
      progressPrefix: 'proverb_finish',
      titleTr: 'Atasözü Tamamla',
      titleEn: 'Finish the Proverb',
      taglineTr: 'Sözü bul • anlamını kavra • bağlamda kullan',
      taglineEn: 'Complete it • learn its meaning • use it in context',
      accent: skin.accent,
      icon: Icons.menu_book_rounded,
      levels: ProverbFinishGamePage._levels,
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
          ) => ProverbFinishPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          ProverbFinishScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class ProverbFinishPlayPage extends StatefulWidget {
  const ProverbFinishPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<ProverbFinishPlayPage> createState() => _ProverbFinishPlayPageState();
}

class _ProverbFinishPlayPageState extends State<ProverbFinishPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.language,
  );

  late StudioGameSession _session;
  late ProverbFinishScenario _scenario;
  bool _initialized = false;
  bool _failureDialogOpen = false;
  int _question = 0;
  int? _selectedAnswer;
  int _hints = 0;
  String? _feedback;
  String? _contextReveal;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  bool get _questionSolved => _contextReveal != null;
  int get _mistakeLimit => widget.level.number <= 3
      ? 5
      : widget.level.number <= 6
      ? 4
      : widget.level.number <= 15
      ? 3
      : 2;

  ProverbCard get _card => _scenario.cards[_question];

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
        ? ProverbFinishScenario.forPracticeRound(widget.practiceRound!)
        : (widget.level.poolIndex != null
              ? ProverbFinishScenario.forPracticeRound(
                  widget.level.contentIndex,
                )
              : ProverbFinishScenario.forCampaignLevel(
                  widget.level.contentLevel,
                ));
  }

  void _selectAnswer(int index) {
    if (_questionSolved || _session.phase != StudioGamePhase.playing) return;
    setState(() {
      _selectedAnswer = index;
      _feedback = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .18),
    );
  }

  void _submitAnswer() {
    final int? selected = _selectedAnswer;
    if (selected == null || _questionSolved) return;
    final String chosen = _scenario.answerOrder[selected];
    if (chosen != _card.ending) {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .32));
      final int left = math.max(0, _mistakeLimit - _session.mistakes).toInt();
      setState(() {
        _feedback = _english
            ? 'Not quite. Read the opening once more. $left ${left == 1 ? 'try' : 'tries'} left.'
            : 'Tam değil. İlk bölümü bir daha oku. $left deneme hakkın kaldı.';
        _selectedAnswer = null;
      });
      if (left == 0 && !_failureDialogOpen) unawaited(_showFailure());
      return;
    }

    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .45));
    _session.recordAccepted(points: 220);
    setState(() {
      _contextReveal = _english ? _card.meaningEn : _card.meaningTr;
      _feedback = null;
      _selectedAnswer = null;
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
              ? 'The attempt limit is used. Re-read the sayings and start this round again.'
              : 'Deneme hakkın doldu. Sözleri yeniden inceleyip bu turu baştan deneyebilirsin.',
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
      _selectedAnswer = null;
      _hints = 0;
      _feedback = null;
      _contextReveal = null;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _useHint() {
    if (_questionSolved || _session.phase != StudioGamePhase.playing) return;
    if (!_session.useHint(pointCost: 120)) return;
    setState(() {
      _hints++;
      _feedback = _english
          ? 'Meaning clue: ${_card.meaningEn}'
          : 'Anlam ipucu: ${_card.meaningTr}';
      _selectedAnswer = null;
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .3));
  }

  void _continue() {
    if (!_questionSolved) return;
    if (_question == _scenario.cards.length - 1) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _question++;
      _contextReveal = null;
      _feedback = null;
      _selectedAnswer = null;
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
      action:
          !_practice && widget.level.number < ProverbFinishGamePage.totalCases
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
        final StudioGameSkin skin = StudioGameSkin.forId('proverb_finish');
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
                    ? '• Read the incomplete Turkish proverb and select the matching ending.\n'
                      '• Tap an option and press "SUBMIT" to verify your choice.\n'
                      '• After solving, read the meaning and cultural context note.\n'
                      '• Complete all proverbs before running out of attempts!'
                    : '• Eksik bırakılan atasözünü oku ve seçenekler arasından doğru tamamlayan parçayı bul.\n'
                      '• Seçeneğe dokunup "CEVABI ONAYLA" butonuna bas.\n'
                      '• Doğru bildikten sonra atasözünün anlamını ve kullanım bağlamını öğren.\n'
                      '• Hata hakkın bitmeden tüm atasözlerini tamamla!',
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
    final StudioGameSkin skin = StudioGameSkin.forId('proverb_finish');
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
              context.l10n.gameTitle('proverb_finish'),
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
                // Kompakt durum çubuğu (36px)
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudioVisuals.line),
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        '${_english ? 'Proverb' : 'Söz'} ${_question + 1}/${_scenario.cards.length}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: StudioVisuals.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•  ❤️ $errorsLeft/$_mistakeLimit',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: errorsLeft <= 1 ? StudioVisuals.danger : skin.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 44,
                        height: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (_question + (_questionSolved ? 1 : 0)) / _scenario.cards.length,
                            minHeight: 6,
                            color: skin.accent,
                            backgroundColor: skin.accentSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Ana Oyun Alanı (Taşma Korumalı & Kaydırılabilir)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _ProverbPromptCard(
                          card: _card,
                          question: _question + 1,
                          total: _scenario.cards.length,
                          english: _english,
                          accent: skin.accent,
                          revealedMeaning: _contextReveal,
                        ),
                        const SizedBox(height: 8),
                        !_questionSolved
                            ? _AnswerGrid(
                                options: _scenario.answerOrder,
                                selected: _selectedAnswer,
                                accent: skin.accent,
                                onSelect: _selectAnswer,
                              )
                            : _UsageNote(
                                card: _card,
                                english: _english,
                                accent: skin.accent,
                              ),
                        if (_feedback != null) ...<Widget>[
                          const SizedBox(height: 6),
                          _FeedbackBanner(
                            message: _feedback!,
                            accent: _feedback!.startsWith(
                              _english ? 'Meaning clue:' : 'Anlam ipucu:',
                            )
                                ? skin.accent
                                : StudioVisuals.danger,
                          ),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Alt Aksiyon Butonları (42px)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _questionSolved ? null : _useHint,
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
                        key: const ValueKey<String>('proverb_finish_submit'),
                        onPressed: _questionSolved
                            ? _continue
                            : _selectedAnswer == null
                                ? null
                                : _submitAnswer,
                        icon: Icon(
                          _questionSolved ? Icons.arrow_forward_rounded : Icons.fact_check_outlined,
                          size: 16,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _questionSolved
                                ? _question == _scenario.cards.length - 1
                                    ? (_english ? 'FINISH ROUND' : 'TURU TAMAMLA')
                                    : (_english ? 'NEXT PROVERB' : 'SONRAKİ ATASÖZÜ')
                                : (_english ? 'SUBMIT' : 'CEVABI ONAYLA'),
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

class _ProverbPromptCard extends StatelessWidget {
  const _ProverbPromptCard({
    required this.card,
    required this.question,
    required this.total,
    required this.english,
    required this.accent,
    required this.revealedMeaning,
  });

  final ProverbCard card;
  final int question;
  final int total;
  final bool english;
  final Color accent;
  final String? revealedMeaning;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('proverb_finish_prompt'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 16),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: accent.withValues(alpha: .2)),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  english
                      ? 'SAYING $question OF $total'
                      : '$total SÖZDEN $question.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ),
              const Icon(
                Icons.language_rounded,
                color: StudioVisuals.muted,
                size: 17,
              ),
              const SizedBox(width: 4),
              Text(
                english ? 'Turkish' : 'Türkçe',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '“${card.opening} …”',
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontSize: 22,
              height: 1.24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            english
                ? 'Choose the ending that completes this fixed saying.'
                : 'Bu kalıplaşmış sözü doğru biçimde tamamla.',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (revealedMeaning != null) ...<Widget>[
            const SizedBox(height: 11),
            Text(
              revealedMeaning!,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerGrid extends StatelessWidget {
  const _AnswerGrid({
    required this.options,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  final List<String> options;
  final int? selected;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cellHeight = constraints.maxWidth < 360 ? 64 : 58;
        return GridView.builder(
          key: const ValueKey<String>('proverb_finish_options'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            mainAxisExtent: cellHeight,
          ),
          itemBuilder: (BuildContext context, int index) {
            final bool isSelected = selected == index;
            return Material(
              color: isSelected
                  ? accent.withValues(alpha: .1)
                  : StudioVisuals.surface,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                key: ValueKey<String>('proverb_finish_answer_$index'),
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? accent : StudioVisuals.line,
                      width: isSelected ? 1.6 : 1,
                    ),
                    boxShadow: isSelected
                        ? const <BoxShadow>[]
                        : StudioVisuals.softShadow,
                  ),
                  child: Center(
                    child: Text(
                      options[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: isSelected ? accent : StudioVisuals.ink,
                        fontSize: constraints.maxWidth < 360 ? 12 : 13,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _UsageNote extends StatelessWidget {
  const _UsageNote({
    required this.card,
    required this.english,
    required this.accent,
  });

  final ProverbCard card;
  final bool english;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('proverb_finish_usage_note'),
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lightbulb_outline_rounded, size: 17, color: accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  english ? 'MEANING & USAGE' : 'ANLAMI VE KULLANIMI',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.fullText,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            english ? card.meaningEn : card.meaningTr,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            english ? card.contextEn : card.contextTr,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, required this.accent});

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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


