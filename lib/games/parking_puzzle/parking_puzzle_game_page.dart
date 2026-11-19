import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/studio_visuals.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'parking_puzzle.dart';

class ParkingPuzzleGamePage extends StatelessWidget {
  const ParkingPuzzleGamePage({
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
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Parkur ${level.toString().padLeft(3, '0')}',
        titleEn: 'Route ${level.toString().padLeft(3, '0')}',
        subtitleTr: 'Trafiği çöz, hedef araca çıkış yolu aç',
        subtitleEn: 'Clear a route for the target car',
        difficulty: GameContentPolicy.difficulty(level),
        icon: Icons.directions_car_filled_rounded,
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('parking_puzzle');
    return ParkurLevelHub(
      gameId: 'parking_puzzle',
      progressPrefix: 'parking_puzzle',
      titleTr: 'Park Yeri',
      titleEn: 'Parking Puzzle',
      taglineTr: 'Trafiği planla, hedef aracı çıkışa ulaştır',
      taglineEn: 'Plan the traffic and clear the target car',
      accent: skin.accent,
      icon: Icons.directions_car_filled_rounded,
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
          ) => ParkingPuzzlePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class ParkingPuzzlePlayPage extends StatefulWidget {
  const ParkingPuzzlePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<ParkingPuzzlePlayPage> createState() => _ParkingPuzzlePlayPageState();
}

class _ParkingPuzzlePlayPageState extends State<ParkingPuzzlePlayPage> {
  static const Color _ink = StudioVisuals.ink;
  static const Color _muted = StudioVisuals.muted;
  static const Color _canvas = StudioVisuals.canvas;
  static const Color _target = Color(0xFFD07F52);
  static const List<Color> _carColors = <Color>[
    Color(0xFFD58C61),
    Color(0xFF6095A0),
    Color(0xFF7189B4),
    Color(0xFF8A9B78),
    Color(0xFFB47C89),
    Color(0xFF85919A),
    Color(0xFFBE9B61),
    Color(0xFF7F8FA9),
    Color(0xFF9A806D),
    Color(0xFF668C83),
  ];

  final GlobalKey _boardKey = GlobalKey();
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.strategy,
  );
  final List<List<int>> _undo = <List<int>>[];
  late final ParkingPuzzle _puzzle;
  late final StudioGameSession _session;
  late List<int> _offsets;
  bool _english = false;
  bool _finished = false;
  int? _selectedVehicle;
  int? _draggingVehicle;
  int _dragOrigin = 0;
  int _previewOffset = 0;
  double _dragDelta = 0;
  int? _hintedVehicle;
  int _moves = 0;
  int _hints = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = ParkingPuzzle.forLevel(widget.level.contentIndex);
    _offsets = List<int>.from(_puzzle.initialOffsets);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  void _startDrag(int vehicleIndex) {
    if (_finished) return;
    setState(() {
      _selectedVehicle = vehicleIndex;
      _draggingVehicle = vehicleIndex;
      _dragOrigin = _offsets[vehicleIndex];
      _previewOffset = _dragOrigin;
      _dragDelta = 0;
      _hintedVehicle = null;
    });
    _audio.hapticSelection();
  }

  void _updateDrag(DragUpdateDetails details) {
    final int? index = _draggingVehicle;
    if (index == null) return;
    final ParkingVehicle vehicle = _puzzle.vehicles[index];
    final RenderBox? board =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (board == null || board.size.width <= 0) return;
    final double cellExtent = board.size.width / ParkingPuzzle.boardSize;
    final double delta = vehicle.axis == ParkingAxis.horizontal
        ? details.delta.dx
        : details.delta.dy;
    _dragDelta += delta;
    final int requested = (_dragOrigin + _dragDelta / cellExtent).round().clamp(
      0,
      vehicle.maximumOffset(ParkingPuzzle.boardSize),
    );
    final List<int> reachable = <int>[
      for (
        int offset = 0;
        offset <= vehicle.maximumOffset(ParkingPuzzle.boardSize);
        offset++
      )
        if (offset == _dragOrigin || _puzzle.canMove(_offsets, index, offset))
          offset,
    ];
    int nearest = _dragOrigin;
    for (final int candidate in reachable) {
      if ((candidate - requested).abs() < (nearest - requested).abs()) {
        nearest = candidate;
      }
    }
    setState(() => _previewOffset = nearest);
  }

  void _finishDrag(DragEndDetails details) {
    final int? index = _draggingVehicle;
    if (index == null) return;
    final int destination = _previewOffset;
    setState(() {
      _draggingVehicle = null;
      _dragDelta = 0;
    });
    if (destination == _dragOrigin) return;
    _moveVehicle(index, destination);
  }

  void _moveVehicle(int index, int destination) {
    if (_finished) return;
    if (!_puzzle.canMove(_offsets, index, destination)) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected));
      _audio.hapticLight();
      _showMessage(
        _english
            ? 'That lane is blocked. Move the car in front first.'
            : 'Bu ray kapalı. Önündeki aracı önce hareket ettir.',
      );
      return;
    }
    setState(() {
      _undo.add(List<int>.from(_offsets));
      _offsets = _puzzle.move(_offsets, index, destination);
      _moves++;
      _selectedVehicle = index;
      _hintedVehicle = null;
    });
    _session.recordAccepted();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.primaryAction));
    if (_puzzle.isSolved(_offsets)) unawaited(_complete());
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    setState(() {
      _offsets = _undo.removeLast();
      _moves++;
      _hintedVehicle = null;
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .35));
  }

  void _hint() {
    if (_finished || !_session.canUseHint) return;
    final List<int> hinted = _puzzle.hintOffsets(_offsets);
    int vehicleIndex = -1;
    for (int index = 0; index < hinted.length; index++) {
      if (hinted[index] != _offsets[index]) {
        vehicleIndex = index;
        break;
      }
    }
    if (vehicleIndex < 0) return;
    setState(() {
      _undo.add(List<int>.from(_offsets));
      _offsets = hinted;
      _moves++;
      _hints++;
      _selectedVehicle = vehicleIndex;
      _hintedVehicle = vehicleIndex;
    });
    _session.useHint(pointCost: 100);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint));
    _audio.hapticSelection();
    if (_puzzle.isSolved(_offsets)) unawaited(_complete());
  }

  void _reset() {
    if (_finished) return;
    setState(() {
      _offsets = List<int>.from(_puzzle.initialOffsets);
      _undo.clear();
      _moves = 0;
      _hints = 0;
      _selectedVehicle = null;
      _hintedVehicle = null;
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .35));
  }

  void _showMessage(String message) {
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

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    final int starThreshold = _puzzle.optimalMoves;
    final int stars = _hints > 1
        ? 1
        : _moves <= starThreshold + (_hints == 0 ? 2 : 0)
        ? 3
        : _moves <= starThreshold + 4
        ? 2
        : 1;
    final int score = math.max(120, 1650 - _moves * 32 - _hints * 220);
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < ParkingPuzzleGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticMedium();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .38),
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: _ink,
        icon: const Icon(Icons.route_rounded, color: Color(0xFFE3AA77)),
        title: Text(
          _english ? 'ROUTE CLEARED' : 'YOL AÇILDI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _english
              ? '$stars stars  •  $score points\nThe target car reached the exit.'
              : '$stars yıldız  •  $score puan\nHedef araç çıkışa ulaştı.',
          style: const TextStyle(fontFamily: 'Roboto', color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(
                StudioGameResult.completed(
                  score: score,
                  stars: stars,
                  action: StudioResultAction.map,
                ).toParkurResult(),
              );
            },
            child: Text(_english ? 'ROUTE MAP' : 'PARKUR'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(result.toParkurResult());
            },
            child: Text(
              widget.level.number < ParkingPuzzleGamePage.totalCases
                  ? (_english ? 'NEXT PUZZLE' : 'SONRAKİ BULMACA')
                  : (_english ? 'CHAPTER MAP' : 'BÖLÜM HARİTASI'),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowToPlay() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DDD8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.directions_car_filled_rounded, color: _target, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      _english ? 'How to Play' : 'Nasıl Oynanır?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _english
                      ? '• Your goal is to guide the red car out through the exit on the right.\n• Cars slide only forward and backward along their lanes.\n• Move the blocking vehicles out of the way to clear a path.\n• Finish in as few moves as possible to earn 3 stars!'
                      : '• Hedefiniz kırmızı aracı sağ taraftaki çıkış kapısına ulaştırmaktır.\n• Araçlar sadece kendi doğrultularında (ileri-geri veya yukarı-aşağı) kaydırılabilir.\n• Kırmızı aracın önünü açmak için diğer araçları uygun boşluklara kaydırın.\n• En az hamleyle bitirerek 3 yıldızı kapın!',
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: _target,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _english ? 'Got it' : 'Anladım',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    final int chapter = _puzzle.chapter;
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'PARKING PUZZLE' : 'PARK YERİ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            Text(
              '${_english ? 'ROUTE' : 'BÖLÜM'} ${widget.level.number} / ${GameContentPolicy.campaignLevels}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _showHowToPlay,
            tooltip: _english ? 'How to play' : 'Nasıl Oynanır?',
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 620,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE3E6E1)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A25343D),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAECE5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_english ? 'PACK' : 'PAKET'} $chapter',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: _target,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_english ? 'MOVES' : 'HAMLE'}: ',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$_moves',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: _moves <= _puzzle.optimalMoves ? const Color(0xFF176D62) : const Color(0xFFC46D32),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        ' / ${_puzzle.optimalMoves}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.previousBestScore > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '•  🏆 ${widget.previousBestScore}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: _target,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final double extent = math.min(
                          math.min(constraints.maxWidth, constraints.maxHeight),
                          560,
                        );
                        return SizedBox.square(
                          dimension: extent,
                          child: _ParkingBoard(
                            key: _boardKey,
                            puzzle: _puzzle,
                            offsets: _offsets,
                            selectedVehicle: _selectedVehicle,
                            draggingVehicle: _draggingVehicle,
                            previewOffset: _previewOffset,
                            hintedVehicle: _hintedVehicle,
                            colors: _carColors,
                            english: _english,
                            onTapVehicle: (int index) {
                              setState(() {
                                _selectedVehicle = index;
                                _hintedVehicle = null;
                              });
                              unawaited(
                                _audioProfile.play(
                                  _audio,
                                  GameAudioEvent.menu,
                                  gain: .24,
                                ),
                              );
                            },
                            onDragStart: _startDrag,
                            onDragUpdate: _updateDrag,
                            onDragEnd: _finishDrag,
                            onAccessibleMove: _moveVehicle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _ToolAction(
                        key: const ValueKey<String>('parking_undo'),
                        icon: Icons.undo_rounded,
                        label: _english ? 'UNDO' : 'GERİ AL',
                        onPressed: _undo.isEmpty ? null : _undoMove,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToolAction(
                        key: const ValueKey<String>('parking_hint'),
                        icon: Icons.lightbulb_outline_rounded,
                        label: _english ? 'HINT' : 'İPUCU',
                        onPressed: _hint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToolAction(
                        key: const ValueKey<String>('parking_reset'),
                        icon: Icons.restart_alt_rounded,
                        label: _english ? 'RESET' : 'SIFIRLA',
                        onPressed: _reset,
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



class _ParkingBoard extends StatelessWidget {
  const _ParkingBoard({
    super.key,
    required this.puzzle,
    required this.offsets,
    required this.selectedVehicle,
    required this.draggingVehicle,
    required this.previewOffset,
    required this.hintedVehicle,
    required this.colors,
    required this.english,
    required this.onTapVehicle,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onAccessibleMove,
  });

  final ParkingPuzzle puzzle;
  final List<int> offsets;
  final int? selectedVehicle;
  final int? draggingVehicle;
  final int previewOffset;
  final int? hintedVehicle;
  final List<Color> colors;
  final bool english;
  final ValueChanged<int> onTapVehicle;
  final ValueChanged<int> onDragStart;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final ValueChanged<DragEndDetails> onDragEnd;
  final void Function(int vehicleIndex, int destination) onAccessibleMove;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double extent = constraints.maxWidth;
      final double cell = extent / ParkingPuzzle.boardSize;
      return Container(
        key: const ValueKey<String>('parking_board_surface'),
        decoration: BoxDecoration(
          color: const Color(0xFF2B3438),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF465156), width: 1.4),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1C25343D),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              const Positioned.fill(
                child: CustomPaint(painter: _RoadPainter()),
              ),
              for (int index = 0; index < puzzle.vehicles.length; index++)
                _buildVehicle(index, cell),
              Positioned(
                right: 1,
                top: 2 * cell,
                width: 12,
                height: cell,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFD07F52),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(5),
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildVehicle(int index, double cell) {
    final ParkingVehicle vehicle = puzzle.vehicles[index];
    final bool horizontal = vehicle.axis == ParkingAxis.horizontal;
    final int currentOffset = index == draggingVehicle
        ? previewOffset
        : offsets[index];
    final double inset = cell * .065;
    final double left = horizontal ? currentOffset * cell : vehicle.lane * cell;
    final double top = horizontal ? vehicle.lane * cell : currentOffset * cell;
    final Color color = index == 0
        ? _ParkingPuzzlePlayPageState._target
        : colors[vehicle.colorIndex % colors.length];
    final bool selected = selectedVehicle == index;
    final bool isHinted = hintedVehicle == index;
    final String label = index == 0
        ? (english ? 'Target car' : 'Hedef araç')
        : (english
              ? 'Car ${index.toString().padLeft(2, '0')}'
              : '${index.toString().padLeft(2, '0')}. araç');
    final List<int> destinations = <int>[
      for (
        int offset = 0;
        offset <= vehicle.maximumOffset(ParkingPuzzle.boardSize);
        offset++
      )
        if (offset != offsets[index] && puzzle.canMove(offsets, index, offset))
          offset,
    ];
    final int? backward = destinations
        .where((int value) => value < offsets[index])
        .fold<int?>(
          null,
          (int? best, int value) => best == null || value > best ? value : best,
        );
    final int? forward = destinations
        .where((int value) => value > offsets[index])
        .fold<int?>(
          null,
          (int? best, int value) => best == null || value < best ? value : best,
        );

    return Positioned(
      key: ValueKey<String>('parking_vehicle_$index'),
      left: left,
      top: top,
      width: horizontal ? vehicle.length * cell : cell,
      height: horizontal ? cell : vehicle.length * cell,
      child: Semantics(
        label:
            '$label, ${horizontal ? (english ? 'horizontal' : 'yatay') : (english ? 'vertical' : 'dikey')}, ${offsets[index] + 1}',
        button: true,
        onIncrease: forward == null
            ? null
            : () => onAccessibleMove(index, forward),
        onDecrease: backward == null
            ? null
            : () => onAccessibleMove(index, backward),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTapVehicle(index),
          onPanStart: (_) => onDragStart(index),
          onPanUpdate: onDragUpdate,
          onPanEnd: onDragEnd,
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: AnimatedContainer(
              duration: draggingVehicle == index
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cell * .22),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: draggingVehicle == index ? .38 : .23,
                    ),
                    blurRadius: draggingVehicle == index ? 13 : 7,
                    offset: Offset(0, draggingVehicle == index ? 7 : 4),
                  ),
                  if (selected || isHinted)
                    BoxShadow(
                      color: (isHinted ? const Color(0xFFE8C57A) : color)
                          .withValues(alpha: .42),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: CustomPaint(
                painter: _CarPainter(
                  color: color,
                  horizontal: horizontal,
                  isBus: vehicle.length >= 3,
                  selected: selected || isHinted,
                ),
                child: Center(
                  child: Text(
                    index == 0 ? '★' : '$index',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white.withValues(alpha: .92),
                      fontSize: index == 0 ? 14 : 10,
                      fontWeight: FontWeight.w900,
                      shadows: const <Shadow>[
                        Shadow(color: Color(0x990F2026), blurRadius: 3),
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

class _RoadPainter extends CustomPainter {
  const _RoadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF354044), Color(0xFF242D31)],
        ).createShader(bounds),
    );
    const double cell = 1 / ParkingPuzzle.boardSize;
    final Paint major = Paint()
      ..color = const Color(0xFF9BA7A5).withValues(alpha: .12)
      ..strokeWidth = 1;
    final Paint minor = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = .7;
    for (int index = 1; index < ParkingPuzzle.boardSize; index++) {
      final double x = size.width * index * cell;
      final double y = size.height * index * cell;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), major);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), major);
    }
    for (int row = 0; row < ParkingPuzzle.boardSize; row++) {
      for (int column = 0; column < ParkingPuzzle.boardSize; column++) {
        final Rect slot = Rect.fromLTWH(
          size.width * column * cell + 2,
          size.height * row * cell + 2,
          size.width * cell - 4,
          size.height * cell - 4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(slot, const Radius.circular(9)),
          minor,
        );
      }
    }
    final double laneTop = size.height * 2 * cell;
    final double laneBottom = size.height * 3 * cell;
    final Paint exitPaint = Paint()
      ..color = _ParkingPuzzlePlayPageState._target.withValues(alpha: .24);
    canvas.drawRect(
      Rect.fromLTRB(size.width - 5, laneTop + 2, size.width, laneBottom - 2),
      exitPaint,
    );
    final Paint dash = Paint()
      ..color = const Color(0xFFE6D6C7).withValues(alpha: .4)
      ..strokeWidth = 1.2;
    final double laneCenter = (laneTop + laneBottom) / 2;
    for (double x = 7; x < size.width - 9; x += 24) {
      canvas.drawLine(Offset(x, laneCenter), Offset(x + 9, laneCenter), dash);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => false;
}

class _CarPainter extends CustomPainter {
  const _CarPainter({
    required this.color,
    required this.horizontal,
    required this.isBus,
    required this.selected,
  });

  final Color color;
  final bool horizontal;
  final bool isBus;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final Rect local;
    if (horizontal) {
      local = Rect.fromLTWH(3, 4, size.width - 6, size.height - 8);
    } else {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(math.pi / 2);
      local = Rect.fromCenter(
        center: Offset.zero,
        width: size.height - 6,
        height: size.width - 8,
      );
    }
    final double length = local.width;
    final double height = local.height;
    final double radius = height * (isBus ? .18 : .28);
    final RRect body = RRect.fromRectAndRadius(local, Radius.circular(radius));
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.lerp(color, Colors.white, isBus ? .20 : .14)!,
          color,
          _shade(color, isBus ? .62 : .72),
        ],
        stops: const <double>[0, .42, 1],
      ).createShader(local);
    canvas.drawRRect(
      body,
      Paint()..color = const Color(0xFF10191D).withValues(alpha: .5),
    );
    canvas.drawRRect(body, bodyPaint);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.3 : 1
        ..color = selected
            ? const Color(0xFFFFD996)
            : Colors.white.withValues(alpha: .48),
    );

    final Paint glass = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF9BC7D1), Color(0xFF294958)],
      ).createShader(local);
    final Paint glassEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .35);
    final Paint trim = Paint()
      ..color = const Color(0xFF14262D).withValues(alpha: .78)
      ..strokeWidth = isBus ? 2.4 : 1.5;

    if (isBus) {
      final double windowTop = local.top + height * .15;
      final double windowHeight = height * .43;
      const int windowCount = 3;
      final double windowGap = length * .035;
      final double windowWidth =
          (length * .58 - windowGap * (windowCount - 1)) / windowCount;
      for (int index = 0; index < windowCount; index++) {
        final Rect window = Rect.fromLTWH(
          local.left + length * .18 + index * (windowWidth + windowGap),
          windowTop,
          windowWidth,
          windowHeight,
        );
        final RRect windowShape = RRect.fromRectAndRadius(
          window,
          Radius.circular(height * .08),
        );
        canvas.drawRRect(windowShape, glass);
        canvas.drawRRect(windowShape, glassEdge);
      }
      // Otobüs kapısı ve alt gövde şeridi.
      canvas.drawLine(
        Offset(local.left + length * .78, local.top + height * .12),
        Offset(local.left + length * .78, local.bottom - height * .10),
        trim,
      );
      canvas.drawLine(
        Offset(local.left + length * .10, local.bottom - height * .18),
        Offset(local.right - length * .10, local.bottom - height * .18),
        Paint()
          ..color = Colors.white.withValues(alpha: .24)
          ..strokeWidth = 1.3,
      );
    } else {
      // Sedan kabini: eğimli ön/arka camlar gerçek araba siluetini belirginleştirir.
      final Path cabin = Path()
        ..moveTo(local.left + length * .25, local.bottom - height * .18)
        ..lineTo(local.left + length * .34, local.top + height * .16)
        ..quadraticBezierTo(
          local.center.dx,
          local.top + height * .05,
          local.left + length * .67,
          local.top + height * .16,
        )
        ..lineTo(local.left + length * .77, local.bottom - height * .18)
        ..close();
      canvas.drawPath(cabin, glass);
      canvas.drawPath(cabin, glassEdge);
      canvas.drawLine(
        Offset(local.center.dx, local.top + height * .10),
        Offset(local.center.dx, local.bottom - height * .18),
        trim,
      );
      // Kapı çizgileri ve iki küçük kapı kolu.
      final Paint door = Paint()
        ..color = const Color(0xFF17272D).withValues(alpha: .48)
        ..strokeWidth = .9;
      canvas.drawLine(
        Offset(local.left + length * .18, local.top + height * .24),
        Offset(local.left + length * .18, local.bottom - height * .16),
        door,
      );
      canvas.drawLine(
        Offset(local.left + length * .82, local.top + height * .24),
        Offset(local.left + length * .82, local.bottom - height * .16),
        door,
      );
      final Paint handle = Paint()
        ..color = Colors.white.withValues(alpha: .62)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (final double fraction in <double>[.42, .58]) {
        canvas.drawLine(
          Offset(local.left + length * fraction, local.top + height * .61),
          Offset(local.left + length * fraction + 4, local.top + height * .61),
          handle,
        );
      }
    }

    final Paint tire = Paint()..color = const Color(0xFF172024);
    final double tireRadius = height * (isBus ? .145 : .12);
    for (final double fraction in <double>[.23, .77]) {
      for (final double side in <double>[local.top + 1, local.bottom - 1]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(local.left + length * fraction, side),
              width: tireRadius * 2.2,
              height: tireRadius * 1.1,
            ),
            Radius.circular(tireRadius * .4),
          ),
          tire,
        );
      }
    }
    final Paint headlamp = Paint()..color = const Color(0xFFFFF0B6);
    final Paint tailLamp = Paint()..color = const Color(0xFFE65E5E);
    final double lampWidth = math.max(2, height * (isBus ? .12 : .105));
    for (final double side in <double>[.11, .89]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(local.left + length * side, local.center.dy),
            width: lampWidth,
            height: height * (isBus ? .20 : .15),
          ),
          const Radius.circular(2),
        ),
        side < .5 ? tailLamp : headlamp,
      );
    }
    // Yan aynalar, araçların yönünü ve gerçeklik hissini güçlendirir.
    final Paint mirror = Paint()..color = const Color(0xFF263B42);
    for (final double side in <double>[.31, .69]) {
      canvas.drawCircle(
        Offset(local.left + length * side, local.top + height * .10),
        math.max(1.5, height * .035),
        mirror,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.horizontal != horizontal ||
      oldDelegate.isBus != isBus ||
      oldDelegate.selected != selected;
}

Color _shade(Color color, double factor) =>
    Color.lerp(color, Colors.black, 1 - factor) ?? color;



class _ToolAction extends StatelessWidget {
  const _ToolAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 17),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      foregroundColor: onPressed == null
          ? _ParkingPuzzlePlayPageState._muted.withValues(alpha: .55)
          : _ParkingPuzzlePlayPageState._ink,
      backgroundColor: Colors.white,
      minimumSize: const Size(48, 44),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      side: const BorderSide(color: Color(0xFFE1E5E0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      textStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
