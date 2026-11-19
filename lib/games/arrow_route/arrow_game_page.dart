import '../shared/studio_game_contracts.dart';

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
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'arrow_puzzle.dart';

class ArrowRouteGamePage extends StatelessWidget {
  const ArrowRouteGamePage({
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
    GameContentPolicy.nativeStages('arrow_route'),
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Ok Rotası ${level.toString().padLeft(2, '0')}',
        titleEn: 'Arrow Route ${level.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: switch (stage) {
          <= 6 => chapter == 1 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.near_me_outlined,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'A denser second field rewards a complete scan before each exit.'
          : 'Daha yoğun ikinci alan, her çıkıştan önce bütün rotayı okumayı ister.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Trace each arrow to the edge before clearing its lane.'
            : 'Şeridi boşaltmadan önce her okun sınır rotasını tara.',
      <= 6 =>
        english
            ? 'Read crossing lanes and uncover the only safe exit.'
            : 'Kesişen şeritleri oku ve güvenli çıkış sırasını bul.',
      7 || 8 =>
        english
            ? 'Advanced: dense blockers hide the forced removal chain.'
            : 'İleri düzey: yoğun engeller zorunlu temizleme zincirini saklar.',
      9 =>
        english
            ? 'Expert field: verify every long lane before committing.'
            : 'Uzman alanı: hamleden önce uzun şeritleri tek tek doğrula.',
      _ =>
        english
            ? 'Master route: untangle a large, fully certified arrow field.'
            : 'Usta rotası: sertifikalı büyük ok alanını adım adım çöz.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('arrow_route');
    return ParkurLevelHub(
      gameId: 'arrow_route',
      progressPrefix: 'arrow_route',
      titleTr: 'Ok Rotası',
      titleEn: 'Arrow Route',
      taglineTr: 'Şeridi tara • Engeli çöz • Oku güvenle çıkar',
      taglineEn: 'Scan the lane • Clear the blocker • Exit with care',
      accent: skin.accent,
      icon: Icons.near_me_outlined,
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
          ) => ArrowRoutePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class ArrowRoutePlayPage extends StatefulWidget {
  const ArrowRoutePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<ArrowRoutePlayPage> createState() => _ArrowRoutePlayPageState();
}

class _ArrowRoutePlayPageState extends State<ArrowRoutePlayPage> {
  static const Color _accent = Color(0xFF665AA2);
  static const Color _boardPaper = Color(0xFFFCFBF8);
  static const Color _gridLine = Color(0xFFE8E5DF);
  static const Color _ink = StudioVisuals.ink;
  static const Color _blocked = Color(0xFFC66A66);
  static const List<Color> _arrowColors = <Color>[
    Color(0xFF5E7DB1),
    Color(0xFF718D79),
    Color(0xFFAA815D),
    Color(0xFF8C78AE),
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.visual,
  );
  final List<int> _moveHistory = <int>[];

  late ArrowPuzzle _puzzle;
  late Set<int> _remaining;
  late StudioGameSession _session;
  int? _selectedId;
  int? _blockerId;
  int? _hintedId;
  int? _exitingId;
  int _mistakes = 0;
  int _hints = 0;
  bool _ready = false;
  bool _animating = false;
  bool _finished = false;
  bool _english = false;
  String? _notice;

  int get _score => math.max(0, 5000 - _hints * 280 - _mistakes * 135);

  int get _stars {
    if (_hints == 0 && _mistakes == 0) return 3;
    if (_hints <= 2 && _mistakes <= 2) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_preparePuzzle());
  }

  Future<void> _preparePuzzle() async {
    ArrowPuzzle puzzle = (widget.level.poolIndex != null
        ? ArrowPuzzle.forPracticeBoard(widget.level.contentIndex)
        : ArrowPuzzle.forLevel(widget.level.contentLevel));
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey = 'arrow_route_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (widget.level.poolIndex == null && visits > 0) {
        final int played =
            await preferences.getInt('arrow_route_practice_index') ?? 0;
        if (played < ArrowPuzzle.maximumVerifiedBoards) {
          final int next = played + 1;
          await preferences.setInt('arrow_route_practice_index', next);
          puzzle = ArrowPuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = (widget.level.poolIndex != null
          ? ArrowPuzzle.forPracticeBoard(widget.level.contentIndex)
          : ArrowPuzzle.forLevel(widget.level.contentLevel));
    }
    if (!mounted) return;
    setState(() {
      _loadPuzzle(puzzle);
      _ready = true;
    });
  }

  void _loadPuzzle(ArrowPuzzle puzzle) {
    _puzzle = puzzle;
    _remaining = puzzle.arrows.map((RouteArrow arrow) => arrow.id).toSet();
    _session = StudioGameSession(level: widget.level.number, seed: puzzle.seed)
      ..start();
    _moveHistory.clear();
    _selectedId = null;
    _blockerId = null;
    _hintedId = null;
    _exitingId = null;
    _mistakes = 0;
    _hints = 0;
    _notice = null;
    _animating = false;
    _finished = false;
  }

  Future<void> _tapArrow(RouteArrow arrow) async {
    if (!_ready || _finished || _animating || !_remaining.contains(arrow.id)) {
      return;
    }
    final RouteArrow? blocker = _puzzle.blockerFor(arrow, _remaining);
    if (blocker != null) {
      _session.recordMistake();
      _mistakes++;
      setState(() {
        _selectedId = arrow.id;
        _blockerId = blocker.id;
        _hintedId = null;
        _notice = _english
            ? 'Lane blocked by the arrow at row ${blocker.row + 1}, column ${blocker.column + 1}.'
            : 'Şerit ${blocker.row + 1}. satır, ${blocker.column + 1}. sütundaki okla kapalı.';
      });
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      return;
    }

    setState(() {
      _selectedId = arrow.id;
      _blockerId = null;
      _hintedId = null;
      _exitingId = arrow.id;
      _animating = true;
      _notice = null;
    });
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
    await Future<void>.delayed(const Duration(milliseconds: 210));
    if (!mounted || _finished) return;
    setState(() {
      _remaining.remove(arrow.id);
      _moveHistory.add(arrow.id);
      _session.recordAccepted(points: 45);
      _selectedId = null;
      _blockerId = null;
      _exitingId = null;
      _animating = false;
      _notice = _english
          ? '${_remaining.length} arrows remain. Scan every lane to the edge.'
          : '${_remaining.length} ok kaldı. Her şeridi sınıra kadar tara.';
    });
    if (_remaining.isEmpty) unawaited(_finish());
  }

  void _undo() {
    if (_finished || _animating || _moveHistory.isEmpty) return;
    final int id = _moveHistory.removeLast();
    setState(() {
      _remaining.add(id);
      _selectedId = null;
      _blockerId = null;
      _hintedId = null;
      _notice = _english
          ? 'Last arrow restored to the board.'
          : 'Son ok tahtaya geri alındı.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (_finished || _animating || !_session.canUseHint) return;
    final int? next = _puzzle.solutionIds.cast<int?>().firstWhere(
      (int? id) => id != null && _remaining.contains(id),
      orElse: () => null,
    );
    if (next == null) return;
    _session.useHint(pointCost: 280);
    setState(() {
      _hints++;
      _selectedId = next;
      _hintedId = next;
      _blockerId = null;
      _notice = _english
          ? 'The highlighted arrow has a clear route to the boundary.'
          : 'Vurgulanan okun sınır çizgisine kadar yolu açık.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .28));
  }

  Future<void> _confirmReset() async {
    if (!_ready || _finished || _animating) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'Restart this field?' : 'Alan yeniden kurulsun mu?',
        ),
        content: Text(
          _english
              ? 'The same certified arrow layout will be restored.'
              : 'Aynı doğrulanmış ok yerleşimi yeniden kurulacak.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep playing' : 'Devam et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_english ? 'Restart' : 'Yeniden başlat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loadPuzzle(_puzzle));
  }

  Future<void> _finish() async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.recordAccepted(points: score);
    _session.complete(
      stars: stars,
      action: widget.level.number < ArrowRouteGamePage.totalCases
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
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'ROTA TEMİZLENDİ',
      titleEn: 'ROUTE CLEARED',
      detailTr: '${_puzzle.arrows.length} ok güvenle çıktı · $_hints ipucu.',
      detailEn: '${_puzzle.arrows.length} arrows exited · $_hints hints.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < ArrowRouteGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: score,
        stars: stars,
        action: action,
      ).toParkurResult(),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: StudioVisuals.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.navigation_rounded, color: _accent, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _english ? 'Arrow Route Rules' : 'Ok Rotası Kuralları',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: StudioVisuals.ink,
                            ),
                          ),
                          Text(
                            _english ? 'Trace clear exit paths' : 'Engelsiz çıkış yolunu bul',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: StudioVisuals.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withValues(alpha: 0.20)),
                  ),
                  child: Text(
                    _english
                        ? 'Tap an arrow to send it flying off the board. An arrow can only escape if no other arrow blocks its forward path to the border. If blocked, remove the blocker first!'
                        : 'Bir oka dokunarak tahtadan dışarı fırlat. Bir ok, yalnızca yöneldiği sınır çizgisine kadar önünde başka hiçbir ok yoksa tahtadan çıkabilir. Eğer önü tıkalıysa önce o engeli temizle!',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      height: 1.4,
                      color: StudioVisuals.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _english ? 'UNDERSTOOD' : 'ANLADIM, BAŞLA',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          backgroundColor: StudioVisuals.canvas,
          foregroundColor: StudioVisuals.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _english ? 'ARROW ROUTE' : 'OK ROTASI',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final RouteArrow? selected = _selectedId == null
        ? null
        : _puzzle.arrowById(_selectedId!);

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
              _english ? 'ARROW ROUTE' : 'OK ROTASI',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              '${_english ? 'Level' : 'Bölüm'} ${widget.level.number} • ${_puzzle.size}×${_puzzle.size}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: _english ? 'How to Play' : 'Nasıl Oynanır',
            icon: const Icon(Icons.help_outline_rounded, size: 22),
            onPressed: () => _showHowToPlay(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Kompakt Tek Satır Durum Çubuğu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudioVisuals.line),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_puzzle.size}×${_puzzle.size}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: _accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_puzzle.arrows.length - _remaining.length}/${_puzzle.arrows.length}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: StudioVisuals.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.flag_rounded, size: 14, color: StudioVisuals.teal),
                          const SizedBox(width: 3),
                          Text(
                            '${_remaining.length}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: StudioVisuals.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: _mistakes > 0 ? StudioVisuals.danger : StudioVisuals.muted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$_mistakes',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _mistakes > 0 ? StudioVisuals.danger : StudioVisuals.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Genişletilmiş Ok Tahtası (Kaydırmasız - Expanded)
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final double maxDimension = math.min(constraints.maxWidth, constraints.maxHeight) - 16;
                        final double cell = (maxDimension / _puzzle.size).clamp(28.0, 56.0);
                        final double boardSize = cell * _puzzle.size;
                        return Container(
                          key: const ValueKey<String>('arrow_route_board'),
                          width: boardSize + 14,
                          height: boardSize + 14,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6E1D8),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFD6D0C5)),
                            boxShadow: StudioVisuals.softShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  CustomPaint(
                                    painter: _ArrowGridPainter(
                                      size: _puzzle.size,
                                      selected: selected,
                                      blocker: _blockerId == null
                                          ? null
                                          : _puzzle.arrowById(_blockerId!),
                                    ),
                                  ),
                                  GridView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _puzzle.size * _puzzle.size,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _puzzle.size,
                                      mainAxisSpacing: 0,
                                      crossAxisSpacing: 0,
                                    ),
                                    itemBuilder: (BuildContext context, int index) {
                                      final int row = index ~/ _puzzle.size;
                                      final int column = index % _puzzle.size;
                                      final RouteArrow? arrow = _puzzle.arrows
                                          .where(
                                            (RouteArrow item) =>
                                                item.row == row &&
                                                item.column == column &&
                                                _remaining.contains(item.id),
                                          )
                                          .firstOrNull;
                                      if (arrow == null) {
                                        return const SizedBox.expand();
                                      }
                                      return _ArrowTile(
                                        key: ValueKey<String>('arrow-tile-${arrow.id}'),
                                        arrow: arrow,
                                        color: _arrowColors[_puzzle.colorIndexFor(arrow)],
                                        cellSize: cell,
                                        selected: _selectedId == arrow.id,
                                        blocked: _blockerId == arrow.id,
                                        hinted: _hintedId == arrow.id,
                                        exiting: _exitingId == arrow.id,
                                        english: _english,
                                        onTap: () => _tapArrow(arrow),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_notice != null) ...<Widget>[
                  const SizedBox(height: 4),
                  _RouteNotice(text: _notice!, warning: _blockerId != null),
                ],
                const SizedBox(height: 6),
                // Alt Kontrol Butonları
                _RouteActions(
                  canUndo: _moveHistory.isNotEmpty,
                  busy: _animating || _finished,
                  english: _english,
                  onUndo: _undo,
                  onHint: _showHint,
                  onReset: _confirmReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowTile extends StatelessWidget {
  const _ArrowTile({
    super.key,
    required this.arrow,
    required this.color,
    required this.cellSize,
    required this.selected,
    required this.blocked,
    required this.hinted,
    required this.exiting,
    required this.english,
    required this.onTap,
  });

  final RouteArrow arrow;
  final Color color;
  final double cellSize;
  final bool selected;
  final bool blocked;
  final bool hinted;
  final bool exiting;
  final bool english;
  final VoidCallback onTap;

  IconData get _icon => switch (arrow.heading) {
    ArrowHeading.north => Icons.arrow_upward_rounded,
    ArrowHeading.east => Icons.arrow_forward_rounded,
    ArrowHeading.south => Icons.arrow_downward_rounded,
    ArrowHeading.west => Icons.arrow_back_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final String direction = switch (arrow.heading) {
      ArrowHeading.north => english ? 'north' : 'kuzeye',
      ArrowHeading.east => english ? 'east' : 'doğuya',
      ArrowHeading.south => english ? 'south' : 'güneye',
      ArrowHeading.west => english ? 'west' : 'batıya',
    };
    return Semantics(
      button: true,
      label: english
          ? 'Arrow ${arrow.id + 1}, row ${arrow.row + 1}, column ${arrow.column + 1}, pointing $direction'
          : '${arrow.id + 1}. ok, ${arrow.row + 1}. satır ${arrow.column + 1}. sütun, $direction',
      child: Padding(
        padding: EdgeInsets.all(cellSize * .075),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: exiting ? .62 : 1,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: exiting ? .15 : 1,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(cellSize * .23),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(cellSize * .23),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        color,
                        Color.lerp(color, _ArrowRoutePlayPageState._ink, .22)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(cellSize * .23),
                    border: Border.all(
                      color: blocked
                          ? _ArrowRoutePlayPageState._blocked
                          : hinted
                          ? const Color(0xFFF1C87B)
                          : selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: .72),
                      width: blocked || hinted || selected ? 2.2 : 1,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: .24),
                        blurRadius: selected || hinted ? 7 : 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _icon,
                      color: Colors.white,
                      size: math.min(24, cellSize * .66),
                      shadows: const <Shadow>[
                        Shadow(color: Color(0x44304455), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowGridPainter extends CustomPainter {
  const _ArrowGridPainter({
    required this.size,
    required this.selected,
    required this.blocker,
  });

  final int size;
  final RouteArrow? selected;
  final RouteArrow? blocker;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final double cell = canvasSize.width / size;
    canvas.drawRect(
      Offset.zero & canvasSize,
      Paint()..color = _ArrowRoutePlayPageState._boardPaper,
    );
    final Paint grid = Paint()
      ..color = _ArrowRoutePlayPageState._gridLine
      ..strokeWidth = 1;
    for (int index = 0; index <= size; index++) {
      final double offset = index * cell;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, canvasSize.height),
        grid,
      );
      canvas.drawLine(
        Offset(0, offset),
        Offset(canvasSize.width, offset),
        grid,
      );
    }

    final RouteArrow? arrow = selected;
    if (arrow == null) return;
    final (int rowDelta, int columnDelta) = switch (arrow.heading) {
      ArrowHeading.north => (-1, 0),
      ArrowHeading.east => (0, 1),
      ArrowHeading.south => (1, 0),
      ArrowHeading.west => (0, -1),
    };
    final Offset start = Offset(
      (arrow.column + .5) * cell,
      (arrow.row + .5) * cell,
    );
    final Offset end;
    if (blocker case final RouteArrow stop) {
      end = Offset((stop.column + .5) * cell, (stop.row + .5) * cell);
    } else {
      final int edgeRow = arrow.row + rowDelta * (size + 1);
      final int edgeColumn = arrow.column + columnDelta * (size + 1);
      end = Offset((edgeColumn + .5) * cell, (edgeRow + .5) * cell);
    }
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color =
            (blocker == null
                    ? _ArrowRoutePlayPageState._accent
                    : _ArrowRoutePlayPageState._blocked)
                .withValues(alpha: .32)
        ..strokeWidth = cell * .085
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      end,
      cell * .11,
      Paint()
        ..color = blocker == null
            ? _ArrowRoutePlayPageState._accent.withValues(alpha: .55)
            : _ArrowRoutePlayPageState._blocked.withValues(alpha: .58),
    );
  }

  @override
  bool shouldRepaint(_ArrowGridPainter oldDelegate) =>
      size != oldDelegate.size ||
      selected?.id != oldDelegate.selected?.id ||
      blocker?.id != oldDelegate.blocker?.id;
}

class _RouteActions extends StatelessWidget {
  const _RouteActions({
    required this.canUndo,
    required this.busy,
    required this.english,
    required this.onUndo,
    required this.onHint,
    required this.onReset,
  });

  final bool canUndo;
  final bool busy;
  final bool english;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _RouteAction(
          icon: Icons.undo_rounded,
          label: english ? 'UNDO' : 'GERİ AL',
          onTap: !busy && canUndo ? onUndo : null,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _RouteAction(
          icon: Icons.lightbulb_outline_rounded,
          label: english ? 'HINT' : 'İPUCU',
          onTap: busy ? null : onHint,
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _RouteAction(
          icon: Icons.restart_alt_rounded,
          label: english ? 'RESTART' : 'BAŞTAN',
          onTap: busy ? null : onReset,
        ),
      ),
    ],
  );
}

class _RouteAction extends StatelessWidget {
  const _RouteAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: StudioVisuals.ink,
      backgroundColor: StudioVisuals.surface,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      side: const BorderSide(color: StudioVisuals.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
    icon: Icon(icon, size: 15),
    label: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _RouteNotice extends StatelessWidget {
  const _RouteNotice({required this.text, required this.warning});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFEFED) : StudioVisuals.amberSoft,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: warning
            ? _ArrowRoutePlayPageState._blocked.withValues(alpha: .22)
            : StudioVisuals.amber.withValues(alpha: .25),
      ),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Roboto',
        color: StudioVisuals.ink,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}