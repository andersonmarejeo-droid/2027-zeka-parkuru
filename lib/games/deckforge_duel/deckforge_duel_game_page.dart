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
import 'deckforge_engine.dart';
import 'deckforge_scenario.dart';

class DeckforgeDuelGamePage extends StatelessWidget {
  const DeckforgeDuelGamePage({super.key});

  static const int totalMissions = DeckforgeScenario.campaignLevels;
  static const int totalStars = totalMissions * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalMissions,
    (int index) {
      final int level = index + 1;
      final String subtitleTr = switch (level) {
        <= 3 => 'Enerjiye göre hücum ve savunma kartı seç.',
        <= 6 => 'Rakibin açık hamle niyetine doğru yanıt ver.',
        7 || 8 => 'Güçlü kartı koru; siper ve delme zamanlamasını yönet.',
        9 ||
        10 => 'Usta düellosu: iyileşme, karşı duruş ve kesintiyi eşleştir.',
        <= 16 => 'Rakip destesi ve telegraph sırası giderek sertleşiyor.',
        _ => 'Final: 12 turda desteni ve enerjini kusursuz yönet.',
      };
      final String subtitleEn = switch (level) {
        <= 3 => 'Choose attack and guard cards within your energy.',
        <= 6 => 'Counter the opponent’s visible tactical intent.',
        7 || 8 => 'Time your breaker, guard and piercing cards.',
        9 || 10 => 'Expert duel: combine healing, riposte and disruption.',
        <= 16 => 'Enemy deck and telegraph sequence grow more punishing.',
        _ => 'Final: manage your deck and energy across 12 rounds.',
      };
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Deste Ustası ${level.toString().padLeft(2, '0')}',
        titleEn: 'Deckforge Duel ${level.toString().padLeft(2, '0')}',
        subtitleTr: subtitleTr,
        subtitleEn: subtitleEn,
        difficulty: switch (level) {
          <= 3 => 'ISINMA',
          <= 6 => 'TAKTİK',
          7 || 8 => 'İLERİ',
          9 || 10 => 'USTA',
          <= 16 => 'ELİT',
          _ => 'FİNAL',
        },
        icon: Icons.style_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'deckforge_duel',
      progressPrefix: 'deckforge_duel',
      titleTr: 'Deste Ustası',
      titleEn: 'Deckforge Duel',
      taglineTr: 'Öngör • Kaynak yönet • Eşzamanlı düello kazan',
      taglineEn: 'Read the intent • Manage resources • Win the duel',
      accent: skin.accent,
      icon: Icons.style_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => DeckforgeDuelPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class DeckforgeDuelPlayPage extends StatefulWidget {
  const DeckforgeDuelPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<DeckforgeDuelPlayPage> createState() => _DeckforgeDuelPlayPageState();
}

class _DeckforgeDuelPlayPageState extends State<DeckforgeDuelPlayPage> {
  static const Color _accent = Color(0xFF8B6748);
  static const Color _ink = Color(0xFF293640);
  static const Color _red = Color(0xFFB75952);
  static const Color _blue = Color(0xFF4F8296);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  DeckforgeMode? _mode;
  DeckforgeScenario? _scenario;
  DeckforgeBattleEngine? _engine;
  StudioGameSession? _session;
  int? _practiceIndex;
  bool _english = false;
  bool _finishedDialog = false;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
  }

  Future<void> _start(DeckforgeMode mode) async {
    DeckforgeScenario scenario = DeckforgeScenario.forLevel(
      widget.level.number,
    );
    int? practiceIndex;
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'deckforge_duel_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int previous =
            await preferences.getInt('deckforge_duel_practice_index') ?? 0;
        practiceIndex = previous % DeckforgeScenario.practiceBattles + 1;
        scenario = DeckforgeScenario.forPractice(practiceIndex);
        await preferences.setInt(
          'deckforge_duel_practice_index',
          practiceIndex,
        );
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // The authored campaign remains playable when local storage is unavailable.
    }
    if (!mounted) return;
    final StudioGameSession session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    setState(() {
      _mode = mode;
      _scenario = scenario;
      _practiceIndex = practiceIndex;
      _engine = DeckforgeBattleEngine(scenario: scenario, mode: mode);
      _session = session;
      _feedback = _english
          ? 'Select cards up to 3 energy, then commit your plan.'
          : '3 enerjiye kadar kart seç, sonra hamleni kilitle.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  DeckforgeBattleEngine get _battle => _engine!;
  DeckforgeScenario get _board => _scenario!;

  void _toggleCard(int index) {
    final bool accepted = _battle.toggleCard(index);
    setState(() {
      _feedback = accepted
          ? (_english ? 'Plan updated.' : 'Plan güncellendi.')
          : (_english
                ? 'That card exceeds the energy budget.'
                : 'Bu kart enerji sınırını aşıyor.');
    });
    unawaited(
      _audioProfile.play(
        _audio,
        accepted ? GameAudioEvent.accepted : GameAudioEvent.rejected,
        gain: .1,
      ),
    );
  }

  void _sealPlan() {
    final DeckforgePhase oldPhase = _battle.phase;
    if (!_battle.sealPlan()) {
      return;
    }
    if (_battle.phase == DeckforgePhase.handoff) {
      setState(() {
        _feedback = _english
            ? 'Plan sealed. Pass the device; Player 2’s hand is private.'
            : 'Hamle kilitlendi. Cihazı ver; 2. oyuncunun eli gizli.';
      });
    } else {
      final DeckforgeRoundReport? report = _battle.lastReport;
      setState(() {
        if (report == null) {
          _feedback = '';
        } else {
          final String one = report.playerOneCards
              .map((DeckforgeCard card) => card.label(_english))
              .join(' + ');
          final String two = report.playerTwoCards
              .map((DeckforgeCard card) => card.label(_english))
              .join(' + ');
          _feedback = _english
              ? 'P1 [$one] vs P2 [$two] · HP loss ${report.playerOneDamage}/${report.playerTwoDamage}'
              : '1. oyuncu [$one] · 2. oyuncu [$two] · can kaybı ${report.playerOneDamage}/${report.playerTwoDamage}';
        }
      });
      final GameAudioEvent event = !_battle.isComplete
          ? GameAudioEvent.accepted
          : (_battle.outcome == DeckforgeOutcome.playerOne
                ? GameAudioEvent.levelComplete
                : GameAudioEvent.rejected);
      unawaited(_audioProfile.play(
        _audio,
        event,
        gain: .14,
        levelNumber: widget.level.number,
      ));
      if (_battle.isComplete) unawaited(_finishBattle());
    }
    if (oldPhase == DeckforgePhase.planning &&
        _battle.phase == DeckforgePhase.handoff) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .1));
    }
  }

  void _confirmHandoff() {
    if (!_battle.confirmHandoff()) return;
    setState(() {
      _feedback = _english
          ? 'Player 2: plan privately, then commit.'
          : '2. oyuncu: hamleni gizlice planla ve kilitle.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .1));
  }

  Future<void> _finishBattle() async {
    if (_finishedDialog || !_battle.isComplete) return;
    _finishedDialog = true;
    final bool won = _battle.outcome == DeckforgeOutcome.playerOne;
    final int remainingHealth = _battle.playerHealth;
    final int stars = won
        ? (remainingHealth >= 20
              ? 3
              : remainingHealth >= 9
              ? 2
              : 1)
        : 0;
    final int score = won
        ? (600 + remainingHealth * 12 - _battle.round * 8)
              .clamp(300, 1000)
              .toInt()
        : 0;
    if (won) {
      _session!.recordAccepted(points: score);
      _session!.complete(
        stars: stars,
        action: widget.level.number < DeckforgeDuelGamePage.totalMissions
            ? StudioResultAction.next
            : StudioResultAction.map,
      );
    } else {
      _session!.fail();
    }
    final String titleTr = won
        ? 'ARENA SANA AİT!'
        : (_battle.outcome == DeckforgeOutcome.draw
              ? 'BERABERE!'
              : 'DÜELLO BİTTİ');
    final String titleEn = won
        ? 'THE ARENA IS YOURS!'
        : (_battle.outcome == DeckforgeOutcome.draw ? 'DRAW!' : 'DUEL OVER');
    final ParkurResultAction? choice = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: titleTr,
      titleEn: titleEn,
      detailTr: won
          ? '${_board.arenaTr} · ${_battle.round} tur · $remainingHealth can · $score puan'
          : '${_board.arenaTr} · ${_battle.round} tur · tekrar dene',
      detailEn: won
          ? '${_board.arenaEn} · ${_battle.round} rounds · $remainingHealth health · $score points'
          : '${_board.arenaEn} · ${_battle.round} rounds · try again',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext:
          won && widget.level.number < DeckforgeDuelGamePage.totalMissions,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (choice) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      (won
              ? StudioGameResult.completed(
                  score: score,
                  stars: stars,
                  action: action,
                )
              : StudioGameResult.failed())
          .toParkurResult(),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          '${_english ? 'DUEL' : 'DÜELLO'} ${widget.level.number.toString().padLeft(2, '0')} · ${_english ? 'DECKFORGE' : 'DESTE USTASI'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 3, 12, 8),
              child: _mode == null ? _modePicker() : _battleScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modePicker() => Column(
    children: <Widget>[
      _arenaArt(height: 170),
      const SizedBox(height: 12),
      Text(
        _english ? 'CHOOSE YOUR MATCH' : 'DÜELLO BİÇİMİNİ SEÇ',
        style: const TextStyle(
          color: _ink,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        _english
            ? 'Three energy. Hidden hands. Plans resolve together.'
            : 'Üç enerji. Kapalı eller. Hamleler aynı anda çözülür.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: StudioVisuals.muted, fontSize: 12),
      ),
      const Spacer(),
      _modeButton(
        key: const ValueKey<String>('deckforge_mode_computer'),
        icon: Icons.smart_toy_rounded,
        title: _english ? 'DUEL THE TACTICIAN' : 'TAKTİSYENE KARŞI',
        subtitle: _english
            ? 'Read its intent. The rival never sees your plan.'
            : 'Niyetini oku. Rakip kapalı planını asla görmez.',
        onPressed: () => unawaited(_start(DeckforgeMode.computer)),
      ),
      const SizedBox(height: 10),
      _modeButton(
        key: const ValueKey<String>('deckforge_mode_local'),
        icon: Icons.people_alt_rounded,
        title: _english ? 'LOCAL TWO-PLAYER' : 'AYNI CİHAZDA İKİ KİŞİ',
        subtitle: _english
            ? 'Both players seal a private plan before reveal.'
            : 'İki oyuncu da açılmadan önce özel planını kilitler.',
        onPressed: () => unawaited(_start(DeckforgeMode.local)),
        subdued: true,
      ),
      const Spacer(),
    ],
  );

  Widget _battleScreen() {
    final bool local = _mode == DeckforgeMode.local;
    final bool handoff = _battle.phase == DeckforgePhase.handoff;
    final int selfHealth = local && _battle.currentPlayer == 1
        ? _battle.opponentHealth
        : _battle.playerHealth;
    final int rivalHealth = local && _battle.currentPlayer == 1
        ? _battle.playerHealth
        : _battle.opponentHealth;
    final int energy = local && _battle.currentPlayer == 1
        ? _battle.opponentEnergy
        : _battle.playerEnergy;
    return Column(
      children: <Widget>[
        _arenaArt(height: 126),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _healthPanel(
                label: local
                    ? (_battle.currentPlayer == 1 ? 'OYUNCU 2' : 'OYUNCU 1')
                    : (_english ? 'YOU' : 'SEN'),
                health: selfHealth,
                maxHealth: local && _battle.currentPlayer == 1
                    ? _board.playerHealth
                    : _board.playerHealth,
                color: _blue,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.bolt_rounded, color: _accent, size: 19),
            ),
            Expanded(
              child: _healthPanel(
                label: local
                    ? (_battle.currentPlayer == 1 ? 'OYUNCU 1' : 'OYUNCU 2')
                    : (_english ? 'RIVAL' : 'RAKİP'),
                health: rivalHealth,
                maxHealth: local && _battle.currentPlayer == 1
                    ? _board.playerHealth
                    : _board.opponentHealth,
                color: _red,
                trailing: !local,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            _smallPill('${_english ? 'ROUND' : 'TUR'} ${_battle.round}/12'),
            const SizedBox(width: 6),
            Expanded(
              child: _smallPill(
                local
                    ? (_english ? 'BOTH PLANS SEALED' : 'İKİ PLAN DA KAPALI')
                    : '${_english ? 'RIVAL INTENT' : 'RAKİP NİYETİ'} · ${_battle.opponentIntent.label(_english)} · ${_battle.opponentEnergy}/${_board.opponentEnergyCap}',
                icon: local ? Icons.lock_rounded : Icons.visibility_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1ECE4),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            _feedback,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!handoff) const Spacer(),
        if (handoff)
          _handoffPanel()
        else ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  local
                      ? '${_english ? 'PLAYER' : 'OYUNCU'} ${_battle.currentPlayer + 1} · ${_english ? 'PRIVATE HAND' : 'GİZLİ EL'}'
                      : (_english ? 'YOUR PRIVATE HAND' : 'GİZLİ ELİN'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .35,
                  ),
                ),
              ),
              _smallPill('${_english ? 'ENERGY' : 'ENERJİ'} $energy'),
              const SizedBox(width: 5),
              _smallPill('${_battle.selectedEnergy}/$energy'),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 122,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double width = (constraints.maxWidth - 8) / 5;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    for (int i = 0; i < _battle.visibleHand.length; i++)
                      SizedBox(
                        width: width,
                        child: _cardButton(i, _battle.visibleHand[i]),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey<String>('deckforge_undo'),
                  onPressed: _battle.selectedCards.isEmpty
                      ? null
                      : () => setState(_battle.undoSelection),
                  icon: const Icon(Icons.undo_rounded, size: 17),
                  label: Text(_english ? 'UNDO' : 'GERİ AL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const ValueKey<String>('deckforge_commit'),
                  onPressed: _sealPlan,
                  icon: const Icon(Icons.lock_rounded, size: 17),
                  label: Text(
                    _battle.selectedCards.isEmpty
                        ? (_english ? 'PASS TURN' : 'TURU GEÇ')
                        : (_english ? 'SEAL PLAN' : 'HAMLEYİ KİLİTLE'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _handoffPanel() => Expanded(
    child: Container(
      key: const ValueKey<String>('deckforge_handoff'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF263943),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.screen_lock_portrait_rounded,
            color: Color(0xFFE8C995),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            _english
                ? 'PLAN SEALED · PASS DEVICE'
                : 'HAMLE KİLİTLENDİ · CİHAZI VER',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _english
                ? 'Player 1’s hand and choices are hidden. Player 2 may now plan.'
                : '1. oyuncunun eli ve seçimleri gizlendi. 2. oyuncu şimdi plan yapabilir.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD9E3E2), fontSize: 11),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey<String>('deckforge_confirm_handoff'),
            onPressed: _confirmHandoff,
            icon: const Icon(Icons.visibility_off_rounded),
            label: Text(_english ? 'PLAYER 2 READY' : 'OYUNCU 2 HAZIR'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4AA70),
              foregroundColor: _ink,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _cardButton(int index, DeckforgeCard card) {
    final bool selected = _battle.selectedHandIndices.contains(index);
    final DeckforgeCardRule rule = card.rule;
    final IconData icon = switch (card) {
      DeckforgeCard.quickCut ||
      DeckforgeCard.breaker ||
      DeckforgeCard.feint => Icons.flash_on_rounded,
      DeckforgeCard.brace || DeckforgeCard.riposte => Icons.shield_rounded,
      DeckforgeCard.focus ||
      DeckforgeCard.disrupt => Icons.center_focus_strong_rounded,
      DeckforgeCard.mend || DeckforgeCard.siphon => Icons.favorite_rounded,
      DeckforgeCard.overdrive => Icons.bolt_rounded,
    };
    final Color tint = rule.damage > 0
        ? const Color(0xFFB9695C)
        : rule.heal > 0
        ? const Color(0xFF638C72)
        : const Color(0xFF5B8190);
    final String effect = <String>[
      if (rule.damage > 0) '−${rule.damage}',
      if (rule.shield > 0) '+${rule.shield} ${_english ? 'GUARD' : 'SİPER'}',
      if (rule.heal > 0) '+${rule.heal} ♥',
      if (rule.piercing > 0) '${_english ? 'PIERCE' : 'DEL'} ${rule.piercing}',
      if (rule.focus > 0) '+${rule.focus} ${_english ? 'FOCUS' : 'ODAK'}',
      if (rule.counter > 0) '${_english ? 'COUNTER' : 'KARŞI'} ${rule.counter}',
      if (rule.jam > 0) '${_english ? 'JAM' : 'KES'} ${rule.jam}',
    ].join(' · ');
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${card.label(_english)}, ${_english ? 'cost' : 'bedel'} ${rule.cost}, $effect',
      child: Material(
        color: selected ? const Color(0xFFFFF1D8) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey<String>('deckforge_card_$index'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleCard(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.fromLTRB(4, 5, 4, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _accent : const Color(0xFFE5DED3),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x208B6748),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x10293640),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: CustomPaint(
              painter: _DeckforgeCardPainter(tint: tint, selected: selected),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Icon(icon, size: 14, color: tint),
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2ECE2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${rule.cost}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    card.label(_english),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 9,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    effect,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tint,
                      fontSize: 7,
                      height: 1.05,
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
  }

  Widget _healthPanel({
    required String label,
    required int health,
    required int maxHealth,
    required Color color,
    bool trailing = false,
  }) => Column(
    crossAxisAlignment: trailing
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        mainAxisAlignment: trailing
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: <Widget>[
          if (!trailing) Icon(Icons.favorite_rounded, color: color, size: 13),
          if (!trailing) const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (trailing) const SizedBox(width: 4),
          if (trailing) Icon(Icons.favorite_rounded, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            '$health/$maxHealth',
            maxLines: 1,
            style: const TextStyle(
              color: _ink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: maxHealth == 0 ? 0 : health / maxHealth,
          minHeight: 6,
          backgroundColor: const Color(0xFFE6E0D7),
          color: color,
        ),
      ),
    ],
  );

  Widget _smallPill(String text, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF1ECE4),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 12, color: _accent),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _modeButton({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    bool subdued = false,
  }) => Material(
    color: subdued ? const Color(0xFFF5F1EA) : const Color(0xFF263943),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      key: key,
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color: subdued ? _accent : const Color(0xFFE4C18F),
              size: 25,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subdued ? _ink : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subdued
                          ? StudioVisuals.muted
                          : const Color(0xFFD5DFDE),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: subdued ? _accent : Colors.white70,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _arenaArt({required double height}) => ClipRRect(
    borderRadius: BorderRadius.circular(19),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const CustomPaint(painter: _DeckforgeArenaPainter()),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: Color(0xFFE5C995),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _english
                            ? 'TACTICAL CARD ARENA'
                            : 'TAKTİK KART ARENASI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE7D8BD),
                          fontSize: 9,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      _practiceIndex != null
                          ? '${_english ? 'PRACTICE' : 'PRATİK'} ${_practiceIndex!.toString().padLeft(3, '0')}'
                          : (_mode == DeckforgeMode.local
                                ? 'LOCAL DUEL'
                                : '20 · 300'),
                      style: const TextStyle(
                        color: Color(0xFFE7D8BD),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _mode == null
                      ? (_english ? 'DECKFORGE' : 'DESTE USTASI')
                      : (_english ? _board.arenaEn : _board.arenaTr),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _english
                      ? '10 card types · 18-card deck · simultaneous combat'
                      : '10 kart türü · 18 kartlık deste · eşzamanlı çatışma',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD3D9D4),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DeckforgeArenaPainter extends CustomPainter {
  const _DeckforgeArenaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Paint base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF354B4B),
          Color(0xFF263943),
          Color(0xFF1D2E38),
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, base);
    final Paint glow = Paint()..color = const Color(0x1FE3C38C);
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .26),
      size.height * .56,
      glow,
    );
    final Paint rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x3FE5C995);
    final Rect frame = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(14)),
      rim,
    );
    final Paint sigil = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0x31E5C995);
    final Offset center = Offset(size.width * .78, size.height * .56);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(center, 19 + i * 15, sigil);
    }
    final Path crest = Path()
      ..moveTo(center.dx, center.dy - 17)
      ..lineTo(center.dx + 13, center.dy - 8)
      ..lineTo(center.dx + 9, center.dy + 13)
      ..lineTo(center.dx, center.dy + 20)
      ..lineTo(center.dx - 9, center.dy + 13)
      ..lineTo(center.dx - 13, center.dy - 8)
      ..close();
    canvas.drawPath(crest, Paint()..color = const Color(0x24E5C995));
    canvas.drawPath(crest, sigil);
    final Paint speck = Paint()..color = const Color(0x30FFFFFF);
    for (int i = 0; i < 14; i++) {
      final double x = (i * 71.0 + 33) % size.width;
      final double y = (i * 37.0 + 17) % size.height;
      canvas.drawCircle(Offset(x, y), i.isEven ? 1.1 : .7, speck);
    }
  }

  @override
  bool shouldRepaint(covariant _DeckforgeArenaPainter oldDelegate) => false;
}

class _DeckforgeCardPainter extends CustomPainter {
  const _DeckforgeCardPainter({required this.tint, required this.selected});

  final Color tint;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Paint surface = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.lerp(Colors.white, tint, selected ? .14 : .045)!,
          const Color(0xFFFFFEFB),
          Color.lerp(Colors.white, tint, selected ? .08 : .025)!,
        ],
      ).createShader(bounds);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(11)),
      surface,
    );
    final Paint frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = Color.lerp(
        const Color(0xFFB6A48B),
        tint,
        .45,
      )!.withValues(alpha: .52);
    final Rect inset = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, const Radius.circular(8)),
      frame,
    );
    final Offset crest = Offset(size.width / 2, size.height * .57);
    final double radius = math.min(size.width * .25, 15);
    final Paint crestFill = Paint()
      ..color = tint.withValues(alpha: selected ? .19 : .09);
    final Paint crestStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = tint.withValues(alpha: selected ? .38 : .18);
    canvas.drawCircle(crest, radius, crestFill);
    canvas.drawCircle(crest, radius, crestStroke);
    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2;
      final Offset point = Offset(
        crest.dx + math.cos(angle) * 9,
        crest.dy + math.sin(angle) * 9,
      );
      canvas.drawCircle(point, 1.2, crestStroke);
    }
    final Paint separator = Paint()
      ..color = tint.withValues(alpha: .16)
      ..strokeWidth = .7;
    canvas.drawLine(Offset(7, 29), Offset(size.width - 7, 29), separator);
    canvas.drawLine(
      Offset(7, size.height - 25),
      Offset(size.width - 7, size.height - 25),
      separator,
    );
  }

  @override
  bool shouldRepaint(covariant _DeckforgeCardPainter oldDelegate) =>
      tint != oldDelegate.tint || selected != oldDelegate.selected;
}
