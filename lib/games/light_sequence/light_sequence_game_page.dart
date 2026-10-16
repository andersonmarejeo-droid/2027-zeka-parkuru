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
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'light_sequence_scenario.dart';

class LightSequenceGamePage extends StatefulWidget {
  const LightSequenceGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalLevels = LightSequenceScenario.campaignLevels;
  static const int totalStars = totalLevels * 3;

  static final List<ParkurLevelSpec> levels = List<ParkurLevelSpec>.generate(
    totalLevels,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Sinyal ${level.toString().padLeft(2, '0')}',
        titleEn: 'Signal ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Kısa ışık yolunu konumlarıyla hatırla',
          <= 6 => 'Daha uzun dizide yön ve aralığı koru',
          <= 10 => 'Kırmızı yanıltıcı ışıkları göz ardı et',
          <= 16 => 'Işık yolunu sondan başa yeniden kur',
          <= 19 => 'Uzun diziyi ters hatırla, sahte flaşları ele',
          _ => 'Usta finali • 11 sinyal, 4 sahte flaş, tek hata hakkı',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Remember a short light path by position',
          <= 6 => 'Keep direction and spacing in a longer sequence',
          <= 10 => 'Ignore the red decoy flashes',
          <= 16 => 'Rebuild the light path from end to start',
          <= 19 => 'Recall a long sequence backwards and reject decoys',
          _ => 'Master finale • 11 signals, 4 false flashes, one mistake',
        },
        difficulty: level <= 3
            ? 'ISINMA'
            : level <= 6
            ? 'ODAK'
            : level <= 10
            ? 'İLERİ'
            : level <= 16
            ? 'UZMAN'
            : 'USTA',
        icon: Icons.light_mode_rounded,
      );
    },
    growable: false,
  );

  @override
  State<LightSequenceGamePage> createState() => _LightSequenceGamePageState();
}

class _LightSequenceGamePageState extends State<LightSequenceGamePage> {
  static const String _practiceKey = 'light_sequence_next_practice_round';
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
      _nextPracticeRound = stored.clamp(1, 300).toInt();
      _practiceLoading = false;
    });
  }

  Future<void> _openPractice() async {
    final bool english = context.l10n.isEnglish;
    final int round = _nextPracticeRound;
    final ParkurGameResult? result = await Navigator.of(context)
        .push<ParkurGameResult>(
          MaterialPageRoute<ParkurGameResult>(
            builder: (BuildContext context) => LightSequencePlayPage(
              level: LightSequenceGamePage
                  .levels[(round - 1) % LightSequenceGamePage.totalLevels],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == LightSequenceScenario.uniquePracticeRounds
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
              ? 'Signal mastered • next unique pattern: $next / 300'
              : 'Dizi tamamlandı • sıradaki farklı örüntü: $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.memory);
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'light_sequence',
      progressPrefix: 'light_sequence',
      titleTr: 'Işık Dizisi',
      titleEn: 'Light Sequence',
      taglineTr: 'Sinyali izle • dikkat dağıtıcıyı filtrele • rotayı hatırla',
      taglineEn: 'Watch the signal • filter distractions • recall the route',
      accent: skin.accent,
      icon: Icons.light_mode_rounded,
      levels: LightSequenceGamePage.levels,
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
                    ? 'UNIQUE PATTERNS • $_nextPracticeRound / 300'
                    : 'FARKLI DİZİ • $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => LightSequencePlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          LightSequenceScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class LightSequencePlayPage extends StatefulWidget {
  const LightSequencePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<LightSequencePlayPage> createState() => _LightSequencePlayPageState();
}

class _LightSequencePlayPageState extends State<LightSequencePlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.memory,
  );
  late StudioGameSession _session;
  late LightSequenceScenario _scenario;
  bool _initialized = false;
  bool _failureDialogOpen = false;
  bool _previewing = false;
  bool _hasPreview = false;
  bool _solved = false;
  bool _hintUsed = false;
  int? _activeCell;
  bool _activeIsDecoy = false;
  int? _hintedCell;
  int _generation = 0;
  final List<int> _input = <int>[];
  String? _feedback;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  int get _errorsLeft =>
      math.max(0, _scenario.mistakeLimit - _session.mistakes).toInt();
  bool get _canRecall =>
      _hasPreview && !_previewing && !_solved && _session.acceptsInput;

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
        ? LightSequenceScenario.forCampaignLevel(widget.level.number)
        : LightSequenceScenario.forPracticeRound(round);
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  Future<void> _playPreview({bool costReplay = false}) async {
    if (_previewing || _solved || !_session.acceptsInput) return;
    if (costReplay) {
      if (_input.isNotEmpty || !_session.useHint(pointCost: 80)) return;
      _hintUsed = true;
      _input.clear();
    }
    final int generation = ++_generation;
    setState(() {
      _previewing = true;
      _activeCell = null;
      _activeIsDecoy = false;
      _hintedCell = null;
      _feedback = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final LightSequenceFlash flash in _scenario.flashes) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _activeCell = flash.cell;
        _activeIsDecoy = flash.isDecoy;
      });
      unawaited(
        _audioProfile.play(
          _audio,
          flash.isDecoy
              ? GameAudioEvent.rejected
              : GameAudioEvent.primaryAction,
          gain: flash.isDecoy ? .08 : .12,
        ),
      );
      await Future<void>.delayed(
        Duration(milliseconds: _scenario.flashIntervalMs),
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _activeCell = null;
        _activeIsDecoy = false;
      });
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
    if (!mounted || generation != _generation) return;
    setState(() {
      _previewing = false;
      _hasPreview = true;
      _feedback = _scenario.reverseRecall
          ? (_english
                ? 'Now tap the true signals in reverse order.'
                : 'Şimdi gerçek sinyallere tersten dokun.')
          : (_english
                ? 'Now repeat the true signals in the same order.'
                : 'Şimdi gerçek sinyalleri aynı sırayla yinele.');
    });
  }

  void _tapCell(int cell) {
    if (!_canRecall) return;
    final int expectedIndex = _input.length;
    final int expectedCell = _scenario.answer[expectedIndex];
    if (cell != expectedCell) {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .26));
      setState(() {
        _input.clear();
        _hintedCell = null;
        _feedback = _english
            ? 'Not that signal. Start the sequence again; $_errorsLeft ${_errorsLeft == 1 ? 'try' : 'tries'} left.'
            : 'Bu sinyal sırada değil. Diziyi baştan başlat; $_errorsLeft hak kaldı.';
      });
      if (_errorsLeft == 0 && !_failureDialogOpen) unawaited(_showFailure());
      return;
    }

    _input.add(cell);
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .22));
    if (_input.length == _scenario.answer.length) {
      _session.recordAccepted(points: 220 + widget.level.number * 22);
      _audio.hapticMedium();
      setState(() {
        _solved = true;
        _hintedCell = null;
        _feedback = null;
      });
      return;
    }
    setState(() {
      _hintedCell = null;
      _feedback = _english
          ? 'Signal ${_input.length} of ${_scenario.answer.length} locked in.'
          : '${_scenario.answer.length} sinyalden ${_input.length} tanesi doğru.';
    });
  }

  void _useHint() {
    if (!_canRecall ||
        _input.length >= _scenario.answer.length ||
        !_session.useHint(pointCost: 80)) {
      return;
    }
    setState(() {
      _hintUsed = true;
      _hintedCell = _scenario.answer[_input.length];
      _feedback = _english
          ? 'A soft outline marks the next true location. Decoy flashes never belong to the answer.'
          : 'Soluk çerçeve sıradaki gerçek konumu gösterir. Sahte flaşlar yanıta girmez.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .25));
  }

  Future<void> _showFailure() async {
    _failureDialogOpen = true;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'Signal lost' : 'Sinyal koptu'),
        content: Text(
          _english
              ? 'The mistake budget is used. Watch the path again, then recall only the true flashes.'
              : 'Hata hakkın doldu. Işık yolunu yeniden izle ve yalnızca gerçek flaşları hatırla.',
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
    _failureDialogOpen = false;
  }

  void _reset() {
    _generation++;
    setState(() {
      _input.clear();
      _activeCell = null;
      _activeIsDecoy = false;
      _hintedCell = null;
      _feedback = null;
      _previewing = false;
      _hasPreview = false;
      _solved = false;
      _hintUsed = false;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _submitCompleted() {
    if (!_solved || !_session.acceptsInput) return;
    final int stars = !_hintUsed && _session.mistakes == 0
        ? 3
        : _session.mistakes <= 1
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action:
          !_practice && widget.level.number < LightSequenceGamePage.totalLevels
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

  Widget _tile(int cell, StudioGameSkin skin) {
    final bool active = cell == _activeCell;
    final bool decoy = active && _activeIsDecoy;
    final int answerIndex = _input.indexOf(cell);
    final bool tapped = answerIndex >= 0;
    final bool hinted = cell == _hintedCell;
    final Color glow = decoy ? StudioVisuals.danger : StudioVisuals.amber;
    final Color background = active
        ? glow
        : tapped
        ? StudioVisuals.teal
        : StudioVisuals.surface;
    return Semantics(
      label: _english ? 'Light tile ${cell + 1}' : 'Işık karesi ${cell + 1}',
      button: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          key: ValueKey<String>('light_sequence_cell_$cell'),
          onTap: () => _tapCell(cell),
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: active || tapped
                    ? background
                    : hinted
                    ? StudioVisuals.amber
                    : StudioVisuals.line,
                width: hinted ? 2.2 : 1,
              ),
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: glow.withValues(alpha: .48),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : StudioVisuals.softShadow,
            ),
            child: active
                ? Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: RealisticGameObject(
                          sheet: RealisticObjectSheet.tokens,
                          index: cell,
                          borderRadius: 14,
                          overlayColor: glow.withValues(alpha: .30),
                        ),
                      ),
                      Icon(
                        decoy ? Icons.close_rounded : Icons.bolt_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  )
                : tapped
                ? Text(
                    '${answerIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : SizedBox(
                    width: 34,
                    height: 34,
                    child: RealisticGameObject(
                      sheet: RealisticObjectSheet.tokens,
                      index: cell,
                      borderRadius: 10,
                      overlayColor: Colors.white.withValues(alpha: .12),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.memory);
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'Light Sequence' : 'Işık Dizisi',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            Text(
              _practice
                  ? (_english
                        ? 'PRACTICE • ${widget.practiceRound} / 300'
                        : 'PRATİK • ${widget.practiceRound} / 300')
                  : (_english
                        ? 'SIGNAL • ${widget.level.number} / 20'
                        : 'SİNYAL • ${widget.level.number} / 20'),
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 10,
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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _english ? 'SIGNAL RECALL' : 'SİNYAL HAFIZASI',
                        style: TextStyle(
                          color: skin.accent,
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _LightStat(
                      icon: Icons.favorite_outline_rounded,
                      value: '$_errorsLeft/${_scenario.mistakeLimit}',
                      accent: _errorsLeft <= 1
                          ? StudioVisuals.danger
                          : skin.accent,
                    ),
                    const SizedBox(width: 6),
                    _LightStat(
                      icon: Icons.stars_rounded,
                      value: '${_session.score}',
                      accent: StudioVisuals.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey<String>('light_sequence_scroll'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: StudioVisuals.surface,
                            borderRadius: StudioVisuals.compactRadius,
                            border: Border.all(color: StudioVisuals.line),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: skin.accentSoft,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  Icons.visibility_rounded,
                                  color: skin.accent,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  _previewing
                                      ? (_activeIsDecoy
                                            ? (_english
                                                  ? 'IGNORE THIS RED FLASH'
                                                  : 'KIRMIZI FLAŞI YOK SAY')
                                            : _english
                                            ? 'WATCH THE LIGHT PATH'
                                            : 'IŞIK YOLUNU İZLE')
                                      : _solved
                                      ? (_english
                                            ? 'PATTERN SECURED'
                                            : 'ÖRÜNTÜ KAYDEDİLDİ')
                                      : _input.isNotEmpty
                                      ? (_english
                                            ? 'SIGNALS LOCKED • ${_input.length}/${_scenario.answer.length}'
                                            : 'DOĞRU SİNYAL • ${_input.length}/${_scenario.answer.length}')
                                      : _english
                                      ? 'MEMORIZE THE SPATIAL ORDER'
                                      : 'KONUM SIRASINI AKLINDA TUT',
                                  style: const TextStyle(
                                    color: StudioVisuals.ink,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (_scenario.reverseRecall)
                                _MemoryTag(
                                  label: _english ? 'REVERSE' : 'TERS',
                                  color: skin.accent,
                                  soft: skin.accentSoft,
                                ),
                              if (_scenario.decoyCount > 0)
                                _MemoryTag(
                                  label: '×${_scenario.decoyCount}',
                                  color: StudioVisuals.danger,
                                  soft: const Color(0xFFFFEEEE),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        AspectRatio(
                          aspectRatio: 1,
                          child: GridView.builder(
                            key: const ValueKey<String>('light_sequence_grid'),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _scenario.boardLength,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _scenario.gridSize,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                ),
                            itemBuilder: (BuildContext context, int cell) =>
                                _tile(cell, skin),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _scenario.reverseRecall
                                    ? (_english
                                          ? 'Remember the true lights backwards.'
                                          : 'Gerçek ışıkları tersten hatırla.')
                                    : (_english
                                          ? 'Recall each position in the order shown.'
                                          : 'Her konumu gösterildiği sırayla hatırla.'),
                                style: const TextStyle(
                                  color: StudioVisuals.muted,
                                  fontSize: 10.5,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${_input.length}/${_scenario.answer.length}',
                              style: TextStyle(
                                color: skin.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        if (_feedback != null) ...<Widget>[
                          const SizedBox(height: 8),
                          _MemoryFeedback(text: _feedback!, positive: _solved),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (_solved)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey<String>('light_sequence_finish'),
                      onPressed: _submitCompleted,
                      icon: const Icon(Icons.celebration_rounded),
                      label: Text(
                        _english ? 'COMPLETE SIGNAL' : 'SİNYALİ TAMAMLA',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else if (_previewing)
                  const SizedBox(height: 49)
                else if (!_hasPreview)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey<String>('light_sequence_start'),
                          onPressed: () => unawaited(_playPreview()),
                          icon: Icon(
                            _feedback == null
                                ? Icons.play_arrow_rounded
                                : Icons.replay_rounded,
                          ),
                          label: Text(
                            _english ? 'SHOW SEQUENCE' : 'DİZİYİ GÖSTER',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 50),
                            backgroundColor: skin.accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey<String>('light_sequence_hint'),
                          onPressed: _canRecall ? _useHint : null,
                          icon: const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _english ? 'HINT −80' : 'İPUCU −80',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: StudioVisuals.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            side: const BorderSide(color: StudioVisuals.line),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey<String>('light_sequence_replay'),
                          onPressed: _input.isEmpty && _canRecall
                              ? () => unawaited(_playPreview(costReplay: true))
                              : null,
                          icon: const Icon(Icons.replay_rounded, size: 18),
                          label: Text(
                            _english ? 'REPLAY −80' : 'TEKRAR −80',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: StudioVisuals.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            side: const BorderSide(color: StudioVisuals.line),
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

class _LightStat extends StatelessWidget {
  const _LightStat({
    required this.icon,
    required this.value,
    required this.accent,
  });
  final IconData icon;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 61, minHeight: 30),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 15, color: accent),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _MemoryTag extends StatelessWidget {
  const _MemoryTag({
    required this.label,
    required this.color,
    required this.soft,
  });
  final String label;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _MemoryFeedback extends StatelessWidget {
  const _MemoryFeedback({required this.text, required this.positive});
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final Color accent = positive ? StudioVisuals.teal : StudioVisuals.danger;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: positive ? StudioVisuals.tealSoft : const Color(0xFFFFEEEE),
        borderRadius: StudioVisuals.compactRadius,
        border: Border.all(color: accent.withValues(alpha: .2)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            positive
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: accent,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: StudioVisuals.ink,
                fontSize: 11,
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
