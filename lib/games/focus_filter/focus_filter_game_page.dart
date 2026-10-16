import '../shared/studio_game_contracts.dart';

import 'dart:async';

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
import '../../widgets/focus_shape_icon.dart';
import 'focus_filter_scenario.dart';

class FocusFilterGamePage extends StatefulWidget {
  const FocusFilterGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalLevels = GameContentPolicy.campaignLevels;
  static const int totalStars = totalLevels * 3;

  static final List<ParkurLevelSpec> levels = List<ParkurLevelSpec>.generate(
    GameContentPolicy.nativeStages('focus_filter'),
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Odak ${level.toString().padLeft(2, '0')}',
        titleEn: 'Focus ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Tek görsel özelliğini seçici biçimde izle',
          <= 6 => 'Renk değişse de hedef kuralını koru',
          <= 10 => 'İki ölçütü birlikte uygula, yakın yanıltıcıyı ele',
          <= 16 => 'Akışın ortasında değişen hedefi yakala',
          <= 19 => 'Nadir sinyali bul, yanlış alarma diren',
          _ => 'Önceki işareti hatırla • 24 deneme • tek hata hakkı',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Selectively track one visual feature',
          <= 6 => 'Hold the color rule while symbols change',
          <= 10 => 'Apply two conditions and reject near-misses',
          <= 16 => 'Catch the target as the rule shifts mid-stream',
          <= 19 => 'Find rare signals and resist false alarms',
          _ => 'Recall the previous shape • 24 trials • one mistake',
        },
        difficulty: level <= 3
            ? 'SEÇİCİLİK'
            : level <= 6
            ? 'ODAK'
            : level <= 10
            ? 'İLERİ'
            : level <= 16
            ? 'UZMAN'
            : 'USTA',
        icon: Icons.filter_center_focus_rounded,
      );
    },
    growable: false,
  );

  @override
  State<FocusFilterGamePage> createState() => _FocusFilterGamePageState();
}

class _FocusFilterGamePageState extends State<FocusFilterGamePage> {
  static const String _practiceKey = 'focus_filter_next_practice_round';
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
          .clamp(1, FocusFilterScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => FocusFilterPlayPage(
              level: FocusFilterGamePage
                  .levels[(round - 1) % FocusFilterGamePage.totalLevels],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == FocusFilterScenario.uniquePracticeRounds
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
              ? 'Focus set cleared • distinct filter $next / 300'
              : 'Odak turu tamamlandı • farklı filtre $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('focus_filter');
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'focus_filter',
      progressPrefix: 'focus_filter',
      titleTr: 'Odak Filtresi',
      titleEn: 'Focus Filter',
      taglineTr: 'Hedefi belle • yakın yanıltıcıyı ele • yanlış alarmı yönet',
      taglineEn: 'Hold the rule • reject near-misses • manage false alarms',
      accent: skin.accent,
      icon: Icons.filter_center_focus_rounded,
      levels: FocusFilterGamePage.levels,
      dailyCourseMode: widget.dailyCourseMode,
      competitionLevel: widget.competitionLevel,
      competitionLayoutCode: widget.competitionLayoutCode,
      hubAction: widget.competitionLevel != null
          ? null
          : OutlinedButton.icon(
              onPressed: _practiceLoading ? null : _openPractice,
              icon: const Icon(Icons.tune_rounded),
              label: Text(
                _practiceLoading
                    ? (english ? 'Loading…' : 'Yükleniyor…')
                    : english
                    ? 'UNIQUE FILTER • $_nextPracticeRound / 300'
                    : 'FARKLI FİLTRE • $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => FocusFilterPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          FocusFilterScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class FocusFilterPlayPage extends StatefulWidget {
  const FocusFilterPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<FocusFilterPlayPage> createState() => _FocusFilterPlayPageState();
}

class _FocusFilterPlayPageState extends State<FocusFilterPlayPage> {
  static const Duration _rulePreviewDuration = Duration(seconds: 10);
  static const Duration _previewTick = Duration(milliseconds: 100);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.memory,
  );
  late StudioGameSession _session;
  late FocusFilterScenario _scenario;
  bool _initialized = false;
  bool _failureOpen = false;
  bool _complete = false;
  bool _hintUsed = false;
  bool? _lastAnswerCorrect;
  int _currentTrial = 0;
  int _correctAnswers = 0;
  int _correctStreak = 0;
  int _longestStreak = 0;
  String? _feedback;
  Timer? _signalTimer;
  Timer? _previewTimer;
  Duration _signalRemaining = Duration.zero;
  Duration _previewRemaining = _rulePreviewDuration;
  bool _showingRulePreview = true;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  int get _mistakeLimit => widget.level.number <= 3
      ? 5
      : widget.level.number <= 6
      ? 4
      : widget.level.number <= 10
      ? 3
      : widget.level.number <= 16
      ? 2
      : widget.level.number <= 19
      ? 2
      : 1;
  int get _errorsLeft =>
      (_mistakeLimit - _session.mistakes).clamp(0, _mistakeLimit);
  Duration get _signalDuration => Duration(
    milliseconds: (1650 - (widget.level.number - 1) * 50)
        .clamp(700, 1650)
        .toInt(),
  );
  double get _signalTimeRemaining => _signalDuration.inMilliseconds == 0
      ? 0
      : (_signalRemaining.inMilliseconds / _signalDuration.inMilliseconds)
            .clamp(0, 1)
            .toDouble();
  int get _previewSeconds =>
      (_previewRemaining.inMilliseconds / 1000).ceil().clamp(0, 10).toInt();
  FocusStimulus get _stimulus =>
      _scenario.stimuli[_currentTrial.clamp(0, _scenario.stimuli.length - 1)];

  static const List<Color> _colors = <Color>[
    Color(0xFFD49A42),
    Color(0xFF4E7FC1),
    Color(0xFF259B91),
    Color(0xFFE57E6F),
    Color(0xFF8974C9),
    Color(0xFF6D9B65),
    Color(0xFFCE626B),
    Color(0xFF435B89),
  ];

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
    final int? round = widget.practiceRound;
    _scenario = round == null
        ? (widget.level.poolIndex != null
              ? FocusFilterScenario.forPracticeRound(
                  widget.level.contentIndex,
                  english: _english,
                )
              : FocusFilterScenario.forCampaignLevel(
                  widget.level.contentLevel,
                  english: _english,
                ))
        : FocusFilterScenario.forPracticeRound(round, english: _english);
    _startRulePreview();
  }

  void _startRulePreview() {
    _signalTimer?.cancel();
    _previewTimer?.cancel();
    _showingRulePreview = true;
    _previewRemaining = _rulePreviewDuration;
    _signalRemaining = _signalDuration;
    _previewTimer = Timer.periodic(_previewTick, (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final int previousSeconds = _previewSeconds;
      final int nextMilliseconds =
          _previewRemaining.inMilliseconds - _previewTick.inMilliseconds;
      if (nextMilliseconds <= 0) {
        timer.cancel();
        setState(() {
          _previewRemaining = Duration.zero;
          _showingRulePreview = false;
        });
        _scheduleSignalAdvance();
        return;
      }
      _previewRemaining = Duration(milliseconds: nextMilliseconds);
      if (_previewSeconds != previousSeconds) setState(() {});
    });
  }

  void _scheduleSignalAdvance() {
    _previewTimer?.cancel();
    _signalTimer?.cancel();
    if (_complete || _failureOpen || _showingRulePreview) return;
    _signalRemaining = _signalDuration;
    _signalTimer = Timer.periodic(const Duration(milliseconds: 50), (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final int nextMilliseconds = _signalRemaining.inMilliseconds - 50;
      if (nextMilliseconds <= 0) {
        timer.cancel();
        _answer(timedOut: true);
        return;
      }
      setState(() {
        _signalRemaining = Duration(milliseconds: nextMilliseconds);
      });
    });
  }

  void _answer({bool timedOut = false}) {
    if (_complete || _showingRulePreview || !_session.acceptsInput) return;
    _signalTimer?.cancel();
    final FocusStimulus current = _stimulus;
    final bool answerCorrect = timedOut ? !current.isTarget : current.isTarget;
    if (answerCorrect) {
      _session.recordAccepted(points: 30 + widget.level.number * 5);
      _correctAnswers++;
      _correctStreak++;
      if (_correctStreak > _longestStreak) {
        _longestStreak = _correctStreak;
      }
      _audio.hapticSelection();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .22));
    } else {
      _session.recordMistake();
      _correctStreak = 0;
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
    }
    final int next = _currentTrial + 1;
    setState(() {
      _lastAnswerCorrect = answerCorrect;
      _feedback = answerCorrect
          ? _english
                ? (current.isTarget
                      ? 'Signal detected.'
                      : timedOut
                      ? 'Signal passed safely.'
                      : 'False alarm avoided.')
                : current.isTarget
                ? 'Hedef doğru yakalandı.'
                : timedOut
                ? 'Sinyal doğru biçimde geçti.'
                : 'Yanlış alarm vermedin.'
          : current.isTarget
          ? (_english ? 'Missed signal.' : 'Hedef sinyal kaçtı.')
          : (_english ? 'False alarm.' : 'Yanlış alarm.');
      _currentTrial = next;
      _complete = next >= _scenario.stimuli.length;
    });
    if (_errorsLeft == 0 && !_failureOpen) {
      unawaited(_showFailure());
    } else if (!_complete) {
      _scheduleSignalAdvance();
    }
  }

  void _repeatRule() {
    if (_complete || !_session.useHint()) return;
    setState(() {
      _hintUsed = true;
      _feedback = _english
          ? 'Rule reminder: ${_scenario.instruction}'
          : 'Kural hatırlatma: ${_scenario.instruction}';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .20));
  }

  Future<void> _showFailure() async {
    _failureOpen = true;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'Filter lost' : 'Filtre dağıldı'),
        content: Text(
          _english
              ? 'The false-alarm budget is used. Review the rule and replay the signal stream.'
              : 'Yanlış alarm bütçen doldu. Kuralı yeniden gözden geçirip sinyal akışını tekrar oyna.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) _reset();
            },
            child: Text(_english ? 'RETRY' : 'YENİDEN DENE'),
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
    _failureOpen = false;
    if (mounted &&
        !_complete &&
        !_showingRulePreview &&
        _session.acceptsInput) {
      _scheduleSignalAdvance();
    }
  }

  void _reset() {
    _signalTimer?.cancel();
    _previewTimer?.cancel();
    setState(() {
      _currentTrial = 0;
      _correctAnswers = 0;
      _correctStreak = 0;
      _longestStreak = 0;
      _feedback = null;
      _lastAnswerCorrect = null;
      _complete = false;
      _hintUsed = false;
      _showingRulePreview = true;
      _previewRemaining = _rulePreviewDuration;
      _signalRemaining = _signalDuration;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
    _startRulePreview();
  }

  void _finish() {
    if (!_complete || _session.phase != StudioGamePhase.playing) return;
    final int stars = !_hintUsed && _session.mistakes == 0
        ? 3
        : _session.mistakes <= 1
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action:
          !_practice && widget.level.number < FocusFilterGamePage.totalLevels
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticHeavy();
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

  Widget _signalCard(bool english) {
    final bool compact = MediaQuery.sizeOf(context).width < 365;
    final bool preparing = _showingRulePreview;
    final FocusStimulus stimulus = _stimulus;
    final Color signal = preparing
        ? StudioGameSkin.forId('focus_filter').accent
        : _colors[stimulus.colorIndex % _colors.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0, .18),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey<String>(
          preparing ? 'focus_filter_rule_preview' : 'signal_${stimulus.index}',
        ),
        width: double.infinity,
        constraints: BoxConstraints(minHeight: compact ? 160 : 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFFDFDFB), Color(0xFFF0F3F6)],
          ),
          border: Border.all(color: const Color(0xFFE1E7ED)),
          boxShadow: StudioVisuals.softShadow,
        ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: SizedBox(
                  height: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ColoredBox(color: signal.withValues(alpha: .12)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _signalTimeRemaining,
                          heightFactor: 1,
                          child: ColoredBox(color: signal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: compact ? 12 : 18,
              right: compact ? 12 : 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEF4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  child: Text(
                    _showingRulePreview
                        ? (english
                              ? '$_previewSeconds s'
                              : '$_previewSeconds sn')
                        : '${stimulus.index + 1} / ${_scenario.stimuli.length}',
                    key: _showingRulePreview
                        ? const ValueKey<String>(
                            'focus_filter_rule_preview_countdown',
                          )
                        : null,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Color(0xFF56677B),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _SignalPatternPainter(
                  color: signal.withValues(alpha: .045),
                  variant: preparing ? 0 : stimulus.patternIndex,
                ),
              ),
            ),
            Semantics(
              key: const ValueKey<String>('focus_filter_signal'),
              button: !_showingRulePreview && !_complete,
              label: english ? 'Current visual signal' : 'Güncel görsel sinyal',
              hint: _showingRulePreview
                  ? (english ? 'Review the rule first.' : 'Önce kuralı incele.')
                  : (english
                        ? 'Tap the visual itself to answer.'
                        : 'Cevap vermek için görselin kendisine dokun.'),
              onTap: _showingRulePreview || _complete ? null : _answer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _showingRulePreview || _complete ? null : _answer,
                child: Container(
              width: compact ? 104 : 132,
              height: compact ? 104 : 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: signal.withValues(alpha: .11),
                border: Border.all(
                  color: stimulus.hasRing && !preparing
                      ? signal
                      : signal.withValues(alpha: .3),
                  width: stimulus.hasRing && !preparing ? 6 : 2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: signal.withValues(alpha: .13),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: preparing
                  ? Icon(
                      Icons.visibility_rounded,
                      size: compact ? 60 : 76,
                      color: signal,
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        FocusShapeIcon(
                          stimulus.shapeIndex,
                          size: compact ? 104 : 132,
                        ),
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: signal.withValues(alpha: .5),
                                width: 4,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
              ),
            ),
            Positioned(
              bottom: compact ? 12 : 19,
              child: Row(
                children: <Widget>[
                  if (!preparing && stimulus.patternIndex.isEven)
                    Icon(
                      Icons.circle,
                      color: signal.withValues(alpha: .45),
                      size: 6,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    preparing
                        ? (english ? 'RULE REVIEW' : 'KURAL HAZIRLIĞI')
                        : _scenario.rule == FocusFilterRule.rareSignal
                        ? stimulus.hasRing
                              ? (english ? 'RINGED SIGNAL' : 'HALKALI SİNYAL')
                              : (english ? 'PLAIN SIGNAL' : 'DÜZ SİNYAL')
                        : stimulus.patternIndex.isEven
                        ? (english ? 'TEXTURED' : 'DESENLİ')
                        : (english ? 'CLEAN' : 'SADE'),
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: signal.withValues(alpha: .88),
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
    );
  }

  @override
  void dispose() {
    _signalTimer?.cancel();
    _previewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final StudioGameSkin skin = StudioGameSkin.forId('focus_filter');
    final double width = MediaQuery.sizeOf(context).width;
    final bool compact = width < 365;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'FOCUS FILTER' : 'ODAK FİLTRESİ',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E8D8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${english ? 'ERRORS' : 'HATA'}  $_errorsLeft',
                  key: const ValueKey<String>('focus_filter_errors_left'),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF84632F),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              key: const ValueKey<String>('focus_filter_scroll'),
              padding: EdgeInsets.fromLTRB(
                compact ? 15 : 22,
                compact ? 2 : 5,
                compact ? 15 : 22,
                compact ? 10 : 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _progressHeader(english, skin),
                  SizedBox(height: compact ? 8 : 14),
                  _ruleCard(english),
                  SizedBox(height: compact ? 8 : 16),
                  Semantics(
                    label: english
                        ? 'Current visual signal'
                        : 'Güncel görsel sinyal',
                    child: _signalCard(english),
                  ),
                  if (!_showingRulePreview && !_complete)
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        english
                            ? 'Tap the shape itself to answer.'
                            : 'Cevap vermek için şeklin kendisine dokun.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: StudioVisuals.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  SizedBox(height: compact ? 7 : 14),
                  _statusLine(english),
                  SizedBox(height: compact ? 7 : 12),
                  if (_complete) _finishCard(english),
                  SizedBox(height: compact ? 6 : 12),
                  OutlinedButton.icon(
                    key: const ValueKey<String>('focus_filter_rule_hint'),
                    onPressed: _complete || _showingRulePreview
                        ? null
                        : _repeatRule,
                    icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                    label: Text(
                      english ? 'REMIND ME OF THE RULE' : 'KURALI HATIRLAT',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressHeader(bool english, StudioGameSkin skin) {
    final double progress = _currentTrial / _scenario.stimuli.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                widget.level.title(english).toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
            ),
            Text(
              widget.level.difficulty,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: skin.accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: const Color(0xFFE1E7ED),
            color: skin.accent,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                '${english ? 'CORRECT' : 'DOĞRU'}  $_correctAnswers',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF718096),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${english ? 'BEST STREAK' : 'EN UZUN SERİ'}  $_longestStreak',
                textAlign: TextAlign.end,
                maxLines: 2,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF718096),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ruleCard(bool english) {
    final Color accent = StudioGameSkin.forId('focus_filter').accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.rule_rounded, color: accent, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _scenario.ruleTitle,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _scenario.instruction,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${english ? 'FILTER' : 'FİLTRE'}  •  ${_scenario.targetLabel}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF607086),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusLine(bool english) {
    final bool? answered = _lastAnswerCorrect;
    final Color color = answered == null
        ? _showingRulePreview
              ? StudioGameSkin.forId('focus_filter').accent
              : const Color(0xFF657387)
        : answered
        ? const Color(0xFF648B72)
        : const Color(0xFFBF6A66);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            answered == null
                ? Icons.visibility_rounded
                : answered
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _showingRulePreview
                  ? (english
                        ? 'Review the rule. The signal stream starts in $_previewSeconds seconds.'
                        : 'Kuralı incele. Sinyal akışı $_previewSeconds saniye sonra başlayacak.')
                  : _feedback ??
                        (english
                            ? 'Signals flow automatically. Select only a target.'
                            : 'Sinyaller kendiliğinden akar. Yalnız hedefi seç.'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: color,
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _finishCard(bool english) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2EC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            english ? 'FILTER COMPLETE' : 'FİLTRE TAMAMLANDI',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF54785F),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            english
                ? '$_longestStreak consecutive correct decisions'
                : '$_longestStreak karar boyunca kesintisiz doğru',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey<String>('focus_filter_finish'),
            onPressed: _finish,
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    english ? 'SAVE RESULT' : 'SONUCU KAYDET',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalPatternPainter extends CustomPainter {
  const _SignalPatternPainter({required this.color, required this.variant});

  final Color color;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final double spacing = 25 + (variant % 3) * 7;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        final Offset point = Offset(x, y);
        if (variant.isEven) {
          canvas.drawCircle(point, 2.1, paint);
        } else {
          canvas.drawLine(
            point.translate(-2.5, -2.5),
            point.translate(2.5, 2.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SignalPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.variant != variant;
}
