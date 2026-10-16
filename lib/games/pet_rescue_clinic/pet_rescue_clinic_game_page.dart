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
import 'pet_care_engine.dart';
import 'pet_case_scenario.dart';

class PetRescueClinicGamePage extends StatelessWidget {
  const PetRescueClinicGamePage({super.key});
  static const int totalCases = PetCaseScenario.campaignLevels;
  static const int totalStars = totalCases * 3;
  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    totalCases,
    (int i) => ParkurLevelSpec(
      number: i + 1,
      titleTr: 'Ziyaret ${(i + 1).toString().padLeft(2, '0')}',
      titleEn: 'Visit ${(i + 1).toString().padLeft(2, '0')}',
      subtitleTr: i < 6
          ? 'Bakım ipuçlarını sırala; hatalar telafi edilebilir.'
          : 'Sakin ve güvenli ziyaret akışını koordine et.',
      subtitleEn: i < 6
          ? 'Sequence care clues; mistakes are recoverable.'
          : 'Coordinate a calm, safe visit one step at a time.',
      difficulty: i < 3 ? 'KARŞILAMA' : (i < 10 ? 'UZMAN' : 'USTA'),
      icon: Icons.pets_rounded,
    ),
    growable: false,
  );
  @override
  Widget build(BuildContext context) => ParkurLevelHub(
    gameId: 'pet_rescue_clinic',
    progressPrefix: 'pet_rescue_clinic',
    titleTr: 'Dostlar Kurtarma Kliniği',
    titleEn: 'Pet Rescue Clinic',
    taglineTr: 'Gözlemle • Sırala • Güvenli ziyaret düzenle',
    taglineEn: 'Observe • Sequence • Run a gentle visit',
    accent: StudioGameSkin.forClass(StudioGameClass.fun).accent,
    icon: Icons.pets_rounded,
    levels: _levels,
    dailyCourseMode: false,
    playBuilder: (
      BuildContext context,
      ParkurLevelSpec level,
      int score,
      int? layout,
      bool competition,
    ) => PetRescueClinicPlayPage(level: level, previousBestScore: score),
  );
}

class PetRescueClinicPlayPage extends StatefulWidget {
  const PetRescueClinicPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });
  final ParkurLevelSpec level;
  final int previousBestScore;
  @override
  State<PetRescueClinicPlayPage> createState() =>
      _PetRescueClinicPlayPageState();
}

class _PetRescueClinicPlayPageState extends State<PetRescueClinicPlayPage> {
  static const Color accent = Color(0xFF6B998A);
  static const Color ink = Color(0xFF3D4E49);
  final GameAudioService audio = GameAudioService.instance;
  final GameAudioProfile profile = GameAudioProfile.forClass(
    StudioGameClass.fun,
  );
  late PetCaseScenario scenario;
  late PetCareEngine engine;
  late StudioGameSession session;
  bool ready = false, finished = false, english = false;
  String feedback = '';
  @override
  void initState() {
    super.initState();
    unawaited(profile.preload(audio));
    unawaited(prepare());
  }

  Future<void> prepare() async {
    PetCaseScenario selected = PetCaseScenario.forLevel(widget.level.number);
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String key =
          'pet_rescue_clinic_level_${widget.level.number}_visits';
      final int visits = await prefs.getInt(key) ?? 0;
      if (visits > 0) {
        final int index =
            await prefs.getInt('pet_rescue_clinic_practice_index') ?? 0;
        if (index < PetCaseScenario.practiceCases) {
          await prefs.setInt('pet_rescue_clinic_practice_index', index + 1);
          selected = PetCaseScenario.forPractice(index + 1);
        }
      }
      await prefs.setInt(key, visits + 1);
    } catch (_) {
      /* The authored case remains playable without preferences. */
    }
    if (!mounted) return;
    scenario = selected;
    engine = PetCareEngine(scenario: scenario);
    session = StudioGameSession(level: widget.level.number, seed: scenario.seed)
      ..start();
    setState(() {
      english = context.l10n.isEnglish;
      feedback = english
          ? 'Fictional care game, not veterinary advice.'
          : 'Kurmaca bakım sıralama oyunu; veteriner önerisi değildir.';
      ready = true;
    });
  }

  void choose(CareStep step) {
    if (finished) return;
    final PetCareStepResult result = engine.choose(step);
    if (result.accepted) {
      session.recordAccepted(points: 12);
      unawaited(profile.play(audio, GameAudioEvent.accepted, gain: .19));
      audio.hapticLight();
      if (result.completed) {
        unawaited(finishCase());
      } else {
        setState(
          () => feedback = english
              ? 'Good sequence · read the next visit clue.'
              : 'Sıra doğru · sıradaki ziyaret ipucunu oku.',
        );
      }
    } else {
      session.recordMistake();
      unawaited(profile.play(audio, GameAudioEvent.rejected, gain: .17));
      setState(
        () => feedback = english
            ? 'Not this step yet · no progress lost. Read the clue and retry.'
            : 'Henüz bu adım değil · ilerleme kaybolmadı. İpucunu oku ve dene.',
      );
    }
  }

  Future<void> finishCase() async {
    if (finished || !mounted) return;
    setState(() => finished = true);
    final int stars = engine.stars;
    session.complete(
      stars: stars,
      action: widget.level.number < PetRescueClinicGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(profile.play(
      audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    final ParkurResultAction? choice = await showParkurResultDialog(
      context: context,
      accent: accent,
      titleTr: 'ZİYARET GÜZELCE TAMAMLANDI',
      titleEn: 'A GENTLE VISIT COMPLETE',
      detailTr:
          '${scenario.animal.label(false)} · ${engine.completedSteps.length} bakım adımı · ${engine.mistakes} sıra hatası',
      detailEn:
          '${scenario.animal.label(true)} · ${engine.completedSteps.length} care steps · ${engine.mistakes} sequence slips',
      stars: stars,
      score: engine.score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < PetRescueClinicGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (choice) {
      ParkurResultAction.replay => StudioResultAction.replay,
      ParkurResultAction.next => StudioResultAction.next,
      _ => StudioResultAction.map,
    };
    Navigator.of(context).pop(
      StudioGameResult.completed(
        score: engine.score,
        stars: stars,
        action: action,
      ).toParkurResult(),
    );
  }

  @override
  Widget build(BuildContext context) {
    english = context.l10n.isEnglish;
    if (!ready) {
      return Scaffold(
        backgroundColor: StudioVisuals.canvas,
        appBar: AppBar(
          title: Text(english ? 'PET RESCUE CLINIC' : 'DOSTLAR KLİNİĞİ'),
        ),
        body: const Center(child: CircularProgressIndicator(color: accent)),
      );
    }
    final CareStep current = engine.currentStep ?? scenario.steps.last;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        title: Text(
          (english ? 'VISIT · ' : 'ZİYARET · ') +
              widget.level.number.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Column(
            children: <Widget>[
              hud(),
              const SizedBox(height: 4),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.56,
                    child: CustomPaint(
                      key: const ValueKey<String>('pet_rescue_scene'),
                      painter: _PetVisitPainter(
                        animal: scenario.animal,
                        stepIndex: engine.nextStep,
                        totalSteps: scenario.steps.length,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              note(),
              const SizedBox(height: 4),
              prompt(current),
              rail(),
              SizedBox(height: 98, child: toolsGrid()),
              SizedBox(
                height: 25,
                child: Center(
                  child: Text(
                    feedback,
                    key: const ValueKey<String>('pet_rescue_feedback'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  english
                      ? 'FICTIONAL CARE GAME · NOT VETERINARY ADVICE'
                      : 'KURMACA BAKIM OYUNU · VETERİNER ÖNERİSİ DEĞİLDİR',
                  style: const TextStyle(
                    color: ink,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget hud() => Container(
    height: 36,
    key: const ValueKey<String>('pet_rescue_hud'),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFE4E8E3)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.favorite_rounded, color: accent, size: 16),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            scenario.animal.label(english),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          '${engine.nextStep}/${scenario.steps.length}',
          key: const ValueKey<String>('pet_rescue_progress'),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 9),
        const Icon(Icons.replay_rounded, color: Color(0xFF9D7856), size: 15),
        const SizedBox(width: 3),
        Text(
          engine.mistakes.toString(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
  Widget note() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F2EB),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      english ? scenario.caseNote : scenario.caseNoteTr,
      key: const ValueKey<String>('pet_rescue_case_note'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: ink,
        fontSize: 9,
        height: 1.15,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget prompt(CareStep step) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE5E8E1)),
    ),
    child: Text(
      step.prompt(english, engine.nextStep + 1),
      key: const ValueKey<String>('pet_rescue_prompt'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: ink,
        fontSize: 9,
        height: 1.16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  Widget rail() => SizedBox(
    height: 25,
    child: Row(
      children: List<Widget>.generate(
        scenario.steps.length,
        (int i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i < engine.nextStep
                    ? accent
                    : (i == engine.nextStep
                          ? const Color(0xFFC4A67C)
                          : const Color(0xFFE1E2DC)),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget toolsGrid() {
    final double width = MediaQuery.sizeOf(context).width - 20;
    final double itemWidth = (width - 18) / 4;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 3,
      children: CareStep.values
          .map((CareStep step) {
            final bool done = engine.completedSteps.contains(step);
            return SizedBox(
              width: itemWidth,
              height: 46,
              child: OutlinedButton(
                key: ValueKey<String>('pet_tool_${step.name}'),
                onPressed: done || finished ? null : () => choose(step),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  backgroundColor: done
                      ? const Color(0xFFE5F0E9)
                      : Colors.white,
                  foregroundColor: ink,
                  side: BorderSide(
                    color: done ? accent : const Color(0xFFE1E4DD),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  step.label(english),
                  maxLines: 2,
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
  }
}

class _PetVisitPainter extends CustomPainter {
  const _PetVisitPainter({
    required this.animal,
    required this.stepIndex,
    required this.totalSteps,
  });
  final RescueAnimal animal;
  final int stepIndex;
  final int totalSteps;
  @override
  void paint(Canvas canvas, Size size) {
    final Rect area = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(area, const Radius.circular(17)),
      Paint()..color = const Color(0xFFE8F0E9),
    );
    final Rect floor = Rect.fromLTWH(
      0,
      size.height * .7,
      size.width,
      size.height * .3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(floor, const Radius.circular(14)),
      Paint()..color = const Color(0xFFF4EFE5),
    );
    final Offset c = Offset(size.width * .5, size.height * .53);
    final double scale = math.min(size.width * .23, size.height * .29);
    final Color fur = switch (animal) {
      RescueAnimal.cat => const Color(0xFFC69C74),
      RescueAnimal.dog => const Color(0xFFD2B17E),
      RescueAnimal.rabbit => const Color(0xFFF3F0E9),
      RescueAnimal.parrot => const Color(0xFF88B79B),
    };
    final Paint body = Paint()..color = fur;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + scale * .2),
        width: scale * 1.5,
        height: scale * 1.2,
      ),
      body,
    );
    canvas.drawCircle(Offset(c.dx, c.dy - scale * .45), scale * .59, body);
    if (animal == RescueAnimal.rabbit) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx - scale * .27, c.dy - scale),
          width: scale * .2,
          height: scale * .8,
        ),
        body,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx + scale * .27, c.dy - scale),
          width: scale * .2,
          height: scale * .8,
        ),
        body,
      );
    } else {
      final Path ears = Path()
        ..moveTo(c.dx - scale * .53, c.dy - scale * .64)
        ..lineTo(c.dx - scale * .45, c.dy - scale * 1.08)
        ..lineTo(c.dx - scale * .11, c.dy - scale * .79)
        ..moveTo(c.dx + scale * .53, c.dy - scale * .64)
        ..lineTo(c.dx + scale * .45, c.dy - scale * 1.08)
        ..lineTo(c.dx + scale * .11, c.dy - scale * .79);
      canvas.drawPath(
        ears,
        Paint()
          ..color = fur
          ..style = PaintingStyle.stroke
          ..strokeWidth = scale * .16
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final Paint eye = Paint()..color = const Color(0xFF40534B);
    canvas.drawCircle(
      Offset(c.dx - scale * .19, c.dy - scale * .48),
      scale * .045,
      eye,
    );
    canvas.drawCircle(
      Offset(c.dx + scale * .19, c.dy - scale * .48),
      scale * .045,
      eye,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .12,
          size.height * .75,
          size.width * .76,
          size.height * .17,
        ),
        const Radius.circular(11),
      ),
      Paint()..color = const Color(0xFFDCE9E0),
    );
    final TextPainter label = TextPainter(
      text: const TextSpan(
        text: 'CALM VISIT',
        style: TextStyle(
          color: Color(0xFF6B8574),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, const Offset(9, 7));
    final TextPainter stage = TextPainter(
      text: TextSpan(
        text: '$stepIndex / $totalSteps',
        style: const TextStyle(
          color: Color(0xFF506259),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    stage.paint(canvas, Offset(size.width - stage.width - 9, 7));
  }

  @override
  bool shouldRepaint(covariant _PetVisitPainter oldDelegate) =>
      oldDelegate.animal != animal ||
      oldDelegate.stepIndex != stepIndex ||
      oldDelegate.totalSteps != totalSteps;
}
