import 'dart:async';

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
import 'dice_bluff_engine.dart';
import 'dice_bluff_scenario.dart';

class DiceBluffArenaGamePage extends StatelessWidget {
  const DiceBluffArenaGamePage({super.key});
  static const int totalMatches = DiceBluffScenario.campaignLevels;
  static const int totalStars = totalMatches * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalMatches,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Zar Masası ${level.toString().padLeft(2, '0')}',
        titleEn: 'Dice Table ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Zarlarını gör; iddiayı yükselt ya da meydan oku.',
          <= 6 => 'Rakibin olasılık aralığını hesapla.',
          7 || 8 => 'İleri: yüz ve adet sırasını dikkatli yükselt.',
          9 || 10 => 'Uzman: yıldız yüzü diğer zarları tamamlar.',
          <= 16 => 'Usta: temkinli, okur ve cesur rakipleri çöz.',
          _ => 'Final: yedi zar, gizli el ve yüksek eşikle oyna.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Read your dice; raise the claim or challenge.',
          <= 6 => 'Estimate the opponent’s probability range.',
          7 || 8 => 'Advanced: respect count-and-face bid order.',
          9 || 10 => 'Expert: the star face counts as a wild.',
          <= 16 => 'Master measured, observant and daring opponents.',
          _ => 'Final: seven dice, hidden hands and high stakes.',
        },
        difficulty: switch (level) {
          <= 3 => 'ISINMA',
          <= 6 => 'OLASILIK',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.casino_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'dice_bluff_arena',
      progressPrefix: 'dice_bluff_arena',
      titleTr: 'Zar ve Hançer',
      titleEn: 'Dice & Dagger',
      taglineTr: 'Olasılığı oku • Blöfü yakala',
      taglineEn: 'Read the odds • Call the bluff',
      accent: skin.accent,
      icon: Icons.casino_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => DiceBluffPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class DiceBluffPlayPage extends StatefulWidget {
  const DiceBluffPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<DiceBluffPlayPage> createState() => _DiceBluffPlayPageState();
}

class _DiceBluffPlayPageState extends State<DiceBluffPlayPage> {
  static const Color _accent = Color(0xFFB8784E);
  static const Color _ink = Color(0xFF28343F);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late DiceBluffScenario _scenario;
  late DiceBluffEngine _engine;
  late StudioGameSession _session;
  DiceBluffMode _mode = DiceBluffMode.versusComputer;
  int? _practiceIndex;
  int _bidCount = 1;
  int _bidFace = 1;
  bool _ready = false;
  bool _started = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareMatch());
  }

  Future<void> _prepareMatch() async {
    DiceBluffScenario scenario = DiceBluffScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String visitKey =
          'dice_bluff_arena_level_${widget.level.number}_visits';
      final int visits = await prefs.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int previous =
            await prefs.getInt('dice_bluff_arena_practice_index') ?? 0;
        _practiceIndex = previous % DiceBluffScenario.practiceHands + 1;
        await prefs.setInt('dice_bluff_arena_practice_index', _practiceIndex!);
        scenario = DiceBluffScenario.forPractice(_practiceIndex!);
      }
      await prefs.setInt(visitKey, visits + 1);
    } catch (_) {
      // Authored dice remain ready if local preferences cannot be read.
    }
    if (!mounted) return;
    _scenario = scenario;
    _resetEngine();
    setState(() {
      _english = context.l10n.isEnglish;
      _feedback = _english
          ? 'Choose a duel. Dice appear only during their private reveal.'
          : 'Düello türünü seç. Zarlar yalnızca özel gösterimde açılır.';
      _ready = true;
    });
  }

  void _resetEngine() {
    _engine = DiceBluffEngine(
      scenario: _scenario,
      mode: _mode,
      firstBidder: widget.level.number.isEven ? 1 : 0,
    );
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
  }

  void _selectMode(DiceBluffMode mode) {
    if (!_ready || _started || _mode == mode) return;
    setState(() {
      _mode = mode;
      _resetEngine();
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .14));
  }

  void _startMatch() {
    if (!_ready || _started) return;
    setState(() {
      _started = true;
      _feedback = _english
          ? 'Pass the device. Memorize your private dice; hands stay concealed after the roll.'
          : 'Cihazı sırayla ver. Zarlarını aklında tut; gösterimden sonra eller kapanır.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .16));
  }

  void _openRoll() {
    if (!_engine.openPrivateRoll()) return;
    setState(() {
      _feedback = _english
          ? 'Read your hand quietly. Remember the star die is wild.'
          : 'Zarlarını sessizce oku. Yıldız zarın joker olduğunu unutma.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _hideRollAndPass() {
    if (!_engine.hideRollAndPass()) return;
    setState(() {
      _feedback = _engine.phase == DiceBluffPhase.bidding
          ? (_english
                ? 'Hands are hidden. Read the table and make a legal claim.'
                : 'Eller kapalı. Masayı oku ve geçerli bir iddia ver.')
          : (_english
                ? 'Dice hidden. Pass the device to the other player.'
                : 'Zarlar kapandı. Cihazı diğer oyuncuya ver.');
      _bidCount = _engine.currentBid?.count ?? 1;
      _bidFace = _engine.currentBid?.face ?? 1;
    });
    _scheduleComputerTurn();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .14));
  }

  void _adjustBidCount(int delta) {
    setState(() {
      _bidCount = (_bidCount + delta).clamp(1, _scenario.totalDice);
    });
  }

  void _selectFace(int face) {
    setState(() => _bidFace = face);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .1));
  }

  void _raise() {
    final int actor = _engine.activePlayer;
    final DiceBluffAction action = _engine.raiseBid(
      player: actor,
      count: _bidCount,
      face: _bidFace,
    );
    if (action == DiceBluffAction.invalid) {
      setState(
        () => _feedback = _english
            ? 'Raise the count, or keep it and choose a higher face.'
            : 'Adedi yükselt ya da aynı adette daha yüksek bir yüz seç.',
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .14));
      return;
    }
    final DiceBluffBid bid = _engine.currentBid!;
    setState(() {
      _bidCount = bid.count;
      _bidFace = bid.face;
      _feedback = _english
          ? '${_playerLabel(actor)} claims at least ${bid.count} ${_faceName(bid.face)}.'
          : '${_playerLabel(actor)} en az ${bid.count} ${_faceName(bid.face)} olduğunu söylüyor.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .17));
    _audio.hapticLight();
    _scheduleComputerTurn();
  }

  void _challenge() {
    final int actor = _engine.activePlayer;
    final DiceBluffAction action = _engine.challenge(player: actor);
    if (action != DiceBluffAction.challenged) return;
    final DiceBluffRoundResult result = _engine.result!;
    setState(() {
      _feedback = result.challengeWasCorrect
          ? (_english
                ? 'Challenge upheld · the claim was false.'
                : 'Meydan okuma doğru · iddia blöftü.')
          : (_english
                ? 'The claim stood · challenger loses a die.'
                : 'İddia doğru çıktı · meydan okuyan zar kaybetti.');
    });
    unawaited(
      _audioProfile.play(
        _audio,
        GameAudioEvent.levelComplete,
        gain: .18,
        levelNumber: widget.level.number,
      ),
    );
    _audio.hapticMedium();
  }

  void _scheduleComputerTurn() {
    if (!_engine.isComputerTurn || _engine.isFinished) return;
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (!mounted || !_engine.isComputerTurn || _engine.isFinished) return;
      final DiceBluffAction action = _engine.playComputerTurn();
      final DiceBluffBid? bid = _engine.currentBid;
      setState(() {
        if (action == DiceBluffAction.challenged) {
          final DiceBluffRoundResult result = _engine.result!;
          _feedback = result.challengeWasCorrect
              ? (_english
                    ? 'The computer called your bluff.'
                    : 'Bilgisayar blöfünü yakaladı.')
              : (_english
                    ? 'The computer challenged a true claim.'
                    : 'Bilgisayar doğru iddiaya meydan okudu.');
        } else if (bid != null) {
          _bidCount = bid.count;
          _bidFace = bid.face;
          _feedback = _english
              ? 'Computer raises to at least ${bid.count} ${_faceName(bid.face)}.'
              : 'Bilgisayar iddiayı en az ${bid.count} ${_faceName(bid.face)} seviyesine çıkardı.';
        }
      });
      if (action != DiceBluffAction.invalid) {
        unawaited(
          _audioProfile.play(
            _audio,
            action == DiceBluffAction.challenged
                ? GameAudioEvent.rejected
                : GameAudioEvent.accepted,
            gain: .16,
          ),
        );
      }
    });
  }

  String _faceName(int face) =>
      _scenario.wildFace == face ? (_english ? 'STAR' : 'YILDIZ') : '$face';

  String _playerLabel(int player) {
    if (_mode == DiceBluffMode.versusComputer) {
      return player == 0
          ? (_english ? 'YOU' : 'SEN')
          : (_english ? 'COMPUTER' : 'BİLGİSAYAR');
    }
    return '${_english ? 'PLAYER' : 'OYUNCU'} ${player + 1}';
  }

  Future<void> _finishHand() async {
    if (_finished) return;
    final DiceBluffRoundResult? result = _engine.result;
    if (result == null) return;
    _finished = true;
    final bool firstSeatWon = result.winningPlayer == 0;
    final int stars = firstSeatWon ? 3 : 1;
    _session.recordAccepted(points: firstSeatWon ? 100 : 45);
    _session.complete(
      stars: stars,
      action: widget.level.number < DiceBluffArenaGamePage.totalMatches
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    final String winnerTr = _mode == DiceBluffMode.versusComputer
        ? (firstSeatWon ? 'Sen kazandın.' : 'Bilgisayar kazandı.')
        : 'Oyuncu ${result.winningPlayer + 1} eli aldı.';
    final String winnerEn = _mode == DiceBluffMode.versusComputer
        ? (firstSeatWon ? 'You won the hand.' : 'The computer won the hand.')
        : 'Player ${result.winningPlayer + 1} takes the hand.';
    final ParkurResultAction? choice = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: firstSeatWon ? 'MASA SENİN!' : 'EL BİTTİ',
      titleEn: firstSeatWon ? 'HAND WON!' : 'HAND OVER',
      detailTr:
          '$winnerTr ${_playerLabel(result.losingPlayer)} bir zar kaybetti · iddia ${result.bid.count} ${_faceName(result.bid.face)} · gerçek ${result.actualCount}',
      detailEn:
          '$winnerEn ${_playerLabel(result.losingPlayer)} loses one die · claim ${result.bid.count} ${_faceName(result.bid.face)} · actual ${result.actualCount}',
      stars: stars,
      score: _session.score * 100,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < DiceBluffArenaGamePage.totalMatches,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (choice) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: _session.score * 100,
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
          title: Text(_english ? 'DICE & DAGGER' : 'ZAR VE HANÇER'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          '${_english ? 'HAND' : 'EL'} ${widget.level.number.toString().padLeft(2, '0')} · ${_english ? _scenario.arenaEn : _scenario.arenaTr}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
          child: Column(
            children: <Widget>[
              _tableBoard(),
              const SizedBox(height: 7),
              Expanded(child: _phasePanel()),
              const SizedBox(height: 4),
              SizedBox(
                key: const ValueKey<String>('dice_bluff_feedback'),
                height: 22,
                child: Center(
                  child: Text(
                    _feedback,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      color: StudioVisuals.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableBoard() => Container(
    key: const ValueKey<String>('dice_bluff_table'),
    height: 139,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x1928343F),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const CustomPaint(painter: _DiceTablePainter()),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.casino_rounded,
                    color: Color(0xFFF3D4AC),
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _english ? 'SEALED DICE TABLE' : 'KAPALI ZAR MASASI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFF4EEE7),
                        fontSize: 9,
                        letterSpacing: .7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${_scenario.diceCount} × ${_english ? 'DICE' : 'ZAR'}',
                    style: const TextStyle(
                      color: Color(0xFFF3D4AC),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                _english ? _scenario.arenaEn : _scenario.arenaTr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _engine.currentBid == null
                          ? (_english
                                ? 'No claim on the table yet.'
                                : 'Masada henüz iddia yok.')
                          : (_english
                                ? 'At least ${_engine.currentBid!.count} ${_faceName(_engine.currentBid!.face)}'
                                : 'En az ${_engine.currentBid!.count} ${_faceName(_engine.currentBid!.face)}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8DCCB),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_engine.currentBid != null)
                    Text(
                      _playerLabel(_engine.currentBid!.player),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF3D4AC),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _phasePanel() {
    if (!_started) return _setupPanel();
    return switch (_engine.phase) {
      DiceBluffPhase.rollHandoff => _rollHandoffPanel(),
      DiceBluffPhase.privateRoll => _privateRollPanel(),
      DiceBluffPhase.bidding => _biddingPanel(),
      DiceBluffPhase.result => _resultPanel(),
    };
  }

  Widget _setupPanel() => Column(
    key: const ValueKey<String>('dice_bluff_setup'),
    children: <Widget>[
      Text(
        _english ? 'CHOOSE YOUR TABLE' : 'MASA TÜRÜNÜ SEÇ',
        style: const TextStyle(
          color: _ink,
          fontSize: 12,
          letterSpacing: .6,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 5),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 7,
        children: <Widget>[
          ChoiceChip(
            key: const ValueKey<String>('dice_bluff_mode_ai'),
            label: Text(_english ? 'AI DUEL' : 'BİLGİSAYAR'),
            selected: _mode == DiceBluffMode.versusComputer,
            onSelected: (_) => _selectMode(DiceBluffMode.versusComputer),
            selectedColor: _accent,
            labelStyle: TextStyle(
              color: _mode == DiceBluffMode.versusComputer
                  ? Colors.white
                  : _ink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          ChoiceChip(
            key: const ValueKey<String>('dice_bluff_mode_local'),
            label: Text(_english ? 'LOCAL 2P' : 'YEREL 2 OYUNCU'),
            selected: _mode == DiceBluffMode.localDuel,
            onSelected: (_) => _selectMode(DiceBluffMode.localDuel),
            selectedColor: _accent,
            labelStyle: TextStyle(
              color: _mode == DiceBluffMode.localDuel ? Colors.white : _ink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      const SizedBox(height: 3),
      _noteCard(
        _english
            ? '3–7 dice each · count then face raises · no money or random prizes.'
            : 'Kişi başı 3–7 zar · önce adet sonra yüz yükselir · para/şans ödülü yok.',
        icon: Icons.rule_rounded,
      ),
      const Spacer(),
      _actionButton(
        key: const ValueKey<String>('dice_bluff_start'),
        label: _english ? 'SET THE TABLE' : 'MASAYI KUR',
        icon: Icons.table_restaurant_rounded,
        onPressed: _startMatch,
      ),
    ],
  );

  Widget _rollHandoffPanel() => Column(
    key: const ValueKey<String>('dice_bluff_roll_handoff'),
    children: <Widget>[
      _phaseTag(_english ? 'PRIVATE ROLL' : 'ÖZEL ZAR GÖSTERİMİ'),
      const SizedBox(height: 8),
      Text(
        '${_english ? 'Pass to' : 'Cihazı ver'}\n${_playerLabel(_engine.rollViewer)}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _ink,
          fontSize: 22,
          height: 1.1,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      _noteCard(
        _english
            ? 'No other player should see this hand. Memorize it; it vanishes when you pass.'
            : 'Diğer oyuncu bu eli görmesin. Aklında tut; verince zarlar kapanır.',
        icon: Icons.visibility_off_rounded,
      ),
      const Spacer(),
      _actionButton(
        key: const ValueKey<String>('dice_bluff_reveal'),
        label: _english ? 'REVEAL MY DICE' : 'ZARLARIMI GÖSTER',
        icon: Icons.lock_open_rounded,
        onPressed: _openRoll,
      ),
    ],
  );

  Widget _privateRollPanel() => Column(
    key: const ValueKey<String>('dice_bluff_private_roll'),
    children: <Widget>[
      _phaseTag(
        _mode == DiceBluffMode.localDuel
            ? '${_english ? 'ONLY PLAYER' : 'YALNIZCA OYUNCU'} ${_engine.rollViewer + 1}'
            : (_english
                  ? 'ONLY YOU · PRIVATE HAND'
                  : 'YALNIZCA SEN · GİZLİ EL'),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: Center(
          child: Wrap(
            key: const ValueKey<String>('dice_bluff_dice_hand'),
            alignment: WrapAlignment.center,
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              for (int index = 0; index < _engine.visibleDice.length; index++)
                _dieTile(
                  _engine.visibleDice[index],
                  key: ValueKey<String>('dice_bluff_die_$index'),
                ),
            ],
          ),
        ),
      ),
      _noteCard(
        _english
            ? 'Remember the values. The computer never sees your dice before a challenge.'
            : 'Yüzleri aklında tut. Bilgisayar meydan okumadan önce zarlarını göremez.',
        icon: Icons.psychology_rounded,
      ),
      const SizedBox(height: 6),
      _actionButton(
        key: const ValueKey<String>('dice_bluff_hide_roll'),
        label: _mode == DiceBluffMode.localDuel && _engine.rollViewer == 0
            ? (_english ? 'HIDE & PASS TO PLAYER 2' : 'KAPAT, OYUNCU 2’YE VER')
            : (_english
                  ? 'HIDE HAND & OPEN BIDDING'
                  : 'ELİ KAPAT, İDDİAYI BAŞLAT'),
        icon: Icons.screen_lock_portrait_rounded,
        onPressed: _hideRollAndPass,
      ),
    ],
  );

  Widget _biddingPanel() {
    if (_engine.isComputerTurn) {
      return Column(
        key: const ValueKey<String>('dice_bluff_computer_turn'),
        children: <Widget>[
          _phaseTag(_english ? 'COMPUTER THINKING' : 'BİLGİSAYAR DÜŞÜNÜYOR'),
          const Spacer(),
          const CircularProgressIndicator(color: _accent),
          const SizedBox(height: 8),
          Text(
            _scenario.opponentStyle.label(_english),
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
        ],
      );
    }
    final int player = _engine.activePlayer;
    final DiceBluffBid? current = _engine.currentBid;
    final bool canChallenge = current != null;
    return Column(
      key: const ValueKey<String>('dice_bluff_bidding'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _phaseTag('${_english ? 'TURN' : 'SIRA'} · ${_playerLabel(player)}'),
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                current == null
                    ? (_english ? 'Open the bidding' : 'İlk iddiayı ver')
                    : (_english
                          ? 'Current: ≥ ${current.count} ${_faceName(current.face)}'
                          : 'Masada: ≥ ${current.count} ${_faceName(current.face)}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${_english ? 'OF' : 'TOPLAM'} ${_scenario.totalDice}',
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          key: const ValueKey<String>('dice_bluff_faces'),
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 3,
          children: <Widget>[
            for (int face = 1; face <= _scenario.faceCount; face++)
              ChoiceChip(
                key: ValueKey<String>('dice_bluff_face_$face'),
                label: Text(_faceName(face)),
                selected: _bidFace == face,
                onSelected: (_) => _selectFace(face),
                visualDensity: VisualDensity.compact,
                selectedColor: const Color(0xFFF2E2D4),
                labelStyle: TextStyle(
                  color: _ink,
                  fontSize: 9,
                  fontWeight: _bidFace == face
                      ? FontWeight.w900
                      : FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 39,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton.filledTonal(
                key: const ValueKey<String>('dice_bluff_count_down'),
                tooltip: _english ? 'Fewer' : 'Azalt',
                onPressed: _bidCount > 1 ? () => _adjustBidCount(-1) : null,
                icon: const Icon(Icons.remove_rounded, size: 16),
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(
                key: const ValueKey<String>('dice_bluff_bid_count'),
                width: 50,
                child: Text(
                  '$_bidCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey<String>('dice_bluff_count_up'),
                tooltip: _english ? 'More' : 'Arttır',
                onPressed: _bidCount < _scenario.totalDice
                    ? () => _adjustBidCount(1)
                    : null,
                icon: const Icon(Icons.add_rounded, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: <Widget>[
            Expanded(
              child: _actionButton(
                key: const ValueKey<String>('dice_bluff_raise'),
                label: _english ? 'RAISE CLAIM' : 'İDDİAYI YÜKSELT',
                icon: Icons.trending_up_rounded,
                onPressed: _raise,
              ),
            ),
            if (canChallenge) ...<Widget>[
              const SizedBox(width: 6),
              Expanded(
                child: _actionButton(
                  key: const ValueKey<String>('dice_bluff_challenge'),
                  label: _english ? 'CHALLENGE' : 'BLÖF DE',
                  icon: Icons.campaign_rounded,
                  onPressed: _challenge,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _resultPanel() {
    final DiceBluffRoundResult result = _engine.result!;
    return Column(
      key: const ValueKey<String>('dice_bluff_result'),
      children: <Widget>[
        _phaseTag(_english ? 'DICE REVEALED' : 'ZARLAR AÇILDI'),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _revealedHand(
              label: _mode == DiceBluffMode.versusComputer
                  ? (_english ? 'YOU' : 'SEN')
                  : (_english ? 'PLAYER 1' : 'OYUNCU 1'),
              dice: _engine.revealedHumanDice,
              prefix: 'human',
            ),
            const SizedBox(width: 10),
            _revealedHand(
              label: _mode == DiceBluffMode.versusComputer
                  ? (_english ? 'COMPUTER' : 'BİLGİSAYAR')
                  : (_english ? 'PLAYER 2' : 'OYUNCU 2'),
              dice: _engine.revealedOpponentDice,
              prefix: 'opponent',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_english ? 'Claim' : 'İddia'} ${result.bid.count} ${_faceName(result.bid.face)} · ${_english ? 'table count' : 'masadaki sayı'} ${result.actualCount}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        _noteCard(
          '${_english ? 'Loses one die' : 'Bir zar kaybeder'} · ${_playerLabel(result.losingPlayer)}',
          icon: Icons.remove_circle_outline_rounded,
        ),
        const Spacer(),
        _actionButton(
          key: const ValueKey<String>('dice_bluff_finish'),
          label: _english ? 'SCORE THE HAND' : 'ELİ SONUÇLANDIR',
          icon: Icons.workspace_premium_rounded,
          onPressed: _finishHand,
        ),
      ],
    );
  }

  Widget _revealedHand({
    required String label,
    required List<int> dice,
    required String prefix,
  }) => Column(
    key: ValueKey<String>('dice_bluff_revealed_$prefix'),
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        label,
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 3,
        runSpacing: 3,
        children: <Widget>[
          for (final int face in dice) _dieTile(face, compact: true),
        ],
      ),
    ],
  );

  Widget _dieTile(int face, {Key? key, bool compact = false}) {
    final bool isWild = _scenario.wildFace == face;
    final double size = compact ? 25 : 43;
    return Container(
      key: key,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isWild ? const Color(0xFFF0D29D) : Colors.white,
        borderRadius: BorderRadius.circular(compact ? 6 : 10),
        border: Border.all(
          color: isWild ? const Color(0xFFD3A85E) : const Color(0xFFE5DED6),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D28343F),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          isWild ? '★' : '$face',
          style: TextStyle(
            color: isWild ? const Color(0xFF785622) : _ink,
            fontSize: compact ? 14 : 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _phaseTag(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6DC),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _ink,
          fontSize: 9,
          letterSpacing: .35,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );

  Widget _noteCard(String text, {required IconData icon}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8E0D8)),
    ),
    child: Row(
      children: <Widget>[
        Icon(icon, color: _accent, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 10,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _actionButton({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) => SizedBox(
    key: key,
    width: double.infinity,
    height: 43,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: .25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
  );
}

class _DiceTablePainter extends CustomPainter {
  const _DiceTablePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF253846),
            Color(0xFF344650),
            Color(0xFF3B3938),
          ],
        ).createShader(bounds),
    );
    final Rect felt = Rect.fromLTWH(
      size.width * .13,
      size.height * .24,
      size.width * .74,
      size.height * .9,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(felt, const Radius.circular(38)),
      Paint()..color = const Color(0xFF516653),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(felt.deflate(5), const Radius.circular(34)),
      Paint()
        ..color = const Color(0xFF89947B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final Offset lamp = Offset(size.width * .82, size.height * .12);
    canvas.drawCircle(lamp, 26, Paint()..color = const Color(0x22F3D4AC));
    canvas.drawCircle(lamp, 5, Paint()..color = const Color(0xFFF3D4AC));
    for (int i = 0; i < 4; i++) {
      final Offset die = Offset(
        size.width * (.28 + .15 * i),
        size.height * .69,
      );
      final Rect box = Rect.fromCenter(center: die, width: 25, height: 25);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(6)),
        Paint()
          ..color = i == 3 ? const Color(0xFFE8CB98) : const Color(0xFFEDE8E0),
      );
      canvas.drawCircle(die, 2.2, Paint()..color = const Color(0xFF41413E));
    }
  }

  @override
  bool shouldRepaint(covariant _DiceTablePainter oldDelegate) => false;
}
