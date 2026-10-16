import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/studio_visuals.dart';
import '../../widgets/realistic_game_object.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'balance_scale_puzzle.dart';

class BalanceScaleGamePage extends StatelessWidget {
  const BalanceScaleGamePage({
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
    GameContentPolicy.nativeStages('balance_scale'),
    (int index) {
      final int stage = (index % 10) + 1;
      return ParkurLevelSpec(
        number: index + 1,
        titleTr: 'Terazi ${'${index + 1}'.padLeft(3, '0')}',
        titleEn: 'Balance ${'${index + 1}'.padLeft(3, '0')}',
        subtitleTr: 'Kütleleri ve ipuçlarını eşleştir',
        subtitleEn: 'Match the weights and layered clues',
        difficulty: stage <= 6
            ? 'USTALAŞMA'
            : stage <= 8
            ? 'İLERİ'
            : 'UZMAN',
        icon: Icons.balance_rounded,
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('balance_scale');
    return ParkurLevelHub(
      gameId: 'balance_scale',
      progressPrefix: 'balance_scale',
      titleTr: 'Ağırlık Dengesi',
      titleEn: 'Balance Scale',
      taglineTr: 'Kefeleri dengele, tüm ipuçlarını çöz',
      taglineEn: 'Balance every pan and solve the layered clues',
      accent: skin.accent,
      icon: Icons.balance_rounded,
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
          ) => BalanceScalePlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class BalanceScalePlayPage extends StatefulWidget {
  const BalanceScalePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<BalanceScalePlayPage> createState() => _BalanceScalePlayPageState();
}

class _BalanceScalePlayPageState extends State<BalanceScalePlayPage> {
  static const Color _ink = StudioVisuals.ink;
  static const Color _muted = StudioVisuals.muted;
  static const Color _canvas = StudioVisuals.canvas;
  static const Color _surface = StudioVisuals.surface;
  static const Color _accent = Color(0xFF866139);
  static const Color _brass = Color(0xFFB58A58);
  static const Color _success = Color(0xFF548775);
  static const Color _pending = Color(0xFFB98957);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  final List<List<BalancePlacement?>> _undo = <List<BalancePlacement?>>[];
  late final BalanceScalePuzzle _puzzle;
  late final StudioGameSession _session;
  late List<BalancePlacement?> _placements;
  bool _english = false;
  bool _finished = false;
  int? _selectedWeight;
  int _moves = 0;
  int _hints = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = BalanceScalePuzzle.forLevel(widget.level.contentIndex);
    _placements = List<BalancePlacement?>.filled(_puzzle.stationCount, null);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  bool get _boardFull => _placements.every(
    (BalancePlacement? pair) =>
        pair != null && pair.leftWeight >= 0 && pair.rightWeight >= 0,
  );

  bool get _hasSelectedWeight => _selectedWeight != null;

  bool _weightIsPlaced(int weightId) => _placements.any(
    (BalancePlacement? pair) =>
        pair != null &&
        (pair.leftWeight == weightId || pair.rightWeight == weightId),
  );

  void _selectWeight(int weightId) {
    if (_finished) return;
    setState(
      () => _selectedWeight = _selectedWeight == weightId ? null : weightId,
    );
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .24),
    );
  }

  void _placeWeight(int station, bool leftSide) {
    if (_finished || station < 0 || station >= _placements.length) return;
    final BalancePlacement? oldPair = _placements[station];
    final int? oldWeight = oldPair == null
        ? null
        : leftSide
        ? oldPair.leftWeight
        : oldPair.rightWeight;
    final int? selected = _selectedWeight;

    if (selected == null) {
      if (oldWeight == null) return;
      setState(() {
        _undo.add(List<BalancePlacement?>.from(_placements));
        _placements[station] = _withoutSide(oldPair!, leftSide);
        _selectedWeight = oldWeight;
        _moves++;
      });
      _session.recordAccepted();
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .3),
      );
      return;
    }

    if (oldWeight == selected) {
      setState(() => _selectedWeight = null);
      return;
    }

    setState(() {
      _undo.add(List<BalancePlacement?>.from(_placements));
      for (int index = 0; index < _placements.length; index++) {
        final BalancePlacement? pair = _placements[index];
        if (pair == null) continue;
        if (pair.leftWeight == selected) {
          _placements[index] = _withoutSide(pair, true);
        } else if (pair.rightWeight == selected) {
          _placements[index] = _withoutSide(pair, false);
        }
      }
      final BalancePlacement? target = _placements[station];
      final int? replaced = target == null
          ? null
          : leftSide
          ? target.leftWeight
          : target.rightWeight;
      _placements[station] = _withSide(target, leftSide, selected);
      _selectedWeight = replaced;
      _moves++;
    });
    _session.recordAccepted();
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .34));
  }

  BalancePlacement? _withoutSide(BalancePlacement pair, bool leftSide) {
    if (leftSide) {
      return pair.rightWeight < 0
          ? null
          : BalancePlacement(leftWeight: -1, rightWeight: pair.rightWeight);
    }
    return pair.leftWeight < 0
        ? null
        : BalancePlacement(leftWeight: pair.leftWeight, rightWeight: -1);
  }

  BalancePlacement _withSide(
    BalancePlacement? pair,
    bool leftSide,
    int weightId,
  ) {
    return leftSide
        ? BalancePlacement(
            leftWeight: weightId,
            rightWeight: pair?.rightWeight ?? -1,
          )
        : BalancePlacement(
            leftWeight: pair?.leftWeight ?? -1,
            rightWeight: weightId,
          );
  }

  void _undoMove() {
    if (_finished || _undo.isEmpty) return;
    setState(() {
      _placements = _undo.removeLast();
      _selectedWeight = null;
      _moves++;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .3));
  }

  void _hint() {
    if (_finished || !_session.canUseHint) return;
    for (int station = 0; station < _puzzle.stationCount; station++) {
      final BalancePlacement? current = _placements[station];
      final BalancePlacement answer = _puzzle.solution[station];
      if (current?.leftWeight != answer.leftWeight) {
        _selectedWeight = answer.leftWeight;
        _placeWeight(station, true);
        _chargeHint();
        return;
      }
      if (current?.rightWeight != answer.rightWeight) {
        _selectedWeight = answer.rightWeight;
        _placeWeight(station, false);
        _chargeHint();
        return;
      }
    }
  }

  void _chargeHint() {
    if (!_session.canUseHint) return;
    setState(() => _hints++);
    _session.useHint(pointCost: 120);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .35));
    _showMessage(
      _english
          ? 'One weight has been placed correctly.'
          : 'Bir ağırlık doğru kefeye yerleştirildi.',
    );
  }

  List<BalancePlacement> get _completePlacements => _placements
      .map(
        (BalancePlacement? pair) =>
            pair ?? const BalancePlacement(leftWeight: -1, rightWeight: -1),
      )
      .toList(growable: false);

  void _reset() {
    if (_finished) return;
    setState(() {
      _placements = List<BalancePlacement?>.filled(_puzzle.stationCount, null);
      _selectedWeight = null;
      _undo.clear();
      _moves = 0;
      _hints = 0;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .3));
  }

  Future<void> _checkBalance() async {
    if (_finished) return;
    if (_boardFull && _puzzle.isSolved(_completePlacements)) {
      await _complete();
      return;
    }
    _session.recordMistake();
    final int mismatchedStations =
        List<int>.generate(_puzzle.stationCount, (int index) => index).where((
          int index,
        ) {
          final BalancePlacement? pair = _placements[index];
          return pair == null ||
              pair.leftWeight < 0 ||
              pair.rightWeight < 0 ||
              !_puzzleStationMatches(index, pair);
        }).length;
    final int pendingClues = _boardFull
        ? _puzzle.extraClues
              .where(
                (BalanceGlobalClue clue) =>
                    !clue.matches(_puzzle.weights, _completePlacements),
              )
              .length
        : _puzzle.extraClues.length;
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .34));
    _showMessage(
      _english
          ? '$mismatchedStations balance${mismatchedStations == 1 ? '' : 's'} and $pendingClues global clue${pendingClues == 1 ? '' : 's'} still need attention.'
          : '$mismatchedStations terazi ve $pendingClues ortak ipucu hâlâ uyuşmuyor.',
    );
  }

  bool _puzzleStationMatches(int index, BalancePlacement pair) {
    if (pair.leftWeight < 0 || pair.rightWeight < 0) return false;
    final BalanceWeight left = _puzzle.weights[pair.leftWeight];
    final BalanceWeight right = _puzzle.weights[pair.rightWeight];
    final BalanceStation station = _puzzle.stations[index];
    final bool sameMaterial = left.material == right.material;
    return left.mass - right.mass == station.leftMinusRight &&
        sameMaterial == (station.pairRule == BalancePairRule.sameMaterial);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
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
      1900 - _moves * 8 - _hints * 180 - _session.mistakes * 70,
    );
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < BalanceScaleGamePage.totalCases
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
        icon: const Icon(Icons.balance_rounded, color: Color(0xFFE8C99B)),
        title: Text(
          _english ? 'BALANCE ACHIEVED' : 'DENGE SAĞLANDI',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _english
              ? '$stars stars  •  $score points\nEvery weight and clue is aligned.'
              : '$stars yıldız  •  $score puan\nTüm ağırlıklar ve ipuçları eşleşti.',
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
              widget.level.number < BalanceScaleGamePage.totalCases
                  ? (_english ? 'NEXT LEVEL' : 'SONRAKİ BÖLÜM')
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
              _english ? 'BALANCE SCALE' : 'AĞIRLIK DENGESİ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            Text(
              '${_english ? 'LEVEL' : 'BÖLÜM'} ${widget.level.number.toString().padLeft(3, '0')} · ${_puzzle.difficultyTier}',
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
                ? 'Place a correct weight'
                : 'Doğru bir ağırlık yerleştir',
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            onPressed: _reset,
            tooltip: _english ? 'Reset board' : 'Tahtayı sıfırla',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 680,
          child: ListView(
            key: const ValueKey<String>('balance_scale_scroll'),
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
            children: <Widget>[
              _BalanceHero(
                level: widget.level.number,
                stationCount: _puzzle.stationCount,
                moveCount: _moves,
                hintCount: _hints,
                bestScore: widget.previousBestScore,
                stage: _puzzle.localStage,
                english: _english,
              ),
              const SizedBox(height: 13),
              _SectionHeading(
                title: _english ? 'BALANCE READINGS' : 'TERAZİ ÖLÇÜMLERİ',
                detail: _english
                    ? 'Match the indicated difference and material type.'
                    : 'Belirtilen kütle farkını ve malzeme türünü eşleştir.',
              ),
              const SizedBox(height: 7),
              for (
                int index = 0;
                index < _puzzle.stationCount;
                index++
              ) ...<Widget>[
                _BalanceStationCard(
                  station: _puzzle.stations[index],
                  placement: _placements[index],
                  valid:
                      _placements[index] != null &&
                      _puzzleStationMatches(index, _placements[index]!),
                  weights: _puzzle.weights,
                  stationIndex: index,
                  english: _english,
                  onPanTap: (bool leftSide) => _placeWeight(index, leftSide),
                ),
                if (index < _puzzle.stationCount - 1) const SizedBox(height: 7),
              ],
              if (_puzzle.extraClues.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                _SectionHeading(
                  title: _english ? 'LEDGER CLUES' : 'DEFTER İPUÇLARI',
                  detail: _english
                      ? 'Use these clues across the whole set of balances.'
                      : 'Bu ipuçlarını tüm teraziler birlikteyken değerlendir.',
                ),
                const SizedBox(height: 7),
                _GlobalClueBoard(
                  clues: _puzzle.extraClues,
                  weights: _puzzle.weights,
                  placements: _completePlacements,
                  completed: _boardFull,
                  english: _english,
                ),
              ],
              const SizedBox(height: 14),
              _SectionHeading(
                title: _english ? 'WEIGHT TRAY' : 'AĞIRLIK TEPSİSİ',
                detail: _english
                    ? _hasSelectedWeight
                          ? 'Now choose a left or right pan.'
                          : 'Select a piece, then tap the pan where it belongs.'
                    : _hasSelectedWeight
                    ? 'Şimdi sol veya sağ kefeyi seç.'
                    : 'Bir ağırlık seç, ardından ait olduğu kefeye dokun.',
              ),
              const SizedBox(height: 7),
              _WeightTray(
                weights: _puzzle.weights,
                isPlaced: _weightIsPlaced,
                selectedWeight: _selectedWeight,
                english: _english,
                onSelect: _selectWeight,
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: <Widget>[
                  _SmallAction(
                    key: const ValueKey<String>('balance_scale_undo'),
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
              const SizedBox(height: 4),
              FilledButton.icon(
                key: const ValueKey<String>('balance_scale_check'),
                onPressed: _checkBalance,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(
                  _english ? 'CHECK THE BALANCE' : 'DENGEYİ KONTROL ET',
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
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                    letterSpacing: .35,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Center(
                child: Text(
                  _english
                      ? '${_puzzle.stationCount} precision balances · ${_puzzle.difficultyTier}'
                      : '${_puzzle.stationCount} hassas terazi · ${_puzzle.difficultyTier}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
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

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.level,
    required this.stationCount,
    required this.moveCount,
    required this.hintCount,
    required this.bestScore,
    required this.stage,
    required this.english,
  });

  final int level;
  final int stationCount;
  final int moveCount;
  final int hintCount;
  final int bestScore;
  final int stage;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _BalanceScalePlayPageState._surface,
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
          width: 92,
          height: 76,
          child: CustomPaint(painter: _BalanceScalePainter(stage: stage)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'CALIBRATION ROOM' : 'HASSASİYET ATÖLYESİ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _BalanceScalePlayPageState._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                english ? 'Every gram matters.' : 'Her gramın önemi var.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: _BalanceScalePlayPageState._ink,
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
                    text: '${english ? 'SCALES' : 'TERAZİ'} $stationCount',
                  ),
                  _MetricPill(
                    text: '${english ? 'MOVES' : 'HAMLE'} $moveCount',
                  ),
                  _MetricPill(
                    text: '${english ? 'HINTS' : 'İPUCU'} $hintCount',
                  ),
                ],
              ),
              if (bestScore > 0) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  '${english ? 'BEST' : 'REKOR'} $bestScore · ${english ? 'LEVEL' : 'BÖLÜM'} $level',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _BalanceScalePlayPageState._success,
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

class _BalanceScalePainter extends CustomPainter {
  const _BalanceScalePainter({required this.stage});

  final int stage;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect plate = RRect.fromRectAndRadius(
      bounds.deflate(2),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFAFCFB), Color(0xFFE8EFEC)],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFD3DEDA),
    );
    final double centerX = size.width / 2;
    final double beamY = size.height * .36;
    final Paint metal = Paint()
      ..color = _BalanceScalePlayPageState._accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, size.height * .29),
      Offset(centerX, size.height * .77),
      metal,
    );
    canvas.drawLine(
      Offset(centerX - size.width * .31, beamY),
      Offset(centerX + size.width * .31, beamY),
      metal,
    );
    final Paint fineLine = Paint()
      ..color = const Color(0xFF9AAEAA)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final double direction in <double>[-1, 1]) {
      final double panX = centerX + size.width * .31 * direction;
      canvas.drawLine(
        Offset(panX, beamY + 2),
        Offset(panX, size.height * .58),
        fineLine,
      );
      canvas.drawLine(
        Offset(panX - 11, size.height * .59),
        Offset(panX + 11, size.height * .59),
        metal..strokeWidth = 2.4,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(panX, size.height * .575),
          width: 22,
          height: 11,
        ),
        0,
        math.pi,
        false,
        Paint()
          ..color = _BalanceScalePlayPageState._brass
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.3,
      );
    }
    final Path base = Path()
      ..moveTo(centerX - 16, size.height * .8)
      ..lineTo(centerX, size.height * .69)
      ..lineTo(centerX + 16, size.height * .8)
      ..close();
    canvas.drawPath(base, Paint()..color = const Color(0xFFD5E0DC));
    canvas.drawLine(
      Offset(centerX - 23, size.height * .81),
      Offset(centerX + 23, size.height * .81),
      metal..strokeWidth = 3,
    );
    final double marker = 3 + stage % 4;
    for (int index = 0; index < marker; index++) {
      canvas.drawCircle(
        Offset(size.width * .2 + index * 7, size.height * .91),
        1.5,
        Paint()
          ..color = _BalanceScalePlayPageState._brass.withValues(alpha: .55),
      );
    }
  }

  @override
  bool shouldRepaint(_BalanceScalePainter oldDelegate) =>
      stage != oldDelegate.stage;
}

class _BalanceStationCard extends StatelessWidget {
  const _BalanceStationCard({
    required this.station,
    required this.placement,
    required this.valid,
    required this.weights,
    required this.stationIndex,
    required this.english,
    required this.onPanTap,
  });

  final BalanceStation station;
  final BalancePlacement? placement;
  final bool valid;
  final List<BalanceWeight> weights;
  final int stationIndex;
  final bool english;
  final ValueChanged<bool> onPanTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: _BalanceScalePlayPageState._surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: valid ? const Color(0xFFBFD5C9) : const Color(0xFFE1E6E3),
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
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  BalanceScalePuzzle.stationLetters[stationIndex],
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _BalanceScalePlayPageState._ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  station.text(english: english),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _BalanceScalePlayPageState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                valid ? Icons.check_circle_rounded : Icons.tune_rounded,
                size: 17,
                color: valid
                    ? _BalanceScalePlayPageState._success
                    : _BalanceScalePlayPageState._pending,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Expanded(
                child: _PanTarget(
                  key: ValueKey<String>(
                    'balance_scale_pan_${stationIndex}_left',
                  ),
                  stationIndex: stationIndex,
                  leftSide: true,
                  weightId: placement?.leftWeight ?? -1,
                  weight: _weightFor(placement?.leftWeight),
                  english: english,
                  onTap: () => onPanTap(true),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _PanTarget(
                  key: ValueKey<String>(
                    'balance_scale_pan_${stationIndex}_right',
                  ),
                  stationIndex: stationIndex,
                  leftSide: false,
                  weightId: placement?.rightWeight ?? -1,
                  weight: _weightFor(placement?.rightWeight),
                  english: english,
                  onTap: () => onPanTap(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BalanceWeight? _weightFor(int? id) =>
      id == null || id < 0 ? null : weights[id];
}

class _PanTarget extends StatelessWidget {
  const _PanTarget({
    super.key,
    required this.stationIndex,
    required this.leftSide,
    required this.weightId,
    required this.weight,
    required this.english,
    required this.onTap,
  });

  final int stationIndex;
  final bool leftSide;
  final int weightId;
  final BalanceWeight? weight;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool filled = weightId >= 0;
    return Semantics(
      button: true,
      label:
          '${english ? 'Balance' : 'Terazi'} ${BalanceScalePuzzle.stationLetters[stationIndex]}, ${leftSide ? (english ? 'left' : 'sol') : (english ? 'right' : 'sağ')} ${english ? 'pan' : 'kefe'}${filled ? ', ${weight?.mass} g' : ''}',
      child: Material(
        color: filled ? const Color(0xFFF0F4F2) : const Color(0xFFF8F9F7),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: GameInputPolicy.minimumTargetSize + 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  leftSide ? Icons.west_rounded : Icons.east_rounded,
                  size: 15,
                  color: _BalanceScalePlayPageState._accent,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    filled
                        ? '${weight?.mass} g'
                        : (leftSide
                              ? (english ? 'LEFT PAN' : 'SOL KEFE')
                              : (english ? 'RIGHT PAN' : 'SAĞ KEFE')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _BalanceScalePlayPageState._ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .25,
                    ),
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

class _GlobalClueBoard extends StatelessWidget {
  const _GlobalClueBoard({
    required this.clues,
    required this.weights,
    required this.placements,
    required this.completed,
    required this.english,
  });

  final List<BalanceGlobalClue> clues;
  final List<BalanceWeight> weights;
  final List<BalancePlacement> placements;
  final bool completed;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAF8),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1E6E3)),
    ),
    child: Column(
      children: <Widget>[
        for (int index = 0; index < clues.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 5),
          _GlobalClueRow(
            clue: clues[index],
            weights: weights,
            placements: placements,
            completed: completed,
            english: english,
          ),
        ],
      ],
    ),
  );
}

class _GlobalClueRow extends StatelessWidget {
  const _GlobalClueRow({
    required this.clue,
    required this.weights,
    required this.placements,
    required this.completed,
    required this.english,
  });

  final BalanceGlobalClue clue;
  final List<BalanceWeight> weights;
  final List<BalancePlacement> placements;
  final bool completed;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final bool valid = completed && clue.matches(weights, placements);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            valid ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
            size: 16,
            color: valid
                ? _BalanceScalePlayPageState._success
                : _BalanceScalePlayPageState._brass,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              clue.text(english: english),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: _BalanceScalePlayPageState._ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightTray extends StatelessWidget {
  const _WeightTray({
    required this.weights,
    required this.isPlaced,
    required this.selectedWeight,
    required this.english,
    required this.onSelect,
  });

  final List<BalanceWeight> weights;
  final bool Function(int weightId) isPlaced;
  final int? selectedWeight;
  final bool english;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: _BalanceScalePlayPageState._surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1E6E3)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x08283640),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final BalanceWeight weight in weights)
          _WeightChip(
            key: ValueKey<String>('balance_scale_weight_${weight.id}'),
            weight: weight,
            placed: isPlaced(weight.id),
            selected: selectedWeight == weight.id,
            english: english,
            onTap: () => onSelect(weight.id),
          ),
      ],
    ),
  );
}

class _WeightChip extends StatelessWidget {
  const _WeightChip({
    super.key,
    required this.weight,
    required this.placed,
    required this.selected,
    required this.english,
    required this.onTap,
  });

  final BalanceWeight weight;
  final bool placed;
  final bool selected;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color materialColor = switch (weight.material) {
      BalanceMaterial.brass => const Color(0xFFB58A58),
      BalanceMaterial.porcelain => const Color(0xFF7899A2),
      BalanceMaterial.slate => const Color(0xFF66727E),
    };
    final String material = switch (weight.material) {
      BalanceMaterial.brass => english ? 'BRASS' : 'PİRİNÇ',
      BalanceMaterial.porcelain => english ? 'PORCELAIN' : 'PORS.',
      BalanceMaterial.slate => english ? 'SLATE' : 'TAŞ',
    };
    return Semantics(
      button: true,
      selected: selected,
      label:
          '$material, ${weight.mass} g${placed ? (english ? ', placed' : ', yerleştirildi') : ''}',
      child: Material(
        color: selected
            ? const Color(0xFFE9F1EE)
            : placed
            ? const Color(0xFFF4F6F4)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 68,
            height: GameInputPolicy.minimumTargetSize + 12,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? _BalanceScalePlayPageState._accent
                    : const Color(0xFFE3E8E5),
                width: selected ? 1.6 : .8,
              ),
            ),
            child: Opacity(
              opacity: placed && !selected ? .42 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: RealisticGameObject(
                          sheet: RealisticObjectSheet.weights,
                          index: switch (weight.material) {
                            BalanceMaterial.brass => 0,
                            BalanceMaterial.slate => 1,
                            BalanceMaterial.porcelain => 2,
                          },
                          borderRadius: 6,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          material,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: materialColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${weight.mass} g',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _BalanceScalePlayPageState._ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
          color: _BalanceScalePlayPageState._ink,
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
          color: _BalanceScalePlayPageState._muted,
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
        color: _BalanceScalePlayPageState._muted,
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
      foregroundColor: _BalanceScalePlayPageState._accent,
      minimumSize: const Size(78, GameInputPolicy.minimumTargetSize),
      padding: const EdgeInsets.symmetric(horizontal: 5),
    ),
  );
}
