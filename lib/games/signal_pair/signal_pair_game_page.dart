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
import 'signal_pair_engine.dart';
import 'signal_pair_scenario.dart';

class SignalPairGamePage extends StatelessWidget {
  const SignalPairGamePage({super.key});
  static const int totalMissions = SignalPairScenario.campaignLevels;
  static const int totalStars = totalMissions * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalMissions,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Sinyal Ortağı ${level.toString().padLeft(2, '0')}',
        titleEn: 'Signal Partner ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Gezgin yolu görür; operatör panelden sırayı kurar.',
          <= 6 => 'Dört sinyal arasından doğru bağlantıyı tarif et.',
          7 || 8 => 'İleri: sekansı akılda tutup panel kablolarını eşleştir.',
          9 || 10 => 'Uzman: daha uzun diziyi hatasız aktar.',
          <= 16 => 'Usta: parazitli aktarımı ortaklaşa düzelt.',
          _ => 'Final: sekiz darbeyi koordinasyonla senkronla.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Navigator sees the route; operator programs the panel.',
          <= 6 => 'Communicate the correct relay among four signals.',
          7 || 8 => 'Advanced: remember the route and map panel wiring.',
          9 || 10 => 'Expert: transfer a longer sequence without error.',
          <= 16 => 'Master: recover a noisy transmission together.',
          _ => 'Final: synchronize eight pulses as a team.',
        },
        difficulty: switch (level) {
          <= 3 => 'ISINMA',
          <= 6 => 'İLETİŞİM',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.sensors_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'signal_pair',
      progressPrefix: 'signal_pair',
      titleTr: 'Sinyal Ortağı',
      titleEn: 'Signal Partner',
      taglineTr: 'Birlikte gör • İletişim kur • Röleyi çalıştır',
      taglineEn: 'Split information • Communicate • Restore the relay',
      accent: skin.accent,
      icon: Icons.sensors_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => SignalPairPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class SignalPairPlayPage extends StatefulWidget {
  const SignalPairPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<SignalPairPlayPage> createState() => _SignalPairPlayPageState();
}

class _SignalPairPlayPageState extends State<SignalPairPlayPage> {
  static const Color _accent = Color(0xFF537F92);
  static const Color _ink = Color(0xFF293640);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late SignalPairScenario _scenario;
  late SignalPairEngine _engine;
  late StudioGameSession _session;
  int? _practiceIndex;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareMission());
  }

  Future<void> _prepareMission() async {
    SignalPairScenario scenario = SignalPairScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String visitKey = 'signal_pair_level_${widget.level.number}_visits';
      final int visits = await prefs.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int previous =
            await prefs.getInt('signal_pair_practice_index') ?? 0;
        _practiceIndex = previous % SignalPairScenario.practiceCases + 1;
        await prefs.setInt('signal_pair_practice_index', _practiceIndex!);
        scenario = SignalPairScenario.forPractice(_practiceIndex!);
      }
      await prefs.setInt(visitKey, visits + 1);
    } catch (_) {
      // The authored relay remains ready when local storage is unavailable.
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = SignalPairEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    setState(() {
      _english = context.l10n.isEnglish;
      _feedback = _english
          ? 'Two players share one device. Keep navigator and operator screens private.'
          : 'İki oyuncu tek cihazı paylaşır. Gezgin ve operatör ekranlarını gizli tutun.';
      _ready = true;
    });
  }

  void _openNavigator() {
    if (!_engine.openNavigatorBrief()) return;
    setState(() {
      _feedback = _english
          ? 'Navigator: memorize the signal order, then pass the device.'
          : 'Gezgin: sinyal sırasını aklında tut, sonra cihazı ver.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _hideMap() {
    if (!_engine.hideNavigatorMap()) return;
    setState(() {
      _feedback = _english
          ? 'Route hidden. Explain the symbols to the operator out loud.'
          : 'Rota kapandı. Sembolleri operatöre sözlü tarif et.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .14));
  }

  void _openOperator() {
    if (!_engine.openOperatorPanel()) return;
    setState(() {
      _feedback = _english
          ? 'Operator: use the navigator’s description to program the panel.'
          : 'Operatör: paneli gezginin tarifine göre sırala.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _selectButton(int button) {
    if (_engine.selectButton(button) != SignalPairAction.selected) return;
    setState(() {
      _feedback = _english
          ? '${_engine.enteredButtons.length}/${_scenario.signalCount} pulses entered.'
          : '${_engine.enteredButtons.length}/${_scenario.signalCount} darbe girildi.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .1));
  }

  void _undo() {
    if (!_engine.undoLastSignal()) return;
    setState(() {});
    unawaited(_audio.play(GameSound.uiClick, gain: .12));
  }

  void _resetRoute() {
    if (!_engine.resetRoute()) return;
    setState(() {
      _feedback = _english ? 'Route cleared.' : 'Rota temizlendi.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .1));
  }

  void _submitRoute() {
    final SignalPairSubmission submission = _engine.submitRoute();
    if (submission.action == SignalPairAction.incomplete) {
      setState(() {
        _feedback = _english
            ? 'Enter ${_engine.requiredSignals} signals before sending.'
            : 'Göndermeden önce ${_engine.requiredSignals} sinyal gir.';
      });
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .12));
      return;
    }
    setState(() {
      _feedback = submission.solved
          ? (_english
                ? 'Synchronized · both roles restored the relay.'
                : 'Eşitlendi · iki rol röleyi birlikte onardı.')
          : (_english
                ? '${submission.correctPrefix} opening signals match. Discuss and retry.'
                : 'İlk ${submission.correctPrefix} sinyal uydu. Konuşup yeniden deneyin.');
    });
    unawaited(
      _audioProfile.play(
        _audio,
        submission.solved
            ? GameAudioEvent.levelComplete
            : GameAudioEvent.rejected,
        gain: .17,
        levelNumber: widget.level.number,
      ),
    );
    if (submission.solved) _audio.hapticLight();
  }

  Future<void> _finishMission() async {
    if (_finished || !_engine.isComplete) return;
    _finished = true;
    final int stars = _engine.mistakes == 0
        ? 3
        : (_engine.mistakes <= 2 ? 2 : 1);
    final int score = (1000 - _engine.mistakes * 105).clamp(300, 1000).toInt();
    _session.recordAccepted(points: score);
    _session.complete(
      stars: stars,
      action: widget.level.number < SignalPairGamePage.totalMissions
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    final ParkurResultAction? choice = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'RÖLE YENİDEN ÇALIŞIYOR!',
      titleEn: 'RELAY RESTORED!',
      detailTr:
          '${_scenario.signalCount} darbe · ${_engine.attempts} aktarım · iki oyuncu · puan $score',
      detailEn:
          '${_scenario.signalCount} pulses · ${_engine.attempts} transmissions · two players · score $score',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < SignalPairGamePage.totalMissions,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (choice) {
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

  IconData _icon(SignalGlyph glyph) => switch (glyph) {
    SignalGlyph.sun => Icons.wb_sunny_rounded,
    SignalGlyph.wave => Icons.water_drop_rounded,
    SignalGlyph.leaf => Icons.eco_rounded,
    SignalGlyph.spark => Icons.bolt_rounded,
  };

  Color _color(SignalGlyph glyph) => switch (glyph) {
    SignalGlyph.sun => const Color(0xFFD19A4B),
    SignalGlyph.wave => const Color(0xFF4D88A7),
    SignalGlyph.leaf => const Color(0xFF54866D),
    SignalGlyph.spark => const Color(0xFFBD7163),
  };

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          title: Text(_english ? 'SIGNAL PARTNER' : 'SİNYAL ORTAĞI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final String site = _english ? _scenario.siteEn : _scenario.siteTr;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          '${_english ? 'LINK' : 'BAĞLANTI'} ${widget.level.number.toString().padLeft(2, '0')} · $site',
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
              _relayBoard(site),
              const SizedBox(height: 7),
              Expanded(child: _phasePanel()),
              const SizedBox(height: 4),
              SizedBox(
                key: const ValueKey<String>('signal_pair_feedback'),
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

  Widget _relayBoard(String site) => Container(
    key: const ValueKey<String>('signal_pair_board'),
    height: 139,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x19293640),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const CustomPaint(painter: _SignalRelayPainter()),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.sensors_rounded,
                    color: Color(0xFFC4E3E5),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _english ? 'COOPERATIVE RELAY' : 'ORTAK RÖLE İLETİŞİMİ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE7EFF0),
                        fontSize: 9,
                        letterSpacing: .6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${_english ? 'BAND' : 'BANT'} ${(_scenario.interference + 1).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Color(0xFFC4E3E5),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                site,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _english
                    ? '${_scenario.signalCount} pulses · four cross-wired channels · two roles'
                    : '${_scenario.signalCount} darbe · dört çapraz bağlı kanal · iki rol',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD7E3E3),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _phasePanel() => switch (_engine.phase) {
    SignalPairPhase.navigatorHandoff => _navigatorHandoff(),
    SignalPairPhase.navigatorBrief => _navigatorBrief(),
    SignalPairPhase.operatorHandoff => _operatorHandoff(),
    SignalPairPhase.operatorPanel => _operatorPanel(),
    SignalPairPhase.result => _resultPanel(),
  };

  Widget _navigatorHandoff() => Column(
    key: const ValueKey<String>('signal_pair_navigator_handoff'),
    children: <Widget>[
      _phaseTag(_english ? 'ROLE 1 · NAVIGATOR' : '1. ROL · GEZGİN'),
      const SizedBox(height: 8),
      Text(
        _english
            ? 'Player 1 sees the route.'
            : 'Rota bilgisini Oyuncu 1 görür.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 7),
      _noteCard(
        _english
            ? 'Player 2 must not see the next screen. Memorize the signal order; speaking is allowed.'
            : 'Oyuncu 2 sonraki ekranı görmemeli. Sinyal sırasını öğren; sözlü tarif serbest.',
        icon: Icons.visibility_off_rounded,
      ),
      const Spacer(),
      _actionButton(
        key: const ValueKey<String>('signal_pair_open_map'),
        label: _english ? 'OPEN PRIVATE MAP' : 'GİZLİ HARİTAYI AÇ',
        icon: Icons.map_rounded,
        onPressed: _openNavigator,
      ),
    ],
  );

  Widget _navigatorBrief() => Column(
    key: const ValueKey<String>('signal_pair_navigator_brief'),
    children: <Widget>[
      _phaseTag(
        _english ? 'PRIVATE MAP · PLAYER 1' : 'GİZLİ HARİTA · OYUNCU 1',
      ),
      const SizedBox(height: 4),
      Expanded(
        child: Center(
          child: Container(
            key: const ValueKey<String>('signal_pair_private_route'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF263943),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF96BEC0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _english
                      ? 'TRANSMIT THESE PULSES IN ORDER'
                      : 'DARBELERİ BU SIRAYLA AKTAR',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC4E3E5),
                    fontSize: 9,
                    letterSpacing: .55,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  key: const ValueKey<String>('signal_pair_route_tokens'),
                  alignment: WrapAlignment.center,
                  spacing: 5,
                  runSpacing: 7,
                  children: <Widget>[
                    for (int i = 0; i < _engine.navigatorRoute.length; i++)
                      _routeToken(i + 1, _engine.navigatorRoute[i], dark: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _english
                      ? 'Name each signal clearly; the panel order is shuffled.'
                      : 'Sinyalleri açıkça tarif et; panel bağlantı sırası karışık.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE0E9E7),
                    fontSize: 9,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 5),
      _actionButton(
        key: const ValueKey<String>('signal_pair_hide_map'),
        label: _english
            ? 'HIDE MAP & PASS DEVICE'
            : 'HARİTAYI KAPAT, CİHAZI VER',
        icon: Icons.screen_lock_portrait_rounded,
        onPressed: _hideMap,
      ),
    ],
  );

  Widget _operatorHandoff() => Column(
    key: const ValueKey<String>('signal_pair_operator_handoff'),
    children: <Widget>[
      _phaseTag(_english ? 'ROLE 2 · OPERATOR' : '2. ROL · OPERATÖR'),
      const SizedBox(height: 8),
      Text(
        _english
            ? 'Player 2 takes the controls.'
            : 'Kontrol paneli Oyuncu 2’de.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 7),
      _noteCard(
        _english
            ? 'The route is hidden now. Ask your partner if a signal description was unclear.'
            : 'Rota artık gizli. Sinyal tarifi anlaşılmadıysa eşine sorabilirsin.',
        icon: Icons.forum_rounded,
      ),
      const Spacer(),
      _actionButton(
        key: const ValueKey<String>('signal_pair_open_panel'),
        label: _english ? 'OPEN CONTROL PANEL' : 'KONTROL PANELİNİ AÇ',
        icon: Icons.tune_rounded,
        onPressed: _openOperator,
      ),
    ],
  );

  Widget _operatorPanel() {
    final List<SignalGlyph> wiring = _engine.operatorWiring;
    return Column(
      key: const ValueKey<String>('signal_pair_operator_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _phaseTag(
          _english ? 'CONTROL PANEL · PLAYER 2' : 'KONTROL PANELİ · OYUNCU 2',
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _english
                    ? 'Follow the navigator’s signal names.'
                    : 'Gezginin sinyal adlarını takip et.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${_engine.enteredButtons.length}/${_scenario.signalCount}',
              key: const ValueKey<String>('signal_pair_route_progress'),
              style: const TextStyle(
                color: _accent,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 50,
          child: Center(
            child: Wrap(
              key: const ValueKey<String>('signal_pair_operator_input'),
              alignment: WrapAlignment.center,
              spacing: 3,
              runSpacing: 2,
              children: <Widget>[
                for (int i = 0; i < _engine.enteredButtons.length; i++)
                  _routeToken(
                    i + 1,
                    wiring[_engine.enteredButtons[i]],
                    dark: false,
                  ),
                for (
                  int i = _engine.enteredButtons.length;
                  i < _scenario.signalCount;
                  i++
                )
                  _emptyRouteToken(i + 1),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            key: const ValueKey<String>('signal_pair_controls'),
            padding: const EdgeInsets.symmetric(vertical: 2),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: wiring.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 53,
              crossAxisSpacing: 6,
              mainAxisSpacing: 5,
            ),
            itemBuilder: (BuildContext context, int index) {
              final SignalGlyph signal = wiring[index];
              return OutlinedButton.icon(
                key: ValueKey<String>('signal_pair_button_$index'),
                onPressed: _engine.enteredButtons.length < _scenario.signalCount
                    ? () => _selectButton(index)
                    : null,
                icon: Icon(_icon(signal), color: _color(signal), size: 19),
                label: Text(
                  signal.label(_english),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE0E6E4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            IconButton.filledTonal(
              key: const ValueKey<String>('signal_pair_undo'),
              tooltip: _english ? 'Undo signal' : 'Sinyali geri al',
              onPressed: _engine.enteredButtons.isEmpty ? null : _undo,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.undo_rounded, size: 16),
            ),
            IconButton.filledTonal(
              key: const ValueKey<String>('signal_pair_reset'),
              tooltip: _english ? 'Clear route' : 'Rotayı temizle',
              onPressed: _engine.enteredButtons.isEmpty ? null : _resetRoute,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
            ),
            const Spacer(),
            SizedBox(
              width: 146,
              height: 41,
              child: FilledButton.icon(
                key: const ValueKey<String>('signal_pair_submit'),
                onPressed:
                    _engine.enteredButtons.length == _scenario.signalCount
                    ? _submitRoute
                    : null,
                icon: const Icon(Icons.send_rounded, size: 15),
                label: Text(
                  _english ? 'SEND SEQUENCE' : 'SIRAYI GÖNDER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: const Color(0xFFD8E0DE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resultPanel() => Column(
    key: const ValueKey<String>('signal_pair_result'),
    children: <Widget>[
      _phaseTag(
        _english
            ? 'SYNC VERIFIED · BOTH ROLES'
            : 'SENKRON DOĞRULANDI · İKİ ROL',
      ),
      const SizedBox(height: 6),
      Icon(Icons.hub_rounded, size: 38, color: _accent),
      const SizedBox(height: 4),
      Text(
        _english ? 'THE RELAY IS STABLE' : 'RÖLE DENGELİ ÇALIŞIYOR',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 5),
      Wrap(
        key: const ValueKey<String>('signal_pair_revealed_route'),
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          for (int i = 0; i < _scenario.targetRoute.length; i++)
            _routeToken(i + 1, _scenario.targetRoute[i], dark: false),
        ],
      ),
      const SizedBox(height: 6),
      _noteCard(
        _engine.mistakes == 0
            ? (_english
                  ? 'Perfect transfer · no correction needed.'
                  : 'Kusursuz aktarım · düzeltme gerekmedi.')
            : (_english
                  ? '${_engine.mistakes} correction(s) · teamwork restored the shared route.'
                  : '${_engine.mistakes} düzeltme · ortak çalışmayla rota kuruldu.'),
        icon: Icons.verified_rounded,
      ),
      const Spacer(),
      _actionButton(
        key: const ValueKey<String>('signal_pair_finish'),
        label: _english ? 'COMPLETE RELAY MISSION' : 'RÖLE GÖREVİNİ TAMAMLA',
        icon: Icons.workspace_premium_rounded,
        onPressed: _finishMission,
      ),
    ],
  );

  Widget _routeToken(int number, SignalGlyph signal, {required bool dark}) =>
      Container(
        key: ValueKey<String>('signal_pair_token_${number}_${signal.name}'),
        width: 31,
        height: 31,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF364D56) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: dark ? const Color(0xFF718C91) : const Color(0xFFE2E8E6),
          ),
        ),
        child: Stack(
          children: <Widget>[
            Center(child: Icon(_icon(signal), color: _color(signal), size: 17)),
            Positioned(
              right: 3,
              top: 1,
              child: Text(
                '$number',
                style: TextStyle(
                  color: dark ? const Color(0xFFDDE7E5) : StudioVisuals.muted,
                  fontSize: 6,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _emptyRouteToken(int number) => Container(
    key: ValueKey<String>('signal_pair_empty_$number'),
    width: 31,
    height: 31,
    decoration: BoxDecoration(
      color: const Color(0xFFEEF2F0),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFD8E0DE)),
    ),
    child: Center(
      child: Text(
        '$number',
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );

  Widget _phaseTag(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3ECEB),
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
      border: Border.all(color: const Color(0xFFE1E8E5)),
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
              height: 1.16,
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
    required VoidCallback onPressed,
  }) => SizedBox(
    key: key,
    width: double.infinity,
    height: 43,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 9,
          letterSpacing: .25,
          fontWeight: FontWeight.w900,
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

class _SignalRelayPainter extends CustomPainter {
  const _SignalRelayPainter();

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
            Color(0xFF243943),
            Color(0xFF38545D),
            Color(0xFF263B45),
          ],
        ).createShader(bounds),
    );
    final Paint grid = Paint()
      ..color = const Color(0x1437B7C0)
      ..strokeWidth = .6;
    for (double x = 14; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 12; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final List<Offset> nodes = <Offset>[
      Offset(size.width * .16, size.height * .76),
      Offset(size.width * .37, size.height * .36),
      Offset(size.width * .61, size.height * .71),
      Offset(size.width * .84, size.height * .35),
    ];
    final Paint wire = Paint()
      ..color = const Color(0xFF7FA5A5)
      ..strokeWidth = 2;
    for (int i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], wire);
    }
    final List<Color> colors = <Color>[
      const Color(0xFFD19A4B),
      const Color(0xFF4D88A7),
      const Color(0xFF54866D),
      const Color(0xFFBD7163),
    ];
    for (int i = 0; i < nodes.length; i++) {
      canvas.drawCircle(nodes[i], 9, Paint()..color = const Color(0x223DE5E0));
      canvas.drawCircle(nodes[i], 3.8, Paint()..color = colors[i]);
    }
    final Paint glow = Paint()..color = const Color(0x22C4E3E5);
    canvas.drawCircle(Offset(size.width * .9, size.height * .2), 23, glow);
    canvas.drawCircle(
      Offset(size.width * .9, size.height * .2),
      5,
      Paint()..color = const Color(0xFFC4E3E5),
    );
  }

  @override
  bool shouldRepaint(covariant _SignalRelayPainter oldDelegate) => false;
}
