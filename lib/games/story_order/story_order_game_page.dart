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
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'story_order_scenario.dart';

class StoryOrderGamePage extends StatefulWidget {
  const StoryOrderGamePage({
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

  static final List<ParkurLevelSpec> levels = List<ParkurLevelSpec>.generate(
    GameContentPolicy.nativeStages('story_order'),
    (int index) {
      final int level = index + 1;
      final String difficulty = level <= 3
          ? 'USTALAŞMA'
          : level <= 6
          ? 'ORTA'
          : level <= 10
          ? 'İLERİ'
          : level <= 16
          ? 'UZMAN'
          : 'USTA';
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Dosya ${level.toString().padLeft(2, '0')}',
        titleEn: 'Story ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Olayların doğal başlangıç ve sonucunu bul',
          <= 6 => 'İpuçlarını neden-sonuç zincirine yerleştir',
          <= 10 => 'Beş aşamalı kayıtta ilgisiz notu ele',
          <= 16 => 'Benzer zaman ipuçlarını ve ara kanıtları tart',
          <= 19 => 'Çok adımlı dosyada tek bir tutarlı sıra kur',
          _ => 'Usta finali • her adım kritik, hata hakkı tek',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Find the natural beginning and outcome',
          <= 6 => 'Place clues into a cause-and-effect chain',
          <= 10 => 'Reject the irrelevant note in a five-step record',
          <= 16 => 'Weigh close timing clues and intermediate evidence',
          <= 19 => 'Build one coherent order from a multi-step file',
          _ => 'Master finale • every step matters; one mistake allowed',
        },
        difficulty: difficulty,
        icon: Icons.timeline_rounded,
      );
    },
    growable: false,
  );

  @override
  State<StoryOrderGamePage> createState() => _StoryOrderGamePageState();
}

class _StoryOrderGamePageState extends State<StoryOrderGamePage> {
  static const String _practiceKey = 'story_order_next_practice_round';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  bool _practiceLoading = true;
  int _nextPracticeRound = 1;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPracticeRound());
  }

  Future<void> _loadPracticeRound() async {
    final int stored = await _preferences.getInt(_practiceKey) ?? 1;
    if (!mounted) return;
    setState(() {
      _nextPracticeRound = stored
          .clamp(1, StoryOrderScenario.uniquePracticeRounds)
          .toInt();
      _practiceLoading = false;
    });
  }

  Future<void> _openPractice() async {
    final bool english = context.l10n.isEnglish;
    final int round = _nextPracticeRound;
    final ParkurGameResult? result = await Navigator.of(context)
        .push<ParkurGameResult>(
          MaterialPageRoute<ParkurGameResult>(
            builder: (BuildContext context) => StoryOrderPlayPage(
              level: StoryOrderGamePage
                  .levels[(round - 1) % StoryOrderGamePage.totalCases],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == StoryOrderScenario.uniquePracticeRounds
        ? 1
        : round + 1;
    await _preferences.setInt(_practiceKey, next);
    if (!mounted) return;
    setState(() => _nextPracticeRound = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          english
              ? 'Story solved • next unique file: $next / 300'
              : 'Hikâye çözüldü • sıradaki farklı dosya: $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('story_order');
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'story_order',
      progressPrefix: 'story_order',
      titleTr: 'Hikâye Sırası',
      titleEn: 'Story Order',
      taglineTr: 'İpuçlarını çöz • olayları sırala • tutarlı zinciri kur',
      taglineEn: 'Read the clues • order the events • build a coherent chain',
      accent: skin.accent,
      icon: Icons.timeline_rounded,
      levels: StoryOrderGamePage.levels,
      dailyCourseMode: widget.dailyCourseMode,
      competitionLevel: widget.competitionLevel,
      competitionLayoutCode: widget.competitionLayoutCode,
      hubAction: widget.competitionLevel != null
          ? null
          : OutlinedButton.icon(
              onPressed: _practiceLoading ? null : _openPractice,
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(
                _practiceLoading
                    ? (english ? 'Loading…' : 'Yükleniyor…')
                    : english
                    ? 'UNIQUE FILES • $_nextPracticeRound / 300'
                    : 'FARKLI DOSYA • $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => StoryOrderPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          StoryOrderScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class StoryOrderPlayPage extends StatefulWidget {
  const StoryOrderPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<StoryOrderPlayPage> createState() => _StoryOrderPlayPageState();
}

class _StoryOrderPlayPageState extends State<StoryOrderPlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.language,
  );
  late StudioGameSession _session;
  late StoryOrderScenario _scenario;
  bool _initialized = false;
  bool _failureDialogOpen = false;
  bool _solved = false;
  bool _hintUsed = false;
  final List<String> _picked = <String>[];
  String? _hintedId;
  String? _feedback;

  bool get _english => context.l10n.isEnglish;
  bool get _practice => widget.practiceRound != null;
  int get _mistakeLimit => widget.level.number <= 3
      ? 5
      : widget.level.number <= 6
      ? 4
      : widget.level.number <= 10
      ? 3
      : widget.level.number <= 16
      ? 2
      : 1;
  int get _errorsLeft => math.max(0, _mistakeLimit - _session.mistakes).toInt();

  @override
  void initState() {
    super.initState();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.practiceRound ?? widget.level.number,
    )..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final bool english = context.l10n.isEnglish;
    final int? practiceRound = widget.practiceRound;
    if (practiceRound != null) {
      _scenario = StoryOrderScenario.forPracticeRound(
        practiceRound,
        english: english,
      );
    } else {
      _scenario = (widget.level.poolIndex != null
          ? StoryOrderScenario.forPracticeRound(
              widget.level.contentIndex,
              english: english,
            )
          : StoryOrderScenario.forCampaignLevel(
              widget.level.contentLevel,
              english: english,
            ));
    }
  }

  void _toggleCard(StorySequenceCard card) {
    if (_solved || !_session.acceptsInput) return;
    setState(() {
      if (_picked.contains(card.id)) {
        _picked.remove(card.id);
      } else if (_picked.length < _scenario.requiredEvents) {
        _picked.add(card.id);
      }
      _hintedId = null;
      _feedback = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .12),
    );
  }

  void _checkAnswer() {
    if (_solved ||
        !_session.acceptsInput ||
        _picked.length != _scenario.requiredEvents) {
      return;
    }
    if (_scenario.acceptsSequence(_picked)) {
      _session.recordAccepted(points: 190 + widget.level.number * 22);
      _audio.hapticMedium();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .4));
      setState(() {
        _solved = true;
        _feedback = null;
      });
      return;
    }
    _session.recordMistake();
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .28));
    setState(() {
      _picked.clear();
      _hintedId = null;
      _feedback = _english
          ? 'The chain does not follow the evidence. Reconsider what must happen first. $_errorsLeft ${_errorsLeft == 1 ? 'try' : 'tries'} left.'
          : 'Olay zinciri kanıtlarla uyuşmuyor. Önce ne olması gerektiğini yeniden düşün. $_errorsLeft hak kaldı.';
    });
    if (_errorsLeft == 0 && !_failureDialogOpen) unawaited(_showFailure());
  }

  Future<void> _showFailure() async {
    _failureDialogOpen = true;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_english ? 'File closed' : 'Dosya kapandı'),
        content: Text(
          _english
              ? 'The attempt limit is used. Re-read the evidence and rebuild the timeline.'
              : 'Deneme hakkın doldu. Kanıtları yeniden oku ve olay zincirini baştan kur.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) _resetRound();
            },
            child: Text(_english ? 'TRY AGAIN' : 'YENİDEN DENE'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) {
                Navigator.of(context).pop(
                  const ParkurGameResult(
                    completed: false,
                    stars: 0,
                    score: 0,
                    nextLevel: false,
                  ),
                );
              }
            },
            child: Text(_english ? 'LEVEL MAP' : 'BÖLÜM HARİTASI'),
          ),
        ],
      ),
    );
    _failureDialogOpen = false;
  }

  void _resetRound() {
    setState(() {
      _picked.clear();
      _hintedId = null;
      _feedback = null;
      _solved = false;
      _hintUsed = false;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _useHint() {
    if (_solved ||
        _picked.length >= _scenario.requiredEvents ||
        !_session.useHint(pointCost: 80)) {
      return;
    }
    final String expected = _scenario.expectedIds[_picked.length];
    setState(() {
      _hintUsed = true;
      _hintedId = expected;
      _feedback = _english
          ? 'The next evidence-backed step is highlighted. Place it where it belongs.'
          : 'Kanıta göre sıradaki adım vurgulandı. Onu doğru yerine yerleştir.';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .28));
  }

  Future<void> _finish() async {
    if (_session.phase != StudioGamePhase.playing) return;
    final int stars = !_hintUsed && _session.mistakes == 0
        ? 3
        : _session.mistakes <= 1
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: !_practice && widget.level.number < StoryOrderGamePage.totalCases
          ? StudioResultAction.next
          : StudioResultAction.map,
    );
    unawaited(
      _audioProfile.play(
        _audio,
        GameAudioEvent.levelComplete,
        gain: .42,
        levelNumber: widget.level.number,
      ),
    );
    if (mounted) Navigator.of(context).pop(result.toParkurResult());
  }

  Widget _buildCard(StorySequenceCard card, StudioGameSkin skin) {
    final int order = _picked.indexOf(card.id);
    final bool selected = order >= 0;
    final bool hinted = card.id == _hintedId;
    final Color border = selected
        ? skin.accent
        : hinted
        ? StudioVisuals.amber
        : StudioVisuals.line;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? skin.accentSoft : StudioVisuals.surface,
        borderRadius: StudioVisuals.compactRadius,
        child: InkWell(
          key: ValueKey<String>('story_order_card_${card.id}'),
          borderRadius: StudioVisuals.compactRadius,
          onTap: _solved ? null : () => _toggleCard(card),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: StudioVisuals.compactRadius,
              border: Border.all(
                color: border,
                width: selected || hinted ? 1.7 : 1,
              ),
              boxShadow: selected
                  ? const <BoxShadow>[]
                  : StudioVisuals.softShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? skin.accent
                        : hinted
                        ? StudioVisuals.amberSoft
                        : StudioVisuals.surfaceSoft,
                  ),
                  child: selected
                      ? Text(
                          '${order + 1}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : Icon(
                          card.isDecoy
                              ? Icons.remove_circle_outline_rounded
                              : Icons.drag_handle_rounded,
                          size: 17,
                          color: card.isDecoy
                              ? StudioVisuals.muted
                              : skin.accent,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    card.text,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.ink,
                      fontSize: 12.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected) ...<Widget>[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: StudioVisuals.teal,
                    size: 19,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('story_order');
    final String title = _english ? 'Story Order' : 'Hikâye Sırası';
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            Text(
              _practice
                  ? (_english
                        ? 'PRACTICE • ${widget.practiceRound} / 300'
                        : 'PRATİK • ${widget.practiceRound} / 300')
                  : (_english
                        ? 'STORY • ${widget.level.number} / ${GameContentPolicy.campaignLevels}'
                        : 'HİKÂYE • ${widget.level.number} / ${GameContentPolicy.campaignLevels}'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _english
                            ? 'BUILD THE TIMELINE'
                            : 'ZAMAN ÇİZELGESİNİ KUR',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: skin.accent,
                          fontSize: 12,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StoryStat(
                      icon: Icons.favorite_outline_rounded,
                      label: '$_errorsLeft/$_mistakeLimit',
                      accent: _errorsLeft <= 1
                          ? StudioVisuals.danger
                          : skin.accent,
                    ),
                    const SizedBox(width: 6),
                    _StoryStat(
                      icon: Icons.stars_rounded,
                      label: '${_session.score}',
                      accent: StudioVisuals.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey<String>('story_order_scroll'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                skin.accentSoft,
                                StudioVisuals.surface,
                              ],
                            ),
                            borderRadius: StudioVisuals.cardRadius,
                            border: Border.all(
                              color: skin.accent.withValues(alpha: .18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.folder_copy_outlined,
                                    color: skin.accent,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      _scenario.title,
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        color: StudioVisuals.ink,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  if (_scenario.hasDecoy)
                                    _TagPill(
                                      label: _english ? '1 DECOY' : '1 TUZAK',
                                      color: StudioVisuals.amber,
                                      soft: StudioVisuals.amberSoft,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Text(
                                _scenario.setup,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: StudioVisuals.ink,
                                  fontSize: 12.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _solved
                                    ? (_english
                                          ? 'EVIDENCE-BASED ORDER'
                                          : 'KANITA DAYALI SIRA')
                                    : _english
                                    ? 'TAP EVENTS IN CAUSAL ORDER'
                                    : 'OLAYLARA NEDEN-SONUÇ SIRASIYLA DOKUN',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: StudioVisuals.muted,
                                  fontSize: 11.5,
                                  letterSpacing: .55,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '${_picked.length}/${_scenario.requiredEvents}',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: skin.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        for (final StorySequenceCard card in _scenario.cards)
                          _buildCard(card, skin),
                        if (_feedback != null) ...<Widget>[
                          const SizedBox(height: 2),
                          _FeedbackNote(text: _feedback!, positive: false),
                        ],
                        if (_solved) ...<Widget>[
                          const SizedBox(height: 4),
                          _FeedbackNote(
                            text: _scenario.explanation,
                            positive: true,
                            key: const ValueKey<String>(
                              'story_order_explanation',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _english
                                ? 'Every step is placed from trigger to verified outcome.'
                                : 'Her adım, başlangıç nedeninden doğrulanmış sonuca yerleştirildi.',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: StudioVisuals.muted,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (!_solved)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _picked.length >= _scenario.requiredEvents
                              ? null
                              : _useHint,
                          icon: const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _english ? 'HINT  −80' : 'İPUCU  −80',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: StudioVisuals.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            textStyle: const TextStyle(fontSize: 10),
                            side: const BorderSide(color: StudioVisuals.line),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          key: const ValueKey<String>('story_order_submit'),
                          onPressed: _picked.length == _scenario.requiredEvents
                              ? _checkAnswer
                              : null,
                          icon: const Icon(Icons.fact_check_rounded),
                          label: Text(
                            _english ? 'CHECK ORDER' : 'SIRAYI KONTROL ET',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: skin.accent,
                            disabledBackgroundColor: StudioVisuals.line,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey<String>('story_order_continue'),
                      onPressed: _finish,
                      icon: const Icon(Icons.celebration_rounded),
                      label: Text(
                        _english ? 'COMPLETE FILE' : 'DOSYAYI TAMAMLA',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 50),
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.white,
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

class _StoryStat extends StatelessWidget {
  const _StoryStat({
    required this.icon,
    required this.label,
    required this.accent,
  });
  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 61, minHeight: 30),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: StudioVisuals.line),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 15, color: accent),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: StudioVisuals.ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.color,
    required this.soft,
  });
  final String label;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: soft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'Roboto',
        color: color,
        fontSize: 10,
        letterSpacing: .4,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _FeedbackNote extends StatelessWidget {
  const _FeedbackNote({super.key, required this.text, required this.positive});
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final Color accent = positive ? StudioVisuals.teal : StudioVisuals.danger;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: positive ? StudioVisuals.tealSoft : const Color(0xFFFFEEEE),
        borderRadius: StudioVisuals.compactRadius,
        border: Border.all(color: accent.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            positive
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontSize: 11.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
