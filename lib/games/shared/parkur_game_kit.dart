import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/daily_course_service.dart';
import '../../services/game_audio_service.dart';

class ParkurLevelSpec {
  final int number;
  final String titleTr;
  final String titleEn;
  final String subtitleTr;
  final String subtitleEn;
  final String difficulty;
  final IconData icon;

  const ParkurLevelSpec({
    required this.number,
    required this.titleTr,
    required this.titleEn,
    required this.subtitleTr,
    required this.subtitleEn,
    required this.difficulty,
    required this.icon,
  });

  String title(bool english) => english ? titleEn : titleTr;
  String subtitle(bool english) => english ? subtitleEn : subtitleTr;
}

class ParkurGameResult {
  final bool completed;
  final int stars;
  final int score;
  final bool nextLevel;
  final bool replayLevel;

  const ParkurGameResult({
    required this.completed,
    required this.stars,
    required this.score,
    required this.nextLevel,
    this.replayLevel = false,
  });
}

class ParkurProgressSnapshot {
  final int unlockedLevel;
  final List<int> stars;
  final List<int> bestScores;

  const ParkurProgressSnapshot({
    required this.unlockedLevel,
    required this.stars,
    required this.bestScores,
  });
}

class ParkurProgressStore {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  final String prefix;
  final int levelCount;

  ParkurProgressStore({required this.prefix, required this.levelCount});

  Future<ParkurProgressSnapshot> load() async {
    final int unlocked = await _prefs.getInt('${prefix}_unlocked_level') ?? 1;
    final List<String>? storedStars = await _prefs.getStringList(
      '${prefix}_stars',
    );
    final List<String>? storedScores = await _prefs.getStringList(
      '${prefix}_best_scores',
    );

    return ParkurProgressSnapshot(
      unlockedLevel: unlocked.clamp(1, levelCount).toInt(),
      stars: _decode(storedStars, stars: true),
      bestScores: _decode(storedScores),
    );
  }

  List<int> _decode(List<String>? source, {bool stars = false}) {
    return List<int>.generate(levelCount, (int index) {
      if (source == null || index >= source.length) return 0;
      final int value = max(0, int.tryParse(source[index]) ?? 0);
      return stars ? value.clamp(0, 3).toInt() : value;
    });
  }

  Future<void> save(ParkurProgressSnapshot data) async {
    await _prefs.setInt(
      '${prefix}_unlocked_level',
      data.unlockedLevel.clamp(1, levelCount).toInt(),
    );
    await _prefs.setStringList(
      '${prefix}_stars',
      data.stars.map((int value) => '$value').toList(growable: false),
    );
    await _prefs.setStringList(
      '${prefix}_best_scores',
      data.bestScores.map((int value) => '$value').toList(growable: false),
    );
  }
}

typedef ParkurPlayBuilder = Widget Function(
  BuildContext context,
  ParkurLevelSpec level,
  int previousBestScore,
  int? competitionLayoutCode,
  bool competitionMode,
);

class ParkurLevelHub extends StatefulWidget {
  final String gameId;
  final String progressPrefix;
  final String titleTr;
  final String titleEn;
  final String taglineTr;
  final String taglineEn;
  final Color accent;
  final IconData icon;
  final List<ParkurLevelSpec> levels;
  final bool dailyCourseMode;
  final int? competitionLevel;
  final int? competitionLayoutCode;
  final ParkurPlayBuilder playBuilder;

  const ParkurLevelHub({
    super.key,
    required this.gameId,
    required this.progressPrefix,
    required this.titleTr,
    required this.titleEn,
    required this.taglineTr,
    required this.taglineEn,
    required this.accent,
    required this.icon,
    required this.levels,
    required this.dailyCourseMode,
    this.competitionLevel,
    this.competitionLayoutCode,
    required this.playBuilder,
  });

  @override
  State<ParkurLevelHub> createState() => _ParkurLevelHubState();
}

class _ParkurLevelHubState extends State<ParkurLevelHub> {
  late final ParkurProgressStore _store;
  final GameAudioService _audio = GameAudioService.instance;

  bool _loading = true;
  int _unlockedLevel = 1;
  List<int> _stars = const <int>[];
  List<int> _bestScores = const <int>[];
  bool _competitionOpened = false;

  int get _totalStars => _stars.fold<int>(0, (int a, int b) => a + b);
  int get _totalScore => _bestScores.fold<int>(0, (int a, int b) => a + b);

  @override
  void initState() {
    super.initState();
    _store = ParkurProgressStore(
      prefix: widget.progressPrefix,
      levelCount: widget.levels.length,
    );
    unawaited(_load());
    unawaited(_audio.preload(GameAudioGroup.ui));
  }

  Future<void> _load() async {
    final ParkurProgressSnapshot data = await _store.load();
    if (!mounted) return;
    setState(() {
      _unlockedLevel = data.unlockedLevel;
      _stars = List<int>.from(data.stars);
      _bestScores = List<int>.from(data.bestScores);
      _loading = false;
    });

    _openCompetitionLevelIfNeeded();
  }

  void _openCompetitionLevelIfNeeded() {
    final int? level = widget.competitionLevel;
    if (_competitionOpened || level == null) return;
    _competitionOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openLevel((level - 1).clamp(0, widget.levels.length - 1).toInt());
    });
  }

  Future<void> _openLevel(int index) async {
    if (_loading ||
        index < 0 ||
        index >= widget.levels.length ||
        (widget.competitionLevel == null && index + 1 > _unlockedLevel)) {
      return;
    }

    unawaited(_audio.play(GameSound.uiClick));
    int activeIndex = index;
    final NavigatorState navigator = Navigator.of(context);

    while (mounted) {
      final ParkurGameResult? result = await navigator.push<ParkurGameResult>(
        MaterialPageRoute(
          builder: (BuildContext context) => widget.playBuilder(
            context,
            widget.levels[activeIndex],
            _bestScores[activeIndex],
            widget.competitionLayoutCode,
            widget.competitionLevel != null,
          ),
        ),
      );

      if (!mounted) return;

      // Daily Course has its own four-state contract. Keep this branch before
      // the generic competition branch so duel and group behaviour stays
      // untouched while Daily Course can distinguish back from failure.
      if (widget.dailyCourseMode) {
        final DailyStageResult dailyResult = result == null
            ? DailyStageResult.exited(gameId: widget.gameId)
            : result.completed
            ? DailyStageResult.completed(
                gameId: widget.gameId,
                stars: result.stars,
                rawScore: result.score,
              )
            : DailyStageResult.failed(gameId: widget.gameId);
        navigator.pop(dailyResult);
        return;
      }

      if (result == null || !result.completed) {
        if (widget.competitionLevel != null && mounted) {
          navigator.pop();
        }
        return;
      }

      if (widget.competitionLevel != null) {
        navigator.pop(
          DailyCourseGameResult(
            gameId: widget.gameId,
            stars: result.stars,
            score: result.score,
          ),
        );
        return;
      }

      setState(() {
        _stars[activeIndex] = max(_stars[activeIndex], result.stars);
        _bestScores[activeIndex] = max(_bestScores[activeIndex], result.score);
        if (activeIndex + 1 == _unlockedLevel &&
            _unlockedLevel < widget.levels.length) {
          _unlockedLevel++;
        }
      });

      await _store.save(
        ParkurProgressSnapshot(
          unlockedLevel: _unlockedLevel,
          stars: _stars,
          bestScores: _bestScores,
        ),
      );

      await DailyChallengeService.instance.recordLevelCompleted(
        gameId: widget.gameId,
        stars: result.stars,
        score: result.score,
      );

      if (!widget.dailyCourseMode && activeIndex + 1 == widget.levels.length) {
        await GameAudioService.instance.playMashallahCelebration();
      }

      if (result.replayLevel) {
        await Future<void>.delayed(const Duration(milliseconds: 160));
        continue;
      }

      if (result.nextLevel && activeIndex + 1 < widget.levels.length) {
        activeIndex++;
        await Future<void>.delayed(const Duration(milliseconds: 160));
        continue;
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.gameUi(english ? widget.titleEn : widget.titleTr),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              context.l10n.gameUi(
                english ? widget.taglineEn : widget.taglineTr,
              ),
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading || widget.competitionLevel != null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                    child: _ProgressPanel(
                      accent: widget.accent,
                      icon: widget.icon,
                      totalScore: _totalScore,
                      totalStars: _totalStars,
                      unlockedLevel: _unlockedLevel,
                      levelCount: widget.levels.length,
                      english: english,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints limits) {
                        final bool compact = limits.maxWidth < 360;
                        return GridView.builder(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 12 : 18,
                            0,
                            compact ? 12 : 18,
                            30,
                          ),
                          itemCount: widget.levels.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: compact ? 10 : 14,
                                mainAxisSpacing: compact ? 10 : 14,
                                mainAxisExtent: compact ? 174 : 184,
                              ),
                          itemBuilder: (BuildContext context, int index) {
                            return _LevelCard(
                              level: widget.levels[index],
                              accent: widget.accent,
                              unlocked: index + 1 <= _unlockedLevel,
                              stars: _stars[index],
                              bestScore: _bestScores[index],
                              english: english,
                              onTap: () => _openLevel(index),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final int totalScore;
  final int totalStars;
  final int unlockedLevel;
  final int levelCount;
  final bool english;

  const _ProgressPanel({
    required this.accent,
    required this.icon,
    required this.totalScore,
    required this.totalStars,
    required this.unlockedLevel,
    required this.levelCount,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            const Color(0xFF10294E),
            accent.withValues(alpha: 0.24),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.55)),
            ),
            child: Icon(icon, color: accent, size: 32),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _HubStat(
                  label: context.l10n.gameUi(english ? 'STARS' : 'YILDIZ'),
                  value: '$totalStars/${levelCount * 3}',
                  color: const Color(0xFFFFD334),
                ),
                _HubStat(
                  label: context.l10n.gameUi(english ? 'SCORE' : 'PUAN'),
                  value: '$totalScore',
                  color: const Color(0xFF00D9FF),
                ),
                _HubStat(
                  label: context.l10n.gameUi(english ? 'OPEN' : 'AÇIK'),
                  value: '$unlockedLevel/$levelCount',
                  color: const Color(0xFF6CFF9B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HubStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.w800,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final ParkurLevelSpec level;
  final Color accent;
  final bool unlocked;
  final int stars;
  final int bestScore;
  final bool english;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.accent,
    required this.unlocked,
    required this.stars,
    required this.bestScore,
    required this.english,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color shownAccent = unlocked ? accent : Colors.blueGrey;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                const Color(0xFF122B50),
                shownAccent.withValues(alpha: unlocked ? 0.22 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: shownAccent.withValues(alpha: unlocked ? 0.42 : 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: shownAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      unlocked ? level.icon : Icons.lock_rounded,
                      color: shownAccent,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      context.l10n.gameUi(level.difficulty),
                      style: TextStyle(
                        color: shownAccent,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${level.number}. ${context.l10n.gameUi(level.title(english))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  context.l10n.gameUi(
                    unlocked
                        ? level.subtitle(english)
                        : english
                        ? 'Complete the previous level.'
                        : 'Önceki bölümü tamamla.',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ),
              if (unlocked)
                Row(
                  children: <Widget>[
                    for (int index = 0; index < 3; index++)
                      Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: index < stars
                            ? const Color(0xFFFFD334)
                            : Colors.white24,
                        size: 18,
                      ),
                    const Spacer(),
                    if (bestScore > 0)
                      Text(
                        '$bestScore',
                        style: const TextStyle(
                          color: Color(0xFF7BEAFF),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ParkurResultAction { replay, map, next }

Future<ParkurResultAction?> showParkurResultDialog({
  required BuildContext context,
  required Color accent,
  required String titleTr,
  required String titleEn,
  required String detailTr,
  required String detailEn,
  required int stars,
  required int score,
  required int previousBestScore,
  required bool canGoNext,
}) {
  final bool english = context.l10n.isEnglish;
  final bool newRecord = score > previousBestScore;

  return showDialog<ParkurResultAction>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                const Color(0xFF12335E),
                accent.withValues(alpha: 0.45),
                const Color(0xFF25194F),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accent.withValues(alpha: 0.62)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.32),
                blurRadius: 34,
                spreadRadius: -12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (newRecord)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD334),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    context.l10n.gameUi(english ? 'NEW RECORD' : 'YENİ REKOR'),
                    style: const TextStyle(
                      color: Color(0xFF4E3500),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (newRecord) const SizedBox(height: 10),
              Text(
                context.l10n.gameUi(english ? titleEn : titleTr),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                context.l10n.gameUi(english ? detailEn : detailTr),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int index = 0; index < 3; index++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: index < stars
                            ? const Color(0xFFFFD334)
                            : Colors.white24,
                        size: 38,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                '$score ${context.l10n.gameUi(english ? 'POINTS' : 'PUAN')}',
                style: const TextStyle(
                  color: Color(0xFF7BEAFF),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        ParkurResultAction.replay,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      icon: const Icon(Icons.autorenew_rounded),
                      label: Text(
                        context.l10n.gameUi(english ? 'NEW ROUND' : 'YENİ TUR'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        canGoNext
                            ? ParkurResultAction.next
                            : ParkurResultAction.map,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: const Color(0xFF051426),
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      icon: Icon(
                        canGoNext
                            ? Icons.arrow_forward_rounded
                            : Icons.map_rounded,
                      ),
                      label: Text(
                        context.l10n.gameUi(
                          canGoNext
                              ? english
                                    ? 'NEXT'
                                    : 'SONRAKİ'
                              : english
                              ? 'MAP'
                              : 'HARİTA',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
