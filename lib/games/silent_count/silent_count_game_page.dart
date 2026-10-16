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
import 'silent_count_scenario.dart';

class SilentCountGamePage extends StatefulWidget {
  const SilentCountGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalLevels = SilentCountScenario.campaignLevels;
  static const int totalStars = totalLevels * 3;
  static final List<ParkurLevelSpec> levels = List<ParkurLevelSpec>.generate(
    totalLevels,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Sayım ${level.toString().padLeft(2, '0')}',
        titleEn: 'Count ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'İki bölmedeki giriş ve çıkışları izle',
          <= 6 => 'Üç türün envanterini aklında tut',
          <= 10 => 'Kapı ters döndüğünde artı ve eksi yer değiştirir',
          <= 16 => 'Dört bölme, uzun akış ve iki kural değişimi',
          <= 19 => 'Beş tür ve hataya daralan sayaç',
          _ => '20 olay • beş tür • üç kural kayması • tek hata',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Track entries and exits in two bays',
          <= 6 => 'Hold the inventory of three types in mind',
          <= 10 => 'When the gate reverses, plus and minus swap',
          <= 16 => 'Four bays, a longer stream and two rule changes',
          <= 19 => 'Five types with a tighter error budget',
          _ => '20 events • five types • three rule shifts • one error',
        },
        difficulty: level <= 3
            ? 'İZLE'
            : level <= 6
            ? 'SAY'
            : level <= 10
            ? 'DEĞİŞİM'
            : level <= 16
            ? 'UZMAN'
            : 'USTA',
        icon: Icons.inventory_2_rounded,
      );
    },
    growable: false,
  );

  @override
  State<SilentCountGamePage> createState() => _SilentCountGamePageState();
}

class _SilentCountGamePageState extends State<SilentCountGamePage> {
  static const String _practiceKey = 'silent_count_next_practice_round';
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
          .clamp(1, SilentCountScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => SilentCountPlayPage(
              level: SilentCountGamePage
                  .levels[(round - 1) % SilentCountGamePage.totalLevels],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == SilentCountScenario.uniquePracticeRounds
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
              ? 'Inventory audited • unique scenario $next / 300'
              : 'Envanter denetlendi • farklı senaryo $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.memory);
    return ParkurLevelHub(
      gameId: 'silent_count',
      progressPrefix: 'silent_count',
      titleTr: 'Sessiz Sayım',
      titleEn: 'Silent Count',
      taglineTr: 'Akışı izle • gizli envanteri takip et • son sayımı yap',
      taglineEn: 'Track the stream • hold the hidden inventory • audit counts',
      accent: skin.accent,
      icon: Icons.inventory_2_rounded,
      levels: SilentCountGamePage.levels,
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
                    ? 'UNIQUE AUDITS • $_nextPracticeRound / 300'
                    : 'FARKLI SAYIM • $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => SilentCountPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          SilentCountScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class SilentCountPlayPage extends StatefulWidget {
  const SilentCountPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<SilentCountPlayPage> createState() => _SilentCountPlayPageState();
}

class _SilentCountPlayPageState extends State<SilentCountPlayPage>
    with WidgetsBindingObserver {
  static const List<Color> _categoryColors = <Color>[
    Color(0xFF4C83AE),
    Color(0xFF6B987F),
    Color(0xFFC47C62),
    Color(0xFF9279B7),
    Color(0xFFB08B4F),
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.memory,
  );
  late StudioGameSession _session;
  late SilentCountScenario _scenario;
  bool _initialized = false;
  bool _running = false;
  bool _audit = false;
  bool _solved = false;
  bool _hintUsed = false;
  bool? _lastCorrect;
  int _eventIndex = 0;
  int _queryIndex = 0;
  int _correctAnswers = 0;
  final Map<int, int> _answers = <int, int>{};
  String? _feedback;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  int get _errorsLeft =>
      (_scenario.mistakeLimit - _session.mistakes).clamp(0, 5);
  int get _currentCategory => _scenario.queryOrder[_queryIndex];
  SilentCountEvent get _currentEvent => _scenario.events[_eventIndex];
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
        ? SilentCountScenario.forCampaignLevel(widget.level.number)
        : SilentCountScenario.forPracticeRound(widget.practiceRound!);
  }

  @override
  void dispose() {
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
    setState(() {
      _running = false;
      _audit = false;
      _eventIndex = 0;
      _queryIndex = 0;
      _correctAnswers = 0;
      _answers.clear();
      _lastCorrect = null;
      _feedback = _english
          ? 'Count paused safely. Restart to begin a fresh audit.'
          : 'Sayım güvenle durdu. Yeni bir denetim için yeniden başlat.';
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _startStream() {
    if (_running || _solved) return;
    setState(() {
      _running = true;
      _audit = false;
      _eventIndex = 0;
      _queryIndex = 0;
      _correctAnswers = 0;
      _answers.clear();
      _lastCorrect = null;
      _feedback = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .14),
    );
  }

  void _advanceStream() {
    if (!_running || _audit || !_session.acceptsInput) return;
    if (_eventIndex + 1 >= _scenario.eventCount) {
      setState(() {
        _audit = true;
        _queryIndex = 0;
        _feedback = _english
            ? 'Stream closed • audit each compartment from memory.'
            : 'Akış kapandı • bölmeleri belleğinden tek tek denetle.';
        _lastCorrect = null;
      });
      _audio.hapticLight();
      return;
    }
    setState(() {
      _eventIndex++;
      _feedback = _scenario.ruleChangeBeforeEvent.contains(_eventIndex)
          ? (_english
                ? 'GATE REVERSED • entry and exit effects have swapped.'
                : 'KAPI TERS DÖNDÜ • giriş ve çıkışın etkisi değişti.')
          : null;
      _lastCorrect = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(
        _audio,
        _scenario.ruleChangeBeforeEvent.contains(_eventIndex)
            ? GameAudioEvent.timeWarning
            : GameAudioEvent.primaryAction,
        gain: .16,
      ),
    );
  }

  void _answerCount(int value) {
    if (!_running || !_audit || !_session.acceptsInput || _solved) return;
    final int category = _currentCategory;
    final bool correct = value == _scenario.finalCounts[category];
    if (correct) {
      _correctAnswers++;
      _session.recordAccepted(points: 120 + widget.level.number * 12);
      _audio.hapticSelection();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
    } else {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
    }
    setState(() {
      _answers[category] = value;
      _lastCorrect = correct;
      _feedback = correct
          ? (_english ? 'Count confirmed.' : 'Sayı doğrulandı.')
          : (_english
                ? 'Not quite • $_errorsLeft error(s) left.'
                : 'Tam değil • $_errorsLeft hata hakkı kaldı.');
    });
    if (_errorsLeft <= 0 && !correct) {
      unawaited(_showFailure());
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted || !_running || !_audit) return;
      if (_queryIndex + 1 >= _scenario.queryOrder.length) {
        _completeAudit();
      } else {
        setState(() {
          _queryIndex++;
          _lastCorrect = null;
          _feedback = null;
        });
      }
    });
  }

  void _useHint() {
    if (!_audit || !_running || !_session.useHint(pointCost: 50)) return;
    _hintUsed = true;
    final int category = _currentCategory;
    final int change = _scenario.netChangeFor(category);
    setState(() {
      _feedback = _english
          ? 'Hint • this compartment changed by ${change >= 0 ? '+' : ''}$change.'
          : 'İpucu • bu bölmenin toplamı ${change >= 0 ? '+' : ''}$change değişti.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .2));
  }

  void _completeAudit() {
    if (_solved) return;
    _session.recordAccepted(points: 180 + _scenario.eventCount * 9);
    setState(() {
      _solved = true;
      _running = false;
      _audit = false;
      _feedback = _english
          ? 'Inventory sealed • $_correctAnswers / ${_scenario.categoryCount} counts exact.'
          : 'Envanter mühürlendi • ${_scenario.categoryCount} sayımdan $_correctAnswers doğru.';
      _lastCorrect = _correctAnswers == _scenario.categoryCount;
    });
  }

  Future<void> _showFailure() async {
    _running = false;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'Inventory lost' : 'Envanter karıştı'),
        content: Text(
          _english
              ? 'The error budget is used. Reset the stream and recount.'
              : 'Hata hakkın doldu. Akışı sıfırla ve yeniden say.',
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
    setState(() {
      _running = false;
      _audit = false;
      _solved = false;
      _hintUsed = false;
      _eventIndex = 0;
      _queryIndex = 0;
      _correctAnswers = 0;
      _answers.clear();
      _lastCorrect = null;
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
          !_practice && widget.level.number < SilentCountGamePage.totalLevels
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

  Widget _categoryMark(int index, {bool compact = false}) {
    return Container(
      width: compact ? 32 : 40,
      height: compact ? 32 : 40,
      decoration: BoxDecoration(
        color: _categoryColors[index].withValues(alpha: .12),
        borderRadius: BorderRadius.circular(compact ? 11 : 14),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: RealisticGameObject(
          sheet: RealisticObjectSheet.memory,
          index: index,
          borderRadius: compact ? 8 : 11,
          overlayColor: _categoryColors[index].withValues(alpha: .12),
        ),
      ),
    );
  }

  Widget _inventoryTile(int index, int count, {required bool compact}) {
    return Container(
      key: ValueKey<String>('silent_count_inventory_$index'),
      width: compact ? 89 : 104,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StudioVisuals.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _categoryMark(index, compact: true),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: _categoryColors[index],
              fontSize: compact ? 19 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialInventory({required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.inventory_2_outlined,
                color: StudioVisuals.ink,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _english ? 'INITIAL INVENTORY' : 'BAŞLANGIÇ ENVANTERİ',
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
              if (!_running)
                Text(
                  _english ? 'KEEP IN VIEW' : 'GÖZÜNÜN ÖNÜNDE',
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (int i = 0; i < _scenario.categoryCount; i++)
                _inventoryTile(i, _scenario.initialCounts[i], compact: compact),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryName(int index) {
    const List<String> turkish = <String>[
      'Pusula',
      'Anahtar',
      'Mercek',
      'Yaprak',
      'Portakal',
    ];
    const List<String> english = <String>[
      'Compass',
      'Key',
      'Lens',
      'Leaf',
      'Orange',
    ];
    return (_english ? english : turkish)[index];
  }

  Widget _eventCard({required bool compact}) {
    final SilentCountEvent event = _currentEvent;
    final bool changed = _scenario.ruleChangeBeforeEvent.contains(_eventIndex);
    return Container(
      key: const ValueKey<String>('silent_count_event_card'),
      padding: EdgeInsets.all(compact ? 12 : 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: changed
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
                  '${_english ? 'EVENT' : 'OLAY'}  ${(_eventIndex + 1).toString().padLeft(2, '0')} / ${_scenario.eventCount}',
                  style: TextStyle(
                    color: StudioVisuals.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .75,
                  ),
                ),
              ),
              _SilentCountTag(
                label: event.reversed
                    ? (_english ? 'REVERSED GATE' : 'TERS KAPI')
                    : (_english ? 'NORMAL GATE' : 'NORMAL KAPI'),
                tint: event.reversed ? StudioVisuals.amber : StudioVisuals.teal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _categoryMark(event.category, compact: false),
              const SizedBox(width: 11),
              Flexible(
                child: Text(
                  _categoryName(event.category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _categoryColors[event.category],
                    fontSize: compact ? 14 : 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Icon(
                event.enters ? Icons.south_rounded : Icons.north_rounded,
                color: StudioVisuals.ink,
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: BoxDecoration(
              color: event.reversed
                  ? const Color(0xFFFFF6E7)
                  : const Color(0xFFF2F7F7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              event.reversed
                  ? (_english
                        ? 'Entry arrow removes one • exit arrow adds one.'
                        : 'Giriş oku bir azaltır • çıkış oku bir artırır.')
                  : (_english
                        ? 'Entry arrow adds one • exit arrow removes one.'
                        : 'Giriş oku bir artırır • çıkış oku bir azaltır.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditCard({required bool compact}) {
    final int category = _currentCategory;
    final int? previousAnswer = _answers[category];
    return Container(
      key: const ValueKey<String>('silent_count_audit_card'),
      padding: EdgeInsets.all(compact ? 12 : 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        children: <Widget>[
          Text(
            '${_english ? 'FINAL AUDIT' : 'SON DENETİM'}  ${_queryIndex + 1} / ${_scenario.categoryCount}',
            style: const TextStyle(
              color: StudioVisuals.teal,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _categoryMark(category),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  _categoryName(category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _categoryColors[category],
                    fontSize: compact ? 16 : 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _english ? 'How many remain?' : 'Kaç tane kaldı?',
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (previousAnswer != null) ...<Widget>[
            const SizedBox(height: 5),
            Text(
              '${_english ? 'Recorded' : 'Kaydedildi'}: $previousAnswer',
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              for (
                int count = 0;
                count <= SilentCountScenario.maxCount;
                count++
              )
                SizedBox(
                  width: compact ? 43 : 48,
                  height: compact ? 40 : 46,
                  child: OutlinedButton(
                    key: ValueKey<String>('silent_count_answer_$count'),
                    onPressed: _session.acceptsInput
                        ? () => _answerCount(count)
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: StudioVisuals.ink,
                      side: BorderSide(
                        color: previousAnswer == count
                            ? _categoryColors[category]
                            : StudioVisuals.line,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
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

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final bool compact = MediaQuery.sizeOf(context).width < 365;
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.memory);
    final int progress = _audit ? _scenario.eventCount : _eventIndex + 1;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'SILENT COUNT' : 'SESSİZ SAYIM',
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
              child: _SilentCountMetric(
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
              key: const ValueKey<String>('silent_count_scroll'),
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
                          _audit
                              ? (english ? 'MEMORY AUDIT' : 'BELLEK DENETİMİ')
                              : (english ? 'VISUAL TRACKING' : 'GÖRSEL TAKİP'),
                          style: TextStyle(
                            color: skin.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      _SilentCountMetric(
                        icon: Icons.swap_vert_rounded,
                        value: '$progress/${_scenario.eventCount}',
                        color: StudioVisuals.ink,
                      ),
                      const SizedBox(width: 6),
                      _SilentCountMetric(
                        icon: Icons.stars_rounded,
                        value: '${_session.score}',
                        color: StudioVisuals.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  _initialInventory(compact: compact),
                  const SizedBox(height: 9),
                  if (_running && !_audit) _eventCard(compact: compact),
                  if (_running && _audit) _auditCard(compact: compact),
                  if (!_running)
                    Container(
                      padding: EdgeInsets.all(compact ? 13 : 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: StudioVisuals.line),
                        boxShadow: StudioVisuals.softShadow,
                      ),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.visibility_off_rounded,
                            color: skin.accent,
                            size: compact ? 29 : 36,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            english
                                ? 'Track each arrow without updating the visible inventory.'
                                : 'Görünen envanteri değiştirmeden her okun etkisini aklında tut.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: StudioVisuals.ink,
                              fontSize: 12,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            english
                                ? 'A reversed gate swaps entry and exit. The event history disappears at audit.'
                                : 'Ters kapı giriş ve çıkışı değiştirir. Denetimde olay geçmişi kapanır.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: StudioVisuals.muted,
                              fontSize: 10,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_feedback != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _SilentCountFeedback(
                      text: _feedback!,
                      positive: _lastCorrect ?? false,
                    ),
                  ],
                  const SizedBox(height: 9),
                  if (_solved)
                    FilledButton.icon(
                      key: const ValueKey<String>('silent_count_finish'),
                      onPressed: _finish,
                      icon: const Icon(Icons.celebration_rounded),
                      label: Text(
                        english ? 'SEAL INVENTORY' : 'ENVANTERİ MÜHÜRLE',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (!_running)
                    FilledButton.icon(
                      key: const ValueKey<String>('silent_count_start'),
                      onPressed: _startStream,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(english ? 'OPEN THE GATE' : 'AKIŞI BAŞLAT'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (_audit)
                    FilledButton.tonalIcon(
                      key: const ValueKey<String>('silent_count_hint'),
                      onPressed: _session.acceptsInput ? _useHint : null,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: Text(english ? 'HINT • 50' : 'İPUCU • 50'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 44),
                        foregroundColor: StudioVisuals.ink,
                      ),
                    )
                  else
                    FilledButton.icon(
                      key: const ValueKey<String>('silent_count_next'),
                      onPressed: _advanceStream,
                      icon: Icon(
                        _eventIndex + 1 >= _scenario.eventCount
                            ? Icons.lock_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _eventIndex + 1 >= _scenario.eventCount
                            ? (english
                                  ? 'CLOSE STREAM • AUDIT'
                                  : 'AKIŞI KAPAT • SAYIM')
                            : (english ? 'NEXT EVENT' : 'SONRAKİ OLAY'),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (_running && !_audit) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      english
                          ? 'The last arrow is not shown again.'
                          : 'Önceki ok yeniden gösterilmez.',
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

class _SilentCountMetric extends StatelessWidget {
  const _SilentCountMetric({
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

class _SilentCountTag extends StatelessWidget {
  const _SilentCountTag({required this.label, required this.tint});

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

class _SilentCountFeedback extends StatelessWidget {
  const _SilentCountFeedback({required this.text, required this.positive});

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
