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
import 'warehouse_puzzle.dart';

/// S04 — a push-planning game with an explicit shortest-push certificate.
class WarehouseMasterGamePage extends StatelessWidget {
  const WarehouseMasterGamePage({
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
        titleTr: 'Depo ${number.toString().padLeft(3, '0')}',
        titleEn: 'Warehouse ${number.toString().padLeft(3, '0')}',
        subtitleTr: _stageSubtitle(stage, english: false),
        subtitleEn: _stageSubtitle(stage, english: true),
        difficulty: _stageName(stage, english: false),
        icon: Icons.inventory_2_outlined,
      );
    },
  );

  static String _stageName(int stage, {required bool english}) =>
      switch (stage) {
        <= 2 => english ? 'APPRENTICE' : 'ÇIRAK',
        <= 6 => english ? 'PLANNER' : 'PLANLAYICI',
        <= 8 => english ? 'ADVANCED' : 'İLERİ',
        9 => english ? 'EXPERT' : 'UZMAN',
        _ => english ? 'MASTER' : 'USTA',
      };

  static String _stageSubtitle(
    int stage, {
    required bool english,
  }) => switch (stage) {
    1 =>
      english ? 'Learn the weight of a push.' : 'Bir itişin ağırlığını öğren.',
    2 =>
      english
          ? 'Keep every crate recoverable.'
          : 'Her kasayı kurtarılabilir tut.',
    3 =>
      english ? 'Read the room before moving.' : 'Hareket etmeden alanı oku.',
    4 =>
      english
          ? 'Route one crate around another.'
          : 'Bir kasayı diğerinin çevresinden dolaştır.',
    5 => english ? 'Protect the narrow corridors.' : 'Dar koridorları koru.',
    6 =>
      english
          ? 'Sequence goals without deadlocks.'
          : 'Çıkmaz oluşturmadan hedefleri sırala.',
    7 =>
      english
          ? 'Plan several pushes ahead.'
          : 'İtişleri birkaç adım sonrasıyla planla.',
    8 => english ? 'Keep multiple routes open.' : 'Birden çok rotayı açık tut.',
    9 =>
      english ? 'Resolve a dense expert layout.' : 'Yoğun uzman düzenini çöz.',
    _ =>
      english
          ? 'Prove the cleanest crate sequence.'
          : 'En temiz kasa sırasını kanıtla.',
  };

  @override
  Widget build(BuildContext context) {
    return ParkurLevelHub(
      gameId: 'warehouse_master',
      progressPrefix: 'warehouse_master',
      titleTr: 'Depo Ustası',
      titleEn: 'Warehouse Master',
      taglineTr: 'Kasaları it, çıkmazlara düşmeden hedefleri sırala.',
      taglineEn: 'Push each crate and sequence every goal without a deadlock.',
      accent: _WarehousePalette.copper,
      icon: Icons.inventory_2_outlined,
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
          ) => WarehouseMasterPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class WarehouseMasterPlayPage extends StatefulWidget {
  const WarehouseMasterPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<WarehouseMasterPlayPage> createState() =>
      _WarehouseMasterPlayPageState();
}

class _WarehouseMasterPlayPageState extends State<WarehouseMasterPlayPage> {
  final GlobalKey _boardKey = GlobalKey();
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.strategy,
  );
  final List<WarehouseState> _undo = <WarehouseState>[];
  late final WarehousePuzzle _puzzle;
  late WarehouseState _state;
  late StudioGameSession _session;

  bool _english = false;
  bool _finished = false;
  int? _hintedCell;
  int _hints = 0;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _puzzle = WarehousePuzzle.forLevel(widget.level.number);
    _state = _puzzle.initialState;
    _startSession();
    unawaited(_audioProfile.preload(_audio));
  }

  void _startSession() {
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
  }

  int get _cratesOnGoal => _state.crates.where(_puzzle.goals.contains).length;

  void _move(WarehouseDirection direction) {
    if (_finished || !_session.acceptsInput) return;
    final WarehouseState? next = _puzzle.move(_state, direction);
    if (next == null) {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .24));
      _showNotice(
        _english
            ? 'The route is blocked. A crate can only be pushed into free space.'
            : 'Rota kapalı. Kasa yalnızca boş bir hücreye itilebilir.',
      );
      return;
    }
    _commit(next);
  }

  void _commit(WarehouseState next) {
    _undo.add(_state);
    if (_undo.length > 120) _undo.removeAt(0);
    setState(() {
      _state = next;
      _hintedCell = null;
      _notice = null;
    });
    _session.recordAccepted();
    _audio.hapticLight();
    unawaited(
      _audioProfile.play(
        _audio,
        next.pushes > _undo.last.pushes
            ? GameAudioEvent.primaryAction
            : GameAudioEvent.accepted,
        gain: next.pushes > _undo.last.pushes ? .34 : .2,
      ),
    );
    if (_puzzle.isSolved(next)) unawaited(_complete());
  }

  void _tapBoard(Offset localPosition, Size size) {
    if (_finished || size.width <= 0 || size.height <= 0) return;
    final int column = (localPosition.dx / (size.width / _puzzle.columns))
        .floor()
        .clamp(0, _puzzle.columns - 1);
    final int row = (localPosition.dy / (size.height / _puzzle.rows))
        .floor()
        .clamp(0, _puzzle.rows - 1);
    final int target = _puzzle.indexAt(row, column);
    final int rowDelta = row - _puzzle.rowOf(_state.player);
    final int columnDelta = column - _puzzle.columnOf(_state.player);
    if (rowDelta.abs() + columnDelta.abs() != 1) return;
    final WarehouseDirection direction = rowDelta < 0
        ? WarehouseDirection.up
        : rowDelta > 0
        ? WarehouseDirection.down
        : columnDelta < 0
        ? WarehouseDirection.left
        : WarehouseDirection.right;
    if (target == _state.player) return;
    _move(direction);
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    setState(() {
      _state = _undo.removeLast();
      _hintedCell = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .25));
    _showNotice(_english ? 'Last move restored.' : 'Son hamle geri alındı.');
  }

  void _restart() {
    if (_finished) return;
    setState(() {
      _state = _puzzle.initialState;
      _undo.clear();
      _hints = 0;
      _hintedCell = null;
      _notice = null;
      _startSession();
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .25));
  }

  void _showHint() {
    if (_finished || !_session.canUseHint) return;
    final WarehouseAction? action = _puzzle.hintFor(_state);
    if (action == null) return;
    final int? target = _puzzle.neighbor(_state.player, action.direction);
    if (target == null) return;
    setState(() {
      _hintedCell = target;
      _hints++;
    });
    _session.useHint(pointCost: 120);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .32));
    _audio.hapticSelection();
    _showNotice(
      action.isPush
          ? (_english
                ? 'Verified push: send the highlighted crate into its lane.'
                : 'Doğrulanmış itiş: vurgulanan kasayı rotasına it.')
          : (_english
                ? 'Verified step: move toward the highlighted tile.'
                : 'Doğrulanmış adım: vurgulanan hücreye doğru ilerle.'),
    );
  }

  void _showNotice(String message) {
    if (!mounted) return;
    setState(() => _notice = message);
  }

  int _stars() {
    if (_hints == 0 &&
        _session.mistakes == 0 &&
        _state.pushes == _puzzle.optimalPushes) {
      return 3;
    }
    if (_hints <= 2 && _session.mistakes <= 1) return 2;
    return 1;
  }

  int _score() => math.max(
    250,
    3400 -
        _state.moves * 7 -
        _state.pushes * 16 -
        _hints * 150 -
        _session.mistakes * 230,
  );

  Future<void> _complete() async {
    if (_finished || !_session.acceptsInput) return;
    _finished = true;
    final int score = _score();
    final int stars = _stars();
    _session.recordAccepted(points: score);
    _session.complete(
      stars: stars,
      action: widget.level.number < WarehouseMasterGamePage.totalCases
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
      accent: _WarehousePalette.copper,
      titleTr: 'DEPO PLANI TAMAMLANDI',
      titleEn: 'WAREHOUSE CLEARED',
      detailTr:
          '$_cratesOnGoal/${_puzzle.crateCount} kasa hedefte · ${_state.pushes} / ${_puzzle.optimalPushes} en az itiş · ${_state.moves} hamle.',
      detailEn:
          '$_cratesOnGoal/${_puzzle.crateCount} crates placed · ${_state.pushes} / ${_puzzle.optimalPushes} minimum pushes · ${_state.moves} moves.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < WarehouseMasterGamePage.totalCases,
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

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    final int stage = _puzzle.stageInChapter;
    return Scaffold(
      backgroundColor: _WarehousePalette.canvas,
      appBar: AppBar(
        backgroundColor: _WarehousePalette.canvas,
        foregroundColor: _WarehousePalette.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'WAREHOUSE MASTER' : 'DEPO USTASI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            Text(
              '${_english ? 'BAY' : 'DEPO'} ${widget.level.number.toString().padLeft(3, '0')} · ${WarehouseMasterGamePage._stageName(stage, english: _english)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _WarehousePalette.muted,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('warehouse_undo'),
            tooltip: _english ? 'Undo move' : 'Hamleyi geri al',
            onPressed: _undo.isEmpty ? null : _undoMove,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('warehouse_restart'),
            tooltip: _english ? 'Restart level' : 'Bölümü sıfırla',
            onPressed: _restart,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 700,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints limits) {
              final bool compact =
                  limits.maxWidth < 390 || limits.maxHeight < 670;
              final double boardExtent = math.max(
                202,
                math.min(
                  limits.maxWidth - 24,
                  compact ? limits.maxHeight * .39 : limits.maxHeight * .53,
                ),
              );
              return ListView(
                key: const ValueKey<String>('warehouse_scroll'),
                padding: EdgeInsets.fromLTRB(12, 4, 12, compact ? 10 : 20),
                children: <Widget>[
                  _WarehouseStatusCard(
                    level: widget.level.number,
                    chapter: _puzzle.chapter,
                    stage: stage,
                    tier: _puzzle.difficultyTier,
                    cratesOnGoal: _cratesOnGoal,
                    crates: _puzzle.crateCount,
                    pushes: _state.pushes,
                    optimalPushes: _puzzle.optimalPushes,
                    moves: _state.moves,
                    bestScore: widget.previousBestScore,
                    english: _english,
                  ),
                  SizedBox(height: compact ? 7 : 11),
                  SizedBox(
                    height: boardExtent,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Semantics(
                          label: _english
                              ? 'Warehouse board, ${_puzzle.crateCount} crates, $_cratesOnGoal on goals'
                              : 'Depo tahtası, ${_puzzle.crateCount} kasa, hedefte $_cratesOnGoal kasa',
                          child: GestureDetector(
                            key: const ValueKey<String>('warehouse_board'),
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (TapUpDetails details) {
                              final RenderBox? box =
                                  _boardKey.currentContext?.findRenderObject()
                                      as RenderBox?;
                              if (box == null) return;
                              _tapBoard(details.localPosition, box.size);
                            },
                            onHorizontalDragEnd: (DragEndDetails details) {
                              final double velocity =
                                  details.primaryVelocity ?? 0;
                              if (velocity.abs() < 100) return;
                              _move(
                                velocity < 0
                                    ? WarehouseDirection.left
                                    : WarehouseDirection.right,
                              );
                            },
                            onVerticalDragEnd: (DragEndDetails details) {
                              final double velocity =
                                  details.primaryVelocity ?? 0;
                              if (velocity.abs() < 100) return;
                              _move(
                                velocity < 0
                                    ? WarehouseDirection.up
                                    : WarehouseDirection.down,
                              );
                            },
                            child: CustomPaint(
                              painter: _WarehouseBoardPainter(
                                puzzle: _puzzle,
                                state: _state,
                                hintedCell: _hintedCell,
                              ),
                              child: KeyedSubtree(
                                key: _boardKey,
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  _WarehouseGoalRail(
                    goals: _puzzle.crateCount,
                    completed: _cratesOnGoal,
                    english: _english,
                    notice: _notice,
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  _WarehouseControls(
                    english: _english,
                    onMove: _move,
                    onHint: _showHint,
                    onUndo: _undoMove,
                    onRestart: _restart,
                    canUndo: _undo.isNotEmpty,
                  ),
                  SizedBox(height: compact ? 5 : 8),
                  Text(
                    _english
                        ? 'A crate never pulls back. Before pushing, leave a route to the next side.'
                        : 'Kasa geri çekilemez. İtişten önce sonraki tarafına ulaşan bir rota bırak.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _WarehousePalette.muted,
                      fontSize: 10,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
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

class _WarehouseStatusCard extends StatelessWidget {
  const _WarehouseStatusCard({
    required this.level,
    required this.chapter,
    required this.stage,
    required this.tier,
    required this.cratesOnGoal,
    required this.crates,
    required this.pushes,
    required this.optimalPushes,
    required this.moves,
    required this.bestScore,
    required this.english,
  });

  final int level;
  final int chapter;
  final int stage;
  final String tier;
  final int cratesOnGoal;
  final int crates;
  final int pushes;
  final int optimalPushes;
  final int moves;
  final int bestScore;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
    decoration: BoxDecoration(
      color: _WarehousePalette.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _WarehousePalette.line),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x0D34414A),
          blurRadius: 15,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _WarehousePalette.copper.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: _WarehousePalette.copper,
                size: 19,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    english
                        ? 'BAY ${level.toString().padLeft(3, '0')}'
                        : 'DEPO ${level.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      color: _WarehousePalette.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                  Text(
                    '${english ? 'CHAPTER' : 'PAKET'} $chapter · ${english ? 'STAGE' : 'AŞAMA'} $stage / 10',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _WarehousePalette.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: _WarehousePalette.copper.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                tier,
                style: const TextStyle(
                  color: _WarehousePalette.copperDark,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .55,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: <Widget>[
            _Metric(
              icon: Icons.flag_outlined,
              value: '$cratesOnGoal/$crates',
              label: english ? 'PLACED' : 'HEDEFTE',
            ),
            _Metric(
              icon: Icons.north_east_rounded,
              value: '$pushes/$optimalPushes',
              label: english ? 'PUSHES / BEST' : 'İTİŞ / EN AZ',
            ),
            _Metric(
              icon: Icons.directions_walk_rounded,
              value: '$moves',
              label: english ? 'MOVES' : 'HAMLE',
            ),
            _Metric(
              icon: Icons.emoji_events_outlined,
              value: '$bestScore',
              label: english ? 'BEST' : 'REKOR',
            ),
          ],
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: <Widget>[
        Icon(icon, color: _WarehousePalette.copper, size: 14),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _WarehousePalette.ink,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _WarehousePalette.muted,
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: .25,
          ),
        ),
      ],
    ),
  );
}

class _WarehouseGoalRail extends StatelessWidget {
  const _WarehouseGoalRail({
    required this.goals,
    required this.completed,
    required this.english,
    required this.notice,
  });

  final int goals;
  final int completed;
  final bool english;
  final String? notice;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 39),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: notice == null
          ? _WarehousePalette.surface.withValues(alpha: .78)
          : _WarehousePalette.copper.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _WarehousePalette.line),
    ),
    child: Row(
      children: <Widget>[
        if (notice == null) ...<Widget>[
          const Icon(
            Icons.flag_rounded,
            color: _WarehousePalette.copper,
            size: 15,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              english
                  ? 'Place every crate on a brass seal'
                  : 'Her kasayı pirinç hedefe ulaştır',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _WarehousePalette.ink,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ] else ...<Widget>[
          const Icon(
            Icons.tips_and_updates_outlined,
            color: _WarehousePalette.copperDark,
            size: 15,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              notice!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _WarehousePalette.ink,
                fontSize: 9,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int index = 0; index < goals; index++)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Icon(
                  index < completed
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: index < completed
                      ? _WarehousePalette.teal
                      : _WarehousePalette.goalMuted,
                  size: 13,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _WarehouseControls extends StatelessWidget {
  const _WarehouseControls({
    required this.english,
    required this.onMove,
    required this.onHint,
    required this.onUndo,
    required this.onRestart,
    required this.canUndo,
  });

  final bool english;
  final ValueChanged<WarehouseDirection> onMove;
  final VoidCallback onHint;
  final VoidCallback onUndo;
  final VoidCallback onRestart;
  final bool canUndo;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Expanded(
        flex: 7,
        child: Column(
          children: <Widget>[
            _DirectionKey(
              keyName: 'warehouse_up',
              tooltip: english ? 'Move up' : 'Yukarı ilerle',
              icon: Icons.keyboard_arrow_up_rounded,
              onPressed: () => onMove(WarehouseDirection.up),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _DirectionKey(
                  keyName: 'warehouse_left',
                  tooltip: english ? 'Move left' : 'Sola ilerle',
                  icon: Icons.keyboard_arrow_left_rounded,
                  onPressed: () => onMove(WarehouseDirection.left),
                ),
                const SizedBox(width: 5),
                _DirectionKey(
                  keyName: 'warehouse_down',
                  tooltip: english ? 'Move down' : 'Aşağı ilerle',
                  icon: Icons.keyboard_arrow_down_rounded,
                  onPressed: () => onMove(WarehouseDirection.down),
                ),
                const SizedBox(width: 5),
                _DirectionKey(
                  keyName: 'warehouse_right',
                  tooltip: english ? 'Move right' : 'Sağa ilerle',
                  icon: Icons.keyboard_arrow_right_rounded,
                  onPressed: () => onMove(WarehouseDirection.right),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        flex: 5,
        child: Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey<String>('warehouse_hint'),
                onPressed: onHint,
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                label: Text(english ? 'PLAN' : 'İPUCU'),
                style: FilledButton.styleFrom(
                  backgroundColor: _WarehousePalette.teal,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey<String>('warehouse_undo_control'),
                    onPressed: canUndo ? onUndo : null,
                    icon: const Icon(Icons.undo_rounded, size: 15),
                    label: Text(english ? 'UNDO' : 'GERİ'),
                    style: _secondaryButtonStyle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey<String>('warehouse_restart_control'),
                    onPressed: onRestart,
                    icon: const Icon(Icons.restart_alt_rounded, size: 15),
                    label: Text(english ? 'RESET' : 'SIFIRLA'),
                    style: _secondaryButtonStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  static final ButtonStyle _secondaryButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 5),
    foregroundColor: _WarehousePalette.ink,
    side: const BorderSide(color: _WarehousePalette.line),
    textStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _DirectionKey extends StatelessWidget {
  const _DirectionKey({
    required this.keyName,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String keyName;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 48,
    child: Material(
      color: _WarehousePalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: _WarehousePalette.line),
      ),
      child: IconButton(
        key: ValueKey<String>(keyName),
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: _WarehousePalette.ink, size: 24),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    ),
  );
}

class _WarehouseBoardPainter extends CustomPainter {
  const _WarehouseBoardPainter({
    required this.puzzle,
    required this.state,
    required this.hintedCell,
  });

  final WarehousePuzzle puzzle;
  final WarehouseState state;
  final int? hintedCell;

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / puzzle.columns;
    final double cellH = size.height / puzzle.rows;
    final Rect outer = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(20)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFE5E3DC),
            Color(0xFFF7F5EF),
          ],
        ).createShader(outer),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(.75), const Radius.circular(20)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFD1CEC5),
    );

    for (int cell = 0; cell < puzzle.cellCount; cell++) {
      final int row = puzzle.rowOf(cell);
      final int column = puzzle.columnOf(cell);
      final Rect tile = Rect.fromLTWH(
        column * cellW + 1,
        row * cellH + 1,
        cellW - 2,
        cellH - 2,
      ).deflate(1.15);
      final RRect rounded = RRect.fromRectAndRadius(
        tile,
        Radius.circular(math.max(2.5, cellW * .11)),
      );
      if (puzzle.isWall(cell)) {
        _drawWall(canvas, rounded);
      } else {
        _drawFloor(canvas, rounded, row, column);
        if (puzzle.isGoal(cell)) _drawGoal(canvas, tile);
      }
    }

    for (final int crate in state.crates) {
      _drawCrate(canvas, crate, cellW, cellH, puzzle.isGoal(crate));
    }
    _drawWorker(canvas, state.player, cellW, cellH);
    if (hintedCell case final int cell) _drawHint(canvas, cell, cellW, cellH);
  }

  void _drawFloor(Canvas canvas, RRect rect, int row, int column) {
    final Color tint = (row + column).isEven
        ? const Color(0xFFF0EFE9)
        : const Color(0xFFEAE9E2);
    canvas.drawRRect(rect, Paint()..color = tint);
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .55
        ..color = const Color(0xFFDCDAD2).withValues(alpha: .6),
    );
  }

  void _drawWall(Canvas canvas, RRect rect) {
    canvas.drawRRect(
      rect.shift(const Offset(0, 1.8)),
      Paint()
        ..color = const Color(0x22293337)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFD8D7D1),
            Color(0xFFC4C4BE),
            Color(0xFFB6B8B4),
          ],
        ).createShader(rect.outerRect),
    );
    canvas.drawRRect(
      rect.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = const Color(0x88FFFFFF),
    );
    final double dot = math.max(1.2, rect.width * .035);
    for (final Offset position in <Offset>[
      rect.outerRect.topLeft + Offset(dot * 1.6, dot * 1.6),
      rect.outerRect.topRight + Offset(-dot * 1.6, dot * 1.6),
      rect.outerRect.bottomLeft + Offset(dot * 1.6, -dot * 1.6),
      rect.outerRect.bottomRight + Offset(-dot * 1.6, -dot * 1.6),
    ]) {
      canvas.drawCircle(
        position,
        dot,
        Paint()..color = const Color(0xFF8D918E),
      );
      canvas.drawCircle(
        position.translate(-dot * .2, -dot * .2),
        dot * .38,
        Paint()..color = const Color(0x88FFFFFF),
      );
    }
  }

  void _drawGoal(Canvas canvas, Rect tile) {
    final Offset center = tile.center;
    final double radius = tile.shortestSide * .27;
    canvas.drawCircle(
      center.translate(0, radius * .22),
      radius * 1.18,
      Paint()
        ..color = const Color(0x224B3C24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0xFFFFF9E8),
            Color(0xFFE8C87F),
            Color(0xFFB9863E),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * .72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, radius * .12)
        ..color = const Color(0xFF96703F),
    );
    canvas.drawCircle(
      center,
      radius * .38,
      Paint()..color = const Color(0xFFFAF4E6),
    );
  }

  void _drawCrate(
    Canvas canvas,
    int cell,
    double cellW,
    double cellH,
    bool onGoal,
  ) {
    final int row = puzzle.rowOf(cell);
    final int column = puzzle.columnOf(cell);
    final Rect base = Rect.fromLTWH(
      column * cellW + cellW * .13,
      row * cellH + cellH * .12,
      cellW * .74,
      cellH * .74,
    );
    final RRect box = RRect.fromRectAndRadius(
      base,
      Radius.circular(cellW * .12),
    );
    canvas.drawRRect(
      box.shift(Offset(0, cellH * .055)),
      Paint()
        ..color = const Color(0x3D403326)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cellW * .07),
    );
    canvas.drawRRect(
      box,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onGoal
              ? const <Color>[
                  Color(0xFF70A99D),
                  Color(0xFF47877D),
                  Color(0xFF356E67),
                ]
              : const <Color>[
                  Color(0xFFE0B586),
                  Color(0xFFC28C5F),
                  Color(0xFFA96F49),
                ],
        ).createShader(base),
    );
    final Rect inset = base.deflate(cellW * .09);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, Radius.circular(cellW * .08)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, cellW * .025)
        ..color = onGoal ? const Color(0x99D5F1E7) : const Color(0xAA704B32),
    );
    final Paint grain = Paint()
      ..color = onGoal ? const Color(0x6672B0A3) : const Color(0x66F0D0A5)
      ..strokeWidth = math.max(1, cellW * .025)
      ..strokeCap = StrokeCap.round;
    for (int line = 0; line < 3; line++) {
      final double x = base.left + base.width * (.29 + line * .21);
      canvas.drawLine(
        Offset(x, base.top + base.height * .22),
        Offset(x, base.bottom - base.height * .22),
        grain,
      );
    }
    final double nail = math.max(1.1, cellW * .028);
    for (final Offset point in <Offset>[
      base.topLeft + Offset(cellW * .12, cellH * .12),
      base.topRight + Offset(-cellW * .12, cellH * .12),
      base.bottomLeft + Offset(cellW * .12, -cellH * .12),
      base.bottomRight + Offset(-cellW * .12, -cellH * .12),
    ]) {
      canvas.drawCircle(point, nail, Paint()..color = const Color(0xCCEFE0C9));
    }
  }

  void _drawWorker(Canvas canvas, int cell, double cellW, double cellH) {
    final Offset topLeft = Offset(
      puzzle.columnOf(cell) * cellW,
      puzzle.rowOf(cell) * cellH,
    );
    final Offset center = topLeft + Offset(cellW / 2, cellH / 2);
    final double radius = cellW * .28;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius * .9),
        width: radius * 1.7,
        height: radius * .6,
      ),
      Paint()
        ..color = const Color(0x33344145)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.28, -.35),
          colors: <Color>[
            Color(0xFF536B76),
            Color(0xFF2E414A),
            Color(0xFF1F3038),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * .72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, cellW * .025)
        ..color = const Color(0x88FFFFFF),
    );
    canvas.drawCircle(
      center.translate(0, -radius * .08),
      radius * .24,
      Paint()..color = const Color(0xFFF0D1A5),
    );
    final Rect shoulders = Rect.fromCenter(
      center: center.translate(0, radius * .42),
      width: radius * 1.05,
      height: radius * .42,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shoulders, Radius.circular(radius * .2)),
      Paint()..color = const Color(0xFF9DBAB4),
    );
  }

  void _drawHint(Canvas canvas, int cell, double cellW, double cellH) {
    final Rect rect = Rect.fromLTWH(
      puzzle.columnOf(cell) * cellW + 2,
      puzzle.rowOf(cell) * cellH + 2,
      cellW - 4,
      cellH - 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cellW * .12)),
      Paint()
        ..color = const Color(0x2270A99D)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cellW * .12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF3D897C),
    );
  }

  @override
  bool shouldRepaint(_WarehouseBoardPainter oldDelegate) =>
      oldDelegate.puzzle != puzzle ||
      oldDelegate.state.signature != state.signature ||
      oldDelegate.hintedCell != hintedCell;
}

abstract final class _WarehousePalette {
  static const Color canvas = Color(0xFFF5F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF29383D);
  static const Color muted = Color(0xFF738087);
  static const Color line = Color(0xFFE3E4DF);
  static const Color copper = Color(0xFFC18852);
  static const Color copperDark = Color(0xFF8B5D34);
  static const Color teal = Color(0xFF4F8D83);
  static const Color goalMuted = Color(0xFFC0B69F);
}
