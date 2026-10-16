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
import 'symbol_stream_scenario.dart';

class SymbolStreamGamePage extends StatefulWidget {
  const SymbolStreamGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalLevels = SymbolStreamScenario.campaignLevels;
  static const int totalStars = totalLevels * 3;
  static final List<ParkurLevelSpec> levels = List<ParkurLevelSpec>.generate(
    totalLevels,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Akış ${level.toString().padLeft(2, '0')}',
        titleEn: 'Stream ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Bir önceki sembolle şekli ve rengi karşılaştır',
          <= 6 => 'Uzayan akışta yakın eşleşmeleri ayıkla',
          <= 10 => 'Kural 1-adımdan 2-adıma sessizce kayar',
          <= 16 => 'İki gerideki sembolü izle, özellik kuralını yenile',
          <= 19 => 'Üç geriyi zihinde tut; işaret kaymalarına dikkat et',
          _ => 'Usta finali • 16 simge • 3-geri • iki kural değişimi',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Compare shape and colour with the previous symbol',
          <= 6 => 'Filter near-matches in a longer stream',
          <= 10 => 'The rule quietly shifts from 1-back to 2-back',
          <= 16 => 'Track two items back as the comparison rule changes',
          <= 19 => 'Hold three positions in mind and watch feature shifts',
          _ => 'Master finale • 16 symbols • 3-back • two rule shifts',
        },
        difficulty: level <= 3
            ? 'AKIŞ'
            : level <= 6
            ? 'ODAK'
            : level <= 10
            ? 'İLERİ'
            : level <= 16
            ? 'UZMAN'
            : 'USTA',
        icon: Icons.view_stream_rounded,
      );
    },
    growable: false,
  );

  @override
  State<SymbolStreamGamePage> createState() => _SymbolStreamGamePageState();
}

class _SymbolStreamGamePageState extends State<SymbolStreamGamePage> {
  static const String _practiceKey = 'symbol_stream_next_practice_round';
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
          .clamp(1, SymbolStreamScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => SymbolStreamPlayPage(
              level: SymbolStreamGamePage
                  .levels[(round - 1) % SymbolStreamGamePage.totalLevels],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == SymbolStreamScenario.uniquePracticeRounds
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
              ? 'Stream cleared • unique sequence $next / 300'
              : 'Akış çözüldü • farklı dizi $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.memory);
    return ParkurLevelHub(
      gameId: 'symbol_stream',
      progressPrefix: 'symbol_stream',
      titleTr: 'Sembol Akışı',
      titleEn: 'Symbol Stream',
      taglineTr: 'Akışı izle • gerideki sembolle karşılaştır • kuralı güncelle',
      taglineEn: 'Track the stream • compare backward • update the rule',
      accent: skin.accent,
      icon: Icons.view_stream_rounded,
      levels: SymbolStreamGamePage.levels,
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
                    ? 'UNIQUE STREAMS • $_nextPracticeRound / 300'
                    : 'FARKLI AKIŞ • $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => SymbolStreamPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          SymbolStreamScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class SymbolStreamPlayPage extends StatefulWidget {
  const SymbolStreamPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<SymbolStreamPlayPage> createState() => _SymbolStreamPlayPageState();
}

class _SymbolStreamPlayPageState extends State<SymbolStreamPlayPage>
    with WidgetsBindingObserver {
  static const List<Color> _colors = <Color>[
    Color(0xFF5378A8),
    Color(0xFF5E8F99),
    Color(0xFF6F9A78),
    Color(0xFFB08A58),
    Color(0xFFB47463),
    Color(0xFF9B76A5),
    Color(0xFF6E83AE),
    Color(0xFF678F88),
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.memory,
  );
  late StudioGameSession _session;
  late SymbolStreamScenario _scenario;
  bool _initialized = false;
  bool _running = false;
  bool _awaitingResponse = false;
  bool _solved = false;
  bool _hintUsed = false;
  bool _failureOpen = false;
  bool? _lastCorrect;
  bool _ruleShift = false;
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _generation = 0;
  final Map<int, bool> _responseResults = <int, bool>{};
  String? _feedback;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  int get _errorsLeft =>
      (_scenario.mistakeLimit - _session.mistakes).clamp(0, 5);
  SymbolStreamItem get _current => _scenario.items[_currentIndex];
  SymbolStreamItem? get _target => _current.targetIndex == null
      ? null
      : _scenario.items[_current.targetIndex!];

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
        ? SymbolStreamScenario.forCampaignLevel(widget.level.number)
        : SymbolStreamScenario.forPracticeRound(widget.practiceRound!);
  }

  @override
  void dispose() {
    _generation++;
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
    if (!mounted || !_running) return;
    _generation++;
    setState(() {
      _running = false;
      _awaitingResponse = false;
      _currentIndex = 0;
      _correctAnswers = 0;
      _responseResults.clear();
      _lastCorrect = null;
      _ruleShift = false;
      _feedback = _english
          ? 'Stream paused safely. Restart when you are ready.'
          : 'Akış güvenle durdu. Hazır olduğunda yeniden başlat.';
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  Future<void> _startStream() async {
    if (_running || _solved) return;
    final int generation = ++_generation;
    setState(() {
      _running = true;
      _awaitingResponse = false;
      _currentIndex = 0;
      _correctAnswers = 0;
      _responseResults.clear();
      _lastCorrect = null;
      _ruleShift = false;
      _feedback = null;
    });
    await _showItem(0, generation);
  }

  Future<void> _showItem(int index, int generation) async {
    if (!mounted || generation != _generation || !_running) return;
    if (index >= _scenario.length) {
      _completeStream();
      return;
    }
    final SymbolStreamItem next = _scenario.items[index];
    final SymbolStreamItem? previous = index == 0
        ? null
        : _scenario.items[index - 1];
    final bool shift =
        previous != null &&
        (previous.nBackDistance != next.nBackDistance ||
            previous.mode != next.mode);
    setState(() {
      _currentIndex = index;
      _awaitingResponse = false;
      _lastCorrect = null;
      _ruleShift = shift;
      _feedback = shift
          ? (_english
                ? 'RULE SHIFT • read the new comparison rule'
                : 'KURAL DEĞİŞTİ • yeni karşılaştırmayı oku')
          : null;
    });
    if (shift) {
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.timeWarning, gain: .18),
      );
      _audio.hapticLight();
    } else {
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .12),
      );
      _audio.hapticSelection();
    }
    final int exposureMs = _scenario.stage <= 6
        ? 760
        : _scenario.stage <= 10
        ? 640
        : _scenario.stage <= 16
        ? 540
        : 450;
    await Future<void>.delayed(Duration(milliseconds: exposureMs));
    if (!mounted || generation != _generation || !_running) return;
    if (next.hasDecision) {
      setState(() {
        _awaitingResponse = true;
        _feedback = shift
            ? (_english
                  ? 'Compare with the NEW distance and feature rule.'
                  : 'Yeni mesafe ve özellik kuralına göre karşılaştır.')
            : _english
            ? 'Does this match the symbol at ${next.nBackDistance} back?'
            : '${next.nBackDistance} adım gerideki sembolle eşleşiyor mu?';
      });
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await _showItem(index + 1, generation);
  }

  void _answer(bool match) {
    if (!_running || !_awaitingResponse || !_session.acceptsInput) return;
    final bool correct = match == _current.matches;
    if (correct) {
      _correctAnswers++;
      _audio.hapticSelection();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
    } else {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
    }
    final int nextIndex = _currentIndex + 1;
    final int generation = _generation;
    setState(() {
      _responseResults[_currentIndex] = correct;
      _awaitingResponse = false;
      _lastCorrect = correct;
      _feedback = correct
          ? (_english ? 'Signal logged.' : 'Yanıt kaydedildi.')
          : (_english
                ? 'Not this time • $_errorsLeft error(s) left.'
                : 'Bu kez olmadı • $_errorsLeft hata hakkı kaldı.');
    });
    if (_errorsLeft <= 0 && !_failureOpen) {
      unawaited(_showFailure());
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted && generation == _generation) {
        unawaited(_showItem(nextIndex, generation));
      }
    });
  }

  void _useHint() {
    if (!_awaitingResponse || !_session.useHint(pointCost: 45)) return;
    _hintUsed = true;
    setState(() {
      _feedback = _english
          ? 'Hint: compare ${_current.mode.name == 'shape'
                ? 'shape only'
                : _current.mode == SymbolCompareMode.shapeAndColor
                ? 'shape + colour'
                : 'the complete symbol'} with ${_current.nBackDistance} back.'
          : 'İpucu: ${_current.mode == SymbolCompareMode.shape
                ? 'yalnız şekli'
                : _current.mode == SymbolCompareMode.shapeAndColor
                ? 'şekil + rengi'
                : 'sembolün tamamını'} ${_current.nBackDistance} adım gerisiyle karşılaştır.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .2));
  }

  void _completeStream() {
    if (_solved) return;
    _session.recordAccepted(points: 160 + widget.level.number * 22);
    setState(() {
      _solved = true;
      _running = false;
      _awaitingResponse = false;
      _feedback = _english
          ? 'Stream complete • $_correctAnswers / ${_scenario.decisionCount} decisions correct.'
          : 'Akış tamamlandı • ${_scenario.decisionCount} karardan $_correctAnswers doğru.';
    });
  }

  Future<void> _showFailure() async {
    _failureOpen = true;
    _running = false;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'Stream overloaded' : 'Akış koptu'),
        content: Text(
          _english
              ? 'The error budget is used. Clear the stream and try again.'
              : 'Hata hakkın doldu. Akışı sıfırlayıp yeniden dene.',
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
  }

  void _reset() {
    _generation++;
    setState(() {
      _running = false;
      _awaitingResponse = false;
      _solved = false;
      _hintUsed = false;
      _currentIndex = 0;
      _correctAnswers = 0;
      _responseResults.clear();
      _lastCorrect = null;
      _ruleShift = false;
      _feedback = null;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _finish() {
    if (!_solved || _session.phase != StudioGamePhase.playing) return;
    final int stars = !_hintUsed && _session.mistakes == 0
        ? 3
        : _session.mistakes <= 1
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action:
          !_practice && widget.level.number < SymbolStreamGamePage.totalLevels
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

  Widget _symbolCard(
    StreamSymbol symbol, {
    required bool compact,
    bool highlighted = false,
    String? caption,
  }) {
    final Color color = _colors[symbol.color % _colors.length];
    final Color border = highlighted ? color : StudioVisuals.line;
    return Container(
      key: caption == null ? null : ValueKey<String>('symbol_stream_$caption'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 16,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border, width: highlighted ? 2 : 1),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                width: compact ? 58 : 78,
                height: compact ? 58 : 78,
                child: RealisticGameObject(
                  sheet: RealisticObjectSheet.tokens,
                  index: symbol.shape,
                  borderRadius: 14,
                  overlayColor: color.withValues(alpha: .12),
                ),
              ),
              if (symbol.marker > 0)
                Positioned(
                  right: compact ? 3 : 8,
                  top: compact ? 5 : 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: StudioVisuals.amber,
                      borderRadius: BorderRadius.circular(
                        symbol.marker == 1 ? 8 : 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              caption,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _modeLabel(SymbolCompareMode mode) {
    if (mode == SymbolCompareMode.shape) {
      return _english ? 'SHAPE ONLY' : 'YALNIZ ŞEKİL';
    }
    if (mode == SymbolCompareMode.shapeAndColor) {
      return _english ? 'SHAPE + COLOUR' : 'ŞEKİL + RENK';
    }
    return _english ? 'EXACT SYMBOL' : 'TAM SEMBOL';
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final bool compact = MediaQuery.sizeOf(context).width < 365;
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.memory);
    final int displayNumber = _scenario.items.isEmpty ? 0 : _currentIndex + 1;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'SYMBOL STREAM' : 'SEMBOL AKIŞI',
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
              child: _StreamMetric(
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
              key: const ValueKey<String>('symbol_stream_scroll'),
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
                          _running
                              ? 'N-BACK • ${_current.nBackDistance}'
                              : (english ? 'WORKING MEMORY' : 'ÇALIŞAN BELLEK'),
                          style: TextStyle(
                            color: skin.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      _StreamMetric(
                        icon: Icons.view_stream_rounded,
                        value: '$displayNumber/${_scenario.length}',
                        color: StudioVisuals.ink,
                      ),
                      const SizedBox(width: 6),
                      _StreamMetric(
                        icon: Icons.stars_rounded,
                        value: '${_session.score}',
                        color: StudioVisuals.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Container(
                    padding: EdgeInsets.all(compact ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: StudioVisuals.line),
                      boxShadow: StudioVisuals.softShadow,
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: skin.accentSoft,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.compare_arrows_rounded,
                                color: skin.accent,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                _running
                                    ? _modeLabel(_current.mode)
                                    : (english
                                          ? 'KEEP THE STREAM IN MIND'
                                          : 'AKIŞI ZİHNİNDE TUT'),
                                style: const TextStyle(
                                  color: StudioVisuals.ink,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (_ruleShift)
                              _StreamTag(
                                label: english ? 'SHIFT' : 'KURAL',
                                tint: StudioVisuals.amber,
                                surface: const Color(0xFFFFF5E5),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _running
                                ? (_english
                                      ? 'Compare with the symbol ${_current.nBackDistance} step${_current.nBackDistance == 1 ? '' : 's'} back • ${_modeLabel(_current.mode).toLowerCase()}'
                                      : '${_current.nBackDistance} adım geriye bak • ${_modeLabel(_current.mode).toLowerCase()}')
                                : (english
                                      ? 'Answer MATCH or NO MATCH after each new symbol.'
                                      : 'Her yeni sembolden sonra EŞLEŞİYOR / EŞLEŞMİYOR yanıtı ver.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: StudioVisuals.muted,
                              fontSize: 10,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _symbolCard(
                              _current.symbol,
                              compact: compact,
                              highlighted: _running,
                              caption: english ? 'CURRENT' : 'ŞİMDİ',
                            ),
                            if (_target != null) ...<Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                ),
                                child: Icon(
                                  Icons.compare_arrows_rounded,
                                  color: skin.accent,
                                  size: 22,
                                ),
                              ),
                              _symbolCard(
                                _target!.symbol,
                                compact: compact,
                                caption: _english
                                    ? '${_current.nBackDistance} BACK'
                                    : '${_current.nBackDistance} GERİ',
                              ),
                            ],
                          ],
                        ),
                        if (_running) ...<Widget>[
                          const SizedBox(height: 9),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 5,
                            runSpacing: 5,
                            children: <Widget>[
                              for (
                                int index = 0;
                                index < _scenario.length;
                                index++
                              )
                                Container(
                                  key: ValueKey<String>(
                                    'symbol_stream_progress_$index',
                                  ),
                                  width: 17,
                                  height: 17,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index < _currentIndex
                                        ? _responseResults[index] == true
                                              ? StudioVisuals.teal
                                              : _responseResults[index] == false
                                              ? StudioVisuals.danger
                                              : StudioVisuals.line
                                        : index == _currentIndex
                                        ? skin.accent
                                        : const Color(0xFFF0F2F5),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: index == _currentIndex
                                          ? Colors.white
                                          : StudioVisuals.muted,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_feedback != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _StreamFeedback(
                      text: _feedback!,
                      positive: _lastCorrect ?? _solved,
                    ),
                  ],
                  const SizedBox(height: 9),
                  if (_solved)
                    FilledButton.icon(
                      key: const ValueKey<String>('symbol_stream_finish'),
                      onPressed: _finish,
                      icon: const Icon(Icons.celebration_rounded),
                      label: Text(
                        english ? 'COMPLETE STREAM' : 'AKIŞI TAMAMLA',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (!_running)
                    FilledButton.icon(
                      key: const ValueKey<String>('symbol_stream_start'),
                      onPressed: _startStream,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(english ? 'START STREAM' : 'AKIŞI BAŞLAT'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (_awaitingResponse)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey<String>('symbol_stream_hint'),
                            onPressed: _useHint,
                            icon: const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                            ),
                            label: Text(english ? 'HINT −45' : 'İPUCU −45'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 47),
                              foregroundColor: StudioVisuals.ink,
                              side: const BorderSide(color: StudioVisuals.line),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey<String>('symbol_stream_match'),
                            onPressed: () => _answer(true),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(english ? 'MATCH' : 'EŞLEŞİYOR'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(44, 47),
                              backgroundColor: StudioVisuals.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey<String>(
                              'symbol_stream_no_match',
                            ),
                            onPressed: () => _answer(false),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(english ? 'NO' : 'HAYIR'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(44, 47),
                              backgroundColor: skin.accent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      key: const ValueKey<String>('symbol_stream_buffering'),
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: StudioVisuals.surface,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        english
                            ? 'BUILDING THE N-BACK WINDOW…'
                            : 'GERİYE BAKIŞ PENCERESİ OLUŞUYOR…',
                        style: const TextStyle(
                          color: StudioVisuals.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    english
                        ? 'A brief flash marks rule changes • sound is optional.'
                        : 'Kısa kehribar işaret kural değişimini gösterir • ses isteğe bağlıdır.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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
}

class _StreamMetric extends StatelessWidget {
  const _StreamMetric({
    required this.icon,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 48, minHeight: 29),
    padding: const EdgeInsets.symmetric(horizontal: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: StudioVisuals.ink,
          ),
        ),
      ],
    ),
  );
}

class _StreamTag extends StatelessWidget {
  const _StreamTag({
    required this.label,
    required this.tint,
    required this.surface,
  });
  final String label;
  final Color tint;
  final Color surface;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(color: tint, fontSize: 8, fontWeight: FontWeight.w900),
    ),
  );
}

class _StreamFeedback extends StatelessWidget {
  const _StreamFeedback({required this.text, required this.positive});
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final Color color = positive ? StudioVisuals.teal : StudioVisuals.danger;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: positive ? StudioVisuals.tealSoft : const Color(0xFFFFEEEE),
        borderRadius: StudioVisuals.compactRadius,
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            positive
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: StudioVisuals.ink,
                fontSize: 10.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
