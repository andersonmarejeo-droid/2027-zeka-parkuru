import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/studio_visuals.dart';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../games/reflex/reflex_game_page.dart';
import '../services/challenge_run_progress_service.dart';
import '../services/daily_course_service.dart';
import 'challenge_game_catalog.dart';
import '../services/online_leaderboard_service.dart';
import '../services/player_progress_service.dart';
import '../services/social_challenge_service.dart';
import '../services/social_notification_service.dart';
import '../widgets/champion_celebration_card.dart';
import '../widgets/competition_exit_decision.dart';
import '../widgets/competition_stage_transition.dart';
import '../widgets/studio_card.dart';
import '../widgets/avatar_icon.dart';

class ChallengeCenterPage extends StatefulWidget {
  final String? initialChallengeId;

  const ChallengeCenterPage({super.key, this.initialChallengeId});

  @override
  State<ChallengeCenterPage> createState() => _ChallengeCenterPageState();
}

class _ChallengeCenterPageState extends State<ChallengeCenterPage> {
  final SocialChallengeService _challenges = SocialChallengeService.instance;
  final OnlineLeaderboardService _leaderboard =
      OnlineLeaderboardService.instance;
  final PlayerProgressService _player = PlayerProgressService.instance;
  final TextEditingController _friendCodeController = TextEditingController();

  OnlineLeaderboardResult? _world;
  Stream<List<SocialChallenge>>? _challengeStream;
  Stream<List<String>>? _friendStream;
  Future<List<OnlineLeaderboardEntry>>? _friendProfilesFuture;
  String _friendProfilesKey = '';
  bool _loading = true;
  bool _online = false;
  bool _busy = false;
  bool _initializing = false;
  bool _initialChallengeOpened = false;
  String? _offlineReason;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  Future<void> _initialize({bool forceRetry = false}) async {
    if (_initializing) return;
    _initializing = true;
    final bool preserveCurrentView =
        !_loading && _online && _challengeStream != null;
    try {
      final bool online = await _challenges.ensureOnline(
        forceRetry: forceRetry,
      );
      if (!online) {
        if (!mounted) return;
        if (preserveCurrentView) {
          _message('Yenileme tamamlanamadı. Mevcut ekran korunuyor.');
        } else {
          setState(() {
            _online = false;
            _offlineReason = _challenges.lastError;
            _world = null;
            _challengeStream = null;
            _friendStream = null;
            _friendProfilesFuture = null;
            _friendProfilesKey = '';
            _loading = false;
          });
        }
        return;
      }
      final PlayerDashboardData dashboard = await _player.load();
      await _leaderboard.syncCurrentPlayer(dashboard);
      final OnlineLeaderboardResult world = await _leaderboard.fetchGlobal(
        limit: 30,
      );
      await SocialNotificationService.instance.enableNotifications();
      if (!mounted) return;
      setState(() {
        _online = true;
        _offlineReason = null;
        _world = world;
        _challengeStream = _challenges.watchMyChallenges();
        _friendStream = _challenges.watchFriendUids();
        _friendProfilesFuture = null;
        _friendProfilesKey = '';
        _loading = false;
      });
      _openInitialChallenge();
    } catch (error, stackTrace) {
      debugPrint('Challenge center initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      if (preserveCurrentView) {
        _message('Yenileme tamamlanamadı. Mevcut ekran korunuyor.');
      } else {
        setState(() {
          _online = false;
          _offlineReason = '$error';
          _world = null;
          _challengeStream = null;
          _friendStream = null;
          _friendProfilesFuture = null;
          _friendProfilesKey = '';
          _loading = false;
        });
      }
    } finally {
      _initializing = false;
    }
  }

  Future<List<OnlineLeaderboardEntry>> _profilesForFriends(
    Iterable<String> uids,
  ) {
    final List<String> normalizedUids = uids.toSet().toList()..sort();
    final String key = normalizedUids.join('|');
    if (_friendProfilesFuture == null || _friendProfilesKey != key) {
      _friendProfilesKey = key;
      _friendProfilesFuture = _leaderboard.fetchPlayersByUid(normalizedUids);
    }
    return _friendProfilesFuture!;
  }

  void _openInitialChallenge() {
    final String? challengeId = widget.initialChallengeId;
    if (_initialChallengeOpened ||
        challengeId == null ||
        challengeId.trim().isEmpty ||
        !_online) {
      return;
    }
    _initialChallengeOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChallengeDuelPage(challengeId: challengeId.trim()),
        ),
      );
    });
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _shareOpenChallenge() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final SocialChallenge? challenge = await _challenges
          .createSeriesChallenge();

      if (!mounted) return;

      if (challenge == null) {
        _message('Davet oluşturulamadı. İnternet bağlantını kontrol et.');
        return;
      }

      final String url = _challenges.inviteUrl(challenge.id);

      await SharePlus.instance.share(
        ShareParams(
          subject: 'Zeka Parkuru meydan okuma daveti',
          text:
              'Benimle Zeka Parkuru ${challenge.gameIds.length} oyunluk Meydan Okuma serisini oyna!\n'
              '${challenge.gameIds.length} farklı oyun • Orta-zor bölümler\n'
              'Puan üstünlüğü • Eşitlikte süre\n'
              'Takıldığında geri tuşundan BÖLÜMÜ GEÇ seçilebilir\n'
              'Davet 48 saat geçerli:\n$url',
        ),
      );
    } catch (error) {
      _message('Paylaşım açılamadı: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _challengePlayer(OnlineLeaderboardEntry player) async {
    if (_busy || player.uid == _challenges.currentUid) return;

    setState(() => _busy = true);

    try {
      final SocialChallenge? challenge = await _challenges
          .createSeriesChallenge(target: player);

      if (!mounted) return;

      if (challenge == null) {
        _message('Meydan okuma gönderilemedi.');
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChallengeDuelPage(challengeId: challenge.id),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _findFriend() async {
    if (_busy) return;
    final String code = _friendCodeController.text;
    if (code.trim().isEmpty) {
      _message('8 karakterli arkadaş kodunu yaz.');
      return;
    }
    setState(() => _busy = true);
    try {
      final OnlineLeaderboardEntry? player = await _leaderboard
          .findByFriendCode(code);
      if (!mounted) return;
      if (player == null || player.uid == _challenges.currentUid) {
        _message('Bu kodla başka bir oyuncu bulunamadı.');
        return;
      }
      final bool? send = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              AvatarIcon(player.avatar, size: 32, borderRadius: 10),
              const SizedBox(width: 9),
              Expanded(child: Text(player.displayName)),
            ],
          ),
          content: Text(
            '${player.score} ZP • ${player.stars}/330 ⭐\n'
            'Meydan okuma göndermek ister misin?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('VAZGEÇ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('MEYDAN OKU'),
            ),
          ],
        ),
      );
      if (send == true) {
        if (mounted) setState(() => _busy = false);
        await _challengePlayer(player);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ARKADAŞLAR & DÜELLO',
          style: TextStyle(
            color: StudioVisuals.ink,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _busy ? null : () => _initialize(forceRetry: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StudioPageFrame(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : !_online
              ? _OfflineState(
                  reason: _offlineReason,
                  onRetry: () => _initialize(forceRetry: true),
                )
              : Stack(
                  children: [
                    ScrollConfiguration(
                      behavior: const MaterialScrollBehavior().copyWith(
                        overscroll: false,
                      ),
                      child: RefreshIndicator(
                        onRefresh: () => _initialize(forceRetry: true),
                        child: ListView(
                          physics: const ClampingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(
                            StudioVisuals.pageGutter,
                            12,
                            StudioVisuals.pageGutter,
                            32,
                          ),
                          children: [
                            _InvitePanel(
                              friendCode:
                                  _challenges.currentFriendCode ?? '--------',
                              onShare: _shareOpenChallenge,
                              onCopy: () async {
                                final String code =
                                    _challenges.currentFriendCode ?? '';
                                await Clipboard.setData(
                                  ClipboardData(text: code),
                                );
                                _message('Arkadaş kodun kopyalandı.');
                              },
                            ),
                            const SizedBox(height: 12),
                            _FriendCodePanel(
                              controller: _friendCodeController,
                              onFind: _findFriend,
                            ),
                            const SizedBox(height: 18),
                            const _SectionTitle(
                              icon: Icons.bolt_rounded,
                              title: 'MEYDAN OKUMALARIM',
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<List<SocialChallenge>>(
                              stream: _challengeStream,
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return _InfoCard(
                                    text:
                                        'Meydan okumalar yüklenemedi: '
                                        '${snapshot.error}',
                                  );
                                }
                                final List<SocialChallenge> items =
                                    snapshot.data ?? const <SocialChallenge>[];
                                if (items.isEmpty) {
                                  return const _InfoCard(
                                    text:
                                        'Henüz düellon yok. WhatsApp daveti '
                                        'göndererek ilk mücadeleyi başlat.',
                                  );
                                }
                                return Column(
                                  children: items
                                      .take(12)
                                      .map((challenge) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: ChallengeCard(
                                            challenge: challenge,
                                            currentUid:
                                                _challenges.currentUid ?? '',
                                            onOpen: () => Navigator.push(
                                              context,
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    ChallengeDuelPage(
                                                      challengeId: challenge.id,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(growable: false),
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            const _SectionTitle(
                              icon: Icons.people_alt_rounded,
                              title: 'ARKADAŞLAR',
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<List<String>>(
                              stream: _friendStream,
                              builder: (context, snapshot) {
                                final List<String> uids =
                                    snapshot.data ?? const <String>[];

                                final String? currentUid =
                                    _challenges.currentUid;

                                final Set<String> rankUids = <String>{
                                  ...uids,
                                  if (currentUid != null &&
                                      currentUid.isNotEmpty)
                                    currentUid,
                                };

                                if (rankUids.isEmpty) {
                                  return const _InfoCard(
                                    text: 'Arkadaş sıralaması henüz hazırlanamadı.',
                                  );
                                }

                                return FutureBuilder<
                                  List<OnlineLeaderboardEntry>
                                >(
                                  future: _profilesForFriends(rankUids),
                                  builder: (context, playersSnapshot) {
                                    final List<OnlineLeaderboardEntry>?
                                    players = playersSnapshot.data;

                                    if (players == null) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final List<OnlineLeaderboardEntry> ranked =
                                        List<OnlineLeaderboardEntry>.from(
                                          players,
                                        );

                                    ranked.sort((a, b) {
                                      final int scoreCompare = b.score
                                          .compareTo(a.score);
                                      if (scoreCompare != 0) {
                                        return scoreCompare;
                                      }

                                      final int starCompare = b.stars.compareTo(
                                        a.stars,
                                      );
                                      if (starCompare != 0) {
                                        return starCompare;
                                      }

                                      return b.completedLevels.compareTo(
                                        a.completedLevels,
                                      );
                                    });

                                    final int myIndex = currentUid == null
                                        ? -1
                                        : ranked.indexWhere(
                                            (player) =>
                                                player.uid == currentUid,
                                          );

                                    final int? myRank = myIndex >= 0
                                        ? myIndex + 1
                                        : null;

                                    final List<
                                      MapEntry<int, OnlineLeaderboardEntry>
                                    >
                                    rankedFriends = ranked
                                        .asMap()
                                        .entries
                                        .toList(growable: false);

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 11,
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: StudioVisuals.surface,
                                            borderRadius:
                                                StudioVisuals.compactRadius,
                                            border: Border.all(
                                              color: StudioVisuals.line,
                                            ),
                                            boxShadow: StudioVisuals.softShadow,
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              const Icon(
                                                Icons.emoji_events_rounded,
                                                size: 20,
                                                color: StudioVisuals.amber,
                                              ),
                                              const SizedBox(width: 9),
                                              Expanded(
                                                child: Text(
                                                  myRank == null
                                                      ? 'Arkadaş sırası hesaplanamadı'
                                                      : 'Arkadaşlar arasında #$myRank',
                                                  style: const TextStyle(
                                                    color: StudioVisuals.ink,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              if (myRank != null)
                                                Text(
                                                  '${ranked.length} oyuncu',
                                                  style: const TextStyle(
                                                    color: StudioVisuals.muted,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (rankedFriends.isEmpty)
                                          const _InfoCard(
                                            text: 'Henüz arkadaşın yok. Bir meydan okuma kabul edildiğinde oyuncu otomatik olarak arkadaş listene eklenir.',
                                          )
                                        else
                                          ...rankedFriends.map(
                                            (item) => _PlayerCard(
                                              rank: item.key + 1,
                                              player: item.value,
                                              isCurrent:
                                                  item.value.uid == currentUid,
                                              onChallenge: () =>
                                                  _challengePlayer(item.value),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            const _SectionTitle(
                              icon: Icons.online_prediction_rounded,
                              title: 'ŞİMDİ AKTİF OYUNCULAR',
                            ),
                            const SizedBox(height: 8),
                            if ((_world?.entries ??
                                    const <OnlineLeaderboardEntry>[])
                                .where(
                                  (player) =>
                                      player.recentlyActive &&
                                      player.uid != _challenges.currentUid,
                                )
                                .isEmpty)
                              const _InfoCard(
                                text:
                                    'Son 15 dakikada başka aktif oyuncu '
                                    'görünmüyor. Dünya listesinden yine de '
                                    'bildirimli meydan okuma gönderebilirsin.',
                              )
                            else
                              ...(_world?.entries ??
                                      const <OnlineLeaderboardEntry>[])
                                  .where(
                                    (player) =>
                                        player.recentlyActive &&
                                        player.uid != _challenges.currentUid,
                                  )
                                  .take(10)
                                  .map(
                                    (player) => _PlayerCard(
                                      player: player,
                                      active: true,
                                      onChallenge: () =>
                                          _challengePlayer(player),
                                    ),
                                  ),
                            const SizedBox(height: 18),
                            const _SectionTitle(
                              icon: Icons.public_rounded,
                              title: 'DÜNYA SIRALAMASI',
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _world?.currentRank == null
                                  ? 'Dünya sırası hesaplanamadı • ${_world?.totalPlayers ?? 0} oyuncu'
                                  : 'Dünya #${_world!.currentRank} • ${_world?.totalPlayers ?? 0} oyuncu',
                              style: const TextStyle(
                                color: StudioVisuals.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...(_world?.entries ??
                                    const <OnlineLeaderboardEntry>[])
                                .take(20)
                                .toList(growable: false)
                                .asMap()
                                .entries
                                .map(
                                  (item) => _PlayerCard(
                                    rank:
                                        item.value.uid ==
                                                _challenges.currentUid &&
                                            _world?.currentRank != null
                                        ? _world!.currentRank
                                        : item.key + 1,
                                    player: item.value,
                                    active: item.value.recentlyActive,
                                    isCurrent:
                                        item.value.uid ==
                                        _challenges.currentUid,
                                    onChallenge: () =>
                                        _challengePlayer(item.value),
                                  ),
                                ),
                            if (_world?.currentRank != null &&
                                (_world?.entries ??
                                        const <OnlineLeaderboardEntry>[])
                                    .any(
                                      (player) =>
                                          player.uid == _challenges.currentUid,
                                    ) &&
                                !(_world?.entries ??
                                        const <OnlineLeaderboardEntry>[])
                                    .take(20)
                                    .any(
                                      (player) =>
                                          player.uid == _challenges.currentUid,
                                    )) ...<Widget>[
                              const SizedBox(height: 2),
                              Container(
                                key: const ValueKey<String>(
                                  'world_current_player_separator',
                                ),
                                margin: const EdgeInsets.fromLTRB(
                                  12,
                                  3,
                                  12,
                                  11,
                                ),
                                child: const Row(
                                  children: <Widget>[
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        'SIRALAMADAKİ YERİN',
                                        style: TextStyle(
                                          color: StudioVisuals.teal,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),
                              ),
                              ...(_world?.entries ??
                                      const <OnlineLeaderboardEntry>[])
                                  .where(
                                    (player) =>
                                        player.uid == _challenges.currentUid,
                                  )
                                  .take(1)
                                  .map(
                                    (player) => _PlayerCard(
                                      rank: _world!.currentRank,
                                      player: player,
                                      active: player.recentlyActive,
                                      isCurrent: true,
                                      onChallenge: () =>
                                          _challengePlayer(player),
                                    ),
                                  ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_busy)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x44000000),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class ChallengeDuelPage extends StatefulWidget {
  final String challengeId;

  const ChallengeDuelPage({super.key, required this.challengeId});

  @override
  State<ChallengeDuelPage> createState() => _ChallengeDuelPageState();
}

class _ChallengeDuelPageState extends State<ChallengeDuelPage> {
  final SocialChallengeService _service = SocialChallengeService.instance;
  final ChallengeRunProgressService _runProgress =
      ChallengeRunProgressService.instance;
  late final Stream<SocialChallenge?> _challengeStream;
  bool _busy = false;

  static const ReflexLevel _duelLevel = ReflexLevel(
    number: 1,
    title: 'Düello: Yeşil Işık',
    subtitle: 'İki oyuncu da aynı seriyi oynar',
    difficulty: 'DÜELLO',
    mode: ReflexMode.reaction,
    rounds: 6,
    lives: 3,
    timeLimitMs: 1200,
    targetMs: 520,
  );

  @override
  void initState() {
    super.initState();
    _challengeStream = _service.watchChallenge(widget.challengeId.trim());
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    final bool success = await _service.acceptChallenge(widget.challengeId);
    if (mounted) {
      setState(() => _busy = false);
      _message(
        success ? 'Meydan okuma kabul edildi!' : 'Davet kabul edilemedi.',
      );
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    final bool success = await _service.declineChallenge(widget.challengeId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) Navigator.pop(context);
  }

  Future<void> _playSeries(SocialChallenge challenge) async {
    if (!challenge.isSeries || _busy) return;

    final String playerUid = _service.currentUid ?? '';
    if (playerUid.isEmpty) {
      _message('Oyuncu bilgisi alınamadı. Parkur başlatılamadı.');
      return;
    }

    setState(() => _busy = true);
    try {
      final String parkourFingerprint = <String>[
        '${challenge.schemaVersion}',
        challenge.gameIds.join(','),
        challenge.levels.join(','),
        challenge.layoutCodes.join(','),
      ].join('|');

      ChallengeRunCheckpoint checkpoint = await _runProgress.loadOrCreate(
        challengeId: challenge.id,
        playerUid: playerUid,
        parkourFingerprint: parkourFingerprint,
        stationCount: challenge.gameIds.length,
      );

      if (!mounted) return;

      // Uygulama oyun açıkken kapatılmışsa duvar saati farkını yarış
      // süresine ekleme. Bölüm aynı yerde kalır ve temiz bir deneme başlar.
      if (checkpoint.activeStationStartedAtMs != null) {
        checkpoint = checkpoint.copyWith(clearActiveStationStartedAt: true);
        await _runProgress.save(checkpoint);
      }

      if (!mounted) return;

      if (checkpoint.nextStationIndex > 0 &&
          checkpoint.nextStationIndex < challenge.gameIds.length) {
        _message(
          'Parkura ${checkpoint.nextStationIndex + 1}. bölümden devam ediliyor.',
        );
      }

      int index = checkpoint.nextStationIndex;
      while (index < challenge.gameIds.length) {
        if (!mounted) return;

        final String gameId = challenge.gameIds[index];
        final String gameName = challengeGameDefinition(gameId).name;
        final int level = challenge.levelForIndex(index);
        final int layoutCode = challenge.layoutCodeForIndex(index);
        bool stationResolved = false;

        while (!stationResolved) {
          if (!mounted) return;

          final int stationStartedAtMs = DateTime.now().millisecondsSinceEpoch;
          checkpoint = checkpoint.copyWith(
            activeStationStartedAtMs: stationStartedAtMs,
          );
          await _runProgress.save(checkpoint);

          if (!mounted) return;

          final Object? rawResult = await Navigator.push<Object?>(
            context,
            MaterialPageRoute<Object?>(
              builder: (_) => buildChallengeCompetitionPage(
                gameId: gameId,
                level: level,
                layoutCode: layoutCode,
              ),
            ),
          );

          if (!mounted) return;

          final int stationElapsedMs =
              (DateTime.now().millisecondsSinceEpoch - stationStartedAtMs)
                  .clamp(0, 86400000)
                  .toInt();

          checkpoint = checkpoint.copyWith(
            elapsedMs: (checkpoint.elapsedMs + stationElapsedMs)
                .clamp(0, 86400000)
                .toInt(),
            clearActiveStationStartedAt: true,
          );
          await _runProgress.save(checkpoint);

          if (!mounted) return;

          final DailyStageOutcome outcome;
          final int resultStars;

          if (rawResult is DailyStageResult && rawResult.gameId == gameId) {
            outcome = rawResult.outcome;
            resultStars = rawResult.stars;
          } else if (rawResult is DailyCourseGameResult &&
              rawResult.gameId == gameId) {
            // V3 döneminden kalan sonuç köprüsü için geriye uyumluluk.
            outcome = DailyStageOutcome.completed;
            resultStars = rawResult.stars;
          } else {
            outcome = DailyStageOutcome.exited;
            resultStars = 0;
          }

          switch (outcome) {
            case DailyStageOutcome.completed:
              final int safeStars = resultStars.clamp(0, 3).toInt();
              final int stageScore = 100 + safeStars * 300;

              // Kontrol noktası geçiş ekranından ve sonraki oyundan önce
              // yazılır. Çözülen bölüm bu nedenle yeniden açılamaz.
              checkpoint = checkpoint.copyWith(
                nextStationIndex: index + 1,
                totalScore: checkpoint.totalScore + stageScore,
                totalStars: checkpoint.totalStars + safeStars,
              );
              await _runProgress.save(checkpoint);
              stationResolved = true;

              if (!mounted) return;
              await CompetitionStageTransition.show(
                context,
                completedCount: index + 1,
                totalCount: challenge.gameIds.length,
                stars: safeStars,
                score: stageScore,
                flowName: '1’E1 DÜELLO',
                nextGameName: index + 1 < challenge.gameIds.length
                    ? challengeGameDefinition(challenge.gameIds[index + 1]).name
                    : null,
              );
              break;

            case DailyStageOutcome.failed:
            case DailyStageOutcome.skipped:
              checkpoint = checkpoint.copyWith(
                nextStationIndex: index + 1,
                skips: checkpoint.skips + 1,
              );
              await _runProgress.save(checkpoint);
              stationResolved = true;

              if (!mounted) return;
              await CompetitionStageTransition.show(
                context,
                completedCount: index + 1,
                totalCount: challenge.gameIds.length,
                stars: 0,
                score: 0,
                flowName: '1’E1 DÜELLO',
                nextGameName: index + 1 < challenge.gameIds.length
                    ? challengeGameDefinition(challenge.gameIds[index + 1]).name
                    : null,
              );
              break;

            case DailyStageOutcome.exited:
              final CompetitionExitDecision decision =
                  await showCompetitionExitDecision(
                    context,
                    flowName: '1’E1 DÜELLO',
                    gameName: gameName,
                  );

              if (!mounted) return;

              switch (decision) {
                case CompetitionExitDecision.retry:
                  // Bölüm çözülmedi; aynı kontrol noktasında yeni deneme.
                  continue;
                case CompetitionExitDecision.skip:
                  checkpoint = checkpoint.copyWith(
                    nextStationIndex: index + 1,
                    skips: checkpoint.skips + 1,
                  );
                  await _runProgress.save(checkpoint);
                  stationResolved = true;

                  if (!mounted) return;
                  await CompetitionStageTransition.show(
                    context,
                    completedCount: index + 1,
                    totalCount: challenge.gameIds.length,
                    stars: 0,
                    score: 0,
                    flowName: '1’E1 DÜELLO',
                    nextGameName: index + 1 < challenge.gameIds.length
                        ? challengeGameDefinition(challenge.gameIds[index + 1])
                              .name
                        : null,
                  );
                  break;
                case CompetitionExitDecision.leave:
                  _message(
                    'İlerlemen kaydedildi. Bu bölüme kaldığın yerden '
                    'devam edebilirsin.',
                  );
                  return;
              }
              break;
          }
        }

        index = checkpoint.nextStationIndex;
      }

      if (!mounted) return;

      final bool saved = await _service.submitSeriesResult(
        challengeId: challenge.id,
        score: checkpoint.totalScore,
        stars: checkpoint.totalStars,
        elapsedMs: checkpoint.elapsedMs,
        skips: checkpoint.skips,
      );

      if (!mounted) return;

      if (saved) {
        await _runProgress.clear(
          challengeId: challenge.id,
          playerUid: playerUid,
        );
      }

      if (!mounted) return;

      _message(
        saved
            ? '${challenge.gameIds.length} oyunluk seri sonucun kaydedildi.'
            : 'Seri sonucu kaydedilemedi.',
      );
    } catch (error, stackTrace) {
      debugPrint('Challenge series flow failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _message(
          'Düello akışı tamamlanamadı. Kaydedilen bölümden tekrar '
          'deneyebilirsin.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play(SocialChallenge challenge) async {
    if (challenge.isSeries) {
      await _playSeries(challenge);
      return;
    }

    int? score;
    int? stars;

    // Eski uygulama sürümlerinde oluşturulmuş Refleks davetleri
    // çalışmaya devam eder.
    if (challenge.gameId == 'reflex') {
      final ReflexLevelResult? legacyResult =
          await Navigator.push<ReflexLevelResult>(
            context,
            MaterialPageRoute<ReflexLevelResult>(
              builder: (_) => ReflexPlayPage(
                level: _duelLevel,
                totalLevels: 1,
                fixedSessionSeed: challenge.seed,
              ),
            ),
          );

      if (legacyResult == null || !legacyResult.completed || !mounted) {
        return;
      }

      score = legacyResult.score;
      stars = legacyResult.stars;
    } else {
      final DailyCourseGameResult? result =
          await Navigator.push<DailyCourseGameResult>(
            context,
            MaterialPageRoute<DailyCourseGameResult>(
              builder: (_) => buildChallengeCompetitionPage(
                gameId: challenge.gameId,
                level: challenge.level,
                layoutCode: challenge.seed,
              ),
            ),
          );

      if (result == null || !mounted) return;

      score = result.score;
      stars = result.stars;
    }

    if (!mounted) return;

    setState(() => _busy = true);

    final bool saved = await _service.submitScore(
      challengeId: challenge.id,
      score: score,
      stars: stars,
    );

    if (!mounted) return;

    setState(() => _busy = false);

    _message(
      saved ? 'Skorun meydan okumaya kaydedildi.' : 'Skor kaydedilemedi.',
    );
  }

  Future<void> _sendReaction(SocialChallenge challenge, String reaction) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final bool sent = await _service.sendReaction(
        challengeId: challenge.id,
        reaction: reaction,
      );

      if (!mounted) return;

      if (!sent) {
        _message('Tepki gönderilemedi.');
        return;
      }

      const Map<String, String> sentMessages = <String, String>{
        'good_game': 'İyi yarıştın mesajın gönderildi. 👏',
        'rematch': 'Rövanş isteğin gönderildi. ⚔️',
        'close_game': 'Çok yakındı mesajın gönderildi. 😅',
        'congrats': 'Tebrik mesajın gönderildi. 🏆',
      };

      SocialNotificationService.instance.showForegroundNotice(
        title: 'Mesaj gönderildi',
        body: sentMessages[reaction] ?? 'Mesajın rakibine gönderildi.',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _rematch(SocialChallenge challenge) async {
    if (_busy) return;

    final String uid = _service.currentUid ?? '';
    if (uid.isEmpty) {
      _message('Oyuncu bilgisi alınamadı.');
      return;
    }

    final String opponentUid = challenge.challengerUid == uid
        ? (challenge.opponentUid ?? challenge.targetUid ?? '')
        : challenge.challengerUid;

    if (opponentUid.isEmpty || opponentUid == uid) {
      _message('Rövanş için rakip bulunamadı.');
      return;
    }

    setState(() => _busy = true);

    try {
      final List<OnlineLeaderboardEntry> players =
          await OnlineLeaderboardService.instance.fetchPlayersByUid(<String>[
            opponentUid,
          ]);

      if (!mounted) return;

      if (players.isEmpty) {
        _message('Rakip bilgisi alınamadı.');
        return;
      }

      final SocialChallenge? rematch = await _service.createSeriesChallenge(
        target: players.first,
      );

      if (!mounted) return;

      if (rematch == null) {
        _message('Rövanş oluşturulamadı.');
        return;
      }

      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChallengeDuelPage(challengeId: rematch.id),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _share(SocialChallenge challenge) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Zeka Parkuru meydan okuma daveti',
        text:
            '${challenge.gameIds.length} oyunluk Zeka Parkuru Meydan Okuma serisine katıl!\n'
            'Puan üstünlüğü • Eşitlikte süre\n'
            '${_service.inviteUrl(challenge.id)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _service.currentUid ?? '';
    return Scaffold(
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        foregroundColor: StudioVisuals.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MEYDAN OKUMA',
          style: TextStyle(
            color: StudioVisuals.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Davet bağlantısını paylaş',
            onPressed: () async {
              final SocialChallenge? challenge = await _service.getChallenge(
                widget.challengeId,
              );
              if (challenge != null) await _share(challenge);
            },
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<SocialChallenge?>(
          stream: _challengeStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Düello açılamadı: ${snapshot.error}'));
            }
            final SocialChallenge? challenge = snapshot.data;
            if (challenge == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final bool mine = challenge.challengerUid == uid;
            final bool canAccept =
                challenge.isPlayable &&
                challenge.pending &&
                !mine &&
                (challenge.targetUid == null || challenge.targetUid == uid);
            final bool canPlay =
                challenge.isPlayable &&
                challenge.accepted &&
                challenge.scoreFor(uid) == null &&
                !challenge.expired;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    ChallengeDuelHero(challenge: challenge, currentUid: uid),
                    const SizedBox(height: 14),
                    _ScoreComparison(challenge: challenge, currentUid: uid),
                    const SizedBox(height: 14),
                    if (challenge.expired && !challenge.completed)
                      const _InfoCard(
                        text: 'Bu davetin 48 saatlik süresi doldu.',
                      ),
                    if (challenge.pending && mine)
                      const _InfoCard(
                        text:
                            'Rakibin daveti açıp kabul etmesi bekleniyor. '
                            'Bağlantıyı WhatsApp üzerinden paylaşabilirsin.',
                      ),
                    if (canAccept)
                      Row(
                        children: [
                          if (challenge.targetUid != null)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _busy ? null : _decline,
                                child: const Text('REDDET'),
                              ),
                            ),
                          if (challenge.targetUid != null)
                            const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _accept,
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('KABUL ET'),
                            ),
                          ),
                        ],
                      ),
                    if (canPlay)
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _play(challenge),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          challenge.isSeries
                              ? '${challenge.gameIds.length} OYUNLUK PARKURU BAŞLAT / DEVAM ET'
                              : 'AYNI SERİYİ OYNA',
                        ),
                      ),
                    if (challenge.accepted && challenge.scoreFor(uid) != null)
                      const _InfoCard(
                        text: 'Skorun kaydedildi. Rakibinin sonucu bekleniyor.',
                      ),
                    if (!challenge.isPlayable)
                      const _InfoCard(
                        text:
                            'Bu davet artık kullanılmayan bir oyun içerdiği '
                            'için parkurdan kaldırıldı.',
                      ),
                    if (challenge.completed)
                      _ResultBanner(challenge: challenge, currentUid: uid),
                    if (challenge.completed) const SizedBox(height: 10),
                    if (challenge.completed)
                      _ReactionPanel(
                        challenge: challenge,
                        currentUid: uid,
                        onReaction: (reaction) =>
                            _sendReaction(challenge, reaction),
                      ),
                    if (challenge.completed) const SizedBox(height: 10),
                    if (challenge.completed)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : () => _rematch(challenge),
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text(
                            'RÖVANŞ',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    if (challenge.declined)
                      const _InfoCard(text: 'Bu meydan okuma reddedildi.'),
                  ],
                ),
                if (_busy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x44000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InvitePanel extends StatelessWidget {
  final String friendCode;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  const _InvitePanel({
    required this.friendCode,
    required this.onShare,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: StudioVisuals.tealSoft,
                  borderRadius: StudioVisuals.compactRadius,
                ),
                child: const Icon(
                  Icons.sports_kabaddi_rounded,
                  color: StudioVisuals.teal,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'ARKADAŞINI ARENAYA ÇAĞIR',
                  style: TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'WhatsApp veya istediğin uygulamayla tek kullanımlık '
            'düello bağlantısı gönder.',
            style: TextStyle(
              color: StudioVisuals.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded),
              label: const Text('WHATSAPP İLE DAVET GÖNDER'),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Text(
                'Arkadaş kodun: ',
                style: TextStyle(color: StudioVisuals.muted, fontSize: 12),
              ),
              Text(
                friendCode,
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendCodePanel extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFind;

  const _FriendCodePanel({required this.controller, required this.onFind});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              decoration: const InputDecoration(
                counterText: '',
                labelText: 'Arkadaş kodu',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'AB12CD34',
                prefixIcon: Icon(Icons.person_search_rounded),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => onFind(),
            ),
          ),
          const SizedBox(width: 9),
          FilledButton(onPressed: onFind, child: const Text('BUL')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: StudioVisuals.teal, size: 20),
      const SizedBox(width: 7),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

class _PlayerCard extends StatelessWidget {
  final int? rank;
  final OnlineLeaderboardEntry player;
  final bool active;
  final bool isCurrent;
  final VoidCallback onChallenge;

  const _PlayerCard({
    this.rank,
    required this.player,
    this.active = false,
    this.isCurrent = false,
    required this.onChallenge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent ? StudioVisuals.tealSoft : StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(
          color: isCurrent
              ? StudioVisuals.teal.withValues(alpha: 0.4)
              : StudioVisuals.line,
        ),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rank != null)
              Text(
                '${rank!}.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            if (rank != null) const SizedBox(width: 5),
            AvatarIcon(player.avatar, size: 34, borderRadius: 10),
          ],
        ),
        title: Text(
          isCurrent ? '${player.displayName} • SEN' : player.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          active
              ? '● Şimdi aktif • ${player.score} ZP • ${player.stars}/330 ⭐'
              : '${player.score} ZP • ${player.stars}/330 ⭐',
          style: TextStyle(
            color: active ? StudioVisuals.teal : StudioVisuals.muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        trailing: isCurrent
            ? const Icon(Icons.person_rounded, color: StudioVisuals.teal)
            : IconButton.filledTonal(
                tooltip: 'Meydan oku',
                onPressed: onChallenge,
                icon: const Icon(Icons.bolt_rounded, size: 20),
              ),
      ),
    );
  }
}

String _challengeParticipantName(String? name, {required bool isCurrentUser}) {
  final String value = name?.trim() ?? '';
  if (value.isEmpty || value.toLowerCase() == 'oyuncu') {
    return isCurrentUser ? 'Sen' : 'Rakip';
  }
  return value;
}

class ChallengeCard extends StatelessWidget {
  final SocialChallenge challenge;
  final String currentUid;
  final VoidCallback onOpen;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.currentUid,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final String status = challenge.completed
        ? 'SONUÇ HAZIR'
        : challenge.accepted
        ? 'OYUN AÇIK'
        : challenge.declined
        ? 'REDDEDİLDİ'
        : challenge.expired
        ? 'SÜRESİ DOLDU'
        : 'KABUL BEKLİYOR';
    final String opponentName = challenge.opponentLabelFor(currentUid);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: StudioVisuals.surface,
      elevation: 0,
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AvatarIcon(
          challenge.opponentAvatarFor(currentUid),
          size: 44,
          borderRadius: 12,
        ),
        title: Text(
          opponentName == 'Rakip bekleniyor'
              ? opponentName
              : _challengeParticipantName(opponentName, isCurrentUser: false),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: StudioVisuals.muted),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class ChallengeDuelHero extends StatelessWidget {
  final SocialChallenge challenge;
  final String currentUid;

  const ChallengeDuelHero({
    super.key,
    required this.challenge,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    final ChallengeGameDefinition game = challenge.isSeries
        ? const ChallengeGameDefinition(
            id: 'series',
            name: 'Meydan Okuma',
            icon: Icons.route_rounded,
            color: StudioVisuals.teal,
          )
        : challengeGameDefinition(challenge.gameId);

    final bool legacyReflex =
        !challenge.isSeries && challenge.gameId == 'reflex';

    final String title = challenge.isSeries
        ? '${challenge.gameIds.length} OYUNLUK MEYDAN OKUMA'
        : legacyReflex
        ? 'REFLEKS AVI • KLASİK'
        : '${game.name.toUpperCase()} • BÖLÜM ${challenge.level}';

    final String detail = challenge.isSeries
        ? '${challenge.gameIds.length} farklı oyun • Puan öncelikli • Eşitlikte süre'
        : legacyReflex
        ? '6 tur • 3 can • En yüksek skor kazanır'
        : '${challengeDifficultyLabel(challenge.level)} • '
              'Aynı görev • En yüksek skor kazanır';

    final Color accent = game.color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.13),
            StudioVisuals.surface,
          ],
        ),
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: StudioVisuals.surface,
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Icon(game.icon, size: 32, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StudioVisuals.ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _challengeParticipantName(
                    challenge.challengerName,
                    isCurrentUser: challenge.challengerUid == currentUid,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: StudioVisuals.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _challengeParticipantName(
                    challenge.opponentName,
                    isCurrentUser:
                        challenge.opponentUid == currentUid ||
                        challenge.targetUid == currentUid,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreComparison extends StatelessWidget {
  final SocialChallenge challenge;
  final String currentUid;

  const _ScoreComparison({required this.challenge, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    Widget score(
      String? name,
      String avatar,
      int? points,
      int? stars, {
      required bool isCurrentUser,
    }) {
      return Expanded(
        child: Column(
          children: [
            AvatarIcon(avatar, size: 52, borderRadius: 15),
            Text(
              _challengeParticipantName(name, isCurrentUser: isCurrentUser),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              points == null ? 'BEKLİYOR' : '$points PUAN',
              style: TextStyle(
                color: points == null
                    ? StudioVisuals.muted
                    : StudioVisuals.amber,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (stars != null) Text('$stars ⭐'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: [
          score(
            challenge.challengerName,
            challenge.challengerAvatar,
            challenge.challengerScore,
            challenge.challengerStars,
            isCurrentUser: challenge.challengerUid == currentUid,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          score(
            challenge.opponentName ?? 'Rakip',
            challenge.opponentAvatar ?? '⚔️',
            challenge.opponentScore,
            challenge.opponentStars,
            isCurrentUser:
                challenge.opponentUid == currentUid ||
                challenge.targetUid == currentUid,
          ),
        ],
      ),
    );
  }
}

class _ReactionPanel extends StatelessWidget {
  final SocialChallenge challenge;
  final String currentUid;
  final Future<void> Function(String reaction) onReaction;

  const _ReactionPanel({
    required this.challenge,
    required this.currentUid,
    required this.onReaction,
  });

  static const Map<String, String> _labels = <String, String>{
    'good_game': 'İyi oynadın 👏',
    'rematch': 'Rövanş? ⚔️',
    'close_game': 'Çok yakındı 😅',
    'congrats': 'Tebrikler 🏆',
  };

  @override
  Widget build(BuildContext context) {
    final bool amChallenger = challenge.challengerUid == currentUid;

    final String? mine = amChallenger
        ? challenge.challengerReaction
        : challenge.opponentReaction;

    final String? other = amChallenger
        ? challenge.opponentReaction
        : challenge.challengerReaction;

    final String opponentName = challenge.opponentLabelFor(currentUid);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (other != null && _labels.containsKey(other)) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: StudioVisuals.tealSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$opponentName: ${_labels[other]}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'TEPKİ GÖNDER',
            style: TextStyle(
              color: StudioVisuals.ink,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _labels.entries
                .map((entry) {
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: mine == entry.key,
                    onSelected: (_) {
                      onReaction(entry.key);
                    },
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final SocialChallenge challenge;
  final String currentUid;

  const _ResultBanner({required this.challenge, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final bool draw = challenge.winnerUid == 'draw';
    final bool won = challenge.winnerUid == currentUid;
    return ChampionCelebrationCard(
      key: ValueKey<String>('challenge_result_${challenge.id}_$currentUid'),
      celebrate: won,
      title: draw
          ? 'BAŞA BAŞA!'
          : won
          ? 'MAŞALLAH!'
          : 'MÜCADELE TAMAMLANDI',
      subtitle: draw
          ? 'Müthiş mücadele 🤝'
          : won
          ? 'Şampiyon sensin 🏆'
          : 'Bu mücadeleyi rakibin kazandı. Rövanşta sıra sende!',
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;

  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: StudioVisuals.compactRadius,
      border: Border.all(color: StudioVisuals.line),
      boxShadow: StudioVisuals.softShadow,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.info_outline_rounded, color: StudioVisuals.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: StudioVisuals.ink, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _OfflineState extends StatelessWidget {
  final VoidCallback onRetry;
  final String? reason;

  const _OfflineState({required this.onRetry, required this.reason});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 54,
            color: StudioVisuals.teal,
          ),
          const SizedBox(height: 12),
          const Text(
            'Çevrim içi arena bağlanamadı',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 7),
          Text(
            reason?.trim().isNotEmpty == true ? reason! : 'İnternetini ve Firebase yapılandırmasını kontrol edip tekrar dene.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: StudioVisuals.muted),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('TEKRAR DENE'),
          ),
        ],
      ),
    ),
  );
}
