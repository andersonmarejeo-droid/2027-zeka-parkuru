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
import 'curator_engine.dart';
import 'curator_scenario.dart';

class MuseumCuratorGamePage extends StatelessWidget {
  const MuseumCuratorGamePage({super.key});
  static const int totalExhibitions = CuratorScenario.campaignLevels;
  static const int totalStars = totalExhibitions * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalExhibitions,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Sergi ${level.toString().padLeft(2, '0')}',
        titleEn: 'Exhibit ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Koleksiyondan seç; sergiye bir anlatı yolu kur.',
          <= 6 => 'Dönem sırasını ve eser korumasını birlikte gözet.',
          7 || 8 => 'İleri: kısıtlı bütçeyle ziyaretçi ilgisini yükselt.',
          9 || 10 => 'Uzman: tema, kronoloji ve hassas eserleri uzlaştır.',
          <= 16 => 'Usta: kalabalık koleksiyonda tutarlı sergi tasarla.',
          _ => 'Final: yedi eser, sıkı koruma ve yüksek ilgi eşiği.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Select from the collection and shape a story path.',
          <= 6 => 'Balance chronology with artifact preservation.',
          7 || 8 => 'Advanced: raise visitor appeal on a tight budget.',
          9 || 10 => 'Expert: reconcile theme, chronology and fragile pieces.',
          <= 16 => 'Master: curate a coherent show from a broad collection.',
          _ => 'Final: seven objects, strict conservation and high appeal.',
        },
        difficulty: switch (level) {
          <= 3 => 'GALERİ',
          <= 6 => 'ANLATI',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.museum_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'museum_curator',
      progressPrefix: 'museum_curator',
      titleTr: 'Müze Küratörü',
      titleEn: 'Museum Curator',
      taglineTr: 'Eser seç • Anlatı kur • Koleksiyonu koru',
      taglineEn: 'Select objects • Shape a story • Protect the collection',
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
          ) => MuseumCuratorPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class MuseumCuratorPlayPage extends StatefulWidget {
  const MuseumCuratorPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });
  final ParkurLevelSpec level;
  final int previousBestScore;
  @override
  State<MuseumCuratorPlayPage> createState() => _MuseumCuratorPlayPageState();
}

class _MuseumCuratorPlayPageState extends State<MuseumCuratorPlayPage> {
  static const Color _accent = Color(0xFF947D5B);
  static const Color _ink = Color(0xFF484741);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late CuratorScenario _scenario;
  late CuratorEngine _engine;
  late StudioGameSession _session;
  CuratorArtifact? _selected;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareExhibit());
  }

  Future<void> _prepareExhibit() async {
    CuratorScenario scenario = CuratorScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String visitKey =
          'museum_curator_level_${widget.level.number}_visits';
      final int visits = await prefs.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await prefs.getInt('museum_curator_practice_index') ?? 0;
        if (index < CuratorScenario.practiceExhibitions) {
          final int next = index + 1;
          await prefs.setInt('museum_curator_practice_index', next);
          scenario = CuratorScenario.forPractice(next);
        }
      }
      await prefs.setInt(visitKey, visits + 1);
    } catch (_) {
      // The authored exhibit remains available without persisted preferences.
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = CuratorEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    setState(() {
      _english = context.l10n.isEnglish;
      _selected = scenario.collection.firstWhere(
        (CuratorArtifact artifact) => artifact.themes.contains(scenario.theme),
      );
      _feedback = _english
          ? 'Choose an object, then tap a gallery pedestal to place it.'
          : 'Bir eser seç; yerleştirmek için galerideki kaideye dokun.';
      _ready = true;
    });
  }

  void _tapGallery(Offset position, Size size) {
    if (!_ready || _finished) return;
    const double inset = 14;
    final double width = (size.width - inset * 2) / _scenario.slotCount;
    final int slot = ((position.dx - inset) / width).floor();
    if (slot < 0 || slot >= _scenario.slotCount) return;
    if (_engine.slots[slot] != null) {
      final CuratorActionResult result = _engine.remove(slot);
      if (result.accepted) {
        setState(
          () => _feedback = _english
              ? 'Pedestal cleared · select a different object.'
              : 'Kaide boşaltıldı · başka bir eser seç.',
        );
        unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .14));
      }
      return;
    }
    final CuratorArtifact? item = _selected;
    if (item == null) {
      setState(
        () => _feedback = _english
            ? 'Select an object from the collection first.'
            : 'Önce koleksiyondan bir eser seç.',
      );
      return;
    }
    final CuratorActionResult result = _engine.place(slot, item);
    setState(() => _feedback = _actionText(result.reason, item));
    unawaited(
      _audioProfile.play(
        _audio,
        result.accepted ? GameAudioEvent.accepted : GameAudioEvent.rejected,
        gain: .17,
      ),
    );
    if (result.accepted) {
      _session.recordAccepted(points: 10);
      _audio.hapticLight();
    } else {
      _session.recordMistake();
    }
  }

  String _actionText(String reason, CuratorArtifact item) => switch (reason) {
    'already_displayed' =>
      _english
          ? 'That object already has a pedestal.'
          : 'Bu eser galeride zaten sergileniyor.',
    'slot_outside' =>
      _english ? 'Choose a valid pedestal.' : 'Geçerli bir kaide seç.',
    'displayed' =>
      _english
          ? '${item.label(true)} placed · era ${item.era}.'
          : '${item.label(false)} yerleşti · dönem ${item.era}.',
    _ =>
      _english
          ? 'Select from the current collection.'
          : 'Mevcut koleksiyondan bir eser seç.',
  };

  void _select(CuratorArtifact artifact) {
    if (_finished || _engine.slots.contains(artifact)) return;
    setState(() {
      _selected = artifact;
      _feedback = _english
          ? '${artifact.label(true)} · era ${artifact.era} · ${artifact.fragile == 1 ? 'fragile' : 'stable'}'
          : '${artifact.label(false)} · dönem ${artifact.era} · ${artifact.fragile == 1 ? 'hassas' : 'dayanıklı'}';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _history(bool undo) {
    final bool changed = undo ? _engine.undo() : _engine.redo();
    if (!changed) return;
    setState(
      () => _feedback = undo
          ? (_english
                ? 'Last curatorial choice undone.'
                : 'Son küratör seçimi geri alındı.')
          : (_english
                ? 'Curatorial choice restored.'
                : 'Küratör seçimi geri yüklendi.'),
    );
    unawaited(_audio.play(GameSound.uiClick, gain: .18));
  }

  Future<void> _openExhibition() async {
    if (_finished) return;
    final CuratorEvaluation result = _engine.evaluate();
    if (!result.canOpen) {
      final List<String> missing = <String>[];
      if (result.placed < result.slots) {
        missing.add(_english ? 'empty pedestals' : 'boş kaideler');
      }
      if (result.themeFit < result.slots) {
        missing.add(_english ? 'theme match' : 'tema uyumu');
      }
      if (!result.chronologyFit) {
        missing.add(_english ? 'era sequence' : 'dönem sırası');
      }
      if (result.fragileCount > result.fragileLimit) {
        missing.add(_english ? 'conservation' : 'eser koruma');
      }
      if (result.visitorAppeal < result.visitorTarget) {
        missing.add(_english ? 'visitor interest' : 'ziyaretçi ilgisi');
      }
      if (result.budgetUsed > result.budget) {
        missing.add(_english ? 'budget' : 'bütçe');
      }
      setState(
        () => _feedback = _english
            ? 'Curator review: ${missing.join(' · ')}'
            : 'Küratör kontrolü: ${missing.join(' · ')}',
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
      return;
    }
    _finished = true;
    final int stars = result.score >= 94 ? 3 : (result.score >= 82 ? 2 : 1);
    _session.complete(
      stars: stars,
      action: widget.level.number < MuseumCuratorGamePage.totalExhibitions
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
      titleTr: 'SERGİ KAPILARI AÇILDI!',
      titleEn: 'EXHIBITION OPEN!',
      detailTr:
          '${result.themeFit}/${result.slots} temalı eser · ilgi ${result.visitorAppeal} · puan ${result.score}',
      detailEn:
          '${result.themeFit}/${result.slots} themed objects · appeal ${result.visitorAppeal} · score ${result.score}',
      stars: stars,
      score: result.score * 100,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < MuseumCuratorGamePage.totalExhibitions,
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
          title: Text(_english ? 'MUSEUM CURATOR' : 'MÜZE KÜRATÖRÜ'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final CuratorEvaluation evaluation = _engine.evaluate();
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          '${_english ? 'EXHIBIT' : 'SERGİ'} · ${widget.level.number.toString().padLeft(2, '0')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('museum_curator_undo'),
            tooltip: _english ? 'Undo' : 'Geri al',
            onPressed: _engine.canUndo ? () => _history(true) : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('museum_curator_redo'),
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
                    aspectRatio: 1.7,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints bounds) =>
                          GestureDetector(
                            key: const ValueKey<String>(
                              'museum_curator_gallery',
                            ),
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (TapUpDetails details) => _tapGallery(
                              details.localPosition,
                              Size(bounds.maxWidth, bounds.maxHeight),
                            ),
                            child: CustomPaint(
                              painter: _GalleryPainter(
                                scenario: _scenario,
                                slots: _engine.slots,
                                selected: _selected,
                                english: _english,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 21,
                child: Center(
                  child: Text(
                    _feedback,
                    key: const ValueKey<String>('museum_curator_feedback'),
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
              ),
              const SizedBox(height: 3),
              _collectionPicker(),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  key: const ValueKey<String>('museum_curator_open'),
                  onPressed: _finished ? null : _openExhibition,
                  style: FilledButton.styleFrom(
                    backgroundColor: evaluation.canOpen ? _accent : _ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: Text(
                    _english ? 'OPEN EXHIBITION' : 'SERGİYİ AÇ',
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

  Widget _hud(CuratorEvaluation evaluation) => Container(
    key: const ValueKey<String>('museum_curator_hud'),
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFE7E1D7)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.payments_rounded, size: 15, color: _accent),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${evaluation.budgetUsed}/${evaluation.budget} ₡',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ),
        const Icon(Icons.groups_rounded, size: 15, color: _accent),
        const SizedBox(width: 3),
        Text(
          '${evaluation.visitorAppeal}/${evaluation.visitorTarget}',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.inventory_2_outlined, size: 14, color: _accent),
        const SizedBox(width: 3),
        Text(
          '${evaluation.placed}/${evaluation.slots}',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );

  Widget _brief() => Container(
    key: const ValueKey<String>('museum_curator_brief'),
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF3EFE7),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.description_outlined, size: 16, color: _accent),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            '${_scenario.theme.label(_english)} · ${_scenario.slotCount} ${_english ? 'pedestals' : 'kaide'}\n${_english ? 'Max fragile' : 'Hassas sınırı'} ${_scenario.fragileLimit} · ${_english ? 'era order' : 'dönem sırası'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8,
              height: 1.15,
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _collectionPicker() => SizedBox(
    key: const ValueKey<String>('museum_curator_collection'),
    height: 174,
    child: GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _scenario.collection.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 32,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemBuilder: (BuildContext context, int index) {
        final CuratorArtifact artifact = _scenario.collection[index];
        final bool chosen = artifact == _selected;
        final bool placed = _engine.slots.contains(artifact);
        return OutlinedButton(
          key: ValueKey<String>('museum_artifact_${artifact.id}'),
          onPressed: placed || _finished ? null : () => _select(artifact),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            backgroundColor: placed
                ? const Color(0xFFE9EEE7)
                : (chosen ? const Color(0xFFF0E7D5) : Colors.white),
            foregroundColor: _ink,
            side: BorderSide(
              color: chosen ? _accent : const Color(0xFFE5E2DA),
              width: chosen ? 1.3 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '${artifact.mark}  ${artifact.label(_english)}${placed ? ' ✓' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900),
          ),
        );
      },
    ),
  );
}

class _GalleryPainter extends CustomPainter {
  const _GalleryPainter({
    required this.scenario,
    required this.slots,
    required this.selected,
    required this.english,
  });
  final CuratorScenario scenario;
  final List<CuratorArtifact?> slots;
  final CuratorArtifact? selected;
  final bool english;

  Color get _wall => switch (scenario.theme) {
    MuseumTheme.deepSea => const Color(0xFF42616C),
    MuseumTheme.ancient => const Color(0xFF75634D),
    MuseumTheme.exploration => const Color(0xFF526B69),
    MuseumTheme.naturalWorld => const Color(0xFF65735D),
    MuseumTheme.cosmos => const Color(0xFF4E546B),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final Rect area = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(area, const Radius.circular(15)),
      Paint()..color = _wall,
    );
    final Rect cornice = Rect.fromLTWH(
      size.width * .06,
      size.height * .1,
      size.width * .88,
      size.height * .56,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cornice, const Radius.circular(10)),
      Paint()..color = const Color(0x18FFFFFF),
    );
    canvas.drawLine(
      Offset(size.width * .06, size.height * .75),
      Offset(size.width * .94, size.height * .75),
      Paint()
        ..color = const Color(0x66998A73)
        ..strokeWidth = 2,
    );
    final double width = (size.width - 28) / scenario.slotCount;
    for (int i = 0; i < scenario.slotCount; i++) {
      final double x = 14 + width * i;
      final Rect backing = Rect.fromLTWH(
        x + width * .1,
        size.height * .2,
        width * .8,
        size.height * .44,
      );
      final RRect frame = RRect.fromRectAndRadius(
        backing,
        const Radius.circular(7),
      );
      canvas.drawRRect(frame, Paint()..color = const Color(0xFFE1D5BD));
      canvas.drawRRect(
        frame.deflate(3),
        Paint()..color = const Color(0xFFEEE7D8),
      );
      final CuratorArtifact? artifact = slots[i];
      if (artifact == null) {
        _centerText(
          canvas,
          backing.deflate(3),
          '0${i + 1}',
          const Color(0xFF8F8778),
          width * .21,
        );
      } else {
        canvas.drawCircle(
          Offset(backing.center.dx, backing.center.dy - 1),
          width * .23,
          Paint()..color = _artifactColor(artifact),
        );
        _centerText(
          canvas,
          Rect.fromCenter(
            center: backing.center.translate(0, -1),
            width: width * .42,
            height: width * .34,
          ),
          artifact.mark,
          Colors.white,
          width * .24,
        );
      }
      final Rect pedestal = Rect.fromLTWH(
        x + width * .13,
        size.height * .68,
        width * .74,
        size.height * .12,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pedestal, const Radius.circular(4)),
        Paint()..color = const Color(0xFFC4B69D),
      );
      canvas.drawLine(
        Offset(pedestal.left + 2, pedestal.bottom),
        Offset(pedestal.right - 2, pedestal.bottom),
        Paint()
          ..color = const Color(0xFF806E53)
          ..strokeWidth = 2,
      );
      _centerText(
        canvas,
        Rect.fromLTWH(x, size.height * .84, width, size.height * .1),
        '${i + 1}',
        const Color(0xFFEEE8DB),
        width * .16,
      );
    }
    final CuratorArtifact? preview = selected;
    if (preview != null) {
      final Rect plaque = Rect.fromLTWH(
        size.width * .08,
        size.height * .02,
        size.width * .84,
        size.height * .12,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(plaque, const Radius.circular(6)),
        Paint()..color = const Color(0xAA2E3436),
      );
      _centerText(
        canvas,
        plaque,
        uppercaseUiText(preview.label(english), english: english),
        const Color(0xFFF3E9D7),
        size.width * .025,
      );
    }
  }

  Color _artifactColor(CuratorArtifact artifact) {
    final int code = artifact.id.codeUnits.fold<int>(
      0,
      (int sum, int unit) => sum + unit,
    );
    return Color.lerp(
      const Color(0xFF967654),
      const Color(0xFF64858A),
      (code % 100) / 100,
    )!;
  }

  void _centerText(
    Canvas canvas,
    Rect rect,
    String value,
    Color color,
    double size,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: size.clamp(5, 13).toDouble(),
          fontWeight: FontWeight.w900,
          letterSpacing: .2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
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
  bool shouldRepaint(covariant _GalleryPainter oldDelegate) =>
      oldDelegate.scenario != scenario ||
      oldDelegate.selected != selected ||
      oldDelegate.slots != slots ||
      oldDelegate.english != english;
}
