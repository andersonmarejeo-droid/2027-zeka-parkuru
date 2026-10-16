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
import 'language_detective_scenario.dart';

class LanguageDetectiveGamePage extends StatefulWidget {
  const LanguageDetectiveGamePage({
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
    GameContentPolicy.nativeStages('language_detective'),
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
        titleEn: 'Case ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Metindeki açık kanıtı ayıkla',
          <= 6 => 'Niyet, koşul ve kaynak sınırını tanı',
          <= 10 => 'Örneklem ve nedensellik iddialarını sına',
          <= 16 => 'İddia, kanıt ve belirsizliği ayrı değerlendir',
          <= 19 => 'Yöntem yanlılığını ve taban oranını çöz',
          _ => 'Usta finali • dört delil, tek savunulabilir sonuç',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Separate explicit evidence from opinion',
          <= 6 => 'Read intent, conditions and source limits',
          <= 10 => 'Test sample and causality claims',
          <= 16 => 'Separate claim, evidence and uncertainty',
          <= 19 => 'Spot method bias and base-rate traps',
          _ => 'Master finale • four exhibits, one supported finding',
        },
        difficulty: difficulty,
        icon: Icons.manage_search_rounded,
      );
    },
    growable: false,
  );

  @override
  State<LanguageDetectiveGamePage> createState() =>
      _LanguageDetectiveGamePageState();
}

class _LanguageDetectiveGamePageState extends State<LanguageDetectiveGamePage> {
  static const String _practiceKey = 'language_detective_next_practice_round';
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
          .clamp(1, LanguageDetectiveScenario.uniquePracticeRounds)
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
            builder: (BuildContext context) => LanguageDetectivePlayPage(
              level: LanguageDetectiveGamePage
                  ._levels[(round - 1) % LanguageDetectiveGamePage.totalCases],
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;
    final int next = round == LanguageDetectiveScenario.uniquePracticeRounds
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
              ? 'Case closed • next unique evidence set: $next / 300'
              : 'Dosya kapandı • sıradaki farklı delil seti: $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('language_detective');
    final bool english = context.l10n.isEnglish;
    return ParkurLevelHub(
      gameId: 'language_detective',
      progressPrefix: 'language_detective',
      titleTr: 'Dil Dedektifi',
      titleEn: 'Language Detective',
      taglineTr: 'İddiayı ayır • kanıtı bul • ölçülü sonuç çıkar',
      taglineEn: 'Separate the claim • locate evidence • infer carefully',
      accent: skin.accent,
      icon: Icons.manage_search_rounded,
      levels: LanguageDetectiveGamePage._levels,
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
                    ? 'UNIQUE FILES  •  $_nextPracticeRound / 300'
                    : 'FARKLI DOSYA  •  $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => LanguageDetectivePlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          LanguageDetectiveScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class LanguageDetectivePlayPage extends StatefulWidget {
  const LanguageDetectivePlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<LanguageDetectivePlayPage> createState() =>
      _LanguageDetectivePlayPageState();
}

class _LanguageDetectivePlayPageState extends State<LanguageDetectivePlayPage> {
  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.language,
  );

  late StudioGameSession _session;
  late LanguageDetectiveScenario _scenario;
  bool _initialized = false;
  bool _failureDialogOpen = false;
  bool _solved = false;
  int _caseIndex = 0;
  int? _selectedOption;
  int _hints = 0;
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
  DetectiveBoardCase get _boardCase => _scenario.cases[_caseIndex];
  DetectiveCase get _caseFile => _boardCase.caseFile;

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
    _scenario = _practice
        ? LanguageDetectiveScenario.forPracticeRound(
            widget.practiceRound!,
            english: _english,
          )
        : (widget.level.poolIndex != null
              ? LanguageDetectiveScenario.forPracticeRound(
                  widget.level.contentIndex,
                  english: _english,
                )
              : LanguageDetectiveScenario.forCampaignLevel(
                  widget.level.contentLevel,
                  english: _english,
                ));
  }

  void _selectOption(int index) {
    if (_solved || !_session.acceptsInput) return;
    setState(() {
      _selectedOption = index;
      _feedback = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .14),
    );
  }

  void _checkAnswer() {
    final int? selected = _selectedOption;
    if (selected == null || _solved || !_session.acceptsInput) return;
    if (selected != _boardCase.correctOptionIndex) {
      _session.recordMistake();
      _audio.hapticLight();
      unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .28));
      setState(() {
        _feedback = _english
            ? 'That conclusion is not fully supported by the file. Re-read the evidence. $_errorsLeft ${_errorsLeft == 1 ? 'try' : 'tries'} left.'
            : 'Bu sonuç dosyadaki kanıtla tam desteklenmiyor. Delili yeniden oku. $_errorsLeft hak kaldı.';
        _selectedOption = null;
      });
      if (_errorsLeft == 0 && !_failureDialogOpen) unawaited(_showFailure());
      return;
    }

    _session.recordAccepted(points: 210 + widget.level.number * 18);
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .4));
    setState(() {
      _solved = true;
      _feedback = null;
      _selectedOption = selected;
    });
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
              ? 'The attempt limit is used. Compare each conclusion with the exact evidence and retry.'
              : 'Deneme hakkın doldu. Her sonucu metindeki açık kanıtla karşılaştırıp yeniden deneyebilirsin.',
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
      _caseIndex = 0;
      _solved = false;
      _selectedOption = null;
      _hints = 0;
      _feedback = null;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _useEvidenceHint() {
    if (_solved || !_session.useHint(pointCost: 100)) return;
    setState(() {
      _hints++;
      _feedback = _english
          ? 'Evidence lead: ${_caseFile.evidenceEn}'
          : 'Delil ipucu: ${_caseFile.evidenceTr}';
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .28));
  }

  void _continue() {
    if (!_solved) return;
    if (_caseIndex == _scenario.cases.length - 1) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _caseIndex++;
      _solved = false;
      _selectedOption = null;
      _feedback = null;
    });
  }

  Future<void> _finish() async {
    if (_session.phase != StudioGamePhase.playing) return;
    final int stars = _hints == 0 && _session.mistakes == 0
        ? 3
        : _hints <= 1 && _session.mistakes <= 2
        ? 2
        : 1;
    final StudioGameResult result = _session.complete(
      stars: stars,
      action:
          !_practice &&
              widget.level.number < LanguageDetectiveGamePage.totalCases
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

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('language_detective');
    final int total = _scenario.cases.length;
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.gameTitle('language_detective'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              _practice
                  ? (_english
                        ? 'PRACTICE  •  ${widget.practiceRound} / 300'
                        : 'PRATİK  •  ${widget.practiceRound} / 300')
                  : (_english
                        ? 'CASE  •  ${widget.level.number} / ${GameContentPolicy.campaignLevels}'
                        : 'DOSYA  •  ${widget.level.number} / ${GameContentPolicy.campaignLevels}'),
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
            padding: const EdgeInsets.fromLTRB(14, 3, 14, 8),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _english
                            ? 'Use only what the source supports. Separate evidence from inference.'
                            : 'Yalnızca kaynağın desteklediği sonuca var. Kanıtla çıkarımı ayır.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: StudioVisuals.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _DetectiveStat(
                      icon: Icons.favorite_outline_rounded,
                      label: '$_errorsLeft/$_mistakeLimit',
                      accent: _errorsLeft <= 1
                          ? StudioVisuals.danger
                          : skin.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: (_caseIndex + (_solved ? 1 : 0)) / total,
                    minHeight: 5,
                    color: skin.accent,
                    backgroundColor: skin.accentSoft,
                  ),
                ),
                const SizedBox(height: 7),
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints limits) =>
                        SingleChildScrollView(
                          key: const ValueKey<String>(
                            'language_detective_scroll',
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: limits.maxHeight,
                            ),
                            child: Column(
                              children: <Widget>[
                                _EvidenceFile(
                                  boardCase: _boardCase,
                                  english: _english,
                                  caseNumber: _caseIndex + 1,
                                  totalCases: total,
                                  accent: skin.accent,
                                ),
                                const SizedBox(height: 8),
                                _DetectiveQuestion(
                                  boardCase: _boardCase,
                                  english: _english,
                                  selectedOption: _selectedOption,
                                  solved: _solved,
                                  accent: skin.accent,
                                  onSelect: _selectOption,
                                ),
                                if (_feedback != null) ...<Widget>[
                                  const SizedBox(height: 7),
                                  _DetectiveFeedback(message: _feedback!),
                                ],
                                if (_solved) ...<Widget>[
                                  const SizedBox(height: 7),
                                  _DetectiveExplanation(
                                    boardCase: _boardCase,
                                    english: _english,
                                    accent: skin.accent,
                                  ),
                                ],
                                const SizedBox(height: 9),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      flex: 2,
                                      child: OutlinedButton.icon(
                                        key: const ValueKey<String>(
                                          'language_detective_hint',
                                        ),
                                        onPressed: _solved
                                            ? null
                                            : _useEvidenceHint,
                                        icon: const Icon(
                                          Icons.search_rounded,
                                          size: 17,
                                        ),
                                        label: Text(
                                          _english
                                              ? 'FIND CLUE'
                                              : 'DELİL İPUCU',
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: skin.accent,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                          ),
                                          minimumSize: const Size.fromHeight(
                                            46,
                                          ),
                                          textStyle: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: FilledButton.icon(
                                        key: const ValueKey<String>(
                                          'language_detective_submit',
                                        ),
                                        onPressed: _solved
                                            ? _continue
                                            : _selectedOption == null
                                            ? null
                                            : _checkAnswer,
                                        icon: Icon(
                                          _solved
                                              ? Icons.arrow_forward_rounded
                                              : Icons.fact_check_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _solved
                                              ? _caseIndex == total - 1
                                                    ? (_english
                                                          ? 'CLOSE FILE'
                                                          : 'DOSYAYI KAPAT')
                                                    : (_english
                                                          ? 'NEXT EXHIBIT'
                                                          : 'SONRAKİ DELİL')
                                              : (_english
                                                    ? 'CHECK FINDING'
                                                    : 'SONUCU KONTROL ET'),
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: skin.accent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: const Size.fromHeight(
                                            46,
                                          ),
                                          textStyle: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
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

class _EvidenceFile extends StatelessWidget {
  const _EvidenceFile({
    required this.boardCase,
    required this.english,
    required this.caseNumber,
    required this.totalCases,
    required this.accent,
  });

  final DetectiveBoardCase boardCase;
  final bool english;
  final int caseNumber;
  final int totalCases;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final DetectiveCase item = boardCase.caseFile;
    return Container(
      key: const ValueKey<String>('language_detective_evidence'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE0E7E9)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080F2931),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  english ? 'EVIDENCE FILE' : 'DELİL DOSYASI',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .65,
                  ),
                ),
              ),
              Text(
                '${caseNumber.toString().padLeft(2, '0')} / ${totalCases.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            english ? item.sourceEn : item.sourceTr,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F7),
              borderRadius: BorderRadius.circular(11),
              border: const Border(
                left: BorderSide(color: Color(0xFFB7C7C2), width: 3),
              ),
            ),
            child: Text(
              english ? item.passageEn : item.passageTr,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.ink,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectiveQuestion extends StatelessWidget {
  const _DetectiveQuestion({
    required this.boardCase,
    required this.english,
    required this.selectedOption,
    required this.solved,
    required this.accent,
    required this.onSelect,
  });

  final DetectiveBoardCase boardCase;
  final bool english;
  final int? selectedOption;
  final bool solved;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final DetectiveCase item = boardCase.caseFile;
    final List<String> sourceOptions = english
        ? item.optionsEn
        : item.optionsTr;
    final List<String> options = boardCase.optionOrder
        .map((int index) => sourceOptions[index])
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            english ? item.questionEn : item.questionTr,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontSize: 14,
              height: 1.24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 7),
        for (int index = 0; index < options.length; index++) ...<Widget>[
          _DetectiveOption(
            key: ValueKey<String>('language_detective_option_$index'),
            label: options[index],
            selected: selectedOption == index,
            disabled: solved,
            index: index,
            accent: accent,
            onTap: () => onSelect(index),
          ),
          if (index < options.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _DetectiveOption extends StatelessWidget {
  const _DetectiveOption({
    super.key,
    required this.label,
    required this.selected,
    required this.disabled,
    required this.index,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final int index;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color letters = selected ? accent : StudioVisuals.muted;
    return Material(
      color: selected ? accent.withValues(alpha: .085) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : const Color(0xFFE0E7E9),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 25,
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? accent : const Color(0xFFF2F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: selected ? Colors.white : letters,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.ink,
                    fontSize: 11,
                    height: 1.22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectiveExplanation extends StatelessWidget {
  const _DetectiveExplanation({
    required this.boardCase,
    required this.english,
    required this.accent,
  });

  final DetectiveBoardCase boardCase;
  final bool english;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final DetectiveCase item = boardCase.caseFile;
    return Container(
      key: const ValueKey<String>('language_detective_explanation'),
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3ED),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFBBD7C4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.verified_outlined, color: accent, size: 17),
              const SizedBox(width: 6),
              Text(
                english ? 'FINDING SUPPORTED' : 'KANITLI SONUÇ',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            english ? item.explanationEn : item.explanationTr,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: StudioVisuals.ink,
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${english ? 'Evidence' : 'Kanıt'}: ${english ? item.evidenceEn : item.evidenceTr}',
            style: TextStyle(
              fontFamily: 'Roboto',
              color: accent,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectiveFeedback extends StatelessWidget {
  const _DetectiveFeedback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('language_detective_feedback'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: Color(0xFF8A5225),
          fontSize: 12,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetectiveStat extends StatelessWidget {
  const _DetectiveStat({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: accent, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
