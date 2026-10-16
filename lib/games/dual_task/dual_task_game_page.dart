import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../../widgets/realistic_game_object.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'dual_task_scenario.dart';

class DualTaskGamePage extends StatefulWidget {
  const DualTaskGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalLevels = DualTaskScenario.campaignLevels;
  static const int totalStars = totalLevels * 3;
  static final List<ParkurLevelSpec> levels = List<ParkurLevelSpec>.generate(
    totalLevels,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'İkili Görev ${level.toString().padLeft(2, '0')}',
        titleEn: 'Dual Task ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Bir şekil kuralına yanıt ver, iki sayıyı akılda tut',
          <= 6 => 'Şekil + renk süzgeci ve üç basamaklı geri çağırma',
          <= 10 => 'Görsel kural yarıda değişir',
          <= 16 => 'Yakın yanıltıcılar ve dört sayı birlikte gelir',
          <= 19 => '18 karar • beş sayı • ters geri çağırma',
          _ => '20 karar • üç kural geçişi • altı ters sayı • tek hata',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Respond to one shape rule and retain two digits',
          <= 6 => 'Shape + colour filter and a three-digit recall',
          <= 10 => 'The visual rule shifts halfway through',
          <= 16 => 'Near-misses and four digits run concurrently',
          <= 19 => '18 decisions • five digits • reverse recall',
          _ =>
            '20 decisions • three rule shifts • six reverse digits • one error',
        },
        difficulty: level <= 3
            ? 'ÇİFT ODAK'
            : level <= 6
            ? 'AKIŞ'
            : level <= 10
            ? 'KAYAN KURAL'
            : level <= 16
            ? 'UZMAN'
            : 'USTA',
        icon: Icons.dashboard_customize_rounded,
      );
    },
    growable: false,
  );

  @override
  State<DualTaskGamePage> createState() => _DualTaskGamePageState();
}

class _DualTaskGamePageState extends State<DualTaskGamePage> {
  static const String _practiceKey = 'dual_task_next_practice_round';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  bool _practiceLoading = true;
  int _nextPracticeRound = 1;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPractice());
  }

  Future<void> _loadPractice() async {
    final int stored = await _preferences.getInt(_practiceKey) ?? 1;
    if (!mounted) return;
    setState(() {
      _nextPracticeRound = stored
          .clamp(1, DualTaskScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => DualTaskPlayPage(
              level: DualTaskGamePage
                  .levels[(round - 1) % DualTaskGamePage.totalLevels],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == DualTaskScenario.uniquePracticeRounds
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
              ? 'Both tasks complete • unique pair $next / 300'
              : 'İki görev tamamlandı • farklı ikili $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.memory);
    return ParkurLevelHub(
      gameId: 'dual_task',
      progressPrefix: 'dual_task',
      titleTr: 'İkili Görev',
      titleEn: 'Dual Task',
      taglineTr:
          'Görsel sinyali çöz • sayı ipuçlarını sakla • iki beceriyi ayrı ölç',
      taglineEn:
          'Read the visual signal • retain number cues • score both skills',
      accent: skin.accent,
      icon: Icons.dashboard_customize_rounded,
      levels: DualTaskGamePage.levels,
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
                    ? 'UNIQUE TASK PAIRS • $_nextPracticeRound / 300'
                    : 'FARKLI GÖREV İKİLİSİ • $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => DualTaskPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          DualTaskScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class DualTaskPlayPage extends StatefulWidget {
  const DualTaskPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<DualTaskPlayPage> createState() => _DualTaskPlayPageState();
}

class _DualTaskPlayPageState extends State<DualTaskPlayPage>
    with WidgetsBindingObserver {
  static const List<Color> _colors = <Color>[
    Color(0xFF5378A8),
    Color(0xFF5E8F99),
    Color(0xFF6F9A78),
    Color(0xFFB08A58),
    Color(0xFFB47463),
    Color(0xFF9B76A5),
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.memory,
  );
  Timer? _trialTimer;
  late StudioGameSession _session;
  late DualTaskScenario _scenario;
  bool _initialized = false;
  bool _active = false;
  bool _memoryPhase = false;
  bool _solved = false;
  bool _hintUsed = false;
  bool _answerLocked = false;
  bool _ruleShift = false;
  bool? _lastCorrect;
  int _trialIndex = 0;
  int _primaryCorrect = 0;
  int _primaryErrors = 0;
  int _memoryCorrect = 0;
  int _memoryErrors = 0;
  final List<int> _memoryEntry = <int>[];
  String? _feedback;
  int? _hintDigit;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  int get _errorsLeft => (_scenario.mistakeLimit - _primaryErrors).clamp(0, 5);
  DualTaskTrial get _current => _scenario.trials[_trialIndex];
  List<int> get _memoryAnswer => _scenario.recallAnswer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _scenario = widget.practiceRound == null
        ? DualTaskScenario.forCampaignLevel(widget.level.number)
        : DualTaskScenario.forPracticeRound(widget.practiceRound!);
  }

  @override
  void dispose() {
    _trialTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused &&
        state != AppLifecycleState.hidden) {
      return;
    }
    if (!mounted || !_active) return;
    _trialTimer?.cancel();
    setState(() {
      _active = false;
      _memoryPhase = false;
      _answerLocked = false;
      _trialIndex = 0;
      _primaryCorrect = 0;
      _primaryErrors = 0;
      _memoryCorrect = 0;
      _memoryErrors = 0;
      _memoryEntry.clear();
      _hintDigit = null;
      _feedback = _english
          ? 'Dual task paused safely. Restart to begin a fresh run.'
          : 'İkili görev güvenle durdu. Yeni tur için yeniden başlat.';
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _start() {
    if (_active || _solved) return;
    setState(() {
      _active = true;
      _memoryPhase = false;
      _answerLocked = false;
      _trialIndex = 0;
      _primaryCorrect = 0;
      _primaryErrors = 0;
      _memoryCorrect = 0;
      _memoryErrors = 0;
      _memoryEntry.clear();
      _hintDigit = null;
      _feedback = null;
      _lastCorrect = null;
      _ruleShift = false;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .14),
    );
    _armPrimaryTimer();
  }

  void _armPrimaryTimer() {
    _trialTimer?.cancel();
    _trialTimer = Timer(Duration(milliseconds: _scenario.exposureMs), () {
      if (_active && !_memoryPhase && !_answerLocked) {
        _answerPrimary(false, timedOut: true);
      }
    });
  }

  void _answerPrimary(bool match, {bool timedOut = false}) {
    if (!_active || _memoryPhase || _answerLocked || !_session.acceptsInput) {
      return;
    }
    _answerLocked = true;
    _trialTimer?.cancel();
    final bool correct = match == _current.isTarget;
    if (correct) {
      _primaryCorrect++;
      _session.recordAccepted(points: 90 + widget.level.number * 10);
      _audio.hapticSelection();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .18));
    } else {
      _primaryErrors++;
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
    }
    setState(() {
      _lastCorrect = correct;
      _feedback = timedOut && _current.isTarget
          ? (_english
                ? 'Signal window closed • $_errorsLeft primary error(s) left.'
                : 'Sinyal penceresi kapandı • $_errorsLeft ana görev hakkı kaldı.')
          : correct
          ? (_english ? 'Signal classified.' : 'Sinyal sınıflandırıldı.')
          : (_english
                ? 'Signal missed • $_errorsLeft primary error(s) left.'
                : 'Sinyal kaçtı • $_errorsLeft ana görev hakkı kaldı.');
    });
    if (_primaryErrors >= _scenario.mistakeLimit && !correct) {
      unawaited(_showFailure());
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 240), () {
      if (!mounted || !_active || _memoryPhase) return;
      if (_trialIndex + 1 >= _scenario.trialCount) {
        setState(() {
          _memoryPhase = true;
          _answerLocked = false;
          _feedback = _english
              ? 'Primary task complete • recall the gold-card digits.'
              : 'Ana görev bitti • altın kartların sayılarını geri çağır.';
          _lastCorrect = null;
        });
        return;
      }
      setState(() {
        _trialIndex++;
        _answerLocked = false;
        _ruleShift = _scenario.ruleChangeBeforeTrial.contains(_trialIndex);
        _lastCorrect = null;
        _feedback = _ruleShift
            ? (_english
                  ? 'RULE SHIFT • keep the number stream running too.'
                  : 'KURAL DEĞİŞTİ • sayı akışını da aklında tut.')
            : null;
      });
      if (_ruleShift) {
        _audio.hapticLight();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.timeWarning, gain: .18),
        );
      }
      _armPrimaryTimer();
    });
  }

  void _enterMemoryDigit(int digit) {
    if (!_active ||
        !_memoryPhase ||
        !_session.acceptsInput ||
        _memoryEntry.length >= _memoryAnswer.length) {
      return;
    }
    final int index = _memoryEntry.length;
    final bool correct = digit == _memoryAnswer[index];
    if (correct) {
      _memoryCorrect++;
      _audio.hapticSelection();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .16));
    } else {
      _memoryErrors++;
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .16));
    }
    setState(() {
      _memoryEntry.add(digit);
      _lastCorrect = correct;
      _feedback = correct
          ? (_english ? 'Digit secured.' : 'Sayı kaydedildi.')
          : (_english
                ? 'Different digit • memory score updated.'
                : 'Farklı sayı • bellek puanı güncellendi.');
    });
    if (_memoryEntry.length >= _memoryAnswer.length) {
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted && _active && _memoryPhase) _completeRun();
      });
    }
  }

  void _useHint() {
    if (!_memoryPhase || !_active || !_session.useHint(pointCost: 45)) return;
    _hintUsed = true;
    _hintDigit = _memoryAnswer[_memoryEntry.length];
    setState(() {
      _feedback = _english
          ? 'Hint • the next digit is $_hintDigit.'
          : 'İpucu • sıradaki sayı $_hintDigit.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .18));
  }

  void _completeRun() {
    if (_solved) return;
    final int total = _primaryCorrect + _memoryCorrect;
    setState(() {
      _active = false;
      _memoryPhase = false;
      _solved = true;
      _feedback = _english
          ? 'Two tasks complete • visual $_primaryCorrect/${_scenario.trialCount} • memory $_memoryCorrect/${_scenario.memoryLength}.'
          : 'İki görev tamam • görsel $_primaryCorrect/${_scenario.trialCount} • bellek $_memoryCorrect/${_scenario.memoryLength}.';
      _lastCorrect = total > 0;
    });
  }

  Future<void> _showFailure() async {
    _trialTimer?.cancel();
    _active = false;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'Primary stream overloaded' : 'Görsel akış koptu',
        ),
        content: Text(
          _english
              ? 'The primary-task error budget is used. Reset both streams and try again.'
              : 'Ana görev hata hakkın doldu. İki akışı sıfırlayıp yeniden dene.',
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
  }

  void _reset() {
    _trialTimer?.cancel();
    setState(() {
      _active = false;
      _memoryPhase = false;
      _answerLocked = false;
      _solved = false;
      _hintUsed = false;
      _trialIndex = 0;
      _primaryCorrect = 0;
      _primaryErrors = 0;
      _memoryCorrect = 0;
      _memoryErrors = 0;
      _memoryEntry.clear();
      _hintDigit = null;
      _feedback = null;
      _lastCorrect = null;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _finish() {
    if (!_solved || _session.phase != StudioGamePhase.playing) return;
    final int stars = !_hintUsed && _primaryErrors == 0 && _memoryErrors == 0
        ? 3
        : _primaryErrors <= 1 && _memoryErrors <= 1
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: !_practice && widget.level.number < DualTaskGamePage.totalLevels
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

  Widget _symbolCard({required bool compact}) {
    final DualTaskTrial trial = _current;
    final bool cue = trial.isMemoryCue;
    return Container(
      key: const ValueKey<String>('dual_task_trial_card'),
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _ruleShift
              ? StudioVisuals.amber.withValues(alpha: .55)
              : StudioVisuals.line,
        ),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${_english ? 'VISUAL' : 'GÖRSEL'}  ${(_trialIndex + 1).toString().padLeft(2, '0')} / ${_scenario.trialCount}',
                  style: const TextStyle(
                    color: StudioVisuals.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
              _DualTaskTag(
                label: _ruleLabel(trial.rule.mode),
                tint: _ruleShift ? StudioVisuals.amber : StudioVisuals.teal,
              ),
            ],
          ),
          const SizedBox(height: 17),
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: compact ? 116 : 140,
                height: compact ? 116 : 140,
                decoration: BoxDecoration(
                  color: _colors[trial.symbol.color].withValues(alpha: .10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _colors[trial.symbol.color].withValues(alpha: .3),
                    width: 1.5,
                  ),
                ),
              ),
              SizedBox(
                width: compact ? 82 : 100,
                height: compact ? 82 : 100,
                child: RealisticGameObject(
                  sheet: RealisticObjectSheet.tokens,
                  index: trial.symbol.shape,
                  borderRadius: 18,
                  overlayColor: _colors[trial.symbol.color].withValues(alpha: .12),
                ),
              ),
              if (trial.symbol.marker > 0)
                Positioned(
                  right: compact ? 28 : 36,
                  top: compact ? 25 : 33,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: StudioVisuals.amber,
                      shape: trial.symbol.marker.isOdd
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      borderRadius: trial.symbol.marker.isOdd
                          ? null
                          : BorderRadius.circular(2),
                    ),
                  ),
                ),
              if (cue)
                Positioned(
                  right: compact ? 2 : 8,
                  bottom: compact ? 4 : 7,
                  child: Container(
                    key: const ValueKey<String>('dual_task_memory_cue'),
                    width: compact ? 39 : 46,
                    height: compact ? 39 : 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: StudioVisuals.amber),
                      boxShadow: StudioVisuals.softShadow,
                    ),
                    child: Text(
                      '${trial.memoryDigit}',
                      style: TextStyle(
                        color: StudioVisuals.ink,
                        fontSize: compact ? 21 : 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _ruleDescription(trial.rule),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StudioVisuals.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (cue) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _english
                  ? 'SECOND TASK • keep the gold digit'
                  : 'İKİNCİ GÖREV • altın sayıyı aklında tut',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: StudioVisuals.amber,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _ruleLabel(DualTaskRuleMode mode) => switch (mode) {
    DualTaskRuleMode.shape => _english ? 'SHAPE' : 'ŞEKİL',
    DualTaskRuleMode.shapeAndColor =>
      _english ? 'SHAPE + COLOUR' : 'ŞEKİL + RENK',
    DualTaskRuleMode.exact => _english ? 'EXACT' : 'TAM EŞ',
  };

  String _ruleDescription(DualTaskRule rule) {
    final String shape = _shapeName(rule.shape);
    final String color = _colorName(rule.color);
    return switch (rule.mode) {
      DualTaskRuleMode.shape =>
        _english
            ? 'Tap MATCH for every $shape. Ignore every other shape.'
            : 'Her $shape gördüğünde EŞLEŞ seç. Diğer şekilleri ele.',
      DualTaskRuleMode.shapeAndColor =>
        _english
            ? 'Tap MATCH only for the $color $shape.'
            : 'Yalnız $color $shape için EŞLEŞ seç.',
      DualTaskRuleMode.exact =>
        _english
            ? 'Tap MATCH only when shape, colour and marker all match.'
            : 'Yalnız şekil, renk ve işaret üçünün de eşleştiğinde seç.',
    };
  }

  String _shapeName(int index) => (_english
      ? <String>['circle', 'square', 'triangle', 'diamond', 'star', 'hexagon']
      : <String>[
          'daire',
          'kare',
          'üçgen',
          'baklava',
          'yıldız',
          'altıgen',
        ])[index];

  String _colorName(int index) => (_english
      ? <String>['blue', 'teal', 'green', 'gold', 'coral', 'violet']
      : <String>['mavi', 'turkuaz', 'yeşil', 'altın', 'mercan', 'mor'])[index];

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final bool compact = MediaQuery.sizeOf(context).width < 365;
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.memory);
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'DUAL TASK' : 'İKİLİ GÖREV',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: .9,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Center(
              child: _DualTaskMetric(
                icon: Icons.favorite_border_rounded,
                value: '$_errorsLeft',
                color: _errorsLeft <= 1 ? StudioVisuals.danger : skin.accent,
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
              key: const ValueKey<String>('dual_task_scroll'),
              padding: EdgeInsets.fromLTRB(
                compact ? 13 : 22,
                compact ? 4 : 12,
                compact ? 13 : 22,
                compact ? 10 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _memoryPhase
                              ? (english
                                    ? 'SECONDARY RECALL'
                                    : 'İKİNCİ GÖREV • GERİ ÇAĞIR')
                              : (english
                                    ? 'PRIMARY + MEMORY'
                                    : 'ANA GÖREV + BELLEK'),
                          style: TextStyle(
                            color: skin.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .9,
                          ),
                        ),
                      ),
                      _DualTaskMetric(
                        icon: Icons.visibility_rounded,
                        value: '$_primaryCorrect/${_scenario.trialCount}',
                        color: StudioVisuals.teal,
                      ),
                      const SizedBox(width: 5),
                      _DualTaskMetric(
                        icon: Icons.memory_rounded,
                        value: '$_memoryCorrect/${_scenario.memoryLength}',
                        color: StudioVisuals.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  if (!_active)
                    Container(
                      padding: EdgeInsets.all(compact ? 14 : 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: StudioVisuals.line),
                        boxShadow: StudioVisuals.softShadow,
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _DualTaskIntroTile(
                                  icon: Icons.center_focus_strong_rounded,
                                  title: english
                                      ? 'VISUAL TASK'
                                      : 'GÖRSEL GÖREV',
                                  detail: english
                                      ? 'Classify every signal as match / no match.'
                                      : 'Her sinyali eşleşiyor / eşleşmiyor diye sınıflandır.',
                                  tint: StudioVisuals.teal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _DualTaskIntroTile(
                            icon: Icons.memory_rounded,
                            title: english ? 'MEMORY TASK' : 'BELLEK GÖREVİ',
                            detail: english
                                ? 'Retain the small gold digits and recall them after the stream.'
                                : 'Küçük altın sayıları aklında tut, akış bitince geri çağır.',
                            tint: StudioVisuals.amber,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            english
                                ? 'Each score stays separate, so a hard recall does not erase visual accuracy.'
                                : 'İki puan ayrı tutulur; zor sayı dizisi görsel doğruluğunu silmez.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: StudioVisuals.muted,
                              fontSize: 10,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_active && !_memoryPhase) _symbolCard(compact: compact),
                  if (_active && _memoryPhase)
                    _DualTaskRecallPanel(
                      english: english,
                      expectedLength: _scenario.memoryLength,
                      entered: _memoryEntry,
                      hintDigit: _hintDigit,
                      reversed: _scenario.reverseMemoryRecall,
                      onDigit: _enterMemoryDigit,
                    ),
                  if (_feedback != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _DualTaskFeedback(
                      text: _feedback!,
                      positive: _lastCorrect ?? false,
                    ),
                  ],
                  const SizedBox(height: 9),
                  if (_solved)
                    FilledButton.icon(
                      key: const ValueKey<String>('dual_task_finish'),
                      onPressed: _finish,
                      icon: const Icon(Icons.celebration_rounded),
                      label: Text(
                        english ? 'COMPLETE BOTH TASKS' : 'İKİ GÖREVİ TAMAMLA',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (!_active)
                    FilledButton.icon(
                      key: const ValueKey<String>('dual_task_start'),
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        english ? 'START BOTH TASKS' : 'İKİLİ GÖREVİ BAŞLAT',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (_memoryPhase)
                    FilledButton.tonalIcon(
                      key: const ValueKey<String>('dual_task_hint'),
                      onPressed: _session.acceptsInput ? _useHint : null,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: Text(english ? 'HINT • 45' : 'İPUCU • 45'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 44),
                        foregroundColor: StudioVisuals.ink,
                      ),
                    )
                  else
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey<String>('dual_task_no_match'),
                            onPressed: _session.acceptsInput && !_answerLocked
                                ? () => _answerPrimary(false)
                                : null,
                            icon: const Icon(Icons.close_rounded),
                            label: Text(
                              english ? 'NO MATCH' : 'EŞLEŞMİYOR',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: StudioVisuals.ink,
                              minimumSize: const Size(44, 50),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey<String>('dual_task_match'),
                            onPressed: _session.acceptsInput && !_answerLocked
                                ? () => _answerPrimary(true)
                                : null,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(
                              english ? 'MATCH' : 'EŞLEŞİYOR',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: skin.accent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(44, 50),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_active && !_memoryPhase) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      english
                          ? 'Keep classifying each signal while retaining gold-card digits.'
                          : 'Altın kartların sayılarını tutarken her sinyali sınıflandır.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DualTaskIntroTile extends StatelessWidget {
  const _DualTaskIntroTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: tint.withValues(alpha: .16)),
    ),
    child: Row(
      children: <Widget>[
        Icon(icon, color: tint, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: tint,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DualTaskRecallPanel extends StatelessWidget {
  const _DualTaskRecallPanel({
    required this.english,
    required this.expectedLength,
    required this.entered,
    required this.hintDigit,
    required this.reversed,
    required this.onDigit,
  });

  final bool english;
  final int expectedLength;
  final List<int> entered;
  final int? hintDigit;
  final bool reversed;
  final ValueChanged<int> onDigit;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('dual_task_recall_panel'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Column(
      children: <Widget>[
        Text(
          '${english ? 'MEMORY TASK' : 'BELLEK GÖREVİ'} • ${entered.length + 1}/$expectedLength',
          style: const TextStyle(
            color: StudioVisuals.amber,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          reversed
              ? (english
                    ? 'Recall the digits in reverse order.'
                    : 'Sayıları tersten sırayla geri çağır.')
              : (english
                    ? 'Recall the gold-card digits in order.'
                    : 'Altın kartlardaki sayıları sırayla geri çağır.'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (hintDigit != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            '${english ? 'HINT' : 'İPUCU'}: $hintDigit',
            style: const TextStyle(
              color: StudioVisuals.amber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 5,
          children: <Widget>[
            for (int index = 0; index < expectedLength; index++)
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: index < entered.length
                      ? StudioVisuals.teal.withValues(alpha: .12)
                      : const Color(0xFFF3F5F7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: StudioVisuals.line),
                ),
                child: Text(
                  index < entered.length ? '${entered[index]}' : '•',
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (int digit = 0; digit <= 9; digit++)
              SizedBox(
                width: 48,
                height: 40,
                child: OutlinedButton(
                  key: ValueKey<String>('dual_task_digit_$digit'),
                  onPressed: entered.length < expectedLength
                      ? () => onDigit(digit)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: StudioVisuals.ink,
                    side: BorderSide(
                      color: hintDigit == digit
                          ? StudioVisuals.amber
                          : StudioVisuals.line,
                    ),
                  ),
                  child: Text(
                    '$digit',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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

class _DualTaskMetric extends StatelessWidget {
  const _DualTaskMetric({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _DualTaskTag extends StatelessWidget {
  const _DualTaskTag({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: tint,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: .5,
      ),
    ),
  );
}

class _DualTaskFeedback extends StatelessWidget {
  const _DualTaskFeedback({required this.text, required this.positive});

  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final Color tint = positive ? StudioVisuals.teal : StudioVisuals.amber;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: .24)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: tint,
          fontSize: 10,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
