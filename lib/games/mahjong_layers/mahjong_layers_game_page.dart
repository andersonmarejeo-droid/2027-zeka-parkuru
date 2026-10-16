import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import 'mahjong_layers_puzzle.dart';

/// S02 — a calm, premium Mahjong solitaire course.
///
/// The puzzle model owns topology, pair validity and the verified removal
/// route. This page deliberately owns only input, presentation and the shared
/// Parkur completion contract, so future layout variations cannot weaken the
/// game's one-solution content guarantees.
class MahjongLayersGamePage extends StatelessWidget {
  const MahjongLayersGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = GameContentPolicy.bestSeriesCampaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int number = index + 1;
      final int stage = (index % 10) + 1;
      return ParkurLevelSpec(
        number: number,
        titleTr: 'Katman ${number.toString().padLeft(3, '0')}',
        titleEn: 'Layer ${number.toString().padLeft(3, '0')}',
        subtitleTr: _stageDescription(stage, english: false),
        subtitleEn: _stageDescription(stage, english: true),
        difficulty: _stageTitle(stage, english: false),
        icon: Icons.layers_rounded,
      );
    },
  );

  static String _stageTitle(int stage, {required bool english}) =>
      switch (stage) {
        1 => english ? 'ORIENTATION' : 'KEŞİF',
        2 => english ? 'OPEN EDGES' : 'AÇIK KENARLAR',
        3 => english ? 'PAIR READING' : 'ÇİFT OKUMA',
        4 => english ? 'ROUTE BUILDING' : 'ROTA KURMA',
        5 => english ? 'LAYER SENSE' : 'KATMAN SEZGİSİ',
        6 => english ? 'COMBINATION' : 'KOMBİNASYON',
        7 => english ? 'ADVANCED' : 'İLERİ',
        8 => english ? 'TACTICAL' : 'TAKTİK',
        9 => english ? 'EXPERT' : 'UZMAN',
        _ => english ? 'MASTER' : 'USTA',
      };

  static String _stageDescription(int stage, {required bool english}) =>
      switch (stage) {
        1 =>
          english
              ? 'Read open pairs on one calm layer.'
              : 'Tek sakin katmanda açık çiftleri oku.',
        2 =>
          english
              ? 'Free the edge tiles before the centre.'
              : 'Merkezden önce kenar taşlarını serbest bırak.',
        3 =>
          english
              ? 'Spot matching symbols through light overlap.'
              : 'Hafif örtüşmede eşleşen sembolleri ayırt et.',
        4 =>
          english
              ? 'Plan a short route before every pair.'
              : 'Her çiftten önce kısa bir rota planla.',
        5 =>
          english
              ? 'Keep future moves open across two layers.'
              : 'İki katmanda gelecek hamleleri açık tut.',
        6 =>
          english
              ? 'Use pair order to reveal hidden combinations.'
              : 'Gizli kombinasyonları çift sırasıyla aç.',
        7 =>
          english
              ? 'Handle compact three-layer routes.'
              : 'Sıkı üç katmanlı rotaları yönet.',
        8 =>
          english
              ? 'Protect scarce symbols and branching choices.'
              : 'Nadir sembolleri ve dallanan seçimleri koru.',
        9 =>
          english
              ? 'Read deep overlaps without closing the board.'
              : 'Tahtayı kapatmadan derin örtüşmeleri çöz.',
        _ =>
          english
              ? 'Master the full layered route with precision.'
              : 'Tam katmanlı rotayı hassasiyetle yönet.',
      };

  @override
  Widget build(BuildContext context) {
    return ParkurLevelHub(
      gameId: 'mahjong_layers',
      progressPrefix: 'mahjong_layers',
      titleTr: 'Mahjong Katmanları',
      titleEn: 'Mahjong Layers',
      taglineTr: 'Açık taş çiftlerini katman katman eşleştir.',
      taglineEn: 'Match free tiles and clear the layers.',
      accent: _MahjongPalette.teal,
      icon: Icons.layers_rounded,
      levels: _levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => MahjongLayersPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class MahjongLayersPlayPage extends StatefulWidget {
  const MahjongLayersPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<MahjongLayersPlayPage> createState() => _MahjongLayersPlayPageState();
}

class _MahjongLayersPlayPageState extends State<MahjongLayersPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.visual,
  );
  final List<_MahjongSnapshot> _undo = <_MahjongSnapshot>[];

  late final MahjongLayersPuzzle _puzzle;
  late Set<int> _remaining;
  late final Set<int> _initialRemaining;
  late final StudioGameSession _session;
  int? _selectedTileId;
  Set<int> _hintedTileIds = <int>{};
  int? _rejectedTileId;
  bool _english = false;
  bool _finished = false;
  int _moves = 0;
  int _hints = 0;
  int _reshuffles = 0;
  int _boardTurn = 0;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _puzzle = MahjongLayersPuzzle.forLevel(widget.level.number);
    _initialRemaining = Set<int>.unmodifiable(_puzzle.initialRemaining);
    _remaining = Set<int>.from(_initialRemaining);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  int get _removedCount => _puzzle.tileCount - _remaining.length;
  int get _pairCount => _puzzle.tileCount ~/ 2;
  int get _removedPairs => _removedCount ~/ 2;
  int get _freeCount => _puzzle.availableTileIds(_remaining).length;

  MahjongTile _tileFor(int id) =>
      _puzzle.tiles.firstWhere((MahjongTile tile) => tile.id == id);

  void _saveUndo() {
    _undo.add(
      _MahjongSnapshot(remaining: Set<int>.from(_remaining), moves: _moves),
    );
    if (_undo.length > 80) _undo.removeAt(0);
  }

  void _tapTile(MahjongTile tile) {
    if (_finished || !_session.acceptsInput || !_remaining.contains(tile.id)) {
      return;
    }
    if (!_puzzle.isTileFree(tile.id, _remaining)) {
      _rejectTile(
        tile.id,
        _english ? 'This tile is covered.' : 'Bu taş kapalı.',
      );
      return;
    }

    final int? selected = _selectedTileId;
    if (selected == null) {
      setState(() => _selectedTileId = tile.id);
      _audio.hapticSelection();
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .26),
      );
      return;
    }
    if (selected == tile.id) {
      setState(() => _selectedTileId = null);
      unawaited(_audio.play(GameSound.uiBack, gain: .2));
      return;
    }
    if (!_puzzle.canMatch(selected, tile.id, _remaining)) {
      _rejectTile(
        tile.id,
        _english ? 'Choose the matching free tile.' : 'Eşleşen açık taşı seç.',
      );
      return;
    }

    _saveUndo();
    setState(() {
      _remaining = _puzzle.removePair(_remaining, selected, tile.id);
      _selectedTileId = null;
      _hintedTileIds = <int>{};
      _moves++;
    });
    _session.recordAccepted();
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .42));
    if (_puzzle.isSolved(_remaining)) unawaited(_complete());
  }

  void _rejectTile(int tileId, String message) {
    setState(() => _rejectedTileId = tileId);
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 460), () {
      if (mounted) setState(() => _rejectedTileId = null);
    });
    _session.recordMistake();
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .32));
    _showMessage(message);
  }

  void _showHint() {
    if (_finished || !_session.canUseHint) return;
    final MahjongMove? move = _puzzle.hintMove(_remaining);
    if (move == null) {
      _showMessage(
        _english
            ? 'No free match is visible. Undo or reset this route.'
            : 'Görünür eşleşme yok. Rotayı geri al veya sıfırla.',
      );
      return;
    }
    setState(() {
      _selectedTileId = null;
      _hintedTileIds = Set<int>.from(move.tileIds);
      _hints++;
    });
    _session.useHint(pointCost: 120);
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .42));
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hintedTileIds = <int>{});
    });
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    final _MahjongSnapshot snapshot = _undo.removeLast();
    setState(() {
      _remaining = Set<int>.from(snapshot.remaining);
      // Undo restores a stable board state rather than a half-selected pair;
      // this avoids an accidental immediate deselection on the next tap.
      _selectedTileId = null;
      _moves = snapshot.moves;
      _hintedTileIds = <int>{};
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .28));
  }

  void _restart() {
    if (_finished) return;
    setState(() {
      _remaining = Set<int>.from(_initialRemaining);
      _selectedTileId = null;
      _hintedTileIds = <int>{};
      _undo.clear();
      _moves = 0;
      _hints = 0;
      _reshuffles = 0;
      _boardTurn = 0;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .3));
  }

  /// The model guarantees a route for this exact board. Reordering the actual
  /// faces independently would break that guarantee, therefore the on-screen
  /// mix uses a 180 degree presentation turn: all genuine availability rules
  /// stay valid while the player gets a fresh reading angle.
  void _shuffleView() {
    if (_finished) return;
    setState(() {
      _boardTurn = (_boardTurn + 1) % 2;
      _selectedTileId = null;
      _hintedTileIds = <int>{};
      _reshuffles++;
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .28));
    _showMessage(
      _english
          ? 'The tile table has been turned for a fresh reading angle.'
          : 'Taş masası yeni bir okuma açısı için çevrildi.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  int _stars() {
    if (_hints == 0 && _session.mistakes == 0 && _reshuffles <= 1) return 3;
    if (_hints <= 2 && _session.mistakes <= 3) return 2;
    return 1;
  }

  int _score() => math.max(
    240,
    2600 -
        _moves * 20 -
        _hints * 170 -
        _session.mistakes * 95 -
        _reshuffles * 35,
  );

  Future<void> _complete() async {
    if (_finished || !_session.acceptsInput) return;
    _finished = true;
    final int stars = _stars();
    final int score = _score();
    _session.recordAccepted(points: score);
    _session.complete(
      stars: stars,
      action: widget.level.number < MahjongLayersGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticMedium();
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final ParkurResultAction? action = await showParkurResultDialog(
      context: context,
      accent: _MahjongPalette.teal,
      titleTr: 'KATMANLAR AÇILDI',
      titleEn: 'LAYERS CLEARED',
      detailTr:
          '$_removedPairs çift, $_moves hamle ve ${_puzzle.layerCount} katman temizlendi.',
      detailEn:
          '$_removedPairs pairs, $_moves moves and ${_puzzle.layerCount} layers cleared.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < MahjongLayersGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction resultAction = switch (action) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: score,
        stars: stars,
        action: resultAction,
      ).toParkurResult(),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    final int stage = _puzzle.localStage;
    return Scaffold(
      backgroundColor: _MahjongPalette.canvas,
      appBar: AppBar(
        backgroundColor: _MahjongPalette.canvas,
        foregroundColor: _MahjongPalette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'MAHJONG LAYERS' : 'MAHJONG KATMANLARI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            Text(
              '${_english ? 'LAYER' : 'KATMAN'} ${widget.level.number.toString().padLeft(3, '0')} · ${MahjongLayersGamePage._stageTitle(stage, english: _english)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _MahjongPalette.muted,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .34,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('mahjong_undo'),
            tooltip: _english ? 'Undo pair' : 'Çifti geri al',
            onPressed: _undo.isEmpty ? null : _undoMove,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('mahjong_restart'),
            tooltip: _english ? 'Restart board' : 'Tahtayı sıfırla',
            onPressed: _restart,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 760,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints limits) {
              final bool compact =
                  limits.maxWidth < 390 || limits.maxHeight < 660;
              // At 320×600 the four touch tools remain on screen. Dense
              // layouts stay inspectable through the board's pinch zoom.
              final double boardHeight = compact
                  ? math.max(192, math.min(230, limits.maxHeight - 350))
                  : math.max(280, math.min(430, limits.maxHeight - 272));
              return ListView(
                key: const ValueKey<String>('mahjong_scroll'),
                padding: EdgeInsets.fromLTRB(12, 4, 12, compact ? 10 : 18),
                children: <Widget>[
                  _MahjongHeader(
                    stage: stage,
                    english: _english,
                    removedPairs: _removedPairs,
                    totalPairs: _pairCount,
                    freeCount: _freeCount,
                    moves: _moves,
                    bestScore: widget.previousBestScore,
                  ),
                  SizedBox(height: compact ? 8 : 11),
                  _RuleBand(english: _english),
                  SizedBox(height: compact ? 8 : 11),
                  SizedBox(
                    height: boardHeight,
                    child: _MahjongBoard(
                      key: const ValueKey<String>('mahjong_layers_board'),
                      puzzle: _puzzle,
                      remaining: _remaining,
                      selectedTileId: _selectedTileId,
                      hintedTileIds: _hintedTileIds,
                      rejectedTileId: _rejectedTileId,
                      boardTurn: _boardTurn,
                      english: _english,
                      onTileTap: _tapTile,
                    ),
                  ),
                  SizedBox(height: compact ? 7 : 10),
                  _SelectedStatus(
                    selected: _selectedTileId == null
                        ? null
                        : _tileFor(_selectedTileId!),
                    freeCount: _freeCount,
                    english: _english,
                  ),
                  SizedBox(height: compact ? 8 : 11),
                  _ToolRail(
                    english: _english,
                    canUndo: _undo.isNotEmpty,
                    onHint: _showHint,
                    onUndo: _undoMove,
                    onShuffle: _shuffleView,
                    onRestart: _restart,
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Text(
                    _english
                        ? 'Only uncovered tiles with a free left or right edge can be paired. Read two moves ahead before clearing a symbol.'
                        : 'Yalnızca üstü açık ve sol ya da sağ kenarı serbest taşlar eşleştirilir. Bir sembolü kaldırmadan iki hamle sonrasını oku.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _MahjongPalette.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.28,
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

class _MahjongSnapshot {
  const _MahjongSnapshot({required this.remaining, required this.moves});

  final Set<int> remaining;
  final int moves;
}

class _MahjongPalette {
  static const Color canvas = Color(0xFFF3F4F0);
  static const Color surface = Color(0xFFFFFEFB);
  static const Color ink = Color(0xFF26363B);
  static const Color muted = Color(0xFF718188);
  static const Color line = Color(0xFFDCE3DF);
  static const Color teal = Color(0xFF3C8B80);
  static const Color tealSoft = Color(0xFFE2F0EC);
  static const Color brass = Color(0xFFB98C56);
  static const Color brassSoft = Color(0xFFF7EEDC);
  static const Color danger = Color(0xFFC96962);
}

class _MahjongHeader extends StatelessWidget {
  const _MahjongHeader({
    required this.stage,
    required this.english,
    required this.removedPairs,
    required this.totalPairs,
    required this.freeCount,
    required this.moves,
    required this.bestScore,
  });

  final int stage;
  final bool english;
  final int removedPairs;
  final int totalPairs;
  final int freeCount;
  final int moves;
  final int bestScore;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: _MahjongPalette.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _MahjongPalette.line),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x0D1F3134),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 45,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFE8F2EF), Color(0xFFD5E9E2)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCEE1DB)),
          ),
          child: const Icon(
            Icons.layers_rounded,
            color: _MahjongPalette.teal,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'CERAMIC TABLE' : 'SERAMİK MASA',
                style: const TextStyle(
                  color: _MahjongPalette.brass,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.05,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${english ? 'Stage' : 'Aşama'} $stage · ${MahjongLayersGamePage._stageTitle(stage, english: english)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _MahjongPalette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$removedPairs/$totalPairs ${english ? 'PAIRS' : 'ÇİFT'}  ·  $freeCount ${english ? 'OPEN' : 'AÇIK'}  ·  $moves ${english ? 'MOVES' : 'HAMLE'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _MahjongPalette.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (bestScore > 0)
          Container(
            constraints: const BoxConstraints(minWidth: 42),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
              color: _MahjongPalette.brassSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.emoji_events_rounded,
                  color: _MahjongPalette.brass,
                  size: 15,
                ),
                Text(
                  '$bestScore',
                  style: const TextStyle(
                    color: _MahjongPalette.ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RuleBand extends StatelessWidget {
  const _RuleBand({required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: _MahjongPalette.tealSoft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFCFE4DE)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.touch_app_outlined,
          color: _MahjongPalette.teal,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            english
                ? 'Select two matching free tiles — no tile above, one side open.'
                : 'İki eşleşen açık taşı seç — üstü boş, bir yanı açık.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _MahjongPalette.ink,
              fontSize: 10,
              height: 1.22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SelectedStatus extends StatelessWidget {
  const _SelectedStatus({
    required this.selected,
    required this.freeCount,
    required this.english,
  });

  final MahjongTile? selected;
  final int freeCount;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final MahjongTile? selectedTile = selected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selectedTile == null
            ? _MahjongPalette.surface
            : _MahjongPalette.brassSoft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: selectedTile == null
              ? _MahjongPalette.line
              : const Color(0xFFE8D2A5),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            selectedTile == null
                ? Icons.visibility_outlined
                : Icons.filter_2_rounded,
            color: selectedTile == null
                ? _MahjongPalette.muted
                : _MahjongPalette.brass,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedTile == null
                  ? (english
                        ? '$freeCount free tiles · choose a pair to begin'
                        : '$freeCount açık taş · başlamak için bir çift seç')
                  : (english
                        ? 'Selected ${selectedTile.faceLabel} · find its free match'
                        : '${selectedTile.faceLabel} seçildi · açık eşini bul'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _MahjongPalette.ink,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolRail extends StatelessWidget {
  const _ToolRail({
    required this.english,
    required this.canUndo,
    required this.onHint,
    required this.onUndo,
    required this.onShuffle,
    required this.onRestart,
  });

  final bool english;
  final bool canUndo;
  final VoidCallback onHint;
  final VoidCallback onUndo;
  final VoidCallback onShuffle;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool wide = constraints.maxWidth >= 510;
      final List<Widget> buttons = <Widget>[
        _MahjongToolButton(
          key: const ValueKey<String>('mahjong_hint'),
          icon: Icons.lightbulb_outline_rounded,
          label: english ? 'HINT' : 'İPUCU',
          color: _MahjongPalette.teal,
          onPressed: onHint,
        ),
        _MahjongToolButton(
          key: const ValueKey<String>('mahjong_undo_action'),
          icon: Icons.undo_rounded,
          label: english ? 'UNDO' : 'GERİ AL',
          color: _MahjongPalette.ink,
          onPressed: canUndo ? onUndo : null,
        ),
        _MahjongToolButton(
          key: const ValueKey<String>('mahjong_shuffle'),
          icon: Icons.flip_rounded,
          label: english ? 'TURN VIEW' : 'GÖRÜNÜMÜ ÇEVİR',
          color: _MahjongPalette.brass,
          onPressed: onShuffle,
        ),
        _MahjongToolButton(
          key: const ValueKey<String>('mahjong_restart_action'),
          icon: Icons.restart_alt_rounded,
          label: english ? 'RESET' : 'SIFIRLA',
          color: _MahjongPalette.muted,
          onPressed: onRestart,
        ),
      ];
      if (wide) {
        return Row(
          children: <Widget>[
            for (int index = 0; index < buttons.length; index++) ...<Widget>[
              Expanded(child: buttons[index]),
              if (index != buttons.length - 1) const SizedBox(width: 8),
            ],
          ],
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 7,
        alignment: WrapAlignment.center,
        children: buttons
            .map((Widget button) => SizedBox(width: 140, child: button))
            .toList(),
      );
    },
  );
}

class _MahjongToolButton extends StatelessWidget {
  const _MahjongToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 16),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      foregroundColor: onPressed == null ? _MahjongPalette.muted : color,
      backgroundColor: _MahjongPalette.surface,
      minimumSize: const Size(48, GameInputPolicy.minimumTargetSize),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      side: BorderSide(
        color: onPressed == null
            ? _MahjongPalette.line
            : color.withValues(alpha: .30),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class _MahjongBoard extends StatelessWidget {
  const _MahjongBoard({
    super.key,
    required this.puzzle,
    required this.remaining,
    required this.selectedTileId,
    required this.hintedTileIds,
    required this.rejectedTileId,
    required this.boardTurn,
    required this.english,
    required this.onTileTap,
  });

  final MahjongLayersPuzzle puzzle;
  final Set<int> remaining;
  final int? selectedTileId;
  final Set<int> hintedTileIds;
  final int? rejectedTileId;
  final int boardTurn;
  final bool english;
  final ValueChanged<MahjongTile> onTileTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFEAF0ED), Color(0xFFDDE7E2)],
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: const Color(0xFFC7D5CF)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x171B3436),
          blurRadius: 23,
          offset: Offset(0, 11),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints limits) {
          final double widthUnits = puzzle.boardWidthUnits.toDouble();
          final double heightUnits = puzzle.boardHeightUnits.toDouble();
          final double side = math.min(
            limits.maxWidth / (widthUnits + puzzle.layerCount * .20),
            limits.maxHeight / (heightUnits + puzzle.layerCount * .20),
          );
          final double tableWidth =
              widthUnits * side + puzzle.layerCount * side * .20;
          final double tableHeight =
              heightUnits * side + puzzle.layerCount * side * .20;
          final double originX = (limits.maxWidth - tableWidth) / 2;
          final double originY =
              (limits.maxHeight - tableHeight) / 2 +
              puzzle.layerCount * side * .12;
          final List<MahjongTile> tiles =
              puzzle.tiles
                  .where((MahjongTile tile) => remaining.contains(tile.id))
                  .toList()
                ..sort((MahjongTile a, MahjongTile b) {
                  final int layer = a.layer.compareTo(b.layer);
                  if (layer != 0) return layer;
                  return a.id.compareTo(b.id);
                });
          return Semantics(
            label: english
                ? 'Layered Mahjong board. Pinch to inspect dense tile groups.'
                : 'Katmanlı Mahjong tahtası. Sık taş gruplarını incelemek için yakınlaştır.',
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 3.2,
              boundaryMargin: const EdgeInsets.all(88),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(
                    child: CustomPaint(painter: _TablePainter()),
                  ),
                  for (final MahjongTile tile in tiles)
                    _positionedTile(
                      tile: tile,
                      side: side,
                      originX: originX,
                      originY: originY,
                    ),
                  Positioned(
                    right: 10,
                    bottom: 8,
                    child: IgnorePointer(
                      child: Text(
                        '${puzzle.layerCount} ${english ? 'LAYERS' : 'KATMAN'}',
                        style: const TextStyle(
                          color: Color(0xFF6C857F),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .65,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _positionedTile({
    required MahjongTile tile,
    required double side,
    required double originX,
    required double originY,
  }) {
    final bool free = puzzle.isTileFree(tile.id, remaining);
    final bool selected = selectedTileId == tile.id;
    final bool hinted = hintedTileIds.contains(tile.id);
    final bool rejected = rejectedTileId == tile.id;
    final double horizontalOffset = tile.layer * side * .20;
    final double verticalOffset = tile.layer * side * -.14;
    double rawLeft =
        originX + (tile.x - puzzle.minimumX) * side + horizontalOffset;
    double rawTop =
        originY + (tile.y - puzzle.minimumY) * side + verticalOffset;
    if (boardTurn == 1) {
      final double width = puzzle.boardWidthUnits * side;
      final double height = puzzle.boardHeightUnits * side;
      rawLeft = originX + width - (rawLeft - originX) - side * 2;
      rawTop = originY + height - (rawTop - originY) - side * 2;
    }
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: rawLeft,
      top: rawTop,
      width: side * 2,
      height: side * 2,
      child: Semantics(
        button: true,
        enabled: free,
        label:
            '${tile.faceLabel}, ${free ? (english ? 'free tile' : 'açık taş') : (english ? 'covered tile' : 'kapalı taş')}',
        child: GestureDetector(
          key: ValueKey<String>('mahjong_tile_${tile.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onTileTap(tile),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: rejected
                ? .92
                : selected || hinted
                ? 1.045
                : 1,
            child: _MahjongTileSurface(
              tile: tile,
              free: free,
              selected: selected,
              hinted: hinted,
              rejected: rejected,
            ),
          ),
        ),
      ),
    );
  }
}

class _MahjongTileSurface extends StatelessWidget {
  const _MahjongTileSurface({
    required this.tile,
    required this.free,
    required this.selected,
    required this.hinted,
    required this.rejected,
  });

  final MahjongTile tile;
  final bool free;
  final bool selected;
  final bool hinted;
  final bool rejected;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CeramicTilePainter(
      free: free,
      selected: selected,
      hinted: hinted,
      rejected: rejected,
      seed: tile.faceKey.hashCode,
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            tile.faceLabel,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: free ? _MahjongPalette.ink : const Color(0xFF889690),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: <Shadow>[
                Shadow(
                  color: Colors.white.withValues(alpha: .85),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TablePainter extends CustomPainter {
  const _TablePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint halo = Paint()
      ..color = const Color(0xFF6C9188).withValues(alpha: .07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(
      Offset(size.width * .52, size.height * .45),
      size.width * .36,
      halo,
    );
    final Paint stitch = Paint()
      ..color = const Color(0xFF79978F).withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final RRect inset = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(20),
    );
    canvas.drawRRect(inset, stitch);
    for (double x = 18; x < size.width - 18; x += 26) {
      canvas.drawCircle(
        Offset(x, 14),
        1,
        Paint()..color = const Color(0xFF7E9992).withValues(alpha: .25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TablePainter oldDelegate) => false;
}

class _CeramicTilePainter extends CustomPainter {
  const _CeramicTilePainter({
    required this.free,
    required this.selected,
    required this.hinted,
    required this.rejected,
    required this.seed,
  });

  final bool free;
  final bool selected;
  final bool hinted;
  final bool rejected;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height);
    final Rect face = Rect.fromLTWH(
      side * .115,
      side * .08,
      side * .78,
      side * .78,
    );
    final RRect body = RRect.fromRectAndRadius(
      face,
      Radius.circular(side * .14),
    );
    final Color edge = selected || hinted
        ? _MahjongPalette.brass
        : rejected
        ? _MahjongPalette.danger
        : free
        ? const Color(0xFFB6C5BF)
        : const Color(0xFFC7D0CB);
    final Paint shadow = Paint()
      ..color = const Color(0xFF244039).withValues(alpha: free ? .25 : .13)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * .065);
    canvas.drawRRect(body.shift(Offset(side * .06, side * .10)), shadow);
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            free ? const Color(0xFFFFFEF9) : const Color(0xFFF2F3EF),
            free ? const Color(0xFFF1F2EA) : const Color(0xFFE4E8E2),
          ],
        ).createShader(face),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected || hinted ? side * .052 : side * .024
        ..color = edge,
    );
    final Paint inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, side * .014)
      ..color = Colors.white.withValues(alpha: .72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        face.deflate(side * .06),
        Radius.circular(side * .085),
      ),
      inner,
    );

    final int pattern = seed.abs() % 4;
    final Paint motif = Paint()
      ..color = (pattern == 0 ? _MahjongPalette.teal : _MahjongPalette.brass)
          .withValues(alpha: free ? .26 : .13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, side * .018);
    final Offset centre = face.center;
    if (pattern == 0) {
      canvas.drawCircle(centre, side * .18, motif);
      canvas.drawCircle(centre, side * .075, motif);
    } else if (pattern == 1) {
      canvas.drawLine(
        centre.translate(-side * .16, 0),
        centre.translate(side * .16, 0),
        motif,
      );
      canvas.drawLine(
        centre.translate(0, -side * .16),
        centre.translate(0, side * .16),
        motif,
      );
    } else if (pattern == 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: centre, width: side * .3, height: side * .3),
          Radius.circular(side * .055),
        ),
        motif,
      );
    } else {
      final Path diamond = Path()
        ..moveTo(centre.dx, centre.dy - side * .19)
        ..lineTo(centre.dx + side * .19, centre.dy)
        ..lineTo(centre.dx, centre.dy + side * .19)
        ..lineTo(centre.dx - side * .19, centre.dy)
        ..close();
      canvas.drawPath(diamond, motif);
    }
  }

  @override
  bool shouldRepaint(covariant _CeramicTilePainter oldDelegate) =>
      oldDelegate.free != free ||
      oldDelegate.selected != selected ||
      oldDelegate.hinted != hinted ||
      oldDelegate.rejected != rejected ||
      oldDelegate.seed != seed;
}
