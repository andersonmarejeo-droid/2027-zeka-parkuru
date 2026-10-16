import '../shared/studio_game_contracts.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../games/shared/game_audio_profile.dart';
import '../../games/shared/parkur_game_kit.dart';
import '../../games/shared/studio_game_session.dart';
import '../../games/shared/studio_game_skin.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import 'reference_game_support.dart';
import 'single_stroke_puzzle.dart';

class SingleStrokeGamePage extends StatelessWidget {
  const SingleStrokeGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });
  static const int totalCases = GameContentPolicy.campaignLevels;
  static const int totalStars = totalCases * 3;

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('single_stroke');
    return ParkurLevelHub(
      gameId: 'single_stroke',
      progressPrefix: 'single_stroke',
      titleTr: 'Tek Çizgi Ustası',
      titleEn: 'One-Stroke Master',
      taglineTr: 'Her kenardan yalnızca bir kez geç',
      taglineEn: 'Trace every edge exactly once',
      accent: skin.accent,
      icon: Icons.gesture_rounded,
      levels: referenceLevels(
        titleTr: 'Ağ Ustası',
        titleEn: 'Circuit',
        icon: Icons.gesture_rounded,
        english: context.l10n.isEnglish,
      ),
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder: (
        BuildContext context,
        ParkurLevelSpec level,
        int best,
        int? layout,
        bool competition,
      ) => _SingleStrokePlayPage(
        level: level,
        dailyCourseMode: dailyCourseMode,
      ),
    );
  }
}

class _SingleStrokePlayPage extends StatefulWidget {
  const _SingleStrokePlayPage({
    required this.level,
    required this.dailyCourseMode,
  });
  final ParkurLevelSpec level;
  final bool dailyCourseMode;
  @override
  State<_SingleStrokePlayPage> createState() => _SingleStrokePlayPageState();
}

class _SingleStrokePlayPageState extends State<_SingleStrokePlayPage> {
  static const Color _accent = Color(0xFF665AA2);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _profile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  late final StudioGameSession _session;
  SingleStrokePuzzle? _puzzle;
  final List<int> _trail = <int>[];
  final Set<String> _usedEdges = <String>{};
  bool _loading = true;
  bool _finished = false;
  bool _english = false;
  bool _traceActive = false;
  bool _offLine = false;
  Offset? _lastTracePosition;
  int? _lastRejectedNode;
  String? _feedback;
  int? _hintNode;
  int _mistakes = 0;
  int get _edgesUsed => _usedEdges.length;

  @override
  void initState() {
    super.initState();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_profile.preload(_audio));
    unawaited(_prepare());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _english = context.l10n.isEnglish;
  }

  Future<void> _prepare() async {
    final int variant =
        widget.level.poolIndex ??
        await ReferenceRoundStore.reserve(
          gameId: 'single_stroke',
          level: widget.level.number,
        );
    final SingleStrokePuzzle puzzle = SingleStrokePuzzle.generate(
      widget.level.contentLevel,
      variant,
    );
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _loading = false;
    });
  }

  String _edgeKey(int a, int b) => a < b ? '$a-$b' : '$b-$a';

  int? _nearestNode(
    Offset position,
    Size boardSize, {
    int? from,
    double? hitRadius,
  }) {
    final SingleStrokePuzzle? puzzle = _puzzle;
    if (puzzle == null) return null;
    // Keep the touch target comfortably larger than the visible node. This
    // makes a quick finger movement or a slightly off-centre touch still snap
    // to the intended point, especially on smaller phone screens.
    final double radius = hitRadius ??
        max(26, min(boardSize.width, boardSize.height) * .085);
    final List<int> candidates = <int>[];
    if (from != null) {
      for (final StrokeEdge edge in puzzle.edges) {
        if (edge.a == from && !_usedEdges.contains(edge.key)) {
          candidates.add(edge.b);
        } else if (edge.b == from && !_usedEdges.contains(edge.key)) {
          candidates.add(edge.a);
        }
      }
    } else {
      candidates.addAll(List<int>.generate(puzzle.points.length, (int i) => i));
    }
    int? nearest;
    double nearestDistance = radius;
    for (final int candidate in candidates.toSet()) {
      final StrokePoint point = puzzle.points[candidate];
      final double distance =
          (position -
                  Offset(point.x * boardSize.width, point.y * boardSize.height))
              .distance;
      if (distance <= nearestDistance) {
        nearest = candidate;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  /// Finds a node only when the finger is close to an unused line incident
  /// to the current endpoint. Looking at the nearest node alone is ambiguous
  /// at crossings and dense corners: a nearby branch could be selected even
  /// while the finger is clearly following another line.
  int? _nearestOpenLineNode(Offset position, Size boardSize) {
    final SingleStrokePuzzle? puzzle = _puzzle;
    if (puzzle == null || _trail.isEmpty) return null;

    final int current = _trail.last;
    final String? incomingEdge = _trail.length > 1
        ? _edgeKey(current, _trail[_trail.length - 2])
        : null;
    final double radius = max(
      30,
      min(boardSize.width, boardSize.height) * .095,
    );
    final double lineTolerance = max(
      24,
      min(boardSize.width, boardSize.height) * .09,
    );
    int? nearest;
    double nearestScore = double.infinity;

    for (final StrokeEdge edge in puzzle.edges) {
      if (edge.a != current && edge.b != current) continue;
      if (_usedEdges.contains(edge.key) && edge.key != incomingEdge) continue;

      final int other = edge.a == current ? edge.b : edge.a;
      final StrokePoint startPoint = puzzle.points[current];
      final StrokePoint endPoint = puzzle.points[other];
      final Offset start = Offset(
        startPoint.x * boardSize.width,
        startPoint.y * boardSize.height,
      );
      final Offset end = Offset(
        endPoint.x * boardSize.width,
        endPoint.y * boardSize.height,
      );
      final Offset segment = end - start;
      final double lengthSquared = segment.distanceSquared;
      if (lengthSquared == 0) continue;

      final double projection = (((position - start).dx * segment.dx +
                    (position - start).dy * segment.dy) /
                lengthSquared)
            .clamp(0.0, 1.0)
            .toDouble();
      final Offset closest = start + segment * projection;
      final double lineDistance = (position - closest).distance;
      final double endpointDistance = (position - end).distance;
      if (endpointDistance > radius || lineDistance > lineTolerance) {
        continue;
      }

      final double score = endpointDistance + lineDistance * .35;
      if (score < nearestScore) {
        nearest = other;
        nearestScore = score;
      }
    }
    return nearest;
  }

  bool _isOnOpenLine(Offset position, Size boardSize) {
    final SingleStrokePuzzle? puzzle = _puzzle;
    if (puzzle == null || _trail.isEmpty) return false;
    final int current = _trail.last;
    final String? incomingEdge = _trail.length > 1
        ? _edgeKey(current, _trail[_trail.length - 2])
        : null;
    // The finger is wider than a pixel-perfect line. A generous corridor
    // keeps the stroke active when the finger drifts a little from the guide.
    final double tolerance = max(
      22.0,
      min(boardSize.width, boardSize.height) * .085,
    );
    for (final StrokeEdge edge in puzzle.edges) {
      final bool isIncident = edge.a == current || edge.b == current;
      if (!isIncident ||
          (_usedEdges.contains(edge.key) && edge.key != incomingEdge)) {
        continue;
      }
      final StrokePoint startPoint = puzzle.points[edge.a];
      final StrokePoint endPoint = puzzle.points[edge.b];
      final Offset start = Offset(
        startPoint.x * boardSize.width,
        startPoint.y * boardSize.height,
      );
      final Offset end = Offset(
        endPoint.x * boardSize.width,
        endPoint.y * boardSize.height,
      );
      final Offset segment = end - start;
      final double lengthSquared =
          segment.dx * segment.dx + segment.dy * segment.dy;
      if (lengthSquared == 0) continue;
      final double projection =
          (((position.dx - start.dx) * segment.dx +
                      (position.dy - start.dy) * segment.dy) /
                  lengthSquared)
              .clamp(0.0, 1.0)
              .toDouble();
      if ((position - (start + segment * projection)).distance <= tolerance) {
        return true;
      }
    }
    return false;
  }

  void _startTrace(PointerDownEvent details, Size boardSize) {
    final SingleStrokePuzzle? puzzle = _puzzle;
    if (puzzle == null || _finished) return;
    final int? node = _nearestNode(details.localPosition, boardSize);
    if (node != puzzle.start) {
      _wrong(
        _english
            ? 'Start at the highlighted point.'
            : 'Vurgulanan başlangıç noktasından başla.',
      );
      return;
    }
    _traceActive = true;
    _offLine = false;
    _lastTracePosition = details.localPosition;
    _lastRejectedNode = null;
    setState(() => _feedback = null);
    _visitNode(node!);
  }

  void _continueTrace(PointerMoveEvent details, Size boardSize) {
    if (!_traceActive || _finished || _trail.isEmpty) return;
    final Offset nextPosition = details.localPosition;
    final Offset previousPosition = _lastTracePosition ?? nextPosition;
    final double distance = (nextPosition - previousPosition).distance;
    // Sample more frequently so a fast swipe cannot jump over a node or a
    // short edge between two pointer events.
    final int samples = max(1, (distance / 5).ceil());
    for (int sample = 1; sample <= samples; sample++) {
      final double t = sample / samples;
      final Offset point = Offset.lerp(previousPosition, nextPosition, t)!;
      if (!_isOnOpenLine(point, boardSize)) {
        if (!_offLine) {
          _offLine = true;
          setState(() {
            _feedback = _english
                ? 'Stay close to one of the drawn lines.'
                : 'Parmağını çizgilerin üzerinden ilerlet.';
          });
        }
        continue;
      }
      _offLine = false;
      final int? nextNode = _nearestOpenLineNode(point, boardSize);
      if (nextNode != null && nextNode != _trail.last) {
        _lastRejectedNode = null;
        _visitNode(nextNode);
        if (_finished || _trail.isEmpty) break;
        continue;
      }

      // Give feedback once when the finger reaches a node that cannot be
      // reached from the current endpoint, without penalizing every sample.
      // Use a tighter radius only for the invalid-node warning. The normal
      // transition radius above stays forgiving, while a broad hit area must
      // not turn a near miss at an unrelated node into a penalty.
      final int? rejectedNode = _nearestNode(
        point,
        boardSize,
        hitRadius: max(18, min(boardSize.width, boardSize.height) * .055),
      );
      if (rejectedNode != null &&
          rejectedNode != _trail.last &&
          rejectedNode != _lastRejectedNode) {
        _lastRejectedNode = rejectedNode;
        _wrong(
          _english
              ? 'Follow a line connected to your current point.'
              : 'Bulunduğun noktaya bağlı bir çizgiyi izle.',
        );
      }
    }
    _lastTracePosition = nextPosition;
  }

  void _endTrace() {
    _traceActive = false;
    _offLine = false;
    _lastTracePosition = null;
    _lastRejectedNode = null;
    if (_finished || _trail.isEmpty) return;
    final bool madeProgress = _edgesUsed > 0;
    if (madeProgress) {
      _mistakes++;
      _session.recordMistake();
      _sound(GameAudioEvent.rejected);
    }
    setState(() {
      _trail.clear();
      _usedEdges.clear();
      _hintNode = null;
      _feedback = madeProgress
          ? (_english
                ? 'Keep your finger down until the whole shape is complete.'
                : 'Şekil bitene kadar parmağını kaldırma. Baştan dene.')
          : (_english
                ? 'Trace from the highlighted start point.'
                : 'Vurgulanan başlangıç noktasından çizime başla.');
    });
  }

  void _visitNode(int node) {
    final SingleStrokePuzzle? puzzle = _puzzle;
    if (puzzle == null || _finished) return;
    if (_trail.isEmpty) {
      if (node != puzzle.start) {
        _wrong(
          _english
              ? 'Start at the highlighted point.'
              : 'Vurgulanan başlangıç noktasından başla.',
        );
        return;
      }
      setState(() {
        _trail.add(node);
        _hintNode = null;
        _feedback = null;
      });
      _sound(GameAudioEvent.primaryAction);
      return;
    }
    if (node == _trail.last) return;
    final String key = _edgeKey(_trail.last, node);
    final bool adjacent = puzzle.edges.any(
      (StrokeEdge edge) => edge.key == key,
    );
    if (!adjacent || _usedEdges.contains(key)) {
      _wrong(
        _english
            ? 'That line is not available from this point.'
            : 'Bu çizgi bulunduğun noktadan kullanılamaz.',
      );
      return;
    }
    setState(() {
      _usedEdges.add(key);
      _trail.add(node);
      _hintNode = null;
      _feedback = null;
    });
    _session.recordAccepted(points: 8);
    _sound(GameAudioEvent.accepted);
    if (_usedEdges.length == puzzle.edges.length) {
      if (node == puzzle.end) {
        unawaited(_finish());
      } else {
        _wrong(
          _english
              ? 'Finish at the marked endpoint.'
              : 'İşaretli bitiş noktasında tamamla.',
        );
      }
    }
  }

  void _wrong(String feedback) {
    _mistakes++;
    _session.recordMistake();
    _sound(GameAudioEvent.rejected);
    if (mounted) {
      setState(() {
        _hintNode = null;
        _feedback = feedback;
      });
    }
  }

  void _restartTrace() {
    if (_finished) return;
    setState(() {
      _trail.clear();
      _usedEdges.clear();
      _traceActive = false;
      _offLine = false;
      _lastTracePosition = null;
      _hintNode = null;
      _feedback = _english
          ? 'Start at the highlighted point.'
          : 'Vurgulanan noktadan başla.';
    });
    _sound(GameAudioEvent.primaryAction);
  }

  void _hint() {
    final SingleStrokePuzzle? puzzle = _puzzle;
    if (puzzle == null || _finished || !_session.canUseHint) return;
    _session.useHint(pointCost: 40);
    final int nextIndex = _trail.isEmpty ? 0 : _trail.length;
    setState(
      () => _hintNode = nextIndex < puzzle.solution.length
          ? puzzle.solution[nextIndex]
          : null,
    );
    _sound(GameAudioEvent.hint);
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    final int stars = _mistakes == 0
        ? 3
        : _mistakes <= 2
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: StudioResultAction.next,
    );
    _sound(GameAudioEvent.levelComplete);
    if (mounted) {
      Navigator.of(context).pop(
        widget.dailyCourseMode
            ? result.toDailyStageResult('single_stroke')
            : result.toParkurResult(),
      );
    }
  }

  void _sound(GameAudioEvent event) => unawaited(
    _profile.play(
      _audio,
      event,
      gain: .31,
      levelNumber: event == GameAudioEvent.levelComplete
          ? widget.level.number
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading || _puzzle == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F6F3),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final SingleStrokePuzzle puzzle = _puzzle!;
    return ReferencePlayScaffold(
      title: _english ? 'One-Stroke Master' : 'Tek Çizgi Ustası',
      level: widget.level.number,
      accent: _accent,
      english: _english,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReferenceCard(
            child: Row(
              children: <Widget>[
                const Icon(Icons.route_rounded, color: _accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _english
                            ? 'Complete it in one stroke'
                            : 'Tek çizgide tamamla',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF27333A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _english
                            ? 'Drag from the marked point. Use every line once without lifting your finger.'
                            : 'İşaretli noktadan sürükle. Parmağını kaldırmadan her çizgiden bir kez geç.',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Color(0xFF798780),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ReferenceCard(
            padding: 12,
            child: Column(
              children: <Widget>[
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double width = constraints.maxWidth;
                    final double height = min(width * 1.12, 510);
                    final double nodeSize = max(
                      28,
                      46 - max(0, puzzle.edges.length - 10) * .45,
                    );
                    final Size boardSize = Size(width, height);
                    return SizedBox(
                      width: width,
                      height: height,
                      child: RawGestureDetector(
                        key: const ValueKey<String>(
                          'single_stroke_trace_board',
                        ),
                        behavior: HitTestBehavior.opaque,
                        gestures:
                            <
                              Type,
                              GestureRecognizerFactory<
                                OneSequenceGestureRecognizer
                              >
                            >{
                              _SingleStrokeGestureRecognizer:
                                  GestureRecognizerFactoryWithHandlers<
                                    _SingleStrokeGestureRecognizer
                                  >(() => _SingleStrokeGestureRecognizer(), (
                                    _SingleStrokeGestureRecognizer instance,
                                  ) {
                                    instance.onStart =
                                        (PointerDownEvent details) {
                                          _startTrace(details, boardSize);
                                        };
                                    instance.onUpdate =
                                        (PointerMoveEvent details) {
                                          _continueTrace(details, boardSize);
                                        };
                                    instance.onEnd = (PointerUpEvent details) {
                                      _endTrace();
                                    };
                                    instance.onCancel = _endTrace;
                                  }),
                            },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _StrokeBoardPainter(
                                  puzzle: puzzle,
                                  used: _usedEdges,
                                  trail: _trail,
                                ),
                              ),
                            ),
                            for (int i = 0; i < puzzle.points.length; i++)
                              Positioned(
                                left: puzzle.points[i].x * width - nodeSize / 2,
                                top: puzzle.points[i].y * height - nodeSize / 2,
                                child: IgnorePointer(
                                  // The large white node balloons added visual
                                  // noise to every campaign and replay board.
                                  // Keep only the lightweight point/endpoint
                                  // marker; hit testing remains on the board.
                                  child: SizedBox(
                                    width: nodeSize,
                                    height: nodeSize,
                                    child: Center(
                                      child: i == puzzle.start || i == puzzle.end
                                          ? Icon(
                                              i == puzzle.start
                                                  ? Icons.play_arrow_rounded
                                                  : Icons.flag_rounded,
                                              color: _trail.contains(i)
                                                  ? _accent
                                                  : i == _hintNode
                                                  ? const Color(0xFFD7A84C)
                                                  : _accent,
                                              size: nodeSize * .56,
                                            )
                                          : AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 140,
                                              ),
                                              width: max(
                                                5,
                                                nodeSize *
                                                    (_hintNode == i ? .25 : .17),
                                              ),
                                              height: max(
                                                5,
                                                nodeSize *
                                                    (_hintNode == i ? .25 : .17),
                                              ),
                                              decoration: BoxDecoration(
                                                color: _trail.contains(i)
                                                    ? _accent
                                                    : _hintNode == i
                                                    ? const Color(0xFFD7A84C)
                                                    : _accent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
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
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _english ? puzzle.shapeNameEn : puzzle.shapeNameTr,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Color(0xFF27333A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_english ? 'Lines' : 'Çizgiler'}  $_edgesUsed / ${puzzle.edges.length}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: _accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_feedback != null) ...<Widget>[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F2E8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _feedback!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFF74613B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _restartTrace,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(_english ? 'Restart' : 'Baştan'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _hint,
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: Text(_english ? 'Hint' : 'İpucu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _english
                ? 'Drag from the highlighted start and keep your finger down until you reach the endpoint.'
                : 'Vurgulanan başlangıçtan çiz. Bitiş noktasına ulaşana kadar parmağını ekrandan kaldırma.',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Color(0xFF7C8983),
            ),
          ),
        ],
      ),
    );
  }
}

/// Claims the pointer as soon as it touches the drawing board so the
/// surrounding scroll view cannot steal a vertical stroke mid-shape.
class _SingleStrokeGestureRecognizer extends OneSequenceGestureRecognizer {
  void Function(PointerDownEvent event)? onStart;
  void Function(PointerMoveEvent event)? onUpdate;
  void Function(PointerUpEvent event)? onEnd;
  VoidCallback? onCancel;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onStart?.call(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onUpdate?.call(event);
    } else if (event is PointerUpEvent) {
      onEnd?.call(event);
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      onCancel?.call();
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) => onCancel?.call();

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'single-stroke trace';
}

class _StrokeBoardPainter extends CustomPainter {
  const _StrokeBoardPainter({
    required this.puzzle,
    required this.used,
    required this.trail,
  });
  final SingleStrokePuzzle puzzle;
  final Set<String> used;
  final List<int> trail;
  @override
  void paint(Canvas canvas, Size size) {
    final Paint shadow = Paint()
      ..color = const Color(0xFFEEF0F5)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final Paint base = Paint()
      ..color = const Color(0xFFD8DCE7)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final Paint active = Paint()
      ..color = const Color(0xFF6F63C8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (final StrokeEdge edge in puzzle.edges) {
      final Offset a = Offset(
        puzzle.points[edge.a].x * size.width,
        puzzle.points[edge.a].y * size.height,
      );
      final Offset b = Offset(
        puzzle.points[edge.b].x * size.width,
        puzzle.points[edge.b].y * size.height,
      );
      canvas.drawLine(a, b, shadow);
      canvas.drawLine(a, b, used.contains(edge.key) ? active : base);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokeBoardPainter old) =>
      old.used != used || old.puzzle != puzzle || old.trail != trail;
}
