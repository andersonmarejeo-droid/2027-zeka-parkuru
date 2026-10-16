import '../shared/studio_game_contracts.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/studio_visuals.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../games/shared/game_audio_profile.dart';
import '../../games/shared/parkur_game_kit.dart';
import '../../games/shared/studio_game_session.dart';
import '../../games/shared/studio_game_skin.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import 'atlas_map_painter.dart';
import 'atlas_puzzle.dart';
import 'reference_game_support.dart';

class AtlasFindGamePage extends StatelessWidget {
  const AtlasFindGamePage({
    super.key,
    required this.kind,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });
  static const int totalCases = GameContentPolicy.campaignLevels;
  static const int totalStars = totalCases * 3;

  final AtlasKind kind;
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;
  bool get _turkey => kind == AtlasKind.turkey;
  String get _id => _turkey ? 'city_atlas' : 'world_atlas';
  String get _titleTr => _turkey ? 'Şehir Atlası' : 'Dünya Atlası';
  String get _titleEn => _turkey ? 'Turkey Atlas' : 'World Atlas';
  IconData get _icon => _turkey ? Icons.map_outlined : Icons.public_rounded;

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId(_id);
    return ParkurLevelHub(
      gameId: _id,
      progressPrefix: _id,
      titleTr: _titleTr,
      titleEn: _titleEn,
      taglineTr: _turkey
          ? '81 ili gerçek harita üzerinde bul'
          : 'Ülkeleri sınırlarından tanı',
      taglineEn: _turkey
          ? 'Find all 81 provinces on a real map'
          : 'Recognize countries by their borders',
      accent: skin.accent,
      icon: _icon,
      levels: referenceLevels(
        titleTr: _turkey ? 'Anadolu' : 'Dünya',
        titleEn: _turkey ? 'Anatolia' : 'World',
        icon: _icon,
        english: context.l10n.isEnglish,
      ),
      dailyCourseMode: dailyCourseMode,
      competitionLevel: competitionLevel,
      competitionLayoutCode: competitionLayoutCode,
      playBuilder: (
        BuildContext context,
        ParkurLevelSpec level,
        int best,
        int? layout,
        bool competition,
      ) => _AtlasPlayPage(
        kind: kind,
        level: level,
        dailyCourseMode: dailyCourseMode,
      ),
    );
  }
}

class _AtlasPlayPage extends StatefulWidget {
  const _AtlasPlayPage({
    required this.kind,
    required this.level,
    required this.dailyCourseMode,
  });
  final AtlasKind kind;
  final ParkurLevelSpec level;
  final bool dailyCourseMode;

  @override
  State<_AtlasPlayPage> createState() => _AtlasPlayPageState();
}

class _AtlasPlayPageState extends State<_AtlasPlayPage>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFF247568);
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _profile = GameAudioProfile.forClass(
    StudioGameClass.visual,
  );
  late final TextEditingController _answerController;
  late final AnimationController _revealController;
  late final AnimationController _hintPulseController;
  late final AnimationController _confettiController;
  late final Animation<double> _hintPulse;
  late final StudioGameSession _session;
  List<AtlasFeature> _features = const <AtlasFeature>[];
  List<AtlasFeature> _targets = const <AtlasFeature>[];
  bool _loading = true;
  bool _finished = false;
  bool _english = false;
  bool _answerLocked = false;
  bool _answerCorrect = false;
  int _question = 0;
  int _mistakes = 0;
  int _hintCount = 0;
  String? _revealedCode;
  String? _feedback;
  bool _showConfetti = false;

  int get _pointsForCurrentAnswer =>
      AtlasScorePolicy.pointsForHints(_hintCount);

  String get _gameId =>
      widget.kind == AtlasKind.turkey ? 'city_atlas' : 'world_atlas';

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _hintPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _hintPulse = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: .42),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: .42, end: 1),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: .42),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: .42, end: 1),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: _hintPulseController, curve: Curves.easeInOut),
    );
    _hintPulseController.forward();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
      maxHints: AtlasScorePolicy.maxHintsPerQuestion,
    )..start();
    unawaited(_profile.preload(_audio));
    unawaited(_prepare());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _english = context.l10n.isEnglish;
  }

  @override
  void dispose() {
    _answerController.dispose();
    _revealController.dispose();
    _hintPulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final List<AtlasFeature> features = await AtlasDataset.load(widget.kind);
    final List<AtlasFeature> candidates = features
        .where((AtlasFeature f) => AtlasDataset.isTarget(widget.kind, f.code))
        .toList();
    final int variant =
        widget.level.poolIndex ??
        await ReferenceRoundStore.reserve(
          gameId: _gameId,
          level: widget.level.number,
        );
    final List<String> questionCodes = atlasQuestionCodes(
      kind: widget.kind,
      codes: candidates.map((AtlasFeature feature) => feature.code),
      level: widget.level.contentLevel,
      variant: variant,
    );
    final Map<String, AtlasFeature> byCode = <String, AtlasFeature>{
      for (final AtlasFeature feature in candidates) feature.code: feature,
    };
    if (!mounted) return;
    setState(() {
      _features = features;
      _targets = questionCodes
          .map((String code) => byCode[code]!)
          .toList(growable: false);
      _loading = false;
    });
  }

  void _hint() {
    if (_finished ||
        _answerLocked ||
        _targets.isEmpty ||
        _hintCount >= AtlasScorePolicy.maxHintsPerQuestion ||
        !_session.canUseHint) {
      return;
    }
    _session.useHint();
    setState(() {
      _hintCount++;
      _feedback = null;
    });
    _sound(GameAudioEvent.hint);
  }

  Future<void> _submitAnswer() async {
    if (_loading || _finished || _answerLocked || _targets.isEmpty) return;
    final String answer = _answerController.text.trim();
    if (answer.isEmpty) {
      setState(() {
        _feedback = _english ? 'Type an answer first.' : 'Önce bir cevap yaz.';
      });
      return;
    }

    final AtlasFeature target = _targets[_question];
    if (!AtlasDataset.answerMatches(widget.kind, target.code, answer)) {
      _session.recordMistake();
      _mistakes++;
      _sound(GameAudioEvent.rejected);
      setState(() {
        _feedback = _english
            ? 'That does not match. Try again or use a hint.'
            : 'Eşleşmedi. Yeniden dene ya da ek ipucu kullan.';
      });
      return;
    }

    _session.recordAccepted(points: _pointsForCurrentAnswer);
    // Atlas sorularında doğru cevap, Blok Blast'teki bölüm başarı jingle'ı
    // kadar belirgin bir geri bildirim vermeli. Son soruda bu efekt bölüm
    // kapanışında zaten çalacağı için iki kez üst üste oynatmayalım.
    final bool completesLevel = _question + 1 >= _targets.length;
    if (!completesLevel) {
      unawaited(_audio.play(GameSound.levelComplete, gain: .78));
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _answerLocked = true;
      _answerCorrect = true;
      _revealedCode = target.code;
      _feedback =
          '${_english ? 'Correct' : 'Doğru'}: ${AtlasDataset.label(widget.kind, target.code, english: _english)}';
    });
    await _revealController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    if (_question + 1 >= _targets.length) {
      await _finish();
      return;
    }
    setState(() {
      _question++;
      _answerController.clear();
      _answerLocked = false;
      _answerCorrect = false;
      _hintCount = 0;
      _revealedCode = null;
      _feedback = null;
    });
    unawaited(_hintPulseController.forward(from: 0));
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    final int stars = _mistakes == 0
        ? 3
        : _mistakes <= _targets.length ~/ 3
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: StudioResultAction.next,
    );
    _sound(GameAudioEvent.levelComplete);
    if (mounted) {
      setState(() => _showConfetti = true);
      _confettiController.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pop(
        widget.dailyCourseMode
            ? result.toDailyStageResult(_gameId)
            : result.toParkurResult(),
      );
    }
  }

  void _sound(GameAudioEvent event) => unawaited(
    _profile.play(
      _audio,
      event,
      gain: .32,
      levelNumber: event == GameAudioEvent.levelComplete
          ? widget.level.number
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bool turkey = widget.kind == AtlasKind.turkey;
    final String title = turkey
        ? (_english ? 'Name the province' : 'İl adını ipucundan bul')
        : (_english ? 'Name the country' : 'Ülke adını ipucundan bul');
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F6F3),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final double aspect = turkey ? 1.90 : 1.80;
    final AtlasFeature target = _targets[_question];
    final String targetCode = target.code;
    return ReferencePlayScaffold(
      title: turkey
          ? (_english ? 'Turkey Atlas' : 'Şehir Atlası')
          : (_english ? 'World Atlas' : 'Dünya Atlası'),
      level: widget.level.contentLevel,
      accent: _accent,
      english: _english,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          ReferenceCard(
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.explore_outlined, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF23333A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _english
                            ? 'Question ${_question + 1} of ${_targets.length} · write the answer'
                            : 'Soru ${_question + 1} / ${_targets.length} · cevabı yaz',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Color(0xFF75847E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ReferenceCard(
            padding: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: _accent,
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _english ? 'ATLAS CLUE' : 'ATLAS İPUCU',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: _accent,
                          fontSize: 12,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F6F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_session.score} ${_english ? 'pts' : 'puan'}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF60736C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AtlasDataset.areaClue(
                    widget.kind,
                    targetCode,
                    english: _english,
                  ),
                  key: const ValueKey<String>('atlas_area_clue'),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF23333A),
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_hintCount >= 1) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    AtlasDataset.positionClue(
                      widget.kind,
                      target,
                      english: _english,
                    ),
                    key: const ValueKey<String>('atlas_position_hint'),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Color(0xFF66766F),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
                if (_hintCount >= 2) ...<Widget>[
                  const SizedBox(height: 7),
                  Text(
                    AtlasDataset.culturalClue(
                      widget.kind,
                      targetCode,
                      english: _english,
                    ),
                    key: const ValueKey<String>('atlas_cultural_hint'),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Color(0xFF66766F),
                      fontSize: 14,
                    ),
                  ),
                ],
                if (_hintCount >= 3) ...<Widget>[
                  const SizedBox(height: 7),
                  Text(
                    AtlasDataset.culturalDetailClue(
                      widget.kind,
                      targetCode,
                      english: _english,
                    ),
                    key: const ValueKey<String>(
                      'atlas_cultural_detail_hint',
                    ),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Color(0xFF66766F),
                      fontSize: 14,
                    ),
                  ),
                ],
                if (_hintCount >= 4) ...<Widget>[
                  const SizedBox(height: 7),
                  Text(
                    AtlasDataset.nameStructureClue(
                      widget.kind,
                      targetCode,
                      english: _english,
                    ),
                    key: const ValueKey<String>('atlas_structure_hint'),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Color(0xFF66766F),
                      fontSize: 14,
                    ),
                  ),
                ],
                if (_hintCount >= 5) ...<Widget>[
                  const SizedBox(height: 7),
                  Text(
                    AtlasDataset.firstLetterClue(
                      widget.kind,
                      targetCode,
                      english: _english,
                    ),
                    key: const ValueKey<String>('atlas_letter_hint'),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (_hintCount >= 6) ...<Widget>[
                  const SizedBox(height: 7),
                  Text(
                    AtlasDataset.lastLetterClue(
                      widget.kind,
                      targetCode,
                      english: _english,
                    ),
                    key: const ValueKey<String>('atlas_last_letter_hint'),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  _english
                      ? 'The name stays hidden until you answer correctly.'
                      : 'Doğru yanıt gelene kadar şehir/ülke adı gizli kalır.',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ReferenceCard(
            padding: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 2, 5, 9),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        turkey ? Icons.map_outlined : Icons.public_rounded,
                        color: _accent,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _english ? 'MAP' : 'HARİTA',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Color(0xFF60736C),
                          fontSize: 12,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final Size size = Size(
                      constraints.maxWidth,
                      constraints.maxWidth / aspect,
                    );
                    return AnimatedBuilder(
                      animation: _revealController,
                      builder: (BuildContext context, Widget? child) {
                        return SizedBox.fromSize(
                          size: size,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 3.4,
                              boundaryMargin: const EdgeInsets.all(24),
                              constrained: false,
                              child: CustomPaint(
                                size: size,
                                painter: AtlasMapPainter(
                                  kind: widget.kind,
                                  features: _features,
                                  revealCode: _revealedCode,
                                  revealProgress: _revealController.value,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    _answerCorrect
                        ? (_english
                              ? 'The correct region is highlighted.'
                              : 'Doğru bölge haritada yanıp sönüyor.')
                        : (_english
                              ? 'It will flash here when you solve the clue.'
                              : 'Doğru cevabında hedef bölge burada yanıp söner.'),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ReferenceCard(
            padding: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _english ? 'WRITE YOUR ANSWER' : 'CEVABI YAZ',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Color(0xFF60736C),
                    fontSize: 12,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey<String>('atlas_answer_input'),
                  controller: _answerController,
                  enabled: !_answerLocked,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: 48,
                  onChanged: (_) => setState(() => _feedback = null),
                  onSubmitted: (_) => unawaited(_submitAnswer()),
                  decoration: InputDecoration(
                    hintText: turkey
                        ? (_english ? 'Province name' : 'İl adı')
                        : (_english ? 'Country name' : 'Ülke adı'),
                    prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF7F9F7),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE0E8E3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE0E8E3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _accent, width: 1.6),
                    ),
                  ),
                ),
                if (_feedback != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _answerCorrect
                          ? const Color(0xFFE7F6EF)
                          : const Color(0xFFFFF0EC),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      _feedback!,
                      key: const ValueKey<String>('atlas_answer_feedback'),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: _answerCorrect
                            ? const Color(0xFF247455)
                            : const Color(0xFFAD5745),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _hintPulse,
                        builder: (BuildContext context, Widget? child) {
                          final bool canHint =
                              _hintCount < AtlasScorePolicy.maxHintsPerQuestion &&
                              !_answerLocked;
                          final double pulse = canHint ? _hintPulse.value : 1;
                          final Color pulseColor = Color.lerp(
                            const Color(0xFFE6F5EE),
                            const Color(0xFFFFD166),
                            1 - pulse,
                          )!;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: pulseColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: canHint && pulse < .9
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: const Color(0xFFFFB300)
                                            .withValues(alpha: .28),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: TextButton.icon(
                              key: const ValueKey<String>('atlas_hint_button'),
                              onPressed: canHint ? _hint : null,
                              style: TextButton.styleFrom(
                                foregroundColor: canHint
                                    ? _accent
                                    : const Color(0xFF7C8C85),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(
                                Icons.lightbulb_outline_rounded,
                              ),
                              label: Text(
                                _hintCount >=
                                        AtlasScorePolicy.maxHintsPerQuestion
                                    ? (_english
                                          ? 'Hints complete · $_pointsForCurrentAnswer pts'
                                          : 'İpuçları tamamlandı · $_pointsForCurrentAnswer puan')
                                    : (_english
                                          ? 'Take hint · $_hintCount/${AtlasScorePolicy.maxHintsPerQuestion} · $_pointsForCurrentAnswer pts'
                                          : 'İpucu Al · $_hintCount/${AtlasScorePolicy.maxHintsPerQuestion} · $_pointsForCurrentAnswer puan'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_session.score} ${_english ? 'pts' : 'puan'}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFF60736C),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ReferencePrimaryButton(
                  label: _answerCorrect
                      ? (_english ? 'Correct answer' : 'Cevap doğru')
                      : (_english ? 'CHECK ANSWER' : 'CEVABI KONTROL ET'),
                  accent: _accent,
                  icon: _answerCorrect
                      ? Icons.check_circle_outline_rounded
                      : Icons.arrow_forward_rounded,
                  enabled:
                      !_answerLocked &&
                      _answerController.text.trim().isNotEmpty,
                  onPressed: () => unawaited(_submitAnswer()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (_question + 1) / _targets.length,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2EAE5),
              color: _accent,
            ),
          ),
            ],
          ),
          if (_showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (BuildContext context, Widget? child) => CustomPaint(
                    painter: _AtlasConfettiPainter(
                      progress: _confettiController.value,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AtlasConfettiPainter extends CustomPainter {
  const _AtlasConfettiPainter({required this.progress});

  final double progress;

  static const List<Color> _colors = <Color>[
    Color(0xFFFFC857),
    Color(0xFF2EC4B6),
    Color(0xFFFF6B6B),
    Color(0xFF5C7CFA),
    Color(0xFFF783AC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double fade = (1 - math.max(0, progress - .72) / .28)
        .clamp(0.0, 1.0)
        .toDouble();
    for (int index = 0; index < 56; index++) {
      final double x = ((index * 37) % 101) / 100 * size.width;
      final double sway = math.sin(progress * 7 + index * .8) * 18;
      final double y = -24 + progress * (size.height + 54) + (index % 8) * 6;
      final double rotation = progress * math.pi * (1.5 + index % 4);
      final double width = index.isEven ? 7 : 5;
      final double height = index.isEven ? 13 : 9;
      paint.color = _colors[index % _colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AtlasConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
