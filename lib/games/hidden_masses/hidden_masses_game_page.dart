import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../../widgets/realistic_game_object.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'hidden_masses_puzzle.dart';

class HiddenMassesGamePage extends StatelessWidget {
  const HiddenMassesGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  static const int totalCases = GameContentPolicy.campaignLevels;
  static const int totalStars = totalCases * 3;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    GameContentPolicy.nativeStages('hidden_masses'),
    (int index) {
      final int number = index + 1;
      final int stage = (index % 10) + 1;
      final int chapter = index ~/ 10 + 1;
      final String difficulty = switch (stage) {
        <= 6 => chapter == 1 ? 'USTALAŞMA' : 'İLERİ',
        <= 8 => 'UZMAN',
        _ => 'UZMAN+',
      };
      return ParkurLevelSpec(
        number: number,
        titleTr: 'Gizli Kütle ${number.toString().padLeft(2, '0')}',
        titleEn: 'Hidden Mass ${number.toString().padLeft(2, '0')}',
        subtitleTr: _subtitle(stage, chapter, english: false),
        subtitleEn: _subtitle(stage, chapter, english: true),
        difficulty: difficulty,
        icon: Icons.scale_outlined,
      );
    },
    growable: false,
  );

  static String _subtitle(int stage, int chapter, {required bool english}) {
    if (chapter == 2 && stage <= 6) {
      return english
          ? 'Ignore the decoy; solve each hidden mass.'
          : 'Çeldiriciyi ayıkla, gizli kütleleri çöz.';
    }
    return switch (stage) {
      <= 3 =>
        english
            ? 'Read three balanced measurements.'
            : 'Üç dengeli ölçümü birlikte oku.',
      <= 6 =>
        english
            ? 'Track the shared object across scales.'
            : 'Terazilerdeki ortak nesneyi izle.',
      <= 8 =>
        english
            ? 'Extend the deduction chain to four objects.'
            : 'Çıkarım zincirini dört nesneye taşı.',
      9 =>
        english
            ? 'Resolve a five-object chain under pressure.'
            : 'Beş nesneli zinciri dikkatle çöz.',
      _ =>
        english
            ? 'Expert calibration: use every clue.'
            : 'Uzman kalibrasyonu: tüm ipuçlarını kullan.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('hidden_masses');
    return ParkurLevelHub(
      gameId: 'hidden_masses',
      progressPrefix: 'hidden_masses',
      titleTr: 'Gizli Kütleler',
      titleEn: 'Hidden Masses',
      taglineTr: 'Dengeli ölçümleri çöz • Bilinmeyen kütleyi bul',
      taglineEn: 'Read balanced measurements • Deduce the unknown mass',
      accent: skin.accent,
      icon: Icons.scale_outlined,
      levels: _levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => HiddenMassesPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class HiddenMassesPlayPage extends StatefulWidget {
  const HiddenMassesPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<HiddenMassesPlayPage> createState() => _HiddenMassesPlayPageState();
}

class _HiddenMassesPlayPageState extends State<HiddenMassesPlayPage> {
  static const Color _accent = Color(0xFF866139);
  static const Color _accentDark = Color(0xFF554AA9);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  late final HiddenMassPuzzle _puzzle;
  late final StudioGameSession _session;
  int? _selectedAnswer;
  String? _notice;
  bool _showingHint = false;
  bool _english = false;
  bool _finished = false;
  int _hints = 0;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = widget.level.poolIndex == null
        ? HiddenMassPuzzle.forLevel(widget.level.contentLevel)
        : HiddenMassPuzzle.forPool(widget.level.contentIndex);
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  void _showHint() {
    if (_finished || !_session.canUseHint || _showingHint) return;
    setState(() {
      _hints++;
      _showingHint = true;
      _notice = _english
          ? 'Find the three-object triangle first. When two measurements share an object, compare them to isolate the next mass.'
          : 'Önce üç nesneli üçgeni çöz. İki ölçümde ortak nesne varsa, diğer kütleyi bulmak için ölçümleri karşılaştır.';
    });
    _session.useHint(pointCost: 180);
    _audio.hapticSelection();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .32));
  }

  void _selectAnswer(int grams) {
    if (_finished || !_session.acceptsInput) return;
    setState(() {
      _selectedAnswer = grams;
      if (!_showingHint) _notice = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .2),
    );
  }

  void _checkAnswer() {
    if (_finished || !_session.acceptsInput) return;
    final int? selected = _selectedAnswer;
    if (selected == null) {
      _setNotice(
        _english
            ? 'Choose a mass before checking.'
            : 'Kontrol etmeden önce bir kütle seç.',
      );
      return;
    }
    _attempts++;
    if (selected == _puzzle.answerGrams) {
      unawaited(_complete());
      return;
    }
    _session.recordMistake();
    setState(() {
      _notice = _english
          ? 'That value does not balance every measurement. Compare the shared objects again.'
          : 'Bu değer tüm ölçümleri dengelemiyor. Ortak nesneleri yeniden karşılaştır.';
      _showingHint = false;
    });
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .28));
  }

  void _setNotice(String message) {
    if (!mounted) return;
    setState(() => _notice = message);
  }

  Future<void> _complete() async {
    if (_finished || !_session.acceptsInput) return;
    _finished = true;
    final int stars = _hints == 0 && _session.mistakes == 0
        ? 3
        : _hints <= 1 && _session.mistakes <= 1
        ? 2
        : 1;
    final int score = math.max(
      160,
      1750 - _hints * 190 - _session.mistakes * 120,
    );
    _session.recordAccepted(points: score);
    _session.complete(
      stars: stars,
      action: widget.level.number < HiddenMassesGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    _audio.hapticMedium();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.accepted, gain: .38),
    );
    unawaited(_audioProfile.play(
      _audio,
      GameAudioEvent.levelComplete,
      levelNumber: widget.level.number,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final ParkurResultAction? result = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'DENGE ÇÖZÜLDÜ',
      titleEn: 'MASSES DECODED',
      detailTr:
          '${_puzzle.activeObjectCount} nesne çözüldü · $_attempts deneme · $_hints ipucu.',
      detailEn:
          '${_puzzle.activeObjectCount} objects solved · $_attempts attempts · $_hints hints.',
      stars: stars,
      score: score,
      previousBestScore: widget.previousBestScore,
      canGoNext: widget.level.number < HiddenMassesGamePage.totalCases,
    );
    if (!mounted) return;
    final StudioResultAction action = switch (result) {
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

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: StudioVisuals.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.scale_rounded, color: _accent, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _english ? 'How to Play: Hidden Masses' : 'Nasıl Oynanır: Gizli Kütleler',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: StudioVisuals.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildRuleItem(
                  Icons.balance_rounded,
                  _english ? 'Balanced Trays' : 'Dengeli Teraziler',
                  _english
                      ? 'Every tray is balanced. The number beside it represents the combined mass in grams.'
                      : 'Her terazi dengededir. Yanındaki sayı, üzerindeki nesnelerin toplam gramıdır.',
                ),
                const SizedBox(height: 10),
                _buildRuleItem(
                  Icons.psychology_rounded,
                  _english ? 'Deduce Shared Values' : 'Ortak Değerleri Bul',
                  _english
                      ? 'Compare scales with shared objects to deduce the weight of each individual object.'
                      : 'Ortak nesnelere sahip terazileri karşılaştırarak nesnelerin tekil ağırlıklarını çıkar.',
                ),
                const SizedBox(height: 10),
                _buildRuleItem(
                  Icons.check_circle_outline_rounded,
                  _english ? 'Select Target Mass' : 'Hedef Kütleyi Seç',
                  _english
                      ? 'Find the unknown mass of the target object and choose from the options below.'
                      : 'Hedef nesnenin bilinmeyen ağırlığını seçeneklerden seçip doğrula.',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_english ? 'Got it!' : 'Anladım, Başla'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuleItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: StudioVisuals.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: StudioVisuals.muted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 12,
        title: Text(
          _english ? 'HIDDEN MASSES' : 'GİZLİ KÜTLELER',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: _english ? 'How to play' : 'Nasıl Oynanır',
            onPressed: () => _showHowToPlay(context),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            tooltip: _english ? 'Deduction hint' : 'Çıkarım ipucu',
            onPressed: _showHint,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 640,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudioVisuals.line),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_english ? 'LVL' : 'BÖLÜM'} ${widget.level.number}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: _accentDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_puzzle.equations.length} ${_english ? 'CLUES' : 'İPUCU'}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${_session.score}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: _accentDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (widget.previousBestScore > 0) ...<Widget>[
                        const SizedBox(width: 4),
                        Text(
                          '(${widget.previousBestScore})',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF1F0FB)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E1F5)),
                  ),
                  child: Row(
                    children: <Widget>[
                      _MassObjectBadge(
                        object: _puzzle.objects[_puzzle.targetObjectIndex],
                        size: 44,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _english
                              ? 'How much does object ${_puzzle.objects[_puzzle.targetObjectIndex].label} weigh?'
                              : '${_puzzle.objects[_puzzle.targetObjectIndex].label} nesnesi kaç gram?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _puzzle.equations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (BuildContext context, int index) {
                      return _MassEquationCard(
                        key: ValueKey<String>('hidden_mass_equation_$index'),
                        equation: _puzzle.equations[index],
                        objects: _puzzle.objects,
                        english: _english,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final int grams in _puzzle.answerChoices)
                      _MassAnswerChip(
                        key: ValueKey<String>('hidden_mass_choice_$grams'),
                        grams: grams,
                        selected: _selectedAnswer == grams,
                        onTap: () => _selectAnswer(grams),
                      ),
                  ],
                ),
                if (_notice != null) ...<Widget>[
                  const SizedBox(height: 5),
                  _MassNotice(
                    message: _notice!,
                    isHint: _showingHint,
                    english: _english,
                  ),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  height: 42,
                  child: FilledButton.icon(
                    key: const ValueKey<String>('hidden_mass_submit'),
                    onPressed: _checkAnswer,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(
                      _english ? 'CHECK DEDUCTION' : 'ÇIKARIMI KONTROL ET',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .35,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _MassEquationCard extends StatelessWidget {
  const _MassEquationCard({
    super.key,
    required this.equation,
    required this.objects,
    required this.english,
  });

  final MassEquation equation;
  final List<MassObjectToken> objects;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x0C102238),
          blurRadius: 11,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // 68 is twice the old 34px thumbnail. On very narrow phones, step
        // down only as much as necessary so a three-object clue still fits.
        final double fullObjectSize = 68;
        const double controlsWidth = 106;
        final double fullRowWidth =
            equation.objectIndices.length * fullObjectSize +
            math.max(0, equation.objectIndices.length - 1) * 3 +
            controlsWidth;
        final double objectSize = constraints.maxWidth >= fullRowWidth
            ? fullObjectSize
            : math.max(
                44.0,
                (constraints.maxWidth -
                        controlsWidth -
                        math.max(0, equation.objectIndices.length - 1) * 3) /
                    equation.objectIndices.length,
              ).toDouble();
        return Row(
          children: <Widget>[
            Expanded(
              child: Wrap(
                spacing: 3,
                runSpacing: 3,
                children: <Widget>[
                  for (final int index in equation.objectIndices)
                    _MassObjectBadge(
                      object: objects[index],
                      size: objectSize,
                    ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F1FA),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.balance_rounded,
                color: _HiddenMassesPlayPageState._accent,
                size: 16,
              ),
            ),
            Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F8),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFE5EAED)),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    '${equation.grams}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.ink,
                      fontSize: 15,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    english ? 'GRAMS' : 'GRAM',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _MassObjectBadge extends StatelessWidget {
  const _MassObjectBadge({required this.object, required this.size});

  final MassObjectToken object;
  final double size;

  @override
  Widget build(BuildContext context) {
    const List<Color> tints = <Color>[
      Color(0xFFB58A58),
      Color(0xFF3D7183),
      Color(0xFF668477),
      Color(0xFF80658E),
      Color(0xFF7A6A58),
    ];
    final Color tint = tints[object.glyphIndex % tints.length];
    return Semantics(
      label: 'Object ${object.label}',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    tint.withValues(alpha: .13),
                    tint.withValues(alpha: .07),
                  ],
                ),
                borderRadius: BorderRadius.circular(size * .29),
                border: Border.all(color: tint.withValues(alpha: .24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    1.05, 0, 0, 0, 12,
                    0, 1.05, 0, 0, 12,
                    0, 0, 1.05, 0, 12,
                    0, 0, 0, 1, 0,
                  ]),
                  child: RealisticGameObject(
                    sheet: RealisticObjectSheet.weights,
                    index: object.glyphIndex,
                    borderRadius: size * .24,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: math.max(15, size * .40),
                height: math.max(15, size * .40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: StudioVisuals.line),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0x17102030), blurRadius: 3),
                  ],
                ),
                child: Text(
                  object.label,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: math.max(8, size * .23),
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MassAnswerChip extends StatelessWidget {
  const _MassAnswerChip({
    super.key,
    required this.grams,
    required this.selected,
    required this.onTap,
  });

  final int grams;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$grams grams',
    child: Material(
      color: selected ? const Color(0xFFEDEBFA) : StudioVisuals.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(minWidth: 54, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? _HiddenMassesPlayPageState._accent
                  : StudioVisuals.line,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected ? StudioVisuals.softShadow : null,
          ),
          child: Text(
            '$grams g',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: selected
                  ? _HiddenMassesPlayPageState._accentDark
                  : StudioVisuals.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}

class _MassNotice extends StatelessWidget {
  const _MassNotice({
    required this.message,
    required this.isHint,
    required this.english,
  });

  final String message;
  final bool isHint;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: isHint ? const Color(0xFFF1F0FB) : StudioVisuals.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isHint ? const Color(0xFFDCD8F2) : StudioVisuals.line,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          isHint ? Icons.lightbulb_outline_rounded : Icons.info_outline_rounded,
          color: isHint
              ? _HiddenMassesPlayPageState._accent
              : StudioVisuals.muted,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

