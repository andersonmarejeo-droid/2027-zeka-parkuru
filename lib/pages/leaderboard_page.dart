import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_visual_theme.dart';
import '../theme/studio_visuals.dart';

import '../l10n/app_localizations.dart';
import 'challenge_center_page.dart';

import '../services/firebase_bootstrap_service.dart';
import '../services/game_audio_service.dart';
import '../services/online_leaderboard_service.dart';
import '../services/player_progress_service.dart';
import '../widgets/studio_card.dart';
import '../widgets/avatar_icon.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with WidgetsBindingObserver {
  final PlayerProgressService _player = PlayerProgressService.instance;

  final GameAudioService _audio = GameAudioService.instance;

  final OnlineLeaderboardService _online = OnlineLeaderboardService.instance;

  PlayerDashboardData? _data;
  OnlineLeaderboardResult? _onlineData;
  bool _loading = true;
  bool _refreshingSilently = false;
  bool _requestInFlight = false;
  bool _leavingPage = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_onlineData?.online == false || _onlineData?.syncPending == true)) {
      _load(silent: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;

    if (mounted) {
      setState(() {
        if (silent && _data != null) {
          _refreshingSilently = true;
        } else if (_data != null) {
          _loading = true;
        }
      });
    }

    try {
      final PlayerDashboardData data = await _player.load();

      if (_onlineData == null) {
        final OnlineLeaderboardResult cachedData = await _online
            .loadCachedGlobal();

        if (mounted && cachedData.fromCache) {
          setState(() {
            _data = data;
            _onlineData = cachedData;
            _loading = false;
            _refreshingSilently = true;
          });
        }
      }

      await _online.syncCurrentPlayer(data);

      final OnlineLeaderboardResult onlineData = await _online.fetchGlobal(
        limit: 30,
      );

      if (!mounted) return;

      setState(() {
        _data = data;
        _onlineData = onlineData;
        _loading = false;
        _refreshingSilently = false;
      });

      _scheduleReconnect(onlineData);
    } catch (error, stackTrace) {
      debugPrint('Leaderboard page load failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _loading = false;
          _refreshingSilently = false;
        });
      }

      if (_onlineData?.online == false) {
        _scheduleReconnect(_onlineData!);
      }
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> _retryNow() async {
    await FirebaseBootstrapService.instance.initialize(forceRetry: true);
    await _load(silent: _data != null);
  }

  Future<void> _returnHome() async {
    if (_leavingPage) return;
    setState(() => _leavingPage = true);

    try {
      await _audio.play(GameSound.uiClick);
    } catch (error) {
      debugPrint('Liderlik dönüş sesi atlandı: $error');
    }
    if (!mounted) return;

    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    setState(() => _leavingPage = false);
  }

  void _scheduleReconnect(OnlineLeaderboardResult result) {
    _retryTimer?.cancel();

    if ((result.online && !result.syncPending) ||
        !FirebaseBootstrapService.instance.configured) {
      return;
    }

    _retryTimer = Timer(const Duration(seconds: 15), () => _load(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    final PlayerDashboardData? data = _data;

    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.leaderboardCenter,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: StudioPageFrame(
        child: _loading || data == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: StudioVisuals.teal,
                backgroundColor: StudioVisuals.surface,
                onRefresh: _retryNow,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    StudioVisuals.pageGutter,
                    12,
                    StudioVisuals.pageGutter,
                    32,
                  ),
                  children: [
                    _LeagueHero(data: data),
                    const SizedBox(height: 12),
                    _SocialArenaCard(
                      onOpen: () async {
                        await _audio.play(GameSound.uiClick);
                        if (!context.mounted) return;
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ChallengeCenterPage(),
                          ),
                        );
                        if (mounted) _load(silent: true);
                      },
                    ),
                    const SizedBox(height: 12),
                    _GlobalLeaderboardSection(
                      data: _onlineData,
                      refreshing: _refreshingSilently,
                      onRetry: _retryNow,
                    ),
                    const SizedBox(height: 16),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: _leavingPage ? null : _returnHome,
                            style: FilledButton.styleFrom(
                              backgroundColor: StudioVisuals.teal,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.home_rounded),
                            label: Text(context.l10n.backHome),
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

class _SocialArenaCard extends StatelessWidget {
  final VoidCallback onOpen;

  const _SocialArenaCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return StudioCard(
      onTap: onOpen,
      semanticLabel: 'Arkadaşlar ve düellolar',
      minHeight: 88,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: const Row(
        children: [
          Icon(Icons.bolt_rounded, size: 34, color: StudioVisuals.amber),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARKADAŞLAR & DÜELLOLAR',
                  style: TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'WhatsApp daveti • arkadaş kodu • canlı skor',
                  style: TextStyle(color: StudioVisuals.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: StudioVisuals.ink),
        ],
      ),
    );
  }
}

class _LeagueHero extends StatelessWidget {
  final PlayerDashboardData data;

  const _LeagueHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    final double levelProgress = data.xpForNextLevel <= 0
        ? 1
        : (data.xpIntoLevel / data.xpForNextLevel).clamp(0.0, 1.0).toDouble();

    return StudioCard(
      minHeight: 154,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 67,
                height: 67,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StudioVisuals.tealSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: StudioVisuals.teal.withValues(alpha: 0.22),
                    width: 2,
                  ),
                ),
                child: AvatarIcon(
                  data.profile.avatar,
                  size: 67,
                  borderRadius: 33.5,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.profile.displayName,
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.levelValue(data.level),
                      style: const TextStyle(
                        color: StudioVisuals.teal,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: StudioVisuals.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${data.level}',
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      context.l10n.level.toUpperCase(),
                      style: TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                '${data.zekaScore} ${english ? 'points' : 'puan'}',
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                data.xpForNextLevel <= 0
                    ? (english ? 'Maximum level' : 'En yüksek seviye')
                    : english
                    ? '${data.xpForNextLevel - data.xpIntoLevel} to level ${data.level + 1}'
                    : 'Seviye ${data.level + 1} için ${data.xpForNextLevel - data.xpIntoLevel} puan',
                style: const TextStyle(color: StudioVisuals.muted, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 8,
              backgroundColor: StudioVisuals.surfaceSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                StudioVisuals.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Retained for the legacy leaderboard layout.
// ignore: unused_element
class _Podium extends StatelessWidget {
  final List<ParkurLeaderboardEntry> entries;
  final Color Function(String id) colorFor;

  const _Podium({required this.entries, required this.colorFor});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final ParkurLeaderboardEntry first = entries[0];
    final ParkurLeaderboardEntry? second = entries.length > 1
        ? entries[1]
        : null;
    final ParkurLeaderboardEntry? third = entries.length > 2
        ? entries[2]
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumItem(
            medal: '🥈',
            entry: second,
            color: second == null
                ? StudioVisuals.line
                : colorFor(second.gameId),
            height: 128,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumItem(
            medal: '🥇',
            entry: first,
            color: colorFor(first.gameId),
            height: 155,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumItem(
            medal: '🥉',
            entry: third,
            color: third == null ? StudioVisuals.line : colorFor(third.gameId),
            height: 112,
          ),
        ),
      ],
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final String medal;
  final ParkurLeaderboardEntry? entry;
  final Color color;
  final double height;

  const _PodiumItem({
    required this.medal,
    required this.entry,
    required this.color,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final ParkurLeaderboardEntry? item = entry;

    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: item == null
          ? const SizedBox.shrink()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(medal, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 3),
                Flexible(
                  child: Text(
                    context.l10n.gameTitle(item.gameId),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '⭐ ${item.stars}/30',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
                Text(
                  context.l10n.completedOutOf(item.completedLevels, 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 8,
                    height: 1.05,
                  ),
                ),
              ],
            ),
    );
  }
}

// Retained for the legacy leaderboard layout.
// ignore: unused_element
class _RankingRow extends StatelessWidget {
  final String position;
  final ParkurLeaderboardEntry entry;
  final Color color;

  const _RankingRow({
    required this.position,
    required this.entry,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (entry.stars / 30).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              position,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: StudioVisuals.surfaceSoft,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.l10n.completedAndLevel(
                    entry.completedLevels,
                    entry.unlockedLevel,
                  ),
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '⭐ ${entry.stars}',
                style: const TextStyle(
                  color: StudioVisuals.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              Text(
                context.l10n.points(entry.score),
                style: const TextStyle(color: StudioVisuals.muted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlobalLeaderboardSection extends StatelessWidget {
  final OnlineLeaderboardResult? data;
  final bool refreshing;
  final Future<void> Function() onRetry;

  const _GlobalLeaderboardSection({
    required this.data,
    required this.refreshing,
    required this.onRetry,
  });

  bool _isEnglish(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en';
  }

  int _competitionRank(List<OnlineLeaderboardEntry> entries, int index) {
    final int score = entries[index].score;
    int higherScorePlayers = 0;

    for (final OnlineLeaderboardEntry entry in entries) {
      if (entry.score > score) {
        higherScorePlayers++;
      }
    }

    return higherScorePlayers + 1;
  }

  @override
  Widget build(BuildContext context) {
    final OnlineLeaderboardResult? result = data;

    if (result == null || (!result.online && !result.fromCache)) {
      return _FirebaseOfflineCard(reason: result?.error, onRetry: onRetry);
    }

    final List<OnlineLeaderboardEntry> entries = result.entries;
    final bool english = _isEnglish(context);
    final bool cached = result.fromCache;
    final int? currentRank = result.currentRank;
    final int totalPlayers = result.totalPlayers ?? entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.worldRanking,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: (cached ? StudioVisuals.amber : StudioVisuals.teal)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: (cached ? StudioVisuals.amber : StudioVisuals.teal)
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cached ? Icons.cloud_off_rounded : Icons.circle,
                    color: cached ? StudioVisuals.amber : StudioVisuals.teal,
                    size: 7,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cached ? context.l10n.cached : context.l10n.online,
                    style: TextStyle(
                      color: cached ? StudioVisuals.amber : StudioVisuals.teal,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (cached) ...[
          _CachedLeaderboardNotice(
            cachedAt: result.cachedAt,
            syncPending: result.syncPending,
            refreshing: refreshing,
            onRetry: onRetry,
          ),
          const SizedBox(height: 10),
        ] else if (result.syncPending) ...[
          _PendingLeaderboardSyncNotice(
            refreshing: refreshing,
            onRetry: onRetry,
          ),
          const SizedBox(height: 10),
        ],
        _WorldRankSummaryCard(
          rank: currentRank,
          totalPlayers: totalPlayers,
          english: english,
        ),
        const SizedBox(height: 9),
        Text(
          context.l10n.leaderboardSyncInfo,
          style: const TextStyle(
            color: StudioVisuals.muted,
            fontSize: 9,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 11),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: StudioVisuals.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: StudioVisuals.line),
              boxShadow: StudioVisuals.softShadow,
            ),
            child: Text(
              context.l10n.noOnlinePlayers,
              textAlign: TextAlign.center,
              style: const TextStyle(color: StudioVisuals.muted, fontSize: 10),
            ),
          )
        else ...[
          Row(
            children: [
              Text(
                english ? 'TOP PLAYERS' : 'EN İYİ OYUNCULAR',
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                english ? '$totalPlayers players' : '$totalPlayers oyuncu',
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(entries.length > 20 ? 20 : entries.length, (index) {
            final OnlineLeaderboardEntry entry = entries[index];
            final int rank = _competitionRank(entries, index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _GlobalPlayerRow(
                rank: rank,
                entry: entry,
                isCurrent: entry.uid == result.currentUid,
              ),
            );
          }),
          if (currentRank != null &&
              entries.any((entry) => entry.uid == result.currentUid) &&
              !entries
                  .take(20)
                  .any((entry) => entry.uid == result.currentUid)) ...[
            const SizedBox(height: 2),
            Container(
              key: const ValueKey<String>(
                'leaderboard_current_player_separator',
              ),
              margin: const EdgeInsets.fromLTRB(12, 3, 12, 11),
              child: Row(
                children: <Widget>[
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      english ? 'YOUR RANK' : 'SIRALAMADAKİ YERİN',
                      style: const TextStyle(
                        color: StudioVisuals.teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _GlobalPlayerRow(
                rank: currentRank,
                entry: entries.firstWhere(
                  (entry) => entry.uid == result.currentUid,
                ),
                isCurrent: true,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _CachedLeaderboardNotice extends StatelessWidget {
  final DateTime? cachedAt;
  final bool syncPending;
  final bool refreshing;
  final Future<void> Function() onRetry;

  const _CachedLeaderboardNotice({
    required this.cachedAt,
    required this.syncPending,
    required this.refreshing,
    required this.onRetry,
  });

  String _cacheAge(BuildContext context) {
    final DateTime? savedAt = cachedAt?.toLocal();
    if (savedAt == null) return context.l10n.lastUpdateUnknown;

    final Duration difference = DateTime.now().difference(savedAt);
    if (difference.isNegative || difference.inMinutes < 1) {
      return context.l10n.updatedJustNow;
    }
    if (difference.inMinutes < 60) {
      return context.l10n.updatedMinutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return context.l10n.updatedHoursAgo(difference.inHours);
    }
    return context.l10n.updatedDaysAgo(difference.inDays);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 9, 11),
      decoration: BoxDecoration(
        color: StudioVisuals.amberSoft,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: StudioVisuals.amber.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.offline_bolt_rounded,
            color: StudioVisuals.amber,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.cachedLeaderboardInfo,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  syncPending
                      ? '${_cacheAge(context)}  •  ${context.l10n.scoreWaitingToSync}'
                      : _cacheAge(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.amber,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 36,
            height: 36,
            child: refreshing
                ? const Padding(
                    padding: EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StudioVisuals.amber,
                    ),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: context.l10n.retryNow,
                    onPressed: () {
                      onRetry();
                    },
                    icon: const Icon(
                      Icons.sync_rounded,
                      color: StudioVisuals.amber,
                      size: 21,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PendingLeaderboardSyncNotice extends StatelessWidget {
  final bool refreshing;
  final Future<void> Function() onRetry;

  const _PendingLeaderboardSyncNotice({
    required this.refreshing,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 9, 9, 9),
      decoration: BoxDecoration(
        color: StudioVisuals.amberSoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: StudioVisuals.amber.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            color: StudioVisuals.amber,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              context.l10n.scoreWaitingToSync,
              style: const TextStyle(
                color: StudioVisuals.ink,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: refreshing
                ? const Padding(
                    padding: EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StudioVisuals.amber,
                    ),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: context.l10n.retryNow,
                    onPressed: () {
                      onRetry();
                    },
                    icon: const Icon(
                      Icons.sync_rounded,
                      color: StudioVisuals.amber,
                      size: 20,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WorldRankSummaryCard extends StatelessWidget {
  final int? rank;
  final int totalPlayers;
  final bool english;

  const _WorldRankSummaryCard({
    required this.rank,
    required this.totalPlayers,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    final String rankText = rank == null ? '—' : '#$rank';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5F4F1), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StudioVisuals.teal.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudioVisuals.amberSoft,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.public_rounded,
              color: StudioVisuals.teal,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  english ? 'YOUR WORLD RANK' : 'DÜNYA SIRALAMAN',
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rankText,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: StudioVisuals.surface.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalPlayers',
                  style: const TextStyle(
                    color: StudioVisuals.teal,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  english ? 'PLAYERS' : 'OYUNCU',
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  english ? 'BY BRAIN SCORE' : 'ZEKA PUANI BAZLI',
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
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

class _GlobalPlayerRow extends StatelessWidget {
  final int rank;
  final OnlineLeaderboardEntry entry;
  final bool isCurrent;

  const _GlobalPlayerRow({
    required this.rank,
    required this.entry,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final String position = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank.',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent ? StudioVisuals.tealSoft : StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(
          color: isCurrent
              ? StudioVisuals.teal.withValues(alpha: 0.38)
              : StudioVisuals.line,
        ),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              position,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: rank <= 3 ? 20 : 14,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudioVisuals.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: AvatarIcon(entry.avatar, size: 48, borderRadius: 14),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: StudioVisuals.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          context.l10n.you,
                          style: const TextStyle(
                            color: StudioVisuals.teal,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.levelValue(entry.level),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score} ${context.l10n.isEnglish ? 'BP' : 'ZP'}',
                style: const TextStyle(
                  color: StudioVisuals.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FirebaseOfflineCard extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String? reason;

  const _FirebaseOfflineCard({required this.onRetry, required this.reason});

  @override
  Widget build(BuildContext context) {
    final bool configured = FirebaseBootstrapService.instance.configured;
    final bool english = Localizations.localeOf(context).languageCode == 'en';

    final String? diagnostic =
        reason ?? FirebaseBootstrapService.instance.lastError;
    final String message = configured
        ? (english
              ? 'The world ranking could not be reached yet. It will retry automatically when the connection returns.'
              : diagnostic?.trim().isNotEmpty == true
              ? diagnostic!
              : 'Dünya sıralamasına henüz ulaşılamadı. Bağlantı geldiğinde otomatik olarak yeniden denenecek.')
        : context.l10n.firebaseSetupNeeded;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: StudioVisuals.amberSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              configured ? Icons.cloud_off_rounded : Icons.cloud_sync_rounded,
              color: StudioVisuals.amber,
              size: 29,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.worldFriendsLeaderboard,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: StudioVisuals.amberSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        context.l10n.offline,
                        style: const TextStyle(
                          color: StudioVisuals.amber,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),
                if (configured) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        onRetry();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: Text(
                        english ? 'TRY AGAIN' : 'YENİDEN DENE',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
