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
import 'target_24_puzzle.dart';

class Target24GamePage extends StatelessWidget {
  const Target24GamePage({
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
    GameContentPolicy.nativeStages('target_24'),
    (int index) {
      final int stage = (index % 10) + 1;
      return ParkurLevelSpec(
        number: index + 1,
        titleTr: 'Hedef ${'${index + 1}'.padLeft(3, '0')}',
        titleEn: 'Target ${'${index + 1}'.padLeft(3, '0')}',
        subtitleTr: 'Dört kartı tek işlem ağacında kullan',
        subtitleEn: 'Use all four cards in one expression tree',
        difficulty: stage <= 6
            ? 'USTALAŞMA'
            : stage <= 8
            ? 'İLERİ'
            : 'UZMAN',
        icon: Icons.functions_rounded,
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('target_24');
    return ParkurLevelHub(
      gameId: 'target_24',
      progressPrefix: 'target_24',
      titleTr: 'Hedef 24',
      titleEn: 'Target 24',
      taglineTr: 'İşlemi seç • Kartları birleştir • 24’e ulaş',
      taglineEn: 'Choose an operation • Combine cards • Reach 24',
      accent: skin.accent,
      icon: Icons.functions_rounded,
      levels: _levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder: (
        BuildContext context,
        ParkurLevelSpec level,
        int previousBestScore,
        int? competitionLayoutCode,
        bool competitionMode,
      ) => Target24PlayPage(level: level, previousBestScore: previousBestScore),
    );
  }
}

class Target24PlayPage extends StatefulWidget {
  const Target24PlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<Target24PlayPage> createState() => _Target24PlayPageState();
}

class _Target24PlayPageState extends State<Target24PlayPage> {
  static const Color _ink = StudioVisuals.ink;
  static const Color _muted = StudioVisuals.muted;
  static const Color _canvas = StudioVisuals.canvas;
  static const Color _surface = StudioVisuals.surface;
  static const Color _accent = Color(0xFF247568);
  static const Color _brass = Color(0xFFB58A58);
  static const Color _success = Color(0xFF548775);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.numbers,
  );
  final List<List<Target24Expression>> _undo = <List<Target24Expression>>[];
  late final Target24Puzzle _puzzle;
  late final StudioGameSession _session;
  late final List<Target24Expression> _initialExpressions;
  late List<Target24Expression> _activeExpressions;
  Target24Operator? _selectedOperation;
  String? _firstOperandSignature;
  bool _english = false;
  bool _finished = false;
  int _moves = 0;
  int _hints = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = Target24Puzzle.forLevel(widget.level.contentIndex);
    _initialExpressions = List<Target24Expression>.unmodifiable(
      <Target24Expression>[
        for (final Target24Card card in _puzzle.cards)
          Target24Expression.card(
            cardId: card.id,
            value: Target24Rational(card.value),
          ),
      ],
    );
    _activeExpressions = List<Target24Expression>.from(_initialExpressions);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  int get _completedCombinations =>
      _puzzle.cards.length - _activeExpressions.length;

  String _expressionKey(Target24Expression expression) => expression.isCard
      ? 'target24_card_${expression.cardId}'
      : 'target24_expression_${expression.signature}';

  void _selectOperation(Target24Operator operation) {
    if (_finished) return;
    setState(() {
      _selectedOperation = operation;
      _firstOperandSignature = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .27),
    );
  }

  void _selectExpression(Target24Expression expression) {
    if (_finished) return;
    final Target24Operator? operation = _selectedOperation;
    if (operation == null) {
      _showMessage(
        _english ? 'Choose an operation first.' : 'Önce bir işlem seç.',
      );
      return;
    }
    if (_firstOperandSignature == null) {
      setState(() => _firstOperandSignature = expression.signature);
      _audio.hapticSelection();
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .24),
      );
      return;
    }
    final Target24Expression? first = _activeExpressions
        .where(
          (Target24Expression item) => item.signature == _firstOperandSignature,
        )
        .firstOrNull;
    if (first == null) {
      setState(() => _firstOperandSignature = expression.signature);
      return;
    }
    if (first.signature == expression.signature) {
      setState(() => _firstOperandSignature = null);
      return;
    }
    _combine(first, expression, operation);
  }

  void _combine(
    Target24Expression first,
    Target24Expression second,
    Target24Operator operation, {
    bool fromHint = false,
  }) {
    if (operation == Target24Operator.divide && second.value.isZero) {
      if (!fromHint) {
        _session.recordMistake();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .34),
        );
        _showMessage(
          _english
              ? 'Division by zero is not allowed.'
              : 'Sıfıra bölme yapılamaz.',
        );
      }
      setState(() {
        _selectedOperation = null;
        _firstOperandSignature = null;
      });
      return;
    }
    final Target24Expression combined = Target24Expression.combine(
      operation: operation,
      first: first,
      second: second,
      value: first.value.apply(operation, second.value),
    );
    setState(() {
      _undo.add(List<Target24Expression>.from(_activeExpressions));
      _activeExpressions = <Target24Expression>[
        for (final Target24Expression item in _activeExpressions)
          if (item.signature != first.signature &&
              item.signature != second.signature)
            item,
        combined,
      ];
      _selectedOperation = null;
      _firstOperandSignature = null;
      _moves++;
    });
    _session.recordAccepted();
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .35));
    if (_activeExpressions.length == 1) {
      _showMessage(
        _activeExpressions.single.value == Target24Puzzle.target
            ? (_english
                  ? '24 is ready. Check your expression.'
                  : '24 hazır. İşlemini kontrol et.')
            : (_english
                  ? 'Your final value is ${_activeExpressions.single.value}.'
                  : 'Sonucun ${_activeExpressions.single.value} oldu.'),
      );
    }
  }

  void _hint() {
    if (_finished ||
        _activeExpressions.length == 1 ||
        !_session.canUseHint ||
        _hints >= math.max(0, _puzzle.solutionSteps.length - 1)) {
      return;
    }
    for (final Target24Step step in _puzzle.solutionSteps) {
      final Target24Expression? first = _activeExpressions
          .where(
            (Target24Expression expression) =>
                expression.signature == step.first.signature,
          )
          .firstOrNull;
      final Target24Expression? second = _activeExpressions
          .where(
            (Target24Expression expression) =>
                expression.signature == step.second.signature,
          )
          .firstOrNull;
      if (first == null || second == null) continue;
      _combine(first, second, step.operation, fromHint: true);
      setState(() => _hints++);
      _session.useHint(pointCost: 140);
      unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .37));
      _showMessage(
        _english
            ? 'Hint: ${first.value} ${step.operation.symbol} ${second.value} = ${step.result}.'
            : 'İpucu: ${first.value} ${step.operation.symbol} ${second.value} = ${step.result}.',
      );
      return;
    }
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    setState(() {
      _activeExpressions = _undo.removeLast();
      _selectedOperation = null;
      _firstOperandSignature = null;
      _moves++;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .3));
  }

  void _reset() {
    if (_finished) return;
    setState(() {
      _activeExpressions = List<Target24Expression>.from(_initialExpressions);
      _selectedOperation = null;
      _firstOperandSignature = null;
      _undo.clear();
      _moves = 0;
      _hints = 0;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .3));
  }

  Future<void> _checkTarget() async {
    if (_finished || _activeExpressions.length != 1) return;
    if (_puzzle.isSolved(_activeExpressions.single)) {
      await _complete();
      return;
    }
    _session.recordMistake();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .37));
    _showMessage(
      _english
          ? 'The result is ${_activeExpressions.single.value}, not 24. Undo a step and rework it.'
          : 'Sonuç ${_activeExpressions.single.value}; 24 değil. Bir adımı geri alıp yeniden dene.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1900),
        ),
      );
  }

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    final int stars = _hints == 0 && _session.mistakes == 0
        ? 3
        : _hints <= 1 && _session.mistakes <= 1
        ? 2
        : 1;
    final int score = math.max(
      180,
      1900 -
          math.max(0, _moves - 3) * 35 -
          _hints * 190 -
          _session.mistakes * 75,
    );
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < Target24GamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticMedium();
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
        icon: const Icon(Icons.functions_rounded, color: Color(0xFFE8C99B)),
        title: Text(
          _english ? 'TARGET REACHED' : 'HEDEF YAKALANDI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _english
              ? '$stars stars  •  $score points\nFour cards, one exact expression.'
              : '$stars yıldız  •  $score puan\nDört kart, tek doğru işlem.',
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
            child: Text(_english ? 'MAP' : 'PARKUR'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(result.toParkurResult());
            },
            child: Text(
              widget.level.number < Target24GamePage.totalCases
                  ? (_english ? 'NEXT DEAL' : 'SONRAKİ EL')
                  : (_english ? 'LEVEL BOARD' : 'BÖLÜM PANOSU'),
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
              _english ? 'TARGET 24' : 'HEDEF 24',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            Text(
              '${_english ? 'DEAL' : 'EL'} ${widget.level.number.toString().padLeft(3, '0')} · ${_puzzle.difficultyTier}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _hint,
            tooltip: _english
                ? 'Combine one correct pair'
                : 'Doğru bir kart çiftini birleştir',
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            onPressed: _reset,
            tooltip: _english ? 'Reset deal' : 'Eli sıfırla',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 640,
          child: ListView(
            key: const ValueKey<String>('target24_scroll'),
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 26),
            children: <Widget>[
              _Target24Hero(
                level: widget.level.number,
                combinations: _completedCombinations,
                moves: _moves,
                hints: _hints,
                bestScore: widget.previousBestScore,
                stage: _puzzle.localStage,
                english: _english,
              ),
              const SizedBox(height: 13),
              _TargetPlate(english: _english, stage: _puzzle.localStage),
              const SizedBox(height: 14),
              _SectionHeading(
                title: _english ? 'CHOOSE AN OPERATION' : 'İŞLEMİ SEÇ',
                detail: _english
                    ? 'Choose first, then select the two cards in operand order.'
                    : 'Önce işlemi, sonra kartları işlem sırasıyla seç.',
              ),
              const SizedBox(height: 7),
              _OperationTray(
                selected: _selectedOperation,
                english: _english,
                onSelect: _selectOperation,
              ),
              const SizedBox(height: 12),
              _SectionHeading(
                title: _english ? 'NUMBER CARDS' : 'SAYI KARTLARI',
                detail: _instruction,
              ),
              const SizedBox(height: 7),
              _NumberCardBoard(
                expressions: _activeExpressions,
                selectedSignature: _firstOperandSignature,
                english: _english,
                onTap: _selectExpression,
                expressionKey: _expressionKey,
              ),
              const SizedBox(height: 10),
              _CombinationProgress(
                completed: _completedCombinations,
                english: _english,
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: <Widget>[
                  _SmallAction(
                    key: const ValueKey<String>('target24_undo'),
                    icon: Icons.undo_rounded,
                    label: _english ? 'UNDO' : 'GERİ AL',
                    onPressed: _undo.isEmpty ? null : _undoMove,
                  ),
                  _SmallAction(
                    icon: Icons.lightbulb_outline_rounded,
                    label: _english ? 'HINT' : 'İPUCU',
                    onPressed: _hint,
                  ),
                  _SmallAction(
                    icon: Icons.restart_alt_rounded,
                    label: _english ? 'RESET' : 'SIFIRLA',
                    onPressed: _reset,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              FilledButton.icon(
                key: const ValueKey<String>('target24_check'),
                onPressed: _activeExpressions.length == 1 ? _checkTarget : null,
                icon: const Icon(Icons.track_changes_rounded),
                label: Text(
                  _english ? 'CHECK THE TARGET' : 'HEDEFİ KONTROL ET',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFDDE5E1),
                  disabledForegroundColor: const Color(0xFF85938D),
                  minimumSize: const Size.fromHeight(
                    GameInputPolicy.minimumTargetSize + 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Center(
                child: Text(
                  _english
                      ? 'Use every card once · Exact fractions allowed · ${_puzzle.difficultyTier}'
                      : 'Her kartı bir kez kullan · Kesirli ara sonuç serbest · ${_puzzle.difficultyTier}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _instruction {
    if (_selectedOperation == null) {
      return _english
          ? 'Tap an operation above to begin.'
          : 'Başlamak için yukarıdan bir işlem seç.';
    }
    if (_firstOperandSignature == null) {
      return _english
          ? 'Choose the first number for ${_selectedOperation!.symbol}.'
          : '${_selectedOperation!.symbol} işleminin ilk sayısını seç.';
    }
    return _english
        ? 'Now choose the second number; order matters.'
        : 'Şimdi ikinci sayıyı seç; işlem sırası önemli.';
  }
}

class _Target24Hero extends StatelessWidget {
  const _Target24Hero({
    required this.level,
    required this.combinations,
    required this.moves,
    required this.hints,
    required this.bestScore,
    required this.stage,
    required this.english,
  });

  final int level;
  final int combinations;
  final int moves;
  final int hints;
  final int bestScore;
  final int stage;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _Target24PlayPageState._surface,
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
          width: 88,
          height: 78,
          child: CustomPaint(painter: _NumberStudioPainter(stage: stage)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'ARITHMETIC STUDIO' : 'İŞLEM ATÖLYESİ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _Target24PlayPageState._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                english ? 'Build it to 24.' : '24’e adım adım ulaş.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _Target24PlayPageState._ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: <Widget>[
                  _MetricPill(
                    text: '${english ? 'JOINED' : 'BİRLEŞİM'} $combinations/3',
                  ),
                  _MetricPill(text: '${english ? 'MOVES' : 'HAMLE'} $moves'),
                  _MetricPill(text: '${english ? 'HINTS' : 'İPUCU'} $hints'),
                ],
              ),
              if (bestScore > 0) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  '${english ? 'BEST' : 'REKOR'} $bestScore · ${english ? 'DEAL' : 'EL'} $level',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _Target24PlayPageState._success,
                    fontSize: 12,
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

class _NumberStudioPainter extends CustomPainter {
  const _NumberStudioPainter({required this.stage});

  final int stage;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect panel = RRect.fromRectAndRadius(
      bounds.deflate(2),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFAFCFB), Color(0xFFE8EFEC)],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFD3DEDA),
    );
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double cardWidth = math.min(size.width * .28, 22);
    final double cardHeight = 28;
    final List<Offset> positions = <Offset>[
      Offset(centerX - cardWidth - 4, centerY - cardHeight - 4),
      Offset(centerX + 4, centerY - cardHeight - 4),
      Offset(centerX - cardWidth - 4, centerY + 4),
      Offset(centerX + 4, centerY + 4),
    ];
    final List<Color> colors = <Color>[
      const Color(0xFFDCEAE5),
      const Color(0xFFECE4D8),
      const Color(0xFFE1E8EB),
      const Color(0xFFE9E8DF),
    ];
    const List<String> symbols = <String>['7', '×', '3', '+'];
    for (int index = 0; index < positions.length; index++) {
      final Rect card = Rect.fromLTWH(
        positions[index].dx,
        positions[index].dy,
        cardWidth,
        cardHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(card, const Radius.circular(6)),
        Paint()..color = colors[(index + stage) % colors.length],
      );
      final TextPainter label = TextPainter(
        text: TextSpan(
          text: symbols[index],
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: _Target24PlayPageState._accent,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        card.center - Offset(label.width / 2, label.height / 2),
      );
    }
    final Paint line = Paint()
      ..color = _Target24PlayPageState._brass.withValues(alpha: .62)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(centerX, 6), Offset(centerX, size.height - 6), line);
  }

  @override
  bool shouldRepaint(_NumberStudioPainter oldDelegate) =>
      stage != oldDelegate.stage;
}

class _TargetPlate extends StatelessWidget {
  const _TargetPlate({required this.english, required this.stage});

  final bool english;
  final int stage;

  @override
  Widget build(BuildContext context) => Container(
    height: 86,
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    decoration: BoxDecoration(
      color: _Target24PlayPageState._ink,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x18283640),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 62,
          child: CustomPaint(painter: _TargetRingPainter(stage: stage)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'EXACT TARGET' : 'KESİN HEDEF',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFFBBC8C2),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '24',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontSize: 32,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
            ],
          ),
        ),
        Text(
          english ? '3 COMBINATIONS' : '3 BİRLEŞİM',
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFFE1C49E),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      ],
    ),
  );
}

class _TargetRingPainter extends CustomPainter {
  const _TargetRingPainter({required this.stage});

  final int stage;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) * .45;
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int index = 0; index < 4; index++) {
      ring.color = index == stage % 4
          ? const Color(0xFFE1C49E)
          : const Color(0xFF6C827A);
      canvas.drawCircle(center, radius * (1 - index * .21), ring);
    }
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFFE1C49E));
  }

  @override
  bool shouldRepaint(_TargetRingPainter oldDelegate) =>
      stage != oldDelegate.stage;
}

class _OperationTray extends StatelessWidget {
  const _OperationTray({
    required this.selected,
    required this.english,
    required this.onSelect,
  });

  final Target24Operator? selected;
  final bool english;
  final ValueChanged<Target24Operator> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (
        int index = 0;
        index < Target24Operator.values.length;
        index++
      ) ...<Widget>[
        if (index > 0) const SizedBox(width: 7),
        Expanded(
          child: _OperationButton(
            operation: Target24Operator.values[index],
            selected: selected == Target24Operator.values[index],
            english: english,
            onTap: () => onSelect(Target24Operator.values[index]),
          ),
        ),
      ],
    ],
  );
}

class _OperationButton extends StatelessWidget {
  const _OperationButton({
    required this.operation,
    required this.selected,
    required this.english,
    required this.onTap,
  });

  final Target24Operator operation;
  final bool selected;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${english ? 'Operation' : 'İşlem'} ${operation.symbol}',
    child: Material(
      color: selected
          ? _Target24PlayPageState._accent
          : _Target24PlayPageState._surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey<String>('target24_op_${operation.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: GameInputPolicy.minimumTargetSize + 7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                operation.symbol,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: selected ? Colors.white : _Target24PlayPageState._ink,
                  fontSize: 21,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _operationName(operation, english),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: selected
                      ? Colors.white70
                      : _Target24PlayPageState._muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String _operationName(Target24Operator value, bool english) =>
      switch (value) {
        Target24Operator.add => english ? 'ADD' : 'TOPLA',
        Target24Operator.subtract => english ? 'SUBTRACT' : 'ÇIKAR',
        Target24Operator.multiply => english ? 'MULTIPLY' : 'ÇARP',
        Target24Operator.divide => english ? 'DIVIDE' : 'BÖL',
      };
}

class _NumberCardBoard extends StatelessWidget {
  const _NumberCardBoard({
    required this.expressions,
    required this.selectedSignature,
    required this.english,
    required this.onTap,
    required this.expressionKey,
  });

  final List<Target24Expression> expressions;
  final String? selectedSignature;
  final bool english;
  final ValueChanged<Target24Expression> onTap;
  final String Function(Target24Expression) expressionKey;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double gap = 8;
      final double width = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: <Widget>[
          for (final Target24Expression expression in expressions)
            _NumberCard(
              key: ValueKey<String>(expressionKey(expression)),
              expression: expression,
              width: width,
              selected: expression.signature == selectedSignature,
              english: english,
              onTap: () => onTap(expression),
            ),
        ],
      );
    },
  );
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({
    super.key,
    required this.expression,
    required this.width,
    required this.selected,
    required this.english,
    required this.onTap,
  });

  final Target24Expression expression;
  final double width;
  final bool selected;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool originalCard = expression.isCard;
    final String identity = originalCard
        ? Target24Puzzle.cardLetters[expression.cardId!]
        : (english ? 'COMBINED' : 'BİRLEŞİK');
    return Semantics(
      button: true,
      selected: selected,
      label:
          '$identity, ${expression.value}${originalCard ? (english ? ' original card' : ' ilk kart') : ', ${expression.expressionText(english: english)}'}',
      child: Material(
        color: selected
            ? const Color(0xFFE8F2EE)
            : _Target24PlayPageState._surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: width,
            height: 84,
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected
                    ? _Target24PlayPageState._accent
                    : const Color(0xFFE2E7E4),
                width: selected ? 1.8 : .9,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x07283640),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 21,
                      height: 21,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: originalCard
                            ? const Color(0xFFF0F4F2)
                            : const Color(0xFFF4EEE4),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        identity == 'COMBINED' || identity == 'BİRLEŞİK'
                            ? '∑'
                            : identity,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: originalCard
                              ? _Target24PlayPageState._accent
                              : _Target24PlayPageState._brass,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 15,
                      color: selected
                          ? _Target24PlayPageState._accent
                          : const Color(0xFFC7D0CC),
                    ),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    expression.value.toString(),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _Target24PlayPageState._ink,
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
                if (!originalCard) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    expression.expressionText(english: english),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _Target24PlayPageState._muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else
                  const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CombinationProgress extends StatelessWidget {
  const _CombinationProgress({required this.completed, required this.english});

  final int completed;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFEDF2EF),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: <Widget>[
        Text(
          english ? 'COMBINATIONS' : 'BİRLEŞİMLER',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: _Target24PlayPageState._muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .65,
          ),
        ),
        const Spacer(),
        for (int index = 0; index < 3; index++) ...<Widget>[
          if (index > 0) const SizedBox(width: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 24,
            height: 6,
            decoration: BoxDecoration(
              color: index < completed
                  ? _Target24PlayPageState._success
                  : const Color(0xFFD5DEDA),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ],
    ),
  );
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
          fontFamily: 'Roboto',
          color: _Target24PlayPageState._ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        detail,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: _Target24PlayPageState._muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    ],
  );
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
        fontFamily: 'Roboto',
        color: _Target24PlayPageState._muted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: .35,
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
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
    style: TextButton.styleFrom(
      foregroundColor: _Target24PlayPageState._accent,
      minimumSize: const Size(78, GameInputPolicy.minimumTargetSize),
      padding: const EdgeInsets.symmetric(horizontal: 5),
    ),
  );
}
