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
import 'meaning_match_scenario.dart';

class MeaningMatchGamePage extends StatefulWidget {
  const MeaningMatchGamePage({
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
    GameContentPolicy.nativeStages('meaning_match'),
    (int index) {
      final int level = index + 1;
      final String difficulty = level <= 6
          ? 'USTALAŞMA'
          : level <= 10
          ? 'İLERİ'
          : level <= 15
          ? 'UZMAN'
          : 'USTA';
      return ParkurLevelSpec(
        number: level,
        titleTr: 'Anlam Kümesi ${level.toString().padLeft(2, '0')}',
        titleEn: 'Meaning Set ${level.toString().padLeft(2, '0')}',
        subtitleTr: switch (level) {
          <= 3 => 'Açık kavram gruplarını bul',
          <= 6 => 'Benzer sözcükleri ayırt et',
          <= 10 => 'Alan bilgisini kullan; yanıltıcıları ele',
          <= 15 => 'Soyut ve uzmanlık bağlarını çöz',
          <= 19 => 'Dört ileri kavram kümesini çıkar',
          _ => 'Usta finali • dört teknik alanı bağla',
        },
        subtitleEn: switch (level) {
          <= 3 => 'Find the clear concept groups',
          <= 6 => 'Separate closely related words',
          <= 10 => 'Use domain knowledge; eliminate decoys',
          <= 15 => 'Resolve abstract and specialist links',
          <= 19 => 'Infer four advanced concept groups',
          _ => 'Expert finale • connect four technical fields',
        },
        difficulty: difficulty,
        icon: Icons.hub_rounded,
      );
    },
    growable: false,
  );

  @override
  State<MeaningMatchGamePage> createState() => _MeaningMatchGamePageState();
}

class _MeaningMatchGamePageState extends State<MeaningMatchGamePage> {
  static const String _practiceKey = 'meaning_match_next_practice_round';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  int _nextPracticeRound = 1;
  bool _practiceRoundLoading = true;

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
          .clamp(1, MeaningMatchScenario.uniquePracticeRounds)
          .toInt();
      _practiceRoundLoading = false;
    });
  }

  Future<void> _openPractice() async {
    final bool english = context.l10n.isEnglish;
    final int round = _nextPracticeRound;
    final ParkurGameResult? result = await Navigator.of(context)
        .push<ParkurGameResult>(
          MaterialPageRoute<ParkurGameResult>(
            builder: (BuildContext context) => MeaningMatchPlayPage(
              level: ParkurLevelSpec(
                number: ((round - 1) % MeaningMatchScenario.campaignLevels) + 1,
                titleTr: 'Serbest Pratik',
                titleEn: 'Open Practice',
                subtitleTr: 'Yeni bir kavram ağı',
                subtitleEn: 'A fresh semantic board',
                difficulty: 'PRATİK',
                icon: Icons.explore_outlined,
              ),
              previousBestScore: 0,
              practiceRound: round,
            ),
          ),
        );
    if (!mounted || result?.completed != true) return;

    final int next = round == MeaningMatchScenario.uniquePracticeRounds
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
              ? 'Board cleared • next unique practice: $next / 300'
              : 'Tahta çözüldü • sıradaki farklı pratik: $next / 300',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('meaning_match');
    return ParkurLevelHub(
      gameId: 'meaning_match',
      progressPrefix: 'meaning_match',
      titleTr: 'Anlam Eşleştir',
      titleEn: 'Meaning Match',
      taglineTr: '16 sözcük • 4 gizli anlam kümesi',
      taglineEn: '16 words • 4 hidden semantic groups',
      accent: skin.accent,
      icon: Icons.hub_rounded,
      levels: MeaningMatchGamePage._levels,
      dailyCourseMode: widget.dailyCourseMode,
      competitionLevel: widget.competitionLevel,
      competitionLayoutCode: widget.competitionLayoutCode,
      hubAction: widget.competitionLevel != null
          ? null
          : OutlinedButton.icon(
              onPressed: _practiceRoundLoading ? null : _openPractice,
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(
                _practiceRoundLoading
                    ? (context.l10n.isEnglish ? 'Loading…' : 'Yükleniyor…')
                    : context.l10n.isEnglish
                    ? 'UNIQUE PRACTICE  •  $_nextPracticeRound / 300'
                    : 'FARKLI PRATİK  •  $_nextPracticeRound / 300',
              ),
            ),
      playBuilder:
          (
            BuildContext context,
            ParkurLevelSpec level,
            int previousBestScore,
            int? competitionLayoutCode,
            bool competitionMode,
          ) => MeaningMatchPlayPage(
            level: level,
            previousBestScore: previousBestScore,
            practiceRound: competitionMode && competitionLayoutCode != null
                ? (competitionLayoutCode.abs() %
                          MeaningMatchScenario.uniquePracticeRounds) +
                      1
                : null,
          ),
    );
  }
}

class MeaningMatchPlayPage extends StatefulWidget {
  const MeaningMatchPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
    this.practiceRound,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;
  final int? practiceRound;

  @override
  State<MeaningMatchPlayPage> createState() => _MeaningMatchPlayPageState();
}

class _MeaningMatchPlayPageState extends State<MeaningMatchPlayPage> {
  static const List<Color> _groupColors = <Color>[
    Color(0xFF3F7D78),
    Color(0xFF5577AB),
    Color(0xFFB4774B),
    Color(0xFF8A68A5),
  ];

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.language,
  );
  final Set<String> _solvedCategories = <String>{};
  final Set<int> _selectedTiles = <int>{};

  late StudioGameSession _session;
  late MeaningMatchScenario _scenario;
  String? _message;
  String? _revealedHint;
  int _hints = 0;
  bool _initialized = false;
  bool _failureDialogOpen = false;

  int get _mistakeLimit => widget.level.number <= 3
      ? 5
      : widget.level.number <= 6
      ? 4
      : 3;

  bool get _completed =>
      _solvedCategories.length == _scenario.categories.length;

  @override
  void initState() {
    super.initState();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.practiceRound ?? widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final bool english = context.l10n.isEnglish;
    _scenario = widget.practiceRound == null
        ? (widget.level.poolIndex != null
              ? MeaningMatchScenario.forPracticeRound(
                  widget.level.contentIndex,
                  languageCode: english ? 'en' : 'tr',
                )
              : MeaningMatchScenario.forCampaignLevel(
                  widget.level.contentLevel,
                  languageCode: english ? 'en' : 'tr',
                ))
        : MeaningMatchScenario.forPracticeRound(
            widget.practiceRound!,
            languageCode: english ? 'en' : 'tr',
          );
    _languageIsEnglish = english;
  }

  bool _languageIsEnglish = false;

  int get _targetGroupSize => _scenario.wordsPerCategory;

  void _toggleTile(int index) {
    if (_completed || _session.phase != StudioGamePhase.playing) return;
    final MeaningTile tile = _scenario.tiles[index];
    if (_solvedCategories.contains(tile.categoryId)) return;
    setState(() {
      if (!_selectedTiles.add(index)) {
        _selectedTiles.remove(index);
      } else if (_selectedTiles.length > _targetGroupSize) {
        _selectedTiles.remove(_selectedTiles.first);
      }
      _message = null;
    });
    _audio.hapticSelection();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .2),
    );
  }

  void _checkGroup() {
    if (_selectedTiles.length != _targetGroupSize || _completed) return;
    final List<MeaningTile> selected = _selectedTiles
        .map((int index) => _scenario.tiles[index])
        .toList(growable: false);
    final Set<String> groupIds = selected
        .map((MeaningTile tile) => tile.categoryId)
        .toSet();
    if (groupIds.length != 1 || _solvedCategories.contains(groupIds.first)) {
      _wrongGroup();
      return;
    }

    final MeaningCategory category = _scenario.categories.firstWhere(
      (MeaningCategory item) => item.id == groupIds.first,
    );
    setState(() {
      _solvedCategories.add(category.id);
      _selectedTiles.clear();
      _message =
          '${category.title(_languageIsEnglish)} · ${category.clue(_languageIsEnglish)}';
      if (_revealedHint == category.id) _revealedHint = null;
    });
    _audio.hapticMedium();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.accepted, gain: .48));
    _session.recordAccepted(points: 260);

    if (_completed) {
      unawaited(_finish());
    }
  }

  void _wrongGroup() {
    _selectedTiles.clear();
    _session.recordMistake();
    _audio.hapticLight();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.rejected, gain: .34));
    final int left = math.max(0, _mistakeLimit - _session.mistakes).toInt();
    setState(() {
      _message = _languageIsEnglish
          ? 'Those $_targetGroupSize do not share one exact group. $left ${left == 1 ? 'mistake' : 'mistakes'} left.'
          : 'Bu $_targetGroupSize sözcük tek bir kümeye ait değil. $left hata hakkı kaldı.';
    });
    if (left == 0 && !_failureDialogOpen) {
      unawaited(_showFailure());
    }
  }

  Future<void> _showFailure() async {
    _failureDialogOpen = true;
    _session.fail();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(_languageIsEnglish ? 'Board locked' : 'Tahta kilitlendi'),
        content: Text(
          _languageIsEnglish
              ? 'The mistake budget is used. Re-read the relationships and try this board again.'
              : 'Hata hakkın doldu. İlişkileri yeniden inceleyip bu tahtayı tekrar deneyebilirsin.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (mounted) _resetBoard();
            },
            child: Text(_languageIsEnglish ? 'TRY AGAIN' : 'YENİDEN DENE'),
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
            child: Text(_languageIsEnglish ? 'LEVEL MAP' : 'BÖLÜM HARİTASI'),
          ),
        ],
      ),
    );
    _failureDialogOpen = false;
  }

  void _resetBoard() {
    setState(() {
      _solvedCategories.clear();
      _selectedTiles.clear();
      _hints = 0;
      _revealedHint = null;
      _message = null;
      _session = StudioGameSession(
        level: widget.level.number,
        seed: widget.practiceRound ?? widget.level.number,
      )..start();
    });
  }

  void _useHint() {
    if (_completed || _session.phase != StudioGamePhase.playing) return;
    final Iterable<MeaningCategory> unresolved = _scenario.categories.where(
      (MeaningCategory category) => !_solvedCategories.contains(category.id),
    );
    final MeaningCategory category = unresolved.firstWhere(
      (MeaningCategory item) => item.id == _revealedHint,
      orElse: () => unresolved.first,
    );
    if (!_session.useHint(pointCost: 140)) return;
    setState(() {
      _hints++;
      _revealedHint = category.id;
      _message = _languageIsEnglish
          ? 'Clue: ${category.clue(true)}'
          : 'İpucu: ${category.clue(false)}';
      _selectedTiles.clear();
    });
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .3));
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
          widget.practiceRound == null &&
              widget.level.number < MeaningMatchGamePage.totalCases
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

  Color _tileColor(MeaningTile tile, bool selected, StudioGameSkin skin) {
    if (selected) {
      // Renklerin kategori hakkında ipucu vermemesi için nötr tema rengi kullanılır.
      return skin.accent.withValues(alpha: .14);
    }
    return StudioVisuals.surface;
  }

  void _showHowToPlay(bool english) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final StudioGameSkin skin = StudioGameSkin.forId('meaning_match');
        return Container(
          decoration: const BoxDecoration(
            color: StudioVisuals.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: skin.accent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    english ? 'How to Play?' : 'Nasıl Oynanır?',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: StudioVisuals.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                english
                    ? '• Group the 16 words into four exact 4-word connection categories.\n'
                      '• Select 4 related words and tap "LOCK GROUP" to confirm.\n'
                      '• Be mindful of crossover words that could fit multiple categories.\n'
                      '• Solve all four groups without exhausting your mistake limit!'
                    : '• 16 sözcüğü birbiriyle bağlantılı dörderli 4 gruba ayır.\n'
                      '• Ortak bir bağı olan 4 sözcüğü seç ve "KÜMEYİ KİLİTLE" butonuna bas.\n'
                      '• Birden fazla kategoriye uyabilecek kelimelere dikkat et.\n'
                      '• Hata hakkın bitmeden 4 kümenin tamamını çözerek seviyeyi tamamla!',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  height: 1.5,
                  color: StudioVisuals.ink,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: skin.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    english ? 'GOT IT' : 'ANLADIM',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool english = _languageIsEnglish;
    final StudioGameSkin skin = StudioGameSkin.forId('meaning_match');
    final int errorsLeft = math
        .max(0, _mistakeLimit - _session.mistakes)
        .toInt();

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
              context.l10n.gameTitle('meaning_match'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              widget.practiceRound == null
                  ? (english
                        ? 'LEVEL ${widget.level.number} / ${GameContentPolicy.campaignLevels}'
                        : 'BÖLÜM ${widget.level.number} / ${GameContentPolicy.campaignLevels}')
                  : (english
                        ? 'PRACTICE  •  ${widget.practiceRound} / 300'
                        : 'PRATİK  •  ${widget.practiceRound} / 300'),
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: english ? 'How to play' : 'Nasıl Oynanır?',
            onPressed: () => _showHowToPlay(english),
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 620,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: <Widget>[
                // Kompakt durum çubuğu (38px)
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StudioVisuals.line),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '${english ? 'Groups' : 'Küme'}: ${_solvedCategories.length}/${_scenario.categories.length}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: StudioVisuals.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${english ? 'Selected' : 'Seçili'}: ${_selectedTiles.length}/$_targetGroupSize',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: skin.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ❤️ $errorsLeft/$_mistakeLimit',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: errorsLeft <= 1 ? StudioVisuals.danger : skin.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          height: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _scenario.categories.isEmpty
                                  ? 0
                                  : _solvedCategories.length /
                                      _scenario.categories.length,
                              minHeight: 6,
                              color: skin.accent,
                              backgroundColor: skin.accentSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Sözcük Izgarası (Bölüm 1-3: 3x3, Bölüm 4+: 4x4, Expanded ile Kaydırmasız)
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final int columns = _scenario.categories.length;
                      final int rows = (_scenario.tiles.length / columns).ceil();
                      final double cellHeight = math
                          .max(42.0, (constraints.maxHeight - 20) / rows)
                          .toDouble();
                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _scenario.tiles.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          mainAxisExtent: cellHeight,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final MeaningTile tile = _scenario.tiles[index];
                          final bool selected = _selectedTiles.contains(index);
                          final bool solved = _solvedCategories.contains(tile.categoryId);
                          final int categoryIndex = _scenario.categories.indexWhere(
                            (MeaningCategory category) => category.id == tile.categoryId,
                          );
                          final Color categoryColor =
                              _groupColors[categoryIndex % _groupColors.length];
                          // Seçimde renklerin ipucu vermemesi için nötr tema rengi kullanılır.
                          final Color borderAccent = selected
                              ? skin.accent.withValues(alpha: .75)
                              : (solved
                                  ? categoryColor.withValues(alpha: .55)
                                  : StudioVisuals.line);
                          final Color textColor = selected
                              ? skin.accent
                              : (solved
                                  ? categoryColor
                                  : StudioVisuals.ink);
                          return Semantics(
                            button: !solved,
                            selected: selected,
                            label: tile.word,
                            child: Material(
                              color: _tileColor(tile, selected, skin),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: solved ? null : () => _toggleTile(index),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: borderAccent,
                                      width: selected ? 1.5 : 1,
                                    ),
                                    boxShadow: selected || solved
                                        ? const <BoxShadow>[]
                                        : StudioVisuals.softShadow,
                                  ),
                                  child: Center(
                                    child: solved
                                        ? Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                            color: categoryColor.withValues(alpha: .65),
                                          )
                                        : Text(
                                            tile.word,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Roboto',
                                              color: textColor,
                                              fontSize: 11,
                                              height: 1.08,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),

                // Çözülen Kümeler
                _SolvedGroups(
                  scenario: _scenario,
                  solved: _solvedCategories,
                  hintedCategory: _revealedHint,
                  colors: _groupColors,
                  english: english,
                ),
                if (_message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _message!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: StudioVisuals.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 6),

                // Alt Butonlar (42px)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _completed ? null : _useHint,
                        icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            english ? 'CLUE' : 'İPUCU',
                            maxLines: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: skin.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                          side: BorderSide(color: skin.accent.withValues(alpha: .4)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _selectedTiles.length == _targetGroupSize && !_completed ? _checkGroup : null,
                        icon: const Icon(Icons.fact_check_outlined, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(english ? 'LOCK GROUP' : 'KÜMEYİ KİLİTLE'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: skin.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _SolvedGroups extends StatelessWidget {
  const _SolvedGroups({
    required this.scenario,
    required this.solved,
    required this.hintedCategory,
    required this.colors,
    required this.english,
  });

  final MeaningMatchScenario scenario;
  final Set<String> solved;
  final String? hintedCategory;
  final List<Color> colors;
  final bool english;

  @override
  Widget build(BuildContext context) {
    final int count = scenario.categories.length;
    return Row(
      children: List<Widget>.generate(count, (int index) {
        final MeaningCategory category = scenario.categories[index];
        final bool isSolved = solved.contains(category.id);
        final bool isHinted = hintedCategory == category.id;
        final Color accent = colors[index % colors.length];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == count - 1 ? 0 : 5),
            child: Container(
              height: 38,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSolved || isHinted
                    ? accent.withValues(alpha: .10)
                    : StudioVisuals.surfaceSoft,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isSolved || isHinted
                      ? accent.withValues(alpha: .28)
                      : StudioVisuals.line,
                ),
              ),
              child: Text(
                isSolved
                    ? category.title(english)
                    : '${index + 1}  •  ${isHinted ? '…' : '—'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: isSolved || isHinted ? accent : StudioVisuals.muted,
                  fontSize: 10,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
