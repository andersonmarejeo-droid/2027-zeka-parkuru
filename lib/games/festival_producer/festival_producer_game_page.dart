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
import 'festival_engine.dart';
import 'festival_scenario.dart';

class FestivalProducerGamePage extends StatelessWidget {
  const FestivalProducerGamePage({super.key});
  static const int totalFestivals = FestivalScenario.campaignLevels;
  static const int totalStars = totalFestivals * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalFestivals,
    (int index) {
      final int level = index + 1;
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Festival ${level.toString().padLeft(2, '0')}',
        titleEn: 'Festival ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Sanatçıları iki sahne ve sekiz saate yerleştir.',
          <= 6 => 'Kitle ilgisi ve sahne değişim aralığını planla.',
          7 || 8 => 'İleri: sahne kurulumuna nefes payı bırak.',
          9 || 10 => 'Uzman: sağanakta açık hava setini güvene al.',
          <= 16 => 'Usta: ekip, enerji ve kalabalığı zaman diliminde çöz.',
          _ => 'Final: yoğun festival akışını bütçeyi aşmadan yayınla.',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Schedule the acts across two stages and eight time blocks.',
          <= 6 => 'Balance audience appeal and stage changeovers.',
          7 || 8 => 'Advanced: leave breathing room for stage setup.',
          9 || 10 => 'Expert: protect open-air sets when showers hit.',
          <= 16 => 'Master: solve crew, power and crowd at each time block.',
          _ => 'Final: publish a dense festival plan within budget.',
        },
        difficulty: switch (level) {
          <= 3 => 'PROGRAM',
          <= 6 => 'SAHNE',
          7 || 8 => 'İLERİ',
          9 || 10 => 'UZMAN',
          <= 16 => 'USTA',
          _ => 'FİNAL',
        },
        icon: Icons.event_rounded,
      );
    },
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forClass(StudioGameClass.fun);
    return ParkurLevelHub(
      gameId: 'festival_producer',
      progressPrefix: 'festival_producer',
      titleTr: 'Festival Yapımcısı',
      titleEn: 'Festival Producer',
      taglineTr: 'Programla • Sahnele • Akışı dengede tut',
      taglineEn: 'Schedule • Stage • Keep the day in balance',
      accent: skin.accent,
      icon: Icons.event_rounded,
      levels: _levels,
      dailyCourseMode: false,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => FestivalProducerPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class FestivalProducerPlayPage extends StatefulWidget {
  const FestivalProducerPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });
  final ParkurLevelSpec level;
  final int previousBestScore;
  @override
  State<FestivalProducerPlayPage> createState() =>
      _FestivalProducerPlayPageState();
}

class _FestivalProducerPlayPageState extends State<FestivalProducerPlayPage> {
  static const Color _accent = Color(0xFF8E6F91);
  static const Color _ink = Color(0xFF423B4B);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late FestivalScenario _scenario;
  late FestivalEngine _engine;
  late StudioGameSession _session;
  int _selectedIndex = 0;
  bool _ready = false;
  bool _finished = false;
  bool _english = false;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    unawaited(_audioProfile.preload(_audio));
    unawaited(_prepareFestival());
  }

  Future<void> _prepareFestival() async {
    FestivalScenario scenario = FestivalScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String visitKey =
          'festival_producer_level_${widget.level.number}_visits';
      final int visits = await prefs.getInt(visitKey) ?? 0;
      if (visits > 0) {
        final int index =
            await prefs.getInt('festival_producer_practice_index') ?? 0;
        if (index < FestivalScenario.practiceFestivals) {
          final int next = index + 1;
          await prefs.setInt('festival_producer_practice_index', next);
          scenario = FestivalScenario.forPractice(next);
        }
      }
      await prefs.setInt(visitKey, visits + 1);
    } catch (_) {
      // The authored set list stays available if preferences cannot load.
    }
    if (!mounted) return;
    _scenario = scenario;
    _engine = FestivalEngine(scenario: scenario);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: scenario.seed,
    )..start();
    setState(() {
      _english = context.l10n.isEnglish;
      _feedback = _english
          ? 'Choose a set, then tap a stage and time. Stage 1 is covered.'
          : 'Bir set seç, sonra sahne ve saate dokun. 1. sahne kapalıdır.';
      _ready = true;
    });
  }

  void _tapSchedule(Offset position, Size size) {
    if (!_ready || _finished) return;
    const double left = 37;
    const double top = 29;
    final double cellWidth = (size.width - left - 7) / _scenario.timeSlots;
    final double rowHeight = (size.height - top - 8) / 2;
    final int block = ((position.dx - left) / cellWidth).floor();
    final int stage = ((position.dy - top) / rowHeight).floor();
    if (block < 0 || block >= _scenario.timeSlots || stage < 0 || stage > 1) {
      return;
    }
    if (_engine.assignments.any(
      (FestivalAssignment a) => a.stage == stage && a.block == block,
    )) {
      final FestivalActionResult removed = _engine.removeAt(
        stage: stage,
        block: block,
      );
      if (removed.accepted) {
        setState(
          () => _feedback = _english
              ? 'Time cleared · reselect or reschedule a set.'
              : 'Saat boşaltıldı · yeniden seç veya başka yere koy.',
        );
        unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .14));
      }
      return;
    }
    final FestivalPerformance performance =
        _scenario.performances[_selectedIndex];
    final FestivalActionResult result = _engine.place(
      performanceIndex: _selectedIndex,
      stage: stage,
      block: block,
    );
    setState(
      () => _feedback = _actionText(result.reason, performance, stage, block),
    );
    unawaited(
      _audioProfile.play(
        _audio,
        result.accepted ? GameAudioEvent.accepted : GameAudioEvent.rejected,
        gain: .17,
      ),
    );
    if (result.accepted) {
      _session.recordAccepted(points: 9);
      _audio.hapticLight();
    } else {
      _session.recordMistake();
    }
  }

  String _actionText(
    String reason,
    FestivalPerformance performance,
    int stage,
    int block,
  ) => switch (reason) {
    'already_booked' =>
      _english ? 'Set already has a time.' : 'Bu setin zamanı zaten var.',
    'stage_occupied' =>
      _english
          ? 'That stage is booked at this time.'
          : 'Bu sahne bu saatte dolu.',
    'outside_time_window' =>
      _english
          ? 'Outside the artist’s available window.'
          : 'Sanatçının uygun olduğu zaman aralığının dışında.',
    'over_budget' =>
      _english ? 'Festival budget exceeded.' : 'Festival bütçesi aşıldı.',
    'booked' =>
      _english
          ? '${performance.label(true)} booked · Stage ${stage + 1} · block ${block + 1}.'
          : '${performance.label(false)} yerleşti · Sahne ${stage + 1} · saat ${block + 1}.',
    _ => _english ? 'Outside the schedule.' : 'Program alanı dışında.',
  };

  void _select(int index) {
    if (_finished ||
        _engine.assignments.any(
          (FestivalAssignment a) => a.performanceIndex == index,
        )) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      final FestivalPerformance item = _scenario.performances[index];
      _feedback = _english
          ? '${item.label(true)} · ${item.earliestBlock + 1}:00–${item.latestBlock + 1}:00 · crew ${item.crew} · power ${item.power}'
          : '${item.label(false)} · ${item.earliestBlock + 1}:00–${item.latestBlock + 1}:00 · ekip ${item.crew} · enerji ${item.power}';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.menu, gain: .12));
  }

  void _history(bool undo) {
    final bool changed = undo ? _engine.undo() : _engine.redo();
    if (!changed) return;
    setState(
      () => _feedback = undo
          ? (_english
                ? 'Last schedule change undone.'
                : 'Son program değişikliği geri alındı.')
          : (_english
                ? 'Schedule change restored.'
                : 'Program değişikliği yeniden yapıldı.'),
    );
    unawaited(_audio.play(GameSound.uiClick, gain: .18));
  }

  Future<void> _publish() async {
    if (_finished) return;
    final FestivalEvaluation result = _engine.evaluate();
    if (!result.canPublish) {
      final List<String> missing = <String>[];
      if (result.scheduled < result.requiredShows) {
        missing.add(_english ? 'show slots' : 'programdaki setler');
      }
      if (result.stageZeroShows == 0 || result.stageOneShows == 0) {
        missing.add(_english ? 'both stages' : 'iki sahne');
      }
      if (result.genreCount < result.minimumGenres) {
        missing.add(_english ? 'genre variety' : 'tür çeşitliliği');
      }
      if (result.audience < result.audienceTarget) {
        missing.add(_english ? 'audience draw' : 'seyirci ilgisi');
      }
      if (!result.resourceReady) {
        missing.add(
          _english ? 'crowd / crew / power' : 'kalabalık / ekip / enerji',
        );
      }
      if (!result.turnaroundReady) {
        missing.add(_english ? 'stage changeover' : 'sahne değişim süresi');
      }
      if (!result.weatherReady) {
        missing.add(_english ? 'rain cover' : 'yağmur koruması');
      }
      if (result.budgetUsed > result.budget) {
        missing.add(_english ? 'budget' : 'bütçe');
      }
      setState(
        () => _feedback = _english
            ? 'Run-of-show check: ${missing.join(' · ')}'
            : 'Akış kontrolü: ${missing.join(' · ')}',
      );
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .18));
      return;
    }
    _finished = true;
    final int stars = result.score >= 94 ? 3 : (result.score >= 82 ? 2 : 1);
    _session.complete(
      stars: stars,
      action: widget.level.number < FestivalProducerGamePage.totalFestivals
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
      titleTr: 'FESTİVAL PROGRAMI YAYINDA!',
      titleEn: 'FESTIVAL PROGRAM PUBLISHED!',
      detailTr:
          '${result.scheduled} set · ilgi ${result.audience} · bütçe ${result.budgetUsed} · puan ${result.score}',
      detailEn:
          '${result.scheduled} sets · appeal ${result.audience} · budget ${result.budgetUsed} · score ${result.score}',
      stars: stars,
      score: result.score * 100,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < FestivalProducerGamePage.totalFestivals,
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
          title: Text(_english ? 'FESTIVAL PRODUCER' : 'FESTİVAL YAPIMCISI'),
        ),
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    final FestivalEvaluation evaluation = _engine.evaluate();
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          '${_english ? 'RUN OF SHOW' : 'GÜN AKIŞI'} · ${widget.level.number.toString().padLeft(2, '0')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('festival_producer_undo'),
            tooltip: _english ? 'Undo' : 'Geri al',
            onPressed: _engine.canUndo ? () => _history(true) : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('festival_producer_redo'),
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
                    aspectRatio: 1.56,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints bounds) =>
                          GestureDetector(
                            key: const ValueKey<String>(
                              'festival_producer_timeline',
                            ),
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (TapUpDetails details) => _tapSchedule(
                              details.localPosition,
                              Size(bounds.maxWidth, bounds.maxHeight),
                            ),
                            child: CustomPaint(
                              painter: _FestivalPainter(
                                scenario: _scenario,
                                assignments: _engine.assignments,
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
                    key: const ValueKey<String>('festival_producer_feedback'),
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
              _setPicker(),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  key: const ValueKey<String>('festival_producer_publish'),
                  onPressed: _finished ? null : _publish,
                  style: FilledButton.styleFrom(
                    backgroundColor: evaluation.canPublish ? _accent : _ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.campaign_rounded),
                  label: Text(
                    _english ? 'PUBLISH PROGRAM' : 'PROGRAMI YAYINLA',
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

  Widget _hud(FestivalEvaluation evaluation) => Container(
    key: const ValueKey<String>('festival_producer_hud'),
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFE6E1E9)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.payments_rounded, size: 15, color: _accent),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            '${evaluation.budgetUsed}/${evaluation.budget}',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
          ),
        ),
        const Icon(Icons.groups_rounded, size: 15, color: _accent),
        const SizedBox(width: 3),
        Text(
          '${evaluation.audience}/${evaluation.audienceTarget}',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 7),
        Text(
          '${evaluation.scheduled}/${evaluation.requiredShows} ${_english ? 'sets' : 'set'}',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );

  Widget _brief() {
    final String weather = switch (_scenario.weather) {
      FestivalWeather.clear => _english ? 'CLEAR' : 'AÇIK HAVA',
      FestivalWeather.drizzle => _english ? 'SHOWERS' : 'SAĞANAK',
      FestivalWeather.wind => _english ? 'WINDY' : 'RÜZGÂRLI',
    };
    return Container(
      key: const ValueKey<String>('festival_producer_brief'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDF3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.description_outlined, size: 16, color: _accent),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '$weather · ${_english ? 'covered stage 1' : 'kapalı sahne 1'} · ${_scenario.turnaroundGap} ${_english ? 'setup gap' : 'kurulum arası'}\n${_english ? 'Per-time cap' : 'Zaman başına sınır'} · ${_scenario.audienceCapacity} ${_english ? 'crowd' : 'kitle'} · ${_scenario.powerCapacity} kW · ${_scenario.crewCapacity} ${_english ? 'crew' : 'ekip'}',
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
  }

  Widget _setPicker() => SizedBox(
    key: const ValueKey<String>('festival_producer_setlist'),
    height: 148,
    child: GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _scenario.performances.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 34,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemBuilder: (BuildContext context, int index) {
        final FestivalPerformance item = _scenario.performances[index];
        final bool selected = index == _selectedIndex;
        final bool booked = _engine.assignments.any(
          (FestivalAssignment a) => a.performanceIndex == index,
        );
        return OutlinedButton(
          key: ValueKey<String>('festival_set_${item.id}'),
          onPressed: booked || _finished ? null : () => _select(index),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            backgroundColor: booked
                ? const Color(0xFFE8EEE9)
                : (selected ? const Color(0xFFEFE2F1) : Colors.white),
            foregroundColor: _ink,
            side: BorderSide(
              color: selected ? _accent : const Color(0xFFE3DEE7),
              width: selected ? 1.3 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '${item.label(_english)} · ${item.genre.label(_english)}${booked ? ' ✓' : ''}',
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

class _FestivalPainter extends CustomPainter {
  const _FestivalPainter({
    required this.scenario,
    required this.assignments,
    required this.english,
  });
  final FestivalScenario scenario;
  final List<FestivalAssignment> assignments;
  final bool english;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect area = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(area, const Radius.circular(15)),
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF42394E), Color(0xFF68566B)],
        ).createShader(area),
    );
    const double left = 37;
    const double top = 29;
    final double cellWidth = (size.width - left - 7) / scenario.timeSlots;
    final double rowHeight = (size.height - top - 8) / 2;
    _label(
      canvas,
      Rect.fromLTWH(5, 4, left - 8, 17),
      english ? 'STAGE' : 'SAHNE',
      const Color(0xFFF1E9F3),
      6,
    );
    for (int block = 0; block < scenario.timeSlots; block++) {
      final Rect timeLabel = Rect.fromLTWH(
        left + block * cellWidth,
        4,
        cellWidth,
        18,
      );
      _label(
        canvas,
        timeLabel,
        '${12 + block}:00',
        const Color(0xFFE7DCEB),
        5.3,
      );
    }
    for (int stage = 0; stage < 2; stage++) {
      final double y = top + stage * rowHeight;
      _label(
        canvas,
        Rect.fromLTWH(3, y + rowHeight * .35, left - 5, 18),
        stage == 0 ? (english ? 'TENT' : 'ÇADIR') : (english ? 'OPEN' : 'AÇIK'),
        const Color(0xFFF6EFD7),
        6,
      );
      for (int block = 0; block < scenario.timeSlots; block++) {
        final Rect cell = Rect.fromLTWH(
          left + block * cellWidth + 1,
          y + 2,
          cellWidth - 3,
          rowHeight - 5,
        );
        final bool rain =
            scenario.weather == FestivalWeather.drizzle &&
            block == scenario.rainSlot;
        final RRect box = RRect.fromRectAndRadius(
          cell,
          const Radius.circular(5),
        );
        canvas.drawRRect(
          box,
          Paint()
            ..color = rain && stage == 1
                ? const Color(0xFF70869A)
                : const Color(0x334D4057),
        );
        canvas.drawRRect(
          box,
          Paint()
            ..color = const Color(0x33F4E7F1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8,
        );
        if (rain) {
          canvas.drawCircle(
            Offset(cell.right - 4, cell.top + 4),
            1.4,
            Paint()..color = const Color(0xFFB5D2DF),
          );
        }
        final FestivalAssignment? assignment = assignments
            .cast<FestivalAssignment?>()
            .firstWhere(
              (FestivalAssignment? a) =>
                  a != null && a.stage == stage && a.block == block,
              orElse: () => null,
            );
        if (assignment != null) {
          final FestivalPerformance performance =
              scenario.performances[assignment.performanceIndex];
          final Color swatch = _genreColor(performance.genre);
          canvas.drawRRect(
            RRect.fromRectAndRadius(cell.deflate(2), const Radius.circular(4)),
            Paint()..color = swatch,
          );
          _label(
            canvas,
            cell.deflate(2),
            _short(performance.label(english)),
            Colors.white,
            5.5,
          );
          canvas.drawCircle(
            Offset(cell.right - 3.5, cell.bottom - 3.5),
            1.2,
            Paint()..color = const Color(0xFFFFEAB5),
          );
        }
      }
    }
  }

  Color _genreColor(FestivalGenre genre) {
    const List<Color> colors = <Color>[
      Color(0xFFD47779),
      Color(0xFF8274BA),
      Color(0xFF8A9D68),
      Color(0xFFC38354),
      Color(0xFF5E9C98),
      Color(0xFFBE7CA1),
      Color(0xFF7093B6),
      Color(0xFFAA9360),
      Color(0xFF668AAB),
      Color(0xFFB17B67),
      Color(0xFF7A9A81),
      Color(0xFF8A7CA8),
      Color(0xFFB07A5E),
      Color(0xFF6D9C8C),
    ];
    return colors[genre.index];
  }

  String _short(String label) {
    final String cleaned = label
        .replaceAll(RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü ]'), '')
        .trim();
    return cleaned
        .split(RegExp(r'\s+'))
        .take(2)
        .map((String part) => part.substring(0, math.min(3, part.length)))
        .join(' ');
  }

  void _label(
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
          fontSize: fontSize.clamp(5, 8).toDouble(),
          fontWeight: FontWeight.w900,
          letterSpacing: .1,
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
  bool shouldRepaint(covariant _FestivalPainter oldDelegate) =>
      oldDelegate.scenario != scenario ||
      oldDelegate.assignments != assignments ||
      oldDelegate.english != english;
}
