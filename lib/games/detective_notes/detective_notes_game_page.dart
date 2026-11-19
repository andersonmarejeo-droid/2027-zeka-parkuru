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
  int _currentClueIndex = 0;

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

  void _showAllClues() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.folder_open_rounded, color: _brass, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _english
                          ? 'CASE FILE & ALL CLUES'
                          : 'VAKA DOSYASI VE TÜM İPUÇLARI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFEAE7DF)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _puzzle.clues.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final DetectiveClue clue = _puzzle.clues[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1EEE5),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              color: _brass,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            clue.text(english: _english, labels: _puzzle.labels),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              color: _ink,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowToPlay() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.help_outline_rounded, color: _brass, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _english ? 'HOW TO PLAY?' : 'NASIL OYNANIR?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _english
                    ? '• Deduce which person matches which item, room, and seat.\n• Read the clues and tap matrix cells to cycle marks:\n  ✓ (Green Check) = Confirmed match\n  ✗ (Red X) = Impossible match\n  ○ (Empty) = Unknown\n• Fill the deduction grid accurately and tap "CLOSE THE CASE"!'
                    : '• İpuçlarından yola çıkarak her kişinin hangi eşya, oda ve sıraya ait olduğunu bulun.\n• Matris hücrelerine dokunarak işaretleri değiştirin:\n  ✓ (Yeşil Onay) = Kesin eşleşme\n  ✗ (Kırmızı Çarpı) = Eşleşemez\n  ○ (Boş) = Bilinmiyor\n• Tüm eşleşmeleri tamamlayıp "VAKAYI ÇÖZ" butonuna dokunun!',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  height: 1.5,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
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
        titleSpacing: 10,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _english ? 'DETECTIVE NOTES' : 'DEDEKTİF NOTLARI',
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  letterSpacing: .6,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              _english
                  ? 'CASE ${widget.level.number.toString().padLeft(2, '0')}'
                  : 'DOSYA ${widget.level.number.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: StudioVisuals.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _showAllClues,
            tooltip: _english ? 'All clues' : 'Tüm ipuçları',
            icon: const Icon(Icons.description_outlined),
          ),
          IconButton(
            onPressed: _showHowToPlay,
            tooltip: _english ? 'How to play' : 'Nasıl oynanır',
            icon: const Icon(Icons.help_outline_rounded),
          ),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Üst Durum Çubuğu
                _DetectiveStatusBar(
                  level: widget.level.number,
                  clueCount: _puzzle.clues.length,
                  moves: _moves,
                  hints: _hints,
                  best: widget.previousBestScore,
                  english: _english,
                ),
                const SizedBox(height: 8),

                // Kompakt İpucu Gezgini (Zero-scroll için kompakt, tüm ipuçları gezilebilir ve açılır pencereli)
                _SmartClueBar(
                  clues: _puzzle.clues,
                  currentIndex: _currentClueIndex,
                  english: _english,
                  labels: _puzzle.labels,
                  onPrev: () => setState(() {
                    if (_currentClueIndex > 0) {
                      _currentClueIndex--;
                    } else {
                      _currentClueIndex = _puzzle.clues.length - 1;
                    }
                  }),
                  onNext: () => setState(() {
                    if (_currentClueIndex < _puzzle.clues.length - 1) {
                      _currentClueIndex++;
                    } else {
                      _currentClueIndex = 0;
                    }
                  }),
                  onShowAll: _showAllClues,
                ),
                const SizedBox(height: 8),

                // Çıkarım Matrisi Alanı (Merkezde, Expanded, küçültülmemiş)
                Expanded(
                  child: _EvidenceMatrix(
                    marks: _activeMarks,
                    category: _category,
                    english: _english,
                    labels: _puzzle.labels,
                    onCategoryChanged: (int category) => setState(() {
                      _category = category;
                    }),
                    onCellTap: _cycleMark,
                  ),
                ),
                const SizedBox(height: 8),

                // Alt Kontrol ve Onay Şeridi
                Row(
                  children: <Widget>[
                    _CompactLegend(english: _english),
                    const SizedBox(width: 8),
                    const Spacer(),
                    Flexible(
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.fact_check_outlined, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_english ? 'CLOSE CASE' : 'VAKAYI ÇÖZ'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: skin.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                            fontSize: 13,
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

class _DetectiveStatusBar extends StatelessWidget {
  const _DetectiveStatusBar({
    required this.level,
    required this.clueCount,
    required this.moves,
    required this.hints,
    required this.best,
    required this.english,
  });

  final int level;
  final int clueCount;
  final int moves;
  final int hints;
  final int best;
  final bool english;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E1D7)),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x06283640),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _DetectiveNotesPlayPageState._ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.folder_copy_outlined,
                  size: 13,
                  color: Color(0xFFE8C98E),
                ),
                const SizedBox(width: 5),
                Text(
                  '${english ? 'CASE' : 'DOSYA'} ${level.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CompactMetric(
            icon: Icons.push_pin_outlined,
            label: english ? 'CLUES' : 'İPUCU',
            value: '$clueCount',
          ),
          const SizedBox(width: 6),
          _CompactMetric(
            icon: Icons.touch_app_outlined,
            label: english ? 'MOVE' : 'HAMLE',
            value: '$moves',
          ),
          if (best > 0) ...<Widget>[
            const SizedBox(width: 6),
            _CompactMetric(
              icon: Icons.emoji_events_outlined,
              label: english ? 'BEST' : 'REKOR',
              value: '$best',
              color: _DetectiveNotesPlayPageState._brass,
            ),
          ],
        ],
      ),
    ),
  );
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color textColor = color ?? _DetectiveNotesPlayPageState._ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: StudioVisuals.muted),
          const SizedBox(width: 4),
          Text(
            '$label $value',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartClueBar extends StatelessWidget {
  const _SmartClueBar({
    required this.clues,
    required this.currentIndex,
    required this.english,
    required this.labels,
    required this.onPrev,
    required this.onNext,
    required this.onShowAll,
  });

  final List<DetectiveClue> clues;
  final int currentIndex;
  final bool english;
  final DetectiveNotesLabels labels;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final DetectiveClue clue = clues[currentIndex];
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E1D7)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06283640),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onPrev,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            tooltip: english ? 'Previous clue' : 'Önceki ipucu',
          ),
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF1EEE5),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${currentIndex + 1}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: _DetectiveNotesPlayPageState._brass,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              clue.text(english: english, labels: labels),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                color: _DetectiveNotesPlayPageState._ink,
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            tooltip: english ? 'Next clue' : 'Sonraki ipucu',
          ),
          InkWell(
            onTap: onShowAll,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 13,
                    color: _DetectiveNotesPlayPageState._brass,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${clues.length}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _DetectiveNotesPlayPageState._brass,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactLegend extends StatelessWidget {
  const _CompactLegend({required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _LegendItem(
        icon: Icons.check_rounded,
        color: const Color(0xFF27816E),
        label: english ? 'Match' : 'Doğru',
      ),
      const SizedBox(width: 8),
      _LegendItem(
        icon: Icons.close_rounded,
        color: const Color(0xFFC67870),
        label: english ? 'Exclude' : 'Yanlış',
      ),
    ],
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
      child: SingleChildScrollView(
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
