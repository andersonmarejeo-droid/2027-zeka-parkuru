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
import 'boardwalk_engine.dart';
import 'boardwalk_scenario.dart';

class BoardwalkBuilderGamePage extends StatelessWidget {
  const BoardwalkBuilderGamePage({super.key});

  static const int totalParks = BoardwalkScenario.campaignLevels;
  static const int totalStars = totalParks * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalParks,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Park ${level.toString().padLeft(2, '0')}',
        titleEn: 'Park ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Giriş yolunu bağla; ziyaretçi için ilk durakları kur.',
          <= 6 => 'Kapasite, bütçe ve sahil hizmetlerini birlikte dengele.',
          7 || 8 => 'İleri: dar alanı kuyruk ve servis akışına göre planla.',
          9 || 10 => 'Uzman: iki büyük eğlence noktasını güvenli bağla.',
          <= 16 => 'Usta: hava, ziyaretçi yoğunluğu ve alan kullanımını çöz.',
          _ => 'Final: yoğun ziyaretçiyi eksiksiz bir ağ ve hizmetle karşıla.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Connect the entrance and place the first guest stops.',
          <= 6 => 'Balance capacity, budget and essential seaside services.',
          7 ||
          8 => 'Advanced: plan tight space around queues and service flow.',
          9 || 10 => 'Expert: connect two major attractions safely.',
          <= 16 => 'Master: solve weather, guest demand and space together.',
          _ => 'Final: serve a busy crowd with a complete connected network.',
        },
        difficulty: switch (level) {
          <= 3 => 'SAHİL',
          <= 6 => 'AKIŞ',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.attractions_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'boardwalk_builder',
      progressPrefix: 'boardwalk_builder',
      titleTr: 'Sahil Parkı Kurucusu',
      titleEn: 'Boardwalk Builder',
      taglineTr: 'Ağı kur • Ziyaretçiyi yönet • Sahili canlandır',
      taglineEn: 'Build the network • Serve guests • Bring the shore to life',
      accent: skin.accent,
      icon: Icons.attractions_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => BoardwalkBuilderPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class BoardwalkBuilderPlayPage extends StatefulWidget {
  const BoardwalkBuilderPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<BoardwalkBuilderPlayPage> createState() =>
      _BoardwalkBuilderPlayPageState();
}

class _BoardwalkBuilderPlayPageState extends State<BoardwalkBuilderPlayPage> {
  static const Color _accent = Color(0xFF4C8F91);
  static const Color _ink = Color(0xFF344C50);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late BoardwalkScenario _scenario;
  late BoardwalkEngine _engine;
  late StudioGameSession _session;
  BoardwalkBuild _selected = BoardwalkBuild.path;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_preparePark());
  }

  Future<void> _preparePark() async {
    BoardwalkScenario scenario = BoardwalkScenario.forLevel(
      widget.level.number,
    );
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String visitKey =
          'boardwalk_builder_level_${widget.level.number}_visits';
      final int visits = await prefs.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await prefs.getInt('boardwalk_builder_practice_index') ?? 0;
        if (index < BoardwalkScenario.practiceParks) {
          final int next = index + 1;
          await prefs.setInt('boardwalk_builder_practice_index', next);
          scenario = BoardwalkScenario.forPractice(next);
        }
      }
      await prefs.setInt(visitKey, visits + 1);
    } catch (_) {
      // Authored parks remain playable when local progress is unavailable.
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = BoardwalkEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    setState(() {
      _english = context.l10n.isEnglish;
      _feedback = _english
          ? 'Extend the timber path from the entrance; connect each guest stop.'
          : 'Ahşap yolu girişten uzat; her ziyaretçi yapısını ağa bağla.';
      _ready = true;
    });
  }

  void _tapPark(Offset position, Size size) {
    if (!_ready || _finished) return;
    const double inset = 12;
    final double cell = math.min(
      (size.width - inset * 2) / _scenario.width,
      (size.height - inset * 2) / _scenario.height,
    );
    final int x = ((position.dx - inset) / cell).floor();
    final int y = ((position.dy - inset) / cell).floor();
    if (x < 0 || y < 0 || x >= _scenario.width || y >= _scenario.height) return;
    final BoardwalkCell cellPosition = BoardwalkCell(x, y);
    final BoardwalkActionResult existing = _engine.removeAt(cellPosition);
    if (existing.accepted) {
      setState(
        () => _feedback = _english
            ? 'Tile cleared · place a new route or facility.'
            : 'Kare boşaltıldı · yeni yol ya da tesis yerleştir.',
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .14));
      return;
    }
    final BoardwalkActionResult result = _engine.place(_selected, cellPosition);
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
    'outside_park' =>
      _english ? 'Outside the park boundary.' : 'Park sınırının dışında.',
    'entry_reserved' =>
      _english
          ? 'The entrance tile is fixed.'
          : 'Giriş karesi sabit; yol girişin yanından devam eder.',
    'blocked' =>
      _english
          ? 'Natural rocks block this tile.'
          : 'Doğal kayalık bu kareyi kapatıyor.',
    'occupied' =>
      _english
          ? 'Tile occupied · tap it to remove first.'
          : 'Kare dolu · kaldırmak için önce dolu kareye dokun.',
    'over_budget' =>
      _english
          ? 'That exceeds the remaining budget.'
          : 'Bu yerleşim kalan bütçeyi aşıyor.',
    'placed' =>
      _english
          ? '${_selected.label(true)} placed · ${_selected.cost} credits.'
          : '${_selected.label(false)} yerleşti · ${_selected.cost} kredi.',
    _ => _english ? 'Empty tile.' : 'Boş kare.',
  };

  void _choose(BoardwalkBuild build) {
    if (_finished) return;
    setState(() {
      _selected = build;
      _feedback = _english
          ? 'Selected ${build.label(true)} · ${build.cost} credits.'
          : '${build.label(false)} seçildi · ${build.cost} kredi.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _history(bool undo) {
    final bool changed = undo ? _engine.undo() : _engine.redo();
    if (!changed) return;
    setState(
      () => _feedback = undo
          ? (_english
                ? 'Last park change undone.'
                : 'Son park hamlesi geri alındı.')
          : (_english
                ? 'Park change restored.'
                : 'Park hamlesi yeniden yapıldı.'),
    );
    unawaited(_audio.play(GameSound.uiClick, gain: .18));
  }

  Future<void> _openPark() async {
    if (_finished) return;
    final BoardwalkEvaluation result = _engine.evaluate();
    if (!result.canOpen) {
      final List<String> missing = <String>[];
      if (result.requiredPlaced < result.requiredCount) {
        missing.add(_english ? 'brief items' : 'brief yapıları');
      }
      if (result.connectedBuildings < result.buildingCount) {
        missing.add(_english ? 'connected paths' : 'bağlı yollar');
      }
      if (result.rideCapacity < _scenario.visitorCount) {
        missing.add(_english ? 'ride capacity' : 'eğlence kapasitesi');
      }
      if (result.foodCapacity < (_scenario.visitorCount / 2).ceil()) {
        missing.add(_english ? 'food service' : 'yiyecek servisi');
      }
      if (result.binCount < _scenario.minimumBins ||
          result.benchCount < _scenario.minimumBenches) {
        missing.add(_english ? 'guest amenities' : 'ziyaretçi hizmetleri');
      }
      if (result.budgetUsed > result.budget) {
        missing.add(_english ? 'budget' : 'bütçe');
      }
      setState(
        () => _feedback = _english
            ? 'Park check: ${missing.join(' · ')}'
            : 'Park kontrolü: ${missing.join(' · ')}',
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
      return;
    }
    _finished = true;
    final int stars = result.score >= 94 ? 3 : (result.score >= 82 ? 2 : 1);
    _session.complete(
      stars: stars,
      action: widget.level.number < BoardwalkBuilderGamePage.totalParks
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
      titleTr: 'SAHİL PARKI AÇILDI!',
      titleEn: 'BOARDWALK OPEN!',
      detailTr:
          '${result.connectedBuildings}/${result.buildingCount} tesis bağlı · ${result.rideCapacity} eğlence kapasitesi · puan ${result.score}',
      detailEn:
          '${result.connectedBuildings}/${result.buildingCount} facilities connected · ${result.rideCapacity} ride capacity · score ${result.score}',
      stars: stars,
      score: result.score * 100,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < BoardwalkBuilderGamePage.totalParks,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (choice) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: result.score * 100,
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
          title: Text(_english ? 'BOARDWALK BUILDER' : 'SAHİL PARKI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final BoardwalkEvaluation evaluation = _engine.evaluate();
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          '${_english ? 'PARK' : 'PARK'} · ${widget.level.number.toString().padLeft(2, '0')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('boardwalk_builder_undo'),
            tooltip: _english ? 'Undo' : 'Geri al',
            onPressed: _engine.canUndo ? () => _history(true) : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('boardwalk_builder_redo'),
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
              _buildHud(evaluation),
              const SizedBox(height: 4),
              _buildBrief(),
              const SizedBox(height: 4),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints bounds) =>
                          GestureDetector(
                            key: const ValueKey<String>(
                              'boardwalk_builder_park',
                            ),
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (TapUpDetails details) => _tapPark(
                              details.localPosition,
                              Size(bounds.maxWidth, bounds.maxHeight),
                            ),
                            child: CustomPaint(
                              painter: _BoardwalkPainter(
                                scenario: _scenario,
                                placements: _engine.placements,
                                selected: _selected,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              _buildFeedback(),
              const SizedBox(height: 3),
              _buildBuildPicker(),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  key: const ValueKey<String>('boardwalk_builder_open'),
                  onPressed: _finished ? null : _openPark,
                  style: FilledButton.styleFrom(
                    backgroundColor: evaluation.canOpen ? _accent : _ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.flag_rounded),
                  label: Text(
                    _english ? 'OPEN THE PARK' : 'PARKI AÇ',
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

  Widget _buildHud(BoardwalkEvaluation evaluation) => Container(
    key: const ValueKey<String>('boardwalk_builder_hud'),
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE3E7E3)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.payments_rounded, size: 16, color: _accent),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${evaluation.budgetUsed}/${evaluation.budget} ₡',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          ),
        ),
        _metric(
          Icons.people_alt_rounded,
          '${_scenario.visitorCount}',
          'GUESTS',
          'KONUK',
        ),
        const SizedBox(width: 7),
        _metric(
          Icons.attractions_rounded,
          '${evaluation.rideCapacity}',
          'RIDE',
          'EĞLENCE',
        ),
      ],
    ),
  );

  Widget _metric(IconData icon, String value, String en, String tr) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 14, color: _accent),
      const SizedBox(width: 2),
      Text(
        value,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
      const SizedBox(width: 2),
      Text(
        _english ? en : tr,
        style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900),
      ),
    ],
  );

  Widget _buildBrief() => Container(
    key: const ValueKey<String>('boardwalk_builder_brief'),
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F4F0),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.description_outlined, size: 16, color: _accent),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            '${_english ? 'BRIEF' : 'GÖREV'} · ${_scenario.requiredBuilds.map((BoardwalkBuild item) => item.label(_english)).join(' · ')}\n${_weatherLabel(_scenario.weather)} · ${_scenario.minimumBins} ${_english ? 'bins' : 'kutu'} · ${_scenario.minimumBenches} ${_english ? 'benches' : 'bank'}',
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

  String _weatherLabel(BoardwalkWeather weather) => switch (weather) {
    BoardwalkWeather.clear => _english ? 'CLEAR' : 'AÇIK HAVA',
    BoardwalkWeather.breezy => _english ? 'BREEZY' : 'ESİNTİLİ',
    BoardwalkWeather.shower => _english ? 'SHOWERS' : 'SAĞANAK',
  };

  Widget _buildFeedback() => SizedBox(
    height: 22,
    child: Center(
      child: Text(
        _feedback,
        key: const ValueKey<String>('boardwalk_builder_feedback'),
        maxLines: 1,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: StudioVisuals.muted,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _buildBuildPicker() => SizedBox(
    height: 77,
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bounds) {
        final double width = (bounds.maxWidth - 18) / 4;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 3,
          children: BoardwalkBuild.values
              .map((BoardwalkBuild build) {
                final bool selected = build == _selected;
                return SizedBox(
                  width: width,
                  height: 36,
                  child: OutlinedButton(
                    key: ValueKey<String>('boardwalk_build_${build.name}'),
                    onPressed: _finished ? null : () => _choose(build),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      backgroundColor: selected
                          ? const Color(0xFFDDECE9)
                          : Colors.white,
                      foregroundColor: _ink,
                      side: BorderSide(
                        color: selected ? _accent : const Color(0xFFE1E5E1),
                        width: selected ? 1.4 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      '${build.label(_english)} · ${build.cost}',
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

class _BoardwalkPainter extends CustomPainter {
  const _BoardwalkPainter({
    required this.scenario,
    required this.placements,
    required this.selected,
  });

  final BoardwalkScenario scenario;
  final List<BoardwalkPlacement> placements;
  final BoardwalkBuild selected;
  static const Color _ink = Color(0xFF3A5658);

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 12;
    final double cell = math.min(
      (size.width - inset * 2) / scenario.width,
      (size.height - inset * 2) / scenario.height,
    );
    final Rect board = Rect.fromLTWH(
      inset,
      inset,
      cell * scenario.width,
      cell * scenario.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(board.inflate(5), const Radius.circular(17)),
      Paint()..color = const Color(0xFFD8E8E3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(13)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFE7D8BD),
            Color(0xFFF1E7D4),
            Color(0xFFE3D3B5),
          ],
        ).createShader(board),
    );
    for (int y = 0; y < scenario.height; y++) {
      for (int x = 0; x < scenario.width; x++) {
        final BoardwalkCell position = BoardwalkCell(x, y);
        final Rect tile = Rect.fromLTWH(
          inset + x * cell,
          inset + y * cell,
          cell,
          cell,
        ).deflate(1.1);
        if (scenario.blockedCells.contains(position)) {
          _drawRock(canvas, tile);
          continue;
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(tile, const Radius.circular(5)),
          Paint()
            ..color = (x + y).isEven
                ? const Color(0x1FFFFFFF)
                : const Color(0x11000000),
        );
        if (position == scenario.entry) {
          _drawEntry(canvas, tile);
        }
      }
    }
    for (final BoardwalkPlacement placement in placements) {
      final Rect tile = Rect.fromLTWH(
        inset + placement.cell.x * cell,
        inset + placement.cell.y * cell,
        cell,
        cell,
      ).deflate(2.1);
      if (placement.build == BoardwalkBuild.path) {
        _drawPath(canvas, tile);
      } else {
        _drawFacility(canvas, tile, placement.build);
      }
    }
    _drawWaterline(canvas, board, cell);
  }

  void _drawEntry(Canvas canvas, Rect rect) {
    final Rect door = rect.deflate(rect.width * .18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(door, const Radius.circular(6)),
      Paint()..color = const Color(0xFF679A94),
    );
    _text(canvas, rect, 'GATE', const Color(0xFFFFFFFF), rect.width * .16);
  }

  void _drawPath(Canvas canvas, Rect rect) {
    final RRect deck = RRect.fromRectAndRadius(
      rect.deflate(rect.width * .08),
      const Radius.circular(5),
    );
    canvas.drawRRect(deck, Paint()..color = const Color(0xFFB8895D));
    canvas.drawRRect(
      deck,
      Paint()
        ..color = const Color(0x22502F1D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (int i = 1; i <= 2; i++) {
      final double y = rect.top + rect.height * i / 3;
      canvas.drawLine(
        Offset(rect.left + 3, y),
        Offset(rect.right - 3, y),
        Paint()
          ..color = const Color(0x55F7E2BE)
          ..strokeWidth = 1,
      );
    }
  }

  void _drawFacility(Canvas canvas, Rect rect, BoardwalkBuild build) {
    final Color color = switch (build) {
      BoardwalkBuild.carousel => const Color(0xFFE79573),
      BoardwalkBuild.pierWheel => const Color(0xFF7899B0),
      BoardwalkBuild.snackBar => const Color(0xFFD2A75D),
      BoardwalkBuild.bench => const Color(0xFF947151),
      BoardwalkBuild.litterBin => const Color(0xFF71977A),
      BoardwalkBuild.shadeCanopy => const Color(0xFF75A89C),
      BoardwalkBuild.lamp => const Color(0xFFE5CB84),
      BoardwalkBuild.path => const Color(0xFFB8895D),
    };
    final Rect body = rect.deflate(rect.width * .1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.shift(const Offset(0, 1.4)),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0x30000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(7)),
      Paint()..color = color,
    );
    switch (build) {
      case BoardwalkBuild.carousel:
        final Offset center = body.center.translate(0, -body.height * .05);
        canvas.drawCircle(
          center,
          body.width * .23,
          Paint()..color = const Color(0xFFFFF6E9),
        );
        for (int i = 0; i < 4; i++) {
          final double angle = math.pi / 2 * i;
          canvas.drawCircle(
            Offset(
              center.dx + math.cos(angle) * body.width * .26,
              center.dy + math.sin(angle) * body.width * .26,
            ),
            body.width * .045,
            Paint()..color = _ink,
          );
        }
        _text(
          canvas,
          Rect.fromLTWH(
            body.left,
            body.bottom - body.height * .34,
            body.width,
            body.height * .24,
          ),
          'RIDE',
          Colors.white,
          body.width * .14,
        );
      case BoardwalkBuild.pierWheel:
        final Offset center = Offset(
          body.center.dx,
          body.center.dy - body.height * .04,
        );
        final double radius = body.width * .27;
        final Paint spoke = Paint()
          ..color = const Color(0xFFEAF2F4)
          ..strokeWidth = 1.3;
        canvas.drawCircle(center, radius, spoke..style = PaintingStyle.stroke);
        for (int i = 0; i < 6; i++) {
          final double angle = math.pi * i / 3;
          canvas.drawLine(
            center,
            Offset(
              center.dx + math.cos(angle) * radius,
              center.dy + math.sin(angle) * radius,
            ),
            spoke..style = PaintingStyle.stroke,
          );
        }
        canvas.drawCircle(
          center,
          radius * .16,
          Paint()..color = const Color(0xFFEAF2F4),
        );
        _text(
          canvas,
          Rect.fromLTWH(
            body.left,
            body.bottom - body.height * .25,
            body.width,
            body.height * .18,
          ),
          'WHEEL',
          Colors.white,
          body.width * .12,
        );
      case BoardwalkBuild.snackBar:
        final Path roof = Path()
          ..moveTo(body.left + body.width * .16, body.top + body.height * .43)
          ..lineTo(body.center.dx, body.top + body.height * .18)
          ..lineTo(body.right - body.width * .16, body.top + body.height * .43)
          ..close();
        canvas.drawPath(roof, Paint()..color = const Color(0xFFF8E8C7));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              body.left + body.width * .23,
              body.top + body.height * .43,
              body.right - body.width * .23,
              body.bottom - body.height * .14,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFFBF5E9),
        );
        canvas.drawLine(
          Offset(body.center.dx, body.top + body.height * .48),
          Offset(body.center.dx, body.bottom - body.height * .14),
          Paint()
            ..color = color
            ..strokeWidth = 1.5,
        );
        _text(
          canvas,
          Rect.fromLTWH(
            body.left,
            body.bottom - body.height * .15,
            body.width,
            body.height * .13,
          ),
          'CAFE',
          _ink,
          body.width * .12,
        );
      case BoardwalkBuild.bench:
        final Rect seat = Rect.fromCenter(
          center: body.center,
          width: body.width * .53,
          height: body.height * .2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(seat, const Radius.circular(2)),
          Paint()..color = const Color(0xFFF2D4A8),
        );
        canvas.drawLine(
          Offset(seat.left, seat.bottom),
          Offset(seat.left, seat.bottom + body.height * .16),
          Paint()
            ..color = _ink
            ..strokeWidth = 1.5,
        );
        canvas.drawLine(
          Offset(seat.right, seat.bottom),
          Offset(seat.right, seat.bottom + body.height * .16),
          Paint()
            ..color = _ink
            ..strokeWidth = 1.5,
        );
      case BoardwalkBuild.litterBin:
        final Rect bin = Rect.fromCenter(
          center: body.center,
          width: body.width * .34,
          height: body.height * .42,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bin, const Radius.circular(3)),
          Paint()..color = const Color(0xFFE5F1E4),
        );
        canvas.drawLine(
          Offset(bin.left - 1, bin.top),
          Offset(bin.right + 1, bin.top),
          Paint()
            ..color = _ink
            ..strokeWidth = 1.5,
        );
        canvas.drawLine(
          Offset(bin.center.dx, bin.top + 2),
          Offset(bin.center.dx, bin.bottom - 2),
          Paint()
            ..color = color
            ..strokeWidth = 1.4,
        );
      case BoardwalkBuild.shadeCanopy:
        final Path canopy = Path()
          ..moveTo(body.left + body.width * .18, body.top + body.height * .62)
          ..quadraticBezierTo(
            body.center.dx,
            body.top + body.height * .05,
            body.right - body.width * .18,
            body.top + body.height * .62,
          )
          ..close();
        canvas.drawPath(canopy, Paint()..color = const Color(0xFFE3F0E7));
        canvas.drawLine(
          Offset(body.left + body.width * .25, body.top + body.height * .58),
          Offset(body.left + body.width * .25, body.bottom - body.height * .12),
          Paint()
            ..color = _ink
            ..strokeWidth = 1.3,
        );
        canvas.drawLine(
          Offset(body.right - body.width * .25, body.top + body.height * .58),
          Offset(
            body.right - body.width * .25,
            body.bottom - body.height * .12,
          ),
          Paint()
            ..color = _ink
            ..strokeWidth = 1.3,
        );
      case BoardwalkBuild.lamp:
        canvas.drawLine(
          Offset(body.center.dx, body.top + body.height * .25),
          Offset(body.center.dx, body.bottom - body.height * .12),
          Paint()
            ..color = const Color(0xFFFAF3D3)
            ..strokeWidth = 2,
        );
        canvas.drawCircle(
          Offset(body.center.dx, body.top + body.height * .26),
          body.width * .13,
          Paint()..color = const Color(0xFFFFF4BB),
        );
        canvas.drawCircle(
          Offset(body.center.dx, body.top + body.height * .26),
          body.width * .22,
          Paint()..color = const Color(0x44FFF4BB),
        );
      case BoardwalkBuild.path:
        break;
    }
  }

  void _drawRock(Canvas canvas, Rect rect) {
    final Path rock = Path()
      ..moveTo(rect.left + rect.width * .16, rect.bottom - rect.height * .16)
      ..lineTo(rect.left + rect.width * .22, rect.top + rect.height * .45)
      ..lineTo(rect.center.dx, rect.top + rect.height * .2)
      ..lineTo(rect.right - rect.width * .12, rect.top + rect.height * .45)
      ..lineTo(rect.right - rect.width * .2, rect.bottom - rect.height * .16)
      ..close();
    canvas.drawPath(rock, Paint()..color = const Color(0xFF9DA8A2));
    canvas.drawPath(
      rock,
      Paint()
        ..color = const Color(0x33708078)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top + rect.height * .35),
      Offset(
        rect.center.dx - rect.width * .12,
        rect.bottom - rect.height * .24,
      ),
      Paint()
        ..color = const Color(0x55737F78)
        ..strokeWidth = 1,
    );
  }

  void _drawWaterline(Canvas canvas, Rect board, double cell) {
    final Paint paint = Paint()
      ..color = const Color(0x447CAEB0)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final double y = board.top + cell * (.18 + .11 * i);
      canvas.drawLine(
        Offset(board.left + cell * .12, y),
        Offset(board.left + cell * .32, y),
        paint,
      );
      canvas.drawLine(
        Offset(board.right - cell * .34, y + cell * .1),
        Offset(board.right - cell * .1, y + cell * .1),
        paint,
      );
    }
  }

  void _text(
    Canvas canvas,
    Rect rect,
    String value,
    Color color,
    double fontSize,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize.clamp(5, 9),
          fontWeight: FontWeight.w900,
          letterSpacing: .2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textAlign: TextAlign.center,
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
  bool shouldRepaint(covariant _BoardwalkPainter oldDelegate) =>
      oldDelegate.scenario != scenario ||
      oldDelegate.selected != selected ||
      oldDelegate.placements != placements;
}
