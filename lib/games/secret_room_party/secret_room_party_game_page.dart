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
import 'secret_room_engine.dart';
import 'secret_room_scenario.dart';

class SecretRoomPartyGamePage extends StatelessWidget {
  const SecretRoomPartyGamePage({super.key});
  static const int totalCases = SecretRoomScenario.campaignLevels;
  static const int totalStars = totalCases * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Gizli Oda ${level.toString().padLeft(2, '0')}',
        titleEn: 'Secret Room ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Rolleri sakla, ipuçlarını konuş ve oy ver.',
          <= 6 => 'Herkesin özel bilgisini adil biçimde dinle.',
          7 || 8 => 'İleri: çelişen anlatımları birlikte değerlendir.',
          9 || 10 => 'Uzman: az ipucuyla sağlam bir oylama kur.',
          <= 16 => 'Usta: dikkat dağıtıcı ayrıntıları ele.',
          _ => 'Final: küçük kanıt kümesinde sabote edeni bul.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Hide roles, discuss clues and cast a vote.',
          <= 6 => 'Hear each player’s private information fairly.',
          7 || 8 => 'Advanced: weigh conflicting accounts together.',
          9 || 10 => 'Expert: reach a sound vote with fewer clues.',
          <= 16 => 'Master: separate red herrings from useful details.',
          _ => 'Final: find the saboteur with a smaller evidence set.',
        },
        difficulty: switch (level) {
          <= 3 => 'ISINMA',
          <= 6 => 'İPUCU',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.visibility_off_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'secret_room_party',
      progressPrefix: 'secret_room_party',
      titleTr: 'Gizli Oda: Sosyal Çıkarım',
      titleEn: 'Secret Room: Social Deduction',
      taglineTr: 'Paylaş • Tartış • Gizli oy ver',
      taglineEn: 'Pass • Discuss • Vote in private',
      accent: skin.accent,
      icon: Icons.visibility_off_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => SecretRoomPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class SecretRoomPlayPage extends StatefulWidget {
  const SecretRoomPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<SecretRoomPlayPage> createState() => _SecretRoomPlayPageState();
}

class _SecretRoomPlayPageState extends State<SecretRoomPlayPage> {
  static const Color _accent = Color(0xFF8B7062);
  static const Color _ink = Color(0xFF293540);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late SecretRoomScenario _scenario;
  late SecretRoomEngine _engine;
  late StudioGameSession _session;
  int _playerCount = 4;
  int? _practiceIndex;
  int? _selectedSuspect;
  bool _ready = false;
  bool _started = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareCase());
  }

  Future<void> _prepareCase() async {
    SecretRoomScenario scenario = SecretRoomScenario.forLevel(
      widget.level.number,
      playerCount: _playerCount,
    );
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String visitKey =
          'secret_room_party_level_${widget.level.number}_visits';
      final int visits = await prefs.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int previous =
            await prefs.getInt('secret_room_party_practice_index') ?? 0;
        _practiceIndex = previous % SecretRoomScenario.practiceCases + 1;
        await prefs.setInt('secret_room_party_practice_index', _practiceIndex!);
        scenario = SecretRoomScenario.forPractice(
          _practiceIndex!,
          playerCount: _playerCount,
        );
      }
      await prefs.setInt(visitKey, visits + 1);
    } catch (_) {
      // The authored case remains playable when local preferences are unavailable.
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = SecretRoomEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    setState(() {
      _english = context.l10n.isEnglish;
      _feedback = _english
          ? 'Choose 3–6 players. Roles stay hidden until each card is revealed.'
          : '3–6 oyuncu seç. Her kart açılana kadar roller gizli kalır.';
      _ready = true;
    });
  }

  void _changePlayerCount(int count) {
    if (!_ready || _started || count < 3 || count > 6) return;
    setState(() {
      _playerCount = count;
      _scenario = _practiceIndex == null
          ? SecretRoomScenario.forLevel(widget.level.number, playerCount: count)
          : SecretRoomScenario.forPractice(_practiceIndex!, playerCount: count);
      _engine = SecretRoomEngine(scenario: _scenario);
      _session = StudioGameSession(
        level: widget.level.number,
        seed: _scenario.seed,
      )..start();
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .14));
  }

  void _startCase() {
    if (!_ready || _started) return;
    setState(() {
      _started = true;
      _feedback = _english
          ? 'Pass the device. Only the active player should read the role card.'
          : 'Cihazı ver. Rol kartını yalnızca sırası gelen oyuncu okusun.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .16));
  }

  void _revealRole() {
    if (!_engine.revealRole()) return;
    setState(() {
      _feedback = _english
          ? 'Read silently. Hide the card before passing the device.'
          : 'Sessizce oku. Cihazı vermeden önce kartı kapat.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _hideAndPass() {
    if (!_engine.hideAndPass()) return;
    setState(() {
      _feedback = _engine.phase == SecretRoomPhase.discussion
          ? (_english
                ? 'All roles are hidden. Discuss the shared evidence.'
                : 'Tüm roller gizli. Ortak kanıtları tartışın.')
          : (_english
                ? 'Private card cleared. Pass to the next player.'
                : 'Özel kart kapandı. Cihazı sıradaki oyuncuya ver.');
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .14));
  }

  void _startVoting() {
    if (!_engine.startVoting()) return;
    setState(() {
      _feedback = _english
          ? 'The ballot is sealed: no earlier vote is shown.'
          : 'Oylar kapalı: önceki oylar gösterilmez.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .14));
  }

  void _openBallot() {
    if (!_engine.openBallot()) return;
    setState(() => _selectedSuspect = null);
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _chooseSuspect(int player) {
    if (!_engine.canVote || player == _engine.activePlayer) return;
    setState(() {
      _selectedSuspect = player;
      _feedback = _english
          ? 'Player ${player + 1} selected. Only the current voter sees this.'
          : '${player + 1}. oyuncu seçildi. Seçimi yalnızca oy veren görür.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _submitVote() {
    final int? suspect = _selectedSuspect;
    if (suspect == null || !_engine.submitVote(suspect)) return;
    setState(() {
      _selectedSuspect = null;
      _feedback = _engine.isComplete
          ? (_english
                ? 'The final sealed vote is in.'
                : 'Son kapalı oy da verildi.')
          : (_english
                ? 'Vote sealed. Pass the device without discussing the choice.'
                : 'Oy kapandı. Seçimi konuşmadan cihazı sıradakine ver.');
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .15));
    _audio.hapticLight();
  }

  Future<void> _finishCase() async {
    if (_finished) return;
    final SecretRoomOutcome? outcome = _engine.outcome;
    if (outcome == null) return;
    _finished = true;
    final int stars = outcome.crewWon ? 3 : 1;
    _session.recordAccepted(points: outcome.crewWon ? 100 : 45);
    _session.complete(
      stars: stars,
      action: widget.level.number < SecretRoomPartyGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    if (!outcome.crewWon) {
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.rejected, gain: .32),
      );
    }
    final String verdictTr = outcome.crewWon
        ? 'Sabotajcı ${outcome.suspect! + 1}. oyuncu çıktı. Ekip doğru kişiyi yakaladı.'
        : outcome.suspect == null
        ? 'Oylar çoğunluk oluşturmadı. Sabotajcı aradan sıyrıldı.'
        : 'Ekip yanlış kişiyi seçti. Sabotajcı ${_saboteurIndex + 1}. oyuncuydu.';
    final String verdictEn = outcome.crewWon
        ? 'Player ${outcome.suspect! + 1} was the saboteur. The crew found the right person.'
        : outcome.suspect == null
        ? 'The vote had no decisive majority. The saboteur slipped away.'
        : 'The crew chose the wrong player. Player ${_saboteurIndex + 1} was the saboteur.';
    final ParkurResultAction? choice = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: outcome.crewWon ? 'VAKA ÇÖZÜLDÜ!' : 'VAKA SONUCU',
      titleEn: outcome.crewWon ? 'CASE SOLVED!' : 'CASE CLOSED',
      detailTr:
          '$verdictTr · ${outcome.voteCount}/${_scenario.playerCount} oy · gereken ${outcome.requiredVotes}',
      detailEn:
          '$verdictEn · ${outcome.voteCount}/${_scenario.playerCount} votes · ${outcome.requiredVotes} required',
      stars: stars,
      score: _session.score * 100,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < SecretRoomPartyGamePage.totalCases,
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

  int get _saboteurIndex => _scenario.playerCards.indexWhere(
    (SecretPlayerCard card) => card.isSaboteur,
  );

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(title: Text(_english ? 'SECRET ROOM' : 'GİZLİ ODA')),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final String caseTitle = _english ? _scenario.titleEn : _scenario.titleTr;
    final String location = _english
        ? _scenario.locationEn
        : _scenario.locationTr;
    final SecretRoomPhase phase = _engine.phase;
    final bool showCase =
        phase == SecretRoomPhase.discussion ||
        phase == SecretRoomPhase.voteHandoff ||
        phase == SecretRoomPhase.ballotOpen ||
        phase == SecretRoomPhase.result;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          '${_english ? 'CASE' : 'VAKA'} ${widget.level.number.toString().padLeft(2, '0')} · $caseTitle',
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
              _caseBoard(
                title: caseTitle,
                location: location,
                showIncident: showCase,
              ),
              const SizedBox(height: 7),
              Expanded(child: _phasePanel()),
              const SizedBox(height: 4),
              SizedBox(
                key: const ValueKey<String>('secret_room_feedback'),
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

  Widget _caseBoard({
    required String title,
    required String location,
    required bool showIncident,
  }) => Container(
    key: const ValueKey<String>('secret_room_scene'),
    height: 150,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x182B313B),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(painter: const _SecretRoomPainter()),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 11, 15, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFFF3CF98),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _english ? 'PRIVATE CASE FILE' : 'ÖZEL VAKA DOSYASI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE9E1D6),
                        fontSize: 9,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_english ? 'PLAYERS' : 'OYUNCU'} $_playerCount',
                    style: const TextStyle(
                      color: Color(0xFFF3CF98),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '$title · $location',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                showIncident
                    ? (_english ? _scenario.incidentEn : _scenario.incidentTr)
                    : (_english
                          ? 'A sealed-role mystery for a shared screen.'
                          : 'Paylaşılan ekranda kapalı rollerle bir vaka.'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE2DCD5),
                  fontSize: 10,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
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
      SecretRoomPhase.roleHandoff => _roleHandoffPanel(),
      SecretRoomPhase.roleVisible => _privateRolePanel(),
      SecretRoomPhase.discussion => _discussionPanel(),
      SecretRoomPhase.voteHandoff => _voteHandoffPanel(),
      SecretRoomPhase.ballotOpen => _ballotPanel(),
      SecretRoomPhase.result => _resultPanel(),
    };
  }

  Widget _setupPanel() => Column(
    key: const ValueKey<String>('secret_room_setup'),
    children: <Widget>[
      Text(
        _english ? 'PASS-AND-PLAY' : 'AYNI CİHAZDA SIRAYLA',
        style: const TextStyle(
          color: _ink,
          fontSize: 12,
          letterSpacing: .7,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _english
            ? 'One hidden saboteur · one private clue per player · no account or network.'
            : 'Bir gizli sabotajcı · herkese özel ipucu · hesap ve internet gerekmez.',
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, color: StudioVisuals.muted),
      ),
      const SizedBox(height: 9),
      Row(
        children: <Widget>[
          for (int count = 3; count <= 6; count++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  key: ValueKey<String>('secret_room_player_count_$count'),
                  label: Text('$count'),
                  selected: _playerCount == count,
                  onSelected: (_) => _changePlayerCount(count),
                  labelStyle: TextStyle(
                    color: _playerCount == count ? Colors.white : _ink,
                    fontWeight: FontWeight.w900,
                  ),
                  selectedColor: _accent,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE4DED8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
        ],
      ),
      const Spacer(),
      _actionButton(
        key: const ValueKey<String>('secret_room_start'),
        label: _english ? 'DISTRIBUTE ROLE CARDS' : 'ROL KARTLARINI DAĞIT',
        icon: Icons.style_rounded,
        onPressed: _startCase,
      ),
    ],
  );

  Widget _roleHandoffPanel() => Column(
    key: const ValueKey<String>('secret_room_role_handoff'),
    children: <Widget>[
      _phaseTag(_english ? 'PRIVATE ROLE' : 'ÖZEL ROL'),
      const SizedBox(height: 8),
      Text(
        '${_english ? 'Pass the screen to' : 'Ekranı şu oyuncuya ver'}\n${_english ? 'PLAYER' : 'OYUNCU'} ${_engine.activePlayer + 1}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _ink,
          fontSize: 22,
          height: 1.12,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      _noteCard(
        _english
            ? 'Make sure nobody else can see the screen before opening the card.'
            : 'Kartı açmadan önce ekrana başkasının bakmadığından emin ol.',
        icon: Icons.visibility_off_rounded,
      ),
      const Spacer(),
      _actionButton(
        key: const ValueKey<String>('secret_room_show_role'),
        label: _english ? 'SHOW MY PRIVATE CARD' : 'ÖZEL KARTIMI AÇ',
        icon: Icons.lock_open_rounded,
        onPressed: _revealRole,
      ),
    ],
  );

  Widget _privateRolePanel() {
    final SecretPlayerCard card = _scenario.playerCards[_engine.activePlayer];
    return Column(
      key: const ValueKey<String>('secret_room_private_card'),
      children: <Widget>[
        _phaseTag(
          _english
              ? 'ONLY PLAYER ${_engine.activePlayer + 1}'
              : 'YALNIZCA ${_engine.activePlayer + 1}. OYUNCU',
        ),
        const SizedBox(height: 7),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFF283744),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD3B583), width: 1.2),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x1B293540),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  card.isSaboteur ? Icons.masks_rounded : Icons.badge_rounded,
                  color: const Color(0xFFF1CF97),
                  size: 30,
                ),
                const SizedBox(height: 5),
                Text(
                  card.persona.label(_english),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(height: 1, width: 74, color: const Color(0xFF857A73)),
                const SizedBox(height: 7),
                Text(
                  card.isSaboteur
                      ? (_english ? 'SABOTEUR' : 'SABOTAJCI')
                      : (_english ? 'INVESTIGATOR' : 'ARAŞTIRMACI'),
                  style: TextStyle(
                    color: card.isSaboteur
                        ? const Color(0xFFFFB4A6)
                        : const Color(0xFFB8D9C9),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.privateBrief(_english),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF4EEE8),
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        _actionButton(
          key: const ValueKey<String>('secret_room_hide_pass'),
          label: _english
              ? 'HIDE CARD & PASS DEVICE'
              : 'KARTI KAPAT, CİHAZI VER',
          icon: Icons.screen_lock_portrait_rounded,
          onPressed: _hideAndPass,
        ),
      ],
    );
  }

  Widget _discussionPanel() => Column(
    key: const ValueKey<String>('secret_room_discussion'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _phaseTag(
        _english ? 'SHARED EVIDENCE · DISCUSS' : 'ORTAK KANIT · TARTIŞIN',
      ),
      const SizedBox(height: 5),
      Expanded(
        child: ListView.separated(
          key: const ValueKey<String>('secret_room_evidence_list'),
          padding: const EdgeInsets.symmetric(vertical: 2),
          itemCount: _scenario.publicEvidenceTr.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (BuildContext context, int index) => _noteCard(
            _english
                ? _scenario.publicEvidenceEn[index]
                : _scenario.publicEvidenceTr[index],
            icon: Icons.push_pin_rounded,
            key: ValueKey<String>('secret_room_evidence_$index'),
          ),
        ),
      ),
      const SizedBox(height: 4),
      _actionButton(
        key: const ValueKey<String>('secret_room_start_vote'),
        label: _english ? 'START SEALED BALLOT' : 'GİZLİ OYLAMAYI BAŞLAT',
        icon: Icons.how_to_vote_rounded,
        onPressed: _startVoting,
      ),
    ],
  );

  Widget _voteHandoffPanel() => Column(
    key: const ValueKey<String>('secret_room_vote_handoff'),
    children: <Widget>[
      _phaseTag(_english ? 'SEALED BALLOT' : 'KAPALI OYLAMA'),
      const SizedBox(height: 8),
      Text(
        '${_english ? 'Private vote for' : 'Gizli oy sırası'}\n${_english ? 'PLAYER' : 'OYUNCU'} ${_engine.activePlayer + 1}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _ink,
          fontSize: 21,
          height: 1.15,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      _noteCard(
        _english
            ? 'Do not show the selected suspect. Each player has one vote; self-voting is disabled.'
            : 'Seçilen kişiyi gösterme. Herkesin bir oyu var; kendine oy verilemez.',
        icon: Icons.lock_outline_rounded,
      ),
      const Spacer(),
      _actionButton(
        key: const ValueKey<String>('secret_room_open_ballot'),
        label: _english ? 'OPEN PRIVATE BALLOT' : 'GİZLİ OY PUSULASINI AÇ',
        icon: Icons.how_to_vote_rounded,
        onPressed: _openBallot,
      ),
    ],
  );

  Widget _ballotPanel() => LayoutBuilder(
    key: const ValueKey<String>('secret_room_ballot'),
    builder: (BuildContext context, BoxConstraints constraints) {
      final int current = _engine.activePlayer;
      final List<int> candidates = <int>[
        for (int player = 0; player < _playerCount; player++)
          if (player != current) player,
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _phaseTag(
            _english
                ? 'PLAYER ${current + 1} · CHOOSE ONE SUSPECT'
                : '${current + 1}. OYUNCU · BİR ŞÜPHELİ SEÇ',
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              key: const ValueKey<String>('secret_room_suspects'),
              padding: const EdgeInsets.symmetric(vertical: 2),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: candidates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 47,
                crossAxisSpacing: 6,
                mainAxisSpacing: 5,
              ),
              itemBuilder: (BuildContext context, int index) {
                final int suspect = candidates[index];
                final bool selected = suspect == _selectedSuspect;
                return OutlinedButton.icon(
                  key: ValueKey<String>('secret_room_suspect_$suspect'),
                  onPressed: () => _chooseSuspect(suspect),
                  icon: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.person_search_rounded,
                    size: 17,
                  ),
                  label: Text(
                    '${_english ? 'PLAYER' : 'OYUNCU'} ${suspect + 1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    backgroundColor: selected
                        ? const Color(0xFFF1E5D8)
                        : Colors.white,
                    side: BorderSide(
                      color: selected ? _accent : const Color(0xFFE4DED8),
                      width: selected ? 1.5 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 5),
          _actionButton(
            key: const ValueKey<String>('secret_room_submit_vote'),
            label: _english ? 'SEAL MY VOTE' : 'OYUMU KAPAT',
            icon: Icons.lock_rounded,
            onPressed: _selectedSuspect == null ? null : _submitVote,
          ),
        ],
      );
    },
  );

  Widget _resultPanel() {
    final SecretRoomOutcome outcome = _engine.outcome!;
    return Column(
      key: const ValueKey<String>('secret_room_result'),
      children: <Widget>[
        _phaseTag(_english ? 'ALL BALLOTS REVEALED' : 'TÜM OYLAR AÇILDI'),
        const SizedBox(height: 7),
        Icon(
          outcome.crewWon ? Icons.verified_rounded : Icons.policy_rounded,
          size: 37,
          color: outcome.crewWon ? const Color(0xFF43846D) : _accent,
        ),
        const SizedBox(height: 3),
        Text(
          outcome.crewWon
              ? (_english ? 'SABOTEUR CAUGHT' : 'SABOTAJCI YAKALANDI')
              : (_english ? 'THE CASE REMAINS OPEN' : 'VAKA AÇIK KALDI'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        _noteCard(
          outcome.suspect == null
              ? (_english
                    ? 'No suspect reached the required ${outcome.requiredVotes} votes.'
                    : 'Hiçbir şüpheli gereken ${outcome.requiredVotes} oya ulaşamadı.')
              : (_english
                    ? 'Player ${outcome.suspect! + 1} received ${outcome.voteCount} votes · required ${outcome.requiredVotes}.'
                    : '${outcome.suspect! + 1}. oyuncu ${outcome.voteCount} oy aldı · gereken ${outcome.requiredVotes}.'),
          icon: Icons.how_to_vote_rounded,
        ),
        const SizedBox(height: 4),
        Text(
          '${_english ? 'THE SABOTEUR WAS' : 'SABOTAJCI'} · ${_english ? 'PLAYER' : 'OYUNCU'} ${_saboteurIndex + 1}',
          key: const ValueKey<String>('secret_room_revealed_identity'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _accent,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        _actionButton(
          key: const ValueKey<String>('secret_room_finish'),
          label: _english ? 'CLOSE CASE & SCORE' : 'VAKAYI KAPAT, PUANI AL',
          icon: Icons.workspace_premium_rounded,
          onPressed: _finishCase,
        ),
      ],
    );
  }

  Widget _phaseTag(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECE5DD),
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

  Widget _noteCard(String text, {required IconData icon, Key? key}) =>
      Container(
        key: key,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E2DB)),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: _accent, size: 16),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 10,
                  height: 1.18,
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
    height: 45,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: .25,
          fontWeight: FontWeight.w900,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        disabledBackgroundColor: const Color(0xFFD8D1CA),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

class _SecretRoomPainter extends CustomPainter {
  const _SecretRoomPainter();

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
            Color(0xFF263642),
            Color(0xFF47505D),
            Color(0xFF302F3A),
          ],
        ).createShader(bounds),
    );
    final Paint table = Paint()..color = const Color(0xFF56443D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .14,
          size.height * .17,
          size.width * .72,
          size.height * .92,
        ),
        const Radius.circular(34),
      ),
      table,
    );
    final Paint rail = Paint()
      ..color = const Color(0xFF80675C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .17,
          size.height * .2,
          size.width * .66,
          size.height * .78,
        ),
        const Radius.circular(28),
      ),
      rail,
    );
    final Offset lamp = Offset(size.width * .82, size.height * .18);
    canvas.drawCircle(lamp, 26, Paint()..color = const Color(0x22F3CF98));
    canvas.drawCircle(lamp, 6, Paint()..color = const Color(0xFFF3CF98));
    final List<Offset> evidence = <Offset>[
      Offset(size.width * .33, size.height * .55),
      Offset(size.width * .50, size.height * .44),
      Offset(size.width * .65, size.height * .59),
    ];
    final Paint thread = Paint()
      ..color = const Color(0xFFC78672)
      ..strokeWidth = 1.3;
    canvas.drawLine(evidence[0], evidence[1], thread);
    canvas.drawLine(evidence[1], evidence[2], thread);
    for (int i = 0; i < evidence.length; i++) {
      final Offset center = evidence[i];
      final Rect note = Rect.fromCenter(
        center: center,
        width: size.width * .15,
        height: size.height * .23,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(note, const Radius.circular(5)),
        Paint()
          ..color = const <Color>[
            Color(0xFFE8D9C2),
            Color(0xFFDCCBB6),
            Color(0xFFF0E8DC),
          ][i],
      );
      canvas.drawLine(
        Offset(note.left + 5, note.center.dy - 2),
        Offset(note.right - 5, note.center.dy - 2),
        Paint()
          ..color = const Color(0xFF968578)
          ..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(note.left + 5, note.center.dy + 3),
        Offset(note.right - 9, note.center.dy + 3),
        Paint()
          ..color = const Color(0xFFB1A293)
          ..strokeWidth = 1,
      );
    }
    for (final Offset center in evidence) {
      canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFFB96F5E));
    }
  }

  @override
  bool shouldRepaint(covariant _SecretRoomPainter oldDelegate) => false;
}
