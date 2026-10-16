import 'package:flutter/material.dart';

import '../theme/studio_visuals.dart';

import '../l10n/app_localizations.dart';
import 'daily_course_page.dart';
import 'themed_course_page.dart';

import '../services/daily_challenge_service.dart';
import '../services/daily_course_service.dart';
import '../services/game_audio_service.dart';
import '../services/themed_course_service.dart';
import '../widgets/studio_card.dart';

const String _dailyCourseVisualAsset =
    'assets/branding/studio_parkur_daily_course.png';

String _themedCourseVisualAsset(String id) {
  switch (id) {
    case 'star_hunt':
      return 'assets/branding/studio_parkur_star_hunt.png';
    case 'mind_gym':
      return 'assets/branding/studio_parkur_mind_gym.png';
    case 'high_iq':
      return 'assets/branding/studio_parkur_high_iq.png';
    case 'word_labyrinth':
      return 'assets/branding/studio_parkur_word_labyrinth.png';
    case 'speed_precision':
      return 'assets/branding/studio_parkur_speed_precision.png';
    default:
      return _dailyCourseVisualAsset;
  }
}

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  final DailyChallengeService _daily = DailyChallengeService.instance;
  final DailyCourseService _course = DailyCourseService.instance;
  final ThemedCourseService _themed = ThemedCourseService.instance;
  final GameAudioService _audio = GameAudioService.instance;

  DailyChallengeData? _data;
  DailyCourseData? _courseData;
  List<ThemedCourseData>? _themedCourses;
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
    final List<ThemedCourseData> themedCourses = await Future.wait(
      ThemedCourseCatalog.definitions.map(
        (ThemedCourseDefinition definition) => _themed.load(definition.id),
      ),
    );

    if (!mounted) return;

    setState(() {
      _data = data;
      _courseData = courseData;
      _themedCourses = themedCourses;
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

  Future<void> _openThemedCourse(ThemedCourseDefinition definition) async {
    await _audio.play(GameSound.uiClick);
    if (!mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ThemedCoursePage(definition: definition),
      ),
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
        return StudioVisuals.teal;
      case DailyTaskType.earnStars:
        return StudioVisuals.amber;
      case DailyTaskType.playDifferentGames:
        return StudioVisuals.muted;
      case DailyTaskType.earnScore:
        return StudioVisuals.teal;
      case DailyTaskType.playSpecificGame:
        return StudioVisuals.muted;
      case DailyTaskType.threeStarLevel:
        return StudioVisuals.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DailyChallengeData? data = _data;
    final DailyCourseData? courseData = _courseData;
    final List<ThemedCourseData>? themedCourses = _themedCourses;

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.dailyChallenges,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: StudioPageFrame(
        child:
            _loading ||
                data == null ||
                courseData == null ||
                themedCourses == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: StudioVisuals.teal,
                backgroundColor: StudioVisuals.surface,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    StudioVisuals.pageGutter,
                    12,
                    StudioVisuals.pageGutter,
                    32,
                  ),
                  children: [
                    _StreakCard(data: data),
                    const SizedBox(height: 16),
                    _DailyCourseLaunchCard(
                      data: courseData,
                      onTap: _openDailyCourse,
                    ),
                    const SizedBox(height: 18),
                    _ThemedCourseSection(
                      courses: themedCourses,
                      onTap: _openThemedCourse,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.todaysGoals,
                            style: const TextStyle(
                              color: StudioVisuals.ink,
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
                            color: StudioVisuals.tealSoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${data.completedTaskCount}/3',
                            style: const TextStyle(
                              color: StudioVisuals.ink,
                              fontWeight: FontWeight.w900,
                            ),
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
                        color: StudioVisuals.muted,
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
                            style: FilledButton.styleFrom(
                              backgroundColor: StudioVisuals.ink,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.sports_esports_rounded),
                            label: Text(context.l10n.backToGame),
                          ),
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
      case 'card_pairs':
        return Icons.style_rounded;
      case 'focus_filter':
        return Icons.filter_center_focus_rounded;
      case 'spot_change':
        return Icons.compare_rounded;
      case 'rhythm_memory':
        return Icons.graphic_eq_rounded;
      case 'attention_tunnel':
        return Icons.blur_on_rounded;
      case 'hanoi':
        return Icons.account_balance_rounded;
      case 'word_hunt':
        return Icons.travel_explore_rounded;
      case 'meaning_match':
        return Icons.hub_rounded;
      case 'proverb_finish':
        return Icons.menu_book_rounded;
      case 'sentence_builder':
        return Icons.format_align_left_rounded;
      case 'near_meaning':
        return Icons.manage_search_rounded;
      case 'letter_maze':
        return Icons.route_rounded;
      case 'language_detective':
        return Icons.manage_search_rounded;
      case 'story_order':
        return Icons.timeline_rounded;
      case 'picture_iq':
        return Icons.auto_awesome_mosaic_rounded;
      case 'candy_sort':
        return Icons.cookie_rounded;
      case 'number_sort':
        return Icons.grid_4x4_rounded;
      case 'bubble_shooter':
        return Icons.bubble_chart_rounded;
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
      borderRadius: StudioVisuals.cardRadius,
      child: Ink(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: StudioVisuals.surface,
          borderRadius: StudioVisuals.cardRadius,
          border: Border.all(color: StudioVisuals.line),
          boxShadow: StudioVisuals.softShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: completed
                        ? StudioVisuals.tealSoft
                        : StudioVisuals.amberSoft.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    completed
                        ? Icons.emoji_events_rounded
                        : Icons.route_rounded,
                    color: completed ? StudioVisuals.teal : StudioVisuals.amber,
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
                          color: StudioVisuals.ink,
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
                          color: StudioVisuals.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: StudioVisuals.ink,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 126,
                child: Image.asset(
                  _dailyCourseVisualAsset,
                  fit: BoxFit.cover,
                  semanticLabel: english
                      ? 'Daily brain course visual'
                      : 'Günün zekâ parkuru görseli',
                ),
              ),
            ),
            const SizedBox(height: 14),
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
                                ? StudioVisuals.teal
                                : StudioVisuals.line,
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
        ? StudioVisuals.teal
        : current
        ? StudioVisuals.amber
        : StudioVisuals.muted;

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

class _ThemedCourseSection extends StatelessWidget {
  final List<ThemedCourseData> courses;
  final ValueChanged<ThemedCourseDefinition> onTap;

  const _ThemedCourseSection({required this.courses, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                english ? 'MORE BRAIN CIRCUITS' : 'DİĞER ZEKÂ PARKURLARI',
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              english ? 'CHOOSE A THEME' : 'TEMANI SEÇ',
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          english
              ? 'Replayable mixed routes, each with its own game mix and difficulty.'
              : 'Günlük parkura ek olarak, kendi oyun seçkisi ve zorluk düzeni olan tekrar oynanabilir parkurlar.',
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 11,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 11),
        ...courses.map(
          (ThemedCourseData data) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _ThemedCourseLaunchCard(
              data: data,
              onTap: () => onTap(data.definition),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemedCourseLaunchCard extends StatelessWidget {
  final ThemedCourseData data;
  final VoidCallback onTap;

  const _ThemedCourseLaunchCard({required this.data, required this.onTap});

  Color _accent(String id) {
    switch (id) {
      case 'star_hunt':
        return StudioVisuals.amber;
      case 'mind_gym':
        return StudioVisuals.teal;
      case 'high_iq':
        return const Color(0xFF665AA2);
      case 'word_labyrinth':
        return const Color(0xFF3D7183);
      case 'speed_precision':
        return StudioVisuals.danger;
      default:
        return StudioVisuals.teal;
    }
  }

  IconData _icon(String id) {
    switch (id) {
      case 'star_hunt':
        return Icons.stars_rounded;
      case 'mind_gym':
        return Icons.psychology_alt_rounded;
      case 'high_iq':
        return Icons.workspace_premium_rounded;
      case 'word_labyrinth':
        return Icons.menu_book_rounded;
      case 'speed_precision':
        return Icons.bolt_rounded;
      default:
        return Icons.route_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    final Color accent = _accent(data.definition.id);
    final double progress = data.games.isEmpty
        ? 0
        : data.completedCount / data.games.length;

    return InkWell(
      onTap: onTap,
      borderRadius: StudioVisuals.cardRadius,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StudioVisuals.surface,
          borderRadius: StudioVisuals.cardRadius,
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          boxShadow: StudioVisuals.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    data.allCompleted
                        ? Icons.check_circle_rounded
                        : _icon(data.definition.id),
                    color: accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.definition.title(english: english),
                        style: const TextStyle(
                          color: StudioVisuals.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data.definition.subtitle(english: english),
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: accent, size: 17),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 126,
                child: Image.asset(
                  _themedCourseVisualAsset(data.definition.id),
                  fit: BoxFit.cover,
                  semanticLabel: data.definition.title(english: english),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              data.definition.description(english: english),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 10,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: StudioVisuals.surfaceSoft,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.allCompleted
                        ? (english
                              ? 'Complete • ${data.totalScore} Brain Points'
                              : 'Tamamlandı • ${data.totalScore} Zeka Puanı')
                        : '${data.completedCount}/${data.games.length} ${english ? 'steps' : 'adım'}',
                    style: TextStyle(
                      color: data.allCompleted ? accent : StudioVisuals.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  english
                      ? 'Lv ${data.definition.minLevel}-${data.definition.maxLevel}'
                      : 'Sv ${data.definition.minLevel}-${data.definition.maxLevel}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Tur ${data.round}',
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final DailyChallengeData data;

  const _StreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return StudioCard(
      minHeight: 142,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 57,
                height: 57,
                decoration: BoxDecoration(
                  color: StudioVisuals.amberSoft.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 36,
                  color: StudioVisuals.amber,
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
                        color: StudioVisuals.ink,
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
                        color: StudioVisuals.muted,
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
                color: data.activeToday
                    ? StudioVisuals.teal
                    : StudioVisuals.amber,
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
        color: StudioVisuals.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StudioVisuals.ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StudioVisuals.muted,
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
    return StudioCard(
      minHeight: 112,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: progress.completed
                  ? StudioVisuals.tealSoft
                  : color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              progress.completed ? Icons.check_rounded : icon,
              color: progress.completed ? StudioVisuals.teal : color,
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
                          color: StudioVisuals.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${progress.shownCurrent}/${progress.task.target}',
                      style: TextStyle(
                        color: progress.completed
                            ? StudioVisuals.teal
                            : StudioVisuals.ink,
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
                    color: StudioVisuals.muted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress.ratio,
                    minHeight: 6,
                    backgroundColor: StudioVisuals.surfaceSoft,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress.completed ? StudioVisuals.teal : color,
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
        color: completed ? StudioVisuals.tealSoft : StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.workspace_premium_rounded
                : Icons.lock_clock_rounded,
            color: completed ? StudioVisuals.amber : StudioVisuals.muted,
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
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  completed
                      ? context.l10n.perfectDayEarned
                      : context.l10n.completeDailyCourse,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 10,
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
