import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'gate_sequence_puzzle.dart';

class GateSequenceGamePage extends StatelessWidget {
  const GateSequenceGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = GameContentPolicy.minimumUniqueRounds;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) => ParkurLevelSpec(
      number: index + 1,
      titleTr: 'Dizi ${'${index + 1}'.padLeft(3, '0')}',
      titleEn: 'Sequence ${'${index + 1}'.padLeft(3, '0')}',
      subtitleTr: 'İpuçlarından açılış sırasını çıkar',
      subtitleEn: 'Deduce the opening order from the clues',
      difficulty: index < 60
          ? 'ÇIRAK'
          : index < 130
          ? 'GÖZCÜ'
          : index < 220
          ? 'USTA'
          : 'BAŞMİMAR',
      icon: Icons.door_front_door_outlined,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.logic);
    return ParkurLevelHub(
      gameId: 'gate_sequence',
      progressPrefix: 'gate_sequence',
      titleTr: 'Kapı Dizisi',
      titleEn: 'Gate Sequence',
      taglineTr: 'İpuçlarını çöz, kasanın kapılarını sırala',
      taglineEn: 'Read the clues and order the vault gates',
      accent: skin.accent,
      icon: Icons.door_front_door_outlined,
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
          ) => GateSequencePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class GateSequencePlayPage extends StatefulWidget {
  const GateSequencePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<GateSequencePlayPage> createState() => _GateSequencePlayPageState();
}

class _GateSequencePlayPageState extends State<GateSequencePlayPage> {
  static const Color _ink = Color(0xFF263440);
  static const Color _muted = Color(0xFF72808A);
  static const Color _canvas = Color(0xFFF4F5F2);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF6F63C8);
  static const Color _copper = Color(0xFFB47D58);
  static const List<Color> _gateColors = <Color>[
    Color(0xFFB9855E),
    Color(0xFF4F8491),
    Color(0xFF96908A),
    Color(0xFF648579),
    Color(0xFFB77A8B),
    Color(0xFF77738F),
    Color(0xFF6D91A0),
    Color(0xFF8B8B78),
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  final List<List<int?>> _undo = <List<int?>>[];
  late final GateSequencePuzzle _puzzle;
  late final StudioGameSession _session;
  late List<int?> _order;
  bool _english = false;
  bool _finished = false;
  int? _selectedSlot;
  int _moves = 0;
  int _hints = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = GateSequencePuzzle.forLevel(widget.level.number);
    _order = List<int?>.filled(_puzzle.gateCount, null);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  void _selectSlot(int index) {
    if (_finished) return;
    setState(() {
      _selectedSlot = _selectedSlot == index ? null : index;
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .28));
  }

  void _placeGate(int gate) {
    if (_finished) return;
    final int firstEmpty = _order.indexWhere((int? value) => value == null);
    final int? targetSlot =
        _selectedSlot ?? (firstEmpty < 0 ? null : firstEmpty);
    if (targetSlot == null) return;
    final int slot = targetSlot;
    if (_order[slot] == gate) {
      setState(() => _selectedSlot = _nextEmptyAfter(slot));
      return;
    }
    final List<int?> previous = List<int?>.from(_order);
    final int existing = _order.indexOf(gate);
    final int? displaced = _order[slot];
    setState(() {
      _undo.add(previous);
      _order[slot] = gate;
      if (existing >= 0 && existing != slot) _order[existing] = displaced;
      _moves++;
      _selectedSlot = _nextEmptyAfter(slot);
    });
    _session.recordAccepted();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .32),
    );
  }

  int? _nextEmptyAfter(int slot) {
    for (int index = slot + 1; index < _order.length; index++) {
      if (_order[index] == null) return index;
    }
    for (int index = 0; index <= slot; index++) {
      if (_order[index] == null) return index;
    }
    return null;
  }

  void _clearSelected() {
    final int? slot = _selectedSlot;
    if (_finished || slot == null || _order[slot] == null) return;
    setState(() {
      _undo.add(List<int?>.from(_order));
      _order[slot] = null;
      _moves++;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .32));
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    setState(() {
      _order = _undo.removeLast();
      _moves++;
      _selectedSlot = _order.indexWhere((int? gate) => gate == null);
      if (_selectedSlot! < 0) _selectedSlot = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .32));
  }

  void _hint() {
    if (_finished ||
        !_session.canUseHint ||
        _hints >= math.min(
          StudioGameSession.defaultMaxHints,
          math.max(0, _puzzle.gateCount - 1),
        )) {
      return;
    }
    int target = -1;
    for (int index = 0; index < _puzzle.gateCount; index++) {
      if (_order[index] != _puzzle.solution[index]) {
        target = index;
        break;
      }
    }
    if (target < 0) return;
    final int wanted = _puzzle.solution[target];
    final List<int?> corrected = List<int?>.from(_order);
    final int existing = corrected.indexOf(wanted);
    final int? displaced = corrected[target];
    if (existing >= 0 && existing != target) corrected[existing] = displaced;
    corrected[target] = wanted;
    setState(() {
      _undo.add(List<int?>.from(_order));
      _order = corrected;
      _hints++;
      _moves++;
      _selectedSlot = _nextEmptyAfter(target);
    });
    _session.useHint(pointCost: 90);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .4));
  }

  void _reset() {
    if (_finished) return;
    setState(() {
      _order = List<int?>.filled(_puzzle.gateCount, null);
      _undo.clear();
      _moves = 0;
      _hints = 0;
      _selectedSlot = null;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .35));
  }

  Future<void> _checkOrder() async {
    if (_finished) return;
    if (_order.any((int? gate) => gate == null)) {
      _session.recordMistake();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .35));
      _showMessage(
        _english
            ? 'Place a gate in every position first.'
            : 'Önce tüm sıraları doldur.',
      );
      return;
    }
    final List<int> order = _order.cast<int>();
    if (_puzzle.isSolved(order)) {
      await _complete();
      return;
    }
    _session.recordMistake();
    final int conflictCount = _puzzle.clues
        .where((GateClue clue) => !clue.matches(order))
        .length;
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .38));
    _showMessage(
      _english
          ? '$conflictCount ${conflictCount == 1 ? 'clue conflicts' : 'clues conflict'}. Recheck the sequence.'
          : '$conflictCount ipucu ile çelişiyor. Diziyi yeniden incele.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1700),
        ),
      );
  }

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    final int stars = _hints == 0
        ? 3
        : _hints == 1
        ? 2
        : 1;
    final int score = math.max(150, 1700 - _moves * 9 - _hints * 180);
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < GateSequenceGamePage.totalCases
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
        title: Text(
          _english ? 'VAULT OPENED' : 'KASA AÇILDI',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _english
              ? '$stars stars  •  $score points\nThe gate sequence is correct.'
              : '$stars yıldız  •  $score puan\nKapı dizisi doğru çözüldü.',
          style: const TextStyle(color: Colors.white70),
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
            child: Text(_english ? 'MAP' : 'PARKUR'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(result.toParkurResult());
            },
            child: Text(
              widget.level.number < GateSequenceGamePage.totalCases
                  ? (_english ? 'NEXT GATE' : 'SONRAKİ KAPI')
                  : (_english ? 'CASE BOARD' : 'DOSYA PANOSU'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 10,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'GATE SEQUENCE' : 'KAPI DİZİSİ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            Text(
              _english
                  ? 'VAULT ${widget.level.number.toString().padLeft(3, '0')}'
                  : 'KASA ${widget.level.number.toString().padLeft(3, '0')}',
              style: const TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _hint,
            tooltip: _english ? 'Reveal one gate' : 'Bir kapıyı göster',
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            onPressed: _reset,
            tooltip: _english ? 'Reset sequence' : 'Diziyi sıfırla',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 620,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 22),
            children: <Widget>[
              _VaultHeader(
                level: widget.level.number,
                gateCount: _puzzle.gateCount,
                clueCount: _puzzle.clues.length,
                moves: _moves,
                bestScore: widget.previousBestScore,
                english: _english,
              ),
              const SizedBox(height: 12),
              _CluePanel(clues: _puzzle.clues, english: _english),
              const SizedBox(height: 13),
              _SectionLabel(
                title: _english ? 'OPENING ORDER' : 'AÇILIŞ SIRASI',
                detail: _english
                    ? 'Tap a position, then a gate'
                    : 'Bir sıraya, sonra bir kapıya dokun',
              ),
              const SizedBox(height: 8),
              _SequenceBoard(
                order: _order,
                selectedSlot: _selectedSlot,
                english: _english,
                onTap: _selectSlot,
              ),
              const SizedBox(height: 9),
              Row(
                children: <Widget>[
                  _ToolAction(
                    key: const ValueKey<String>('gate_sequence_undo'),
                    icon: Icons.undo_rounded,
                    label: _english ? 'UNDO' : 'GERİ AL',
                    onPressed: _undo.isEmpty ? null : _undoMove,
                  ),
                  const Spacer(),
                  _ToolAction(
                    icon: Icons.backspace_outlined,
                    label: _english ? 'CLEAR' : 'BOŞALT',
                    onPressed:
                        _selectedSlot == null || _order[_selectedSlot!] == null
                        ? null
                        : _clearSelected,
                  ),
                  const Spacer(),
                  _ToolAction(
                    icon: Icons.lightbulb_outline_rounded,
                    label: _english ? 'HINT' : 'İPUCU',
                    onPressed: _hint,
                  ),
                ],
              ),
              const SizedBox(height: 11),
              _SectionLabel(
                title: _english ? 'AVAILABLE GATES' : 'KAPI TAŞLARI',
                detail: _english
                    ? 'Each gate can be used once'
                    : 'Her kapı yalnızca bir kez kullanılır',
              ),
              const SizedBox(height: 7),
              _GateTray(
                gateCount: _puzzle.gateCount,
                order: _order,
                english: _english,
                onTap: _placeGate,
              ),
              const SizedBox(height: 13),
              FilledButton.icon(
                key: const ValueKey<String>('gate_sequence_check'),
                onPressed: _checkOrder,
                icon: const Icon(Icons.lock_open_rounded),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _english ? 'VERIFY THE SEQUENCE' : 'DİZİYİ DOĞRULA',
                    maxLines: 1,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(
                    GameInputPolicy.minimumTargetSize + 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultHeader extends StatelessWidget {
  const _VaultHeader({
    required this.level,
    required this.gateCount,
    required this.clueCount,
    required this.moves,
    required this.bestScore,
    required this.english,
  });

  final int level;
  final int gateCount;
  final int clueCount;
  final int moves;
  final int bestScore;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: _GateSequencePlayPageState._surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE5E7E3)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x0B263440),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 88,
          height: 78,
          child: CustomPaint(painter: _VaultPainter(level: level)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'VAULT CHRONICLE' : 'KASA GÜNLÜĞÜ',
                style: const TextStyle(
                  color: _GateSequencePlayPageState._muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                english ? 'Every clue matters.' : 'Her ipucu önemli.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _GateSequencePlayPageState._ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 10,
                runSpacing: 3,
                children: <Widget>[
                  _Metric(text: '${english ? 'GATES' : 'KAPI'} $gateCount'),
                  _Metric(text: '${english ? 'CLUES' : 'İPUCU'} $clueCount'),
                  _Metric(text: '${english ? 'MOVES' : 'HAMLE'} $moves'),
                ],
              ),
              if (bestScore > 0) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  '${english ? 'BEST' : 'REKOR'}  $bestScore',
                  style: const TextStyle(
                    color: StudioVisuals.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _VaultPainter extends CustomPainter {
  const _VaultPainter({required this.level});

  final int level;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect outer = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(18),
    );
    canvas.drawRRect(outer, Paint()..color = const Color(0xFFF0EFEA));
    final Paint line = Paint()
      ..color = const Color(0xFF6D7780).withValues(alpha: .46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final Paint copper = Paint()
      ..color = const Color(0xFFB47D58).withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final double center = size.width * .5;
    final double doorWidth = size.width * .53;
    final double doorLeft = center - doorWidth / 2;
    final double base = size.height * .82;
    for (int layer = 0; layer < 3; layer++) {
      final double inset = layer * 7.2;
      final double top = size.height * (.15 + layer * .10);
      final double left = doorLeft + inset;
      final double right = doorLeft + doorWidth - inset;
      final Path arch = Path()
        ..moveTo(left, base)
        ..lineTo(left, top + 16)
        ..quadraticBezierTo(left, top, center, top)
        ..quadraticBezierTo(right, top, right, top + 16)
        ..lineTo(right, base);
      canvas.drawPath(arch, layer == 0 ? copper : line);
    }
    canvas.drawLine(
      Offset(center, size.height * .46),
      Offset(center, base),
      line,
    );
    final double medallionRadius = size.width * .046;
    canvas.drawCircle(
      Offset(center, size.height * .56),
      medallionRadius,
      copper,
    );
    final TextPainter label = TextPainter(
      text: TextSpan(
        text: level.toString().padLeft(3, '0'),
        style: const TextStyle(
          color: Color(0xFF66717A),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(center - label.width / 2, size.height * .87));
  }

  @override
  bool shouldRepaint(_VaultPainter oldDelegate) => oldDelegate.level != level;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF596772),
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: .35,
    ),
  );
}

class _CluePanel extends StatelessWidget {
  const _CluePanel({required this.clues, required this.english});
  final List<GateClue> clues;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
    decoration: BoxDecoration(
      color: _GateSequencePlayPageState._surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5E7E3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F0FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.subject_rounded,
                size: 17,
                color: _GateSequencePlayPageState._accent,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                english ? 'ARCHIVE CLUES' : 'ARŞİV İPUÇLARI',
                style: const TextStyle(
                  color: _GateSequencePlayPageState._ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ),
            Text(
              '${clues.length} ${english ? 'rules' : 'kural'}',
              style: const TextStyle(
                color: _GateSequencePlayPageState._muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int index = 0; index < clues.length; index++)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 24,
                  height: 26,
                  child: Center(
                    child: Text(
                      '${index + 1}'.padLeft(2, '0'),
                      style: const TextStyle(
                        color: _GateSequencePlayPageState._copper,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: const Color(0xFFECE9E1)),
                const SizedBox(width: 9),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 4),
                    child: Text(
                      clues[index].text(english: english),
                      style: const TextStyle(
                        color: Color(0xFF485660),
                        fontSize: 12,
                        height: 1.26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _GateSequencePlayPageState._ink,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .75,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: const TextStyle(
            color: _GateSequencePlayPageState._muted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _SequenceBoard extends StatelessWidget {
  const _SequenceBoard({
    required this.order,
    required this.selectedSlot,
    required this.english,
    required this.onTap,
  });

  final List<int?> order;
  final int? selectedSlot;
  final bool english;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFE9ECE9),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDDE2DE)),
    ),
    child: GridView.builder(
      key: const ValueKey<String>('gate_sequence_board'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: order.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 63,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
      ),
      itemBuilder: (BuildContext context, int index) {
        final int? gate = order[index];
        final bool selected = selectedSlot == index;
        final Color accent = gate == null
            ? _GateSequencePlayPageState._muted
            : _GateSequencePlayPageState._gateColors[gate];
        return Semantics(
          button: true,
          label: english
              ? 'Position ${index + 1}, ${gate == null ? 'empty' : GateSequencePuzzle.gateNamesEn[gate]}'
              : '${index + 1}. sıra, ${gate == null ? 'boş' : GateSequencePuzzle.gateNames[gate]}',
          child: Material(
            color: selected ? const Color(0xFFF3F0FC) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: ValueKey<String>('gate_sequence_slot_$index'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTap(index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? _GateSequencePlayPageState._accent
                        : const Color(0xFFDDE2DE),
                    width: selected ? 1.8 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${index + 1}'.padLeft(2, '0'),
                      style: TextStyle(
                        color: accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gate == null
                          ? (english ? 'Choose' : 'Seç')
                          : (english
                                ? GateSequencePuzzle.gateNamesEn[gate]
                                : GateSequencePuzzle.gateNames[gate]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gate == null
                            ? _GateSequencePlayPageState._muted
                            : _GateSequencePlayPageState._ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _GateTray extends StatelessWidget {
  const _GateTray({
    required this.gateCount,
    required this.order,
    required this.english,
    required this.onTap,
  });

  final int gateCount;
  final List<int?> order;
  final bool english;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => GridView.builder(
    key: const ValueKey<String>('gate_sequence_tray'),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: gateCount,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      mainAxisExtent: 66,
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
    ),
    itemBuilder: (BuildContext context, int index) {
      final bool used = order.contains(index);
      final Color accent = _GateSequencePlayPageState._gateColors[index];
      return Semantics(
        button: true,
        label: english
            ? '${GateSequencePuzzle.gateNamesEn[index]}${used ? ', already placed; tap to move' : ''}'
            : '${GateSequencePuzzle.gateNames[index]}${used ? ', yerleştirildi; taşımak için dokun' : ''}',
        child: Opacity(
          opacity: used ? .72 : 1,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: ValueKey<String>('gate_sequence_gate_$index'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTap(index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: used
                        ? const Color(0xFFE3E6E2)
                        : accent.withValues(alpha: .42),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      used
                          ? Icons.swap_horiz_rounded
                          : Icons.door_front_door_outlined,
                      color: accent,
                      size: 19,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      english
                          ? GateSequencePuzzle.gateNamesEn[index]
                          : GateSequencePuzzle.gateNames[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _GateSequencePlayPageState._ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

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
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 17),
    label: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1),
    ),
    style: TextButton.styleFrom(
      foregroundColor: _GateSequencePlayPageState._muted,
      minimumSize: const Size(48, 44),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}
