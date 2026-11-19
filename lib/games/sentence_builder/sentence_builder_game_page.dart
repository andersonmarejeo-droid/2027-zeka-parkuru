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
import 'sentence_builder_scenario.dart';

class SentenceBuilderGamePage extends StatefulWidget {
  const SentenceBuilderGamePage({
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
    GameContentPolicy.nativeStages('sentence_builder'),
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
        titleTr: 'Cümle Atölyesi ${level.toString().padLeft(2, '0')}',
        titleEn: 'Sentence Studio ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Anlamlı cümle bloklarını sırala',
          <= 6 => 'Zaman ve sebep bağlarını izle',
          <= 10 => 'Yan cümle ve karşıtlık yapısını kur',
          <= 15 => 'Uzun özne ve eylem zincirlerini çöz',
          <= 19 => 'Birden çok bağlayıcıyı birlikte kullan',
          _ => 'Usta finali • beş cümle bloğu',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Order meaningful sentence blocks',
          <= 6 => 'Follow time and cause links',
          <= 10 => 'Build subordinate and contrast clauses',
          <= 15 => 'Resolve long subjects and action chains',
          <= 19 => 'Track multiple connectors at once',
          _ => 'Master finale • five sentence blocks',
        },
        difficulty: difficulty,
        icon: Icons.format_align_left_rounded,
      );
    },
    growable: false,
  );

  @override
  State<SentenceBuilderGamePage> createState() =>
      _SentenceBuilderGamePageState();
}

class _SentenceBuilderGamePageState extends State<SentenceBuilderGamePage> {
  static const String _practiceKey = 'sentence_builder_next_practice_round';
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
          .clamp(1, SentenceBuilderScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => SentenceBuilderPlayPage(
              level: ParkurLevelSpec(
                number:
                    ((round - 1) % SentenceBuilderScenario.campaignLevels) + 1,
                titleTr: 'Serbest Cümle Turu',
                titleEn: 'Open Sentence Round',
                subtitleTr: 'Yeni cümle bağlarını çöz',
                subtitleEn: 'Rebuild a fresh sentence board',
                difficulty: 'PRATİK',
                icon: Icons.shuffle_rounded,
              ),
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;

    final int next = round == SentenceBuilderScenario.uniquePracticeRounds
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
              : 'Tahta tamamlandı • sıradaki farklı set: $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('sentence_builder');
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'sentence_builder',
      progressPrefix: 'sentence_builder',
      titleTr: 'Cümle Kur',
      titleEn: 'Sentence Builder',
      taglineTr: 'İpuçlarını izle • blokları sırala • anlamı kur',
      taglineEn: 'Read the cues • order the clauses • build the meaning',
      accent: skin.accent,
      icon: Icons.format_align_left_rounded,
      levels: SentenceBuilderGamePage._levels,
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
          ) => SentenceBuilderPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          SentenceBuilderScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class SentenceBuilderPlayPage extends StatefulWidget {
  const SentenceBuilderPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<SentenceBuilderPlayPage> createState() =>
      _SentenceBuilderPlayPageState();
}

class _SentenceBuilderPlayPageState extends State<SentenceBuilderPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.language,
  );

  late StudioGameSession _session;
  late SentenceBuilderScenario _scenario;
  bool _initialized = false;
  bool _failureDialogOpen = false;
  int _question = 0;
  final List<int> _assembled = <int>[];
  int _hints = 0;
  String? _feedback;
  String? _revealedNote;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  bool get _solved => _revealedNote != null;
  int get _mistakeLimit => widget.level.number <= 3
      ? 5
      : widget.level.number <= 6
      ? 4
      : widget.level.number <= 15
      ? 3
      : 2;

  SentenceBoardCard get _card => _scenario.cards[_question];
  List<String> get _target =>
      _english ? _card.sentence.partsEn : _card.sentence.partsTr;
  List<String> get _scrambled =>
      _english ? _card.scrambledEn : _card.scrambledTr;

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
        ? SentenceBuilderScenario.forPracticeRound(widget.practiceRound!)
        : (widget.level.poolIndex != null
              ? SentenceBuilderScenario.forPracticeRound(
                  widget.level.contentIndex,
                )
              : SentenceBuilderScenario.forCampaignLevel(
                  widget.level.contentLevel,
                ));
  }

  void _addPart(int index) {
    if (_solved || _session.phase != StudioGamePhase.playing) return;
    if (_assembled.contains(index) || _assembled.length >= _target.length) {
      return;
    }
    setState(() {
      _assembled.add(index);
      _feedback = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .16),
    );
  }

  void _undoPart() {
    if (_assembled.isEmpty || _solved) return;
    setState(() {
      _assembled.removeLast();
      _feedback = null;
    });
    _audio.hapticLight();
  }

  void _clearParts() {
    if (_assembled.isEmpty || _solved) return;
    setState(() {
      _assembled.clear();
      _feedback = null;
    });
    _audio.hapticLight();
  }

  void _checkOrder() {
    if (_assembled.length != _target.length || _solved) return;
    final List<String> current = _assembled
        .map((int index) => _scrambled[index])
        .toList(growable: false);
    if (!_sameOrder(current, _target)) {
      _session.recordMistake();
      final int left = math.max(0, _mistakeLimit - _session.mistakes).toInt();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .32));
      setState(() {
        _assembled.clear();
        _feedback = _english
            ? 'The clauses do not connect in that order. Trace the clue once more. $left ${left == 1 ? 'try' : 'tries'} left.'
            : 'Bağlaçlar bu sırada anlamlı akmıyor. İpucunu yeniden izle. $left deneme hakkın kaldı.';
      });
      if (left == 0 && !_failureDialogOpen) unawaited(_showFailure());
      return;
    }

    _session.recordAccepted(points: 170 + widget.level.number * 18);
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .42));
    setState(() {
      _revealedNote = _english ? _card.sentence.noteEn : _card.sentence.noteTr;
      _feedback = null;
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
              ? 'The attempt limit is used. Look for the clause and connector cues, then try this board again.'
              : 'Deneme hakkın doldu. Yan cümle ve bağlaç ipuçlarına bakıp bu tahtayı yeniden deneyebilirsin.',
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
      _assembled.clear();
      _hints = 0;
      _feedback = null;
      _revealedNote = null;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _useHint() {
    if (_solved || !_session.useHint(pointCost: 110)) return;
    setState(() {
      _hints++;
      _feedback = _english
          ? 'Structure clue: ${_card.sentence.clueEn}'
          : 'Yapı ipucu: ${_card.sentence.clueTr}';
      _assembled.clear();
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
      _assembled.clear();
      _revealedNote = null;
      _feedback = null;
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
          !_practice && widget.level.number < SentenceBuilderGamePage.totalCases
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

  bool _sameOrder(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (int index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  void _showHowToPlay() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final StudioGameSkin skin = StudioGameSkin.forId('sentence_builder');
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
                    ? '• Rebuild the complete sentence from meaningful clause blocks.\n'
                      '• Follow the contextual cues, conjunctions, and grammar markers.\n'
                      '• Tap blocks to place them in order, or tap placed blocks to remove.\n'
                      '• Watch your mistake limit and use hints when needed!'
                    : '• Parçalanmış cümle bloklarını anlamlı ve kurallı bir cümle olacak şekilde sırayla birleştir.\n'
                      '• Bağlaçları, noktalama ve gramer ipuçlarını takip et.\n'
                      '• Bloklara dokunarak yerleştir, yerleşen bloğa dokunarak geri al.\n'
                      '• Hata hakkın bitmeden tüm cümleleri tamamla!',
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
    final StudioGameSkin skin = StudioGameSkin.forId('sentence_builder');
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
              context.l10n.gameTitle('sentence_builder'),
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
        actions: <Widget>[
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          '${_english ? 'Sentence' : 'Cümle'} ${_question + 1}/${_scenario.cards.length}',
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
                              color: skin.accent,
                              backgroundColor: skin.accentSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Ana Oyun Alanı: Taşma Korumalı & Kaydırılabilir
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _SentencePrompt(
                          card: _card.sentence,
                          question: _question + 1,
                          total: _scenario.cards.length,
                          english: _english,
                          accent: skin.accent,
                        ),
                        const SizedBox(height: 6),
                        _SentenceAssembly(
                          assembled: _assembled
                              .map((int index) => _scrambled[index])
                              .toList(growable: false),
                          solved: _solved,
                          targetLength: _target.length,
                          accent: skin.accent,
                          onUndo: _undoPart,
                          onClear: _clearParts,
                          english: _english,
                        ),
                        const SizedBox(height: 6),
                        _solved
                            ? _SentenceNote(
                                sentence: _target.join(' '),
                                note: _revealedNote!,
                                english: _english,
                                accent: skin.accent,
                              )
                            : _ClauseChoices(
                                parts: _scrambled,
                                selectedIndices: _assembled.toSet(),
                                accent: skin.accent,
                                onSelect: _addPart,
                              ),
                        if (_feedback != null) ...<Widget>[
                          const SizedBox(height: 6),
                          _SentenceFeedback(
                            message: _feedback!,
                            accent: _feedback!.startsWith(
                              _english ? 'Structure clue:' : 'Yapı ipucu:',
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

                // Alt Aksiyon Butonları (44px)
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: _solved ? null : _useHint,
                        icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_english ? 'CLUE' : 'İPUCU'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: skin.accent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        key: const ValueKey<String>('sentence_builder_submit'),
                        onPressed: _solved
                            ? _continue
                            : _assembled.length == _target.length
                                ? _checkOrder
                                : null,
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
                                    : (_english ? 'NEXT SENTENCE' : 'SONRAKİ CÜMLE')
                                : (_english ? 'CHECK ORDER' : 'SIRAYI KONTROL ET'),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: skin.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
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

class _SentencePrompt extends StatelessWidget {
  const _SentencePrompt({
    required this.card,
    required this.question,
    required this.total,
    required this.english,
    required this.accent,
  });

  final SentenceCard card;
  final int question;
  final int total;
  final bool english;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('sentence_builder_prompt'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
              Icon(Icons.short_text_rounded, color: accent, size: 19),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  english
                      ? 'SENTENCE $question OF $total'
                      : '$total CÜMLENİN $question.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
              const Icon(
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
              color: StudioVisuals.ink,
              fontSize: 12.5,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            english
                ? 'Order the clause blocks to build the target sentence.'
                : 'Anlam ve noktalama ipuçlarına uyan cümle bloklarını sırala.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SentenceAssembly extends StatelessWidget {
  const _SentenceAssembly({
    required this.assembled,
    required this.solved,
    required this.targetLength,
    required this.accent,
    required this.onUndo,
    required this.onClear,
    required this.english,
  });

  final List<String> assembled;
  final bool solved;
  final int targetLength;
  final Color accent;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final bool english;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('sentence_builder_assembly'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: solved
            ? const Color(0xFFE8F5EC)
            : accent.withValues(alpha: .085),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: solved ? const Color(0xFF388E3C) : accent,
          width: 2.0,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (solved ? const Color(0xFF388E3C) : accent).withValues(alpha: .14),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.edit_note_rounded,
                color: solved ? const Color(0xFF388E3C) : accent,
                size: 18,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  english ? 'YOUR SENTENCE (TARGET)' : 'KURDUĞUN CÜMLE',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: solved ? const Color(0xFF2E7D32) : accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (solved ? const Color(0xFF388E3C) : accent)
                      .withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${assembled.length}/$targetLength',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: solved ? const Color(0xFF2E7D32) : accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (assembled.isNotEmpty && !solved) ...<Widget>[
                const SizedBox(width: 4),
                IconButton(
                  key: const ValueKey<String>('sentence_builder_undo'),
                  tooltip: english ? 'Undo last block' : 'Son bloğu geri al',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                ),
                IconButton(
                  key: const ValueKey<String>('sentence_builder_clear'),
                  tooltip: english ? 'Clear sentence' : 'Cümleyi temizle',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onClear,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (assembled.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: accent.withValues(alpha: .25),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.touch_app_outlined,
                      size: 15,
                      color: accent.withValues(alpha: .8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      english
                          ? 'Tap clause blocks below to place here'
                          : 'Aşağıdaki bloklara dokunarak cümleni kur',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: accent.withValues(alpha: .85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: <Widget>[
                for (final String part in assembled)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: solved
                            ? Colors.white
                            : StudioVisuals.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: solved
                              ? const Color(0xFF388E3C)
                              : accent.withValues(alpha: .7),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        child: Text(
                          part,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.ink,
                            fontSize: 11.5,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
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
}

class _ClauseChoices extends StatelessWidget {
  const _ClauseChoices({
    required this.parts,
    required this.selectedIndices,
    required this.accent,
    required this.onSelect,
  });

  final List<String> parts;
  final Set<int> selectedIndices;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        key: const ValueKey<String>('sentence_builder_choices'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 5),
            child: Text(
              context.l10n.isEnglish
                  ? 'AVAILABLE CLAUSE BLOCKS'
                  : 'CÜMLE BLOKLARI',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ),
          for (int index = 0; index < parts.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(height: 5),
            _ClauseChoice(
              index: index,
              text: parts[index],
              selected: selectedIndices.contains(index),
              accent: accent,
              onTap: () => onSelect(index),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClauseChoice extends StatelessWidget {
  const _ClauseChoice({
    required this.index,
    required this.text,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: .07) : StudioVisuals.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey<String>('sentence_builder_part_$index'),
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: .32)
                  : StudioVisuals.line,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: 11.5,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                color: selected ? accent : StudioVisuals.muted,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SentenceNote extends StatelessWidget {
  const _SentenceNote({
    required this.sentence,
    required this.note,
    required this.english,
    required this.accent,
  });

  final String sentence;
  final String note;
  final bool english;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('sentence_builder_note'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                Icon(Icons.rule_rounded, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  english ? 'SENTENCE LOGIC' : 'CÜMLE MANTIĞI',
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
              sentence,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              note,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 10.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentenceFeedback extends StatelessWidget {
  const _SentenceFeedback({required this.message, required this.accent});

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


