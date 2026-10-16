import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
import 'museum_engine.dart';
import 'museum_scenario.dart';

class MuseumAfterHoursPage extends StatelessWidget {
  const MuseumAfterHoursPage({super.key});

  static const int totalCases = MuseumScenario.campaignLevels;
  static const int totalStars = totalCases * 3;
  static final List<ParkurLevelSpec>
  _levels = List<ParkurLevelSpec>.generate(totalCases, (int index) {
    final int level = index + 1;
    final String phase = switch (level) {
      <= 3 => 'GÖLGEYİ ÖĞREN',
      <= 6 => 'IŞIK DÖNGÜSÜ',
      7 || 8 => 'İLERİ',
      9 || 10 => 'UZMAN',
      <= 16 => 'USTA',
      _ => 'GECE NÖBETİ FİNALİ',
    };
    return ParkurLevelSpec(
      number: level,
      titleTr: 'Vardiya ${level.toString().padLeft(2, '0')}',
      titleEn: 'Shift ${level.toString().padLeft(2, '0')}',
      subtitleTr: switch (level) {
        <= 3 => 'Gölge ceplerinde saklan, eseri bul ve çıkışa ulaş.',
        <= 6 => 'Lazer çevrimini oku; her hamlenin bir nöbet maliyeti var.',
        7 || 8 => 'İki devriye ile üç eser rotasını birlikte yönet.',
        9 || 10 => 'Uzman: dar güvenli pencerede dikkat dağıtıcıyı harca.',
        <= 16 => 'Daha uzun görüş, sık devriye ve kesişen lazer hatları.',
        _ => 'Final: üç eser, üç devriye ve az sayıda güvenli bekleme.',
      },
      subtitleEn: switch (level) {
        <= 3 => 'Hide in shadow pockets, recover the piece and reach the exit.',
        <= 6 => 'Read laser cycles; every deliberate move costs a guard turn.',
        7 || 8 => 'Route around two patrols while securing three pieces.',
        9 || 10 => 'Expert: spend your single distraction in a narrow window.',
        <= 16 => 'Longer sightlines, tighter patrols and crossing laser lanes.',
        _ => 'Final: three artifacts, three guards and scarce safe pauses.',
      },
      difficulty: level >= 17 ? 'FİNAL' : phase,
      icon: Icons.museum_rounded,
    );
  }, growable: false);

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'museum_after_hours',
      progressPrefix: 'museum_after_hours',
      titleTr: 'Müze: Gece Vardiyası',
      titleEn: 'Museum: After Hours',
      taglineTr: 'Gölgede kal • Eseri al • Sessizce çık',
      taglineEn: 'Stay in shadow • Recover the art • Slip out',
      accent: skin.accent,
      icon: Icons.museum_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => MuseumAfterHoursPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class MuseumAfterHoursPlayPage extends StatefulWidget {
  const MuseumAfterHoursPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<MuseumAfterHoursPlayPage> createState() =>
      _MuseumAfterHoursPlayPageState();
}

class _MuseumAfterHoursPlayPageState extends State<MuseumAfterHoursPlayPage>
    with WidgetsBindingObserver {
  static const Color _accent = Color(0xFF568B8A);
  static const Color _ink = Color(0xFF35464F);
  static const Color _amber = Color(0xFFC99753);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late MuseumScenario _scenario;
  late MuseumAfterHoursEngine _engine;
  late StudioGameSession _session;
  bool _ready = false;
  bool _paused = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  int get _score =>
      (_engine.collectedArtifacts.length * 420 +
              math.max(0, 280 - _engine.actions * 3) +
              (_engine.escaped ? 700 : 0))
          .clamp(0, 10000000)
          .toInt();

  int get _stars => _engine.escaped && _engine.actions <= 30
      ? 3
      : _engine.escaped
      ? 2
      : 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareMap());
  }

  Future<void> _prepareMap() async {
    MuseumScenario scenario = MuseumScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'museum_after_hours_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('museum_after_hours_practice_index') ?? 0;
        if (index < MuseumScenario.practiceMaps) {
          final int next = index + 1;
          await preferences.setInt('museum_after_hours_practice_index', next);
          scenario = MuseumScenario.forPracticeMap(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // Authored campaign remains playable without local persistence.
    }
    if (!mounted) return;
    _scenario = scenario;
    _resetRun();
    setState(() => _ready = true);
  }

  void _resetRun() {
    _engine = MuseumAfterHoursEngine(scenario: _scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: _scenario.seed,
    )..start();
    _finished = false;
    _paused = false;
    _feedback = _english
        ? 'Stay in the marked shadow pockets; the cone is only a warning.'
        : 'İşaretli gölgelerde kal; görüş konisi uyarıdır, henüz yakalanmadın.';
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
    setState(() => _paused = value);
    _feedback = value
        ? (_english
              ? 'SHIFT PAUSED · RESUME WHEN READY'
              : 'VARDİYA DURAKLATILDI · HAZIR OLUNCA DEVAM ET')
        : (_english
              ? 'BACK IN THE SHADOWS · READ THE NEXT CYCLE'
              : 'GÖLGEYE DÖNDÜN · SIRADAKİ ÇEVRİMİ OKU');
    _feedback = value
        ? (_english
              ? 'SHIFT PAUSED · RESUME WHEN READY'
              : 'VARDİYA DURAKLATILDI · HAZIR OLUNCA DEVAM ET')
        : (_english
              ? 'BACK IN THE SHADOWS · READ THE NEXT CYCLE'
              : 'GÖLGEYE DÖNDÜN · SIRADAKİ ÇEVRİMİ OKU');
    if (value) {
      _session.pause();
    } else {
      _session.resume();
    }
    unawaited(_audio.play(GameSound.uiClick, gain: .2));
  }

  void _apply(MuseumActionResult result) {
    if (!_ready || _paused || _finished) return;
    if (!result.accepted) {
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .15));
      setState(
        () => _feedback = _english
            ? 'That action is blocked. Check the wall, shadow or objective.'
            : 'Bu hamle kapalı. Duvarı, gölgeyi veya hedefi kontrol et.',
      );
      return;
    }
    _session.recordAccepted(
      points: result.collected
          ? 120
          : result.escaped
          ? 180
          : 8,
    );
    if (result.caught) _session.recordMistake();
    final String actionText = result.laserHit
        ? (_english
              ? 'LASER TRIP · SECURITY ALERT'
              : 'LAZER TETİKLENDİ · ALARM')
        : result.escaped
        ? (_english
              ? 'COLLECTION COMPLETE · EXIT SECURED'
              : 'KOLEKSİYON TAMAM · ÇIKIŞ GÜVENDE')
        : result.collected
        ? (_english
              ? 'ARTWORK RECOVERED · KEEP LOW'
              : 'ESER ALINDI · GÖLGEDE KAL')
        : result.hidden
        ? (_english
              ? 'HOLD IN SHADOW · CYCLE ADVANCED'
              : 'GÖLGEDE BEKLE · ÇEVRİM İLERLEDİ')
        : result.lureUsed
        ? (_english
              ? 'DECOY RELEASED · PATROL DIVERTED'
              : 'DİKKAT DAĞITICI BIRAKILDI · DEVRİYE SAPTI')
        : result.caught
        ? (_english
              ? 'SPOTTED · RETRY THE ROUTE'
              : 'FARK EDİLDİN · ROTAYI YENİDEN DENE')
        : (_english
              ? 'MOVE COMPLETE · WATCH THE NEXT PATROL STEP'
              : 'HAMLE TAMAM · SIRADAKİ DEVRİYEYİ İZLE');
    _feedback = actionText;
    unawaited(
      _audioProfile.play(
        _audio,
        result.caught
            ? GameAudioEvent.rejected
            : result.escaped || result.collected
            ? GameAudioEvent.accepted
            : GameAudioEvent.primaryAction,
        gain: result.escaped ? .27 : .2,
      ),
    );
    if (result.accepted) _audio.hapticLight();
    setState(() {});
    if (result.escaped) {
      unawaited(_finishRun());
    } else if (result.caught) {
      unawaited(_offerRetry());
    }
  }

  Future<void> _offerRetry() async {
    if (_finished || !mounted) return;
    _finished = true;
    _session.fail();
    final bool retry =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(_english ? 'SECURITY ALERT' : 'GÜVENLİK ALARMI'),
            content: Text(
              _english
                  ? 'The guard cone, patrol timing and laser pulses are visible. Wait from a shadow pocket, then cross on an inactive beat.'
                  : 'Devriye görüşü, tur zamanı ve lazer atımları görünür. Gölge cebinde bekle; ışık söndüğünde geç.',
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
      setState(_resetRun);
    } else {
      Navigator.of(context)
          .pop(StudioGameResult.failed(score: _score).toParkurResult());
    }
  }

  Future<void> _finishRun() async {
    if (_finished || !mounted) return;
    _finished = true;
    _session.complete(
      stars: _stars,
      action: widget.level.number < MuseumAfterHoursPage.totalCases
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
      titleTr: 'GECE VARDİYASI TAMAMLANDI',
      titleEn: 'AFTER HOURS COMPLETE',
      detailTr:
          '${_engine.collectedArtifacts.length} eser · ${_engine.actions} hamle · sessiz kaçış',
      detailEn:
          '${_engine.collectedArtifacts.length} artworks · ${_engine.actions} moves · clean escape',
      stars: _stars,
      score: _score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < MuseumAfterHoursPage.totalCases,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    if (!_ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          title: Text(_english ? 'AFTER HOURS' : 'GECE VARDİYASI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final bool inputDisabled = _paused || _finished;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          _english
              ? 'MUSEUM · SHIFT ${widget.level.number}'
              : 'MÜZE · VARDİYA ${widget.level.number}',
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('museum_after_hours_pause'),
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
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                child: Text(
                  _feedback,
                  key: const ValueKey<String>('museum_after_hours_feedback'),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: MuseumScenario.columns / MuseumScenario.rows,
                    child: RepaintBoundary(
                      key: const ValueKey<String>('museum_after_hours_map'),
                      child: CustomPaint(
                        painter: _MuseumPainter(engine: _engine),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              _buildActionRow(inputDisabled),
              const SizedBox(height: 8),
              _buildDirectionPad(inputDisabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Container(
      key: const ValueKey<String>('museum_after_hours_hud'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8E2)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _ink.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.auto_awesome_rounded, size: 18, color: _amber),
          const SizedBox(width: 7),
          Text(
            '${_engine.collectedArtifacts.length}/${_scenario.artifacts.length}',
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _english ? 'ARTWORKS' : 'ESER',
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: .8,
              ),
            ),
          ),
          Icon(
            _engine.isInShadow
                ? Icons.dark_mode_rounded
                : Icons.visibility_rounded,
            size: 17,
            color: _engine.isInShadow ? _accent : const Color(0xFFC36A5F),
          ),
          const SizedBox(width: 5),
          Text(
            _engine.isInShadow
                ? (_english ? 'HIDDEN' : 'GİZLİ')
                : (_english ? 'EXPOSED' : 'AÇIKTA'),
            style: TextStyle(
              color: _engine.isInShadow ? _accent : const Color(0xFFC36A5F),
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _engine.turn.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: _ink,
              fontFeatures: <ui.FontFeature>[ui.FontFeature.tabularFigures()],
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(bool disabled) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _actionButton(
            Icons.dark_mode_outlined,
            _english ? 'HIDE' : 'BEKLE',
            'museum_hide',
            disabled || !_engine.isInShadow,
            () => _apply(_engine.hide()),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _actionButton(
            Icons.auto_awesome_rounded,
            _english ? 'LURE' : 'OYALA',
            'museum_lure',
            disabled || _engine.lureCharges == 0,
            () => _apply(_engine.useLure()),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _actionButton(
            Icons.inventory_2_outlined,
            _english ? 'COLLECT' : 'ESERİ AL',
            'museum_collect',
            disabled ||
                !_scenario.artifacts.contains(_engine.player) ||
                _engine.collectedArtifacts.contains(_engine.player),
            () => _apply(_engine.collect()),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _actionButton(
            Icons.logout_rounded,
            _english ? 'EXIT' : 'ÇIKIŞ',
            'museum_exit',
            disabled ||
                _engine.player != MuseumScenario.exit ||
                !_engine.allArtifactsCollected,
            () => _apply(_engine.escape()),
            primary: true,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    String key,
    bool disabled,
    VoidCallback onTap, {
    bool primary = false,
  }) {
    return SizedBox(
      height: 56,
      child: FilledButton.tonal(
        key: ValueKey<String>(key),
        onPressed: disabled ? null : onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
          backgroundColor: primary ? _accent : Colors.white,
          foregroundColor: primary ? Colors.white : _ink,
          disabledBackgroundColor: const Color(0xFFEDEDE8),
          disabledForegroundColor: const Color(0xFF9A9B96),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: primary ? _accent : const Color(0xFFE6E7E1),
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
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionPad(bool disabled) {
    Widget moveButton(String key, IconData icon, int dx, int dy) => SizedBox(
      width: 48,
      height: 48,
      child: IconButton.filledTonal(
        key: ValueKey<String>(key),
        tooltip: _english ? 'Move' : 'Yürü',
        visualDensity: VisualDensity.compact,
        onPressed: disabled ? null : () => _apply(_engine.move(dx, dy)),
        icon: Icon(icon, size: 20),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        moveButton('museum_move_left', Icons.chevron_left_rounded, -1, 0),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            moveButton(
              'museum_move_up',
              Icons.keyboard_arrow_up_rounded,
              0,
              -1,
            ),
            const SizedBox(height: 2),
            moveButton(
              'museum_move_down',
              Icons.keyboard_arrow_down_rounded,
              0,
              1,
            ),
          ],
        ),
        const SizedBox(width: 4),
        moveButton('museum_move_right', Icons.chevron_right_rounded, 1, 0),
      ],
    );
  }
}

class _MuseumPainter extends CustomPainter {
  const _MuseumPainter({required this.engine});

  final MuseumAfterHoursEngine engine;
  static const Color _floor = Color(0xFFF3F0E8);
  static const Color _wall = Color(0xFFBEB9AC);
  static const Color _shadow = Color(0xFF7EA8A2);
  static const Color _gold = Color(0xFFC99959);
  static const Color _alert = Color(0xFFD97969);

  @override
  void paint(Canvas canvas, Size size) {
    final double cw = size.width / MuseumScenario.columns;
    final double ch = size.height / MuseumScenario.rows;
    final Rect bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(22)),
      Paint()..color = const Color(0xFFE3DED2),
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(22)),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF9F6EF), _floor, Color(0xFFECE8DD)],
        ).createShader(bounds),
    );
    for (int y = 0; y < MuseumScenario.rows; y++) {
      for (int x = 0; x < MuseumScenario.columns; x++) {
        final Rect cell = Rect.fromLTWH(x * cw, y * ch, cw, ch).deflate(1.1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(cell, const Radius.circular(5)),
          Paint()..color = const Color(0x14FFFFFF),
        );
      }
    }
    for (final MuseumCell cell in engine.scenario.shadows) {
      final Rect rect = Rect.fromLTWH(
        cell.x * cw + 3,
        cell.y * ch + 3,
        cw - 6,
        ch - 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        Paint()..color = _shadow.withValues(alpha: .28),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _shadow.withValues(alpha: .38),
      );
    }
    for (int x = 0; x < MuseumScenario.columns; x++) {
      final double lineY = (x % 2 == 0 ? 3 : 6) * ch + ch / 2;
      canvas.drawLine(
        Offset(x * cw + 4, lineY),
        Offset((x + 1) * cw - 4, lineY),
        Paint()
          ..color = const Color(0x14A89373)
          ..strokeWidth = 1,
      );
    }
    for (final MuseumCell cell in engine.scenario.walls) {
      final Rect rect = Rect.fromLTWH(
        cell.x * cw + 1,
        cell.y * ch + 1,
        cw - 2,
        ch - 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 2)),
          const Radius.circular(5),
        ),
        Paint()..color = const Color(0x1F303940),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[Color(0xFFE1DDD2), _wall, Color(0xFFAAA597)],
          ).createShader(rect),
      );
      canvas.drawLine(
        rect.topLeft + Offset(4, 3),
        rect.topRight + Offset(-4, 3),
        Paint()
          ..color = Colors.white.withValues(alpha: .55)
          ..strokeWidth = 1.4,
      );
    }
    for (final MuseumLaserSpec laser in engine.scenario.lasers) {
      final Offset center = _center(laser.cell, cw, ch);
      final bool active = engine.laserActive(laser);
      final Paint beam = Paint()
        ..color = active
            ? _alert.withValues(alpha: .92)
            : _shadow.withValues(alpha: .35)
        ..strokeWidth = active ? 3.2 : 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx - cw * .32, center.dy),
        Offset(center.dx + cw * .32, center.dy),
        beam,
      );
      canvas.drawCircle(
        center,
        math.min(cw, ch) * .25,
        Paint()
          ..color = active
              ? _alert.withValues(alpha: .14)
              : _shadow.withValues(alpha: .12),
      );
    }
    final Set<MuseumCell> visible = engine.visibleCells.toSet();
    for (final MuseumCell cell in visible) {
      final Rect coneCell = Rect.fromLTWH(
        cell.x * cw + 4,
        cell.y * ch + 4,
        cw - 8,
        ch - 8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(coneCell, const Radius.circular(5)),
        Paint()..color = const Color(0x1FD98969),
      );
    }
    _drawExit(
      canvas,
      _center(MuseumScenario.exit, cw, ch),
      cw,
      ch,
      engine.allArtifactsCollected,
    );
    for (final MuseumCell artifact in engine.scenario.artifacts) {
      _drawArtifact(
        canvas,
        _center(artifact, cw, ch),
        cw,
        ch,
        engine.collectedArtifacts.contains(artifact),
      );
    }
    for (final MuseumGuardState guard in engine.guards) {
      _drawGuard(
        canvas,
        _center(guard.cell, cw, ch),
        guard.facing,
        cw,
        ch,
        guard.distractedTurns > 0,
      );
    }
    _drawPlayer(canvas, _center(engine.player, cw, ch), cw, ch, engine.hidden);
    canvas.restore();
  }

  Offset _center(MuseumCell cell, double cw, double ch) =>
      Offset((cell.x + .5) * cw, (cell.y + .5) * ch);

  void _drawArtifact(
    Canvas canvas,
    Offset center,
    double cw,
    double ch,
    bool collected,
  ) {
    final double scale = math.min(cw, ch);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, scale * .23),
        width: scale * .58,
        height: scale * .17,
      ),
      Paint()..color = const Color(0x263B4141),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, scale * .08),
          width: scale * .55,
          height: scale * .29,
        ),
        Radius.circular(scale * .08),
      ),
      Paint()
        ..shader =
            const LinearGradient(
              colors: <Color>[Color(0xFFE6D2A9), Color(0xFFB9945F)],
            ).createShader(
              Rect.fromCenter(
                center: center,
                width: scale * .6,
                height: scale * .4,
              ),
            ),
    );
    final Path gem = Path()
      ..moveTo(center.dx, center.dy - scale * .31)
      ..lineTo(center.dx + scale * .19, center.dy - scale * .05)
      ..lineTo(center.dx, center.dy + scale * .06)
      ..lineTo(center.dx - scale * .19, center.dy - scale * .05)
      ..close();
    canvas.drawPath(
      gem,
      Paint()..color = collected ? _shadow.withValues(alpha: .55) : _gold,
    );
    canvas.drawPath(
      gem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .74),
    );
    if (collected) {
      canvas.drawCircle(
        center,
        scale * .35,
        Paint()..color = Colors.white.withValues(alpha: .28),
      );
    }
  }

  void _drawExit(
    Canvas canvas,
    Offset center,
    double cw,
    double ch,
    bool open,
  ) {
    final double scale = math.min(cw, ch);
    final Rect arch = Rect.fromCenter(
      center: center + Offset(0, scale * .06),
      width: scale * .5,
      height: scale * .59,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(arch, Radius.circular(scale * .24)),
      Paint()..color = open ? _shadow : const Color(0xFF938E81),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        arch.deflate(scale * .06),
        Radius.circular(scale * .20),
      ),
      Paint()..color = open ? const Color(0xFFDAEBE3) : const Color(0xFFE5DFD2),
    );
    canvas.drawCircle(
      Offset(center.dx + scale * .13, center.dy + scale * .05),
      scale * .025,
      Paint()..color = _gold,
    );
  }

  void _drawGuard(
    Canvas canvas,
    Offset center,
    MuseumCell facing,
    double cw,
    double ch,
    bool distracted,
  ) {
    final double scale = math.min(cw, ch);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, scale * .23),
        width: scale * .47,
        height: scale * .16,
      ),
      Paint()..color = const Color(0x2A303942),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, scale * .04),
          width: scale * .34,
          height: scale * .39,
        ),
        Radius.circular(scale * .13),
      ),
      Paint()..color = distracted ? _shadow : const Color(0xFF52616A),
    );
    canvas.drawCircle(
      center + Offset(0, -scale * .2),
      scale * .15,
      Paint()..color = const Color(0xFFD9B89B),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: center + Offset(0, -scale * .25),
        width: scale * .38,
        height: scale * .23,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF35464F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * .08,
    );
    final Offset arrowStart = center + Offset(0, -scale * .2);
    final Offset arrowEnd =
        arrowStart + Offset(facing.x * scale * .22, facing.y * scale * .22);
    canvas.drawLine(
      arrowStart,
      arrowEnd,
      Paint()
        ..color = _gold
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawPlayer(
    Canvas canvas,
    Offset center,
    double cw,
    double ch,
    bool hidden,
  ) {
    final double scale = math.min(cw, ch);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, scale * .22),
        width: scale * .43,
        height: scale * .14,
      ),
      Paint()..color = const Color(0x30384243),
    );
    canvas.drawCircle(
      center,
      scale * .32,
      Paint()..color = _shadow.withValues(alpha: hidden ? .24 : .42),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, scale * .04),
          width: scale * .27,
          height: scale * .38,
        ),
        Radius.circular(scale * .12),
      ),
      Paint()..color = const Color(0xFF466F75),
    );
    canvas.drawCircle(
      center + Offset(0, -scale * .19),
      scale * .12,
      Paint()..color = const Color(0xFFE8D0B8),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: center + Offset(0, -scale * .23),
        width: scale * .31,
        height: scale * .18,
      ),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF344A50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale * .065,
    );
  }

  @override
  bool shouldRepaint(covariant _MuseumPainter oldDelegate) =>
      oldDelegate.engine != engine || oldDelegate.engine.turn != engine.turn;
}
