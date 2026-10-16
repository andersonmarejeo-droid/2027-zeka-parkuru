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
import '../shared/studio_game_skin.dart';
import 'pin_unlock_puzzle.dart';

class PinUnlockGamePage extends StatelessWidget {
  const PinUnlockGamePage({
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
    (int index) {
      final int stage = (index % 10) + 1;
      return ParkurLevelSpec(
        number: index + 1,
        titleTr: 'Kilit ${'${index + 1}'.padLeft(3, '0')}',
        titleEn: 'Lock ${'${index + 1}'.padLeft(3, '0')}',
        subtitleTr: 'Pim kısıtlarını birleştir',
        subtitleEn: 'Combine the pin constraints',
        difficulty: stage <= 6
            ? 'USTALAŞMA'
            : stage <= 8
            ? 'İLERİ'
            : 'UZMAN',
        icon: Icons.lock_open_rounded,
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.logic);
    return ParkurLevelHub(
      gameId: 'pin_unlock',
      progressPrefix: 'pin_unlock',
      titleTr: 'Kilit Aç',
      titleEn: 'Pin Unlock',
      taglineTr: 'Mekanik ipuçlarını birleştir, kilidi aç',
      taglineEn: 'Combine mechanical clues and release the lock',
      accent: skin.accent,
      icon: Icons.lock_open_rounded,
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
          ) => PinUnlockPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class PinUnlockPlayPage extends StatefulWidget {
  const PinUnlockPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<PinUnlockPlayPage> createState() => _PinUnlockPlayPageState();
}

class _PinUnlockPlayPageState extends State<PinUnlockPlayPage> {
  static const Color _ink = Color(0xFF283640);
  static const Color _muted = Color(0xFF71808A);
  static const Color _canvas = Color(0xFFF3F5F3);
  static const Color _surface = Colors.white;
  static const Color _accent = Color(0xFF527E86);
  static const Color _brass = Color(0xFFB58A58);
  static const Color _success = Color(0xFF548775);
  static const Color _pending = Color(0xFFB98957);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  final List<List<int>> _undo = <List<int>>[];
  late final PinUnlockPuzzle _puzzle;
  late final StudioGameSession _session;
  late List<int> _heights;
  bool _english = false;
  bool _finished = false;
  int _moves = 0;
  int _hints = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = PinUnlockPuzzle.forLevel(widget.level.number);
    _heights = List<int>.filled(_puzzle.pinCount, 1);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  void _setHeight(int pin, int height) {
    if (_finished || _heights[pin] == height) return;
    setState(() {
      _undo.add(List<int>.from(_heights));
      _heights[pin] = height;
      _moves++;
    });
    _session.recordAccepted();
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .28),
    );
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    setState(() {
      _heights = _undo.removeLast();
      _moves++;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .32));
  }

  void _hint() {
    if (_finished ||
        !_session.canUseHint ||
        _hints >= math.max(0, _puzzle.pinCount - 1)) {
      return;
    }
    final int pin = List<int>.generate(_puzzle.pinCount, (int index) => index)
        .firstWhere(
          (int index) => _heights[index] != _puzzle.solution[index],
          orElse: () => -1,
        );
    if (pin < 0) return;
    setState(() {
      _undo.add(List<int>.from(_heights));
      _heights[pin] = _puzzle.solution[pin];
      _moves++;
      _hints++;
    });
    _session.useHint(pointCost: 100);
    final String letter = String.fromCharCode(65 + pin);
    _showMessage(
      _english
          ? 'Pin $letter is set to notch ${_puzzle.solution[pin]}.'
          : '$letter pimi ${_puzzle.solution[pin]}. çentikte olmalı.',
    );
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .38));
  }

  void _reset() {
    if (_finished) return;
    setState(() {
      _heights = List<int>.filled(_puzzle.pinCount, 1);
      _undo.clear();
      _moves = 0;
      _hints = 0;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .32));
  }

  Future<void> _checkLock() async {
    if (_finished) return;
    if (_puzzle.isSolved(_heights)) {
      await _complete();
      return;
    }
    _session.recordMistake();
    final int conflicts = _puzzle.clues
        .where((PinClue clue) => !clue.matches(_heights))
        .length;
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .36));
    _showMessage(
      _english
          ? '$conflicts clue signals are still out of alignment.'
          : '$conflicts ipucu sinyali henüz pimlerle uyuşmuyor.',
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
    final int score = math.max(180, 1900 - _moves * 10 - _hints * 220);
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < PinUnlockGamePage.totalCases
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
    await Future<void>.delayed(const Duration(milliseconds: 170));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: _ink,
        icon: const Icon(Icons.lock_open_rounded, color: Color(0xFFE8C99B)),
        title: Text(
          _english ? 'LOCK RELEASED' : 'KİLİT AÇILDI',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _english
              ? '$stars stars  •  $score points\nEvery pin is aligned.'
              : '$stars yıldız  •  $score puan\nTüm pimler doğru hizalandı.',
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
              widget.level.number < PinUnlockGamePage.totalCases
                  ? (_english ? 'NEXT LOCK' : 'SONRAKİ KİLİT')
                  : (_english ? 'CASE BOARD' : 'BÖLÜM PANOSU'),
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
              _english ? 'PIN UNLOCK' : 'KİLİT AÇ',
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
                  ? 'LOCK ${widget.level.number.toString().padLeft(3, '0')}'
                  : 'KİLİT ${widget.level.number.toString().padLeft(3, '0')}',
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
            tooltip: _english ? 'Reveal one pin' : 'Bir pimi göster',
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            onPressed: _reset,
            tooltip: _english ? 'Reset pins' : 'Pimleri sıfırla',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 640,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 26),
            children: <Widget>[
              _LockHero(
                level: widget.level.number,
                pinCount: _puzzle.pinCount,
                clueCount: _puzzle.clues.length,
                moves: _moves,
                bestScore: widget.previousBestScore,
                stage: _puzzle.localStage,
                english: _english,
              ),
              const SizedBox(height: 14),
              _SectionHeading(
                title: _english ? 'MECHANICAL SIGNALS' : 'MEKANİK İPUÇLARI',
                detail: _english
                    ? 'Combine the readings; no single line gives a pin away.'
                    : 'Ölçümleri birleştir; tek bir satır pim değerini vermez.',
              ),
              const SizedBox(height: 8),
              _ClueBoard(
                clues: _puzzle.clues,
                heights: _heights,
                english: _english,
              ),
              const SizedBox(height: 15),
              _SectionHeading(
                title: _english ? 'PIN BANK' : 'PİM BANKASI',
                detail: _english
                    ? 'Tap one of four notch heights for each pin.'
                    : 'Her pim için dört çentik yüksekliğinden birini seç.',
              ),
              const SizedBox(height: 8),
              _PinBank(
                heights: _heights,
                english: _english,
                onSelect: _setHeight,
              ),
              const SizedBox(height: 9),
              Row(
                children: <Widget>[
                  _SmallAction(
                    key: const ValueKey<String>('pin_unlock_undo'),
                    icon: Icons.undo_rounded,
                    label: _english ? 'UNDO' : 'GERİ AL',
                    onPressed: _undo.isEmpty ? null : _undoMove,
                  ),
                  const Spacer(),
                  _SmallAction(
                    icon: Icons.lightbulb_outline_rounded,
                    label: _english ? 'HINT' : 'İPUCU',
                    onPressed: _hint,
                  ),
                  const Spacer(),
                  _SmallAction(
                    icon: Icons.restart_alt_rounded,
                    label: _english ? 'RESET' : 'SIFIRLA',
                    onPressed: _reset,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey<String>('pin_unlock_check'),
                onPressed: _checkLock,
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(
                  _english ? 'TEST THE LOCK' : 'KİLİDİ SINAYI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 7),
              Center(
                child: Text(
                  _english
                      ? 'Four calibrated notches · ${_puzzle.difficultyTier}'
                      : 'Dört hassas çentik · ${_puzzle.difficultyTier}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
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

class _LockHero extends StatelessWidget {
  const _LockHero({
    required this.level,
    required this.pinCount,
    required this.clueCount,
    required this.moves,
    required this.bestScore,
    required this.stage,
    required this.english,
  });

  final int level;
  final int pinCount;
  final int clueCount;
  final int moves;
  final int bestScore;
  final int stage;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: _PinUnlockPlayPageState._surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE2E6E3)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x0B283640),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 82,
          height: 78,
          child: CustomPaint(painter: _LockPlatePainter(stage: stage)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'PRECISION CYLINDER' : 'HASSAS KİLİT SİLİNDİRİ',
                style: const TextStyle(
                  color: _PinUnlockPlayPageState._muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                english ? 'Release the core.' : 'Çekirdeği serbest bırak.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _PinUnlockPlayPageState._ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 9,
                runSpacing: 4,
                children: <Widget>[
                  _MetricPill(text: '${english ? 'PINS' : 'PİM'} $pinCount'),
                  _MetricPill(
                    text: '${english ? 'CLUES' : 'İPUCU'} $clueCount',
                  ),
                  _MetricPill(text: '${english ? 'MOVES' : 'HAMLE'} $moves'),
                ],
              ),
              if (bestScore > 0) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  '${english ? 'BEST' : 'REKOR'} $bestScore · ${english ? 'LEVEL' : 'AŞAMA'} $level',
                  style: const TextStyle(
                    color: _PinUnlockPlayPageState._success,
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

class _LockPlatePainter extends CustomPainter {
  const _LockPlatePainter({required this.stage});

  final int stage;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect plate = RRect.fromRectAndRadius(
      bounds.deflate(3),
      const Radius.circular(18),
    );
    final Paint shadow = Paint()
      ..color = const Color(0x17283640)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(plate.shift(const Offset(0, 3)), shadow);
    final Paint enamel = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFFAFCFB), Color(0xFFE8EFEC)],
      ).createShader(bounds);
    canvas.drawRRect(plate, enamel);
    canvas.drawRRect(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = const Color(0xFFD3DEDA),
    );
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) * .31;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFC4D0CC));
    canvas.drawCircle(
      center,
      radius * .79,
      Paint()..color = const Color(0xFF607E80),
    );
    canvas.drawCircle(
      center,
      radius * .52,
      Paint()..color = const Color(0xFFEAF0ED),
    );
    final int teeth = 4 + stage ~/ 3;
    final Paint tooth = Paint()
      ..color = _PinUnlockPlayPageState._brass
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (int index = 0; index < teeth; index++) {
      final double angle = math.pi * 2 * index / teeth;
      final Offset start =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * .91;
      final Offset end =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 1.06;
      canvas.drawLine(start, end, tooth);
    }
    canvas.drawCircle(
      center,
      radius * .2,
      Paint()..color = _PinUnlockPlayPageState._brass,
    );
    final Paint screw = Paint()..color = const Color(0xFFB8C5C1);
    for (final Offset point in <Offset>[
      const Offset(12, 12),
      Offset(size.width - 12, 12),
      Offset(12, size.height - 12),
      Offset(size.width - 12, size.height - 12),
    ]) {
      canvas.drawCircle(point, 2.2, screw);
    }
  }

  @override
  bool shouldRepaint(covariant _LockPlatePainter oldDelegate) =>
      oldDelegate.stage != stage;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: const TextStyle(
          color: _PinUnlockPlayPageState._ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        detail,
        style: const TextStyle(
          color: _PinUnlockPlayPageState._muted,
          fontSize: 10,
          height: 1.3,
        ),
      ),
    ],
  );
}

class _ClueBoard extends StatelessWidget {
  const _ClueBoard({
    required this.clues,
    required this.heights,
    required this.english,
  });

  final List<PinClue> clues;
  final List<int> heights;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xFFE9EFEC),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFFDDE5E1)),
    ),
    child: Column(
      children: <Widget>[
        for (int index = 0; index < clues.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 6),
          _ClueRow(
            index: index,
            clue: clues[index],
            matches: clues[index].matches(heights),
            english: english,
          ),
        ],
      ],
    ),
  );
}

class _ClueRow extends StatelessWidget {
  const _ClueRow({
    required this.index,
    required this.clue,
    required this.matches,
    required this.english,
  });

  final int index;
  final PinClue clue;
  final bool matches;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final Color signal = matches
        ? _PinUnlockPlayPageState._success
        : _PinUnlockPlayPageState._pending;
    final IconData icon = switch (clue.family) {
      PinClueFamily.pair => Icons.compare_arrows_rounded,
      PinClueFamily.aggregate => Icons.functions_rounded,
      PinClueFamily.sequence => Icons.insights_rounded,
    };
    return Semantics(
      label:
          '${english ? 'Clue' : 'İpucu'} ${index + 1}. ${clue.text(english: english)}. ${matches ? (english ? 'Aligned' : 'Uyumlu') : (english ? 'Not aligned' : 'Uyumsuz')}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _PinUnlockPlayPageState._surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFE2E8E5)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 17, color: _PinUnlockPlayPageState._accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                clue.text(english: english),
                style: const TextStyle(
                  color: _PinUnlockPlayPageState._ink,
                  fontSize: 11,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Icon(
              matches ? Icons.check_circle_rounded : Icons.adjust_rounded,
              key: ValueKey<String>('pin_unlock_clue_$index'),
              size: 19,
              color: signal,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinBank extends StatelessWidget {
  const _PinBank({
    required this.heights,
    required this.english,
    required this.onSelect,
  });

  final List<int> heights;
  final bool english;
  final void Function(int pin, int height) onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: _PinUnlockPlayPageState._surface,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFFE1E6E3)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x08283640),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: <Widget>[
        for (int pin = 0; pin < heights.length; pin++) ...<Widget>[
          if (pin > 0) const SizedBox(height: 6),
          _PinChoiceRow(
            pin: pin,
            selected: heights[pin],
            english: english,
            onSelect: (int height) => onSelect(pin, height),
          ),
        ],
      ],
    ),
  );
}

class _PinChoiceRow extends StatelessWidget {
  const _PinChoiceRow({
    required this.pin,
    required this.selected,
    required this.english,
    required this.onSelect,
  });

  final int pin;
  final int selected;
  final bool english;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Container(
        width: 40,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              String.fromCharCode(65 + pin),
              style: const TextStyle(
                color: _PinUnlockPlayPageState._ink,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            Text(
              english ? 'PIN' : 'PİM',
              style: const TextStyle(
                color: _PinUnlockPlayPageState._muted,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 7),
      for (
        int height = 1;
        height <= PinUnlockPuzzle.heightCount;
        height++
      ) ...<Widget>[
        if (height > 1) const SizedBox(width: 4),
        Expanded(
          child: _NotchButton(
            pin: pin,
            height: height,
            selected: selected == height,
            english: english,
            onTap: () => onSelect(height),
          ),
        ),
      ],
    ],
  );
}

class _NotchButton extends StatelessWidget {
  const _NotchButton({
    required this.pin,
    required this.height,
    required this.selected,
    required this.english,
    required this.onTap,
  });

  final int pin;
  final int height;
  final bool selected;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? _PinUnlockPlayPageState._accent
        : const Color(0xFFF3F5F4);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${english ? 'Pin' : 'Pim'} ${String.fromCharCode(65 + pin)}, ${english ? 'notch' : 'çentik'} $height',
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey<String>('pin_unlock_pin_${pin}_height_$height'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: GameInputPolicy.minimumTargetSize,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  selected ? Icons.circle : Icons.circle_outlined,
                  size: 13,
                  color: selected
                      ? Colors.white
                      : _PinUnlockPlayPageState._brass,
                ),
                const SizedBox(height: 1),
                Text(
                  '$height',
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : _PinUnlockPlayPageState._ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4F2),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: _PinUnlockPlayPageState._muted,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: .4,
      ),
    ),
  );
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
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
    label: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
    ),
    style: TextButton.styleFrom(
      foregroundColor: _PinUnlockPlayPageState._accent,
      minimumSize: const Size(78, GameInputPolicy.minimumTargetSize),
      padding: const EdgeInsets.symmetric(horizontal: 5),
    ),
  );
}
