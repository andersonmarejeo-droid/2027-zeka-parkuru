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
import 'moonbase_engine.dart';
import 'moonbase_scenario.dart';

class MoonbaseOpsGamePage extends StatelessWidget {
  const MoonbaseOpsGamePage({super.key});
  static const int totalMissions = MoonbaseScenario.campaignLevels;
  static const int totalStars = totalMissions * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalMissions,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Üs ${level.toString().padLeft(2, '0')}',
        titleEn: 'Outpost ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Enerji ve oksijeni çekirdeğe bağla.',
          <= 6 => 'Isı bütçesini ve yaşam alanını dengele.',
          7 || 8 => 'İleri: haberleşme ağına laboratuvarı ekle.',
          9 || 10 => 'Uzman: göktaşı ve güneş tutulmasına hazırlan.',
          <= 16 => 'Usta: bütün modülleri kesintisiz ağda birleştir.',
          _ => 'Final: yüksek ekip talebini soğuk cephede yönet.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Connect power and oxygen to the core.',
          <= 6 => 'Balance thermal load and crew habitat.',
          7 || 8 => 'Advanced: connect a laboratory and comm relay.',
          9 || 10 => 'Expert: prepare for meteors and solar eclipses.',
          <= 16 => 'Master: join every module into one live network.',
          _ => 'Final: sustain a large crew through a cold front.',
        },
        difficulty: switch (level) {
          <= 3 => 'KURULUM',
          <= 6 => 'YAŞAM',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.rocket_launch_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'moonbase_ops',
      progressPrefix: 'moonbase_ops',
      titleTr: 'Ay Üssü Operasyonları',
      titleEn: 'Moonbase Operations',
      taglineTr: 'Modülleri bağla • Kaynakları yaşat • Ekibi koru',
      taglineEn: 'Connect modules • Balance resources • Protect your crew',
      accent: skin.accent,
      icon: Icons.rocket_launch_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => MoonbaseOpsPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class MoonbaseOpsPlayPage extends StatefulWidget {
  const MoonbaseOpsPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });
  final ParkurLevelSpec level;
  final int previousBestScore;
  @override
  State<MoonbaseOpsPlayPage> createState() => _MoonbaseOpsPlayPageState();
}

class _MoonbaseOpsPlayPageState extends State<MoonbaseOpsPlayPage> {
  static const Color _accent = Color(0xFF6C8FA5);
  static const Color _ink = Color(0xFF344C5B);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late MoonbaseScenario _scenario;
  late MoonbaseEngine _engine;
  late StudioGameSession _session;
  MoonModule _selected = MoonModule.solarArray;
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
    MoonbaseScenario scenario = MoonbaseScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String visitKey =
          'moonbase_ops_level_${widget.level.number}_visits';
      final int visits = await prefs.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await prefs.getInt('moonbase_ops_practice_index') ?? 0;
        if (index < MoonbaseScenario.practiceMissions) {
          final int next = index + 1;
          await prefs.setInt('moonbase_ops_practice_index', next);
          scenario = MoonbaseScenario.forPractice(next);
        }
      }
      await prefs.setInt(visitKey, visits + 1);
    } catch (_) {
      // The authored mission still works without local preferences.
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = MoonbaseEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    setState(() {
      _english = context.l10n.isEnglish;
      _feedback = _english
          ? 'Connect each module to the central core; protect all life systems.'
          : 'Her modülü merkez çekirdeğe bağla; yaşam sistemlerini koru.';
      _ready = true;
    });
  }

  void _tapGrid(Offset position, Size size) {
    if (!_ready || _finished) return;
    const double inset = 12;
    final double cell = math.min(
      (size.width - inset * 2) / _scenario.size,
      (size.height - inset * 2) / _scenario.size,
    );
    final int x = ((position.dx - inset) / cell).floor();
    final int y = ((position.dy - inset) / cell).floor();
    if (x < 0 || y < 0 || x >= _scenario.size || y >= _scenario.size) return;
    final MoonCell target = MoonCell(x, y);
    final MoonbaseActionResult existing = _engine.removeAt(target);
    if (existing.accepted) {
      setState(
        () => _feedback = _english
            ? 'Module removed · choose another system to install.'
            : 'Modül kaldırıldı · yerleştirmek için başka bir sistem seç.',
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .14));
      return;
    }
    final MoonbaseActionResult result = _engine.place(_selected, target);
    setState(() => _feedback = _actionText(result.reason));
    unawaited(
      _audioProfile.play(
        _audio,
        result.accepted ? GameAudioEvent.accepted : GameAudioEvent.rejected,
        gain: .17,
      ),
    );
    if (result.accepted) {
      _session.recordAccepted(points: 8);
      _audio.hapticLight();
    } else {
      _session.recordMistake();
    }
  }

  String _actionText(String reason) => switch (reason) {
    'outside_grid' =>
      _english ? 'Outside the module grid.' : 'Modül ızgarasının dışında.',
    'core_reserved' =>
      _english ? 'The command core is fixed.' : 'Komuta çekirdeği sabit.',
    'rock' =>
      _english ? 'This crater tile is blocked.' : 'Bu krater karesi kapalı.',
    'occupied' =>
      _english
          ? 'Tile occupied · tap it to remove first.'
          : 'Kare dolu · önce kaldırmak için dokun.',
    'over_budget' =>
      _english ? 'Mission budget exceeded.' : 'Görev bütçesi aşıldı.',
    'placed' =>
      _english
          ? '${_selected.label(true)} module installed · ${_selected.cost} credits.'
          : '${_selected.label(false)} modülü kuruldu · ${_selected.cost} kredi.',
    _ => _english ? 'Empty tile.' : 'Boş kare.',
  };

  void _choose(MoonModule module) {
    if (_finished) return;
    setState(() {
      _selected = module;
      _feedback = _english
          ? '${module.label(true)} selected · ${module.cost} credits.'
          : '${module.label(false)} seçildi · ${module.cost} kredi.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _history(bool undo) {
    final bool changed = undo ? _engine.undo() : _engine.redo();
    if (!changed) return;
    setState(
      () => _feedback = undo
          ? (_english
                ? 'Last module change undone.'
                : 'Son modül hamlesi geri alındı.')
          : (_english
                ? 'Module change restored.'
                : 'Modül hamlesi yeniden yapıldı.'),
    );
    unawaited(_audio.play(GameSound.uiClick, gain: .18));
  }

  Future<void> _launch() async {
    if (_finished) return;
    final MoonbaseEvaluation evaluation = _engine.evaluate();
    if (!evaluation.canLaunch) {
      final List<String> missing = <String>[];
      if (evaluation.requiredPlaced < evaluation.requiredCount) {
        missing.add(_english ? 'required modules' : 'zorunlu modüller');
      }
      if (evaluation.connectedCount < evaluation.moduleCount) {
        missing.add(_english ? 'core network' : 'çekirdek ağı');
      }
      if (evaluation.powerAvailable < evaluation.powerDemand) {
        missing.add(_english ? 'power' : 'enerji');
      }
      if (evaluation.oxygenAvailable < evaluation.oxygenDemand) {
        missing.add(_english ? 'oxygen' : 'oksijen');
      }
      if (evaluation.heatLoad > _scenario.heatLimit + evaluation.cooling) {
        missing.add(_english ? 'thermal control' : 'ısı kontrolü');
      }
      if (!evaluation.shieldReady) {
        missing.add(_english ? 'meteor shield' : 'göktaşı kalkanı');
      }
      if (evaluation.budgetUsed > evaluation.budget) {
        missing.add(_english ? 'budget' : 'bütçe');
      }
      setState(
        () => _feedback = _english
            ? 'Launch check: ${missing.join(' · ')}'
            : 'Fırlatma kontrolü: ${missing.join(' · ')}',
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
      return;
    }
    _finished = true;
    final int stars = evaluation.score >= 94
        ? 3
        : (evaluation.score >= 82 ? 2 : 1);
    _session.complete(
      stars: stars,
      action: widget.level.number < MoonbaseOpsGamePage.totalMissions
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
    final ParkurResultAction? choice = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'ÜS GÜVENDE · GÖREV TAMAMLANDI',
      titleEn: 'BASE SECURE · MISSION COMPLETE',
      detailTr:
          'Enerji ${evaluation.powerAvailable}/${evaluation.powerDemand} · oksijen ${evaluation.oxygenAvailable}/${evaluation.oxygenDemand} · puan ${evaluation.score}',
      detailEn:
          'Power ${evaluation.powerAvailable}/${evaluation.powerDemand} · oxygen ${evaluation.oxygenAvailable}/${evaluation.oxygenDemand} · score ${evaluation.score}',
      stars: stars,
      score: evaluation.score * 100,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < MoonbaseOpsGamePage.totalMissions,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (choice) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: evaluation.score * 100,
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
        appBar: AppBar(title: Text(_english ? 'MOONBASE OPS' : 'AY ÜSSÜ')),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final MoonbaseEvaluation evaluation = _engine.evaluate();
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          '${_english ? 'OUTPOST' : 'ÜS'} · ${widget.level.number.toString().padLeft(2, '0')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('moonbase_ops_undo'),
            tooltip: _english ? 'Undo' : 'Geri al',
            onPressed: _engine.canUndo ? () => _history(true) : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('moonbase_ops_redo'),
            tooltip: _english ? 'Redo' : 'Yeniden yap',
            onPressed: _engine.canRedo ? () => _history(false) : null,
            icon: const Icon(Icons.redo_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Column(
            children: <Widget>[
              _hud(evaluation),
              const SizedBox(height: 4),
              _brief(),
              const SizedBox(height: 4),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints bounds) =>
                          GestureDetector(
                            key: const ValueKey<String>('moonbase_ops_grid'),
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (TapUpDetails details) => _tapGrid(
                              details.localPosition,
                              Size(bounds.maxWidth, bounds.maxHeight),
                            ),
                            child: CustomPaint(
                              painter: _MoonbasePainter(
                                scenario: _scenario,
                                placements: _engine.placements,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              _feedbackWidget(),
              const SizedBox(height: 3),
              _modulePicker(),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  key: const ValueKey<String>('moonbase_ops_launch'),
                  onPressed: _finished ? null : _launch,
                  style: FilledButton.styleFrom(
                    backgroundColor: evaluation.canLaunch ? _accent : _ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: Text(
                    _english ? 'LAUNCH MISSION' : 'GÖREVİ BAŞLAT',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: .4,
                      fontWeight: FontWeight.w900,
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

  Widget _hud(MoonbaseEvaluation evaluation) => Container(
    key: const ValueKey<String>('moonbase_ops_hud'),
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE0E6E9)),
    ),
    child: Row(
      children: <Widget>[
        _metric(
          Icons.bolt_rounded,
          evaluation.powerAvailable,
          evaluation.powerDemand,
        ),
        const Spacer(),
        _metric(
          Icons.air_rounded,
          evaluation.oxygenAvailable,
          evaluation.oxygenDemand,
        ),
        const Spacer(),
        _metric(
          Icons.device_thermostat_rounded,
          evaluation.heatLoad,
          _scenario.heatLimit + evaluation.cooling,
        ),
        const Spacer(),
        Text(
          '${evaluation.budgetUsed}/${evaluation.budget}',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );

  Widget _metric(IconData icon, int value, int target) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 15, color: _accent),
      const SizedBox(width: 2),
      Text(
        '$value/$target',
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
      ),
    ],
  );

  Widget _brief() {
    final Map<MoonModule, int> counts = <MoonModule, int>{};
    for (final MoonModule module in _scenario.requiredModules) {
      counts.update(module, (int n) => n + 1, ifAbsent: () => 1);
    }
    final String modules = counts.entries
        .map(
          (MapEntry<MoonModule, int> entry) =>
              '${entry.key.label(_english)}${entry.value > 1 ? ' ×${entry.value}' : ''}',
        )
        .join(' · ');
    return Container(
      key: const ValueKey<String>('moonbase_ops_brief'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.description_outlined, size: 16, color: _accent),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '${_hazardLabel(_scenario.hazard)} · ${_scenario.crew} ${_english ? 'crew' : 'ekip'}\n$modules',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8,
                height: 1.17,
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _hazardLabel(MoonHazard hazard) => switch (hazard) {
    MoonHazard.calm => _english ? 'STABLE ORBIT' : 'DENGELİ YÖRÜNGE',
    MoonHazard.coldFront => _english ? 'COLD FRONT' : 'SOĞUK CEPHE',
    MoonHazard.meteorShower => _english ? 'METEOR SHOWER' : 'GÖKTAŞI YAĞMURU',
    MoonHazard.solarEclipse => _english ? 'SOLAR ECLIPSE' : 'GÜNEŞ TUTULMASI',
  };

  Widget _feedbackWidget() => SizedBox(
    height: 22,
    child: Center(
      child: Text(
        _feedback,
        key: const ValueKey<String>('moonbase_ops_feedback'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _modulePicker() => SizedBox(
    height: 77,
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bounds) {
        final double width = (bounds.maxWidth - 18) / 4;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 3,
          children: MoonModule.values
              .map((MoonModule module) {
                final bool selected = _selected == module;
                return SizedBox(
                  width: width,
                  height: 36,
                  child: OutlinedButton(
                    key: ValueKey<String>('moonbase_module_${module.name}'),
                    onPressed: _finished ? null : () => _choose(module),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      backgroundColor: selected
                          ? const Color(0xFFDDE8EE)
                          : Colors.white,
                      foregroundColor: _ink,
                      side: BorderSide(
                        color: selected ? _accent : const Color(0xFFE1E6E8),
                        width: selected ? 1.4 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      '${module.label(_english)} · ${module.cost}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    ),
  );
}

class _MoonbasePainter extends CustomPainter {
  const _MoonbasePainter({required this.scenario, required this.placements});
  final MoonbaseScenario scenario;
  final List<MoonModulePlacement> placements;

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 12;
    final double cell = math.min(
      (size.width - 24) / scenario.size,
      (size.height - 24) / scenario.size,
    );
    final Rect field = Rect.fromLTWH(
      inset,
      inset,
      cell * scenario.size,
      cell * scenario.size,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(field.inflate(5), const Radius.circular(17)),
      Paint()..color = const Color(0xFFDCE5E9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(field, const Radius.circular(13)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFE9E8E1),
            Color(0xFFD9DFDE),
            Color(0xFFE5E3DB),
          ],
        ).createShader(field),
    );
    for (int y = 0; y < scenario.size; y++) {
      for (int x = 0; x < scenario.size; x++) {
        final MoonCell position = MoonCell(x, y);
        final Rect tile = Rect.fromLTWH(
          inset + x * cell,
          inset + y * cell,
          cell,
          cell,
        ).deflate(1.2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(tile, const Radius.circular(5)),
          Paint()
            ..color = (x + y).isEven
                ? const Color(0x25FFFFFF)
                : const Color(0x12000000),
        );
        _crater(canvas, tile, x, y);
        if (scenario.rocks.contains(position)) _rock(canvas, tile);
        if (position == scenario.core) _core(canvas, tile);
      }
    }
    for (final MoonModulePlacement placement in placements) {
      final Rect tile = Rect.fromLTWH(
        inset + placement.cell.x * cell,
        inset + placement.cell.y * cell,
        cell,
        cell,
      ).deflate(2.4);
      _module(canvas, tile, placement.module);
    }
  }

  void _core(Canvas canvas, Rect rect) {
    final Rect body = rect.deflate(rect.width * .12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(8)),
      Paint()..color = const Color(0xFF526D7B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.deflate(body.width * .18),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFE6F0EF),
    );
    canvas.drawCircle(
      body.center,
      body.width * .11,
      Paint()..color = const Color(0xFF75C1C3),
    );
    _label(
      canvas,
      Rect.fromLTWH(
        body.left,
        body.bottom - body.height * .26,
        body.width,
        body.height * .16,
      ),
      'CORE',
      const Color(0xFFECF3F1),
      6,
    );
  }

  void _module(Canvas canvas, Rect rect, MoonModule module) {
    final Color shell = switch (module) {
      MoonModule.solarArray => const Color(0xFF547F99),
      MoonModule.habitat => const Color(0xFF8C9F9D),
      MoonModule.greenhouse => const Color(0xFF669483),
      MoonModule.laboratory => const Color(0xFF8D84A5),
      MoonModule.battery => const Color(0xFFB99460),
      MoonModule.radiator => const Color(0xFF77919F),
      MoonModule.shield => const Color(0xFF758B9A),
      MoonModule.commRelay => const Color(0xFF9B826C),
    };
    final Rect body = rect.deflate(rect.width * .1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.shift(const Offset(0, 1.3)),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(7)),
      Paint()..color = shell,
    );
    switch (module) {
      case MoonModule.solarArray:
        for (int i = 0; i < 3; i++) {
          final Rect panel = Rect.fromLTWH(
            body.left + body.width * (.13 + i * .25),
            body.top + body.height * .22,
            body.width * .2,
            body.height * .48,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(panel, const Radius.circular(2)),
            Paint()..color = const Color(0xFFAED0D5),
          );
          canvas.drawLine(
            Offset(panel.center.dx, panel.top),
            Offset(panel.center.dx, panel.bottom),
            Paint()
              ..color = const Color(0xFF678FA2)
              ..strokeWidth = 1,
          );
        }
        canvas.drawLine(
          Offset(body.center.dx, body.bottom - 2),
          Offset(body.center.dx, body.bottom + 2),
          Paint()
            ..color = const Color(0xFFE9F2EF)
            ..strokeWidth = 2,
        );
      case MoonModule.habitat:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              body.left + body.width * .2,
              body.top + body.height * .25,
              body.width * .6,
              body.height * .48,
            ),
            Radius.circular(body.width * .16),
          ),
          Paint()..color = const Color(0xFFE9E9DF),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              body.left + body.width * .28,
              body.top + body.height * .34,
              body.width * .18,
              body.height * .18,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFF9ED1D2),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              body.left + body.width * .55,
              body.top + body.height * .34,
              body.width * .18,
              body.height * .18,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFF9ED1D2),
        );
      case MoonModule.greenhouse:
        final Rect dome = Rect.fromLTWH(
          body.left + body.width * .16,
          body.top + body.height * .22,
          body.width * .68,
          body.height * .48,
        );
        canvas.drawArc(
          dome,
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFFBFE0C7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
        for (int i = 0; i < 3; i++) {
          final double x = body.left + body.width * (.3 + i * .2);
          canvas.drawLine(
            Offset(x, body.bottom - body.height * .12),
            Offset(x, body.top + body.height * .46),
            Paint()
              ..color = const Color(0xFFE5F1D6)
              ..strokeWidth = 1.2,
          );
          canvas.drawCircle(
            Offset(x - body.width * .04, body.top + body.height * .47),
            body.width * .06,
            Paint()..color = const Color(0xFFE5F1D6),
          );
        }
      case MoonModule.laboratory:
        final Path roof = Path()
          ..moveTo(body.left + body.width * .2, body.top + body.height * .42)
          ..lineTo(body.center.dx, body.top + body.height * .2)
          ..lineTo(body.right - body.width * .2, body.top + body.height * .42)
          ..close();
        canvas.drawPath(roof, Paint()..color = const Color(0xFFECE8F0));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              body.left + body.width * .25,
              body.top + body.height * .42,
              body.width * .5,
              body.height * .35,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFECE8F0),
        );
        canvas.drawCircle(
          Offset(body.center.dx, body.center.dy + body.height * .04),
          body.width * .09,
          Paint()..color = const Color(0xFF92D3D0),
        );
      case MoonModule.battery:
        final Rect cell = Rect.fromLTWH(
          body.left + body.width * .28,
          body.top + body.height * .27,
          body.width * .44,
          body.height * .48,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(cell, const Radius.circular(4)),
          Paint()..color = const Color(0xFFF5E5BE),
        );
        canvas.drawRect(
          Rect.fromLTWH(
            cell.right,
            cell.top + cell.height * .28,
            body.width * .07,
            cell.height * .42,
          ),
          Paint()..color = const Color(0xFFF5E5BE),
        );
        canvas.drawLine(
          Offset(cell.center.dx, cell.top + 3),
          Offset(cell.center.dx, cell.bottom - 3),
          Paint()
            ..color = shell
            ..strokeWidth = 2,
        );
      case MoonModule.radiator:
        for (int i = 0; i < 4; i++) {
          final double x = body.left + body.width * (.24 + i * .17);
          canvas.drawLine(
            Offset(x, body.top + body.height * .22),
            Offset(x, body.bottom - body.height * .22),
            Paint()
              ..color = const Color(0xFFDCE8EA)
              ..strokeWidth = 2,
          );
        }
        canvas.drawLine(
          Offset(body.left + body.width * .18, body.center.dy),
          Offset(body.right - body.width * .18, body.center.dy),
          Paint()
            ..color = const Color(0xFFDCE8EA)
            ..strokeWidth = 1.5,
        );
      case MoonModule.shield:
        final Path shield = Path()
          ..moveTo(body.center.dx, body.top + body.height * .2)
          ..lineTo(body.right - body.width * .2, body.top + body.height * .34)
          ..lineTo(
            body.right - body.width * .25,
            body.bottom - body.height * .32,
          )
          ..lineTo(body.center.dx, body.bottom - body.height * .12)
          ..lineTo(
            body.left + body.width * .25,
            body.bottom - body.height * .32,
          )
          ..lineTo(body.left + body.width * .2, body.top + body.height * .34)
          ..close();
        canvas.drawPath(shield, Paint()..color = const Color(0xFFDCE8EC));
        canvas.drawLine(
          Offset(body.center.dx, body.top + body.height * .33),
          Offset(body.center.dx, body.bottom - body.height * .24),
          Paint()
            ..color = shell
            ..strokeWidth = 1.5,
        );
      case MoonModule.commRelay:
        final Offset dish = Offset(
          body.center.dx,
          body.top + body.height * .37,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: dish,
            width: body.width * .48,
            height: body.height * .36,
          ),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFFF3E5D0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawLine(
          dish,
          Offset(body.center.dx, body.bottom - body.height * .16),
          Paint()
            ..color = const Color(0xFFF3E5D0)
            ..strokeWidth = 1.5,
        );
        canvas.drawCircle(
          dish,
          body.width * .05,
          Paint()..color = const Color(0xFFF3E5D0),
        );
    }
    _label(
      canvas,
      Rect.fromLTWH(
        body.left,
        body.bottom - body.height * .19,
        body.width,
        body.height * .12,
      ),
      _short(module),
      const Color(0xFFF9FAF7),
      body.width * .12,
    );
  }

  String _short(MoonModule module) => switch (module) {
    MoonModule.solarArray => 'SOL',
    MoonModule.habitat => 'HAB',
    MoonModule.greenhouse => 'O2',
    MoonModule.laboratory => 'LAB',
    MoonModule.battery => 'PWR',
    MoonModule.radiator => 'HEAT',
    MoonModule.shield => 'DEF',
    MoonModule.commRelay => 'COM',
  };

  void _crater(Canvas canvas, Rect rect, int x, int y) {
    if ((x * 11 + y * 7) % 5 != 1) return;
    canvas.drawCircle(
      Offset(rect.left + rect.width * .72, rect.top + rect.height * .72),
      rect.width * .1,
      Paint()..color = const Color(0x20717C7D),
    );
  }

  void _rock(Canvas canvas, Rect rect) {
    final Path shape = Path()
      ..moveTo(rect.left + rect.width * .17, rect.bottom - rect.height * .16)
      ..lineTo(rect.left + rect.width * .28, rect.top + rect.height * .43)
      ..lineTo(rect.center.dx, rect.top + rect.height * .2)
      ..lineTo(rect.right - rect.width * .15, rect.top + rect.height * .4)
      ..lineTo(rect.right - rect.width * .2, rect.bottom - rect.height * .15)
      ..close();
    canvas.drawPath(shape, Paint()..color = const Color(0xFF8C9997));
    canvas.drawPath(
      shape,
      Paint()
        ..color = const Color(0x55707C7B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _label(
    Canvas canvas,
    Rect rect,
    String text,
    Color color,
    double fontSize,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize.clamp(5, 8).toDouble(),
          fontWeight: FontWeight.w900,
          letterSpacing: .15,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
    )..layout(maxWidth: rect.width);
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MoonbasePainter oldDelegate) =>
      oldDelegate.scenario != scenario || oldDelegate.placements != placements;
}
