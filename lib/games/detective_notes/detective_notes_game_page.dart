import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/studio_game_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/game_audio_service.dart';
import '../../theme/studio_visuals.dart';
import '../shared/game_audio_profile.dart';
import '../shared/parkur_game_kit.dart';
import '../shared/studio_game_contracts.dart';
import '../shared/studio_game_session.dart';
import '../shared/studio_game_skin.dart';
import 'detective_notes_puzzle.dart';

class DetectiveNotesGamePage extends StatelessWidget {
  const DetectiveNotesGamePage({
    super.key,
    this.dailyCourseMode = false,
    this.competitionLevel,
    this.competitionLayoutCode,
  });

  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;
  static const int totalStars = GameContentPolicy.minimumUniqueRounds * 3;
  static const int totalCases = GameContentPolicy.campaignLevels;

  static final List<ParkurLevelSpec> _levels = List<ParkurLevelSpec>.generate(
    GameContentPolicy.minimumUniqueRounds,
    (int index) => ParkurLevelSpec(
      number: index + 1,
      titleTr: 'Dosya ${(index + 1).toString().padLeft(3, '0')}',
      titleEn: 'Case ${(index + 1).toString().padLeft(3, '0')}',
      subtitleTr: 'İpuçlarını birleştir ve vakayı çöz',
      subtitleEn: 'Connect the clues and solve the case',
      difficulty: index < 50
          ? 'GÖZLEMCİ'
          : index < 180
          ? 'DEDEKTİF'
          : 'BAŞDEDEKTİF',
      icon: Icons.manage_search_rounded,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final StudioGameSkin skin = StudioGameSkin.forId('detective_notes');
    return ParkurLevelHub(
      gameId: 'detective_notes',
      progressPrefix: 'detective_notes',
      titleTr: 'Dedektif Notları',
      titleEn: 'Detective Notes',
      taglineTr: 'İpuçlarını birleştir, vakayı çöz',
      taglineEn: 'Connect the clues and solve the case',
      accent: skin.accent,
      icon: Icons.manage_search_rounded,
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
          ) => DetectiveNotesPlayPage(
            level: level,
            previousBestScore: previousBestScore,
          ),
    );
  }
}

class DetectiveNotesPlayPage extends StatefulWidget {
  const DetectiveNotesPlayPage({
    super.key,
    required this.level,
    required this.previousBestScore,
  });

  final ParkurLevelSpec level;
  final int previousBestScore;

  @override
  State<DetectiveNotesPlayPage> createState() => _DetectiveNotesPlayPageState();
}

class _DetectiveNotesPlayPageState extends State<DetectiveNotesPlayPage> {
  static const Color _ink = StudioVisuals.ink;
  static const Color _paper = Color(0xFFF5F3ED);
  static const Color _brass = Color(0xFFB28A4C);

  final GameAudioService _audio = GameAudioService.instance;
  final GameAudioProfile _audioProfile = GameAudioProfile.forClass(
    StudioGameClass.logic,
  );
  late final DetectiveNotesPuzzle _puzzle;
  late final StudioGameSession _session;
  late List<List<DetectiveMark>> _relicMarks;
  late List<List<DetectiveMark>> _roomMarks;
  late List<List<DetectiveMark>> _seatMarks;
  bool _english = false;
  int _category = 0;
  bool _finished = false;
  int _moves = 0;
  int _hints = 0;

  List<List<DetectiveMark>> get _activeMarks => switch (_category) {
    0 => _relicMarks,
    1 => _roomMarks,
    _ => _seatMarks,
  };

  @override
  void initState() {
    super.initState();
    _puzzle = DetectiveNotesPuzzle.forLevel(
      widget.level.contentIndex,
      progressive: widget.level.poolIndex != null,
    );
    _relicMarks = _emptyGrid();
    _roomMarks = _emptyGrid();
    _seatMarks = _emptyGrid();
    _session = StudioGameSession(
      level: widget.level.number,
      seed: widget.level.number,
    )..start();
    unawaited(_audioProfile.preload(_audio));
  }

  List<List<DetectiveMark>> _emptyGrid() => List<List<DetectiveMark>>.generate(
    DetectiveNotesPuzzle.people.length,
    (_) => List<DetectiveMark>.filled(
      DetectiveNotesPuzzle.people.length,
      DetectiveMark.unknown,
    ),
  );

  void _cycleMark(int person, int value) {
    if (_finished) return;
    final List<List<DetectiveMark>> marks = _activeMarks;
    final DetectiveMark previous = marks[person][value];
    final DetectiveMark next = switch (previous) {
      DetectiveMark.unknown => DetectiveMark.confirmed,
      DetectiveMark.confirmed => DetectiveMark.crossed,
      DetectiveMark.crossed => DetectiveMark.unknown,
    };
    setState(() {
      _moves++;
      marks[person][value] = next;
      if (next == DetectiveMark.confirmed) {
        for (int index = 0; index < marks.length; index++) {
          if (index != value) {
            if (marks[person][index] == DetectiveMark.confirmed) {
              marks[person][index] = DetectiveMark.unknown;
            } else {
              marks[person][index] = DetectiveMark.crossed;
            }
          }
          if (index != person) {
            if (marks[index][value] == DetectiveMark.confirmed) {
              marks[index][value] = DetectiveMark.unknown;
            } else {
              marks[index][value] = DetectiveMark.crossed;
            }
          }
        }
      }
    });
    _session.recordAccepted();
    unawaited(
      _audioProfile.play(_audio, GameAudioEvent.primaryAction, gain: .38),
    );
  }

  void _hint() {
    if (_finished || !_session.canUseHint) return;
    final int person =
        List<int>.generate(
          DetectiveNotesPuzzle.people.length,
          (int index) => index,
        ).firstWhere(
          (int index) =>
              _activeMarks[index][_solutionValue(index)] !=
              DetectiveMark.confirmed,
          orElse: () => -1,
        );
    if (person < 0) return;
    final int value = _solutionValue(person);
    final List<List<DetectiveMark>> marks = _activeMarks;
    setState(() {
      _hints++;
      marks[person][value] = DetectiveMark.confirmed;
      for (int index = 0; index < marks.length; index++) {
        if (index != value) {
          marks[person][index] = DetectiveMark.crossed;
        }
        if (index != person) marks[index][value] = DetectiveMark.crossed;
      }
    });
    _session.useHint();
    unawaited(_audioProfile.play(_audio, GameAudioEvent.hint, gain: .55));
  }

  int _solutionValue(int person) => switch (_category) {
    0 => _puzzle.solution.relicByPerson[person],
    1 => _puzzle.solution.roomByPerson[person],
    _ => _puzzle.solution.seatOfPerson(person),
  };

  void _reset() {
    if (_finished) return;
    setState(() {
      _relicMarks = _emptyGrid();
      _roomMarks = _emptyGrid();
      _seatMarks = _emptyGrid();
      _moves = 0;
      _hints = 0;
    });
    unawaited(_audio.play(GameSound.uiBack, gain: .45));
  }

  Future<void> _submit() async {
    if (_finished) return;
    final bool correct = _puzzle.isSolved(_relicMarks, _roomMarks, _seatMarks);
    if (!correct) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _english
                ? 'The case is still open. Check every person, seat, room and relic.'
                : 'Dosya açık kaldı. Her kişi, sıra, oda ve eseri yeniden kontrol et.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      unawaited(_audio.play(GameSound.logicWall, gain: .38));
      return;
    }
    await _complete();
  }

  Future<void> _complete() async {
    if (_finished) return;
    _finished = true;
    final int stars = _hints == 0
        ? 3
        : _hints == 1
        ? 2
        : 1;
    final int score = math.max(120, 1500 - _moves * 9 - _hints * 190);
    _session.recordAccepted(points: score);
    final StudioGameResult result = _session.complete(
      stars: stars,
      action: widget.level.number < DetectiveNotesGamePage.totalCases
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
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: _ink,
        title: Text(
          _english ? 'CASE CLOSED' : 'VAKA ÇÖZÜLDÜ',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _english
              ? '$stars stars  •  $score points\nEvery clue led to one solution.'
              : '$stars yıldız  •  $score puan\nTüm ipuçları tek çözüme ulaştı.',
          style: const TextStyle(fontFamily: 'Roboto', color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(
                StudioGameResult.completed(
                  score: score,
                  stars: stars,
                  action: StudioResultAction.map,
                ).toParkurResult(),
              );
            },
            child: Text(_english ? 'CASE BOARD' : 'DOSYA PANOSU'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(result.toParkurResult());
            },
            child: Text(
              widget.level.number < DetectiveNotesGamePage.totalCases
                  ? (_english ? 'NEXT CASE' : 'SONRAKİ DOSYA')
                  : (_english ? 'CASE BOARD' : 'DOSYA PANOSU'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _english = context.l10n.isEnglish;
    final StudioGameSkin skin = StudioGameSkin.forId('detective_notes');
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _english ? 'DETECTIVE NOTES' : 'DEDEKTİF NOTLARI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                letterSpacing: .7,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              _english
                  ? 'CASE ${widget.level.number.toString().padLeft(2, '0')}'
                  : 'DOSYA ${widget.level.number.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _hint,
            tooltip: _english ? 'Reveal one deduction' : 'Bir çıkarım göster',
            icon: const Icon(Icons.tips_and_updates_outlined),
          ),
          IconButton(
            onPressed: _reset,
            tooltip: _english ? 'Reset notes' : 'Notları sıfırla',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveGameFrame(
          maxContentWidth: 620,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: <Widget>[
              _CaseFileHeader(
                level: widget.level.number,
                clueCount: _puzzle.clues.length,
                moveCount: _moves,
                best: widget.previousBestScore,
                english: _english,
              ),
              const SizedBox(height: 14),
              _CluePanel(
                clues: _puzzle.clues,
                english: _english,
                labels: _puzzle.labels,
              ),
              const SizedBox(height: 16),
              _EvidenceMatrix(
                marks: _activeMarks,
                category: _category,
                english: _english,
                labels: _puzzle.labels,
                onCategoryChanged: (int category) => setState(() {
                  _category = category;
                }),
                onCellTap: _cycleMark,
              ),
              const SizedBox(height: 12),
              _Legend(english: _english),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(_english ? 'CLOSE THE CASE' : 'VAKAYI ÇÖZ'),
                style: FilledButton.styleFrom(
                  backgroundColor: skin.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(
                    GameInputPolicy.minimumTargetSize + 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseFileHeader extends StatelessWidget {
  const _CaseFileHeader({
    required this.level,
    required this.clueCount,
    required this.moveCount,
    required this.best,
    required this.english,
  });

  final int level;
  final int clueCount;
  final int moveCount;
  final int best;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[_DetectiveNotesPlayPageState._ink, Color(0xFF384B63)],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: _DetectiveNotesPlayPageState._ink.withValues(alpha: .15),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
          ),
          child: const Icon(
            Icons.folder_copy_outlined,
            color: Color(0xFFE8C98E),
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                english ? 'ARCHIVE FILE' : 'ARŞİV DOSYASI',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFFE8C98E),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                english ? 'The Museum Cipher' : 'Müze Şifresi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                english
                    ? '$clueCount clues  ·  $moveCount notes${best > 0 ? '  ·  $best best' : ''}'
                    : '$clueCount ipucu  ·  $moveCount not${best > 0 ? '  ·  $best rekor' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8C98E),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '№ ${level.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF42351F),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CluePanel extends StatelessWidget {
  const _CluePanel({
    required this.clues,
    required this.english,
    required this.labels,
  });

  final List<DetectiveClue> clues;
  final bool english;
  final DetectiveNotesLabels labels;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5E1D7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.push_pin_outlined,
                color: _DetectiveNotesPlayPageState._brass,
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  english ? 'EVIDENCE & CLUES' : 'KANITLAR VE İPUÇLARI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _DetectiveNotesPlayPageState._ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .65,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: _DetectiveNotesPlayPageState._paper,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${clues.length} ${english ? 'CLUES' : 'İPUCU'}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: StudioVisuals.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEAE7DF)),
        for (int index = 0; index < clues.length; index++)
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 7, 13, 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EEE5),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _DetectiveNotesPlayPageState._brass,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    clues[index].text(english: english, labels: labels),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: _DetectiveNotesPlayPageState._ink,
                      fontSize: 11,
                      height: 1.28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 5),
      ],
    ),
  );
}

class _EvidenceMatrix extends StatelessWidget {
  const _EvidenceMatrix({
    required this.marks,
    required this.category,
    required this.english,
    required this.labels,
    required this.onCategoryChanged,
    required this.onCellTap,
  });

  final List<List<DetectiveMark>> marks;
  final int category;
  final bool english;
  final DetectiveNotesLabels labels;
  final ValueChanged<int> onCategoryChanged;
  final void Function(int person, int value) onCellTap;

  @override
  Widget build(BuildContext context) {
    final List<String> values = switch (category) {
      0 => english ? labels.relicsEn : labels.relicsTr,
      1 => english ? labels.roomsEn : labels.roomsTr,
      _ =>
        english
            ? const <String>['Seat 1', 'Seat 2', 'Seat 3', 'Seat 4']
            : const <String>['Sıra 1', 'Sıra 2', 'Sıra 3', 'Sıra 4'],
    };
    final String valueKey = switch (category) {
      0 => 'relic',
      1 => 'room',
      _ => 'seat',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 12, 11, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E1D7)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF4D5662).withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.table_chart_outlined,
                color: _DetectiveNotesPlayPageState._brass,
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  english ? 'DEDUCTION GRID' : 'ÇIKARIM MATRİSİ',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: _DetectiveNotesPlayPageState._ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
              Text(
                english ? 'Tap to mark' : 'İşaretlemek için dokun',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: StudioVisuals.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _DetectiveNotesPlayPageState._paper,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: <Widget>[
                _CategoryTab(
                  key: const ValueKey<String>('detective_relics_tab'),
                  label: english ? 'RELICS' : 'ESERLER',
                  icon: Icons.diamond_outlined,
                  selected: category == 0,
                  onTap: () => onCategoryChanged(0),
                ),
                _CategoryTab(
                  key: const ValueKey<String>('detective_rooms_tab'),
                  label: english ? 'ROOMS' : 'ODALAR',
                  icon: Icons.meeting_room_outlined,
                  selected: category == 1,
                  onTap: () => onCategoryChanged(1),
                ),
                _CategoryTab(
                  key: const ValueKey<String>('detective_seats_tab'),
                  label: english ? 'SEATS' : 'SIRA',
                  icon: Icons.event_seat_outlined,
                  selected: category == 2,
                  onTap: () => onCategoryChanged(2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const double labelWidth = 68;
              final double columnWidth =
                  (constraints.maxWidth - labelWidth - 4) / values.length;
              final double cellWidth = math.min(52, columnWidth);
              return Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const SizedBox(width: labelWidth),
                      for (int column = 0; column < values.length; column++)
                        SizedBox(
                          width: cellWidth,
                          height: 43,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Center(
                              child: Text(
                                values[column],
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: StudioVisuals.muted,
                                  fontSize: 10,
                                  height: 1.12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (
                    int person = 0;
                    person < labels.people.length;
                    person++
                  )
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: labelWidth,
                            height: GameInputPolicy.minimumTargetSize,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                labels.people[person],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: _DetectiveNotesPlayPageState._ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          for (int value = 0; value < values.length; value++)
                            SizedBox(
                              width: cellWidth,
                              height: GameInputPolicy.minimumTargetSize,
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: _EvidenceCell(
                                  key: ValueKey<String>(
                                    'detective_cell_${valueKey}_${person}_$value',
                                  ),
                                  mark: marks[person][value],
                                  english: english,
                                  onTap: () => onCellTap(person, value),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 14,
                  color: selected
                      ? _DetectiveNotesPlayPageState._ink
                      : StudioVisuals.muted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: selected
                          ? _DetectiveNotesPlayPageState._ink
                          : StudioVisuals.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _EvidenceCell extends StatelessWidget {
  const _EvidenceCell({
    super.key,
    required this.mark,
    required this.english,
    required this.onTap,
  });

  final DetectiveMark mark;
  final bool english;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = switch (mark) {
      DetectiveMark.unknown => const Color(0xFFF5F6F8),
      DetectiveMark.crossed => const Color(0xFFF6ECEB),
      DetectiveMark.confirmed => const Color(0xFFE5F1ED),
    };
    final Color ink = switch (mark) {
      DetectiveMark.unknown => const Color(0xFFDCE1E5),
      DetectiveMark.crossed => const Color(0xFFC67870),
      DetectiveMark.confirmed => const Color(0xFF27816E),
    };
    final IconData? icon = switch (mark) {
      DetectiveMark.unknown => null,
      DetectiveMark.crossed => Icons.close_rounded,
      DetectiveMark.confirmed => Icons.check_rounded,
    };
    return Semantics(
      button: true,
      label: switch (mark) {
        DetectiveMark.unknown => english ? 'Unmarked' : 'İşaretlenmemiş',
        DetectiveMark.crossed => english ? 'Not a match' : 'Eşleşme değil',
        DetectiveMark.confirmed => english ? 'Match' : 'Eşleşme',
      },
      child: Material(
        color: tint,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: ink.withValues(alpha: .27)),
              ),
              child: icon == null ? null : Icon(icon, color: ink, size: 19),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 18,
    runSpacing: 6,
    children: <Widget>[
      _LegendItem(
        icon: Icons.check_rounded,
        color: const Color(0xFF27816E),
        label: english ? 'Match' : 'Eşleşir',
      ),
      _LegendItem(
        icon: Icons.close_rounded,
        color: const Color(0xFFC67870),
        label: english ? 'Exclude' : 'Elendi',
      ),
      _LegendItem(
        icon: Icons.circle_outlined,
        color: StudioVisuals.muted,
        label: english ? 'Unknown' : 'Belirsiz',
      ),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: StudioVisuals.muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
