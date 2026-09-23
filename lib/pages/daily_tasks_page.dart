import 'package:flutter/material.dart';

import '../theme/app_visual_theme.dart';

import '../l10n/app_localizations.dart';
import 'daily_course_page.dart';

import '../services/daily_challenge_service.dart';
import '../services/daily_course_service.dart';
import '../services/game_audio_service.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  final DailyChallengeService _daily = DailyChallengeService.instance;
  final DailyCourseService _course = DailyCourseService.instance;
  final GameAudioService _audio = GameAudioService.instance;

  DailyChallengeData? _data;
  DailyCourseData? _courseData;
  bool _loading = true;
  bool _leavingPage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final DailyChallengeData data = await _daily.loadToday();
    final DailyCourseData courseData = await _course.loadToday();

    if (!mounted) return;

    setState(() {
      _data = data;
      _courseData = courseData;
      _loading = false;
    });
  }

  Future<void> _openDailyCourse() async {
    await _audio.play(GameSound.uiClick);
    if (!mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const DailyCoursePage()),
    );

    if (mounted) await _load();
  }

  Future<void> _returnToGame() async {
    if (_leavingPage) return;
    setState(() => _leavingPage = true);

    try {
      await _audio.play(GameSound.uiClick);
    } catch (error) {
      debugPrint('Görevler dönüş sesi atlandı: $error');
    }
    if (!mounted) return;

    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    setState(() => _leavingPage = false);
  }

  IconData _iconFor(DailyTaskType type) {
    switch (type) {
      case DailyTaskType.completeLevels:
        return Icons.flag_rounded;
      case DailyTaskType.earnStars:
        return Icons.star_rounded;
      case DailyTaskType.playDifferentGames:
        return Icons.route_rounded;
      case DailyTaskType.earnScore:
        return Icons.bolt_rounded;
      case DailyTaskType.playSpecificGame:
        return Icons.sports_esports_rounded;
      case DailyTaskType.threeStarLevel:
        return Icons.workspace_premium_rounded;
    }
  }

  Color _colorFor(DailyTaskType type) {
    switch (type) {
      case DailyTaskType.completeLevels:
        return const Color(0xFF00D9FF);
      case DailyTaskType.earnStars:
        return const Color(0xFFFFD334);
      case DailyTaskType.playDifferentGames:
        return const Color(0xFF76FF03);
      case DailyTaskType.earnScore:
        return const Color(0xFFFF8A00);
      case DailyTaskType.playSpecificGame:
        return const Color(0xFFB06CFF);
      case DailyTaskType.threeStarLevel:
        return const Color(0xFFE748CF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DailyChallengeData? data = _data;
    final DailyCourseData? courseData = _courseData;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.dailyChallenges,
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.7),
        ),
      ),
      body: _loading || data == null || courseData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  _StreakCard(data: data),
                  const SizedBox(height: 16),
                  _DailyCourseLaunchCard(
                    data: courseData,
                    onTap: _openDailyCourse,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.todaysGoals,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${data.completedTaskCount}/3',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...data.tasks.map(
                    (progress) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TaskCard(
                        progress: progress,
                        icon: _iconFor(progress.task.type),
                        color: _colorFor(progress.task.type),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _DailyFinishCard(data: data),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.dailyResetInfo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _leavingPage ? null : _returnToGame,
                          icon: const Icon(Icons.sports_esports_rounded),
                          label: Text(context.l10n.backToGame),
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

class _DailyCourseLaunchCard extends StatelessWidget {
  final DailyCourseData data;
  final VoidCallback onTap;

  const _DailyCourseLaunchCard({required this.data, required this.onTap});

  IconData _iconFor(String gameId) {
    switch (gameId) {
      case 'logic':
        return Icons.route_rounded;
      case 'numbers':
        return Icons.calculate_rounded;
      case 'blocks':
        return Icons.view_in_ar_rounded;
      case 'memory':
        return Icons.grid_view_rounded;
      case 'hanoi':
        return Icons.account_balance_rounded;
      case 'word_hunt':
        return Icons.travel_explore_rounded;
      case 'picture_iq':
        return Icons.auto_awesome_mosaic_rounded;
      case 'candy_sort':
        return Icons.cookie_rounded;
      case 'number_sort':
        return Icons.hive_rounded;
      case 'shape_puzzle':
        return Icons.interests_rounded;
      case 'reflex':
        return Icons.bolt_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    final bool completed = data.allCompleted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Ink(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: completed
                ? const [Color(0xFF375C25), Color(0xFF176A62)]
                : const [Color(0xFF07577A), Color(0xFF4D2A85)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4400D9FF),
              blurRadius: 22,
              spreadRadius: -13,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    completed
                        ? Icons.emoji_events_rounded
                        : Icons.route_rounded,
                    color: const Color(0xFFFFD334),
                    size: 31,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        english ? 'Daily Brain Course' : 'Günün Zekâ Parkuru',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        completed
                            ? english
                                  ? 'Course complete • ${data.totalScore} Brain Points'
                                  : 'Parkur tamamlandı • ${data.totalScore} Zeka Puanı'
                            : english
                            ? 'Complete ${data.games.length} different games in order.'
                            : '${data.games.length} farklı oyunu sırayla tamamla.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Column(
              children: [
                for (
                  int rowStart = 0;
                  rowStart < data.games.length;
                  rowStart += 4
                ) ...[
                  Row(
                    children: [
                      for (
                        int index = rowStart;
                        index < data.games.length && index < rowStart + 4;
                        index++
                      ) ...[
                        Expanded(
                          child: _DailyCourseMiniStep(
                            number: index + 1,
                            icon: _iconFor(data.games[index]),
                            completed: data.isCompleted(data.games[index]),
                            current: data.nextGameId == data.games[index],
                          ),
                        ),
                        if (index < data.games.length - 1 &&
                            index < rowStart + 3)
                          Container(
                            width: 12,
                            height: 2,
                            color: data.isCompleted(data.games[index])
                                ? const Color(0xFF6CFF9B)
                                : Colors.white24,
                          ),
                      ],
                    ],
                  ),
                  if (rowStart + 4 < data.games.length)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyCourseMiniStep extends StatelessWidget {
  final int number;
  final IconData icon;
  final bool completed;
  final bool current;

  const _DailyCourseMiniStep({
    required this.number,
    required this.icon,
    required this.completed,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = completed
        ? const Color(0xFF6CFF9B)
        : current
        ? const Color(0xFF7BEAFF)
        : Colors.white54;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(completed ? Icons.check_rounded : icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            '$number',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final DailyChallengeData data;

  const _StreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5C00), Color(0xFFFFB300)],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 57,
                height: 57,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 36,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.streakTitle(data.currentStreak),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.activeToday
                          ? context.l10n.streakDoneToday
                          : context.l10n.keepStreak,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                data.activeToday
                    ? Icons.check_circle_rounded
                    : Icons.hourglass_top_rounded,
                size: 29,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StreakStat(
                  title: context.l10n.bestStreak,
                  value: context.l10n.dayCount(data.bestStreak),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _StreakStat(
                  title: context.l10n.perfectDay,
                  value: '${data.perfectDays}',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _StreakStat(
                  title: context.l10n.today,
                  value: context.l10n.taskCount(data.completedTaskCount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final String title;
  final String value;

  const _StreakStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTaskProgress progress;
  final IconData icon;
  final Color color;

  const _TaskCard({
    required this.progress,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: progress.completed
              ? const Color(0xFF52E86B).withValues(alpha: 0.65)
              : color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: progress.completed
                  ? const Color(0xFF52E86B).withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              progress.completed ? Icons.check_rounded : icon,
              color: progress.completed ? const Color(0xFF52E86B) : color,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.dailyTaskTitle(progress.task.id),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${progress.shownCurrent}/${progress.task.target}',
                      style: TextStyle(
                        color: progress.completed
                            ? const Color(0xFF52E86B)
                            : Colors.white70,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.dailyTaskDescription(
                    progress.task.id,
                    progress.task.gameId,
                  ),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress.ratio,
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress.completed ? const Color(0xFF52E86B) : color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyFinishCard extends StatelessWidget {
  final DailyChallengeData data;

  const _DailyFinishCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool completed = data.allTasksCompleted;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: completed
            ? const LinearGradient(
                colors: [Color(0xFF6043D8), Color(0xFFE748CF)],
              )
            : null,
        color: completed ? null : const Color(0xFF0D213F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: completed ? Colors.white24 : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.workspace_premium_rounded
                : Icons.lock_clock_rounded,
            color: completed ? const Color(0xFFFFD334) : Colors.white30,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed
                      ? context.l10n.dailyCourseCompleted
                      : context.l10n.dailyCourse,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  completed
                      ? context.l10n.perfectDayEarned
                      : context.l10n.completeDailyCourse,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
