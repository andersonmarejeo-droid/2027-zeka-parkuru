import 'dart:math';

import '../../services/replayability_service.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/daily_course_service.dart';
import '../../services/game_audio_service.dart';
import '../../services/common_level_score_service.dart';
import '../../theme/studio_visuals.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/studio_chapter_card.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/advanced_result_banner.dart';
import '../../services/local_progress_service.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/game_instruction_catalog.dart';

abstract final class _BlockNeon {
  static const Color background = Color(0xFF080D22);
  static const Color board = Color(0xFF101936);
  static const Color panel = Color(0xFF151F40);
  static const Color panelRaised = Color(0xFF1D2A52);
  static const Color emptyCell = Color(0xFF202D50);
  static const Color line = Color(0xFF35456F);
  static const Color text = Color(0xFFF4F7FF);
  static const Color muted = Color(0xFFBCC8E8);
  // The play pieces use a rich, material-like palette inspired by the
  // reference block set. Keep the interface accents separate so the board
  // remains readable without the pieces looking fluorescent.
  static const Color cyan = Color(0xFF148FA7);
  static const Color violet = Color(0xFF7C58AF);
  static const Color pink = Color(0xFFD94A56);
  static const Color orange = Color(0xFFE6A12B);
  static const Color lime = Color(0xFF82A64F);
  static const Color green = Color(0xFF4D9964);
  static const Color red = Color(0xFFD94445);
  static const Color blockBlue = Color(0xFF2D6FB0);
  static const Color blockOrange = Color(0xFFE2752C);

  static const List<Color> pieces = <Color>[
    pink,
    orange,
    blockBlue,
    green,
    violet,
    cyan,
    blockOrange,
  ];
}

class BlockGamePage extends StatefulWidget {
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const BlockGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  @override
  State<BlockGamePage> createState() => _BlockGamePageState();
}

class _BlockGamePageState extends State<BlockGamePage> {
  final LocalProgressService _progressService = LocalProgressService();

  bool yukleniyor = true;
  int acikSeviye = 1;

  List<int> yildizlar = List<int>.filled(GameContentPolicy.campaignLevels, 0);
  List<int> enIyiPuanlar = List<int>.filled(
    GameContentPolicy.campaignLevels,
    0,
  );
  bool _competitionOpened = false;

  final List<BlockLevel> _nativeLevels = const [
    BlockLevel(
      number: 1,
      title: 'Blok Başlangıç',
      difficulty: 'KOLAY',
      targetScore: 3800,
      targetLines: 15,
      targetMoves: 110,
    ),
    BlockLevel(
      number: 2,
      title: 'Renk Patlaması',
      difficulty: 'KOLAY',
      targetScore: 5800,
      targetLines: 22,
      targetMoves: 135,
    ),
    BlockLevel(
      number: 3,
      title: 'Çift Çizgi',
      difficulty: 'ORTA',
      targetScore: 8200,
      targetLines: 30,
      targetMoves: 165,
    ),
    BlockLevel(
      number: 4,
      title: 'Combo Avı',
      difficulty: 'ORTA',
      targetScore: 11000,
      targetLines: 38,
      targetCombo: 2,
      targetMoves: 200,
    ),
    BlockLevel(
      number: 5,
      title: 'Dar Alan',
      difficulty: 'ZOR',
      targetScore: 14500,
      targetLines: 46,
      targetMoves: 235,
    ),
    BlockLevel(
      number: 6,
      title: 'Hız Turu',
      difficulty: 'KOLAY',
      targetScore: 18000,
      targetLines: 54,
      targetMoves: 270,
    ),
    BlockLevel(
      number: 7,
      title: 'Zincir Ustası',
      difficulty: 'ORTA',
      targetScore: 22000,
      targetLines: 62,
      targetCombo: 2,
      targetMoves: 310,
    ),
    BlockLevel(
      number: 8,
      title: 'Mega Temizleme',
      difficulty: 'ZOR',
      targetScore: 26500,
      targetLines: 70,
      targetCombo: 2,
      targetMoves: 350,
    ),
    BlockLevel(
      number: 9,
      title: 'Blok Fırtınası',
      difficulty: 'ZOR',
      targetScore: 32000,
      targetLines: 80,
      targetCombo: 2,
      targetMoves: 400,
    ),
    BlockLevel(
      number: 10,
      title: 'Blok Boss',
      difficulty: 'BOSS',
      targetScore: 38500,
      targetLines: 95,
      targetCombo: 3,
      targetMoves: 460,
    ),
  ];

  final ScrollController _scrollController = ScrollController();
  late List<BlockLevel> seviyeler;

  List<BlockLevel> _generateLevels(int targetLevel) {
    final int count = targetLevel >= 26
        ? max(GameContentPolicy.campaignLevels, targetLevel + 5)
        : GameContentPolicy.campaignLevels;
    final stages = _nativeLevels.length;
    return List.generate(
      count,
      (index) {
        final chapter = index + 1;
        final source = GameContentPolicy.nativeLevel(chapter, stages: stages);
        final base = _nativeLevels[(source - 1).clamp(0, stages - 1)];
        final int extraChapters = max(0, chapter - GameContentPolicy.campaignLevels);
        final int extraTier = extraChapters == 0 ? 0 : (extraChapters - 1) ~/ 3 + 1;
        return BlockLevel(
          number: chapter,
          sourceNumber: base.number,
          difficulty: GameContentPolicy.difficulty(chapter),
          title: extraChapters > 0
              ? '${base.title} • Faz $extraChapters'
              : base.title,
          targetScore: base.targetScore + extraTier * 1500,
          targetLines: base.targetLines + extraTier * 4,
          targetCombo: extraChapters >= 10
              ? max(base.targetCombo, 3)
              : base.targetCombo,
          targetMoves: base.targetMoves + extraTier * 16,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    seviyeler = _generateLevels(acikSeviye);
    ilerlemeyiYukle();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> ilerlemeyiYukle() async {
    final BlockProgressData veri = await _progressService
        .blokIlerlemesiniYukle();

    if (!mounted) return;

    final nextLevels = _generateLevels(veri.acikSeviye);
    final nextStars = List<int>.from(veri.yildizlar);
    final nextScores = List<int>.from(veri.enIyiPuanlar);
    while (nextStars.length < nextLevels.length) {
      nextStars.add(0);
    }
    while (nextScores.length < nextLevels.length) {
      nextScores.add(0);
    }

    setState(() {
      acikSeviye = veri.acikSeviye;
      seviyeler = nextLevels;
      yildizlar = nextStars;
      enIyiPuanlar = nextScores;
      yukleniyor = false;
    });

    _openCompetitionLevelIfNeeded();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (acikSeviye > 2) {
        final double targetOffset = (acikSeviye - 2) * 110.0;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _openCompetitionLevelIfNeeded() {
    final int? level = widget.competitionLevel;
    if (_competitionOpened || level == null) return;
    _competitionOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      seviyeAc((level - 1).clamp(0, seviyeler.length - 1).toInt());
    });
  }

  Future<void> ilerlemeyiKaydet() async {
    await _progressService.blokIlerlemesiniKaydet(
      acikSeviye: acikSeviye,
      yildizlar: yildizlar,
      enIyiPuanlar: enIyiPuanlar,
    );
  }

  int get toplamYildiz => yildizlar.fold(0, (a, b) => a + b);

  int get toplamPuan => enIyiPuanlar.fold(0, (a, b) => a + b);

  Future<void> seviyeAc(int index) async {
    if (widget.competitionLevel == null && index + 1 > acikSeviye) return;

    GameAudioService.instance.play(GameSound.uiClick);

    final List<int> previousStars = List<int>.from(yildizlar);
    final CommonLevelScoreSession scoring = CommonLevelScoreSession.begin();
    final BlockLevelResult? sonuc;
    try {
      sonuc = await Navigator.push<BlockLevelResult>(
        context,
        MaterialPageRoute(
          builder: (_) => BlockPlayPage(
            level: seviyeler[index],
            totalLevels: seviyeler.length,
            previousBestScore: enIyiPuanlar[index],
            fixedSessionSeed: widget.competitionLayoutCode,
            competitionMode: widget.competitionLevel != null,
          ),
        ),
      );
    } finally {
      scoring.finish();
    }
    final int commonPoints = scoring.points;

    if (!mounted) return;

    if (widget.dailyCourseMode) {
      Navigator.pop(
        context,
        sonuc == null
            ? const DailyStageResult.exited(gameId: 'blocks')
            : sonuc.completed
            ? DailyStageResult.completed(
                gameId: 'blocks',
                stars: sonuc.stars,
                rawScore: commonPoints,
              )
            : const DailyStageResult.failed(gameId: 'blocks'),
      );
      return;
    }

    if (sonuc == null || !sonuc.completed) {
      if (widget.competitionLevel != null && mounted) {
        Navigator.pop(context);
      }
      return;
    }
    final BlockLevelResult completedResult = sonuc;

    if (widget.competitionLevel != null) {
      Navigator.pop(
        context,
        DailyCourseGameResult(
          gameId: 'blocks',
          stars: completedResult.stars,
          score: commonPoints,
        ),
      );
      return;
    }

    setState(() {
      yildizlar[index] = max(yildizlar[index], completedResult.stars);

      enIyiPuanlar[index] = max(enIyiPuanlar[index], completedResult.score);

      if (index + 1 == acikSeviye) {
        acikSeviye++;
        if (acikSeviye + 3 >= seviyeler.length) {
          seviyeler = _generateLevels(acikSeviye);
          while (yildizlar.length < seviyeler.length) {
            yildizlar.add(0);
          }
          while (enIyiPuanlar.length < seviyeler.length) {
            enIyiPuanlar.add(0);
          }
        }
      }
    });

    await ilerlemeyiKaydet();
    await CommonLevelScoreStore.recordBest(
      gameId: 'blocks',
      levelIndex: index,
      points: commonPoints,
      levelCount: seviyeler.length,
      completedStars: previousStars,
    );

    await DailyChallengeService.instance.recordLevelCompleted(
      gameId: 'blocks',
      stars: completedResult.stars,
      score: commonPoints,
    );

    if (completedResult.nextLevel && mounted) {
      await Future.delayed(const Duration(milliseconds: 180));

      if (mounted) {
        if (index + 1 >= seviyeler.length) {
          setState(() {
            seviyeler = _generateLevels(index + 2);
            while (yildizlar.length < seviyeler.length) {
              yildizlar.add(0);
            }
            while (enIyiPuanlar.length < seviyeler.length) {
              enIyiPuanlar.add(0);
            }
          });
        }
        seviyeAc(index + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor || widget.competitionLevel != null) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              'BLOK FIRTINASI',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            LText(
              'Sürükle • Yerleştir • Patlat',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints limits) {
              final bool compact = limits.maxWidth < 360;
              final bool isLandscape = limits.maxWidth > limits.maxHeight;

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: _ProgressPanel(
                            score: toplamPuan,
                            stars: toplamYildiz,
                            level: acikSeviye,
                          ),
                        ),
                        if (acikSeviye <= seviyeler.length)
                          _BlockQuickResumeCard(
                            levelNumber: acikSeviye,
                            levelTitle: seviyeler[acikSeviye - 1].title,
                            difficulty: seviyeler[acikSeviye - 1].difficulty,
                            onPlay: () => seviyeAc(acikSeviye - 1),
                          ),
                        GameInstructionCard(
                          gameId: 'blocks',
                          english: context.l10n.isEnglish,
                          initiallyExpanded: false,
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isLandscape ? 2 : 1,
                        crossAxisSpacing: compact ? 10 : 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent:
                            104 *
                            MediaQuery.textScalerOf(context)
                                .scale(1)
                                .clamp(1.0, 1.6),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _LevelCard(
                            level: seviyeler[index],
                            unlocked: index + 1 <= acikSeviye,
                            stars: yildizlar[index],
                            bestScore: enIyiPuanlar[index],
                            onTap: () => seviyeAc(index),
                          );
                        },
                        childCount: seviyeler.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class BlockPlayPage extends StatefulWidget {
  final BlockLevel level;
  final int totalLevels;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const BlockPlayPage({
    super.key,
    required this.level,
    required this.totalLevels,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<BlockPlayPage> createState() => _BlockPlayPageState();
}

class _BlockPlayPageState extends State<BlockPlayPage> {
  static const int boardSize = 8;
  static const double boardGap = 3;

  // Parça parmağın altında gizlenmesin.
  static const double fingerLift = 120;

  Random random = Random();
  final ReplayabilityService _replayability = ReplayabilityService();
  final GameAudioService _audio = GameAudioService.instance;

  int sessionSeed = 0;

  final GlobalKey _boardGridKey = GlobalKey();

  late List<List<Color?>> board;
  late List<GamePiece?> pieces;

  int score = 0;
  int moves = 0;
  int clearedLines = 0;
  int combo = 0;
  int bestCombo = 0;

  bool get _scoreMissionCompleted => score >= widget.level.targetScore;

  bool get _lineMissionCompleted => clearedLines >= widget.level.targetLines;

  bool get _comboMissionCompleted => bestCombo >= widget.level.targetCombo;

  bool get _allMissionsCompleted =>
      _scoreMissionCompleted && _lineMissionCompleted && _comboMissionCompleted;

  int? selectedPieceIndex;

  bool processing = false;
  bool completed = false;

  Set<String> clearingCells = {};
  Set<String> poppingCells = {};

  int burstSeed = 0;
  bool showBurst = false;
  bool showFlash = false;

  String floatingText = '';
  bool showFloatingText = false;

  bool dragging = false;
  int? draggingIndex;
  GamePiece? draggingPiece;

  BlockCell grabbedCell = const BlockCell(0, 0);

  Offset dragGlobalPosition = Offset.zero;
  Offset dragPointerStart = Offset.zero;
  Offset dragVirtualStart = Offset.zero;

  // Parmağın 0.7 birim hareketi, bloğu yaklaşık 1 birim hareket ettirir.
  static const double dragSensitivity = 1.43;

  int? hoverRow;
  int? hoverCol;
  bool hoverValid = false;

  // Yalnızca bırakma sonrasında gerçekten temizlenecek yatay/dikey
  // hatları içerir. Gerçek tahta veya skor bu önizlemede değiştirilmez.
  Set<String> _lineClearPreviewCells = <String>{};

  double boardCellSize = 38;

  OverlayEntry? _dragOverlay;

  final List<Color> blockColors = _BlockNeon.pieces;

  @override
  void initState() {
    super.initState();

    _audio.preload(GameAudioGroup.blocks);
    _audio.playMusic(GameMusic.calm);

    if (widget.level.contentLevel == 10) {
      _audio.play(GameSound.bossIntro);
    }

    board = _emptyBoard();
    pieces = _generateThreePieces();

    _initializeReplaySession();
  }

  Future<void> _initializeReplaySession() async {
    sessionSeed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'blocks',
          level: widget.level.number,
        );

    random = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: 0,
      salt: 71,
    );

    if (!mounted) return;

    setState(() {
      board = _scenarioBoard();
      pieces = _generateThreePieces();
    });
    if (widget.fixedSessionSeed == null) {
      await _replayability.registerFingerprint(
        gameId: 'blocks',
        level: widget.level.number,
        fingerprint: _scenarioFingerprint(),
        historyLimit: 100,
      );
    }
  }

  @override
  void dispose() {
    _removeDragOverlay();
    _audio.stopMusic();
    super.dispose();
  }

  List<List<Color?>> _emptyBoard() {
    return List.generate(
      boardSize,
      (_) => List<Color?>.filled(boardSize, null),
    );
  }

  List<List<Color?>> _scenarioBoard() {
    final List<List<Color?>> result = _emptyBoard();
    if (widget.level.contentLevel < 5) return result;

    final int fillTarget = min(22, 5 + widget.level.number * 2);
    final List<int> cells = List<int>.generate(
      boardSize * boardSize,
      (int index) => index,
    )..shuffle(random);
    final List<int> rowCounts = List<int>.filled(boardSize, 0);
    final List<int> columnCounts = List<int>.filled(boardSize, 0);
    int filled = 0;
    for (final int cell in cells) {
      if (filled >= fillTarget) break;
      final int row = cell ~/ boardSize;
      final int column = cell % boardSize;
      if (rowCounts[row] >= 5 || columnCounts[column] >= 5) continue;
      result[row][column] = blockColors[random.nextInt(blockColors.length)];
      rowCounts[row]++;
      columnCounts[column]++;
      filled++;
    }
    return result;
  }

  String _scenarioFingerprint() {
    final String geometry = board
        .expand((List<Color?> row) => row)
        .map((Color? cell) => cell == null ? '0' : '1')
        .join();
    final String flow = pieces
        .whereType<GamePiece>()
        .map((GamePiece piece) {
          final List<String> cells =
              piece.cells
                  .map((BlockCell cell) => '${cell.x},${cell.y}')
                  .toList(growable: true)
                ..sort();
          return cells.join(';');
        })
        .join('/');
    return '$geometry|$flow';
  }

  List<GamePiece?> _generateThreePieces() {
    return List<GamePiece?>.generate(3, (_) {
      GamePiece piece = _randomPiece();
      for (
        int attempt = 0;
        attempt < 40 && !_pieceHasPlacement(piece);
        attempt++
      ) {
        piece = _randomPiece();
      }
      if (!_pieceHasPlacement(piece)) {
        piece = GamePiece(
          cells: const <BlockCell>[BlockCell(0, 0)],
          color: blockColors[random.nextInt(blockColors.length)],
        );
      }
      return piece;
    });
  }

  bool _pieceHasPlacement(GamePiece piece) {
    for (int row = 0; row < boardSize; row++) {
      for (int column = 0; column < boardSize; column++) {
        if (canPlace(piece, row, column)) return true;
      }
    }
    return false;
  }

  GamePiece _randomPiece() {
    // 3x3 dolu kare blok
    const piece3x3 = [
      BlockCell(0, 0), BlockCell(0, 1), BlockCell(0, 2),
      BlockCell(1, 0), BlockCell(1, 1), BlockCell(1, 2),
      BlockCell(2, 0), BlockCell(2, 1), BlockCell(2, 2),
    ];

    // 3x2 ve 2x3 dolu dikdörtgen bloklar
    const piece3x2 = [
      BlockCell(0, 0), BlockCell(0, 1),
      BlockCell(1, 0), BlockCell(1, 1),
      BlockCell(2, 0), BlockCell(2, 1),
    ];
    const piece2x3 = [
      BlockCell(0, 0), BlockCell(0, 1), BlockCell(0, 2),
      BlockCell(1, 0), BlockCell(1, 1), BlockCell(1, 2),
    ];

    // 2x2 dolu kare
    const piece2x2 = [
      BlockCell(0, 0), BlockCell(0, 1),
      BlockCell(1, 0), BlockCell(1, 1),
    ];

    // Kolay tekli ve çubuk parçalar
    const piece1x1 = [BlockCell(0, 0)];
    const piece2x1 = [BlockCell(0, 0), BlockCell(1, 0)];
    const piece1x2 = [BlockCell(0, 0), BlockCell(0, 1)];
    const piece3x1 = [BlockCell(0, 0), BlockCell(1, 0), BlockCell(2, 0)];
    const piece1x3 = [BlockCell(0, 0), BlockCell(0, 1), BlockCell(0, 2)];
    const pieceCorner = [BlockCell(0, 0), BlockCell(1, 0), BlockCell(0, 1)];

    // Bolca gelmesi istenen kolay şekiller ve 3x2, 2x3, 3x3 bloklar havuzu
    final List<List<BlockCell>> kolayVeFavori = [
      piece3x2,
      piece3x2,
      piece3x2, // 3*2 bloklar bolca
      piece2x3,
      piece2x3,
      piece2x3, // 2*3 bloklar bolca
      piece3x3,
      piece3x3, // 3*3 bloklar bolca
      piece2x2,
      piece2x2,
      piece1x1,
      piece1x1,
      piece2x1,
      piece1x2,
      piece3x1,
      piece1x3,
      pieceCorner,
    ];

    final List<List<BlockCell>> cesitlilikSekilleri = [
      // 4'lü çubuklar
      const [BlockCell(0, 0), BlockCell(1, 0), BlockCell(2, 0), BlockCell(3, 0)],
      const [BlockCell(0, 0), BlockCell(0, 1), BlockCell(0, 2), BlockCell(0, 3)],
      // T ve L şekilleri
      const [BlockCell(0, 0), BlockCell(1, 0), BlockCell(2, 0), BlockCell(1, 1)],
      const [BlockCell(0, 0), BlockCell(0, 1), BlockCell(0, 2), BlockCell(1, 2)],
      const [BlockCell(1, 0), BlockCell(0, 1), BlockCell(1, 1), BlockCell(2, 1)],
      const [BlockCell(0, 0), BlockCell(1, 0), BlockCell(2, 0), BlockCell(2, 1)],
      const [BlockCell(0, 0), BlockCell(0, 1), BlockCell(1, 0)],
      const [BlockCell(0, 1), BlockCell(1, 1), BlockCell(1, 0)],
    ];

    // Kolay ve keyifli oynanış için: %75 oranında favori kolay bloklar (3x2, 3x3, 2x2 vb.) gelir
    final bool favoriGelsin = random.nextInt(100) < 75;
    final List<List<BlockCell>> pool = favoriGelsin ? kolayVeFavori : cesitlilikSekilleri;

    return GamePiece(
      cells: List<BlockCell>.from(pool[random.nextInt(pool.length)]),
      color: blockColors[random.nextInt(blockColors.length)],
    );
  }

  // =========================================================
  // ULTRA HIZLI POINTER SÜRÜKLEME
  // =========================================================

  void _pointerDown(
    int index,
    GamePiece piece,
    PointerDownEvent event,
    double previewCellSize,
  ) {
    if (processing || completed || dragging) {
      return;
    }

    _audio.hapticMedium();
    _audio.play(GameSound.blockPickup);

    // Kartın herhangi bir noktasına dokunmak yeterli.
    // Parçanın merkeze en yakın bloğu referans alınır.
    grabbedCell = _defaultGrabCell(piece);

    dragging = true;
    draggingIndex = index;
    draggingPiece = piece;

    dragPointerStart = event.position;
    dragVirtualStart = event.position;
    dragGlobalPosition = event.position;

    selectedPieceIndex = null;

    _updateHover(dragGlobalPosition);

    _createDragOverlay();

    setState(() {});
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!dragging) return;

    final Offset fingerDelta = event.position - dragPointerStart;
    final Offset amplifiedDelta = fingerDelta * dragSensitivity;

    dragGlobalPosition = dragVirtualStart + amplifiedDelta;

    _updateHover(dragGlobalPosition);

    _dragOverlay?.markNeedsBuild();
  }

  Future<void> _pointerUp(PointerUpEvent event) async {
    if (!dragging) return;

    await _finishDrag();
  }

  Future<void> _pointerCancel(PointerCancelEvent event) async {
    if (!dragging) return;

    await _cancelDrag();
  }

  BlockCell _defaultGrabCell(GamePiece piece) {
    final double centerX =
        piece.cells.map((e) => e.x).reduce((a, b) => a + b) /
        piece.cells.length;

    final double centerY =
        piece.cells.map((e) => e.y).reduce((a, b) => a + b) /
        piece.cells.length;

    BlockCell best = piece.cells.first;
    double bestDistance = double.infinity;

    for (final cell in piece.cells) {
      final double dx = cell.x - centerX;
      final double dy = cell.y - centerY;
      final double distance = dx * dx + dy * dy;

      if (distance < bestDistance) {
        bestDistance = distance;
        best = cell;
      }
    }

    return best;
  }

  void _updateHover(Offset pointerGlobal) {
    final BuildContext? boardContext = _boardGridKey.currentContext;

    final GamePiece? piece = draggingPiece;

    if (boardContext == null || piece == null) {
      return;
    }

    final RenderBox? box = boardContext.findRenderObject() as RenderBox?;

    if (box == null) return;

    // Parça parmağın biraz üstünde.
    final Offset liftedGlobal = pointerGlobal - const Offset(0, fingerLift);

    final Offset local = box.globalToLocal(liftedGlobal);

    final double pitch = boardCellSize + boardGap;

    // FLOOR yerine ROUND:
    // Hücre merkezine yaklaşınca mıknatıs gibi kilitlenir.
    final int touchedCol = ((local.dx - boardCellSize / 2) / pitch).round();

    final int touchedRow = ((local.dy - boardCellSize / 2) / pitch).round();

    final int startRow = touchedRow - grabbedCell.y;

    final int startCol = touchedCol - grabbedCell.x;

    final bool valid = canPlace(piece, startRow, startCol);

    final Set<String> nextLinePreview = valid
        ? blockLineClearPreviewCells(
            board: board,
            piece: piece,
            startRow: startRow,
            startCol: startCol,
            boardSize: boardSize,
          )
        : <String>{};

    final bool linePreviewChanged =
        _lineClearPreviewCells.length != nextLinePreview.length ||
        !_lineClearPreviewCells.containsAll(nextLinePreview);

    final bool changed =
        hoverRow != startRow ||
        hoverCol != startCol ||
        hoverValid != valid ||
        linePreviewChanged;

    hoverRow = startRow;
    hoverCol = startCol;
    hoverValid = valid;
    _lineClearPreviewCells = nextLinePreview;

    // Tahtayı sadece hedef hücre değişince yeniden çiz.
    if (changed && mounted) {
      setState(() {});
    }
  }

  Future<void> _finishDrag() async {
    final int? index = draggingIndex;

    final GamePiece? piece = draggingPiece;

    final int? row = hoverRow;

    final int? col = hoverCol;

    final bool valid = hoverValid;

    _removeDragOverlay();

    dragging = false;
    draggingIndex = null;
    draggingPiece = null;

    hoverRow = null;
    hoverCol = null;
    hoverValid = false;
    _lineClearPreviewCells.clear();

    if (mounted) {
      setState(() {});
    }

    if (piece == null ||
        index == null ||
        row == null ||
        col == null ||
        !valid) {
      _audio.hapticLight();
      _audio.play(GameSound.blockInvalid);
      return;
    }

    await _placePiece(index, piece, row, col);
  }

  Future<void> _cancelDrag() async {
    _removeDragOverlay();

    dragging = false;
    draggingIndex = null;
    draggingPiece = null;

    hoverRow = null;
    hoverCol = null;
    hoverValid = false;
    _lineClearPreviewCells.clear();

    if (mounted) {
      setState(() {});
    }
  }

  void _createDragOverlay() {
    _removeDragOverlay();

    final OverlayState overlay = Overlay.of(context);

    _dragOverlay = OverlayEntry(
      builder: (_) {
        final GamePiece? piece = draggingPiece;

        if (!dragging || piece == null) {
          return const SizedBox.shrink();
        }

        final int maxX = piece.cells.map((e) => e.x).reduce(max);

        final int maxY = piece.cells.map((e) => e.y).reduce(max);

        final double width = (maxX + 1) * boardCellSize + maxX * boardGap;

        final double height = (maxY + 1) * boardCellSize + maxY * boardGap;

        final double grabCenterX =
            grabbedCell.x * (boardCellSize + boardGap) + boardCellSize / 2;

        final double grabCenterY =
            grabbedCell.y * (boardCellSize + boardGap) + boardCellSize / 2;

        return Positioned(
          left: dragGlobalPosition.dx - grabCenterX,
          top: dragGlobalPosition.dy - fingerLift - grabCenterY,
          width: width,
          height: height,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: _FloatingPiece(
                piece: piece,
                cellSize: boardCellSize,
                valid: hoverValid,
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_dragOverlay!);
  }

  void _removeDragOverlay() {
    _dragOverlay?.remove();
    _dragOverlay = null;
  }

  // =========================================================
  // YERLEŞTİRME
  // =========================================================

  bool canPlace(GamePiece piece, int startRow, int startCol) {
    for (final cell in piece.cells) {
      final int row = startRow + cell.y;

      final int col = startCol + cell.x;

      if (row < 0 || row >= boardSize || col < 0 || col >= boardSize) {
        return false;
      }

      if (board[row][col] != null) {
        return false;
      }
    }

    return true;
  }

  Future<void> _placePiece(int index, GamePiece piece, int row, int col) async {
    if (processing || completed || pieces[index] == null) {
      return;
    }

    if (!canPlace(piece, row, col)) {
      return;
    }

    processing = true;

    _audio.hapticMedium();

    _audio.play(GameSound.blockPlace);

    setState(() {
      poppingCells = piece.cells
          .map((cell) => '${row + cell.y}-${col + cell.x}')
          .toSet();

      for (final cell in piece.cells) {
        board[row + cell.y][col + cell.x] = piece.color;
      }

      score += piece.cells.length * 10;

      moves++;

      pieces[index] = null;

      selectedPieceIndex = null;
    });

    await Future.delayed(const Duration(milliseconds: 115));

    if (mounted) {
      setState(() {
        poppingCells.clear();
      });
    }

    await _clearLines();

    if (pieces.every((piece) => piece == null)) {
      setState(() {
        pieces = _generateThreePieces();
      });
    }

    if (_allMissionsCompleted && !completed) {
      completed = true;

      await Future.delayed(const Duration(milliseconds: 180));

      if (mounted) {
        _showLevelCompleted();
      }

      processing = false;
      return;
    }

    if (!_anyMoveAvailable()) {
      await Future.delayed(const Duration(milliseconds: 180));

      if (!mounted) return;

      setState(() {
        pieces = _generateThreePieces();
        selectedPieceIndex = null;
      });

      _audio.hapticMedium();

      processing = false;
      return;
    }

    processing = false;
  }

  // Yedek dokun-seç yöntemi.
  void selectPiece(int index) {
    if (pieces[index] == null || processing || dragging) {
      return;
    }

    _audio.hapticMedium();

    _audio.play(GameSound.blockPickup);

    setState(() {
      selectedPieceIndex = selectedPieceIndex == index ? null : index;
    });
  }

  Future<void> tapBoard(int row, int col) async {
    if (selectedPieceIndex == null || processing || dragging) {
      return;
    }

    final int index = selectedPieceIndex!;

    final GamePiece? piece = pieces[index];

    if (piece == null) return;

    if (!canPlace(piece, row, col)) {
      _audio.hapticLight();

      _audio.play(GameSound.blockInvalid);

      return;
    }

    await _placePiece(index, piece, row, col);
  }

  // =========================================================
  // TEMİZLEME
  // =========================================================

  Future<void> _clearLines() async {
    final Set<int> fullRows = {};

    final Set<int> fullCols = {};

    for (int row = 0; row < boardSize; row++) {
      if (board[row].every((e) => e != null)) {
        fullRows.add(row);
      }
    }

    for (int col = 0; col < boardSize; col++) {
      bool full = true;

      for (int row = 0; row < boardSize; row++) {
        if (board[row][col] == null) {
          full = false;
          break;
        }
      }

      if (full) {
        fullCols.add(col);
      }
    }

    final int lineCount = fullRows.length + fullCols.length;

    if (lineCount == 0) {
      combo = 0;
      return;
    }

    clearedLines += lineCount;
    combo++;

    bestCombo = max(bestCombo, combo);

    final Set<String> cells = {};

    for (final row in fullRows) {
      for (int col = 0; col < boardSize; col++) {
        cells.add('$row-$col');
      }
    }

    for (final col in fullCols) {
      for (int row = 0; row < boardSize; row++) {
        cells.add('$row-$col');
      }
    }

    int bonus = lineCount * 120;

    if (lineCount >= 2) {
      bonus += 180;
    }

    if (lineCount >= 3) {
      bonus += 350;
    }

    if (combo >= 2) {
      bonus += combo * 70;
    }

    score += bonus;

    setState(() {
      clearingCells = cells;
      burstSeed++;
      showBurst = true;
      showFlash = true;
    });

    Future.delayed(const Duration(milliseconds: 95), () {
      if (mounted) {
        setState(() {
          showFlash = false;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 520), () {
      if (mounted) {
        setState(() {
          showBurst = false;
        });
      }
    });

    if (lineCount >= 3) {
      _audio.hapticHeavy();

      _audio.play(GameSound.blockMega);

      await _floating('🔥 MEGA!  +$bonus');
    } else if (lineCount >= 2) {
      _audio.hapticHeavy();

      _audio.play(GameSound.blockDoubleClear);

      await _floating('⚡ ÇİFT ÇİZGİ  +$bonus');
    } else if (combo >= 2) {
      _audio.hapticMedium();

      _audio.play(GameSound.blockCombo);

      await _floating('COMBO x$combo  +$bonus');
    } else {
      _audio.hapticMedium();

      _audio.play(GameSound.blockClear);

      await _floating('✨ +$bonus');
    }

    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    setState(() {
      for (final key in clearingCells) {
        final List<String> p = key.split('-');

        board[int.parse(p[0])][int.parse(p[1])] = null;
      }

      clearingCells.clear();
    });
  }

  Future<void> _floating(String text) async {
    if (!mounted) return;

    setState(() {
      floatingText = text;
      showFloatingText = true;
    });

    await Future.delayed(const Duration(milliseconds: 430));

    if (!mounted) return;

    setState(() {
      showFloatingText = false;
    });
  }

  bool _anyMoveAvailable() {
    for (final piece in pieces) {
      if (piece == null) {
        continue;
      }

      for (int row = 0; row < boardSize; row++) {
        for (int col = 0; col < boardSize; col++) {
          if (canPlace(piece, row, col)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  int calculateStars() {
    if (moves <= widget.level.targetMoves) {
      return 3;
    }

    if (moves <= (widget.level.targetMoves * 1.35).ceil()) {
      return 2;
    }

    return 1;
  }

  Future<void> _newGame() async {
    _removeDragOverlay();

    sessionSeed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'blocks',
          level: widget.level.number,
        );

    random = _replayability.randomFor(
      sessionSeed: sessionSeed,
      round: 0,
      salt: widget.fixedSessionSeed == null ? 73 : 71,
    );

    if (!mounted) return;

    setState(() {
      board = _scenarioBoard();

      pieces = _generateThreePieces();

      score = 0;
      moves = 0;
      clearedLines = 0;

      combo = 0;
      bestCombo = 0;

      selectedPieceIndex = null;

      dragging = false;
      draggingPiece = null;
      draggingIndex = null;

      hoverRow = null;
      hoverCol = null;
      hoverValid = false;
      _lineClearPreviewCells.clear();

      clearingCells.clear();
      poppingCells.clear();
      showBurst = false;
      showFlash = false;

      processing = false;
      completed = false;
    });
    if (widget.fixedSessionSeed == null) {
      await _replayability.registerFingerprint(
        gameId: 'blocks',
        level: widget.level.number,
        fingerprint: _scenarioFingerprint(),
        historyLimit: 100,
      );
    }
  }

  void _showLevelCompleted() {
    final int stars = calculateStars();

    final int finalScore = score + bestCombo * 30;

    _audio.hapticHeavy();

    _audio.playVictory(
      stars: stars,
      boss: widget.level.contentLevel == 10,
      levelNumber: widget.level.number,
    );

    if (widget.competitionMode) {
      Navigator.pop(
        context,
        BlockLevelResult(
          completed: true,
          stars: stars,
          score: finalScore,
          nextLevel: false,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_BlockNeon.board, _BlockNeon.panel],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _BlockNeon.cyan, width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _BlockNeon.cyan.withValues(alpha: 0.20),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 62,
                    color: _BlockNeon.orange,
                  ),
                  const SizedBox(height: 8),
                  LText(
                    widget.level.contentLevel == 10
                        ? '🔥 BLOK BOSS!'
                        : '🎉 HEDEF TAMAMLANDI!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _BlockNeon.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 23,
                    ),
                  ),
                  const SizedBox(height: 11),
                  AdvancedResultBanner(
                    score: finalScore,
                    previousBestScore: widget.previousBestScore,
                    english: context.l10n.isEnglish,
                    accentColor: _BlockNeon.cyan,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _BlockNeon.orange,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LText(
                    '$clearedLines sıra • $moves hamle • x$bestCombo en iyi kombo',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _BlockNeon.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultBox(title: 'PUAN', value: '$finalScore'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ResultBox(title: 'HAMLE', value: '$moves'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ResultBox(title: 'COMBO', value: 'x$bestCombo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);

                        Navigator.pop(
                          context,
                          BlockLevelResult(
                            completed: true,
                            stars: stars,
                            score: finalScore,
                            nextLevel: true,
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const LText('SONRAKİ SEVİYE'),
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

  void _showHowToPlay() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: _BlockNeon.panel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _BlockNeon.cyan.withValues(alpha: 0.3)),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: _BlockNeon.cyan, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Nasıl Oynanır?',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                '• Alttaki blok parçalarını 8×8 ızgaraya sürükle veya dokunarak yerleştir.\n'
                '• Yatay veya dikey tam bir sıra oluşturduğunda o sıra patlar ve temizlenir.\n'
                '• Art arda hamlelerde sıra temizleyerek Kombo puanı kazan.\n'
                '• Seviye hedeflerine (Puan, Temizlenen Çizgi, Kombo) ulaşarak bölümü tamamla!',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFFD6E2E8),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _BlockNeon.cyan,
                    foregroundColor: const Color(0xFF0D1B2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('ANLADIM', style: TextStyle(fontWeight: FontWeight.w900)),
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
    final double scoreProgress = min(
      score / widget.level.targetScore,
      1.0,
    ).toDouble();
    final double lineProgress = min(
      clearedLines / widget.level.targetLines,
      1.0,
    ).toDouble();
    final double comboProgress = widget.level.targetCombo == 0
        ? 1.0
        : min(bestCombo / widget.level.targetCombo, 1.0).toDouble();
    final double progress = widget.level.targetCombo == 0
        ? (scoreProgress + lineProgress) / 2
        : (scoreProgress + lineProgress + comboProgress) / 3;

    return Scaffold(
      backgroundColor: _BlockNeon.background,
      appBar: AppBar(
        backgroundColor: _BlockNeon.background,
        foregroundColor: _BlockNeon.text,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: _BlockNeon.background,
          systemNavigationBarColor: _BlockNeon.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              context.l10n.uppercaseLabel(widget.level.title),
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            LText(
              'Bölüm ${widget.level.number} / ${widget.totalLevels}',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: _BlockNeon.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nasıl Oynanır?',
            onPressed: _showHowToPlay,
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            tooltip: 'Yeni oyun',
            onPressed: _newGame,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
          child: Column(
            children: [
              // Kompakt tek satır durum çubuğu (38px)
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _BlockNeon.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _BlockNeon.cyan.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars_rounded, size: 16, color: _BlockNeon.orange),
                    const SizedBox(width: 4),
                    Text(
                      '$score/${widget.level.targetScore}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: _scoreMissionCompleted ? _BlockNeon.orange : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.clear_all_rounded, size: 16, color: _BlockNeon.cyan),
                    const SizedBox(width: 4),
                    Text(
                      '$clearedLines/${widget.level.targetLines}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: _lineMissionCompleted ? _BlockNeon.cyan : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (widget.level.targetCombo > 0) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.bolt_rounded, size: 16, color: const Color(0xFFFF5252)),
                      const SizedBox(width: 4),
                      Text(
                        'x$bestCombo/${widget.level.targetCombo}',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: _comboMissionCompleted ? const Color(0xFFFF5252) : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: 50,
                      height: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: _BlockNeon.panelRaised,
                          valueColor: const AlwaysStoppedAnimation<Color>(_BlockNeon.cyan),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildBoard(),

                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 90),
                          opacity: showFlash ? 0.30 : 0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0x66FFB21C),
                                  Color(0x0000D9FF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (showBurst)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(burstSeed),
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, value, child) {
                              return CustomPaint(
                                painter: _BurstPainter(
                                  progress: value,
                                  seed: burstSeed,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: showFloatingText ? 1 : 0,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(floatingText),
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 430),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            final double scale =
                                0.72 + (0.38 * min(value * 1.7, 1.0));
                            return Transform.translate(
                              offset: Offset(0, -54 * value),
                              child: Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity:
                                      (1 -
                                              (value - 0.72).clamp(0.0, 0.28) /
                                                  0.28)
                                          .clamp(0.0, 1.0),
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF)
                                  .withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _BlockNeon.cyan,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _BlockNeon.cyan.withValues(
                                    alpha: 0.34,
                                  ),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: LText(
                              floatingText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: _BlockNeon.cyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              SizedBox(
                height: 96,
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: index == 1 ? 4 : 2,
                        ),
                        child: _FastPieceTray(
                          piece: pieces[index],
                          selected: selectedPieceIndex == index,
                          onTap: () => selectPiece(index),
                          onPointerDown: (event, cellSize) {
                            final GamePiece? piece = pieces[index];

                            if (piece != null) {
                              _pointerDown(index, piece, event, cellSize);
                            }
                          },
                          onPointerMove: _pointerMove,
                          onPointerUp: _pointerUp,
                          onPointerCancel: _pointerCancel,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: _BlockNeon.board,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _BlockNeon.cyan.withValues(alpha: 0.72),
            width: 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _BlockNeon.cyan.withValues(alpha: 0.16),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            boardCellSize = (constraints.maxWidth - boardGap * 7) / 8;

            return SizedBox(
              key: _boardGridKey,
              width: constraints.maxWidth,
              height: constraints.maxWidth,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 64,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: boardGap,
                  mainAxisSpacing: boardGap,
                ),
                itemBuilder: (context, index) {
                  final int row = index ~/ 8;

                  final int col = index % 8;

                  bool preview = false;

                  if (dragging &&
                      draggingPiece != null &&
                      hoverRow != null &&
                      hoverCol != null) {
                    for (final cell in draggingPiece!.cells) {
                      if (hoverRow! + cell.y == row &&
                          hoverCol! + cell.x == col) {
                        preview = true;

                        break;
                      }
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      tapBoard(row, col);
                    },
                    child: _BoardCell(
                      color: board[row][col],
                      clearing: clearingCells.contains('$row-$col'),
                      popping: poppingCells.contains('$row-$col'),
                      preview: preview,
                      previewValid: hoverValid,
                      previewColor: draggingPiece?.color,
                      lineClearPreview: _lineClearPreviewCells.contains(
                        '$row-$col',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// =========================================================
// POINTER TABANLI HIZLI PARÇA TEPSİSİ
// =========================================================

class _FastPieceTray extends StatelessWidget {
  final GamePiece? piece;
  final bool selected;

  final VoidCallback onTap;

  final void Function(PointerDownEvent event, double cellSize) onPointerDown;

  final void Function(PointerMoveEvent event) onPointerMove;

  final Future<void> Function(PointerUpEvent event) onPointerUp;

  final Future<void> Function(PointerCancelEvent event) onPointerCancel;

  const _FastPieceTray({
    required this.piece,
    required this.selected,
    required this.onTap,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (piece == null) {
      return Container(
        decoration: BoxDecoration(
          color: _BlockNeon.panel,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Icon(Icons.check_rounded, color: _BlockNeon.green, size: 30),
        ),
      );
    }

    const double previewCellSize = 18;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        onPointerDown(event, previewCellSize);
      },
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          decoration: BoxDecoration(
            color: selected ? _BlockNeon.panelRaised : _BlockNeon.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? piece!.color : _BlockNeon.line,
              width: selected ? 2 : 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (selected ? piece!.color : _BlockNeon.cyan).withValues(
                  alpha: selected ? 0.30 : 0.07,
                ),
                blurRadius: selected ? 17 : 8,
                spreadRadius: selected ? 1 : 0,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _PiecePreview(piece: piece!, cellSize: previewCellSize),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingPiece extends StatelessWidget {
  final GamePiece piece;
  final double cellSize;
  final bool valid;

  const _FloatingPiece({
    required this.piece,
    required this.cellSize,
    required this.valid,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: piece.cells.map((cell) {
        return Positioned(
          left: cell.x * (cellSize + _BlockPlayPageState.boardGap),
          top: cell.y * (cellSize + _BlockPlayPageState.boardGap),
          width: cellSize,
          height: cellSize,
          child: _ColorBlock(
            color: valid ? piece.color : _BlockNeon.red,
            glow: true,
          ),
        );
      }).toList(),
    );
  }
}

class _PiecePreview extends StatelessWidget {
  final GamePiece piece;
  final double cellSize;

  const _PiecePreview({required this.piece, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    final int maxX = piece.cells.map((e) => e.x).reduce(max);

    final int maxY = piece.cells.map((e) => e.y).reduce(max);

    const double gap = 3;

    final double width = (maxX + 1) * cellSize + maxX * gap;

    final double height = (maxY + 1) * cellSize + maxY * gap;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: piece.cells.map((cell) {
          return Positioned(
            left: cell.x * (cellSize + gap),
            top: cell.y * (cellSize + gap),
            width: cellSize,
            height: cellSize,
            child: _ColorBlock(color: piece.color),
          );
        }).toList(),
      ),
    );
  }
}

class _LineClearLedCell extends StatelessWidget {
  final Color color;
  final bool ghost;

  const _LineClearLedCell({required this.color, required this.ghost});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double glow, Widget? child) {
        final Color litColor =
            Color.lerp(color, Colors.white, 0.28 + glow * 0.22) ?? color;

        final Color edgeColor =
            Color.lerp(color, Colors.white, 0.52 + glow * 0.30) ?? Colors.white;

        return Transform.scale(
          scale: 1 + glow * 0.025,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.96),
                  litColor.withValues(alpha: ghost ? 0.88 : 1),
                  color.withValues(alpha: ghost ? 0.82 : 0.98),
                ],
                stops: const <double>[0, 0.38, 1],
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: edgeColor, width: 1.8 + glow * 0.9),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.42 + glow * 0.24),
                  blurRadius: 7 + glow * 9,
                  spreadRadius: 0.5 + glow,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.20 + glow * 0.26),
                  blurRadius: 4 + glow * 7,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Positioned(
                  left: 4,
                  right: 4,
                  top: 3,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.70 + glow * 0.25),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.65),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72 + glow * 0.26),
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: edgeColor.withValues(alpha: 0.85),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BoardCell extends StatelessWidget {
  final Color? color;
  final bool clearing;
  final bool popping;

  final bool preview;
  final bool previewValid;
  final Color? previewColor;
  final bool lineClearPreview;

  const _BoardCell({
    required this.color,
    required this.clearing,
    required this.popping,
    required this.preview,
    required this.previewValid,
    required this.previewColor,
    required this.lineClearPreview,
  });

  @override
  Widget build(BuildContext context) {
    if (lineClearPreview) {
      return _LineClearLedCell(
        color: preview
            ? (previewColor ?? _BlockNeon.cyan)
            : (color ?? previewColor ?? _BlockNeon.cyan),
        ghost: preview,
      );
    }

    if (preview) {
      return Container(
        decoration: BoxDecoration(
          color: previewValid
              ? (previewColor ?? _BlockNeon.lime).withValues(alpha: 0.68)
              : _BlockNeon.red.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: previewValid
                ? (previewColor ?? _BlockNeon.lime)
                : _BlockNeon.red,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (previewValid
                          ? (previewColor ?? _BlockNeon.lime)
                          : _BlockNeon.red)
                      .withValues(alpha: 0.58),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: popping ? 0.72 : 1.0,
        end: clearing ? 0.10 : 1.0,
      ),
      duration: Duration(milliseconds: clearing ? 130 : 115),
      curve: popping ? Curves.easeOutBack : Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: color == null
          ? Container(
              decoration: BoxDecoration(
                color: _BlockNeon.emptyCell,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _BlockNeon.line.withValues(alpha: 0.68),
                  width: 0.8,
                ),
              ),
            )
          : _ColorBlock(color: color!, glow: true),
    );
  }
}

class _ColorBlock extends StatelessWidget {
  final Color color;
  final bool glow;

  const _ColorBlock({required this.color, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.30) ?? color,
            color,
            Color.lerp(color, Colors.black, 0.16) ?? color,
          ],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.54),
          width: 1.3,
        ),
        boxShadow: glow
            ? <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.74),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final int score;
  final int stars;
  final int level;

  const _ProgressPanel({
    required this.score,
    required this.stars,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: StudioVisuals.tealSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              size: 29,
              color: StudioVisuals.teal,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LText(
                  'BLOK FIRTINASI',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                LText(
                  'Seviye $level / ${GameContentPolicy.campaignLevels}   •   ⭐ $stars / ${GameContentPolicy.campaignLevels * 3}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          LText(
            '$score',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.amber,
              fontWeight: FontWeight.w900,
              fontSize: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final BlockLevel level;
  final bool unlocked;
  final int stars;
  final int bestScore;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.bestScore,
    required this.onTap,
  });

  Color get color {
    switch (level.difficulty) {
      case 'KOLAY':
        return const Color(0xFF34715D);
      case 'ORTA':
        return const Color(0xFFFF9F1C);
      case 'ZOR':
        return const Color(0xFFA84640);
      case 'BOSS':
        return const Color(0xFFFF4F9A);
      default:
        return const Color(0xFF3D7183);
    }
  }

  @override
  Widget build(BuildContext context) => StudioChapterCard(
    gameId: 'blocks',
    number: level.number,
    title: level.title,
    detail: '${level.targetScore} puan • ${level.targetLines} sıra',
    difficulty: GameContentPolicy.difficulty(level.number),
    unlocked: unlocked,
    stars: stars,
    best: bestScore,
    onTap: onTap,
  );
}

class _BlockQuickResumeCard extends StatelessWidget {
  final int levelNumber;
  final String levelTitle;
  final String difficulty;
  final VoidCallback onPlay;

  const _BlockQuickResumeCard({
    required this.levelNumber,
    required this.levelTitle,
    required this.difficulty,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    const Color accent = StudioVisuals.teal;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: accent, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    const Text(
                      'SIRADAKİ PARKUR',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        difficulty,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: accent,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Bölüm $levelNumber • $levelTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onPlay,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 16),
                SizedBox(width: 2),
                Text(
                  'OYNA',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final String title;
  final String value;

  const _ResultBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _BlockNeon.panelRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          LText(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: _BlockNeon.text,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          LText(
            title,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: _BlockNeon.muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double progress;
  final int seed;

  const _BurstPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final Random rng = Random(seed);
    final Offset center = Offset(size.width / 2, size.height / 2);

    const List<Color> colors = _BlockNeon.pieces;

    final double fade = (1 - progress).clamp(0.0, 1.0);

    for (int i = 0; i < 62; i++) {
      final double angle = rng.nextDouble() * pi * 2;
      final double distance =
          (24 + rng.nextDouble() * 175) *
          Curves.easeOutBack.transform(progress);

      final Offset point =
          center + Offset(cos(angle) * distance, sin(angle) * distance);

      final Paint paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: fade)
        ..style = PaintingStyle.fill;

      final double radius =
          (3.0 + rng.nextDouble() * 6.5) * (0.65 + fade * 0.35);

      if (i.isEven) {
        canvas.drawCircle(point, radius, paint);
      } else {
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle + progress * 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: radius * 2.2,
              height: radius * 1.1,
            ),
            Radius.circular(radius / 2),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.seed != seed;
  }
}

/// Parça gerçekten yerleştirilmeden, yerleştirme sonrasında tamamlanacak
/// yatay ve dikey hatların bütün hücrelerini döndürür.
///
/// Bu fonksiyon [board] listesini değiştirmez. Geçersiz veya hat
/// tamamlamayan bir yerleşimde boş küme döndürür.
Set<String> blockLineClearPreviewCells({
  required List<List<Color?>> board,
  required GamePiece piece,
  required int startRow,
  required int startCol,
  int boardSize = 8,
}) {
  if (boardSize <= 0 ||
      board.length < boardSize ||
      board.any((List<Color?> row) => row.length < boardSize)) {
    return <String>{};
  }

  final Set<String> placedCells = <String>{};

  for (final BlockCell cell in piece.cells) {
    final int row = startRow + cell.y;
    final int col = startCol + cell.x;

    if (row < 0 ||
        row >= boardSize ||
        col < 0 ||
        col >= boardSize ||
        board[row][col] != null) {
      return <String>{};
    }

    placedCells.add('$row-$col');
  }

  bool occupiedAfterPlacement(int row, int col) {
    return board[row][col] != null || placedCells.contains('$row-$col');
  }

  final Set<int> completedRows = <int>{};
  final Set<int> completedColumns = <int>{};

  for (int row = 0; row < boardSize; row++) {
    bool full = true;

    for (int col = 0; col < boardSize; col++) {
      if (!occupiedAfterPlacement(row, col)) {
        full = false;
        break;
      }
    }

    if (full) completedRows.add(row);
  }

  for (int col = 0; col < boardSize; col++) {
    bool full = true;

    for (int row = 0; row < boardSize; row++) {
      if (!occupiedAfterPlacement(row, col)) {
        full = false;
        break;
      }
    }

    if (full) completedColumns.add(col);
  }

  final Set<String> result = <String>{};

  for (final int row in completedRows) {
    for (int col = 0; col < boardSize; col++) {
      result.add('$row-$col');
    }
  }

  for (final int col in completedColumns) {
    for (int row = 0; row < boardSize; row++) {
      result.add('$row-$col');
    }
  }

  return result;
}

class BlockLevel {
  final int number;
  final int? sourceNumber;
  int get contentLevel => sourceNumber ?? number;
  final String title;
  final String difficulty;
  final int targetScore;
  final int targetLines;
  final int targetCombo;
  final int targetMoves;

  const BlockLevel({
    required this.number,
    this.sourceNumber,
    required this.title,
    required this.difficulty,
    required this.targetScore,
    required this.targetLines,
    this.targetCombo = 0,
    required this.targetMoves,
  });
}

class GamePiece {
  final List<BlockCell> cells;
  final Color color;

  const GamePiece({required this.cells, required this.color});
}

class BlockCell {
  final int x;
  final int y;

  const BlockCell(this.x, this.y);
}

class BlockLevelResult {
  final bool completed;
  final int stars;
  final int score;
  final bool nextLevel;

  const BlockLevelResult({
    required this.completed,
    required this.stars,
    required this.score,
    required this.nextLevel,
  });
}
