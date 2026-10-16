import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'deep_current_engine.dart';
import 'deep_current_scenario.dart';

class DeepCurrentGamePage extends StatelessWidget {
  const DeepCurrentGamePage({super.key});

  static const int totalCases = DeepCurrentScenario.campaignLevels;
  static const int totalStars = totalCases * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Dalış ${level.toString().padLeft(2, '0')}',
        titleEn: 'Dive ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Sonar ile enkazı tara; yükü al ve üsse dön.',
          <= 6 => 'Kaya sırtlarından kaçın, akıntının yönünü oku.',
          7 || 8 => 'İleri: iki parçayı farklı derinliklerde kurtar.',
          9 || 10 => 'Uzman: dört kaynağı dönüş payı bırakarak yönet.',
          <= 16 => 'Usta: güçlü akıntılar ve daha hassas gövde sınırı.',
          _ => 'Final dalışı: dört ağır yük, dar kaynak marjı.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Sweep with sonar, recover the wreck and return to base.',
          <= 6 => 'Clear the reef ridges and read the current direction.',
          7 || 8 => 'Advanced: recover two fragments at different depths.',
          9 ||
          10 => 'Expert: budget four systems while saving return reserves.',
          <= 16 => 'Master: stronger currents and a tighter hull margin.',
          _ => 'Final dive: four heavy loads and narrow resource margins.',
        },
        difficulty: switch (level) {
          <= 3 => 'KEŞİF',
          <= 6 => 'AKINTI',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.sailing_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'deep_current',
      progressPrefix: 'deep_current',
      titleTr: 'Derin Akıntı',
      titleEn: 'Deep Current',
      taglineTr: 'Sonar tara • Yükü kurtar • Üsse dön',
      taglineEn: 'Ping • Salvage • Return to base',
      accent: skin.accent,
      icon: Icons.sailing_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => DeepCurrentPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class DeepCurrentPlayPage extends StatefulWidget {
  const DeepCurrentPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<DeepCurrentPlayPage> createState() => _DeepCurrentPlayPageState();
}

class _DeepCurrentPlayPageState extends State<DeepCurrentPlayPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _accent = Color(0xFF377E8E);
  static const Color _ink = Color(0xFF344A53);
  static const Color _amber = Color(0xFFC89859);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late final Ticker _ticker;
  late DeepCurrentScenario _scenario;
  late DeepCurrentEngine _engine;
  late StudioGameSession _session;
  Duration _lastTick = Duration.zero;
  final Set<String> _heldDirections = <String>{};
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  bool _warningShown = false;
  String _feedback = '';

  Offset get _steering => Offset(
    (_heldDirections.contains('right') ? 1 : 0) -
        (_heldDirections.contains('left') ? 1 : 0),
    (_heldDirections.contains('down') ? 1 : 0) -
        (_heldDirections.contains('up') ? 1 : 0),
  );

  int get _score =>
      (_engine.collectedTargets.fold<int>(
                0,
                (int total, int index) =>
                    total + _scenario.salvage[index].value,
              ) +
              _engine.oxygen.round() * 2 +
              _engine.battery.round() * 2 +
              _engine.hull.round() * 4 +
              (_engine.completed ? 600 : 0))
          .clamp(0, 10000000)
          .toInt();

  int get _stars =>
      _engine.hull >= 78 &&
          _engine.oxygen > _scenario.oxygenCapacity * .35 &&
          _engine.battery > _scenario.batteryCapacity * .3
      ? 3
      : _engine.hull >= 48
      ? 2
      : 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareMission());
  }

  Future<void> _prepareMission() async {
    DeepCurrentScenario scenario = DeepCurrentScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'deep_current_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('deep_current_practice_index') ?? 0;
        if (index < DeepCurrentScenario.practiceMissions) {
          final int next = index + 1;
          await preferences.setInt('deep_current_practice_index', next);
          scenario = DeepCurrentScenario.forPracticeMission(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // The authored mission remains playable when preferences are unavailable.
    }
    if (!mounted) return;
    _scenario = scenario;
    _resetMission();
    setState(() => _ready = true);
    _ticker.start();
  }

  void _resetMission() {
    _engine = DeepCurrentEngine(scenario: _scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _finished = false;
    _paused = false;
    _warningShown = false;
    _feedback = _english
        ? 'Hold a direction to pilot. Sonar reveals nearby cargo; keep a return reserve.'
        : 'Yön tuşunu basılı tut. Sonar yakındaki yükü gösterir; dönüş payını koru.';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_ready && !_paused && !_finished) _setPaused(true);
    } else if (state == AppLifecycleState.resumed && _paused && !_finished) {
      _setPaused(false);
    }
  }

  void _setPaused(bool value) {
    if (!_ready || _finished || _paused == value) return;
    setState(() {
      _paused = value;
      _heldDirections.clear();
      _feedback = value
          ? (_english
                ? 'MISSION PAUSED · SYSTEMS STABLE'
                : 'GÖREV DURAKLATILDI · SİSTEMLER SABİT')
          : (_english
                ? 'DIVE RESUMED · WATCH DEPTH AND POWER'
                : 'DALIŞ SÜRÜYOR · DERİNLİK VE GÜCÜ İZLE');
    });
    if (value) {
      _ticker.stop();
      _session.pause();
    } else {
      _session.resume();
      _lastTick = Duration.zero;
      _ticker.start();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .2));
  }

  void _tick(Duration elapsed) {
    if (!_ready || _paused || _finished) return;
    final double raw = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (raw <= 0) return;
    final DeepCurrentStepResult result = _engine.step(
      raw.clamp(0, .05).toDouble(),
      _steering,
    );
    if (result.collision) {
      _session.recordMistake();
      _feedback = _english
          ? 'REEF CONTACT · BACK OFF AND RE-ORIENT'
          : 'KAYAYA TEMAS · GERİ AÇIL VE YÖNÜNÜ DÜZELT';
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .2));
      _audio.hapticLight();
    } else if (result.resourceWarning && !_warningShown) {
      _warningShown = true;
      _feedback = _english
          ? 'SYSTEM RESERVE LOW · TURN HOME IF THE RETURN MARGIN IS TIGHT'
          : 'KAYNAK PAYI AZ · DÖNÜŞ MARJI DARSA ÜSSE YÖNEL';
    }
    setState(() {});
    if (result.failed) unawaited(_offerRetry());
  }

  void _setDirection(String direction, bool held) {
    if (_paused || _finished || !_ready) return;
    setState(() {
      if (held) {
        _heldDirections.add(direction);
      } else {
        _heldDirections.remove(direction);
      }
    });
    if (held) {
      unawaited(
        _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .06),
      );
    }
  }

  void _ping() {
    if (!_session.canUseHint) return;
    final DeepCurrentActionResult result = _engine.ping();
    if (!result.accepted) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .16));
      setState(
        () => _feedback = _english
            ? 'SONAR RECHARGING OR BATTERY TOO LOW'
            : 'SONAR ŞARJ OLUYOR VEYA BATARYA DÜŞÜK',
      );
      return;
    }
    _session.useHint();
    _session.recordAccepted(points: result.revealed * 5);
    setState(
      () => _feedback = result.revealed == 0
          ? (_english
                ? 'CLEAR PING · MOVE CLOSER TO THE SEARCH ZONE'
                : 'SONAR TEMİZ · ARAMA ALANINA YAKLAŞ')
          : (_english
                ? '${result.revealed} CONTACT${result.revealed == 1 ? '' : 'S'} · HOLD TO APPROACH'
                : '${result.revealed} SİNYAL · YAKLAŞMAK İÇİN YÖNÜ BASILI TUT'),
    );
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .2));
    _audio.hapticLight();
  }

  void _collect() {
    final DeepCurrentActionResult result = _engine.collect();
    if (!result.accepted) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .15));
      setState(
        () => _feedback = _english
            ? 'NO SCANNED CARGO IN GRAB RANGE'
            : 'KAVRAMA MENZİLİNDE TARAMA YAPILMIŞ YÜK YOK',
      );
      return;
    }
    _session.recordAccepted(points: 90);
    setState(
      () => _feedback = _english
          ? '${_engine.collectedCount}/${_scenario.salvage.length} CARGO SECURED · KEEP A PATH TO BASE'
          : '${_engine.collectedCount}/${_scenario.salvage.length} YÜK GÜVENDE · ÜS ROTASINI AÇIK TUT',
    );
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .23));
    _audio.hapticLight();
  }

  void _dock() {
    final DeepCurrentActionResult result = _engine.dock();
    if (!result.docked) {
      setState(
        () => _feedback = !_engine.allCollected
            ? (_english
                  ? 'SALVAGE ALL MARKED CARGO BEFORE RETURNING'
                  : 'DÖNMEDEN ÖNCE İŞARETLİ TÜM YÜKÜ AL')
            : (_english
                  ? 'DOCKING RANGE · ${(_engine.dockDistance * 100).round()} m'
                  : 'ÜS MENZİLİ · ${(_engine.dockDistance * 100).round()} m'),
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .14));
      return;
    }
    _session.recordAccepted(points: 150);
    setState(
      () => _feedback = _english
          ? 'DOCKING SEQUENCE COMPLETE'
          : 'ÜSLE KENETLENME TAMAM',
    );
    _ticker.stop();
    unawaited(_finishMission());
  }

  Future<void> _offerRetry() async {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker.stop();
    _session.fail();
    final bool retry =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(_english ? 'DIVE ABORTED' : 'DALIŞ SONLANDI'),
            content: Text(
              _english
                  ? 'The sonar, current and depth bands are all visible. Use short steering corrections, scan before grabbing and leave power for the trip home.'
                  : 'Sonar, akıntı ve derinlik bantları görünür. Kısa yön düzeltmeleri yap, kavramadan önce tara ve dönüş için güç bırak.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_english ? 'MAP' : 'HARİTA'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(_english ? 'RETRY' : 'YENİDEN DENE'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted) return;
    if (retry) {
      setState(() {
        _resetMission();
        _ticker.start();
      });
    } else {
      Navigator.of(context)
          .pop(StudioGameResult.failed(score: _score).toParkurResult());
    }
  }

  Future<void> _finishMission() async {
    if (_finished || !mounted) return;
    _finished = true;
    _session.complete(
      stars: _stars,
      action: widget.level.number < DeepCurrentGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'KURTARMA TAMAMLANDI',
      titleEn: 'SALVAGE COMPLETE',
      detailTr:
          '${_engine.collectedCount} yük · ${_engine.hull.round()} gövde · ${_engine.oxygen.round()} oksijen kaldı',
      detailEn:
          '${_engine.collectedCount} cargo · ${_engine.hull.round()} hull · ${_engine.oxygen.round()} oxygen left',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < DeepCurrentGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: _score,
        stars: _stars,
        action: action,
      ).toParkurResult(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(title: Text(_english ? 'DEEP CURRENT' : 'DERİN AKINTI')),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final bool disabled = _paused || _finished;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          _english
              ? 'DEEP CURRENT · DIVE ${widget.level.number}'
              : 'DERİN AKINTI · DALIŞ ${widget.level.number}',
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('deep_current_pause'),
            tooltip: _paused
                ? (_english ? 'Resume' : 'Devam et')
                : (_english ? 'Pause' : 'Duraklat'),
            onPressed: () => _setPaused(!_paused),
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Column(
            children: <Widget>[
              _buildHud(),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: Text(
                  _feedback,
                  key: const ValueKey<String>('deep_current_feedback'),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.42,
                    child: RepaintBoundary(
                      key: const ValueKey<String>('deep_current_ocean'),
                      child: CustomPaint(
                        painter: _DeepCurrentPainter(engine: _engine),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildControls(disabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Container(
      key: const ValueKey<String>('deep_current_hud'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E9E7)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _ink.withValues(alpha: .05),
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _resourceMeter(
            Icons.air_rounded,
            _engine.oxygen,
            _scenario.oxygenCapacity,
            const Color(0xFF4E9E9B),
          ),
          const SizedBox(width: 7),
          _resourceMeter(
            Icons.battery_charging_full_rounded,
            _engine.battery,
            _scenario.batteryCapacity,
            _amber,
          ),
          const SizedBox(width: 7),
          _resourceMeter(
            Icons.shield_outlined,
            _engine.hull,
            _scenario.hullCapacity,
            _engine.hull < 48 ? const Color(0xFFC66C5D) : _accent,
          ),
          const SizedBox(width: 7),
          Container(width: 1, height: 29, color: const Color(0xFFE5E8E4)),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${_engine.collectedCount}/${_scenario.salvage.length}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _english ? 'CARGO' : 'YÜK',
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resourceMeter(IconData icon, double value, double max, Color color) {
    final double fraction = (value / max).clamp(0, 1).toDouble();
    return Expanded(
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 3),
              Text(
                value.round().toString(),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFeatures: <ui.FontFeature>[
                    ui.FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: const Color(0xFFE9ECE8),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(bool disabled) {
    Widget hold(String direction, IconData icon, String key) =>
        _HoldDirectionButton(
          key: ValueKey<String>(key),
          icon: icon,
          enabled: !disabled,
          onChanged: (bool held) => _setDirection(direction, held),
        );
    Widget action(
      String label,
      IconData icon,
      String key,
      VoidCallback callback, {
      bool enabled = true,
      bool primary = false,
    }) => Expanded(
      child: SizedBox(
        height: 56,
        child: FilledButton.tonal(
          key: ValueKey<String>(key),
          onPressed: disabled || !enabled ? null : callback,
          style: FilledButton.styleFrom(
            backgroundColor: primary ? _accent : Colors.white,
            foregroundColor: primary ? Colors.white : _ink,
            disabledBackgroundColor: const Color(0xFFE9EBE8),
            disabledForegroundColor: const Color(0xFF9A9E9A),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: primary ? _accent : const Color(0xFFE2E6E2),
              ),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 18),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Row(
      children: <Widget>[
        SizedBox(
          width: 100,
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  hold(
                    'up',
                    Icons.keyboard_arrow_up_rounded,
                    'deep_current_up',
                  ),
                  const SizedBox(width: 4),
                  hold(
                    'down',
                    Icons.keyboard_arrow_down_rounded,
                    'deep_current_down',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  hold('left', Icons.chevron_left_rounded, 'deep_current_left'),
                  const SizedBox(width: 4),
                  hold(
                    'right',
                    Icons.chevron_right_rounded,
                    'deep_current_right',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Row(
            children: <Widget>[
              action(
                _english ? 'PING' : 'SONAR',
                Icons.radar_rounded,
                'deep_current_ping',
                _ping,
                enabled: _engine.canPing,
              ),
              const SizedBox(width: 6),
              action(
                _english ? 'GRAB' : 'KAVRA',
                Icons.backpack_outlined,
                'deep_current_collect',
                _collect,
                enabled: _engine.revealedTargets.any(
                  (int index) =>
                      (_scenario.salvage[index].position - _engine.position)
                          .distance <=
                      .09,
                ),
              ),
              const SizedBox(width: 6),
              action(
                _english ? 'DOCK' : 'ÜSSE DÖN',
                Icons.anchor_rounded,
                'deep_current_dock',
                _dock,
                enabled: _engine.allCollected && _engine.dockDistance <= .18,
                primary: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HoldDirectionButton extends StatefulWidget {
  const _HoldDirectionButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  State<_HoldDirectionButton> createState() => _HoldDirectionButtonState();
}

class _HoldDirectionButtonState extends State<_HoldDirectionButton> {
  bool _pressed = false;

  void _set(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
    widget.onChanged(value);
  }

  @override
  void didUpdateWidget(covariant _HoldDirectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pressed) {
      _pressed = false;
      widget.onChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 48,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFD8E8E4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pressed ? const Color(0xFF90B8B1) : const Color(0xFFE0E5E1),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF31474E).withValues(alpha: .05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          size: 20,
          color: widget.enabled
              ? const Color(0xFF385660)
              : const Color(0xFF9A9E9A),
        ),
      ),
    ),
  );
}

class _DeepCurrentPainter extends CustomPainter {
  const _DeepCurrentPainter({required this.engine});

  final DeepCurrentEngine engine;
  static const Color _teal = Color(0xFF6CA8A5);
  static const Color _sand = Color(0xFFD6C5A5);
  static const Color _gold = Color(0xFFD2A75D);
  static const Color _ink = Color(0xFF2C4C56);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final RRect clip = RRect.fromRectAndRadius(
      bounds,
      const Radius.circular(22),
    );
    canvas.drawRRect(clip, Paint()..color = const Color(0xFFD8E2DE));
    canvas.save();
    canvas.clipRRect(clip);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF9FD0C9),
            Color(0xFF4E98A0),
            Color(0xFF266274),
            Color(0xFF173E51),
          ],
        ).createShader(bounds),
    );
    _drawDepthBands(canvas, size);
    _drawCaustics(canvas, size);
    for (int index = 0; index < engine.scenario.currents.length; index++) {
      _drawCurrent(canvas, size, engine.scenario.currents[index], index);
    }
    for (int index = 0; index < engine.scenario.reefs.length; index++) {
      _drawReef(canvas, size, engine.scenario.reefs[index], index);
    }
    _drawBase(canvas, size);
    for (final int index in engine.revealedTargets) {
      _drawCargo(canvas, size, engine.scenario.salvage[index], engine.elapsed);
    }
    _drawSubmarine(canvas, size);
    _drawSonar(canvas, size);
    _drawHudScale(canvas, size);
    canvas.restore();
  }

  Offset _map(Offset point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  void _drawDepthBands(Canvas canvas, Size size) {
    for (int index = 0; index < 5; index++) {
      final double y = size.height * (.55 + index * .078);
      final Path band = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(
          size.width * .28,
          y - 10 - index * 2,
          size.width * .53,
          y + 4,
        )
        ..quadraticBezierTo(size.width * .77, y + 14, size.width, y - 4)
        ..lineTo(size.width, y + size.height * .045)
        ..quadraticBezierTo(
          size.width * .68,
          y + size.height * .065,
          size.width * .38,
          y + size.height * .038,
        )
        ..quadraticBezierTo(
          size.width * .14,
          y + size.height * .025,
          0,
          y + size.height * .055,
        )
        ..close();
      canvas.drawPath(
        band,
        Paint()..color = _sand.withValues(alpha: .045 + index * .008),
      );
    }
  }

  void _drawCaustics(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = Colors.white.withValues(alpha: .14)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int index = 0; index < 8; index++) {
      final double x = size.width * (.05 + index * .13);
      final Path path = Path()
        ..moveTo(x, 0)
        ..cubicTo(
          x - 14,
          size.height * .12,
          x + 23,
          size.height * .20,
          x + 5,
          size.height * .34,
        );
      canvas.drawPath(path, line);
    }
    final Paint speck = Paint()..color = Colors.white.withValues(alpha: .28);
    for (int index = 0; index < 36; index++) {
      final double x = size.width * ((index * 37 % 97) / 100);
      final double y = size.height * ((index * 53 % 89) / 100);
      canvas.drawCircle(Offset(x, y), 1 + index % 2 * .5, speck);
    }
  }

  void _drawCurrent(Canvas canvas, Size size, DeepCurrentFlow flow, int index) {
    final Offset center = _map(flow.center, size);
    final double radius = flow.radius * size.width;
    final Rect area = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            _teal.withValues(alpha: .15),
            const Color(0x004DB5B5),
          ],
        ).createShader(area),
    );
    final double angle = math.atan2(flow.force.dy, flow.force.dx);
    final Path sweep = Path()
      ..addArc(area.deflate(radius * .14), angle + index * .35, math.pi * 1.22);
    canvas.drawPath(
      sweep,
      Paint()
        ..color = Colors.white.withValues(alpha: .36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    for (int arrow = -1; arrow <= 1; arrow++) {
      final Offset pos =
          center +
          Offset(
            math.cos(angle) * radius * .48,
            math.sin(angle) * radius * .48,
          ) +
          Offset(-math.sin(angle), math.cos(angle)) *
              arrow.toDouble() *
              radius *
              .18;
      _drawArrow(
        canvas,
        pos,
        angle,
        Colors.white.withValues(alpha: .56),
        size.width * .014,
      );
    }
  }

  void _drawArrow(
    Canvas canvas,
    Offset center,
    double angle,
    Color color,
    double scale,
  ) {
    final Offset direction = Offset(math.cos(angle), math.sin(angle));
    final Offset side = Offset(-direction.dy, direction.dx);
    final Path path = Path()
      ..moveTo(
        center.dx + direction.dx * scale,
        center.dy + direction.dy * scale,
      )
      ..lineTo(
        center.dx - direction.dx * scale * .75 + side.dx * scale * .58,
        center.dy - direction.dy * scale * .75 + side.dy * scale * .58,
      )
      ..lineTo(
        center.dx - direction.dx * scale * .75 - side.dx * scale * .58,
        center.dy - direction.dy * scale * .75 - side.dy * scale * .58,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawReef(Canvas canvas, Size size, DeepCurrentReef reef, int index) {
    final Offset center = _map(reef.center, size);
    final double radius = reef.radius * size.width;
    final Rect shape = Rect.fromCircle(center: center, radius: radius);
    canvas.drawOval(
      shape.translate(0, radius * .34),
      Paint()..color = const Color(0x4030444B),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.4, -.55),
          colors: <Color>[
            const Color(0xFF9EAC9B),
            Color.lerp(
              const Color(0xFF667E7A),
              const Color(0xFF394E58),
              index.isEven ? .15 : .55,
            )!,
          ],
        ).createShader(shape),
    );
    canvas.drawArc(
      shape.deflate(radius * .12),
      3.45,
      2.4,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .12,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-radius * .2, 0),
        width: radius * .28,
        height: radius * .13,
      ),
      Paint()..color = const Color(0xFF45675F).withValues(alpha: .65),
    );
  }

  void _drawBase(Canvas canvas, Size size) {
    final Offset center = _map(DeepCurrentScenario.base, size);
    final double scale = size.shortestSide;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, scale * .022),
        width: scale * .12,
        height: scale * .045,
      ),
      Paint()..color = const Color(0x45304149),
    );
    final Rect dock = Rect.fromCenter(
      center: center,
      width: scale * .105,
      height: scale * .085,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(dock, Radius.circular(scale * .018)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFE6E1D4), Color(0xFF8C9B99)],
        ).createShader(dock),
    );
    canvas.drawLine(
      Offset(dock.left + 5, dock.center.dy),
      Offset(dock.right - 5, dock.center.dy),
      Paint()
        ..color = _gold
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center + Offset(scale * .034, -scale * .022),
      scale * .007,
      Paint()..color = const Color(0xFF93D7C1),
    );
  }

  void _drawCargo(
    Canvas canvas,
    Size size,
    DeepCurrentSalvage cargo,
    double time,
  ) {
    final Offset center = _map(cargo.position, size);
    final double scale = size.shortestSide;
    final double pulse = .5 + .5 * math.sin(time * 2.5 + cargo.value);
    canvas.drawCircle(
      center,
      scale * (.035 + pulse * .008),
      Paint()..color = _gold.withValues(alpha: .17 + pulse * .12),
    );
    final Rect box = Rect.fromCenter(
      center: center,
      width: scale * .048,
      height: scale * .04,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        box.translate(0, scale * .008),
        Radius.circular(scale * .007),
      ),
      Paint()..color = const Color(0x4730444A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(scale * .007)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFE9D9B8), Color(0xFFAC8652)],
        ).createShader(box),
    );
    canvas.drawLine(
      Offset(box.left + 1, center.dy),
      Offset(box.right - 1, center.dy),
      Paint()
        ..color = const Color(0xFF765F3F)
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(
      center,
      scale * .046,
      Paint()
        ..color = _gold.withValues(alpha: .48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  void _drawSubmarine(Canvas canvas, Size size) {
    final Offset center = _map(engine.position, size);
    final double angle = engine.velocity.distance > .012
        ? math.atan2(engine.velocity.dy, engine.velocity.dx)
        : 0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final double length = size.shortestSide * .078;
    final double height = length * .48;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, height * .48),
        width: length * 1.15,
        height: height * .72,
      ),
      Paint()..color = const Color(0x48314349),
    );
    final RRect hull = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: length, height: height),
      Radius.circular(height * .5),
    );
    canvas.drawRRect(
      hull,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFE9F0E7),
            Color(0xFF7D9C99),
            Color(0xFF45646B),
          ],
        ).createShader(hull.outerRect),
    );
    canvas.drawRRect(
      hull,
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      Offset(length * .17, 0),
      height * .17,
      Paint()..color = const Color(0xFFB4DAD1),
    );
    canvas.drawCircle(
      Offset(length * .17, 0),
      height * .17,
      Paint()
        ..color = const Color(0xFF315E68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-length * .23, -height * .38),
          width: length * .20,
          height: height * .42,
        ),
        Radius.circular(2),
      ),
      Paint()..color = _ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-length * .39, 0)
        ..lineTo(-length * .57, -height * .35)
        ..lineTo(-length * .57, height * .35)
        ..close(),
      Paint()..color = const Color(0xFF62837F),
    );
    canvas.restore();
    if (engine.velocity.distance > .025) {
      canvas.drawCircle(
        center - Offset(math.cos(angle), math.sin(angle)) * length * .62,
        length * .10,
        Paint()..color = Colors.white.withValues(alpha: .22),
      );
    }
  }

  void _drawSonar(Canvas canvas, Size size) {
    final Offset center = _map(engine.position, size);
    final double progress = (engine.pingCooldown / 2.4).clamp(0, 1).toDouble();
    final double radius =
        size.width * (engine.scenario.sonarRange * (1 - progress * .22));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: .055)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.drawCircle(
      center,
      radius * .68,
      Paint()
        ..color = Colors.white.withValues(alpha: .035)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
  }

  void _drawHudScale(Canvas canvas, Size size) {
    final double depth = engine.depth;
    final double y = size.height * (.07 + depth * .48);
    final Offset point = Offset(size.width - 12, y);
    canvas.drawLine(
      Offset(size.width - 12, size.height * .07),
      Offset(size.width - 12, size.height * .55),
      Paint()
        ..color = Colors.white.withValues(alpha: .5)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(point, 4, Paint()..color = _gold);
  }

  @override
  bool shouldRepaint(covariant _DeepCurrentPainter oldDelegate) =>
      oldDelegate.engine != engine ||
      oldDelegate.engine.elapsed != engine.elapsed;
}
