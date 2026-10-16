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
import 'rhythm_memory_scenario.dart';

class RhythmMemoryGamePage extends StatefulWidget {
  const RhythmMemoryGamePage({
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
    GameContentPolicy.nativeStages('rhythm_memory'),
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Ritim ${level.toString().padLeft(2, '0')}',
        titleEn: 'Rhythm ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Kısa nota dizisini ve vuruş aralığını hatırla',
          <= 6 => 'Uzun-kısa araları ve vurgulu vuruşları ayır',
          <= 10 => 'Daha hızlı örüntüde sessizlikleri de koru',
          <= 16 => 'Diziyi tersten çal; vurguyu ve arayı unutma',
          <= 19 => 'Dokuz-on vuruş, üç aralık ve iki el dinamiği',
          _ => 'Usta finali • 11 nota • ters • uzun bek • vurgu',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Remember a short note phrase and its beat spacing',
          <= 6 => 'Separate long and short gaps from accented beats',
          <= 10 => 'Preserve rests inside a faster phrase',
          <= 16 => 'Replay the pattern backwards with its accents intact',
          <= 19 => 'Nine to ten beats, three intervals and two dynamics',
          _ => 'Master finale • 11 notes • reverse • long rests • accents',
        },
        difficulty: level <= 3
            ? 'TEMPO'
            : level <= 6
            ? 'VURUŞ'
            : level <= 10
            ? 'İLERİ'
            : level <= 16
            ? 'UZMAN'
            : 'USTA',
        icon: Icons.graphic_eq_rounded,
      );
    },
    growable: false,
  );

  @override
  State<RhythmMemoryGamePage> createState() => _RhythmMemoryGamePageState();
}

class _RhythmMemoryGamePageState extends State<RhythmMemoryGamePage> {
  static const String _practiceKey = 'rhythm_memory_next_practice_round';
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
          .clamp(1, RhythmMemoryScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => RhythmMemoryPlayPage(
              level: RhythmMemoryGamePage
                  .levels[(round - 1) % RhythmMemoryGamePage.totalLevels],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == RhythmMemoryScenario.uniquePracticeRounds
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
              ? 'Pattern remembered • unique rhythm $next / 300'
              : 'Ritim hatırlandı • farklı örüntü $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('rhythm_memory');
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'rhythm_memory',
      progressPrefix: 'rhythm_memory',
      titleTr: 'Ritim Hafızası',
      titleEn: 'Rhythm Memory',
      taglineTr: 'Notayı dinle • arayı ve vurguyu aklında tut',
      taglineEn: 'Listen to the notes • remember each gap and accent',
      accent: skin.accent,
      icon: Icons.graphic_eq_rounded,
      levels: RhythmMemoryGamePage.levels,
      dailyCourseMode: widget.dailyCourseMode,
      competitionLevel: widget.competitionLevel,
      competitionLayoutCode: widget.competitionLayoutCode,
      hubAction: widget.competitionLevel != null
          ? null
          : OutlinedButton.icon(
              onPressed: _practiceLoading ? null : _openPractice,
              icon: const Icon(Icons.queue_music_rounded),
              label: Text(
                _practiceLoading
                    ? (english ? 'Loading…' : 'Yükleniyor…')
                    : english
                    ? 'UNIQUE RHYTHMS • $_nextPracticeRound / 300'
                    : 'FARKLI RİTİM • $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => RhythmMemoryPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          RhythmMemoryScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class RhythmMemoryPlayPage extends StatefulWidget {
  const RhythmMemoryPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<RhythmMemoryPlayPage> createState() => _RhythmMemoryPlayPageState();
}

class _RhythmMemoryPlayPageState extends State<RhythmMemoryPlayPage>
    with WidgetsBindingObserver {
  static const List<String> _solfegeTr = <String>[
    'DO',
    'RE',
    'Mİ',
    'FA',
    'SOL',
    'LA',
    'Sİ',
    'DO+',
  ];
  static const List<String> _solfegeEn = <String>[
    'C',
    'D',
    'E',
    'F',
    'G',
    'A',
    'B',
    'C+',
  ];
  static const List<Color> _notes = <Color>[
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
  late RhythmMemoryScenario _scenario;
  bool _initialized = false;
  bool _playingBack = false;
  bool _heardPattern = false;
  bool _solved = false;
  bool _hintUsed = false;
  bool _failureOpen = false;
  int? _activeNote;
  int _activeBeatIndex = -1;
  String? _feedback;
  final List<int> _inputNotes = <int>[];
  final List<bool> _inputAccents = <bool>[];
  final List<int> _inputIntervals = <int>[];
  DateTime? _lastTapAt;
  int _generation = 0;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  int get _errorsLeft =>
      (_scenario.mistakeLimit - _session.mistakes).clamp(0, 5);

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
    final int? round = widget.practiceRound;
    _scenario = round == null
        ? (widget.level.poolIndex != null
              ? RhythmMemoryScenario.forPracticeRound(widget.level.contentIndex)
              : RhythmMemoryScenario.forCampaignLevel(
                  widget.level.contentLevel,
                ))
        : RhythmMemoryScenario.forPracticeRound(round);
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
    if (!mounted || !_playingBack) return;
    _generation++;
    setState(() {
      _playingBack = false;
      _heardPattern = false;
      _activeNote = null;
      _activeBeatIndex = -1;
      _inputNotes.clear();
      _inputAccents.clear();
      _inputIntervals.clear();
      _lastTapAt = null;
      _feedback = _english
          ? 'Playback paused safely. Listen again when you are ready.'
          : 'Oynatma güvenle durdu. Hazır olduğunda ritmi yeniden dinle.';
    });
  }

  Future<void> _playPattern({bool costReplay = false}) async {
    if (_playingBack || _solved || !_session.acceptsInput) return;
    if (costReplay && !_session.useHint(pointCost: 70)) return;
    final int generation = ++_generation;
    setState(() {
      _playingBack = true;
      _activeNote = null;
      _activeBeatIndex = -1;
      _feedback = null;
      if (costReplay) {
        _inputNotes.clear();
        _inputAccents.clear();
        _inputIntervals.clear();
        _lastTapAt = null;
      }
      if (costReplay) _hintUsed = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 220));
    for (int index = 0; index < _scenario.beats.length; index++) {
      if (!mounted || generation != _generation) return;
      final RhythmBeat beat = _scenario.beats[index];
      setState(() {
        _activeNote = beat.note;
        _activeBeatIndex = index;
      });
      unawaited(
        _audio.playMemoryNote(beat.note, gain: beat.accent ? .82 : .62),
      );
      if (beat.accent) {
        _audio.hapticMedium();
      } else {
        _audio.hapticSelection();
      }
      await Future<void>.delayed(const Duration(milliseconds: 125));
      if (!mounted || generation != _generation) return;
      setState(() {
        _activeNote = null;
        _activeBeatIndex = -1;
      });
      if (index < _scenario.gaps.length) {
        await Future<void>.delayed(
          Duration(
            milliseconds: _scenario.baseBeatMs * _scenario.gaps[index] - 125,
          ),
        );
      }
    }
    if (!mounted || generation != _generation) return;
    setState(() {
      _playingBack = false;
      _heardPattern = true;
      _feedback = _scenario.reverseRecall
          ? (_english
                ? 'Your turn: replay every note in reverse, keeping its rhythm.'
                : 'Sıra sende: notaları ritmi koruyarak tersten çal.')
          : (_english
                ? 'Your turn: copy the notes, spaces and accents.'
                : 'Sıra sende: notaları, araları ve vurguları taklit et.');
    });
  }

  void _tapNote(int note, {bool accent = false}) {
    if (_playingBack || !_heardPattern || _solved || !_session.acceptsInput) {
      return;
    }
    final DateTime now = DateTime.now();
    if (_lastTapAt != null) {
      _inputIntervals.add(
        math.max(1, now.difference(_lastTapAt!).inMilliseconds).toInt(),
      );
    }
    _lastTapAt = now;
    _inputNotes.add(note);
    _inputAccents.add(accent);
    final int activeBeatIndex = _inputNotes.length - 1;
    setState(() {
      _activeNote = note;
      _activeBeatIndex = activeBeatIndex;
      _feedback = _english
          ? 'Beat ${_inputNotes.length} / ${_scenario.length}'
          : '${_inputNotes.length} / ${_scenario.length}. vuruş';
    });
    _audio.hapticSelection();
    unawaited(_audio.playMemoryNote(note, gain: accent ? .82 : .62));
    Future<void>.delayed(const Duration(milliseconds: 110), () {
      if (mounted && _activeBeatIndex == activeBeatIndex) {
        setState(() {
          _activeNote = null;
          _activeBeatIndex = -1;
        });
      }
    });
    if (_inputNotes.length == _scenario.length) _evaluateRecall();
  }

  void _evaluateRecall() {
    final bool correct = _scenario.accepts(
      notes: _inputNotes,
      accents: _inputAccents,
      intervalsMs: _inputIntervals,
    );
    if (!correct) {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      setState(() {
        _inputNotes.clear();
        _inputAccents.clear();
        _inputIntervals.clear();
        _lastTapAt = null;
        _feedback = _english
            ? 'The notes, accents or spaces drifted. Listen once more and retry.'
            : 'Nota, vurgu ya da aralık kaydı. Bir kez daha dinleyip dene.';
      });
      if (_errorsLeft <= 0 && !_failureOpen) unawaited(_showFailure());
      return;
    }
    _session.recordAccepted(points: 180 + widget.level.number * 24);
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .25));
    setState(() {
      _solved = true;
      _activeNote = null;
      _activeBeatIndex = -1;
      _feedback = _english ? 'The rhythm is yours.' : 'Ritmi hafızana aldın.';
    });
  }

  void _showHint() {
    if (_playingBack || !_heardPattern || _solved) {
      return;
    }
    unawaited(_playPattern(costReplay: true));
  }

  Future<void> _showFailure() async {
    _failureOpen = true;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'The rhythm slipped' : 'Ritim kaçtı'),
        content: Text(
          _english
              ? 'The mistake budget is used. Reset this attempt to hear the pattern again.'
              : 'Hata hakkın doldu. Örüntüyü yeniden dinlemek için denemeyi sıfırla.',
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
      _inputNotes.clear();
      _inputAccents.clear();
      _inputIntervals.clear();
      _lastTapAt = null;
      _activeNote = null;
      _activeBeatIndex = -1;
      _feedback = null;
      _playingBack = false;
      _heardPattern = false;
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
      action:
          !_practice && widget.level.number < RhythmMemoryGamePage.totalLevels
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

  Widget _pad(int note, StudioGameSkin skin) {
    final bool active = _activeNote == note;
    final bool compact = MediaQuery.sizeOf(context).width < 365;
    final Color color = _notes[note];
    final String name = _english ? _solfegeEn[note] : _solfegeTr[note];
    return Semantics(
      button: true,
      label: _english
          ? '$name note. Tap for a normal beat, hold to accent.'
          : '$name notası. Normal vuruş için dokun, vurgu için basılı tut.',
      child: GestureDetector(
        key: ValueKey<String>('rhythm_memory_pad_$note'),
        onTap: () => _tapNote(note),
        onLongPress: () => _tapNote(note, accent: true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: active ? color : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: active ? color : StudioVisuals.line),
            boxShadow: active
                ? <BoxShadow>[
                    BoxShadow(
                      color: color.withValues(alpha: .22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : StudioVisuals.softShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: compact ? 36 : 40,
                height: compact ? 36 : 40,
                child: RealisticGameObject(
                  sheet: RealisticObjectSheet.tokens,
                  index: note,
                  borderRadius: 12,
                  overlayColor: color.withValues(alpha: active ? .32 : .12),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                name,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: active ? Colors.white : StudioVisuals.ink,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final bool compact = MediaQuery.sizeOf(context).width < 365;
    final StudioGameSkin skin = StudioGameSkin.forId('rhythm_memory');
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'RHYTHM MEMORY' : 'RİTİM HAFIZASI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: .9,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: Center(
              child: _RhythmChip(
                key: const ValueKey<String>('rhythm_memory_errors_left'),
                icon: Icons.favorite_border_rounded,
                value: '$_errorsLeft',
                tint: _errorsLeft <= 1 ? StudioVisuals.danger : skin.accent,
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
              key: const ValueKey<String>('rhythm_memory_scroll'),
              padding: EdgeInsets.fromLTRB(
                compact ? 13 : 22,
                compact ? 4 : 12,
                compact ? 13 : 22,
                compact ? 12 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _scenario.reverseRecall
                              ? (english ? 'REVERSE RECALL' : 'TERS HATIRLAMA')
                              : (english
                                    ? 'AUDITORY MEMORY'
                                    : 'İŞİTSEL HAFIZA'),
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: skin.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.15,
                          ),
                        ),
                      ),
                      _RhythmChip(
                        icon: Icons.music_note_rounded,
                        value: '${_scenario.length}',
                        tint: StudioVisuals.ink,
                      ),
                      const SizedBox(width: 6),
                      _RhythmChip(
                        icon: Icons.stars_rounded,
                        value: '${_session.score}',
                        tint: StudioVisuals.amber,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                Icons.graphic_eq_rounded,
                                color: skin.accent,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                _playingBack
                                    ? (english
                                          ? 'LISTEN • KEEP THE SPACES'
                                          : 'DİNLE • ARALARI DA TUT')
                                    : _solved
                                    ? (english
                                          ? 'PATTERN SECURED'
                                          : 'RİTİM KAYDEDİLDİ')
                                    : _heardPattern
                                    ? (english
                                          ? 'REPLAY THE PATTERN'
                                          : 'ÖRÜNTÜYÜ TEKRARLA')
                                    : (english
                                          ? 'MEMORIZE THE BEAT'
                                          : 'VURUŞU AKLINDA TUT'),
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: StudioVisuals.ink,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (_scenario.reverseRecall)
                              _RhythmTag(
                                label: english ? 'REVERSE' : 'TERS',
                                tint: skin.accent,
                                surface: skin.accentSoft,
                              ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        SizedBox(
                          height: compact ? 74 : 90,
                          child: CustomPaint(
                            key: const ValueKey<String>(
                              'rhythm_memory_waveform',
                            ),
                            painter: _RhythmWavePainter(
                              beats: _heardPattern && !_playingBack
                                  ? _scenario.answer
                                  : _scenario.beats,
                              gaps: _heardPattern && !_playingBack
                                  ? _scenario.answerGaps
                                  : _scenario.gaps,
                              activeIndex: _activeBeatIndex,
                              tint: skin.accent,
                              heard: _heardPattern,
                            ),
                            child: Center(
                              child: Text(
                                _scenario.reverseRecall
                                    ? (english
                                          ? 'Listen forward · play it backwards'
                                          : 'İleri dinle · tersten çal')
                                    : (english
                                          ? 'Note · gap · accent'
                                          : 'Nota · ara · vurgu'),
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: StudioVisuals.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          english
                              ? 'Tap a pad for a soft beat • hold it for an accent. The light-and-haptic cue also works with sound off.'
                              : 'Normal vuruş için dokun • vurgu için basılı tut. Ses kapalıyken ışık ve titreşim ipucu sürer.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.muted,
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    key: const ValueKey<String>('rhythm_memory_pad_grid'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 8,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 7,
                      mainAxisSpacing: 7,
                      mainAxisExtent: compact ? 62 : 74,
                    ),
                    itemBuilder: (BuildContext context, int note) =>
                        _pad(note, skin),
                  ),
                  if (_feedback != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _RhythmFeedback(text: _feedback!, positive: _solved),
                  ],
                  const SizedBox(height: 8),
                  if (_solved)
                    FilledButton.icon(
                      key: const ValueKey<String>('rhythm_memory_finish'),
                      onPressed: _finish,
                      icon: const Icon(Icons.celebration_rounded),
                      label: Text(
                        english ? 'COMPLETE RHYTHM' : 'RİTMİ TAMAMLA',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (!_heardPattern)
                    FilledButton.icon(
                      key: const ValueKey<String>('rhythm_memory_start'),
                      onPressed: _playingBack
                          ? null
                          : () => unawaited(_playPattern()),
                      icon: Icon(
                        _playingBack
                            ? Icons.graphic_eq_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(english ? 'PLAY THE RHYTHM' : 'RİTMİ DİNLE'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey<String>('rhythm_memory_hint'),
                            onPressed: _playingBack ? null : _showHint,
                            icon: const Icon(Icons.replay_rounded, size: 18),
                            label: Text(english ? 'REPLAY −70' : 'TEKRAR −70'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              foregroundColor: StudioVisuals.ink,
                              side: const BorderSide(color: StudioVisuals.line),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_inputNotes.length}/${_scenario.length}',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: skin.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
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
    );
  }
}

class _RhythmChip extends StatelessWidget {
  const _RhythmChip({
    super.key,
    required this.icon,
    required this.value,
    required this.tint,
  });
  final IconData icon;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 51, minHeight: 29),
    padding: const EdgeInsets.symmetric(horizontal: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 14, color: tint),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: StudioVisuals.ink,
          ),
        ),
      ],
    ),
  );
}

class _RhythmTag extends StatelessWidget {
  const _RhythmTag({
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
      style: TextStyle(
        fontFamily: 'Roboto',
        color: tint,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _RhythmFeedback extends StatelessWidget {
  const _RhythmFeedback({required this.text, required this.positive});
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
                fontFamily: 'Roboto',
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

class _RhythmWavePainter extends CustomPainter {
  const _RhythmWavePainter({
    required this.beats,
    required this.gaps,
    required this.activeIndex,
    required this.tint,
    required this.heard,
  });
  final List<RhythmBeat> beats;
  final List<int> gaps;
  final int activeIndex;
  final Color tint;
  final bool heard;

  @override
  void paint(Canvas canvas, Size size) {
    if (beats.isEmpty) return;
    final double totalUnits =
        (beats.length + gaps.fold<int>(0, (int sum, int gap) => sum + gap))
            .toDouble();
    final double unitWidth = size.width / (totalUnits + 1);
    double cursor = unitWidth / 2;
    final Paint line = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final Paint dot = Paint()..style = PaintingStyle.fill;
    final double centerY = size.height / 2;
    for (int index = 0; index < beats.length; index++) {
      final RhythmBeat beat = beats[index];
      final double radius = beat.accent ? 8 : 5.5;
      final Offset point = Offset(cursor + radius, centerY);
      line.color = tint.withValues(alpha: .32);
      if (index > 0) {
        canvas.drawLine(
          Offset(cursor - unitWidth + radius, centerY),
          point,
          line,
        );
      }
      dot.color = activeIndex == index
          ? tint
          : heard
          ? tint.withValues(alpha: .55)
          : StudioVisuals.line;
      canvas.drawCircle(point, activeIndex == index ? radius + 3 : radius, dot);
      if (beat.accent) {
        line.color = tint;
        canvas.drawLine(
          Offset(point.dx, centerY - radius - 7),
          Offset(point.dx, centerY - radius - 2),
          line,
        );
      }
      cursor += unitWidth * (1 + (index < gaps.length ? gaps[index] : 0));
    }
  }

  @override
  bool shouldRepaint(covariant _RhythmWavePainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.heard != heard ||
      oldDelegate.tint != tint;
}
