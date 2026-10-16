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
import 'interior_engine.dart';
import 'interior_scenario.dart';

class InteriorStudioGamePage extends StatelessWidget {
  const InteriorStudioGamePage({super.key});

  static const int totalCases = InteriorScenario.campaignLevels;
  static const int totalStars = totalCases * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Tasarım ${level.toString().padLeft(2, '0')}',
        titleEn: 'Design ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Brief’i oku; bütçeyi aşmadan temel eşyaları yerleştir.',
          <= 6 => 'Stil ve renk uyumuyla pencere ışığını birlikte kullan.',
          7 || 8 => 'İleri: büyük eşyalar arasında geçiş koridoru bırak.',
          9 || 10 => 'Uzman: dar odada tüm şartları ve ışık yönünü dengele.',
          <= 16 => 'Usta: sınırlı bütçeyle altı parçalı brief’i çöz.',
          _ => 'Final: büyük mobilyalar, dar dolaşım ve tam stil uyumu.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Read the brief and place essentials without overspending.',
          <= 6 => 'Balance style, palette and natural window light.',
          7 || 8 => 'Advanced: preserve circulation between larger pieces.',
          9 || 10 => 'Expert: balance every constraint in a compact room.',
          <= 16 => 'Master: solve a six-piece brief on a limited budget.',
          _ => 'Final: large furniture, tight circulation and full style fit.',
        },
        difficulty: switch (level) {
          <= 3 => 'TEMEL',
          <= 6 => 'STİL',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.chair_alt_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'interior_studio',
      progressPrefix: 'interior_studio',
      titleTr: 'İç Mekân Atölyesi',
      titleEn: 'Interior Studio',
      taglineTr: 'Brief’i çöz • Alanı kur • Tasarımını değerlendir',
      taglineEn: 'Read the brief • Place with purpose • Review the room',
      accent: skin.accent,
      icon: Icons.chair_alt_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => InteriorStudioPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class InteriorStudioPlayPage extends StatefulWidget {
  const InteriorStudioPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<InteriorStudioPlayPage> createState() => _InteriorStudioPlayPageState();
}

class _InteriorStudioPlayPageState extends State<InteriorStudioPlayPage> {
  static const Color _ink = Color(0xFF454944);
  static const Color _accent = Color(0xFF788C76);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late InteriorScenario _scenario;
  late InteriorEngine _engine;
  late StudioGameSession _session;
  InteriorFurniture? _selectedFurniture;
  InteriorPalette _selectedPalette = InteriorPalette.linen;
  bool _rotated = false;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';
  InteriorEvaluation? _lastEvaluation;

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareRoom());
  }

  Future<void> _prepareRoom() async {
    InteriorScenario scenario = InteriorScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      final String visitKey =
          'interior_studio_level_${widget.level.number}_visits';
      final int visits = await preferences.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await preferences.getInt('interior_studio_practice_index') ?? 0;
        if (index < InteriorScenario.practiceScenarios) {
          final int next = index + 1;
          await preferences.setInt('interior_studio_practice_index', next);
          scenario = InteriorScenario.forPractice(next);
        }
      }
      await preferences.setInt(visitKey, visits + 1);
    } catch (_) {
      // The authored room remains playable if local preferences are unavailable.
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = InteriorEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    _selectedFurniture = scenario.requirements.first;
    _selectedPalette = scenario.palette;
    setState(() {
      _feedback = _english
          ? 'Place every required piece, keep the entry clear and use the window.'
          : 'Zorunlu eşyaları yerleştir; kapı yolunu açık, pencereyi işlevli tut.';
      _ready = true;
    });
  }

  void _tapRoom(Offset localPosition, Size size) {
    if (!_ready || _finished) return;
    const double inset = 13;
    final double cell = math.min(
      (size.width - inset * 2) / _scenario.width,
      (size.height - inset * 2) / _scenario.height,
    );
    final int x = ((localPosition.dx - inset) / cell).floor();
    final int y = ((localPosition.dy - inset) / cell).floor();
    if (x < 0 || y < 0 || x >= _scenario.width || y >= _scenario.height) {
      return;
    }
    final InteriorActionResult result = _engine.removeAt(x, y);
    if (result.accepted) {
      setState(() {
        _lastEvaluation = null;
        _feedback = _english
            ? 'Piece removed. Choose another item or undo.'
            : 'Eşya kaldırıldı. Yeni parça seçebilir veya geri alabilirsin.';
      });
      unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .14));
      return;
    }
    final InteriorFurniture? furniture = _selectedFurniture;
    if (furniture == null) return;
    final InteriorActionResult placed = _engine.place(
      furniture: furniture,
      x: x,
      y: y,
      rotated: _rotated,
      palette: _selectedPalette,
    );
    setState(() {
      _lastEvaluation = null;
      _feedback = placed.accepted
          ? (_english
                ? '${furniture.label(true)} placed · ${furniture.cost} credits'
                : '${furniture.label(false)} yerleşti · ${furniture.cost} kredi')
          : _reason(placed.reason);
    });
    unawaited(
      _audioProfile.play(
        _audio,
        placed.accepted ? GameAudioEvent.accepted : GameAudioEvent.rejected,
        gain: .18,
      ),
    );
    if (placed.accepted) _audio.hapticLight();
  }

  String _reason(String reason) => switch (reason) {
    'already_placed' =>
      _english
          ? 'That piece is already in the room.'
          : 'Bu parçadan odada zaten var.',
    'outside_room' =>
      _english
          ? 'The piece does not fit inside the room.'
          : 'Eşya odanın dışına taşıyor.',
    'door_blocked' =>
      _english
          ? 'Keep the entry tile clear.'
          : 'Giriş kapısının önünü açık bırak.',
    'overlap' =>
      _english
          ? 'Furniture cannot overlap.'
          : 'Eşyalar birbirinin üstüne gelemez.',
    'over_budget' =>
      _english
          ? 'That would exceed the visible budget.'
          : 'Bu yerleşim görünen bütçeyi aşıyor.',
    _ => _english ? 'Choose a free tile.' : 'Boş bir kare seç.',
  };

  void _selectFurniture(InteriorFurniture furniture) {
    if (_finished) return;
    setState(() {
      _selectedFurniture = furniture;
      _rotated = false;
      _feedback = _english
          ? 'Tap a clear tile. Tap placed furniture to remove it.'
          : 'Boş kareye dokunarak yerleştir; yerleşik eşyaya dokunarak kaldır.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _history(bool undo) {
    final bool changed = undo ? _engine.undo() : _engine.redo();
    if (!changed) return;
    setState(() {
      _lastEvaluation = null;
      _feedback = undo
          ? (_english
                ? 'Last layout change undone.'
                : 'Son yerleşim geri alındı.')
          : (_english
                ? 'Layout change restored.'
                : 'Yerleşim yeniden yapıldı.');
    });
    unawaited(_audio.play(GameSound.uiClick, gain: .18));
  }

  int get _stars {
    final InteriorEvaluation? evaluation = _lastEvaluation;
    if (evaluation == null) return 0;
    if (evaluation.score >= 94) return 3;
    if (evaluation.score >= 83) return 2;
    return 1;
  }

  Future<void> _submitDesign() async {
    if (_finished) return;
    final InteriorEvaluation evaluation = _engine.evaluate();
    setState(() => _lastEvaluation = evaluation);
    if (!evaluation.canSubmit) {
      final List<String> missing = <String>[];
      if (evaluation.requiredPlaced < evaluation.requiredCount) {
        missing.add(_english ? 'required pieces' : 'zorunlu eşyalar');
      }
      if (evaluation.budgetUsed > evaluation.budget) {
        missing.add(_english ? 'budget' : 'bütçe');
      }
      if (!evaluation.windowUsed) {
        missing.add(_english ? 'window use' : 'pencere kullanımı');
      }
      if (evaluation.styleFit < .6) {
        missing.add(_english ? 'style match' : 'stil uyumu');
      }
      if (evaluation.paletteFit < .6) {
        missing.add(_english ? 'palette match' : 'renk uyumu');
      }
      if (evaluation.accessibleRatio < .35) {
        missing.add(_english ? 'walkway' : 'geçiş alanı');
      }
      setState(
        () => _feedback = _english
            ? 'Brief incomplete: ${missing.join(' · ')}'
            : 'Brief tamamlanmadı: ${missing.join(' · ')}',
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
      return;
    }
    _finished = true;
    final int stars = _stars;
    _session.complete(
      stars: stars,
      action: widget.level.number < InteriorStudioGamePage.totalCases
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
      titleTr: 'TASARIM ONAYLANDI',
      titleEn: 'DESIGN APPROVED',
      detailTr:
          'Brief ${evaluation.requiredPlaced}/${evaluation.requiredCount} · bütçe ${evaluation.budgetUsed}/${evaluation.budget} · puan ${evaluation.score}',
      detailEn:
          'Brief ${evaluation.requiredPlaced}/${evaluation.requiredCount} · budget ${evaluation.budgetUsed}/${evaluation.budget} · score ${evaluation.score}',
      stars: stars,
      score: evaluation.score * 100,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < InteriorStudioGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
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
        appBar: AppBar(
          title: Text(_english ? 'INTERIOR STUDIO' : 'İÇ MEKÂN ATÖLYESİ'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final InteriorEvaluation evaluation = _engine.evaluate();
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          _english
              ? 'STUDIO · DESIGN ${widget.level.number}'
              : 'ATÖLYE · TASARIM ${widget.level.number}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('interior_studio_undo'),
            tooltip: _english ? 'Undo' : 'Geri al',
            onPressed: _engine.canUndo ? () => _history(true) : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('interior_studio_redo'),
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
                    aspectRatio: 1.17,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints bounds) =>
                          GestureDetector(
                            key: const ValueKey<String>('interior_studio_room'),
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (TapUpDetails details) => _tapRoom(
                              details.localPosition,
                              Size(bounds.maxWidth, bounds.maxHeight),
                            ),
                            child: CustomPaint(
                              painter: _InteriorPainter(
                                scenario: _scenario,
                                placements: _engine.placements,
                                previewFurniture: _selectedFurniture,
                                previewRotated: _rotated,
                                previewPalette: _selectedPalette,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildFeedback(),
              const SizedBox(height: 4),
              _buildPalettePicker(),
              const SizedBox(height: 4),
              _buildFurniturePicker(),
              const SizedBox(height: 5),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  key: const ValueKey<String>('interior_studio_evaluate'),
                  onPressed: _finished ? null : _submitDesign,
                  style: FilledButton.styleFrom(
                    backgroundColor: evaluation.canSubmit ? _accent : _ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.fact_check_rounded),
                  label: Text(
                    _english ? 'REVIEW DESIGN' : 'TASARIMI DEĞERLENDİR',
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

  Widget _buildHud(InteriorEvaluation evaluation) {
    final int remaining = _scenario.budget - evaluation.budgetUsed;
    return Container(
      key: const ValueKey<String>('interior_studio_hud'),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1D8)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.payments_rounded, size: 17, color: _accent),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '${evaluation.budgetUsed} / ${evaluation.budget}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: remaining >= 0
                  ? const Color(0xFFEAF1E8)
                  : const Color(0xFFF8E8E3),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${_scenario.style.label(_english)} · ${_scenario.palette.label(_english)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrief() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0E8),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.description_outlined, size: 17, color: _accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_english ? 'BRIEF' : 'BRİEF'} · ${_scenario.style.label(_english)}  •  ${_scenario.requirements.map((InteriorFurniture item) => item.label(_english)).join(' · ')}',
              key: const ValueKey<String>('interior_studio_brief'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 9,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback() {
    return SizedBox(
      height: 26,
      child: Center(
        child: Text(
          _feedback,
          key: const ValueKey<String>('interior_studio_feedback'),
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPalettePicker() {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ...InteriorPalette.values.map((InteriorPalette palette) {
            final bool selected = _selectedPalette == palette;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                key: ValueKey<String>('interior_palette_${palette.name}'),
                label: Text(
                  palette.label(_english),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                selected: selected,
                onSelected: (_) => setState(() {
                  _selectedPalette = palette;
                  _lastEvaluation = null;
                }),
                selectedColor: const Color(0xFFE5ECE1),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(
                  color: selected ? _accent : const Color(0xFFE2DED6),
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 3),
              ),
            );
          }),
          IconButton(
            key: const ValueKey<String>('interior_studio_rotate'),
            tooltip: _english ? 'Rotate 90°' : '90° döndür',
            onPressed: _finished
                ? null
                : () => setState(() {
                    _rotated = !_rotated;
                    _lastEvaluation = null;
                  }),
            icon: const Icon(Icons.rotate_90_degrees_cw_rounded, size: 19),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildFurniturePicker() {
    return SizedBox(
      height: 72,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double itemWidth = (constraints.maxWidth - 18) / 4;
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 2,
            children: InteriorFurniture.values
                .map((InteriorFurniture item) {
                  final bool selected = _selectedFurniture == item;
                  final bool placed = _engine.placements.any(
                    (InteriorPlacement p) => p.furniture == item,
                  );
                  return SizedBox(
                    width: itemWidth,
                    height: 34,
                    child: OutlinedButton(
                      key: ValueKey<String>('interior_item_${item.name}'),
                      onPressed: placed ? null : () => _selectFurniture(item),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        backgroundColor: selected
                            ? const Color(0xFFE7EEE4)
                            : Colors.white,
                        foregroundColor: _ink,
                        side: BorderSide(
                          color: selected ? _accent : const Color(0xFFE2DED6),
                          width: selected ? 1.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Text(
                        '${item.label(_english)}${placed ? ' ✓' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8,
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
}

class _InteriorPainter extends CustomPainter {
  const _InteriorPainter({
    required this.scenario,
    required this.placements,
    required this.previewFurniture,
    required this.previewRotated,
    required this.previewPalette,
  });

  final InteriorScenario scenario;
  final List<InteriorPlacement> placements;
  final InteriorFurniture? previewFurniture;
  final bool previewRotated;
  final InteriorPalette previewPalette;

  static const Color _wall = Color(0xFFDDD7CC);
  static const Color _floorA = Color(0xFFF5F0E7);
  static const Color _floorB = Color(0xFFEFE9DE);
  static const Color _ink = Color(0xFF55564F);

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 13;
    final double cell = math.min(
      (size.width - inset * 2) / scenario.width,
      (size.height - inset * 2) / scenario.height,
    );
    final Rect room = Rect.fromLTWH(
      inset,
      inset,
      cell * scenario.width,
      cell * scenario.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(room.inflate(4), const Radius.circular(13)),
      Paint()..color = _wall,
    );
    for (int y = 0; y < scenario.height; y++) {
      for (int x = 0; x < scenario.width; x++) {
        final Rect tile = Rect.fromLTWH(
          inset + x * cell,
          inset + y * cell,
          cell,
          cell,
        ).deflate(1.3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(tile, const Radius.circular(4)),
          Paint()..color = (x + y).isEven ? _floorA : _floorB,
        );
      }
    }
    final Rect window = Rect.fromLTWH(
      inset + scenario.windowX * cell + cell * .15,
      inset - 3,
      cell * .7,
      5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(3)),
      Paint()..color = const Color(0xFF9EC5C7),
    );
    final Rect door = Rect.fromLTWH(
      inset + scenario.doorX * cell + cell * .12,
      inset + scenario.height * cell - 3,
      cell * .76,
      6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(door, const Radius.circular(3)),
      Paint()..color = const Color(0xFFB68A5E),
    );

    for (final InteriorPlacement item in placements) {
      _drawFurniture(
        canvas,
        Rect.fromLTWH(
          inset + item.x * cell + 2,
          inset + item.y * cell + 2,
          item.width * cell - 4,
          item.height * cell - 4,
        ),
        item.furniture,
        item.palette,
      );
    }
    if (previewFurniture != null &&
        !placements.any(
          (InteriorPlacement p) => p.furniture == previewFurniture,
        )) {
      final (int width, int height) = previewFurniture!.footprint;
      final bool rotated = previewRotated;
      final int previewWidth = rotated ? height : width;
      final int previewHeight = rotated ? width : height;
      final Rect swatch = Rect.fromLTWH(
        inset + (scenario.width - previewWidth) * cell / 2 + 2,
        inset + (scenario.height - previewHeight) * cell / 2 + 2,
        previewWidth * cell - 4,
        previewHeight * cell - 4,
      );
      _drawFurniture(
        canvas,
        swatch,
        previewFurniture!,
        previewPalette,
        preview: true,
      );
    }
    _drawRoomLabel(canvas, size, room);
  }

  void _drawRoomLabel(Canvas canvas, Size size, Rect room) {
    final TextPainter painter = TextPainter(
      text: const TextSpan(
        text: 'WINDOW',
        style: TextStyle(
          color: Color(0xFF668B8A),
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(room.left, 1));
    final TextPainter doorLabel = TextPainter(
      text: const TextSpan(
        text: 'ENTRY',
        style: TextStyle(
          color: Color(0xFF8A6C4B),
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    doorLabel.paint(
      canvas,
      Offset(room.right - doorLabel.width, room.bottom + 4),
    );
  }

  void _drawFurniture(
    Canvas canvas,
    Rect rect,
    InteriorFurniture type,
    InteriorPalette palette, {
    bool preview = false,
  }) {
    final Color color = switch (palette) {
      InteriorPalette.linen => const Color(0xFFC9B89F),
      InteriorPalette.sage => const Color(0xFF8BA38C),
      InteriorPalette.terracotta => const Color(0xFFC7866C),
    };
    final Color alphaColor = color.withValues(alpha: preview ? .52 : 1);
    canvas.drawShadow(
      Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(7))),
      Colors.black.withValues(alpha: .17),
      2,
      true,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()..color = alphaColor,
    );
    final IconData icon = switch (type) {
      InteriorFurniture.sofa => Icons.weekend_rounded,
      InteriorFurniture.bed => Icons.bed_rounded,
      InteriorFurniture.desk => Icons.desk_rounded,
      InteriorFurniture.plant => Icons.local_florist_rounded,
      InteriorFurniture.lamp => Icons.light_rounded,
      InteriorFurniture.bookshelf => Icons.auto_stories_rounded,
      InteriorFurniture.diningTable => Icons.table_restaurant_rounded,
    };
    final double iconSize = math.min(rect.width, rect.height) * .53;
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: iconSize,
          color: _ink.withValues(alpha: preview ? .7 : 1),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _InteriorPainter oldDelegate) =>
      oldDelegate.scenario.signature != scenario.signature ||
      oldDelegate.placements != placements ||
      oldDelegate.previewFurniture != previewFurniture ||
      oldDelegate.previewRotated != previewRotated ||
      oldDelegate.previewPalette != previewPalette;
}
