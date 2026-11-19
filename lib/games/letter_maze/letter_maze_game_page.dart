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
import 'letter_maze_scenario.dart';

class LetterMazeGamePage extends StatefulWidget {
  const LetterMazeGamePage({
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
    GameContentPolicy.nativeStages('letter_maze'),
    (int index) {
      final int level = index + 1;
      final String difficulty = level <= 6
          ? 'USTALAŞMA'
          : level <= 10
          ? 'İLERİ'
          : level <= 16
          ? 'UZMAN'
          : 'USTA';
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Rota ${level.toString().padLeft(2, '0')}',
        titleEn: 'Route ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Girişten başla, hece kapısına ulaş',
          <= 6 => 'Ek kapısını geçip doğru sözcüğü izle',
          <= 10 => 'Uzun rotada benzer harfleri ayıkla',
          <= 16 => 'Dar geçitlerde kök ve eki sırala',
          <= 19 => 'Tüm rota işaretlerini hatasız bağla',
          _ => 'Usta finali • uzun ve yanıltıcı rota',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Start at the entrance and find the syllable gate',
          <= 6 => 'Pass the affix gate and trace the word',
          <= 10 => 'Separate similar letters across a longer route',
          <= 16 => 'Sequence root and ending through narrow turns',
          <= 19 => 'Connect every route marker without a mistake',
          _ => 'Master finale • long route with close decoys',
        },
        difficulty: difficulty,
        icon: Icons.route_rounded,
      );
    },
    growable: false,
  );

  @override
  State<LetterMazeGamePage> createState() => _LetterMazeGamePageState();
}

class _LetterMazeGamePageState extends State<LetterMazeGamePage> {
  static const String _practiceKey = 'letter_maze_next_practice_round';
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
          .clamp(1, LetterMazeScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => LetterMazePlayPage(
              level: LetterMazeGamePage
                  ._levels[(round - 1) % LetterMazeGamePage.totalCases],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == LetterMazeScenario.uniquePracticeRounds
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
              ? 'Route solved • next unique maze: $next / 300'
              : 'Rota çözüldü • sıradaki farklı labirent: $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('letter_maze');
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'letter_maze',
      progressPrefix: 'letter_maze',
      titleTr: 'Harf Labirenti',
      titleEn: 'Letter Maze',
      taglineTr: 'İpucunu çöz • harfleri izle • kök kapısını geç',
      taglineEn: 'Solve the clue • trace the letters • pass the root gate',
      accent: skin.accent,
      icon: Icons.route_rounded,
      levels: LetterMazeGamePage._levels,
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
                    ? 'UNIQUE MAZES  •  $_nextPracticeRound / 300'
                    : 'FARKLI LABİRENT  •  $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => LetterMazePlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          LetterMazeScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class LetterMazePlayPage extends StatefulWidget {
  const LetterMazePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<LetterMazePlayPage> createState() => _LetterMazePlayPageState();
}

class _LetterMazePlayPageState extends State<LetterMazePlayPage>
    with SingleTickerProviderStateMixin {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.language,
  );

  late StudioGameSession _session;
  late LetterMazeScenario _scenario;
  late final AnimationController _entranceBlinkController;
  int _blinkCount = 0;
  bool _initialized = false;
  bool _failureDialogOpen = false;
  bool _solved = false;
  int _hints = 0;
  int? _hintTile;
  String? _feedback;
  List<int> _route = <int>[];

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  int get _mistakeLimit => widget.level.number <= 3
      ? 6
      : widget.level.number <= 6
      ? 5
      : widget.level.number <= 10
      ? 3
      : widget.level.number <= 16
      ? 2
      : 1;
  int get _errorsLeft => math.max(0, _mistakeLimit - _session.mistakes).toInt();
  String get _attempt =>
      _route.map((int index) => _scenario.tiles[index].letter).join();

  @override
  void initState() {
    super.initState();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.practiceRound ?? widget.level.number,
    )..start();
    _entranceBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _entranceBlinkController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _blinkCount++;
          if (_blinkCount < 3 && mounted) {
            _entranceBlinkController.forward();
          }
        }
      });
    _startEntranceBlink();
  }

  void _startEntranceBlink() {
    _blinkCount = 0;
    _entranceBlinkController.reset();
    _entranceBlinkController.forward();
  }

  @override
  void dispose() {
    _entranceBlinkController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _scenario = _practice
        ? LetterMazeScenario.forPracticeRound(
            widget.practiceRound!,
            english: _english,
          )
        : (widget.level.poolIndex != null
              ? LetterMazeScenario.forPracticeRound(
                  widget.level.contentIndex,
                  english: _english,
                )
              : LetterMazeScenario.forCampaignLevel(
                  widget.level.contentLevel,
                  english: _english,
                ));
  }

  void _selectTile(int index) {
    if (_solved || !_session.acceptsInput) return;
    setState(() {
      _feedback = null;
      if (_route.isEmpty) {
        if (index != _scenario.solutionPath.first) {
          _feedback = _english
              ? 'Begin at the marked entrance.'
              : 'İşaretli giriş hücresinden başla.';
          return;
        }
        if (_entranceBlinkController.isAnimating) {
          _entranceBlinkController.stop();
        }
        _route.add(index);
        return;
      }

      final int priorPosition = _route.indexOf(index);
      if (priorPosition >= 0) {
        if (priorPosition < _route.length - 1) {
          _route.removeRange(priorPosition + 1, _route.length);
        }
        return;
      }

      final int previous = _route.last;
      final int rowDelta =
          (previous ~/ LetterMazeScenario.gridSide) -
          (index ~/ LetterMazeScenario.gridSide);
      final int columnDelta =
          (previous % LetterMazeScenario.gridSide) -
          (index % LetterMazeScenario.gridSide);
      if (rowDelta.abs() + columnDelta.abs() != 1) {
        _feedback = _english
            ? 'The maze only allows side-to-side steps.'
            : 'Labirentte yalnızca kenar komşusu hücreye ilerleyebilirsin.';
        return;
      }
      if (_route.length >= _scenario.answer.runes.length) {
        _feedback = _english
            ? 'This route is already at the word length. Clear it to retry.'
            : 'Bu rota sözcük uzunluğuna ulaştı. Yeniden denemek için temizle.';
        return;
      }
      _route.add(index);
      _hintTile = null;
    });
    if (_route.isNotEmpty && _route.last == index) {
      _audio.hapticSelection();
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .14),
      );
    }
  }

  void _clearRoute() {
    if (_solved || !_session.acceptsInput) return;
    setState(() {
      _route = <int>[];
      _hintTile = null;
      _feedback = null;
    });
    _audio.hapticLight();
  }

  void _checkRoute() {
    if (_solved || _route.isEmpty || !_session.acceptsInput) return;
    final bool reachesExit = _route.last == _scenario.solutionPath.last;
    final bool crossesGate = _route.contains(_scenario.checkpointIndex);
    final bool spellsAnswer = _attempt == _scenario.answer;
    if (!reachesExit || !crossesGate || !spellsAnswer) {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .28));
      final String reason = !reachesExit
          ? (_english ? 'Reach the marked exit.' : 'İşaretli çıkışa ulaş.')
          : !crossesGate
          ? (_english
                ? 'Pass through the root gate before the exit.'
                : 'Çıkıştan önce kök kapısından geç.')
          : (_english
                ? 'The letters do not form the word described by the clue.'
                : 'Harfler, ipucunda anlatılan sözcüğü oluşturmuyor.');
      setState(() {
        _feedback =
            '$reason  $_errorsLeft ${_errorsLeft == 1 ? (_english ? 'try' : 'hak') : (_english ? 'tries' : 'hak')}';
        _route = <int>[];
        _hintTile = null;
      });
      if (_errorsLeft == 0 && !_failureDialogOpen) unawaited(_showFailure());
      return;
    }

    _session.recordAccepted(points: 250 + widget.level.number * 24);
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .42));
    setState(() {
      _solved = true;
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
        title: Text(_english ? 'Route closed' : 'Rota kapandı'),
        content: Text(
          _english
              ? 'The try limit is used. Re-read the clue, then connect the entrance, root gate and exit in order.'
              : 'Deneme hakkın doldu. İpucunu yeniden oku; giriş, kök kapısı ve çıkışı sırayla bağla.',
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
      _solved = false;
      _hints = 0;
      _hintTile = null;
      _feedback = null;
      _route = <int>[];
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
      _startEntranceBlink();
    });
  }

  void _useHint() {
    if (_solved || _hints >= 2 || !_session.useHint(pointCost: 125)) return;
    final bool hasCorrectPrefix =
        _route.length <= _scenario.solutionPath.length &&
        List<int>.generate(
          _route.length,
          (int index) => _route[index] == _scenario.solutionPath[index] ? 1 : 0,
        ).every((int matches) => matches == 1);
    final int nextIndex = hasCorrectPrefix
        ? _route.length.clamp(0, _scenario.solutionPath.length - 1).toInt()
        : 0;
    setState(() {
      _hints++;
      _hintTile = _scenario.solutionPath[nextIndex];
      _feedback = _english
          ? 'The glowing tile is the next step on the intended route.'
          : 'Parlayan hücre, doğru rotadaki sıradaki adımdır.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .28));
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
      action: !_practice && widget.level.number < LetterMazeGamePage.totalCases
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
        final StudioGameSkin skin = StudioGameSkin.forId('letter_maze');
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
                    ? '• Trace the correct word path from the maze entrance, passing through root gates to the exit.\n'
                      '• Tap adjacent letters step-by-step to form the target word.\n'
                      '• Use the hint button if you need help finding the next letter.\n'
                      '• Press "CHECK ROUTE" once your sequence is complete!'
                    : '• Labirent girişinden başlayarak kök kapısından geçen ve çıkışa ulaşan doğru kelime rotasını çiz.\n'
                      '• Komşu harflere sırayla dokunarak hedef sözcüğü oluştur.\n'
                      '• Takıldığında "İPUCU" butonuna basarak bir sonraki harfi görebilirsin.\n'
                      '• Rotanı tamamlayınca "ROTAYI KONTROL ET" butonuyla doğrula!',
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
    final StudioGameSkin skin = StudioGameSkin.forId('letter_maze');
    final Map<int, int> routeSteps = <int, int>{
      for (int step = 0; step < _route.length; step++) _route[step]: step + 1,
    };
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
              context.l10n.gameTitle('letter_maze'),
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
                          '${_english ? 'Word' : 'Sözcük'}: ${_route.length}/${_scenario.answer.runes.length}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ❤️ $_errorsLeft/$_mistakeLimit',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: _errorsLeft <= 1 ? StudioVisuals.danger : skin.accent,
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
                              value: _solved ? 1 : _route.length / _scenario.answer.runes.length,
                              minHeight: 6,
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

                // Ana Labirent Alanı: Kaydırmasız (Zero-Scroll)
                Expanded(
                  child: Column(
                    children: <Widget>[
                      _MazeClue(
                        scenario: _scenario,
                        english: _english,
                        accent: skin.accent,
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints gridLimits) {
                            final double width = math.min(
                              math.min(gridLimits.maxWidth, gridLimits.maxHeight),
                              340,
                            );
                            return Center(
                              child: SizedBox(
                                width: width,
                                height: width,
                                child: AnimatedBuilder(
                                  animation: _entranceBlinkController,
                                  builder: (
                                    BuildContext context,
                                    Widget? child,
                                  ) {
                                    return _MazeGrid(
                                      scenario: _scenario,
                                      accent: skin.accent,
                                      selectedSteps: routeSteps,
                                      hintTile: _hintTile,
                                      solved: _solved,
                                      entranceBlinkValue:
                                          _route.isEmpty
                                              ? _entranceBlinkController.value
                                              : 0.0,
                                      onTap: _selectTile,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RouteReadout(
                        attempt: _attempt,
                        targetLength: _scenario.answer.runes.length,
                        english: _english,
                        accent: skin.accent,
                        solved: _solved,
                      ),
                      if (_feedback != null) ...<Widget>[
                        const SizedBox(height: 4),
                        _MazeFeedback(message: _feedback!),
                      ],
                      if (_solved) ...<Widget>[
                        const SizedBox(height: 6),
                        _MazeSolved(
                          scenario: _scenario,
                          english: _english,
                          accent: skin.accent,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Alt Aksiyon Butonları (42px)
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: _solved || _hints >= 2 ? null : _useHint,
                        icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                        label: Text(
                          _english ? 'HINT $_hints/2' : 'İPUCU $_hints/2',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: skin.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: _solved ? null : _clearRoute,
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: Text(
                          _english ? 'CLEAR' : 'TEMİZLE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: StudioVisuals.muted,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        key: const ValueKey<String>('letter_maze_submit'),
                        onPressed: _solved
                            ? _finish
                            : _route.isEmpty
                                ? null
                                : _checkRoute,
                        icon: Icon(
                          _solved ? Icons.celebration_rounded : Icons.route_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _solved
                              ? (_english ? 'COMPLETED' : 'TAMAMLANDI')
                              : (_english ? 'CHECK ROUTE' : 'ROTAYI KONTROL ET'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: skin.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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

class _MazeClue extends StatelessWidget {
  const _MazeClue({
    required this.scenario,
    required this.english,
    required this.accent,
  });

  final LetterMazeScenario scenario;
  final bool english;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: .19)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: .055),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.tips_and_updates_outlined, size: 17, color: accent),
              const SizedBox(width: 6),
              Text(
                english ? 'WORD CLUE' : 'SÖZCÜK İPUCU',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              const Spacer(),
              Text(
                '${scenario.answer.runes.length} ${english ? 'LETTERS' : 'HARF'}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            scenario.clue,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontSize: 14,
              height: 1.22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              _MazeLegend(
                icon: Icons.login_rounded,
                label: english ? 'IN' : 'GİRİŞ',
                accent: accent,
              ),
              const SizedBox(width: 7),
              _MazeLegend(
                icon: Icons.adjust_rounded,
                label: scenario.rootLabel,
                accent: const Color(0xFFB48236),
              ),
              const SizedBox(width: 7),
              _MazeLegend(
                icon: Icons.logout_rounded,
                label: english ? 'OUT' : 'ÇIKIŞ',
                accent: StudioVisuals.ink,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MazeLegend extends StatelessWidget {
  const _MazeLegend({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .075),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: accent, size: 12),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MazeGrid extends StatelessWidget {
  const _MazeGrid({
    required this.scenario,
    required this.accent,
    required this.selectedSteps,
    required this.hintTile,
    required this.solved,
    this.entranceBlinkValue = 0.0,
    required this.onTap,
  });

  final LetterMazeScenario scenario;
  final Color accent;
  final Map<int, int> selectedSteps;
  final int? hintTile;
  final bool solved;
  final double entranceBlinkValue;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final int entrance = scenario.solutionPath.first;
    final int exit = scenario.solutionPath.last;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF0),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x140F2931),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: scenario.tiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: LetterMazeScenario.gridSide,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (BuildContext context, int index) {
          final LetterMazeTile tile = scenario.tiles[index];
          return _LetterTile(
            key: ValueKey<String>('letter_maze_tile_$index'),
            letter: _displayLetter(tile.letter),
            selectedStep: selectedSteps[index],
            isEntrance: index == entrance,
            isCheckpoint: index == scenario.checkpointIndex,
            isExit: index == exit,
            isHint: index == hintTile && !solved,
            solved: solved && scenario.solutionPath.contains(index),
            entranceBlinkValue: index == entrance ? entranceBlinkValue : 0.0,
            accent: accent,
            onTap: () => onTap(index),
          );
        },
      ),
    );
  }

  String _displayLetter(String letter) {
    const Map<String, String> turkishUpper = <String, String>{
      'i': 'İ',
      'ı': 'I',
      'ç': 'Ç',
      'ğ': 'Ğ',
      'ö': 'Ö',
      'ş': 'Ş',
      'ü': 'Ü',
    };
    return turkishUpper[letter] ?? letter.toUpperCase();
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    super.key,
    required this.letter,
    required this.selectedStep,
    required this.isEntrance,
    required this.isCheckpoint,
    required this.isExit,
    required this.isHint,
    required this.solved,
    this.entranceBlinkValue = 0.0,
    required this.accent,
    required this.onTap,
  });

  final String letter;
  final int? selectedStep;
  final bool isEntrance;
  final bool isCheckpoint;
  final bool isExit;
  final bool isHint;
  final bool solved;
  final double entranceBlinkValue;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool selected = selectedStep != null;
    final bool isBlinking = isEntrance && !selected && entranceBlinkValue > 0;
    final Color baseTone = selected
        ? accent
        : isCheckpoint
        ? const Color(0xFFB48236)
        : isExit
        ? StudioVisuals.ink
        : const Color(0xFFFCFDFD);
    final Color tone = isBlinking
        ? Color.lerp(baseTone, accent.withValues(alpha: .30), entranceBlinkValue)!
        : baseTone;
    final Color foreground = selected || isExit
        ? Colors.white
        : StudioVisuals.ink;
    final Color borderColor = isHint
        ? const Color(0xFFE0A62B)
        : selected
        ? accent
        : isBlinking
        ? Color.lerp(accent.withValues(alpha: .52), accent, entranceBlinkValue)!
        : isEntrance
        ? accent.withValues(alpha: .52)
        : isCheckpoint
        ? const Color(0xFFD5AD69)
        : const Color(0xFFD9E1E4);
    final double borderWidth = isHint || selected
        ? 2
        : isBlinking
        ? 1.0 + 1.8 * entranceBlinkValue
        : 1;
    final double scale = isBlinking ? 1.0 + 0.07 * entranceBlinkValue : 1.0;

    return Transform.scale(
      scale: scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: isHint ? const Color(0xFFFFEDB8) : tone,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isBlinking
                  ? accent.withValues(alpha: .14 + .26 * entranceBlinkValue)
                  : (isHint ? const Color(0xFFD59B24) : accent).withValues(
                      alpha: .11,
                    ),
              blurRadius: isBlinking ? 6 + 10 * entranceBlinkValue : (isHint ? 10 : 5),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Text(
                  letter,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: isHint ? const Color(0xFF614512) : foreground,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              if (selectedStep != null)
                Positioned(
                  top: 2,
                  right: 3,
                  child: Text(
                    '$selectedStep',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (isEntrance || isCheckpoint || isExit)
                Positioned(
                  bottom: 2,
                  child: Icon(
                    isEntrance
                        ? Icons.login_rounded
                        : isCheckpoint
                        ? Icons.adjust_rounded
                        : Icons.logout_rounded,
                    color: foreground.withValues(alpha: .82),
                    size: 11,
                  ),
                ),
              if (solved)
                Positioned(
                  top: 2,
                  left: 3,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 10,
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

class _RouteReadout extends StatelessWidget {
  const _RouteReadout({
    required this.attempt,
    required this.targetLength,
    required this.english,
    required this.accent,
    required this.solved,
  });

  final String attempt;
  final int targetLength;
  final bool english;
  final Color accent;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    final String visible = attempt.isEmpty ? '—' : _uppercaseTurkish(attempt);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: solved ? const Color(0xFFE7F2EB) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: solved ? const Color(0xFFB8D3BF) : const Color(0xFFE0E7E9),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            solved ? Icons.check_circle_rounded : Icons.route_rounded,
            color: accent,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              visible,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontSize: 15,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '${attempt.runes.length}/$targetLength',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _uppercaseTurkish(String value) {
    const Map<String, String> upper = <String, String>{'i': 'İ', 'ı': 'I'};
    return value
        .split('')
        .map((String char) => upper[char] ?? char.toUpperCase())
        .join();
  }
}

class _MazeFeedback extends StatelessWidget {
  const _MazeFeedback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: Color(0xFF8A5225),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MazeSolved extends StatelessWidget {
  const _MazeSolved({
    required this.scenario,
    required this.english,
    required this.accent,
  });

  final LetterMazeScenario scenario;
  final bool english;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('letter_maze_result'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3ED),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFBBD7C4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  english ? 'Route solved' : 'Rota çözüldü',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  scenario.explanation,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
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

