import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_visual_theme.dart';

import '../l10n/app_localizations.dart';

import 'first_run_profile_page.dart';

import '../services/app_analytics_service.dart';
import '../services/game_audio_service.dart';
import '../services/online_leaderboard_service.dart';
import '../services/player_profile_service.dart';
import '../services/player_progress_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final PlayerProgressService _player = PlayerProgressService.instance;

  final PlayerProfileService _profile = PlayerProfileService.instance;

  final GameAudioService _audio = GameAudioService.instance;

  final OnlineLeaderboardService _online = OnlineLeaderboardService.instance;

  final AppAnalyticsService _analytics = AppAnalyticsService.instance;

  PlayerDashboardData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final PlayerDashboardData data = await _player.load();

    unawaited(_online.syncCurrentPlayer(data));

    if (!mounted) return;

    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Color _gameColor(String id) {
    switch (id) {
      case 'logic':
        return const Color(0xFF8A4FFF);
      case 'numbers':
        return const Color(0xFF39B54A);
      case 'blocks':
        return const Color(0xFF168CFF);
      case 'memory':
        return const Color(0xFFE748CF);
      case 'hanoi':
        return const Color(0xFFFF5A3C);
      case 'word_hunt':
        return const Color(0xFF00D9A6);
      case 'picture_iq':
        return const Color(0xFFFF4FA3);
      case 'candy_sort':
        return const Color(0xFFFF8A3D);
      case 'number_sort':
        return const Color(0xFFFFD334);
      case 'shape_puzzle':
        return const Color(0xFF8C6CFF);
      case 'reflex':
        return const Color(0xFFFF5B5B);
      default:
        return const Color(0xFF00D9FF);
    }
  }

  Future<void> _editProfile() async {
    final PlayerDashboardData? current = _data;
    if (current == null) return;

    final _ProfileEditResult? result =
        await showModalBottomSheet<_ProfileEditResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: ZpVisualPalette.of(context).surface,
          showDragHandle: true,
          builder: (sheetContext) {
            return _ProfileEditSheet(
              initialName: current.profile.displayName,
              initialAvatar: current.profile.avatar,
            );
          },
        );

    if (!mounted || result == null) return;

    await _profile.save(displayName: result.displayName, avatar: result.avatar);

    unawaited(_analytics.logProfileEdit());

    await _audio.play(GameSound.uiUnlock);

    if (!mounted) return;
    await _load();
  }

  Future<void> _openGamePreferences() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const FirstRunProfilePage.edit()),
    );

    if (!mounted || saved != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.localeOf(context).languageCode.toLowerCase() == 'tr'
              ? 'Oyun tercihlerin kaydedildi.'
              : 'Your game preferences were saved.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PlayerDashboardData? data = _data;
    final List<PlayerAchievementData> specialAchievements =
        data?.specialAchievements ?? const <PlayerAchievementData>[];
    final List<PlayerAchievementData> regularAchievements =
        data?.regularAchievements ?? const <PlayerAchievementData>[];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.profileTitle,
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.7),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.editProfile,
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: _loading || data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  _ProfileHero(data: data, onEdit: _editProfile),
                  const SizedBox(height: 12),
                  _GamePreferencesTile(onTap: _openGamePreferences),
                  const SizedBox(height: 15),
                  _XpCard(data: data),
                  const SizedBox(height: 15),
                  _StatsGrid(data: data),
                  const SizedBox(height: 15),
                  _ScoreBreakdownCard(data: data),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.specialBadges,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 0.35,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD334)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: const Color(0xFFFFD334)
                                .withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(
                          '${data.unlockedSpecialAchievementCount}/${specialAchievements.length}',
                          style: const TextStyle(
                            color: Color(0xFFFFD334),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.l10n.specialBadgesInfo,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 11),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: specialAchievements.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 174,
                        ),
                    itemBuilder: (context, index) {
                      return _SpecialBadgeCard(
                        item: specialAchievements[index],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.achievements,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${data.unlockedRegularAchievementCount}/${regularAchievements.length}',
                        style: const TextStyle(
                          color: Color(0xFFFFD334),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.l10n.achievementsInfo,
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 11),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: regularAchievements.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 152,
                        ),
                    itemBuilder: (context, index) {
                      return _AchievementCard(item: regularAchievements[index]);
                    },
                  ),
                  const SizedBox(height: 23),
                  Text(
                    context.l10n.courseStats,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ...data.parkurRanking.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GameStatsCard(
                        entry: entry,
                        color: _gameColor(entry.gameId),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _GamePreferencesTile extends StatelessWidget {
  const _GamePreferencesTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isTurkish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'tr';

    return Material(
      color: const Color(0xFFFF7200).withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFF7200).withValues(alpha: 0.34),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7200),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      isTurkish ? 'Oyun Tercihleri' : 'Game Preferences',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isTurkish
                          ? 'Yaş grubunu ve oyun hedefini güncelle'
                          : 'Update your age group and game goal',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFFFA14D)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEditResult {
  final String displayName;
  final String avatar;

  const _ProfileEditResult({required this.displayName, required this.avatar});
}

class _ProfileEditSheet extends StatefulWidget {
  final String initialName;
  final String initialAvatar;

  const _ProfileEditSheet({
    required this.initialName,
    required this.initialAvatar,
  });

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _controller;
  late String _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _selectedAvatar = widget.initialAvatar;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      _ProfileEditResult(
        displayName: _controller.text,
        avatar: _selectedAvatar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          5,
          18,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.editProfile,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                context.l10n.playerName,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _controller,
                maxLength: 18,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: context.l10n.playerNameHint,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.avatar,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: PlayerProfileService.avatars.map((avatar) {
                  final bool selected = avatar == _selectedAvatar;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatar;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF7655FF).withValues(alpha: 0.23)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF7655FF)
                              : Colors.white12,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(avatar, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(context.l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final PlayerDashboardData data;
  final VoidCallback onEdit;

  const _ProfileHero({required this.data, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF302875), Color(0xFF5D2EC4), Color(0xFFB52CA4)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Text(
              data.profile.avatar,
              style: const TextStyle(fontSize: 43),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.rankLabel(data.rankTitle),
                  style: const TextStyle(
                    color: Color(0xFFFFD334),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.l10n.leagueLabel(data.league.shortName)}  •  ${context.l10n.levelValue(data.level)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 13),
                        SizedBox(width: 4),
                        Text(
                          context.l10n.edit,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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

class _XpCard extends StatelessWidget {
  final PlayerDashboardData data;

  const _XpCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final double progress = data.level >= 50
        ? 1.0
        : (data.xpIntoLevel / data.xpForNextLevel).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00D9FF)),
              const SizedBox(width: 8),
              Text(
                context.l10n.playerLevel,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'LV. ${data.level}',
                style: const TextStyle(
                  color: Color(0xFF00D9FF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00D9FF),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                context.l10n.totalXp(data.zekaScore),
                style: const TextStyle(color: Colors.white54, fontSize: 9),
              ),
              const Spacer(),
              Text(
                data.level >= 50
                    ? context.l10n.maxLevel
                    : '${data.xpIntoLevel}/${data.xpForNextLevel} ZP',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final PlayerDashboardData data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final List<_StatItemData> stats = <_StatItemData>[
      _StatItemData(
        icon: Icons.stars_rounded,
        value: '${data.zekaScore}',
        title: context.l10n.mindScore,
        color: const Color(0xFF00D9FF),
      ),
      _StatItemData(
        icon: Icons.star_rounded,
        value: '${data.progress.toplamYildiz}/330',
        title: context.l10n.stars.toUpperCase(),
        color: const Color(0xFFFFD334),
      ),
      _StatItemData(
        icon: Icons.flag_rounded,
        value: '${data.progress.tamamlananSeviye}/110',
        title: context.l10n.completedLevels.toUpperCase(),
        color: const Color(0xFF76FF03),
      ),
      _StatItemData(
        icon: Icons.local_fire_department_rounded,
        value: '${data.daily.currentStreak}',
        title: context.l10n.streak,
        color: const Color(0xFFFF7900),
      ),
      _StatItemData(
        icon: Icons.emoji_events_rounded,
        value: '${data.daily.bestStreak}',
        title: context.l10n.bestStreak,
        color: const Color(0xFFE748CF),
      ),
      _StatItemData(
        icon: Icons.workspace_premium_rounded,
        value: '${data.daily.perfectDays}',
        title: context.l10n.perfectDay,
        color: const Color(0xFFB06CFF),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        mainAxisExtent: 91,
      ),
      itemBuilder: (context, index) {
        final _StatItemData item = stats[index];

        return Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: ZpVisualPalette.of(context).surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: item.color.withValues(alpha: 0.20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color, size: 21),
              const SizedBox(height: 4),
              Text(
                item.value,
                maxLines: 1,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreBreakdownCard extends StatelessWidget {
  final PlayerDashboardData data;

  const _ScoreBreakdownCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final breakdown = data.scoreBreakdown;
    final bool english = context.l10n.isEnglish;
    final int coursePoints =
        breakdown.levelPoints + breakdown.starPoints + breakdown.bossPoints;
    final int dailyPoints =
        breakdown.dailyCoursePoints +
        breakdown.streakPoints +
        breakdown.perfectDayPoints;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0D213F),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFF00D9FF).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: Color(0xFF00D9FF), size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  english ? 'ONE SCORE, ONE RANKING' : 'TEK PUAN, TEK SIRALAMA',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${data.zekaScore} ${english ? 'BP' : 'ZP'}',
                style: const TextStyle(
                  color: Color(0xFFFFD334),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _ScoreBreakdownRow(
            label: english ? 'Course progress' : 'Parkur ilerlemesi',
            value: coursePoints,
          ),
          _ScoreBreakdownRow(
            label: english ? 'Course variety' : 'Parkur çeşitliliği',
            value: breakdown.varietyPoints,
          ),
          _ScoreBreakdownRow(
            label: english ? 'Daily consistency' : 'Günlük düzen',
            value: dailyPoints,
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdownRow extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreBreakdownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ),
          Text(
            '+$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItemData {
  final IconData icon;
  final String value;
  final String title;
  final Color color;

  const _StatItemData({
    required this.icon,
    required this.value,
    required this.title,
    required this.color,
  });
}

class _SpecialBadgeCard extends StatelessWidget {
  final PlayerAchievementData item;

  const _SpecialBadgeCard({required this.item});

  Color _accentColor() {
    switch (item.id) {
      case 'shape_scout':
        return const Color(0xFF00D9FF);
      case 'shape_master':
        return const Color(0xFFE748CF);
      case 'daily_course_1':
        return const Color(0xFFFF9F1C);
      case 'daily_course_7':
        return const Color(0xFFB06CFF);
      default:
        return const Color(0xFFFFD334);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool unlocked = item.unlocked;
    final Color accent = _accentColor();
    final bool english = context.l10n.isEnglish;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: unlocked
              ? <Color>[
                  accent.withValues(alpha: 0.24),
                  const Color(0xFF142D54),
                  const Color(0xFF0B1C37),
                ]
              : const <Color>[Color(0xFF101E35), Color(0xFF081426)],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: unlocked ? accent.withValues(alpha: 0.68) : Colors.white10,
        ),
        boxShadow: unlocked
            ? <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.16),
                  blurRadius: 19,
                  spreadRadius: -9,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: unlocked
                      ? accent.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: unlocked
                        ? accent.withValues(alpha: 0.55)
                        : Colors.white10,
                  ),
                ),
                child: Text(
                  unlocked ? item.emoji : '🔒',
                  style: const TextStyle(fontSize: 23),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: unlocked
                      ? accent.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  english ? 'RARE' : 'ÖZEL',
                  style: TextStyle(
                    color: unlocked ? accent : Colors.white24,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.achievementTitle(item.id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            context.l10n.achievementDescription(item.id),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? Colors.white60 : Colors.white24,
              fontSize: 8,
              height: 1.25,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 5,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      unlocked ? accent : Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '${item.current > item.target ? item.target : item.current}/${item.target}',
                style: TextStyle(
                  color: unlocked ? accent : Colors.white30,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final PlayerAchievementData item;

  const _AchievementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool unlocked = item.unlocked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFF142D54) : const Color(0xFF0B1A31),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: unlocked
              ? const Color(0xFFFFD334).withValues(alpha: 0.45)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                unlocked ? item.emoji : '🔒',
                style: const TextStyle(fontSize: 26),
              ),
              const Spacer(),
              if (unlocked)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF52E86B),
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.achievementTitle(item.id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            context.l10n.achievementDescription(item.id),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? Colors.white54 : Colors.white24,
              fontSize: 8,
              height: 1.25,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 5,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                unlocked ? const Color(0xFFFFD334) : Colors.white24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.current > item.target ? item.target : item.current}/${item.target}',
            style: TextStyle(
              color: unlocked ? Colors.white70 : Colors.white30,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameStatsCard extends StatelessWidget {
  final ParkurLeaderboardEntry entry;
  final Color color;

  const _GameStatsCard({required this.entry, required this.color});

  @override
  Widget build(BuildContext context) {
    final double progress = (entry.stars / 30).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.psychology_alt_rounded, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.gameTitle(entry.gameId),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.openLevel(entry.unlockedLevel),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${entry.score}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '⭐ ${entry.stars}/30',
                style: const TextStyle(
                  color: Color(0xFFFFD334),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.completedOutOf(entry.completedLevels, 10),
                style: const TextStyle(color: Colors.white54, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
