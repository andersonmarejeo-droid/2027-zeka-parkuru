import '../shared/studio_game_contracts.dart';

import 'dart:async';
import 'dart:math' as math;

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
import 'spot_change_scenario.dart';

class SpotChangeGamePage extends StatefulWidget {
  const SpotChangeGamePage({
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
    GameContentPolicy.nativeStages('spot_change'),
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Sahne ${level.toString().padLeft(2, '0')}',
        titleEn: 'Scene ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Şekil ve renk farklarını dikkatle karşılaştır',
          <= 6 => 'Yön, desen ve küçük ayrıntıları izle',
          <= 10 => 'Aynı sahnede iki değişimi de seç',
          <= 16 => 'Nesnelerin yer değiştirmesini ve bağlarını gör',
          <= 19 => 'Yoğun panoda üç değişimi ayıkla',
          _ => 'Usta sahne • 12 konum • dört fark • tek hata hakkı',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Compare shape and colour changes carefully',
          <= 6 => 'Track orientation, pattern and fine detail',
          <= 10 => 'Select both changes in the same scene',
          <= 16 => 'Notice object swaps and shifting relations',
          <= 19 => 'Isolate three changes in a dense panel',
          _ => 'Master scene • 12 positions • four changes • one error',
        },
        difficulty: level <= 3
            ? 'GÖZLEM'
            : level <= 6
            ? 'AYRINTI'
            : level <= 10
            ? 'İLERİ'
            : level <= 16
            ? 'UZMAN'
            : 'USTA',
        icon: Icons.compare_rounded,
      );
    },
    growable: false,
  );

  @override
  State<SpotChangeGamePage> createState() => _SpotChangeGamePageState();
}

class _SpotChangeGamePageState extends State<SpotChangeGamePage> {
  static const String _practiceKey = 'spot_change_next_practice_round';
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
          .clamp(1, SpotChangeScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => SpotChangePlayPage(
              level: SpotChangeGamePage
                  .levels[(round - 1) % SpotChangeGamePage.totalLevels],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == SpotChangeScenario.uniquePracticeRounds
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
              ? 'Scene solved • unique comparison $next / 300'
              : 'Sahne çözüldü • farklı kıyaslama $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('spot_change');
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'spot_change',
      progressPrefix: 'spot_change',
      titleTr: 'Değişeni Bul',
      titleEn: 'Spot the Change',
      taglineTr: 'Önce/sonra sahnelerini karşılaştır • her değişimi işaretle',
      taglineEn: 'Compare before/after scenes • mark every changed position',
      accent: skin.accent,
      icon: Icons.compare_rounded,
      levels: SpotChangeGamePage.levels,
      emphasizeLevelCards: true,
      dailyCourseMode: widget.dailyCourseMode,
      competitionLevel: widget.competitionLevel,
      competitionLayoutCode: widget.competitionLayoutCode,
      hubAction: widget.competitionLevel != null
          ? null
          : OutlinedButton.icon(
              onPressed: _practiceLoading ? null : _openPractice,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _practiceLoading
                    ? (english ? 'Loading…' : 'Yükleniyor…')
                    : english
                    ? 'UNIQUE SCENE • $_nextPracticeRound / 300'
                    : 'FARKLI SAHNE • $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => SpotChangePlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          SpotChangeScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class SpotChangePlayPage extends StatefulWidget {
  const SpotChangePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<SpotChangePlayPage> createState() => _SpotChangePlayPageState();
}

class _SpotChangePlayPageState extends State<SpotChangePlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.memory,
  );
  late StudioGameSession _session;
  late SpotChangeScenario _scenario;
  bool _initialized = false;
  bool _failureOpen = false;
  bool _solved = false;
  bool _hintUsed = false;
  int? _hintIndex;
  String? _feedback;
  final Set<int> _selected = <int>{};

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
              ? SpotChangeScenario.forPracticeRound(
                  widget.level.contentIndex,
                  english: _english,
                )
              : SpotChangeScenario.forCampaignLevel(
                  widget.level.contentLevel,
                  english: _english,
                ))
        : SpotChangeScenario.forPracticeRound(round, english: _english);
  }

  void _tapPosition(int index) {
    if (_solved || !_session.acceptsInput || _selected.contains(index)) return;
    if (_scenario.changedIndices.contains(index)) {
      _selected.add(index);
      _session.recordAccepted(points: 60 + widget.level.number * 8);
      _audio.hapticSelection();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .24));
      final bool finished = _selected.length == _scenario.changeCount;
      setState(() {
        _feedback = finished
            ? (_english
                  ? 'Every change is accounted for.'
                  : 'Bütün değişimler bulundu.')
            : (_english
                  ? '${_scenario.changeCount - _selected.length} more change(s) to find.'
                  : '${_scenario.changeCount - _selected.length} değişim daha bul.');
        _hintIndex = null;
        _solved = finished;
      });
      return;
    }
    _session.recordMistake();
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
    setState(() {
      _feedback = _english
          ? 'This position is unchanged. $_errorsLeft error(s) left.'
          : 'Bu konum değişmemiş. $_errorsLeft hata hakkı kaldı.';
      _hintIndex = null;
    });
    if (_errorsLeft == 0 && !_failureOpen) unawaited(_showFailure());
  }

  void _showHint() {
    if (_solved || !_session.useHint(pointCost: 70)) return;
    final int? next = _scenario.changedIndices
        .where((int index) => !_selected.contains(index))
        .firstOrNull;
    if (next == null) return;
    setState(() {
      _hintUsed = true;
      _hintIndex = next;
      _feedback = _english
          ? 'The amber frame marks one changed position.'
          : 'Kehribar çerçeve değişen konumlardan birini gösteriyor.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .2));
  }

  Future<void> _showFailure() async {
    _failureOpen = true;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'Scene comparison paused' : 'Sahne karşılaştırması durdu',
        ),
        content: Text(
          _english
              ? 'The error budget is used. Compare the paired tiles once more and retry.'
              : 'Hata bütçen doldu. Eşli kutuları yeniden karşılaştırıp tekrar dene.',
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
    setState(() {
      _selected.clear();
      _hintIndex = null;
      _feedback = null;
      _solved = false;
      _hintUsed = false;
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
      action: !_practice && widget.level.number < SpotChangeGamePage.totalLevels
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

  Widget _tile(int index, bool compact) {
    final SpotChangeObject before = _scenario.before[index];
    final SpotChangeObject after = _scenario.after[index];
    final bool selected = _selected.contains(index);
    final bool hinted = _hintIndex == index;
    final Color beforeColor = _colors[before.colorIndex % _colors.length];
    final Color afterColor = _colors[after.colorIndex % _colors.length];
    final double beforeSize = switch (before.scaleIndex) {
      0 => 28,
      1 => 35,
      _ => 42,
    };
    final double afterSize = switch (after.scaleIndex) {
      0 => 28,
      1 => 35,
      _ => 42,
    };
    return Semantics(
      button: true,
      label: _english
          ? 'Position ${index + 1}, compare before and after'
          : '${index + 1}. konum, önce ve sonrayı karşılaştır',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          key: ValueKey<String>('spot_change_cell_$index'),
          onTap: _solved ? null : () => _tapPosition(index),
          borderRadius: BorderRadius.circular(13),
          child: Container(
            constraints: const BoxConstraints(minHeight: 110),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 2 : 6,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? const Color(0xFF648B72)
                    : hinted
                    ? const Color(0xFFD49A42)
                    : const Color(0xFFE1E7ED),
                width: selected || hinted ? 2 : 1,
              ),
              color: selected
                  ? const Color(0xFFE9F2EC)
                  : hinted
                  ? const Color(0xFFFBF3E4)
                  : const Color(0xFFFCFDFD),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _miniSymbol(before, beforeColor, beforeSize, compact),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: const Color(0xFFA2ADBA),
                      size: compact ? 11 : 14,
                    ),
                    _miniSymbol(after, afterColor, afterSize, compact),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: selected
                        ? const Color(0xFF54785F)
                        : const Color(0xFF7A8796),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniSymbol(
    SpotChangeObject object,
    Color color,
    double size,
    bool compact,
  ) {
    return SizedBox(
      width: 46,
      height: 59,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          Transform.rotate(
            angle: object.rotationStep * math.pi / 4,
            child: Container(
              width: math.min(48, size + 12),
              height: math.min(48, size + 12),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: color.withValues(alpha: .55), width: 1.2),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1E18252B),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: RealisticGameObject(
                sheet: RealisticObjectSheet.tokens,
                index: object.shapeIndex,
                borderRadius: 8,
                overlayColor: color.withValues(alpha: .10),
              ),
            ),
          ),
          Positioned(
            bottom: 1,
            left: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(
                object.patternIndex + 1,
                (int index) => Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(right: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .72),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          if (object.hasMarker)
            Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFFD49A42),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final double width = MediaQuery.sizeOf(context).width;
    final bool compact = width < 365;
    final StudioGameSkin skin = StudioGameSkin.forId('spot_change');
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'SPOT THE CHANGE' : 'DEĞİŞENİ BUL',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: .9,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                key: const ValueKey<String>('spot_change_errors_left'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E8D8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${english ? 'ERRORS' : 'HATA'}  $_errorsLeft',
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
              key: const ValueKey<String>('spot_change_scroll'),
              padding: EdgeInsets.fromLTRB(
                compact ? 13 : 22,
                compact ? 2 : 5,
                compact ? 13 : 22,
                compact ? 10 : 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _header(english, skin),
                  SizedBox(height: compact ? 8 : 14),
                  _instructionCard(english, skin),
                  SizedBox(height: compact ? 8 : 13),
                  _comparisonGrid(compact),
                  SizedBox(height: compact ? 7 : 12),
                  _statusLine(english),
                  SizedBox(height: compact ? 6 : 11),
                  if (_solved)
                    _finishCard(english)
                  else
                    OutlinedButton.icon(
                      key: const ValueKey<String>('spot_change_hint'),
                      onPressed: _showHint,
                      icon: const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        english
                            ? 'REVEAL ONE DIFFERENCE'
                            : 'BİR FARK İÇİN İPUCU',
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

  Widget _header(bool english, StudioGameSkin skin) {
    final double progress = _selected.length / _scenario.changeCount;
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
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              _scenario.stageTheme,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: skin.accent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE1E7ED),
            color: skin.accent,
          ),
        ),
      ],
    );
  }

  Widget _instructionCard(bool english, StudioGameSkin skin) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: MediaQuery.sizeOf(context).width < 365 ? 9 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: skin.accent.withValues(alpha: .20)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: skin.accent.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.compare_arrows_rounded,
              color: skin.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  english ? 'BEFORE  →  AFTER' : 'ÖNCE  →  SONRA',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: skin.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _scenario.instruction,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: 14,
                    height: 1.35,
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

  Widget _comparisonGrid(bool compact) {
    return Container(
      padding: EdgeInsets.all(compact ? 7 : 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFDFDFB), Color(0xFFF1F4F7)],
        ),
        border: Border.all(color: const Color(0xFFE1E7ED)),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: GridView.builder(
        key: const ValueKey<String>('spot_change_grid'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _scenario.cellCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width < 600
              ? 2
              : _scenario.columns,
          crossAxisSpacing: compact ? 5 : 8,
          mainAxisSpacing: compact ? 5 : 8,
          mainAxisExtent: 122,
        ),
        itemBuilder: (BuildContext context, int index) => _tile(index, compact),
      ),
    );
  }

  Widget _statusLine(bool english) {
    final bool hasFeedback = _feedback != null;
    final Color color = hasFeedback && _session.mistakes > 0
        ? const Color(0xFF648B72)
        : const Color(0xFF64748B);
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            _solved ? Icons.check_circle_rounded : Icons.visibility_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _feedback ??
                  (english
                      ? 'Select the changed positions in any order.'
                      : 'Değişen konumları istediğin sırayla seç.'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: color,
                fontSize: 12,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2EC),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: <Widget>[
          Text(
            english ? 'SCENE RESTORED' : 'SAHNE ÇÖZÜLDÜ',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF54785F),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey<String>('spot_change_finish'),
              onPressed: _finish,
              icon: const Icon(Icons.emoji_events_rounded),
              label: Text(english ? 'SAVE RESULT' : 'SONUCU KAYDET'),
            ),
          ),
        ],
      ),
    );
  }
}
