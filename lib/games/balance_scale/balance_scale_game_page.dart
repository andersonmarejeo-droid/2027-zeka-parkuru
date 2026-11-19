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

  void _showLedgerClues() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
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
                  const Icon(Icons.menu_book_rounded, color: _brass, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _english ? 'LEDGER CLUES' : 'DEFTER İPUÇLARI',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFEAE7DF)),
              const SizedBox(height: 8),
              if (_puzzle.extraClues.isEmpty)
                Text(
                  _english
                      ? 'No extra clues for this level.'
                      : 'Bu bölüm için ek defter ipucu yok.',
                  style: const TextStyle(fontFamily: 'Roboto', color: _muted),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _puzzle.extraClues.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final BalanceGlobalClue clue = _puzzle.extraClues[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1EEE5),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: _brass,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              clue.text(english: _english),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                color: _ink,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _english ? 'HOW TO PLAY?' : 'NASIL OYNANIR?',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _english
                    ? '• Choose weights from the bottom tray and tap a left or right pan on a scale.\n• Each scale shows the target difference between its two pans.\n• Follow the ledger clues to determine which materials belong where.\n• When all scales are balanced, tap "CHECK"!'
                    : '• Alttaki tepsiden bir ağırlık seçin ve terazideki sol veya sağ kefeye dokunarak yerleştirin.\n• Her terazi, iki kefesi arasındaki hedef kütle farkını gösterir.\n• Hangi ağırlığın nereye geleceğini bulmak için defter ipuçlarını takip edin.\n• Tüm kefeler dolduğunda "KONTROL ET" butonuna dokunun!',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  height: 1.5,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
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
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
            Text(
              '${_english ? 'LEVEL' : 'BÖLÜM'} ${widget.level.number.toString().padLeft(3, '0')} · ${_puzzle.difficultyTier}',
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
          if (_puzzle.extraClues.isNotEmpty)
            IconButton(
              onPressed: _showLedgerClues,
              tooltip: _english ? 'Ledger clues' : 'Defter ipuçları',
              icon: const Icon(Icons.menu_book_rounded),
            ),
          IconButton(
            onPressed: _showHowToPlay,
            tooltip: _english ? 'How to play' : 'Nasıl oynanır',
            icon: const Icon(Icons.help_outline_rounded),
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
          maxContentWidth: 640,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _BalanceStatusBar(
                  level: widget.level.number,
                  stationCount: _puzzle.stationCount,
                  moves: _moves,
                  hints: _hints,
                  bestScore: widget.previousBestScore,
                  english: _english,
                  extraCluesCount: _puzzle.extraClues.length,
                  onOpenClues: _showLedgerClues,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          for (
                            int index = 0;
                            index < _puzzle.stationCount;
                            index++
                          ) ...<Widget>[
                            if (index > 0) const SizedBox(height: 6),
                            _BalanceStationCard(
                              station: _puzzle.stations[index],
                              placement: _placements[index],
                              valid:
                                  _placements[index] != null &&
                                  _puzzleStationMatches(
                                    index,
                                    _placements[index]!,
                                  ),
                              weights: _puzzle.weights,
                              stationIndex: index,
                              english: _english,
                              onPanTap: (bool leftSide) =>
                                  _placeWeight(index, leftSide),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
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
                            _english ? 'WEIGHT TRAY' : 'AĞIRLIK TEPSİSİ',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _muted,
                              letterSpacing: .5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hasSelectedWeight
                                  ? (_english
                                        ? 'Tap a pan to place'
                                        : 'Yerleştirmek için kefeye dokun')
                                  : (_english
                                        ? 'Select a weight'
                                        : 'Bir ağırlık seç'),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _hasSelectedWeight ? _accent : _muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _WeightTray(
                        weights: _puzzle.weights,
                        isPlaced: _weightIsPlaced,
                        selectedWeight: _selectedWeight,
                        english: _english,
                        onSelect: _selectWeight,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    _SmallAction(
                      key: const ValueKey<String>('balance_scale_undo'),
                      icon: Icons.undo_rounded,
                      label: _english ? 'UNDO' : 'GERİ AL',
                      onPressed: _undo.isEmpty ? null : _undoMove,
                    ),
                    const SizedBox(width: 8),
                    _SmallAction(
                      icon: Icons.lightbulb_outline_rounded,
                      label: _english ? 'HINT' : 'İPUCU',
                      onPressed: _hint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey<String>('balance_scale_check'),
                        onPressed: _checkBalance,
                        icon: const Icon(Icons.fact_check_outlined, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _english ? 'CHECK' : 'KONTROL ET',
                            maxLines: 1,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w900,
                            letterSpacing: .3,
                            fontSize: 13,
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
}

class _BalanceStatusBar extends StatelessWidget {
  const _BalanceStatusBar({
    required this.level,
    required this.stationCount,
    required this.moves,
    required this.hints,
    required this.bestScore,
    required this.english,
    required this.extraCluesCount,
    required this.onOpenClues,
  });

  final int level;
  final int stationCount;
  final int moves;
  final int hints;
  final int bestScore;
  final bool english;
  final int extraCluesCount;
  final VoidCallback onOpenClues;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: _BalanceScalePlayPageState._surface,
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
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _BalanceScalePlayPageState._ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.balance_rounded,
                  size: 13,
                  color: Color(0xFFE8C98E),
                ),
                const SizedBox(width: 5),
                Text(
                  '${english ? 'SCALE' : 'TERAZİ'} $level',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (extraCluesCount > 0) ...<Widget>[
            InkWell(
              onTap: onOpenClues,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EEE4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 12,
                      color: _BalanceScalePlayPageState._brass,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${english ? 'CLUES' : 'İPUCU'} $extraCluesCount',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _BalanceScalePlayPageState._brass,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          _CompactBalanceMetric(
            icon: Icons.layers_outlined,
            label: english ? 'PANS' : 'KEFE',
            value: '$stationCount',
          ),
          const SizedBox(width: 6),
          _CompactBalanceMetric(
            icon: Icons.touch_app_outlined,
            label: english ? 'MOVE' : 'HAMLE',
            value: '$moves',
          ),
          if (bestScore > 0) ...<Widget>[
            const SizedBox(width: 6),
            _CompactBalanceMetric(
              icon: Icons.emoji_events_outlined,
              label: english ? 'BEST' : 'REKOR',
              value: '$bestScore',
              color: _BalanceScalePlayPageState._brass,
            ),
          ],
        ],
      ),
    ),
  );
}

class _CompactBalanceMetric extends StatelessWidget {
  const _CompactBalanceMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color textColor = color ?? _BalanceScalePlayPageState._ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: _BalanceScalePlayPageState._muted),
          const SizedBox(width: 4),
          Text(
            '$label $value',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
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
    label: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
    style: TextButton.styleFrom(
      foregroundColor: _BalanceScalePlayPageState._accent,
      minimumSize: const Size(78, GameInputPolicy.minimumTargetSize),
      padding: const EdgeInsets.symmetric(horizontal: 5),
    ),
  );
}
