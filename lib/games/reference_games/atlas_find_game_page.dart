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
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int best,
            int? layout,
            bool competition,
          ) => AtlasPlayPage(
            kind: kind,
            level: level,
            dailyCourseMode: dailyCourseMode,
          ),
    );
  }
}

class AtlasPlayPage extends StatefulWidget {
  const AtlasPlayPage({
    super.key,
    required this.kind,
    required this.level,
    this.dailyCourseMode = false,
  });
  final AtlasKind kind;
  final ParkurLevelSpec level;
  final bool dailyCourseMode;

  @override
  State<AtlasPlayPage> createState() => _AtlasPlayPageState();
}

class _AtlasPlayPageState extends State<AtlasPlayPage>
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

  Timer? _autoAdvanceTimer;

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
      duration: const Duration(milliseconds: 900),
    );
    _hintPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _hintPulse =
        TweenSequence<double>(<TweenSequenceItem<double>>[
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
          CurvedAnimation(
            parent: _hintPulseController,
            curve: Curves.easeInOut,
          ),
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
    _autoAdvanceTimer?.cancel();
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

  String _hintText(int index, AtlasFeature target) => switch (index) {
    1 => AtlasDataset.positionClue(widget.kind, target, english: _english),
    2 => AtlasDataset.culturalClue(widget.kind, target.code, english: _english),
    3 => AtlasDataset.culturalDetailClue(
      widget.kind,
      target.code,
      english: _english,
    ),
    4 => AtlasDataset.nameStructureClue(
      widget.kind,
      target.code,
      english: _english,
    ),
    5 => AtlasDataset.firstLetterClue(
      widget.kind,
      target.code,
      english: _english,
    ),
    _ => AtlasDataset.lastLetterClue(
      widget.kind,
      target.code,
      english: _english,
    ),
  };

  void _skipQuestion() {
    if (_loading || _finished || _answerLocked || _targets.isEmpty) return;
    _autoAdvanceTimer?.cancel();
    final AtlasFeature target = _targets[_question];
    _session.recordMistake();
    _mistakes++;
    _sound(GameAudioEvent.hint);
    FocusScope.of(context).unfocus();

    setState(() {
      _answerLocked = true;
      _answerCorrect = false;
      _revealedCode = target.code;
      _feedback =
          '${_english ? 'Skipped. Correct answer' : 'Pas geçildi. Doğru yanıt'}: ${AtlasDataset.label(widget.kind, target.code, english: _english)}';
    });

    unawaited(_revealController.forward(from: 0));
    // 1400 ms sonra otonom olarak sonraki soruya geçer (veya kullanıcı butona basabilir)
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) _proceedToNext();
    });
  }

  Future<void> _submitAnswer() async {
    if (_loading || _finished || _targets.isEmpty) return;
    // Eğer cevap zaten kilitliyse (doğru veya pas geçilmişse), butona basarak anında sonraki soruya geç
    if (_answerLocked) {
      _proceedToNext();
      return;
    }

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

    _autoAdvanceTimer?.cancel();
    _session.recordAccepted(points: _pointsForCurrentAnswer);
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

    unawaited(_revealController.forward(from: 0));

    // Doğru bilinince otonom olarak (850ms) sonraki soruya ilerler
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 850), () {
      if (mounted) _proceedToNext();
    });
  }

  void _proceedToNext() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
    if (_finished || !mounted) return;

    if (_question + 1 >= _targets.length) {
      unawaited(_finish());
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
    final double aspect = turkey ? 2.75 : 2.65;
    final AtlasFeature target = _targets[_question];
    final String targetCode = target.code;
    return ReferencePlayScaffold(
      title: turkey
          ? (_english ? 'Turkey Atlas' : 'Şehir Atlası')
          : (_english ? 'World Atlas' : 'Dünya Atlası'),
      level: widget.level.contentLevel,
      accent: _accent,
      english: _english,
      scrollable: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ReferenceCard(
                padding: 10,
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
              const SizedBox(height: 6),
              ReferenceCard(
                padding: 10,
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
                    const SizedBox(height: 5),
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
                    if (_hintCount > 0)
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: ExpansionTile(
                          key: const ValueKey<String>('atlas_hints_dropdown'),
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 4),
                          minTileHeight: 38,
                          title: Text(
                            _english
                                ? 'Hints revealed ($_hintCount)'
                                : 'Görülen ipuçları ($_hintCount)',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: _accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            _hintText(_hintCount, target),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          children: <Widget>[
                            for (int index = 1; index <= _hintCount; index++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${_english ? 'Hint' : 'İpucu'} $index: ${_hintText(index, target)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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
              const SizedBox(height: 6),
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
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final Size size = Size(
                              constraints.maxWidth,
                              constraints.maxWidth / aspect,
                            );
                            return SizedBox.fromSize(
                              size: size,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 3.4,
                                  boundaryMargin: const EdgeInsets.all(24),
                                  constrained: false,
                                  child: RepaintBoundary(
                                    child: CustomPaint(size: size, isComplex: true, willChange: _revealedCode != null,
                                      painter: AtlasMapPainter(
                                        kind: widget.kind,
                                        features: _features,
                                        revealCode: _revealedCode,
                                        revealProgress: _revealController.value,
                                        revealAnimation: _revealController,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                    ),
                    const SizedBox(height: 5),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 6),
              ReferenceCard(
                padding: 10,
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
                      onChanged: (_) {
                        if (_feedback != null) {
                          setState(() => _feedback = null);
                        }
                      },
                      onSubmitted: (_) => unawaited(_submitAnswer()),
                      decoration: InputDecoration(
                        hintText: turkey
                            ? (_english ? 'Province name' : 'İl adı')
                            : (_english ? 'Country name' : 'Ülke adı'),
                        prefixIcon: const Icon(
                          Icons.edit_location_alt_outlined,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F9F7),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E8E3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E8E3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _accent,
                            width: 1.6,
                          ),
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
                        Expanded(flex: 6, child: RepaintBoundary(child: AnimatedBuilder(
                            animation: _hintPulse,
                            builder: (BuildContext context, Widget? child) {
                              final bool canHint =
                                  _hintCount <
                                      AtlasScorePolicy.maxHintsPerQuestion &&
                                  !_answerLocked;
                              final double pulse = canHint
                                  ? _hintPulse.value
                                  : 1;
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
                                  key: const ValueKey<String>(
                                    'atlas_hint_button',
                                  ),
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
                                    size: 19,
                                  ),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _hintCount >=
                                              AtlasScorePolicy
                                                  .maxHintsPerQuestion
                                          ? (_english
                                                ? 'Hints used (${_pointsForCurrentAnswer}p)'
                                                : 'İpuçları bitti (${_pointsForCurrentAnswer}p)')
                                          : (_english
                                                ? 'Hint · $_hintCount/${AtlasScorePolicy.maxHintsPerQuestion} ($_pointsForCurrentAnswer p)'
                                                : 'İpucu Al · $_hintCount/${AtlasScorePolicy.maxHintsPerQuestion} ($_pointsForCurrentAnswer p)'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },),),),
                        const SizedBox(width: 8),
                        // Pas Geç / Atla Butonu (Kullanıcı takıldığında veya ipuçları bittiğinde kurtarıcı)
                        if (!_answerLocked)
                          Expanded(
                            flex: 4,
                            child: OutlinedButton.icon(
                              onPressed: _skipQuestion,
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    _hintCount >=
                                        AtlasScorePolicy.maxHintsPerQuestion
                                    ? const Color(0xFFC46D32)
                                    : const Color(0xFF7C8C85),
                                side: BorderSide(
                                  color:
                                      _hintCount >=
                                          AtlasScorePolicy.maxHintsPerQuestion
                                      ? const Color(0xFFC46D32)
                                            .withValues(alpha: .6)
                                      : const Color(0xFFD0DCD5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                size: 20,
                              ),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _english ? 'Skip' : 'Pas Geç',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _answerController,
                      builder:
                          (
                            BuildContext context,
                            TextEditingValue value,
                            Widget? child,
                          ) {
                            if (_answerLocked) {
                              // Cevap doğru verildiğinde veya pas geçildiğinde aktifleşen ve sonraki soruya geçiren buton
                              return ReferencePrimaryButton(
                                label: _english
                                    ? 'NEXT QUESTION →'
                                    : 'SONRAKİ SORUYA GEÇ →',
                                accent: _answerCorrect
                                    ? const Color(0xFF247455)
                                    : const Color(0xFFC46D32),
                                icon: Icons.arrow_forward_rounded,
                                enabled: true,
                                onPressed: _proceedToNext,
                              );
                            }

                            return ReferencePrimaryButton(
                              label: _english
                                  ? 'CHECK ANSWER'
                                  : 'CEVABI KONTROL ET',
                              accent: _accent,
                              icon: Icons.arrow_forward_rounded,
                              enabled: value.text.trim().isNotEmpty,
                              onPressed: () => unawaited(_submitAnswer()),
                            );
                          },
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
