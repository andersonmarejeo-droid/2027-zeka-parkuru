import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/studio_visuals.dart';

import '../l10n/app_localizations.dart';

import 'first_run_profile_page.dart';

import '../services/app_analytics_service.dart';
import '../services/game_audio_service.dart';
import '../services/online_leaderboard_service.dart';
import '../services/player_profile_service.dart';
import '../services/player_progress_service.dart';
import '../widgets/studio_card.dart';
import '../widgets/avatar_icon.dart';

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

  Future<void> _editProfile() async {
    final PlayerDashboardData? current = _data;
    if (current == null) return;

    final _ProfileEditResult? result =
        await showModalBottomSheet<_ProfileEditResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: StudioVisuals.surface,
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
    final List<PlayerAchievementData> regularAchievements =
        data?.regularAchievements ?? const <PlayerAchievementData>[];

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.profileTitle,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
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
      body: StudioPageFrame(
        child: _loading || data == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
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
                    _ProfileHero(data: data, onEdit: _editProfile),
                    const SizedBox(height: 12),
                    _GamePreferencesTile(onTap: _openGamePreferences),
                    const SizedBox(height: 15),
                    _XpCard(data: data),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.isEnglish
                                ? 'Main game badges'
                                : 'Ana parkur rozetleri',
                            style: const TextStyle(
                              color: StudioVisuals.ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        Text(
                          '${data.unlockedRegularAchievementCount}/8',
                          style: const TextStyle(
                            color: StudioVisuals.teal,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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
                            mainAxisExtent: 142,
                          ),
                      itemBuilder: (context, index) {
                        return _AchievementCard(
                          item: regularAchievements[index],
                        );
                      },
                    ),
                  ],
                ),
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

    return StudioCard(
      onTap: onTap,
      semanticLabel: isTurkish ? 'Oyun Tercihleri' : 'Game Preferences',
      minHeight: 88,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: StudioVisuals.amberSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tune_rounded, color: StudioVisuals.amber),
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
                    color: StudioVisuals.ink,
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
                    color: StudioVisuals.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: StudioVisuals.ink),
        ],
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
                  color: StudioVisuals.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                context.l10n.playerName,
                style: const TextStyle(
                  color: StudioVisuals.muted,
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
                style: const TextStyle(color: StudioVisuals.ink),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: StudioVisuals.surfaceSoft,
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: StudioVisuals.line),
                  ),
                  hintText: context.l10n.playerNameHint,
                  hintStyle: const TextStyle(color: StudioVisuals.muted),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.avatar,
                style: const TextStyle(
                  color: StudioVisuals.muted,
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
                            ? StudioVisuals.tealSoft
                            : StudioVisuals.surfaceSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? StudioVisuals.teal
                              : StudioVisuals.line,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: AvatarIcon(avatar, size: 54, borderRadius: 14),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: StudioVisuals.teal,
                    foregroundColor: Colors.white,
                  ),
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
    return StudioCard(
      minHeight: 118,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudioVisuals.tealSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: StudioVisuals.teal.withValues(alpha: 0.22),
                width: 2,
              ),
            ),
            child: AvatarIcon(data.profile.avatar, size: 82, borderRadius: 41),
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
                    color: StudioVisuals.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
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
                      color: StudioVisuals.surfaceSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          size: 13,
                          color: StudioVisuals.ink,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.edit,
                          style: const TextStyle(
                            color: StudioVisuals.ink,
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
    final double progress = data.xpForNextLevel <= 0
        ? 1.0
        : (data.xpIntoLevel / data.xpForNextLevel).clamp(0.0, 1.0).toDouble();
    final bool english = context.l10n.isEnglish;

    return StudioCard(
      minHeight: 96,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: StudioVisuals.teal),
              const SizedBox(width: 8),
              Text(
                english ? 'OVERALL SCORE' : 'GENEL PUAN',
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.levelValue(data.level),
                style: const TextStyle(
                  color: StudioVisuals.teal,
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
              backgroundColor: StudioVisuals.surfaceSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                StudioVisuals.teal,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '${data.zekaScore} ${english ? 'points' : 'puan'}',
                style: const TextStyle(color: StudioVisuals.muted, fontSize: 9),
              ),
              const Spacer(),
              Text(
                data.xpForNextLevel <= 0
                    ? (english ? 'Maximum level' : 'En yüksek seviye')
                    : english
                    ? '${data.xpForNextLevel - data.xpIntoLevel} points to level ${data.level + 1}'
                    : 'Seviye ${data.level + 1} için ${data.xpForNextLevel - data.xpIntoLevel} puan',
                style: const TextStyle(
                  color: StudioVisuals.ink,
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

// Retained for legacy profile snapshots.
// ignore: unused_element
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
        color: StudioVisuals.teal,
      ),
      _StatItemData(
        icon: Icons.star_rounded,
        value: '${data.progress.toplamYildiz}/330',
        title: context.l10n.uppercaseLabel(context.l10n.stars),
        color: StudioVisuals.amber,
      ),
      _StatItemData(
        icon: Icons.flag_rounded,
        value: '${data.progress.tamamlananSeviye}/110',
        title: context.l10n.uppercaseLabel(context.l10n.completedLevels),
        color: StudioVisuals.teal,
      ),
      _StatItemData(
        icon: Icons.local_fire_department_rounded,
        value: '${data.daily.currentStreak}',
        title: context.l10n.streak,
        color: StudioVisuals.amber,
      ),
      _StatItemData(
        icon: Icons.emoji_events_rounded,
        value: '${data.daily.bestStreak}',
        title: context.l10n.bestStreak,
        color: StudioVisuals.teal,
      ),
      _StatItemData(
        icon: Icons.workspace_premium_rounded,
        value: '${data.daily.perfectDays}',
        title: context.l10n.perfectDay,
        color: StudioVisuals.muted,
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
        mainAxisExtent: 100,
      ),
      itemBuilder: (context, index) {
        final _StatItemData item = stats[index];

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: StudioVisuals.surface,
            borderRadius: StudioVisuals.compactRadius,
            border: Border.all(color: StudioVisuals.line),
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
                  color: StudioVisuals.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 8,
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

// Retained for legacy profile snapshots.
// ignore: unused_element
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

    return StudioCard(
      minHeight: 120,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.hub_rounded,
                color: StudioVisuals.teal,
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  english ? 'ONE SCORE, ONE RANKING' : 'TEK PUAN, TEK SIRALAMA',
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${data.zekaScore} ${english ? 'BP' : 'ZP'}',
                style: const TextStyle(
                  color: StudioVisuals.amber,
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
              style: const TextStyle(color: StudioVisuals.muted, fontSize: 10),
            ),
          ),
          Text(
            '+$value',
            style: const TextStyle(
              color: StudioVisuals.ink,
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

// Retained for legacy profile snapshots.
// ignore: unused_element
class _SpecialBadgeCard extends StatelessWidget {
  final PlayerAchievementData item;

  const _SpecialBadgeCard({required this.item});

  Color _accentColor() {
    switch (item.id) {
      case 'shape_scout':
        return StudioVisuals.teal;
      case 'shape_master':
        return StudioVisuals.muted;
      case 'daily_course_1':
        return StudioVisuals.amber;
      case 'daily_course_7':
        return StudioVisuals.teal;
      default:
        return StudioVisuals.amber;
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
              ? <Color>[accent.withValues(alpha: 0.10), StudioVisuals.surface]
              : const <Color>[StudioVisuals.surfaceSoft, StudioVisuals.surface],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: unlocked ? accent.withValues(alpha: 0.38) : StudioVisuals.line,
        ),
        boxShadow: StudioVisuals.softShadow,
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
                      : StudioVisuals.surfaceSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: unlocked
                        ? accent.withValues(alpha: 0.55)
                        : StudioVisuals.line,
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
                      : StudioVisuals.surfaceSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  english ? 'RARE' : 'ÖZEL',
                  style: TextStyle(
                    color: unlocked ? accent : StudioVisuals.muted,
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
            context.l10n.isEnglish ? (item.titleEn ?? item.title) : item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? StudioVisuals.ink : StudioVisuals.muted,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            context.l10n.isEnglish
                ? (item.descriptionEn ?? item.description)
                : item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: StudioVisuals.muted,
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
                    backgroundColor: StudioVisuals.line,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      unlocked ? accent : StudioVisuals.line,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '${item.current > item.target ? item.target : item.current}/${item.target}',
                style: TextStyle(
                  color: unlocked ? accent : StudioVisuals.muted,
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
        color: unlocked ? StudioVisuals.tealSoft : StudioVisuals.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: unlocked
              ? StudioVisuals.amber.withValues(alpha: 0.42)
              : StudioVisuals.line,
        ),
        boxShadow: StudioVisuals.softShadow,
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
                  color: StudioVisuals.teal,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.isEnglish ? (item.titleEn ?? item.title) : item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? StudioVisuals.ink : StudioVisuals.muted,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            context.l10n.isEnglish
                ? (item.descriptionEn ?? item.description)
                : item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: StudioVisuals.muted,
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
              backgroundColor: StudioVisuals.line,
              valueColor: AlwaysStoppedAnimation<Color>(
                unlocked ? StudioVisuals.amber : StudioVisuals.line,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.current > item.target ? item.target : item.current}/${item.target}',
            style: TextStyle(
              color: unlocked ? StudioVisuals.ink : StudioVisuals.muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// Retained for legacy profile snapshots.
// ignore: unused_element
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
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
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
                        color: StudioVisuals.muted,
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
              backgroundColor: StudioVisuals.line,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '⭐ ${entry.stars}/30',
                style: const TextStyle(
                  color: StudioVisuals.amber,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.completedOutOf(entry.completedLevels, 10),
                style: const TextStyle(color: StudioVisuals.muted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
