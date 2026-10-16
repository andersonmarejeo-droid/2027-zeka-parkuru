import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/studio_visuals.dart';

import 'package:flutter/services.dart';

import '../../services/game_audio_service.dart';
import '../../services/replayability_service.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import 'professional_iq_art.dart';
import 'professional_iq_engine.dart';
import 'professional_iq_localizations.dart';
import 'professional_iq_models.dart';

class PictureIqGamePage extends StatelessWidget {
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;

  const PictureIqGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  static const List<PictureIqLevel> levels = <PictureIqLevel>[
    PictureIqLevel(
      number: 1,
      titleTr: 'Görsel Başlangıç',
      titleEn: 'Visual Foundations',
      subtitleTr: 'Aykırı, döndürme, ayna ve temel analoji',
      subtitleEn: 'Odd-one-out, rotation, mirror and core analogy',
      difficulty: 'KOLAY',
      questionCount: 6,
      targetSeconds: 72,
    ),
    PictureIqLevel(
      number: 2,
      titleTr: 'Örüntü ve İlişki',
      titleEn: 'Patterns & Relations',
      subtitleTr: '2×2 matris, simetri ve adet döngüleri',
      subtitleEn: '2×2 matrices, symmetry and count cycles',
      difficulty: 'KOLAY',
      questionCount: 7,
      targetSeconds: 84,
    ),
    PictureIqLevel(
      number: 3,
      titleTr: 'Konum ve Şekil',
      titleEn: 'Position & Shape',
      subtitleTr: 'Komşu konumlar, şekil transferi ve birleşim',
      subtitleEn: 'Adjacent positions, shape transfer and union',
      difficulty: 'ORTA',
      questionCount: 7,
      targetSeconds: 88,
    ),
    PictureIqLevel(
      number: 4,
      titleTr: 'Renk ve Katlama',
      titleEn: 'Colour & Folding',
      subtitleTr: 'Renk ritmi ve kâğıt katlama',
      subtitleEn: 'Colour rhythms and paper folding',
      difficulty: 'ORTA',
      questionCount: 8,
      targetSeconds: 104,
    ),
    PictureIqLevel(
      number: 5,
      titleTr: 'Görsel İşlemler',
      titleEn: 'Visual Operations',
      subtitleTr: 'Görsel seri, birleşim ve ortak parçayı çıkarma',
      subtitleEn: 'Visual series, union and logical difference',
      difficulty: 'ORTA',
      questionCount: 8,
      targetSeconds: 108,
    ),
    PictureIqLevel(
      number: 6,
      titleTr: '3×3 Akıl Yürütme',
      titleEn: '3×3 Reasoning',
      subtitleTr: 'Satır ve sütun ilişkilerini birlikte çöz',
      subtitleEn: 'Solve row and column relations together',
      difficulty: 'ZOR',
      questionCount: 9,
      targetSeconds: 122,
    ),
    PictureIqLevel(
      number: 7,
      titleTr: 'Karma Kurallar',
      titleEn: 'Mixed Rules',
      subtitleTr: 'Birden çok özelliği aynı anda izle',
      subtitleEn: 'Track several visual features at once',
      difficulty: 'ZOR',
      questionCount: 9,
      targetSeconds: 132,
    ),
    PictureIqLevel(
      number: 8,
      titleTr: 'Uzamsal Ustalık',
      titleEn: 'Spatial Mastery',
      subtitleTr: 'İleri matrisler, ayna, katlama ve konum',
      subtitleEn: 'Advanced matrices, mirrors, folds and positions',
      difficulty: 'ZOR',
      questionCount: 10,
      targetSeconds: 146,
    ),
    PictureIqLevel(
      number: 9,
      titleTr: 'İleri Görsel Mantık',
      titleEn: 'Advanced Visual Logic',
      subtitleTr: 'İki eksenli kuralları ve analojileri birleştir',
      subtitleEn: 'Combine two-axis rules and analogies',
      difficulty: 'ZOR',
      questionCount: 11,
      targetSeconds: 162,
    ),
    PictureIqLevel(
      number: 10,
      titleTr: 'Görsel Akıl Finali',
      titleEn: 'Professional Final',
      subtitleTr: '16 soru ailesinden dengeli karma oturum',
      subtitleEn: 'A mixed session across all 16 families',
      difficulty: 'BOSS',
      questionCount: 12,
      targetSeconds: 180,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ParkurLevelHub(
      gameId: 'picture_iq',
      progressPrefix: 'picture_iq',
      titleTr: 'GÖRSEL AKIL',
      titleEn: 'VISUAL REASONING',
      taglineTr: 'İncele • Kuralı Çöz • Profilini Gör',
      taglineEn: 'Observe • Solve • View Your Profile',
      accent: StudioVisuals.teal,
      icon: Icons.psychology_alt_rounded,
      levels: levels,
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? fixedSessionSeed,
            bool competitionMode,
          ) {
            return PictureIqPlayPage(
              level: level as PictureIqLevel,
              previousBestScore: previousBestScore,
              fixedSessionSeed: fixedSessionSeed ?? level.poolIndex,
              competitionMode: competitionMode,
            );
          },
    );
  }
}

class PictureIqLevel extends ParkurLevelSpec {
  final int questionCount;
  final int targetSeconds;

  const PictureIqLevel({
    super.sourceNumber,
    super.poolIndex,
    required super.number,
    required super.titleTr,
    required super.titleEn,
    required super.subtitleTr,
    required super.subtitleEn,
    required super.difficulty,
    required this.questionCount,
    required this.targetSeconds,
  }) : super(icon: Icons.psychology_alt_rounded);
  @override
  PictureIqLevel campaignCopy({
    required int number,
    int? sourceNumber,
    int? poolIndex,
    String? titleTr,
    String? titleEn,
    String? difficulty,
  }) => PictureIqLevel(
    number: number,
    sourceNumber: sourceNumber,
    poolIndex: poolIndex,
    titleTr: titleTr ?? this.titleTr,
    titleEn: titleEn ?? this.titleEn,
    subtitleTr: subtitleTr,
    subtitleEn: subtitleEn,
    difficulty: difficulty ?? this.difficulty,
    questionCount: questionCount,
    targetSeconds: targetSeconds,
  );
}

class PictureIqPlayPage extends StatefulWidget {
  final PictureIqLevel level;
  final int previousBestScore;
  final int? fixedSessionSeed;
  final bool competitionMode;

  const PictureIqPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.fixedSessionSeed,
    this.competitionMode = false,
  });

  @override
  State<PictureIqPlayPage> createState() => _PictureIqPlayPageState();
}

class _PictureIqPlayPageState extends State<PictureIqPlayPage> {
  static const Color _accent = StudioVisuals.teal;

  final GameAudioService _audio = GameAudioService.instance;
  final ReplayabilityService _replayability = ReplayabilityService();
  final ProfessionalIqEngine _engine = ProfessionalIqEngine();
  final Stopwatch _questionWatch = Stopwatch();
  final List<ProfessionalIqAnswerRecord> _answers =
      <ProfessionalIqAnswerRecord>[];

  Timer? _timer;
  List<ProfessionalIqQuestion> _questions = const <ProfessionalIqQuestion>[];
  int _questionIndex = 0;
  int _correct = 0;
  int _mistakes = 0;
  int _elapsed = 0;
  late int _sessionBestScore;
  int _sessionBestStars = 0;
  int? _selectedIndex;
  bool _answerLocked = false;
  bool _completed = false;
  bool _ready = false;

  ProfessionalIqQuestion get _question => _questions[_questionIndex];

  @override
  void initState() {
    super.initState();
    _sessionBestScore = widget.previousBestScore;
    unawaited(_initializeSession());
    unawaited(_audio.preload(GameAudioGroup.ui));
  }

  Future<void> _initializeSession() async {
    final int seed =
        widget.fixedSessionSeed ??
        await _replayability.newSeed(
          gameId: 'picture_iq',
          level: widget.level.contentLevel,
        );
    final List<ProfessionalIqQuestion> questions = await _engine.compose(
      level: widget.level.contentLevel,
      count: widget.level.questionCount,
      sessionSeed: seed,
      fixedSession: widget.fixedSessionSeed != null,
    );
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _ready = true;
    });
    _questionWatch
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted || _completed || _answerLocked) return;
      setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionWatch.stop();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_answerLocked || _completed) return;
    _questionWatch.stop();
    final bool correct = index == _question.correctIndex;
    _answers.add(
      ProfessionalIqAnswerRecord(
        skill: _question.skill,
        correct: correct,
        responseMillis: max(250, _questionWatch.elapsedMilliseconds),
      ),
    );
    setState(() {
      _answerLocked = true;
      _selectedIndex = index;
      if (correct) {
        _correct++;
      } else {
        _mistakes++;
      }
    });
    if (correct) {
      unawaited(_audio.play(GameSound.success));
      HapticFeedback.mediumImpact();
    } else {
      unawaited(_audio.play(GameSound.numberWrong));
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _nextQuestion() async {
    if (!_answerLocked || _completed) return;
    if (_questionIndex + 1 >= _questions.length) {
      await _finish();
      return;
    }
    setState(() {
      _questionIndex++;
      _selectedIndex = null;
      _answerLocked = false;
    });
    _questionWatch
      ..reset()
      ..start();
  }

  Future<void> _finish() async {
    if (_completed) return;
    _completed = true;
    _timer?.cancel();
    _questionWatch.stop();
    final double accuracy = _correct / widget.level.questionCount;
    final int stars = accuracy >= 0.9 && _elapsed <= widget.level.targetSeconds
        ? 3
        : accuracy >= 0.7
        ? 2
        : 1;
    final int score = max(
      200,
      widget.level.number * 250 +
          _correct * 280 +
          max(0, widget.level.targetSeconds - _elapsed) * 8 -
          _mistakes * 90,
    );
    unawaited(
      _audio.playLevelComplete(levelNumber: widget.level.number),
    );
    _sessionBestScore = max(_sessionBestScore, score);
    _sessionBestStars = max(_sessionBestStars, stars);
    if (!mounted) return;
    if (widget.competitionMode) {
      Navigator.pop(
        context,
        ParkurGameResult(
          completed: true,
          stars: _sessionBestStars,
          score: _sessionBestScore,
          nextLevel: false,
        ),
      );
      return;
    }
    final ProfessionalIqCopy copy = ProfessionalIqCopy(
      Localizations.localeOf(context),
    );
    final String localizedDetail = copy.resultDetail(
      _correct,
      widget.level.questionCount,
      _elapsed,
      _mistakes,
    );
    await _showSkillProfile(copy, buildProfessionalIqProfile(_answers));
    if (!mounted) return;
    final ParkurResultAction? action = await showParkurResultDialog(
      context: context,
      accent: _accent,
      titleTr: 'Görsel Akıl Yürütme Tamamlandı!',
      titleEn: copy.text('visualTestComplete'),
      detailTr: localizedDetail,
      detailEn: localizedDetail,
      stars: stars,
      score: score,
      previousBestScore: _sessionBestScore,
      canGoNext: widget.level.number < GameContentPolicy.campaignLevels,
    );
    if (!mounted || action == null) return;
    Navigator.pop(
      context,
      ParkurGameResult(
        completed: true,
        stars: _sessionBestStars,
        score: _sessionBestScore,
        nextLevel: action == ParkurResultAction.next,
        replayLevel: action == ParkurResultAction.replay,
      ),
    );
  }

  Future<void> _showSkillProfile(
    ProfessionalIqCopy copy,
    ProfessionalIqSessionProfile profile,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  StudioVisuals.surface,
                  StudioVisuals.surfaceSoft,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _accent.withValues(alpha: 0.65)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.insights_rounded,
                    color: Color(0xFF3D7183),
                    size: 42,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.text('skillProfile'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    copy.text('profileSubtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final ProfessionalIqSkillResult result in profile.skills)
                    _SkillMeter(copy: copy, result: result),
                  if (profile.strongest != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _ProfileHighlight(
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFF8B622C),
                      label: copy.text('strongest'),
                      value: copy.skillName(profile.strongest!.skill),
                    ),
                  ],
                  if (profile.growthArea != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _ProfileHighlight(
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF34715D),
                      label: copy.text('growthArea'),
                      value: copy.skillName(profile.growthArea!.skill),
                    ),
                  ],
                  const SizedBox(height: 13),
                  Text(
                    copy.text('notClinical'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: const Color(0xFFEEF3F0),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.star_rounded),
                      label: Text(
                        copy.text('continueToResult'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProfessionalIqCopy copy = ProfessionalIqCopy(
      Localizations.localeOf(context),
    );
    if (!_ready) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${copy.text('visualReasoning')} • ${widget.level.number}/${GameContentPolicy.campaignLevels}',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints limits) {
            final bool compact = limits.maxHeight < 690;
            return ListView(
              padding: EdgeInsets.fromLTRB(14, compact ? 3 : 9, 14, 24),
              children: <Widget>[
                _IqHeader(
                  progress: copy.questionProgress(
                    _questionIndex + 1,
                    _questions.length,
                  ),
                  correct: _correct,
                  elapsed: _elapsed,
                ),
                SizedBox(height: compact ? 9 : 14),
                Text(
                  copy.prompt(_question),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 7),
                Center(
                  child: _FamilyChip(label: copy.familyName(_question.family)),
                ),
                SizedBox(height: compact ? 8 : 12),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: _QuestionBoard(question: _question, compact: compact),
                ),
                SizedBox(height: compact ? 9 : 14),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _question.options.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                      // The artwork is the answer, not decoration. Give the
                      // visual tile enough vertical space to be read at a
                      // glance, while the list remains scrollable on short
                      // phones.
                      mainAxisExtent: compact ? 116 : 132,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final bool selected = _selectedIndex == index;
                      final bool correct = index == _question.correctIndex;
                      Color border = const Color(0xFFD7E2EA);
                      Color background = Colors.white;
                      if (_answerLocked && correct) {
                        border = const Color(0xFF20A464);
                        background = const Color(0xFFEAF8F1);
                      } else if (_answerLocked && selected) {
                        border = const Color(0xFFE64B5D);
                        background = const Color(0xFFFFEEF0);
                      } else if (selected) {
                        border = const Color(0xFF4A90D9);
                        background = const Color(0xFFEEF6FF);
                      }
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _answerLocked
                              ? null
                              : () => _selectAnswer(index),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: border, width: 1.4),
                            ),
                            child: Stack(
                              children: <Widget>[
                                Center(
                                  child: _FigureView(
                                    figure: _question.options[index],
                                    scene: _question.scene,
                                  ),
                                ),
                                Positioned(
                                  left: 9,
                                  top: 7,
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      color: Color(0xFF526D82),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_answerLocked) ...<Widget>[
                  const SizedBox(height: 11),
                  _ExplanationCard(copy: copy, question: _question),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _nextQuestion,
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: const Color(0xFFEEF3F0),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: Icon(
                        _questionIndex + 1 == _questions.length
                            ? Icons.insights_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _questionIndex + 1 == _questions.length
                            ? copy.text('viewProfile')
                            : copy.text('nextQuestion'),
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuestionBoard extends StatelessWidget {
  final ProfessionalIqQuestion question;
  final bool compact;

  const _QuestionBoard({required this.question, required this.compact});

  @override
  Widget build(BuildContext context) {
    if (question.layout == ProfessionalIqLayout.oddOneOut) {
      return const SizedBox(height: 2);
    }
    return switch (question.layout) {
      ProfessionalIqLayout.analogy => _buildAnalogy(),
      ProfessionalIqLayout.transform => _buildTransform(),
      ProfessionalIqLayout.relation => _buildRelation(),
      ProfessionalIqLayout.matrix2 ||
      ProfessionalIqLayout.matrix3 => _buildMatrix(),
      ProfessionalIqLayout.series => _buildSeries(),
      ProfessionalIqLayout.oddOneOut => const SizedBox.shrink(),
    };
  }

  Widget _buildSeries() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 10 : 14,
      ),
      decoration: _boardDecoration,
      child: Row(
        children: <Widget>[
          for (
            int index = 0;
            index < question.board.length;
            index++
          ) ...<Widget>[
            Expanded(child: _boardCell(question.board[index])),
            if (index < question.board.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: Color(0xFF8BA0B4),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransform() {
    final ProfessionalIqFigure? source = question.board.isNotEmpty
        ? question.board.first
        : null;
    final ProfessionalIqFigure? target = question.board.length > 1
        ? question.board[1]
        : null;
    final bool mirror = question.family == ProfessionalIqFamily.mirror;
    final bool shape = question.family == ProfessionalIqFamily.shapeTransform;
    final String label = mirror
        ? 'AYNA'
        : shape
        ? 'ŞEKİL'
        : '${(question.operationCode.clamp(1, 3) * 90)}°';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 12 : 16,
      ),
      decoration: _boardDecoration,
      child: Row(
        children: <Widget>[
          Expanded(child: _boardCell(source)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  mirror || shape
                      ? (shape
                            ? Icons.swap_horiz_rounded
                            : Icons.compare_arrows_rounded)
                      : Icons.rotate_right_rounded,
                  color: const Color(0xFF35556E),
                  size: 26,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF35556E),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _boardCell(target)),
        ],
      ),
    );
  }

  Widget _buildAnalogy() {
    final List<ProfessionalIqFigure?> items = question.board;
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: _boardDecoration,
      child: Column(
        children: <Widget>[
          _analogyLine(items[0], items[1], 'A', 'B'),
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFE3EAF0)),
          const SizedBox(height: 8),
          _analogyLine(items[2], items[3], 'C', '?'),
        ],
      ),
    );
  }

  Widget _analogyLine(
    ProfessionalIqFigure? left,
    ProfessionalIqFigure? right,
    String leftLabel,
    String rightLabel,
  ) {
    return Row(
      children: <Widget>[
        Expanded(child: _labeledBoardCell(left, leftLabel)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: Color(0xFF526D82),
            size: 24,
          ),
        ),
        Expanded(child: _labeledBoardCell(right, rightLabel)),
      ],
    );
  }

  Widget _labeledBoardCell(ProfessionalIqFigure? figure, String label) {
    return Stack(
      children: <Widget>[
        _boardCell(figure),
        Positioned(
          left: 7,
          top: 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2F8),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF35556E),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelation() {
    final String operator = switch (question.family) {
      ProfessionalIqFamily.overlay => '+',
      ProfessionalIqFamily.xor => '⊕',
      ProfessionalIqFamily.symmetry => '↔',
      ProfessionalIqFamily.paperFold => '⤵',
      _ => '+',
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 10 : 14,
      ),
      decoration: _boardDecoration,
      child: Row(
        children: <Widget>[
          Expanded(child: _boardCell(question.board[0])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              operator,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFF35556E),
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(child: _boardCell(question.board[1])),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '=',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFF35556E),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(child: _boardCell(question.board[2])),
        ],
      ),
    );
  }

  Widget _buildMatrix() {
    final int columns = question.boardColumns;
    final double cellHeight = compact ? 58 : 70;
    return Container(
      padding: EdgeInsets.all(compact ? 9 : 13),
      decoration: _boardDecoration,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: question.board.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 7,
          mainAxisSpacing: 7,
          mainAxisExtent: cellHeight,
        ),
        itemBuilder: (BuildContext context, int index) =>
            _boardCell(question.board[index]),
      ),
    );
  }

  Widget _boardCell(ProfessionalIqFigure? figure) {
    if (figure == null) return const _MissingFigureCard();
    return _FigureCard(figure: figure, scene: question.scene);
  }

  BoxDecoration get _boardDecoration => BoxDecoration(
    color: const Color(0xFFF8FAFC),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFD9E4EC)),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: .12),
        blurRadius: 16,
        offset: const Offset(0, 7),
      ),
    ],
  );
}

class _FigureCard extends StatelessWidget {
  final ProfessionalIqFigure figure;
  final ProfessionalIqScene scene;

  const _FigureCard({required this.figure, required this.scene});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFCFEFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4E2EB), width: 1.2),
      ),
      child: _FigureView(
        figure: figure,
        scene: scene,
        silhouette: scene == ProfessionalIqScene.parts,
      ),
    );
  }
}

class _MissingFigureCard extends StatelessWidget {
  const _MissingFigureCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF69A9E8), width: 1.5),
      ),
      child: const Text(
        '?',
        style: TextStyle(
          fontFamily: 'Roboto',
          color: Color(0xFF1F6EB7),
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FigureView extends StatelessWidget {
  final ProfessionalIqFigure figure;
  final ProfessionalIqScene scene;
  final bool silhouette;

  const _FigureView({
    required this.figure,
    this.scene = ProfessionalIqScene.symbols,
    this.silhouette = false,
  });

  @override
  Widget build(BuildContext context) {
    if (figure.isDotPattern) {
      if (scene == ProfessionalIqScene.fold) {
        return _PaperFoldPattern(figure: figure);
      }
      return _DotPattern(figure: figure);
    }

    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints constraints) {
        final double width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 96;
        final double height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 96;
        final double usable = max(20, min(width, height) - 10);
        final double countFactor = switch (figure.count) {
          1 => .76,
          2 => .45,
          _ => .31,
        };
        final double upperBound = switch (figure.count) {
          1 => 72,
          2 => 54,
          _ => 40,
        };
        final double lowerBound = figure.count == 1 ? 30 : 20;
        final double motifSize = min(
          upperBound,
          max(lowerBound, usable * countFactor * (figure.size == 1 ? 1 : .78)),
        );
        final Alignment alignment = Alignment(
          (figure.position % 3 - 1) * 0.72,
          (figure.position ~/ 3 - 1) * 0.62,
        );

        final Widget motifs = FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int index = 0; index < figure.count; index++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: ProfessionalIqMotif(
                    motif: figure.shape,
                    colorIndex: figure.color,
                    rotation: figure.rotation,
                    mirrored: figure.mirrorMatters && figure.mirrored,
                    size: motifSize,
                  ),
                ),
            ],
          ),
        );

        final Widget renderedMotifs = silhouette
            ? ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFF263E52),
                  BlendMode.srcIn,
                ),
                child: motifs,
              )
            : motifs;

        final Widget positioned = Padding(
          padding: const EdgeInsets.all(5),
          child: Align(alignment: alignment, child: renderedMotifs),
        );

        if (scene == ProfessionalIqScene.spatialGrid) {
          final double gridSize = min(92, max(52, usable));
          return SizedBox.square(
            dimension: gridSize,
            child: CustomPaint(
              painter: const _SpatialGridPainter(),
              child: positioned,
            ),
          );
        }
        return positioned;
      },
    );
  }
}

class _SpatialGridPainter extends CustomPainter {
  const _SpatialGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()..color = const Color(0xFFF6F9FC);
    final Paint line = Paint()
      ..color = const Color(0xFFB8C9D8)
      ..strokeWidth = 0.9;
    final RRect card = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(9),
    );
    canvas.drawRRect(card, fill);
    for (int i = 1; i < 3; i++) {
      final double x = size.width * i / 3;
      final double y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    canvas.drawRRect(
      card,
      Paint()
        ..color = const Color(0xFF9EB6C9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SpatialGridPainter oldDelegate) => false;
}

class _PaperFoldPattern extends StatelessWidget {
  final ProfessionalIqFigure figure;

  const _PaperFoldPattern({required this.figure});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(painter: _PaperFoldPainter(figure: figure)),
    );
  }
}

class _PaperFoldPainter extends CustomPainter {
  final ProfessionalIqFigure figure;

  const _PaperFoldPainter({required this.figure});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect paper = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(paper, const Radius.circular(5)),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(paper, const Radius.circular(5)),
      Paint()
        ..color = const Color(0xFF9DB2C3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final Paint dash = Paint()
      ..color = const Color(0xFF6B879C)
      ..strokeWidth = 1.1;
    if (figure.pattern.isEven) {
      final double x = size.width / 2;
      for (double y = 8; y < size.height - 8; y += 7) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 3.5), dash);
      }
    } else {
      final double y = size.height / 2;
      for (double x = 8; x < size.width - 8; x += 7) {
        canvas.drawLine(Offset(x, y), Offset(x + 3.5, y), dash);
      }
    }

    final double cell = (size.width - 18) / 3;
    for (int index = 0; index < 9; index++) {
      if ((figure.dotMask & (1 << index)) == 0) continue;
      final int row = index ~/ 3;
      final int col = index % 3;
      final Offset center = Offset(
        9 + col * cell + cell / 2,
        9 + row * cell + cell / 2,
      );
      canvas.drawCircle(center, 3.4, Paint()..color = const Color(0xFF263E52));
    }
  }

  @override
  bool shouldRepaint(covariant _PaperFoldPainter oldDelegate) =>
      oldDelegate.figure.dotMask != figure.dotMask ||
      oldDelegate.figure.pattern != figure.pattern;
}

class _DotPattern extends StatelessWidget {
  final ProfessionalIqFigure figure;

  const _DotPattern({required this.figure});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (BuildContext context, int index) {
          final bool active = (figure.dotMask & (1 << index)) != 0;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: active
                  ? ProfessionalIqMotif.palette[figure.color %
                        ProfessionalIqMotif.palette.length]
                  : const Color(0xFFE8EDF2),
              shape: figure.pattern.isEven
                  ? BoxShape.circle
                  : BoxShape.rectangle,
              border: Border.all(
                color: active
                    ? const Color(0xFF39546A).withValues(alpha: .35)
                    : const Color(0xFFD4DEE6),
              ),
              borderRadius: figure.pattern.isEven
                  ? null
                  : BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }
}

class _IqHeader extends StatelessWidget {
  final String progress;
  final int correct;
  final int elapsed;

  const _IqHeader({
    required this.progress,
    required this.correct,
    required this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StudioVisuals.line),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              progress,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF34715D),
            size: 18,
          ),
          const SizedBox(width: 5),
          Text(
            '$correct',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 13),
          const Icon(Icons.timer_outlined, color: Color(0xFF3D7183), size: 18),
          const SizedBox(width: 5),
          Text(
            '${elapsed}s',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyChip extends StatelessWidget {
  final String label;

  const _FamilyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: StudioVisuals.tealSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: StudioVisuals.teal.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: StudioVisuals.tealInk,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final ProfessionalIqCopy copy;
  final ProfessionalIqQuestion question;

  const _ExplanationCard({required this.copy, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: StudioVisuals.tealSoft,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: StudioVisuals.teal.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            copy.text('explanation'),
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.tealInk,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            copy.explanation(question),
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillMeter extends StatelessWidget {
  final ProfessionalIqCopy copy;
  final ProfessionalIqSkillResult result;

  const _SkillMeter({required this.copy, required this.result});

  @override
  Widget build(BuildContext context) {
    final bool measured = result.total > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  copy.skillName(result.skill),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                measured ? '${result.performance}%' : copy.text('notMeasured'),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: measured
                      ? const Color(0xFF3D7183)
                      : StudioVisuals.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: measured ? result.performance / 100 : 0,
              minHeight: 7,
              backgroundColor: StudioVisuals.line,
              color: const Color(0xFF3D7183),
            ),
          ),
          if (measured) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              '${result.correct}/${result.total} • ${copy.averageSeconds(result.averageMillis)}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHighlight extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _ProfileHighlight({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
