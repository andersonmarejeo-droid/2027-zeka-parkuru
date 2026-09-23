import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_visual_theme.dart';

import '../l10n/app_localizations.dart';
import 'challenge_center_page.dart';

import '../services/firebase_bootstrap_service.dart';
import '../services/game_audio_service.dart';
import '../services/online_leaderboard_service.dart';
import '../services/player_progress_service.dart';

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

  String _medal(int index) {
    if (index == 0) return '🥇';
    if (index == 1) return '🥈';
    if (index == 2) return '🥉';
    return '${index + 1}.';
  }

  @override
  Widget build(BuildContext context) {
    final PlayerDashboardData? data = _data;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.leaderboardCenter,
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.6),
        ),
      ),
      body: _loading || data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _retryNow,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
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
                  const SizedBox(height: 18),
                  Text(
                    context.l10n.personalPodium,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.l10n.podiumDescription,
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 13),
                  _Podium(
                    entries: data.parkurRanking.take(3).toList(),
                    colorFor: _gameColor,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.fiveCourseRanking,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${data.progress.toplamYildiz}/330 ⭐',
                        style: const TextStyle(
                          color: Color(0xFFFFD334),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(data.parkurRanking.length, (index) {
                    final ParkurLeaderboardEntry entry =
                        data.parkurRanking[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RankingRow(
                        position: _medal(index),
                        entry: entry,
                        color: _gameColor(entry.gameId),
                      ),
                    );
                  }),
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
                          icon: const Icon(Icons.home_rounded),
                          label: Text(context.l10n.backHome),
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

class _SocialArenaCard extends StatelessWidget {
  final VoidCallback onOpen;

  const _SocialArenaCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5C42E8), Color(0xFF0D8FA9)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 34),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARKADAŞLAR & DÜELLOLAR',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'WhatsApp daveti • arkadaş kodu • canlı skor',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeagueHero extends StatelessWidget {
  final PlayerDashboardData data;

  const _LeagueHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final String nextText = data.nextLeague == null
        ? context.l10n.highestLeague
        : context.l10n.nextLeague(
            context.l10n.leagueLabel(data.nextLeague!.shortName),
            data.nextLeague!.minXp,
          );

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF472DB7), Color(0xFF155CC8), Color(0xFF0A9DB7)],
        ),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 67,
                height: 67,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Text(
                  data.profile.avatar,
                  style: const TextStyle(fontSize: 35),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.profile.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.rankLabel(data.rankTitle),
                      style: const TextStyle(
                        color: Color(0xFFFFD334),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.l10n.leagueLabel(data.league.shortName),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
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
                  color: Colors.black.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${data.level}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      context.l10n.level.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                '${data.zekaScore} ${context.l10n.isEnglish ? 'BP' : 'ZP'}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                nextText,
                style: const TextStyle(color: Colors.white60, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: data.leagueProgress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFD334),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroStat(
                value: '${data.zekaScore}',
                title: context.l10n.mindScore,
              ),
              const SizedBox(width: 8),
              _HeroStat(
                value: '${data.progress.toplamYildiz}/330',
                title: context.l10n.stars.toUpperCase(),
              ),
              const SizedBox(width: 8),
              _HeroStat(
                value: '${data.progress.tamamlananSeviye}/110',
                title: context.l10n.completedLevels.toUpperCase(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String title;

  const _HeroStat({required this.value, required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w800,
                fontSize: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            color: second == null ? Colors.white24 : colorFor(second.gameId),
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
            color: third == null ? Colors.white24 : colorFor(third.gameId),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(20),
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
                      fontSize: 10,
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
                    fontSize: 9,
                  ),
                ),
                Text(
                  context.l10n.completedOutOf(item.completedLevels, 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 7,
                    height: 1.05,
                  ),
                ),
              ],
            ),
    );
  }
}

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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(19),
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
            width: 43,
            height: 43,
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
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.l10n.completedAndLevel(
                    entry.completedLevels,
                    entry.unlockedLevel,
                  ),
                  style: const TextStyle(color: Colors.white54, fontSize: 8),
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
                  color: Color(0xFFFFD334),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              Text(
                context.l10n.points(entry.score),
                style: const TextStyle(color: Colors.white54, fontSize: 8),
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
                color:
                    (cached ? const Color(0xFFFFA726) : const Color(0xFF52E86B))
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color:
                      (cached
                              ? const Color(0xFFFFA726)
                              : const Color(0xFF52E86B))
                          .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cached ? Icons.cloud_off_rounded : Icons.circle,
                    color: cached
                        ? const Color(0xFFFFA726)
                        : const Color(0xFF52E86B),
                    size: 7,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cached ? context.l10n.cached : context.l10n.online,
                    style: TextStyle(
                      color: cached
                          ? const Color(0xFFFFA726)
                          : const Color(0xFF52E86B),
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
            color: Colors.white54,
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
              color: const Color(0xFF0D213F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              context.l10n.noOnlinePlayers,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          )
        else ...[
          Row(
            children: [
              Text(
                english ? 'TOP PLAYERS' : 'EN İYİ OYUNCULAR',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                english ? '$totalPlayers players' : '$totalPlayers oyuncu',
                style: const TextStyle(
                  color: Colors.white38,
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
                        color: Color(0xFF00D9FF),
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
        color: const Color(0xFFFFA726).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFFFA726).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.offline_bolt_rounded,
            color: Color(0xFFFFA726),
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
                    color: Colors.white70,
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
                    color: Color(0xFFFFC56D),
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
                      color: Color(0xFFFFA726),
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
                      color: Color(0xFFFFA726),
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
        color: const Color(0xFFFFA726).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFA726).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            color: Color(0xFFFFA726),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              context.l10n.scoreWaitingToSync,
              style: const TextStyle(
                color: Colors.white70,
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
                      color: Color(0xFFFFA726),
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
                      color: Color(0xFFFFA726),
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
          colors: [Color(0xFF153455), Color(0xFF23315E)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF00D9FF).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD334).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.public_rounded,
              color: Color(0xFFFFD334),
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
                    color: Colors.white60,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rankText,
                  style: const TextStyle(
                    color: Color(0xFFFFD334),
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
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalPlayers',
                  style: const TextStyle(
                    color: Color(0xFF52E86B),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  english ? 'PLAYERS' : 'OYUNCU',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  english ? 'BY BRAIN SCORE' : 'ZEKA PUANI BAZLI',
                  style: const TextStyle(
                    color: Colors.white30,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isCurrent
            ? const LinearGradient(
                colors: [Color(0xFF1B3C67), Color(0xFF3D2F74)],
              )
            : null,
        color: isCurrent ? null : ZpVisualPalette.of(context).surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF00D9FF).withValues(alpha: 0.55)
              : Colors.white10,
        ),
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
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(entry.avatar, style: const TextStyle(fontSize: 25)),
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
                          fontSize: 12,
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
                          color: const Color(0xFF00D9FF)
                              .withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          context.l10n.you,
                          style: const TextStyle(
                            color: Color(0xFF00D9FF),
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${context.l10n.leagueLabel(entry.leagueShortName)}'
                  '  •  ${context.l10n.levelValue(entry.level)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 8),
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
                  color: Color(0xFFFFD334),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              Text(
                '⭐ ${entry.stars}  •  ${entry.completedLevels}/110',
                style: const TextStyle(color: Colors.white54, fontSize: 8),
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
        color: const Color(0xFF0D213F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              configured ? Icons.cloud_off_rounded : Icons.cloud_sync_rounded,
              color: const Color(0xFFFFA726),
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
                        color: const Color(0xFFFFA726).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        context.l10n.offline,
                        style: const TextStyle(
                          color: Color(0xFFFFA726),
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
                    color: Colors.white54,
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
