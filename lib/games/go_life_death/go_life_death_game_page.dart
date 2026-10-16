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
import 'go_life_death_puzzle.dart';
import 'go_position.dart';

class GoLifeDeathGamePage extends StatelessWidget {
  const GoLifeDeathGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = GoLifeDeathPuzzle.maximumLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      final int stage = index % 10 + 1;
      final int chapter = index ~/ 10 + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Go Yaşam-Ölüm ${level.toString().padLeft(2, '0')}',
        titleEn: 'Go Life & Death ${level.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: switch (stage) {
          <= 6 => chapter == 1 ? 'USTALAŞMA' : 'DERİNLEŞME',
          7 || 8 => 'İLERİ',
          9 => 'UZMAN',
          _ => 'USTA',
        },
        icon: Icons.circle_outlined,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'Read the marked group through a denser, less familiar shape.'
          : 'İşaretli grubu daha yoğun ve alışılmadık bir biçimde oku.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Count liberties before choosing a capture or rescue point.'
            : 'Yakalama ya da kurtarma noktasını seçmeden özgürlükleri say.',
      <= 6 =>
        english
            ? 'Read connected stones as one group, not as isolated pieces.'
            : 'Bitişik taşları tek grup olarak oku; ayrı taşlar sanma.',
      7 || 8 =>
        english
            ? 'Advanced: scan a larger board and reject legal decoys.'
            : 'İleri: daha geniş tahtada yasal görünen tuzakları ele.',
      9 =>
        english
            ? 'Expert tsumego: compare capture and extension liberties.'
            : 'Uzman tsumego: yakalama ve uzatma özgürlüklerini karşılaştır.',
      _ =>
        english
            ? 'Master reading: certify the only move that changes life and death.'
            : 'Usta okuması: yaşam-ölümü değiştiren tek hamleyi kanıtla.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(
      StudioGameClass.strategy,
    );
    return ParkurLevelHub(
      gameId: 'go_life_death',
      progressPrefix: 'go_life_death',
      titleTr: 'Go Yaşam-Ölüm',
      titleEn: 'Go Life & Death',
      taglineTr: 'Özgürlükleri say • Grubu oku • Hayatta kal ya da yakala',
      taglineEn: 'Count liberties • Read the group • Save or capture',
      accent: skin.accent,
      icon: Icons.circle_outlined,
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
          ) => GoLifeDeathPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class GoLifeDeathPlayPage extends StatefulWidget {
  const GoLifeDeathPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<GoLifeDeathPlayPage> createState() => _GoLifeDeathPlayPageState();
}

class _GoLifeDeathPlayPageState extends State<GoLifeDeathPlayPage> {
  static const Color _accent = Color(0xFF667F79);
  static const Color _ink = Color(0xFF28363A);
  static const Color _board = Color(0xFFE8DCC4);
  static const Color _grid = Color(0xFF81735F);
  static const Color _target = Color(0xFFC17464);
  static const Color _gold = Color(0xFFC4974E);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.strategy,
  );

  late GoLifeDeathPuzzle _puzzle;
  late GoPosition _position;
  late StudioGameSession _session;
  final List<GoPosition> _undoStack = <GoPosition>[];
  int? _hintedPoint;
  int? _attemptPoint;
  int _mistakes = 0;
  int _hints = 0;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String? _notice;

  int get _score => math.max(0, 5000 - _hints * 280 - _mistakes * 160);

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
    GoLifeDeathPuzzle puzzle = GoLifeDeathPuzzle.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'go_life_death_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('go_life_death_practice_index') ?? 0;
        if (index < GoLifeDeathPuzzle.maximumVerifiedBoards) {
          final int next = index + 1;
          await preferences.setInt('go_life_death_practice_index', next);
          puzzle = GoLifeDeathPuzzle.forPracticeBoard(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      puzzle = GoLifeDeathPuzzle.forLevel(widget.level.number);
    }
    if (!mounted) return;
    setState(() {
      _puzzle = puzzle;
      _position = puzzle.position;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: puzzle.seed,
      )..start();
      _undoStack.clear();
      _hintedPoint = null;
      _attemptPoint = null;
      _mistakes = 0;
      _hints = 0;
      _notice = null;
      _finished = false;
      _ready = true;
    });
  }

  int? _pointAt(Offset location, Size boardSize) {
    final double spacing = boardSize.width / (_position.size + 1);
    final int column = (location.dx / spacing).round() - 1;
    final int row = (location.dy / spacing).round() - 1;
    if (row < 0 ||
        row >= _position.size ||
        column < 0 ||
        column >= _position.size) {
      return null;
    }
    final double x = (location.dx - (column + 1) * spacing).abs();
    final double y = (location.dy - (row + 1) * spacing).abs();
    if (x > spacing * .44 || y > spacing * .44) return null;
    return _position.point(row, column);
  }

  void _playAt(int point) {
    if (!_ready || _finished || !_session.acceptsInput) return;
    final GoPlayResult? move = _position.play(point);
    if (move == null) {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      setState(() {
        _mistakes++;
        _attemptPoint = point;
        _notice = _english
            ? 'Illegal here: occupied, ko, or no liberties after capture.'
            : 'Bu hamle yasak: nokta dolu, ko ihlali ya da özgürlüksüz kalıyor.';
      });
      return;
    }
    _hintedPoint = null;
    if (!_puzzle.isSolution(point)) {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      setState(() {
        _mistakes++;
        _attemptPoint = point;
        _notice = _english
            ? 'Legal, but it does not change the marked group’s life and death. Undo the preview and count again.'
            : 'Yasal ama işaretli grubun yaşam-ölümünü çözmüyor. Önizlemeyi geri alıp özgürlükleri yeniden say.';
      });
      return;
    }
    _session.recordAccepted(points: 60);
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .26));
    setState(() {
      _undoStack.add(_position);
      _position = move.position;
      _attemptPoint = null;
      _notice = _english
          ? 'Certified: ${move.captured.length} stone(s) captured; the marked group now has ${_position.groupAt(_puzzle.targetStones.first)?.liberties.length ?? 0} liberties.'
          : 'Doğrulandı: ${move.captured.length} taş yakalandı; işaretli grubun ${_position.groupAt(_puzzle.targetStones.first)?.liberties.length ?? 0} özgürlüğü var.';
    });
    unawaited(_finish());
  }

  void _undo() {
    if (!_ready || _finished) return;
    if (_attemptPoint != null) {
      setState(() {
        _attemptPoint = null;
        _notice = _english
            ? 'Move preview cleared.'
            : 'Hamle önizlemesi temizlendi.';
      });
      return;
    }
    if (_undoStack.isNotEmpty) {
      setState(() {
        _position = _undoStack.removeLast();
        _notice = _english ? 'Last move restored.' : 'Son hamle geri alındı.';
      });
      unawaited(_audio.play(GameSound.uiBack, gain: .2));
    }
  }

  void _showHint() {
    if (!_ready || _finished || !_session.canUseHint) return;
    _session.useHint(pointCost: 280);
    setState(() {
      _hints++;
      _attemptPoint = null;
      _hintedPoint = _puzzle.solutionPoint;
      _notice = _english
          ? 'Gold ring marks the certified vital point. Confirm its effect on the whole group.'
          : 'Altın halka doğrulanmış yaşamsal noktayı gösterir. Etkisini grubun tamamında doğrula.';
    });
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .25));
  }

  Future<void> _confirmReset() async {
    if (!_ready || _finished) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          _english ? 'Reset this tsumego?' : 'Bu tsumego sıfırlansın mı?',
        ),
        content: Text(
          _english
              ? 'The same certified position will be restored.'
              : 'Aynı doğrulanmış konum yeniden kurulacak.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_english ? 'Keep reading' : 'Okumaya devam et'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_english ? 'Reset' : 'Sıfırla'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _position = _puzzle.position;
      _undoStack.clear();
      _hintedPoint = null;
      _attemptPoint = null;
      _mistakes = 0;
      _hints = 0;
      _notice = null;
    });
  }

  Future<void> _finish() async {
    if (_finished || !mounted) return;
    _finished = true;
    final int score = _score;
    final int stars = _stars;
    _session.complete(
      stars: stars,
      action: widget.level.number < GoLifeDeathGamePage.totalCases
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
      titleTr: _puzzle.goal == GoPuzzleGoal.capture
          ? 'GRUP YAKALANDI'
          : 'GRUP KURTULDU',
      titleEn: _puzzle.goal == GoPuzzleGoal.capture
          ? 'GROUP CAPTURED'
          : 'GROUP SAVED',
      detailTr:
          '${_puzzle.position.size}×${_puzzle.position.size} Go tahtası · $_hints ipucu.',
      detailEn:
          '${_puzzle.position.size}×${_puzzle.position.size} Go board · $_hints hints.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < GoLifeDeathGamePage.totalCases,
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
          title: Text(_english ? 'GO LIFE & DEATH' : 'GO YAŞAM-ÖLÜM'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final int targetLiberties =
        _position.groupAt(_puzzle.targetStones.first)?.liberties.length ?? 0;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 14,
        title: Text(
          _english ? 'GO LIFE & DEATH' : 'GO YAŞAM-ÖLÜM',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Center(child: _GoLevelPill(level: widget.level.number)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 3, 14, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _GoStatus(
                level: widget.level.number,
                tier: _puzzle.difficultyTier,
                legalMoves: _puzzle.proofLegalMoves,
                liberties: targetLiberties,
                english: _english,
              ),
              const SizedBox(height: 10),
              _GoGoalCard(
                goal: _puzzle.goal,
                targetColor: _puzzle.targetColor,
                groupSize: _puzzle.targetStones.length,
                english: _english,
              ),
              const SizedBox(height: 11),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double boardSize = math.min(
                    520.0,
                    constraints.maxWidth - 4,
                  );
                  return Center(
                    child: Container(
                      key: const ValueKey<String>('go_life_death_board_frame'),
                      width: boardSize + 16,
                      height: boardSize + 16,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9CEB8),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFC9BDA8)),
                        boxShadow: StudioVisuals.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: SizedBox.square(
                          dimension: boardSize,
                          child: GestureDetector(
                            key: const ValueKey<String>('go_life_death_board'),
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (TapUpDetails details) {
                              final int? point = _pointAt(
                                details.localPosition,
                                Size(boardSize, boardSize),
                              );
                              if (point != null) _playAt(point);
                            },
                            child: Semantics(
                              label: _english
                                  ? 'Go board. Read liberties of the outlined group and tap the vital point.'
                                  : 'Go tahtası. Çerçeveli grubun özgürlüklerini say ve yaşamsal noktaya dokun.',
                              value: _english
                                  ? '$targetLiberties liberties remain'
                                  : '$targetLiberties özgürlük kaldı',
                              child: CustomPaint(
                                painter: _GoBoardPainter(
                                  position: _position,
                                  targetStones: _puzzle.targetStones,
                                  targetColor: _puzzle.targetColor,
                                  hintedPoint: _hintedPoint,
                                  attemptPoint: _attemptPoint,
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _GoActions(
                canUndo: _attemptPoint != null || _undoStack.isNotEmpty,
                busy: _finished,
                english: _english,
                onUndo: _undo,
                onHint: _showHint,
                onReset: _confirmReset,
              ),
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 8),
                _GoNotice(text: _notice!, warning: _attemptPoint != null),
              ],
              const SizedBox(height: 8),
              Text(
                _english
                    ? 'Tap a board intersection. Capture removes a group with zero liberties; saving must leave at least two.'
                    : 'Tahta kesişimine dokun. Yakalama özgürlüğü sıfırlanan grubu kaldırır; kurtarma hamlesi en az iki özgürlük bırakmalıdır.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7472),
                  fontSize: 11,
                  height: 1.4,
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

class _GoBoardPainter extends CustomPainter {
  const _GoBoardPainter({
    required this.position,
    required this.targetStones,
    required this.targetColor,
    required this.hintedPoint,
    required this.attemptPoint,
  });

  final GoPosition position;
  final Set<int> targetStones;
  final GoStone targetColor;
  final int? hintedPoint;
  final int? attemptPoint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _GoLifeDeathPlayPageState._board,
    );
    final double spacing = size.width / (position.size + 1);
    final double inset = spacing;
    final Offset first = Offset(inset, inset);
    final Offset last = Offset(size.width - inset, size.height - inset);
    final Paint grid = Paint()
      ..color = _GoLifeDeathPlayPageState._grid
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke;
    for (int index = 0; index < position.size; index++) {
      final double coordinate = (index + 1) * spacing;
      canvas.drawLine(
        Offset(coordinate, first.dy),
        Offset(coordinate, last.dy),
        grid,
      );
      canvas.drawLine(
        Offset(first.dx, coordinate),
        Offset(last.dx, coordinate),
        grid,
      );
    }
    if (position.size >= 9) {
      final Paint star = Paint()..color = _GoLifeDeathPlayPageState._grid;
      for (final int row in <int>[2, 4, 6]) {
        for (final int column in <int>[2, 4, 6]) {
          canvas.drawCircle(
            Offset((column + 1) * spacing, (row + 1) * spacing),
            2.2,
            star,
          );
        }
      }
    }
    for (int point = 0; point < position.stones.length; point++) {
      final GoStone stone = position.at(point);
      if (stone == GoStone.empty) continue;
      final int row = point ~/ position.size;
      final int column = point % position.size;
      final Offset center = Offset((column + 1) * spacing, (row + 1) * spacing);
      final double radius = spacing * .43;
      if (targetStones.contains(point)) {
        canvas.drawCircle(
          center,
          radius + 3.4,
          Paint()
            ..color = _GoLifeDeathPlayPageState._target.withValues(alpha: .72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.7,
        );
      }
      final Rect bounds = Rect.fromCircle(center: center, radius: radius);
      final Gradient gradient = stone == GoStone.black
          ? const RadialGradient(
              center: Alignment(-.28, -.34),
              radius: .88,
              colors: <Color>[
                Color(0xFF65716F),
                Color(0xFF182326),
                Color(0xFF0F1719),
              ],
              stops: <double>[0, .4, 1],
            )
          : const RadialGradient(
              center: Alignment(-.3, -.35),
              radius: .9,
              colors: <Color>[
                Colors.white,
                Color(0xFFF2EFE8),
                Color(0xFFC8C5BD),
              ],
              stops: <double>[0, .55, 1],
            );
      canvas.drawCircle(
        center.translate(0, radius * .09),
        radius,
        Paint()..color = Colors.black.withValues(alpha: .18),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()..shader = gradient.createShader(bounds),
      );
      if (hintedPoint == point) {
        canvas.drawCircle(
          center,
          radius + 5,
          Paint()
            ..color = _GoLifeDeathPlayPageState._gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
    final int? marker = attemptPoint;
    if (marker != null && position.at(marker) == GoStone.empty) {
      final int row = marker ~/ position.size;
      final int column = marker % position.size;
      final Offset center = Offset((column + 1) * spacing, (row + 1) * spacing);
      canvas.drawCircle(
        center,
        spacing * .35,
        Paint()
          ..color = _GoLifeDeathPlayPageState._target.withValues(alpha: .85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.3,
      );
      canvas.drawLine(
        center.translate(-spacing * .18, -spacing * .18),
        center.translate(spacing * .18, spacing * .18),
        Paint()
          ..color = _GoLifeDeathPlayPageState._target
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        center.translate(spacing * .18, -spacing * .18),
        center.translate(-spacing * .18, spacing * .18),
        Paint()
          ..color = _GoLifeDeathPlayPageState._target
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoBoardPainter oldDelegate) =>
      oldDelegate.position.signature != position.signature ||
      oldDelegate.targetStones != targetStones ||
      oldDelegate.targetColor != targetColor ||
      oldDelegate.hintedPoint != hintedPoint ||
      oldDelegate.attemptPoint != attemptPoint;
}

class _GoStatus extends StatelessWidget {
  const _GoStatus({
    required this.level,
    required this.tier,
    required this.legalMoves,
    required this.liberties,
    required this.english,
  });

  final int level;
  final String tier;
  final int legalMoves;
  final int liberties;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7E3DC)),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${english ? 'PUZZLE' : 'ETÜT'} ${level.toString().padLeft(2, '0')}  ·  $tier',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF76817F),
                  fontSize: 9,
                  letterSpacing: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                english
                    ? '$legalMoves legal candidates'
                    : '$legalMoves yasal aday',
                style: const TextStyle(
                  color: _GoLifeDeathPlayPageState._ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            english ? '$liberties LIBERTY' : '$liberties ÖZGÜRLÜK',
            style: const TextStyle(
              color: _GoLifeDeathPlayPageState._accent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _GoGoalCard extends StatelessWidget {
  const _GoGoalCard({
    required this.goal,
    required this.targetColor,
    required this.groupSize,
    required this.english,
  });

  final GoPuzzleGoal goal;
  final GoStone targetColor;
  final int groupSize;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final bool capture = goal == GoPuzzleGoal.capture;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7E3DC)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F0E8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE6DED1)),
            ),
            child: Icon(
              capture ? Icons.gps_fixed_rounded : Icons.shield_outlined,
              color: _GoLifeDeathPlayPageState._accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  capture
                      ? (english
                            ? 'CAPTURE THE MARKED GROUP'
                            : 'İŞARETLİ GRUBU YAKALA')
                      : (english
                            ? 'SAVE THE MARKED GROUP'
                            : 'İŞARETLİ GRUBU KURTAR'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _GoLifeDeathPlayPageState._ink,
                    fontSize: 11,
                    letterSpacing: .35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  english
                      ? '${targetColor.name.toUpperCase()} group · $groupSize connected stone${groupSize == 1 ? '' : 's'}'
                      : '${targetColor == GoStone.black ? 'SİYAH' : 'BEYAZ'} grup · $groupSize bitişik taş',
                  style: const TextStyle(
                    color: Color(0xFF78817D),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.more_horiz_rounded,
            color: _GoLifeDeathPlayPageState._accent.withValues(alpha: .55),
          ),
        ],
      ),
    );
  }
}

class _GoActions extends StatelessWidget {
  const _GoActions({
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
        child: OutlinedButton.icon(
          onPressed: canUndo && !busy ? onUndo : null,
          icon: const Icon(Icons.undo_rounded, size: 18),
          label: Text(english ? 'UNDO' : 'GERİ AL'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: _GoLifeDeathPlayPageState._ink,
            side: const BorderSide(color: Color(0xFFDCD9D2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: FilledButton.icon(
          onPressed: busy ? null : onHint,
          icon: const Icon(Icons.lightbulb_outline_rounded, size: 17),
          label: Text(english ? 'HINT' : 'İPUCU'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: _GoLifeDeathPlayPageState._accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton.outlined(
        tooltip: english ? 'Reset' : 'Sıfırla',
        onPressed: busy ? null : onReset,
        icon: const Icon(Icons.refresh_rounded),
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: _GoLifeDeathPlayPageState._ink,
          side: const BorderSide(color: Color(0xFFDCD9D2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ],
  );
}

class _GoNotice extends StatelessWidget {
  const _GoNotice({required this.text, required this.warning});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFBF0EC) : const Color(0xFFF0F4F1),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: warning ? const Color(0xFFE9D0C9) : const Color(0xFFD9E6DE),
      ),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: warning ? const Color(0xFF925B50) : const Color(0xFF54766B),
        fontSize: 11,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _GoLevelPill extends StatelessWidget {
  const _GoLevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4F1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '${level.toString().padLeft(2, '0')} / 20',
      style: const TextStyle(
        color: _GoLifeDeathPlayPageState._accent,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
