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
import 'hex_position.dart';

class HexConnectionGamePage extends StatelessWidget {
  const HexConnectionGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = HexScenarioBank.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Hex ${level.toString().padLeft(2, '0')}',
        titleEn: 'Hex ${level.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: switch (stage) {
          <= 6 => chapter == 1 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.hexagon_outlined,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'Read earlier openings and plan a resilient bridge.'
          : 'Önceki açılışı oku; dayanıklı bir köprü planla.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Connect the coral sides before the blue path closes.'
            : 'Lacivert yol kapanmadan koral kenarları bağla.',
      <= 6 =>
        english
            ? 'Use adjacent hexes to build an unbroken route.'
            : 'Kesintisiz bir rota için komşu altıgenleri kullan.',
      7 || 8 =>
        english
            ? 'Advanced: preserve a bridge while denying the rival.'
            : 'İleri: rakibi durdururken köprü bağlantını koru.',
      9 =>
        english
            ? 'Expert: face the larger board and deeper responses.'
            : 'Uzman: daha büyük tahta ve derin rakip araması.',
      _ =>
        english
            ? 'Master match: read cuts, bridges and the full connection race.'
            : 'Usta maçı: kesmeleri, köprüleri ve tüm bağlantı yarışını oku.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(
      StudioGameClass.strategy,
    );
    return ParkurLevelHub(
      gameId: 'hex_connection',
      progressPrefix: 'hex_connection',
      titleTr: 'Hex Bağlantısı',
      titleEn: 'Hex Connection',
      taglineTr: 'Bağlantı kur • Köprüleri oku • Rakibi kes',
      taglineEn: 'Connect • Read bridges • Cut off the rival',
      accent: skin.accent,
      icon: Icons.hexagon_outlined,
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
          ) => HexConnectionPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class HexConnectionPlayPage extends StatefulWidget {
  const HexConnectionPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<HexConnectionPlayPage> createState() => _HexConnectionPlayPageState();
}

class _HexConnectionPlayPageState extends State<HexConnectionPlayPage> {
  static const Color _accent = Color(0xFFBD745A);
  static const Color _redStone = Color(0xFFDA8A73);
  static const Color _blueStone = Color(0xFF536D79);
  static const Color _gold = Color(0xFFC39B56);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.strategy,
  );
  final List<HexPosition> _undoStack = <HexPosition>[];

  late HexScenario _scenario;
  late HexPosition _position;
  late StudioGameSession _session;
  int? _hintedCell;
  int? _lastMove;
  int _hints = 0;
  int _playerMoves = 0;
  int _mistakes = 0;
  bool _ready = false;
  bool _thinking = false;
  bool _finished = false;
  bool _english = false;
  String? _notice;

  int get _score =>
      math.max(0, 5000 - _playerMoves * 12 - _hints * 360 - _mistakes * 180);
  int get _stars => _hints == 0 && _mistakes == 0
      ? 3
      : _hints <= 2 && _mistakes <= 2
      ? 2
      : 1;

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareScenario());
  }

  Future<void> _prepareScenario() async {
    HexScenario scenario = HexScenarioBank.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'hex_connection_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int practiceIndex =
            await preferences.getInt('hex_connection_practice_index') ?? 0;
        if (practiceIndex < HexScenarioBank.maximumVerifiedBoards) {
          final int next = practiceIndex + 1;
          await preferences.setInt('hex_connection_practice_index', next);
          scenario = HexScenarioBank.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      scenario = HexScenarioBank.forLevel(widget.level.number);
    }
    if (!mounted) return;
    setState(() {
      _scenario = scenario;
      _position = scenario.start;
      _session = _newSession(scenario);
      _undoStack.clear();
      _hintedCell = null;
      _lastMove = null;
      _hints = 0;
      _playerMoves = 0;
      _mistakes = 0;
      _thinking = false;
      _finished = false;
      _notice = null;
      _ready = true;
    });
  }

  StudioGameSession _newSession(HexScenario scenario) =>
      StudioGameSession(level: widget.level.number, seed: scenario.seed)
        ..start();

  void _playAt(int cell) {
    if (!_ready || _thinking || _finished) return;
    if (_position.nextSide != HexSide.red) return;
    final HexPosition? next = _position.play(cell);
    if (next == null) {
      _mistakes++;
      setState(() {
        _notice = _english
            ? 'Choose an open hex. Occupied stones cannot be replaced.'
            : 'Boş bir altıgen seç. Dolu taşların yeri değiştirilemez.';
      });
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .17));
      return;
    }
    _undoStack.add(_position);
    setState(() {
      _position = next;
      _lastMove = cell;
      _hintedCell = null;
      _playerMoves++;
      _notice = _english
          ? 'Coral stone placed. Find the next link before blue.'
          : 'Koral taş yerleşti. Lacivertten önce sonraki bağlantıyı bul.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .2));
    if (next.winner == HexSide.red) {
      _session.recordAccepted(points: 60);
      unawaited(_finishWin());
    } else {
      setState(() => _thinking = true);
      unawaited(_computerReply());
    }
  }

  Future<void> _computerReply() async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    if (!mounted || _finished) return;
    final HexPosition before = _position;
    final int? response = HexComputerPlayer.chooseMove(
      before,
      side: HexSide.blue,
      level: widget.level.number,
      seed: _scenario.seed ^ _playerMoves,
    );
    if (!mounted || _finished || before.signature != _position.signature) {
      return;
    }
    if (response == null) {
      setState(() {
        _thinking = false;
        _notice = _english
            ? 'No legal blue response remains.'
            : 'Lacivert için yasal hamle kalmadı.';
      });
      return;
    }
    final HexPosition? next = _position.play(response);
    if (next == null) return;
    setState(() {
      _position = next;
      _lastMove = response;
      _thinking = false;
      _notice = _english
          ? 'Blue played. Connect the coral top and bottom edges.'
          : 'Lacivert oynadı. Koral üst ve alt kenarı bağla.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .15));
    if (next.winner == HexSide.blue) unawaited(_finishLoss());
  }

  void _undo() {
    if (_undoStack.isEmpty || _thinking || _finished) return;
    setState(() {
      _position = _undoStack.removeLast();
      _hintedCell = null;
      _lastMove = null;
      _playerMoves = math.max(0, _playerMoves - 1);
      _notice = _english
          ? 'Your last turn was undone.'
          : 'Son turun geri alındı.';
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .2));
  }

  void _showHint() {
    if (!_ready || _thinking || _finished || !_session.canUseHint) return;
    final int? candidate = HexComputerPlayer.chooseMove(
      _position,
      side: HexSide.red,
      level: math.max(1, widget.level.number - 2),
      seed: _scenario.seed ^ 0x41564E,
    );
    if (candidate == null) return;
    _session.useHint(pointCost: 360);
    _hints++;
    setState(() {
      _hintedCell = candidate;
      _notice = _english
          ? 'Suggested connection: inspect the highlighted open hex.'
          : 'Önerilen bağlantı: vurgulanan boş altıgeni incele.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .22));
  }

  Future<void> _confirmRestart() async {
    if (!_ready || _thinking || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'Restart this match?' : 'Bu maç yeniden başlasın mı?',
        ),
        content: Text(
          _english
              ? 'The same opening position and sides will be restored.'
              : 'Aynı başlangıç konumu ve taş renkleri korunacak.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep playing' : 'Oynamaya devam et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_english ? 'Restart' : 'Yeniden başla'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _position = _scenario.start;
      _undoStack.clear();
      _hintedCell = null;
      _lastMove = null;
      _hints = 0;
      _playerMoves = 0;
      _mistakes = 0;
      _notice = null;
      _session = _newSession(_scenario);
    });
  }

  Future<void> _finishLoss() async {
    if (_finished || !mounted) return;
    _finished = true;
    final bool? retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: const Icon(Icons.alt_route_rounded, color: _blueStone, size: 36),
        title: Text(_english ? 'BLUE CONNECTED' : 'LACİVERT BAĞLANTI KURDU'),
        content: Text(
          _english
              ? 'Hex has no draws. Read the cut points, then try the same opening again.'
              : 'Hex’te beraberlik yok. Kesme noktalarını oku ve aynı açılışı yeniden dene.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Level map' : 'Bölüm haritası'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_english ? 'Retry opening' : 'Açılışı dene'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (retry != true) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _position = _scenario.start;
      _undoStack.clear();
      _hintedCell = null;
      _lastMove = null;
      _hints = 0;
      _playerMoves = 0;
      _mistakes = 0;
      _finished = false;
      _notice = _english
          ? 'Same opening. Your turn.'
          : 'Aynı açılış. Sıra sende.';
      _session = _newSession(_scenario);
    });
  }

  Future<void> _finishWin() async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.complete(
      stars: stars,
      action: widget.level.number < HexConnectionGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
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
      titleTr: 'KÖPRÜ KURULDU',
      titleEn: 'CONNECTION COMPLETE',
      detailTr:
          '${_position.size}×${_position.size} tahta · $_playerMoves koral hamlesi.',
      detailEn:
          '${_position.size}×${_position.size} board · $_playerMoves coral moves.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < HexConnectionGamePage.totalCases,
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
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          backgroundColor: StudioVisuals.canvas,
          foregroundColor: StudioVisuals.ink,
          title: Text(_english ? 'HEX CONNECTION' : 'HEX BAĞLANTISI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 14,
        title: Text(
          _english ? 'HEX CONNECTION' : 'HEX BAĞLANTISI',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(child: _HexLevelPill(level: widget.level.number)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 3, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HexStatus(
                tier: _scenario.difficultyTier,
                size: _position.size,
                red: _position.redCount,
                blue: _position.blueCount,
                english: _english,
              ),
              const SizedBox(height: 9),
              _HexLegend(english: _english),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  key: const ValueKey<String>('hex_board_frame'),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E2D9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD9D3C8)),
                    boxShadow: StudioVisuals.softShadow,
                  ),
                  child: _HexBoard(
                    key: const ValueKey<String>('hex_board'),
                    position: _position,
                    hintedCell: _hintedCell,
                    lastMove: _lastMove,
                    onTapCell: _playAt,
                    english: _english,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              _HexActions(
                canUndo: _undoStack.isNotEmpty && !_thinking && !_finished,
                canHint: !_thinking && !_finished,
                canRestart: !_thinking && !_finished,
                onUndo: _undo,
                onHint: _showHint,
                onRestart: _confirmRestart,
                english: _english,
              ),
              if (_thinking) ...<Widget>[
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: _blueStone,
                  backgroundColor: Color(0xFFE8ECEB),
                ),
              ],
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _HexNotice(text: _notice!, thinking: _thinking),
              ],
              const SizedBox(height: 8),
              Text(
                _english
                    ? 'Hex has no draws: coral joins north–south, blue joins west–east. Stones never move once placed.'
                    : 'Hex’te beraberlik yok: koral kuzey–güneyi, lacivert batı–doğuyu bağlar. Yerleşen taş bir daha hareket etmez.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7472),
                  fontSize: 10,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HexBoard extends StatelessWidget {
  const _HexBoard({
    super.key,
    required this.position,
    required this.hintedCell,
    required this.lastMove,
    required this.onTapCell,
    required this.english,
  });

  final HexPosition position;
  final int? hintedCell;
  final int? lastMove;
  final ValueChanged<int> onTapCell;
  final bool english;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double radius = math.min(
        32,
        constraints.maxWidth / (1.5 * position.size + .5),
      );
      final double halfHeight = math.sqrt(3) * radius / 2;
      final double boardWidth = (1.5 * position.size + .5) * radius;
      final double boardHeight = (3 * position.size - 1) * halfHeight;
      return Semantics(
        label: english
            ? 'Hex board. Tap an open hex to place a coral stone and connect north to south.'
            : 'Hex tahtası. Koral taşı yerleştirmek ve kuzey-güney bağlantısı kurmak için boş altıgene dokun.',
        child: GestureDetector(
          key: const ValueKey<String>('hex_board_touch'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (TapUpDetails details) {
            final int? cell = _hitTest(
              details.localPosition,
              position.size,
              radius,
            );
            if (cell != null) onTapCell(cell);
          },
          child: CustomPaint(
            key: const ValueKey<String>('hex_board_canvas'),
            size: Size(boardWidth, boardHeight),
            painter: _HexBoardPainter(
              position: position,
              hintedCell: hintedCell,
              lastMove: lastMove,
              radius: radius,
            ),
          ),
        ),
      );
    },
  );

  int? _hitTest(Offset point, int size, double radius) {
    final double halfHeight = math.sqrt(3) * radius / 2;
    int? closest;
    double closestDistance = double.infinity;
    for (int row = 0; row < size; row++) {
      for (int column = 0; column < size; column++) {
        final Offset center = _hexCenter(row, column, radius, halfHeight);
        final double dx = (point.dx - center.dx).abs();
        final double dy = (point.dy - center.dy).abs();
        final bool inside =
            dx <= radius &&
            dy <= halfHeight &&
            dx + dy / math.sqrt(3) <= radius + .5;
        if (!inside) continue;
        final double distance = (point - center).distanceSquared;
        if (distance < closestDistance) {
          closest = row * size + column;
          closestDistance = distance;
        }
      }
    }
    return closest;
  }
}

Offset _hexCenter(int row, int column, double radius, double halfHeight) =>
    Offset(
      radius + column * radius * 1.5,
      halfHeight + row * radius * math.sqrt(3) + column * halfHeight,
    );

class _HexBoardPainter extends CustomPainter {
  const _HexBoardPainter({
    required this.position,
    required this.hintedCell,
    required this.lastMove,
    required this.radius,
  });

  final HexPosition position;
  final int? hintedCell;
  final int? lastMove;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final double halfHeight = math.sqrt(3) * radius / 2;
    for (int cell = 0; cell < position.cells.length; cell++) {
      final int row = cell ~/ position.size;
      final int column = cell % position.size;
      final Offset center = _hexCenter(row, column, radius, halfHeight);
      final Path path = _hexPath(center, radius);
      canvas.drawPath(
        path.shift(const Offset(0, 2.2)),
        Paint()
          ..color = const Color(0xFF33434B).withValues(alpha: .12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
      final int side = position.cells[cell];
      final Color fillColor = switch (side) {
        1 => _HexConnectionPlayPageState._redStone,
        2 => _HexConnectionPlayPageState._blueStone,
        _ => const Color(0xFFFBFAF7),
      };
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.3, -.38),
            radius: 1,
            colors: <Color>[
              Color.lerp(fillColor, Colors.white, side == 0 ? .18 : .23)!,
              fillColor,
              Color.lerp(
                fillColor,
                const Color(0xFF28333A),
                side == 0 ? .08 : .14,
              )!,
            ],
            stops: const <double>[0, .58, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = side == 0
              ? const Color(0xFFD8D6D0)
              : const Color(0xFF46545A).withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      if (side == HexSide.red.value) {
        canvas.drawCircle(
          center,
          radius * .28,
          Paint()..color = const Color(0xFFFFE7DC).withValues(alpha: .93),
        );
        canvas.drawCircle(
          center,
          radius * .12,
          Paint()..color = const Color(0xFFBA6555),
        );
      } else if (side == HexSide.blue.value) {
        final Path diamond = Path()
          ..moveTo(center.dx, center.dy - radius * .34)
          ..lineTo(center.dx + radius * .25, center.dy)
          ..lineTo(center.dx, center.dy + radius * .34)
          ..lineTo(center.dx - radius * .25, center.dy)
          ..close();
        canvas.drawPath(diamond, Paint()..color = const Color(0xFFE8F0F2));
      }
      if (cell == lastMove) {
        canvas.drawPath(
          path,
          Paint()
            ..color = _HexConnectionPlayPageState._gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      }
      if (cell == hintedCell) {
        canvas.drawCircle(
          center,
          radius * .7,
          Paint()
            ..color = _HexConnectionPlayPageState._gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  Path _hexPath(Offset center, double side) {
    final Path path = Path();
    for (int point = 0; point < 6; point++) {
      final double angle = point * math.pi / 3;
      final Offset vertex = Offset(
        center.dx + math.cos(angle) * side,
        center.dy + math.sin(angle) * side,
      );
      if (point == 0) {
        path.moveTo(vertex.dx, vertex.dy);
      } else {
        path.lineTo(vertex.dx, vertex.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_HexBoardPainter oldDelegate) =>
      oldDelegate.position.signature != position.signature ||
      oldDelegate.hintedCell != hintedCell ||
      oldDelegate.lastMove != lastMove ||
      oldDelegate.radius != radius;
}

class _HexStatus extends StatelessWidget {
  const _HexStatus({
    required this.tier,
    required this.size,
    required this.red,
    required this.blue,
    required this.english,
  });

  final String tier;
  final int size;
  final int red;
  final int blue;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFCFBF8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8E5DF)),
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF5ECE8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.hexagon_outlined,
            color: _HexConnectionPlayPageState._accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                tier,
                style: const TextStyle(
                  color: Color(0xFF526660),
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                english
                    ? '$size×$size · Coral $red · Blue $blue'
                    : '$size×$size · Koral $red · Lacivert $blue',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF78827D),
                  fontSize: 11,
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

class _HexLegend extends StatelessWidget {
  const _HexLegend({required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _HexSideLabel(
          color: _HexConnectionPlayPageState._redStone,
          symbol: '●',
          title: english ? 'CORAL · N–S' : 'KORAL · K–G',
          detail: english ? 'You connect top to bottom' : 'Sen üstü alta bağla',
        ),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: _HexSideLabel(
          color: _HexConnectionPlayPageState._blueStone,
          symbol: '◆',
          title: english ? 'BLUE · W–E' : 'LACİVERT · B–D',
          detail: english ? 'Computer connects sides' : 'Rakip yanları bağlar',
        ),
      ),
    ],
  );
}

class _HexSideLabel extends StatelessWidget {
  const _HexSideLabel({
    required this.color,
    required this.symbol,
    required this.title,
    required this.detail,
  });

  final Color color;
  final String symbol;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFCFBF8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8E5DF)),
    ),
    child: Row(
      children: <Widget>[
        Text(symbol, style: TextStyle(color: color, fontSize: 16)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF53625D),
                  fontSize: 9,
                  letterSpacing: .4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF87918C),
                  fontSize: 9,
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

class _HexActions extends StatelessWidget {
  const _HexActions({
    required this.canUndo,
    required this.canHint,
    required this.canRestart,
    required this.onUndo,
    required this.onHint,
    required this.onRestart,
    required this.english,
  });

  final bool canUndo;
  final bool canHint;
  final bool canRestart;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onRestart;
  final bool english;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 7,
    children: <Widget>[
      _HexActionButton(
        key: const ValueKey<String>('hex_undo'),
        icon: Icons.undo_rounded,
        label: english ? 'Undo turn' : 'Turu geri al',
        enabled: canUndo,
        onPressed: onUndo,
      ),
      _HexActionButton(
        key: const ValueKey<String>('hex_hint'),
        icon: Icons.lightbulb_outline_rounded,
        label: english ? 'Hint' : 'İpucu',
        enabled: canHint,
        onPressed: onHint,
      ),
      _HexActionButton(
        key: const ValueKey<String>('hex_restart'),
        icon: Icons.restart_alt_rounded,
        label: english ? 'Restart' : 'Yeniden başla',
        enabled: canRestart,
        onPressed: onRestart,
      ),
    ],
  );
}

class _HexActionButton extends StatelessWidget {
  const _HexActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF596A64),
        side: const BorderSide(color: Color(0xFFDDE2DC)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}

class _HexNotice extends StatelessWidget {
  const _HexNotice({required this.text, required this.thinking});

  final String text;
  final bool thinking;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: thinking ? const Color(0xFFEEF2F3) : const Color(0xFFF5F1EA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: <Widget>[
        Icon(
          thinking ? Icons.more_horiz_rounded : Icons.alt_route_rounded,
          size: 17,
          color: thinking
              ? _HexConnectionPlayPageState._blueStone
              : _HexConnectionPlayPageState._accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF586761),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HexLevelPill extends StatelessWidget {
  const _HexLevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF4ECE8),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFFE9D9D2)),
    ),
    child: Text(
      '${level.toString().padLeft(2, '0')} / 20',
      style: const TextStyle(
        color: Color(0xFF785C50),
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
