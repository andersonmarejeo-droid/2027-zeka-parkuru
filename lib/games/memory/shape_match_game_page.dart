import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../services/replayability_service.dart';
import '../../widgets/advanced_result_banner.dart';

class ShapeMatchGamePage extends StatefulWidget {
  final int levelNumber;
  final int totalLevels;
  final int cardCount;
  final int stageCount;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const ShapeMatchGamePage({
    super.key,
    required this.levelNumber,
    required this.totalLevels,
    required this.cardCount,
    required this.stageCount,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  }) : assert(cardCount == 8 || cardCount == 16),
       assert(stageCount >= 1);

  @override
  State<ShapeMatchGamePage> createState() => _ShapeMatchGamePageState();
}

class _ShapeMatchGamePageState extends State<ShapeMatchGamePage> {
  final ReplayabilityService _replayability = ReplayabilityService();
  final GameAudioService _audio = GameAudioService.instance;

  static const List<_ShapeTheme> _shapeThemes = <_ShapeTheme>[
    _ShapeTheme(
      icon: Icons.circle_rounded,
      color: Color(0xFF00D9FF),
      nameTr: 'Daire',
      nameEn: 'Circle',
    ),
    _ShapeTheme(
      icon: Icons.change_history_rounded,
      color: Color(0xFFFFD93D),
      nameTr: 'Üçgen',
      nameEn: 'Triangle',
    ),
    _ShapeTheme(
      icon: Icons.stop_rounded,
      color: Color(0xFFFF6B6B),
      nameTr: 'Kare',
      nameEn: 'Square',
    ),
    _ShapeTheme(
      icon: Icons.star_rounded,
      color: Color(0xFFB06CFF),
      nameTr: 'Yıldız',
      nameEn: 'Star',
    ),
    _ShapeTheme(
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF4F9A),
      nameTr: 'Kalp',
      nameEn: 'Heart',
    ),
    _ShapeTheme(
      icon: Icons.bolt_rounded,
      color: Color(0xFFFF9F1C),
      nameTr: 'Şimşek',
      nameEn: 'Bolt',
    ),
    _ShapeTheme(
      icon: Icons.hexagon_rounded,
      color: Color(0xFF52E86B),
      nameTr: 'Altıgen',
      nameEn: 'Hexagon',
    ),
    _ShapeTheme(
      icon: Icons.diamond_rounded,
      color: Color(0xFF4D7CFE),
      nameTr: 'Elmas',
      nameEn: 'Diamond',
    ),
  ];

  List<_ShapeCardData> cards = <_ShapeCardData>[];
  final List<int> openedCards = <int>[];
  final Set<int> matchedCards = <int>{};
  final Set<int> wrongCards = <int>{};

  Timer? _timer;
  int _sessionGeneration = 0;
  int attempts = 0;
  int pairsFound = 0;
  int wrongAttempts = 0;
  int elapsedSeconds = 0;
  int currentStage = 1;

  bool preparing = true;
  bool previewing = false;
  bool inputLocked = true;
  bool completed = false;

  String statusTr = 'Kartlar hazırlanıyor...';
  String statusEn = 'Preparing the cards...';

  int get pairCount => widget.cardCount ~/ 2;
  bool get isLargeBoard => widget.cardCount == 16;

  @override
  void initState() {
    super.initState();
    unawaited(_audio.preload(GameAudioGroup.memory));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_startNewGame()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startNewGame() async {
    final int generation = ++_sessionGeneration;
    _timer?.cancel();

    if (mounted) {
      setState(() {
        cards = <_ShapeCardData>[];
        openedCards.clear();
        matchedCards.clear();
        wrongCards.clear();
        attempts = 0;
        pairsFound = 0;
        wrongAttempts = 0;
        elapsedSeconds = 0;
        currentStage = 1;
        preparing = true;
        previewing = false;
        inputLocked = true;
        completed = false;
        statusTr = 'Kartlar hazırlanıyor...';
        statusEn = 'Preparing the cards...';
      });
    }

    await _prepareStage(generation);
  }

  Future<void> _prepareStage(int generation) async {
    if (!mounted || generation != _sessionGeneration) return;

    setState(() {
      cards = <_ShapeCardData>[];
      openedCards.clear();
      matchedCards.clear();
      wrongCards.clear();
      pairsFound = 0;
      preparing = true;
      previewing = false;
      inputLocked = true;
      statusTr = '$currentStage. aşama hazırlanıyor...';
      statusEn = 'Preparing stage $currentStage...';
    });

    final List<_ShapeCardData> newDeck = await _createNonRepeatingDeck(
      currentStage,
    );

    if (!mounted || generation != _sessionGeneration) return;

    setState(() {
      cards = newDeck;
      preparing = false;
      previewing = true;
      statusTr =
          'Aşama $currentStage/${widget.stageCount} • '
          'şekillerin yerini dikkatle incele.';
      statusEn =
          'Stage $currentStage/${widget.stageCount} • '
          'study the positions of the shapes.';
    });

    unawaited(_audio.play(GameSound.memoryRoundStart));
    _audio.hapticSelection();

    await Future<void>.delayed(
      Duration(milliseconds: isLargeBoard ? 1900 : 1450),
    );

    if (!mounted || generation != _sessionGeneration) return;

    setState(() {
      previewing = false;
      inputLocked = false;
      statusTr = 'Aşama $currentStage/${widget.stageCount} • ilk kartı seç.';
      statusEn =
          'Stage $currentStage/${widget.stageCount} • '
          'choose the first card.';
    });

    if (!(_timer?.isActive ?? false)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted ||
            completed ||
            preparing ||
            previewing ||
            generation != _sessionGeneration) {
          return;
        }
        setState(() => elapsedSeconds++);
      });
    }
  }

  Future<List<_ShapeCardData>> _createNonRepeatingDeck(int stage) async {
    final int sessionSeed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'memory_shape_match',
          level: widget.levelNumber,
        );

    List<int> pairIds = <int>[];

    for (int attempt = 0; attempt < 12; attempt++) {
      final Random random = _replayability.randomFor(
        sessionSeed: sessionSeed,
        round: stage * 100 + attempt,
        salt: widget.cardCount * 19 + stage * 97,
      );

      pairIds = <int>[
        for (int pair = 0; pair < pairCount; pair++) pair,
        for (int pair = 0; pair < pairCount; pair++) pair,
      ]..shuffle(random);

      final String fingerprint = pairIds.join('-');
      final bool isNew =
          widget.fixedSessionSeed != null ||
          await _replayability.registerFingerprint(
            gameId: 'memory_shape_match',
            level: widget.levelNumber,
            fingerprint: fingerprint,
            historyLimit: 150,
          );

      if (isNew) break;
    }

    return List<_ShapeCardData>.generate(
      pairIds.length,
      (index) => _ShapeCardData(id: index, pairId: pairIds[index]),
      growable: false,
    );
  }

  Future<void> _tapCard(int index) async {
    if (inputLocked ||
        previewing ||
        preparing ||
        completed ||
        index < 0 ||
        index >= cards.length ||
        openedCards.contains(index) ||
        matchedCards.contains(index)) {
      return;
    }

    final int generation = _sessionGeneration;

    setState(() {
      openedCards.add(index);
      wrongCards.clear();
      statusTr = openedCards.length == 1
          ? 'Şimdi eşini bul.'
          : 'Kartlar karşılaştırılıyor...';
      statusEn = openedCards.length == 1
          ? 'Now find its pair.'
          : 'Comparing the cards...';
    });

    unawaited(_audio.play(GameSound.memoryTap));
    _audio.hapticLight();

    if (openedCards.length < 2) return;

    inputLocked = true;
    attempts++;

    final int firstIndex = openedCards[0];
    final int secondIndex = openedCards[1];
    final bool isMatch = cards[firstIndex].pairId == cards[secondIndex].pairId;

    if (isMatch) {
      await Future<void>.delayed(const Duration(milliseconds: 230));

      if (!mounted || generation != _sessionGeneration) return;

      setState(() {
        matchedCards
          ..add(firstIndex)
          ..add(secondIndex);
        openedCards.clear();
        pairsFound++;
        statusTr = pairsFound == pairCount
            ? 'Bütün şekiller eşleşti!'
            : 'Harika! Yeni bir kart seç.';
        statusEn = pairsFound == pairCount
            ? 'All shapes are matched!'
            : 'Great! Choose a new card.';
      });

      unawaited(_audio.play(GameSound.memoryCorrect));
      _audio.hapticMedium();

      if (pairsFound == pairCount) {
        await _completeStage(generation);
      } else {
        setState(() => inputLocked = false);
      }
      return;
    }

    wrongAttempts++;
    setState(() {
      wrongCards
        ..add(firstIndex)
        ..add(secondIndex);
      statusTr = 'Bu şekiller farklı. Yerlerini hatırla.';
      statusEn = 'These shapes differ. Remember their positions.';
    });

    unawaited(_audio.play(GameSound.memoryWrong));
    _audio.hapticMedium();

    await Future<void>.delayed(const Duration(milliseconds: 720));

    if (!mounted || generation != _sessionGeneration) return;

    setState(() {
      openedCards.clear();
      wrongCards.clear();
      inputLocked = false;
      statusTr = 'Tekrar dene; ilk kartı seç.';
      statusEn = 'Try again; choose the first card.';
    });
  }

  Future<void> _completeStage(int generation) async {
    if (!mounted || completed || generation != _sessionGeneration) {
      return;
    }

    if (currentStage < widget.stageCount) {
      setState(() {
        inputLocked = true;
        preparing = true;
        statusTr =
            '$currentStage. aşama tamamlandı! '
            'Yeni deste hazırlanıyor...';
        statusEn =
            'Stage $currentStage complete! '
            'Preparing a new deck...';
      });
      unawaited(_audio.play(GameSound.memoryStreak));
      _audio.hapticMedium();

      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted || generation != _sessionGeneration) return;

      setState(() => currentStage++);
      await _prepareStage(generation);
      return;
    }

    completed = true;
    inputLocked = true;
    _timer?.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (mounted && generation == _sessionGeneration) {
      await _showResult();
    }
  }

  int _calculateStars() {
    final int extraAttempts = attempts - pairCount * widget.stageCount;

    if (isLargeBoard) {
      if (extraAttempts <= 2 * widget.stageCount) return 3;
      if (extraAttempts <= 6 * widget.stageCount) return 2;
      return 1;
    }

    if (extraAttempts <= widget.stageCount) return 3;
    if (extraAttempts <= 3 * widget.stageCount) return 2;
    return 1;
  }

  int _calculateScore(int stars) {
    final int baseScore = (isLargeBoard ? 5200 : 3000) * widget.stageCount;
    final int mistakePenalty = wrongAttempts * (isLargeBoard ? 180 : 210);
    final int timePenalty = elapsedSeconds * (isLargeBoard ? 7 : 10);
    final int efficiencyBonus =
        max(
          0,
          pairCount * widget.stageCount + 5 * widget.stageCount - attempts,
        ) *
        45;

    return max(
      500,
      baseScore + stars * 500 + efficiencyBonus - mistakePenalty - timePenalty,
    );
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  Future<void> _showResult() async {
    final int stars = _calculateStars();
    final int score = _calculateScore(stars);
    final bool english = context.l10n.isEnglish;

    unawaited(_audio.playVictory(stars: stars, boss: false));
    _audio.hapticHeavy();

    if (widget.competitionMode) {
      Navigator.pop(
        context,
        ShapeMatchResult(
          completed: true,
          stars: stars,
          score: score,
          nextLevel: false,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF173D70), Color(0xFF382567)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFFD93D), width: 2),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x55745CFF), blurRadius: 28),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.style_rounded,
                    color: Color(0xFFFFD93D),
                    size: 52,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    english ? 'ALL PAIRS FOUND!' : 'BÜTÜN ÇİFTLER BULUNDU!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    english
                        ? '${widget.stageCount} stages • '
                              '${pairCount * widget.stageCount} pairs'
                        : '${widget.stageCount} aşama • '
                              '${pairCount * widget.stageCount} çift',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AdvancedResultBanner(
                    score: score,
                    previousBestScore: widget.previousBestScore,
                    english: english,
                    accentColor: const Color(0xFFB06CFF),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      3,
                      (index) => Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFFFD93D),
                        size: 39,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ShapeResultBox(
                          label: context.l10n.gameUi(
                            english ? 'ATTEMPTS' : 'HAMLE',
                          ),
                          value: '$attempts',
                          icon: Icons.touch_app_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ShapeResultBox(
                          label: context.l10n.gameUi(english ? 'TIME' : 'SÜRE'),
                          value: _formatTime(elapsedSeconds),
                          icon: Icons.timer_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ShapeResultBox(
                          label: context.l10n.gameUi(
                            english ? 'SCORE' : 'PUAN',
                          ),
                          value: '$score',
                          icon: Icons.bolt_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF745CFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.pop(
                          context,
                          ShapeMatchResult(
                            completed: true,
                            stars: stars,
                            score: score,
                            nextLevel: widget.levelNumber < widget.totalLevels,
                          ),
                        );
                      },
                      icon: Icon(
                        widget.levelNumber < widget.totalLevels
                            ? Icons.arrow_forward_rounded
                            : Icons.workspace_premium_rounded,
                      ),
                      label: Text(
                        context.l10n.gameUi(
                          widget.levelNumber < widget.totalLevels
                              ? english
                                    ? 'NEXT LEVEL'
                                    : 'SONRAKİ SEVİYE'
                              : english
                              ? 'FINISH MEMORY COURSE'
                              : 'HAFIZA PARKURUNU TAMAMLA',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(
                        context,
                        ShapeMatchResult(
                          completed: true,
                          stars: stars,
                          score: score,
                          nextLevel: false,
                        ),
                      );
                    },
                    child: Text(
                      context.l10n.gameUi(
                        english ? 'LEVEL LIST' : 'BÖLÜM LİSTESİ',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    final String status = english ? statusEn : statusTr;

    return Scaffold(
      backgroundColor: const Color(0xFF06152B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.gameUi(
                isLargeBoard
                    ? english
                          ? 'GRAND MATCHING'
                          : 'BÜYÜK EŞLEŞTİRME'
                    : english
                    ? 'SHAPE MATCHING'
                    : 'ŞEKİL EŞLEŞTİRME',
              ),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              english
                  ? 'Level ${widget.levelNumber}/${widget.totalLevels} • '
                        'Stage $currentStage/${widget.stageCount}'
                  : 'Seviye ${widget.levelNumber}/${widget.totalLevels} • '
                        'Aşama $currentStage/${widget.stageCount}',
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.gameUi(
              english ? 'Restart' : 'Yeniden başlat',
            ),
            onPressed: completed ? null : () => unawaited(_startNewGame()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ShapeMatchBackgroundPainter()),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: max(
                        0.0,
                        constraints.maxHeight - 26,
                      ).toDouble(),
                    ),
                    child: Column(
                      children: <Widget>[
                        _ShapeMatchStats(
                          attempts: attempts,
                          pairsFound:
                              (currentStage - 1) * pairCount + pairsFound,
                          pairCount: pairCount * widget.stageCount,
                          elapsed: _formatTime(elapsedSeconds),
                          english: english,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: pairCount == 0
                                ? 0
                                : ((currentStage - 1) * pairCount +
                                          pairsFound) /
                                      (pairCount * widget.stageCount),
                            minHeight: 7,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF52E86B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 11),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: previewing
                                ? const Color(0x3300D9FF)
                                : wrongCards.isNotEmpty
                                ? const Color(0x33FF5E57)
                                : const Color(0x22745CFF),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: previewing
                                  ? const Color(0x8800D9FF)
                                  : wrongCards.isNotEmpty
                                  ? const Color(0x99FF5E57)
                                  : const Color(0x66745CFF),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                previewing
                                    ? Icons.visibility_rounded
                                    : wrongCards.isNotEmpty
                                    ? Icons.refresh_rounded
                                    : Icons.psychology_alt_rounded,
                                color: previewing
                                    ? const Color(0xFF00D9FF)
                                    : wrongCards.isNotEmpty
                                    ? const Color(0xFFFF7474)
                                    : const Color(0xFFFFD93D),
                                size: 21,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (preparing)
                          const SizedBox(
                            height: 260,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 470),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      Color(0xFF122E52),
                                      Color(0xFF0B203D),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0x44745CFF),
                                  ),
                                  boxShadow: const <BoxShadow>[
                                    BoxShadow(
                                      color: Color(0x3300D9FF),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cards.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 0.84,
                                      ),
                                  itemBuilder: (context, index) {
                                    final _ShapeCardData card = cards[index];
                                    final bool isMatched = matchedCards
                                        .contains(index);
                                    final bool faceUp =
                                        previewing ||
                                        openedCards.contains(index) ||
                                        isMatched;

                                    return _ShapeMatchCard(
                                      key: ValueKey<String>(
                                        '${currentStage}_${card.id}',
                                      ),
                                      theme: _shapeThemes[card.pairId],
                                      faceUp: faceUp,
                                      matched: isMatched,
                                      wrong: wrongCards.contains(index),
                                      compact: isLargeBoard,
                                      english: english,
                                      onTap: () => _tapCard(index),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.touch_app_rounded,
                              color: Colors.white38,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                english
                                    ? 'Open two cards and find identical shapes.'
                                    : 'İki kart aç ve aynı şekilleri eşleştir.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeMatchCard extends StatelessWidget {
  final _ShapeTheme theme;
  final bool faceUp;
  final bool matched;
  final bool wrong;
  final bool compact;
  final bool english;
  final VoidCallback onTap;

  const _ShapeMatchCard({
    super.key,
    required this.theme,
    required this.faceUp,
    required this.matched,
    required this.wrong,
    required this.compact,
    required this.english,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: faceUp
          ? english
                ? '${theme.nameEn} card'
                : '${theme.nameTr} kartı'
          : english
          ? 'Closed card'
          : 'Kapalı kart',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutBack,
          scale: wrong
              ? 0.93
              : matched
              ? 0.97
              : 1,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: faceUp ? 1 : 0),
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              final double angle = value * pi;
              final bool showFront = value >= 0.5;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0014)
                  ..rotateY(angle),
                child: showFront
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(pi),
                        child: _buildFront(context),
                      )
                    : _buildBack(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    final Color borderColor = wrong
        ? const Color(0xFFFF5E57)
        : matched
        ? const Color(0xFF76FF8A)
        : theme.color;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(theme.color, Colors.white, 0.25)!,
            theme.color.withValues(alpha: 0.86),
            Color.lerp(
              theme.color,
              Theme.of(context).scaffoldBackgroundColor,
              0.48,
            )!,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 17),
        border: Border.all(
          color: borderColor,
          width: wrong || matched ? 2.4 : 1.6,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: borderColor.withValues(alpha: matched ? 0.55 : 0.32),
            blurRadius: matched ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Center(
            child: Icon(
              theme.icon,
              color: Colors.white,
              size: compact ? 33 : 42,
              shadows: const <Shadow>[
                Shadow(
                  color: Colors.black38,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          if (matched)
            const Positioned(
              top: 5,
              right: 5,
              child: Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFB9FFC3),
                size: 17,
              ),
            ),
          if (wrong)
            const Positioned(
              top: 5,
              right: 5,
              child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF263F73),
            Color(0xFF162C55),
            Color(0xFF10213F),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 17),
        border: Border.all(color: const Color(0x66745CFF), width: 1.4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black26, blurRadius: 7, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: const _CardBackPainter()),
          ),
          Container(
            width: compact ? 34 : 43,
            height: compact ? 34 : 43,
            decoration: BoxDecoration(
              color: const Color(0x22745CFF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x88745CFF)),
            ),
            child: Icon(
              Icons.psychology_alt_rounded,
              color: const Color(0xFFB9AEFF),
              size: compact ? 23 : 29,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeMatchStats extends StatelessWidget {
  final int attempts;
  final int pairsFound;
  final int pairCount;
  final String elapsed;
  final bool english;

  const _ShapeMatchStats({
    required this.attempts,
    required this.pairsFound,
    required this.pairCount,
    required this.elapsed,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ShapeStatBox(
            label: context.l10n.gameUi(english ? 'ATTEMPTS' : 'HAMLE'),
            value: '$attempts',
            icon: Icons.touch_app_rounded,
            color: const Color(0xFF00D9FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ShapeStatBox(
            label: context.l10n.gameUi(english ? 'PAIRS' : 'ÇİFT'),
            value: '$pairsFound / $pairCount',
            icon: Icons.style_rounded,
            color: const Color(0xFF52E86B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ShapeStatBox(
            label: context.l10n.gameUi(english ? 'TIME' : 'SÜRE'),
            value: elapsed,
            icon: Icons.timer_outlined,
            color: const Color(0xFFFFD93D),
          ),
        ),
      ],
    );
  }
}

class _ShapeStatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ShapeStatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF102A4A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w800,
                    fontSize: 7,
                    letterSpacing: 0.4,
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

class _ShapeResultBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ShapeResultBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF00D9FF), size: 19),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeMatchBackgroundPainter extends CustomPainter {
  const _ShapeMatchBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dotPaint = Paint()..color = const Color(0x1000D9FF);
    const double step = 27;

    for (double x = 10; x < size.width; x += step) {
      for (double y = 10; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }

    final Paint glowPaint = Paint()
      ..shader =
          const RadialGradient(
            colors: <Color>[Color(0x22745CFF), Color(0x0007162E)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.55),
              radius: size.width * 0.72,
            ),
          );

    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ShapeMatchBackgroundPainter oldDelegate) =>
      false;
}

class _CardBackPainter extends CustomPainter {
  const _CardBackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x16745CFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double step = 13;
    for (double offset = -size.height; offset < size.width; offset += step) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardBackPainter oldDelegate) => false;
}

class _ShapeTheme {
  final IconData icon;
  final Color color;
  final String nameTr;
  final String nameEn;

  const _ShapeTheme({
    required this.icon,
    required this.color,
    required this.nameTr,
    required this.nameEn,
  });
}

class _ShapeCardData {
  final int id;
  final int pairId;

  const _ShapeCardData({required this.id, required this.pairId});
}

class ShapeMatchResult {
  final bool completed;
  final int stars;
  final int score;
  final bool nextLevel;

  const ShapeMatchResult({
    required this.completed,
    required this.stars,
    required this.score,
    required this.nextLevel,
  });
}
