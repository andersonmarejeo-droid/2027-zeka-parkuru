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
import 'attention_tunnel_scenario.dart';

const List<String> _attentionCardNamesTr = <String>[
  'PUSULA',
  'ANAHTAR',
  'MERCEK',
  'YAPRAK',
  'PORTAKAL',
  'DENİZ KABUĞU',
  'FENER',
  'KAR KÜRESİ',
  'KURDELE',
];
const List<String> _attentionCardNamesEn = <String>[
  'COMPASS',
  'KEY',
  'LENS',
  'LEAF',
  'ORANGE',
  'SHELL',
  'LANTERN',
  'SNOW GLOBE',
  'RIBBON',
];
const List<Color> _attentionCardColors = <Color>[
  Color(0xFF238F81),
  Color(0xFF5585C4),
  Color(0xFFD68F3E),
  Color(0xFF4E9C9A),
  Color(0xFFBA6D8E),
  Color(0xFF678B67),
  Color(0xFF7765C6),
  Color(0xFFCE7654),
  Color(0xFF3985A0),
];

class AttentionTunnelGamePage extends StatefulWidget {
  const AttentionTunnelGamePage({
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
    GameContentPolicy.nativeStages('attention_tunnel'),
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Tünel ${level.toString().padLeft(2, '0')}',
        titleEn: 'Tunnel ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 2 => 'Üç büyük karttan hedefi gör ve karıştırmada izle',
          <= 6 => 'Dört kartta giderek hızlanan karıştırmayı takip et',
          <= 10 => 'Beş kart ve ilk yavaş geçişlerle odağını koru',
          <= 13 => 'Altı kartta hedefi kesişen hareketlerden ayır',
          <= 16 => 'Yedi kartta çift geçişleri ve yavaş geçişleri izle',
          <= 19 => 'Sekiz kartı hızlı karıştırmada takip et',
          _ => 'Dokuz kart • 22 karıştırma • dört yavaş geçiş • tek hata',
        },
        subtitleEn: switch (level) {
          <= 2 =>
            'Spot the target among three large cards and follow its shuffle',
          <= 6 => 'Track faster shuffles across four cards',
          <= 10 => 'Hold focus across five cards and the first slow crossings',
          <= 13 => 'Follow the target through six-card crossings',
          <= 16 => 'Track paired swaps and slow crossings across seven cards',
          <= 19 => 'Follow eight cards through a fast shuffle',
          _ => 'Nine cards • 22 shuffles • four slow crossings • one mistake',
        },
        difficulty: level <= 3
            ? 'ODAK'
            : level <= 6
            ? 'İZLE'
            : level <= 10
            ? 'KESİŞİM'
            : level <= 16
            ? 'UZMAN'
            : 'USTA',
        icon: Icons.blur_on_rounded,
      );
    },
    growable: false,
  );

  @override
  State<AttentionTunnelGamePage> createState() =>
      _AttentionTunnelGamePageState();
}

class _AttentionTunnelGamePageState extends State<AttentionTunnelGamePage> {
  static const String _practiceKey = 'attention_tunnel_next_practice_round';
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
          .clamp(1, AttentionTunnelScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => AttentionTunnelPlayPage(
              level: AttentionTunnelGamePage
                  .levels[(round - 1) % AttentionTunnelGamePage.totalLevels],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == AttentionTunnelScenario.uniquePracticeRounds
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
              ? 'Target tracked • unique route $next / 300'
              : 'Hedef izlendi • farklı rota $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    final StudioGameSkin skin = StudioGameSkin.forId('attention_tunnel');
    return ParkurLevelHub(
      gameId: 'attention_tunnel',
      progressPrefix: 'attention_tunnel',
      titleTr: 'Dikkat Tüneli',
      titleEn: 'Attention Tunnel',
      taglineTr: 'Hedef kartı tanı • karıştırmayı izle • doğru kartı seç',
      taglineEn: 'Spot the target card • follow the shuffle • choose it',
      accent: skin.accent,
      icon: Icons.blur_on_rounded,
      levels: AttentionTunnelGamePage.levels,
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
                    ? 'UNIQUE TRACKS • $_nextPracticeRound / 300'
                    : 'FARKLI ROTАLAR • $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => AttentionTunnelPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          AttentionTunnelScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class AttentionTunnelPlayPage extends StatefulWidget {
  const AttentionTunnelPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<AttentionTunnelPlayPage> createState() =>
      _AttentionTunnelPlayPageState();
}

class _AttentionTunnelPlayPageState extends State<AttentionTunnelPlayPage>
    with WidgetsBindingObserver {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.memory,
  );
  late StudioGameSession _session;
  late AttentionTunnelScenario _scenario;
  late List<int> _occupants;
  bool _initialized = false;
  bool _tracking = false;
  bool _choosingLane = false;
  bool _solved = false;
  bool _hintUsed = false;
  final Set<int> _revealedCardTokens = <int>{};
  int _movementIndex = 0;
  int _generation = 0;
  int? _selectedCardSlot;
  String? _feedback;
  bool? _lastCorrect;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  String _cardName(int token) => _english
      ? _attentionCardNamesEn[token % _attentionCardNamesEn.length]
      : _attentionCardNamesTr[token % _attentionCardNamesTr.length];
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
    _scenario = widget.practiceRound == null
        ? (widget.level.poolIndex != null
              ? AttentionTunnelScenario.forPracticeRound(
                  widget.level.contentIndex,
                )
              : AttentionTunnelScenario.forCampaignLevel(
                  widget.level.contentLevel,
                ))
        : AttentionTunnelScenario.forPracticeRound(widget.practiceRound!);
    _occupants = List<int>.generate(_scenario.cardCount, (int index) => index);
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
    if (!mounted || !_tracking) return;
    _generation++;
    setState(() {
      _tracking = false;
      _choosingLane = false;
      _movementIndex = 0;
      _occupants = List<int>.generate(
        _scenario.cardCount,
        (int index) => index,
      );
      _revealedCardTokens.clear();
      _feedback = _english
          ? 'Shuffle paused safely. Restart to begin again.'
          : 'Karıştırma güvenle durdu. Yeniden başlatıp tekrar dene.';
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  bool _validGeneration(int generation) =>
      mounted && generation == _generation && _tracking;

  Future<void> _startTracking() async {
    if (_tracking || _solved) return;
    final int generation = ++_generation;
    setState(() {
      _tracking = true;
      _choosingLane = false;
      _movementIndex = 0;
      _selectedCardSlot = null;
      _occupants = List<int>.generate(
        _scenario.cardCount,
        (int index) => index,
      );
      _revealedCardTokens.clear();
      _feedback = _english
          ? 'Cards closed • follow the marked target through every swap.'
          : 'Kartlar kapandı • işaretli hedefi her değişimde takip et.';
      _lastCorrect = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .16),
    );
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!_validGeneration(generation)) return;
    await _runMovements(generation);
  }

  Future<void> _runMovements(int generation) async {
    for (int index = 0; index < _scenario.movements.length; index++) {
      if (!_validGeneration(generation)) return;
      final TunnelMovement movement = _scenario.movements[index];
      if (movement.occluded) {
        setState(() {
          _feedback = _english
              ? 'SLOW CROSSING • keep following the visible target card.'
              : 'YAVAŞ GEÇİŞ • görünür hedef kartı izlemeyi sürdür.';
          _lastCorrect = null;
        });
      }
      setState(() {
        for (final TunnelSwap swap in movement.swaps) {
          final int held = _occupants[swap.firstLane];
          _occupants[swap.firstLane] = _occupants[swap.secondLane];
          _occupants[swap.secondLane] = held;
        }
        _movementIndex = index + 1;
      });
      if (index % 5 == 4 || movement.occluded) {
        _audio.hapticLight();
        unawaited(
          _audioProfile.play(
            _audio,
            movement.occluded
                ? GameAudioEvent.timeWarning
                : GameAudioEvent.primaryAction,
            gain: movement.occluded ? .2 : .08,
          ),
        );
      }
      final int remaining = math.max(
        0,
        _scenario.movementIntervalMs - 80,
      );
      await Future<void>.delayed(Duration(milliseconds: remaining));
    }
    if (!_validGeneration(generation)) return;
    setState(() {
      _tracking = false;
      _choosingLane = true;
      _feedback = _english
          ? 'Shuffle complete • tap the card that held the target.'
          : 'Karıştırma bitti • hedefin kaldığı karta dokun.';
      _lastCorrect = null;
    });
    _audio.hapticSelection();
  }

  void _chooseCardSlot(int slot) {
    if (!_choosingLane || !_session.acceptsInput || _solved) return;
    final int token = _occupants[slot];
    final bool correct = slot == _scenario.finalTargetCardSlot;
    if (correct) {
      _session.recordAccepted(points: 180 + _scenario.movementCount * 16);
      _audio.hapticSelection();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .24));
      setState(() {
        _selectedCardSlot = slot;
        _revealedCardTokens.add(token);
        _solved = true;
        _choosingLane = false;
        _feedback = _english
            ? 'Target found • the ${_cardName(token)} card was yours.'
            : 'Hedef bulundu • ${_cardName(token)} kartı doğru.';
        _lastCorrect = true;
      });
      return;
    }
    _session.recordMistake();
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
    setState(() {
      _selectedCardSlot = slot;
      _revealedCardTokens.add(token);
      _feedback = _english
          ? 'Not this card • $_errorsLeft attempt(s) remain.'
          : 'Bu kart değil • $_errorsLeft deneme hakkı kaldı.';
      _lastCorrect = false;
    });
    if (_errorsLeft <= 0) unawaited(_showFailure());
  }

  void _useHint() {
    if (!_choosingLane || !_session.useHint(pointCost: 45)) return;
    _hintUsed = true;
    final int moves = _scenario.actualTargetLaneMoves;
    setState(() {
      _feedback = _english
          ? 'Hint • the target card moved $moves times.'
          : 'İpucu • hedef kart $moves kez yer değiştirdi.';
      _lastCorrect = null;
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .2));
  }

  Future<void> _showFailure() async {
    _choosingLane = false;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'Target lost' : 'Hedef kayboldu'),
        content: Text(
          _english
              ? 'Your attempts are used. Reset the cards and follow the target again.'
              : 'Deneme hakkın doldu. Kartları sıfırla ve hedefi yeniden izle.',
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
    _generation++;
    setState(() {
      _tracking = false;
      _choosingLane = false;
      _solved = false;
      _hintUsed = false;
      _movementIndex = 0;
      _selectedCardSlot = null;
      _occupants = List<int>.generate(
        _scenario.cardCount,
        (int index) => index,
      );
      _revealedCardTokens.clear();
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
    final int stars = !_hintUsed && _session.mistakes == 0
        ? 3
        : _session.mistakes <= 1
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action:
          !_practice &&
              widget.level.number < AttentionTunnelGamePage.totalLevels
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

  Widget _tunnelBoard({required bool compact, required bool reduceMotion}) {
    final int targetToken = _scenario.targetCardId;
    final int cardCount = _scenario.cardCount;
    final bool preview = !_tracking && !_choosingLane && _movementIndex == 0;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = cardCount == 3
            ? 3
            : cardCount == 4
            ? 2
            : 3;
        final int rows = (cardCount + columns - 1) ~/ columns;
        final double inset = compact ? 10 : 14;
        final double gap = compact ? 8 : 11;
        final double cardWidth =
            (constraints.maxWidth - inset * 2 - gap * (columns - 1)) / columns;
        final double cardHeight = (cardWidth * (cardCount <= 3 ? 1.64 : 1.42))
            .clamp(compact ? 126.0 : 144.0, compact ? 184.0 : 200.0)
            .toDouble();
        final double gridHeight = cardHeight * rows + gap * (rows - 1);
        final int travelMs = _scenario.movementIntervalMs;
        // Keep every swap on screen for almost the whole movement interval.
        // Previously the cards finished their slide halfway through the
        // interval, which looked like a teleport on the faster stages.
        final Duration slideDuration = reduceMotion
            ? Duration.zero
            : Duration(milliseconds: (travelMs - 120).clamp(280, 760));

        return Container(
          key: const ValueKey<String>('attention_tunnel_board'),
          padding: EdgeInsets.all(inset),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFFFFFFF), Color(0xFFECF5F2)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: StudioVisuals.line),
            boxShadow: StudioVisuals.softShadow,
          ),
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            height: gridHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: <Widget>[
                for (int token = 0; token < cardCount; token++)
                  Builder(
                    builder: (BuildContext context) {
                      final int slot = _occupants.indexOf(token);
                      final int row = slot ~/ columns;
                      final int column = slot % columns;
                      final bool isTarget = token == targetToken;
                      final bool faceUp =
                          preview ||
                          _revealedCardTokens.contains(token) ||
                          (_solved && isTarget);
                      final bool canChoose =
                          _choosingLane &&
                          _session.acceptsInput &&
                          !_solved &&
                          !_revealedCardTokens.contains(token);
                      final bool selected = _selectedCardSlot == slot;
                      final Color accent =
                          _attentionCardColors[token %
                              _attentionCardColors.length];
                      final Color borderColor = _solved && isTarget
                          ? StudioVisuals.teal
                          : selected && _lastCorrect == false
                          ? StudioVisuals.danger
                          : preview && isTarget
                          ? StudioVisuals.amber
                          : canChoose
                          ? StudioVisuals.teal.withValues(alpha: .42)
                          : StudioVisuals.line;
                      return AnimatedPositioned(
                        key: ValueKey<String>('attention_tunnel_token_$token'),
                        duration: slideDuration,
                        curve: Curves.easeInOutCubic,
                        left: column * (cardWidth + gap),
                        top: row * (cardHeight + gap),
                        child: SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(21),
                            child: InkWell(
                              key: ValueKey<String>(
                                'attention_tunnel_card_slot_$slot',
                              ),
                              onTap: canChoose
                                  ? () => _chooseCardSlot(slot)
                                  : null,
                              borderRadius: BorderRadius.circular(21),
                              child: AnimatedContainer(
                                duration: reduceMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 260),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(21),
                                  border: Border.all(
                                    color: borderColor,
                                    width: preview && isTarget || selected
                                        ? 2.5
                                        : 1.2,
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: preview && isTarget
                                          ? StudioVisuals.amber.withValues(
                                              alpha: .30,
                                            )
                                          : accent.withValues(alpha: .13),
                                      blurRadius: preview && isTarget ? 22 : 12,
                                      spreadRadius: preview && isTarget ? 2 : 0,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedSwitcher(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 440),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder:
                                        (
                                          Widget child,
                                          Animation<double> animation,
                                        ) {
                                          final bool front =
                                              child.key ==
                                              const ValueKey<String>('face_up');
                                          final Animation<double> rotation =
                                              Tween<double>(
                                                begin: front ? -.5 : .5,
                                                end: 0,
                                              ).animate(animation);
                                          return AnimatedBuilder(
                                            animation: rotation,
                                            child: child,
                                            builder:
                                                (
                                                  BuildContext context,
                                                  Widget? child,
                                                ) => Transform(
                                                  alignment: Alignment.center,
                                                  transform: Matrix4.identity()
                                                    ..setEntry(3, 2, .001)
                                                    ..rotateY(
                                                      rotation.value * math.pi,
                                                    ),
                                                  child: child,
                                                ),
                                          );
                                        },
                                    child: faceUp
                                        ? _frontCard(
                                            token: token,
                                            accent: accent,
                                            isTarget: isTarget,
                                            cardWidth: cardWidth,
                                            cardHeight: cardHeight,
                                          )
                                        : _backCard(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _frontCard({
    required int token,
    required Color accent,
    required bool isTarget,
    required double cardWidth,
    required double cardHeight,
  }) => Container(
    key: const ValueKey<String>('face_up'),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.lerp(Colors.white, accent, .08)!,
          Color.lerp(Colors.white, accent, .16)!,
        ],
      ),
    ),
    child: Stack(
      children: <Widget>[
        if (isTarget)
          Positioned(
            top: 7,
            left: 5,
            right: 5,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  key: const ValueKey<String>('attention_tunnel_target_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0C9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: StudioVisuals.amber.withValues(alpha: .3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: StudioVisuals.amber,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _english ? 'TARGET' : 'HEDEF',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Color(0xFF98651F),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            5,
            isTarget ? 27 : 8,
            5,
            cardHeight < 145 ? 6 : 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Container(
                    width: math.min(cardWidth * .68, cardHeight * .48),
                    height: math.min(cardWidth * .68, cardHeight * .48),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          Colors.white.withValues(alpha: .98),
                          accent.withValues(alpha: .10),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withValues(alpha: .18)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: accent.withValues(alpha: .14),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: RealisticGameObject(
                      sheet: RealisticObjectSheet.memory,
                      index: token,
                      borderRadius: math.min(cardWidth * .16, 14),
                      overlayColor: accent.withValues(alpha: .08),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _cardName(token),
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: cardWidth < 90 ? 10 : 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _backCard() => Container(
    key: const ValueKey<String>('face_down'),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF2DA998),
          Color(0xFF155B59),
          Color(0xFF12414B),
        ],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Icon(
          Icons.blur_on_rounded,
          color: Colors.white.withValues(alpha: .08),
          size: 112,
        ),
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .10),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .32)),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFFFD37A),
            size: 34,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bool english = _english;
    final bool compact = MediaQuery.sizeOf(context).width < 365;
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final StudioGameSkin skin = StudioGameSkin.forId('attention_tunnel');
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          english ? 'ATTENTION TUNNEL' : 'DİKKAT TÜNELİ',
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
              child: _TunnelMetric(
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
              key: const ValueKey<String>('attention_tunnel_scroll'),
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
                          _choosingLane
                              ? (english ? 'CHOOSE THE CARD' : 'KARTI SEÇ')
                              : _tracking
                              ? (english
                                    ? 'FOLLOW THE SHUFFLE'
                                    : 'KARIŞTIRMAYI İZLE')
                              : (english ? 'CARD PREVIEW' : 'KART ÖNİZLEMESİ'),
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: skin.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      _TunnelMetric(
                        icon: Icons.shuffle_rounded,
                        value: '$_movementIndex/${_scenario.movementCount}',
                        color: StudioVisuals.ink,
                      ),
                      const SizedBox(width: 6),
                      _TunnelMetric(
                        icon: Icons.stars_rounded,
                        value: '${_session.score}',
                        color: StudioVisuals.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Container(
                    padding: EdgeInsets.all(compact ? 11 : 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: StudioVisuals.line),
                      boxShadow: StudioVisuals.softShadow,
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
                            Icons.style_rounded,
                            color: skin.accent,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            _tracking
                                ? (english
                                      ? 'Follow the marked card through ${_scenario.cardCount} cards.'
                                      : 'İşaretli kartı ${_scenario.cardCount} kartın arasında izle.')
                                : _choosingLane
                                ? (english
                                      ? 'Which face-down card held the target?'
                                      : 'İşaretli hedef hangi kapalı kartta kaldı?')
                                : (english
                                      ? 'Study the marked picture. All cards turn over before the shuffle.'
                                      : 'İşaretli görseli aklında tut. Karıştırma başlamadan tüm kartlar kapanır.'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: StudioVisuals.ink,
                              fontSize: 11,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (_tracking)
                          _TunnelTag(
                            label:
                                _scenario
                                    .movements[math.min(
                                      _movementIndex,
                                      _scenario.movementCount - 1,
                                    )]
                                    .occluded
                                    ? (english ? 'SLOW' : 'YAVAŞ')
                                : (english ? 'SHUFFLE' : 'KARIŞTIR'),
                            tint: StudioVisuals.teal,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  _tunnelBoard(compact: compact, reduceMotion: reduceMotion),
                  if (_feedback != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _TunnelFeedback(
                      text: _feedback!,
                      positive: _lastCorrect ?? false,
                    ),
                  ],
                  const SizedBox(height: 9),
                  if (_solved)
                    FilledButton.icon(
                      key: const ValueKey<String>('attention_tunnel_finish'),
                      onPressed: _finish,
                      icon: const Icon(Icons.celebration_rounded),
                      label: Text(english ? 'CONTINUE' : 'DEVAM ET'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (_choosingLane)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          english ? 'Tap a card above to reveal your choice.' : 'Seçimini açmak için yukarıdaki kartlardan birine dokun.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        FilledButton.tonalIcon(
                          key: const ValueKey<String>('attention_tunnel_hint'),
                          onPressed: _session.acceptsInput ? _useHint : null,
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: Text(english ? 'HINT • 45' : 'İPUCU • 45'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 42),
                            foregroundColor: StudioVisuals.ink,
                          ),
                        ),
                      ],
                    )
                  else if (!_tracking)
                    FilledButton.icon(
                      key: const ValueKey<String>('attention_tunnel_start'),
                      onPressed: _startTracking,
                      icon: const Icon(Icons.shuffle_rounded),
                      label: Text(
                        english ? 'START SHUFFLE' : 'KARTLARI KARIŞTIR',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      key: const ValueKey<String>('attention_tunnel_live'),
                      onPressed: null,
                      icon: const Icon(Icons.visibility_rounded),
                      label: Text(
                        '${english ? 'SHUFFLING' : 'KARIŞTIRMA'} • $_movementIndex/${_scenario.movementCount}',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        foregroundColor: skin.accent,
                      ),
                    ),
                  if (_tracking) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      english
                          ? 'Every card back is identical. Follow the position that began marked.'
                          : 'Kartların arkası artık aynı. Başlangıçta işaretli olan konumu izle.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: StudioVisuals.muted,
                        fontSize: 11,
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

class _TunnelMetric extends StatelessWidget {
  const _TunnelMetric({
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
            fontFamily: 'Roboto',
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _TunnelTag extends StatelessWidget {
  const _TunnelTag({required this.label, required this.tint});

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
        fontFamily: 'Roboto',
        color: tint,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: .5,
      ),
    ),
  );
}

class _TunnelFeedback extends StatelessWidget {
  const _TunnelFeedback({required this.text, required this.positive});

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
          fontFamily: 'Roboto',
          color: tint,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
