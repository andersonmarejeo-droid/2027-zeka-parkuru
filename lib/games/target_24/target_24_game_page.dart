import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/studio_visuals.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/common_level_score_service.dart';
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

  static ParkurLevelSpec levelSpec(int index) {
    final int safeLevel = GameContentPolicy.endlessHighChapter(index + 1);
    final int stage = ((safeLevel - 1) % 10) + 1;
    final int target = Target24Puzzle.targetNumberForLevel(index + 1);
    return ParkurLevelSpec(
      number: index + 1,
      titleTr: 'Hedef $target',
      titleEn: 'Target $target',
      subtitleTr: 'Dört kartı tek işlem ağacında kullan',
      subtitleEn: 'Use all four cards in one expression tree',
      difficulty: stage <= 6
          ? 'USTALAŞMA'
          : stage <= 8
          ? 'İLERİ'
          : 'UZMAN',
      icon: Icons.functions_rounded,
    );
  }

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    levelSpec,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('target_24');
    return ParkurLevelHub(
      gameId: 'target_24',
      progressPrefix: 'target_24',
      titleTr: 'Bir İşlem',
      titleEn: 'Target Number',
      taglineTr: 'Hedef sayıya ulaş • Tam sayılarla 4 işlem',
      taglineEn: 'Reach target number • 4 operations with whole numbers',
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
    // 1. Sıfıra bölme kontrolü
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

    // 2. Küsüratsız / Tam bölme kontrolü
    if (operation == Target24Operator.divide &&
        first.value.numerator % second.value.numerator != 0) {
      if (!fromHint) {
        _session.recordMistake();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .34),
        );
        _showMessage(
          _english
              ? 'Only exact whole division is allowed (remainder must be 0).'
              : 'Yalnızca kalansız tam bölünen sayılar bölünebilir.',
        );
      }
      setState(() {
        _selectedOperation = null;
        _firstOperandSignature = null;
      });
      return;
    }

    // 3. Çıkarma: Pozitif tam sayı kontrolü (küçükten büyük çıkarılamaz)
    if (operation == Target24Operator.subtract &&
        first.value.numerator <= second.value.numerator) {
      if (!fromHint) {
        _session.recordMistake();
        unawaited(
          _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .34),
        );
        _showMessage(
          _english
              ? 'Subtraction must yield a positive integer (cannot subtract larger from smaller).'
              : 'Küçük sayıdan büyük sayı çıkarılamaz (sonuç pozitif tam sayı olmalıdır).',
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
        _activeExpressions.single.value == _puzzle.target
            ? (_english
                  ? 'Target ${_puzzle.targetValue} is ready! Tap check.'
                  : 'Hedef ${_puzzle.targetValue} hazır! Hedefi kontrol et.')
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
          ? 'The result is ${_activeExpressions.single.value}, not ${_puzzle.targetValue}. Undo a step and rework it.'
          : 'Sonuç ${_activeExpressions.single.value}; hedef ${_puzzle.targetValue} değil. Bir adımı geri alıp yeniden dene.',
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

  void _showHowToPlay() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.help_outline_rounded, color: _accent, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _english ? 'HOW TO PLAY?' : 'NASIL OYNANIR?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _english
                    ? '• Reach the TARGET NUMBER using all 4 cards and arithmetic operations (+, −, ×, ÷).\n• Tap an operation, then choose two cards in sequence to combine them.\n• All calculations use whole positive numbers only; no fractions or decimals.\n• Division is only valid when numbers divide evenly (remainder 0).\n• Subtraction must yield a positive number.\n• Combine until exactly one card matching the target remains!'
                    : '• Verilen 4 sayıyı ve 4 işlemi (+, −, ×, ÷) kullanarak HEDEF SAYI\'ya ulaşın.\n• Önce bir işlem seçin, ardından sırayla iki karta dokunun.\n• İki kart birleşerek yeni bir tam sayı karta dönüşür.\n• Tüm işlemler kesinlikle pozitif tam sayılarla yapılır; kesir veya küsürat çıkmaz.\n• Bölme yalnızca kalansız tam bölünen sayılarda geçerlidir.\n• Çıkarma yalnızca pozitif sonuçlarda geçerlidir (küçükten büyük çıkmaz).\n• 3 işlem sonunda tek kartta hedef sayıyı elde edip onaylayın!',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  height: 1.5,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _english
                    ? 'Difficulty: ${_puzzle.difficultyTier}  •  Target: ${_puzzle.targetValue}'
                    : 'Zorluk: ${_puzzle.difficultyTier}  •  Hedef: ${_puzzle.targetValue}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
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
    final int zpEarned = CommonLevelScoreSession.isActive
        ? CommonLevelScoreSession.activePoints
        : math.max(0, 10 - _hints * 2);
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3B36),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E6B62)),
              ),
              child: Text(
                _english
                    ? '$stars stars  •  +$zpEarned ZP'
                    : '$stars yıldız  •  +$zpEarned ZP',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF64D2B7),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            Text(
              _english
                  ? 'Target ${_puzzle.targetValue} achieved with whole numbers!\n($score points)'
                  : 'Hedef ${_puzzle.targetValue} tam sayılarla başarıyla yakalandı!\n($score puan)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Roboto', color: Colors.white70),
            ),
          ],
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
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'TARGET NUMBER' : 'BİR İŞLEM',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
            Text(
              '${_english ? 'DEAL' : 'EL'} ${widget.level.number.toString().padLeft(3, '0')} · ${_english ? 'TARGET' : 'HEDEF'} ${_puzzle.targetValue}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            tooltip: _english ? 'How to play' : 'Nasıl oynanır',
            icon: const Icon(Icons.help_outline_rounded),
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
          maxContentWidth: 600,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Target24StatusBar(
                  stage: _puzzle.localStage,
                  targetValue: _puzzle.targetValue,
                  combinations: _completedCombinations,
                  moves: _moves,
                  hints: _hints,
                  bestScore: widget.previousBestScore,
                  english: _english,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E7E4)),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _english ? 'OPERATION' : 'İŞLEM SEÇİN',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _muted,
                              letterSpacing: .5,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              _instruction,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _selectedOperation != null
                                    ? _accent
                                    : _muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _OperationTray(
                        selected: _selectedOperation,
                        english: _english,
                        onSelect: _selectOperation,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: _NumberCardBoard(
                      expressions: _activeExpressions,
                      selectedSignature: _firstOperandSignature,
                      english: _english,
                      onTap: _selectExpression,
                      expressionKey: _expressionKey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    _SmallAction(
                      key: const ValueKey<String>('target24_undo'),
                      icon: Icons.undo_rounded,
                      label: _english ? 'UNDO' : 'GERİ AL',
                      onPressed: _undo.isEmpty ? null : _undoMove,
                    ),
                    const SizedBox(width: 6),
                    _SmallAction(
                      icon: Icons.lightbulb_outline_rounded,
                      label: _english ? 'HINT' : 'İPUCU',
                      onPressed: _hint,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey<String>('target24_check'),
                        onPressed: _activeExpressions.length == 1
                            ? _checkTarget
                            : null,
                        icon: const Icon(Icons.track_changes_rounded, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _english
                                ? 'CHECK TARGET'
                                : 'HEDEFİ KONTROL ET',
                            maxLines: 1,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFDDE5E1),
                          disabledForegroundColor: const Color(0xFF85938D),
                          minimumSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w900,
                            letterSpacing: .3,
                            fontSize: 12,
                          ),
                        ),
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

class _Target24StatusBar extends StatelessWidget {
  const _Target24StatusBar({
    required this.stage,
    required this.targetValue,
    required this.combinations,
    required this.moves,
    required this.hints,
    required this.bestScore,
    required this.english,
  });

  final int stage;
  final int targetValue;
  final int combinations;
  final int moves;
  final int hints;
  final int bestScore;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: _Target24PlayPageState._surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E6E3)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x06283640),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _Target24PlayPageState._ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.track_changes_rounded,
                  size: 14,
                  color: Color(0xFFE1C49E),
                ),
                const SizedBox(width: 5),
                Text(
                  '${english ? 'TARGET' : 'HEDEF'} $targetValue',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatPill(
            label: english ? 'STEP' : 'ADIM',
            value: '$combinations/3',
          ),
          const SizedBox(width: 6),
          _StatPill(
            label: english ? 'MOVES' : 'HAMLE',
            value: '$moves',
          ),
          const SizedBox(width: 6),
          _StatPill(
            label: english ? 'BEST' : 'EN İYİ',
            value: bestScore > 0 ? '$bestScore' : '—',
            highlight: bestScore > 0,
          ),
        ],
      ),
    ),
  );
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: highlight ? const Color(0xFFE8F3EE) : const Color(0xFFF3F5F4),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: highlight
                ? _Target24PlayPageState._accent
                : _Target24PlayPageState._muted,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: highlight
                ? _Target24PlayPageState._accent
                : _Target24PlayPageState._ink,
          ),
        ),
      ],
    ),
  );
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
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final Target24Operator operation in Target24Operator.values) ...<Widget>[
          if (operation != Target24Operator.values.first)
            const SizedBox(width: 8),
          Expanded(
            child: _OperatorButton(
              key: ValueKey<String>('target24_op_${operation.name}'),
              operation: operation,
              isSelected: selected == operation,
              onTap: () => onSelect(operation),
            ),
          ),
        ],
      ],
    );
  }
}

class _OperatorButton extends StatelessWidget {
  const _OperatorButton({
    super.key,
    required this.operation,
    required this.isSelected,
    required this.onTap,
  });

  final Target24Operator operation;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = isSelected
        ? _Target24PlayPageState._accent
        : const Color(0xFFF3F5F4);
    final Color fg = isSelected
        ? Colors.white
        : _Target24PlayPageState._ink;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? _Target24PlayPageState._accent
                  : const Color(0xFFE2E7E4),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            operation.symbol,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxW = constraints.maxWidth;
        final double maxH = constraints.maxHeight;

        // Kart sayısına göre esnek 2x2 veya tekli grid
        final int count = expressions.length;
        final int crossAxisCount = count <= 2 ? count : 2;

        return GridView.builder(
          key: const ValueKey<String>('target24_scroll'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: count == 1 ? 1.6 : (maxW / (maxH > 0 ? maxH : 300)).clamp(1.0, 1.4),
          ),
          itemCount: count,
          itemBuilder: (BuildContext context, int index) {
            final Target24Expression expr = expressions[index];
            final bool isSelected = expr.signature == selectedSignature;
            return _Target24BoardCard(
              key: ValueKey<String>(expressionKey(expr)),
              expression: expr,
              isSelected: isSelected,
              english: english,
              onTap: () => onTap(expr),
            );
          },
        );
      },
    );
  }
}

class _Target24BoardCard extends StatelessWidget {
  const _Target24BoardCard({
    super.key,
    required this.expression,
    required this.isSelected,
    required this.english,
    required this.onTap,
  });

  final Target24Expression expression;
  final bool isSelected;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isComposite = !expression.isCard;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE6F3EE)
                : _Target24PlayPageState._surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? _Target24PlayPageState._accent
                  : const Color(0xFFD6DDD9),
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isSelected
                    ? const Color(0x24247568)
                    : const Color(0x0C202824),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isComposite)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    expression.expressionText(english: english),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _Target24PlayPageState._muted,
                    ),
                  ),
                ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  expression.value.toString(),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: isComposite ? 34 : 38,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? _Target24PlayPageState._accent
                        : _Target24PlayPageState._ink,
                    letterSpacing: -0.5,
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
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _Target24PlayPageState._ink,
        disabledForegroundColor: const Color(0xFFACB7B2),
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: const BorderSide(color: Color(0xFFD6DDD9)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}
