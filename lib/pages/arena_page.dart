import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_visual_theme.dart';
import '../theme/studio_visuals.dart';
import '../features/catalog/domain/studio_game_catalog.dart';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/arena_service.dart';
import '../services/arena_run_progress_service.dart';
import '../services/daily_course_service.dart';
import '../services/online_leaderboard_service.dart';
import '../services/player_progress_service.dart';
import '../services/social_notification_service.dart';
import '../widgets/champion_celebration_card.dart';
import '../widgets/competition_exit_decision.dart';
import '../widgets/competition_stage_transition.dart';
import '../widgets/competition_stage_page.dart';
import '../widgets/studio_card.dart';
import '../widgets/avatar_icon.dart';
import 'challenge_game_catalog.dart';
import 'challenge_center_page.dart';

class ArenaPage extends StatefulWidget {
  final String? initialGroupId;
  final String? initialJoinCode;
  const ArenaPage({super.key, this.initialGroupId, this.initialJoinCode});
  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {
  final ArenaService _arena = ArenaService.instance;
  final OnlineLeaderboardService _leaderboard =
      OnlineLeaderboardService.instance;
  final PlayerProgressService _player = PlayerProgressService.instance;
  Stream<List<ArenaGroup>>? _groups;
  bool _loading = true;
  bool _online = false;
  bool _busy = false;
  bool _initializing = false;
  bool _inviteHandled = false;
  String? _offlineReason;
  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize({bool forceRetry = false}) async {
    if (_initializing) return;
    _initializing = true;
    final bool preserveCurrentView = !_loading && _online && _groups != null;
    try {
      final bool online = await _arena.ensureOnline(forceRetry: forceRetry);
      if (!online) {
        if (!mounted) return;
        if (preserveCurrentView) {
          _message('Yenileme tamamlanamadı. Mevcut ekran korunuyor.');
        } else {
          setState(() {
            _online = false;
            _offlineReason = _arena.lastError;
            _groups = null;
            _loading = false;
          });
        }
        return;
      }
      final PlayerDashboardData dashboard = await _player.load();
      await _leaderboard.syncCurrentPlayer(dashboard);
      if (!mounted) return;
      setState(() {
        _online = true;
        _offlineReason = null;
        _groups = _arena.watchMyGroups();
        _loading = false;
      });
      unawaited(_handleInitialInvite());
    } catch (error, stackTrace) {
      debugPrint('Arena initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      if (preserveCurrentView) {
        _message('Yenileme tamamlanamadı. Mevcut ekran korunuyor.');
      } else {
        setState(() {
          _online = false;
          _offlineReason = '$error';
          _groups = null;
          _loading = false;
        });
      }
    } finally {
      _initializing = false;
    }
  }

  Future<void> _handleInitialInvite() async {
    if (_inviteHandled || !_online) return;
    final String? groupId = widget.initialGroupId;
    final String? code = widget.initialJoinCode;
    if (groupId == null ||
        groupId.trim().isEmpty ||
        code == null ||
        code.trim().isEmpty) {
      return;
    }
    _inviteHandled = true;
    final ArenaGroup? group = await _arena.joinByInvite(
      groupId: groupId,
      joinCode: code,
    );
    if (!mounted) return;
    if (group == null) {
      _message('Grup daveti geçersiz, dolu veya süresi geçmiş olabilir.');
      return;
    }
    await _openGroup(group);
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
      );
  }

  Future<void> _createGroup() async {
    if (_busy) return;
    String draftName = '';
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: ZpVisualPalette.of(dialogContext).surface,
        title: const Text('YENİ GRUP OLUŞTUR'),
        content: TextField(
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: (String value) => draftName = value,
          onSubmitted: (String value) => Navigator.pop(dialogContext, value),
          decoration: const InputDecoration(
            labelText: 'Grup adı',
            hintText: 'Örn. Giresun Zekâ Takımı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, draftName),
            child: const Text('OLUŞTUR'),
          ),
        ],
      ),
    );
    if (name == null) return;
    setState(() => _busy = true);
    try {
      final ArenaGroup? group = await _arena.createGroup(name);
      if (!mounted) return;
      if (group == null) {
        _message('Grup oluşturulamadı. Bağlantını kontrol et.');
        return;
      }
      await _openGroup(group);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinGroup() async {
    if (_busy) return;
    String draftCode = '';
    final String? code = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: ZpVisualPalette.of(dialogContext).surface,
        title: const Text('GRUBA KATIL'),
        content: TextField(
          autofocus: true,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
          ],
          onChanged: (String value) => draftCode = value,
          onSubmitted: (String value) => Navigator.pop(dialogContext, value),
          decoration: const InputDecoration(
            labelText: '6 karakterli grup kodu',
            hintText: 'ABC123',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, draftCode),
            child: const Text('KATIL'),
          ),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final ArenaGroup? group = await _arena.joinByCode(code);
      if (!mounted) return;
      if (group == null) {
        _message('Grup bulunamadı veya grup 30 kişiye ulaşmış.');
        return;
      }
      await _openGroup(group);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openGroup(ArenaGroup group) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ArenaGroupPage(groupId: group.id),
      ),
    );
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
          'ARKADAŞLARINA MEYDAN OKU',
          style: TextStyle(
            color: StudioVisuals.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Yenile',
            onPressed: _busy ? null : () => _initialize(forceRetry: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: StudioPageFrame(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_online
            ? _ArenaOffline(
                reason: _offlineReason,
                onRetry: () => _initialize(forceRetry: true),
              )
            : ScrollConfiguration(
                behavior: ScrollConfiguration.of(context)
                    .copyWith(overscroll: false),
                child: ListView(
                  key: const PageStorageKey<String>('arena_home_scroll'),
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    StudioVisuals.pageGutter,
                    12,
                    StudioVisuals.pageGutter,
                    32,
                  ),
                  children: <Widget>[
                    const _ArenaHero(),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 104),
                      child: _ArenaActionCard(
                        icon: Icons.bolt_rounded,
                        color: StudioVisuals.teal,
                        imageAsset:
                            'assets/branding/studio_parkur_one_to_one_duel.webp',
                        title: 'BİREBİR DÜELLO',
                        subtitle:
                            'Arkadaşına veya dünyadan bir oyuncuya meydan oku.',
                        trailing: 'AÇ',
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ChallengeCenterPage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 104),
                      child: _ArenaActionCard(
                        icon: Icons.group_add_rounded,
                        color: StudioVisuals.amber,
                        imageAsset:
                            'assets/branding/studio_parkur_group_arena.webp',
                        title: 'GRUP OLUŞTUR',
                        subtitle: 'Arkadaşlarınla aynı parkurda yarış.',
                        trailing: 'OLUŞTUR',
                        onTap: _createGroup,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 104),
                      child: _ArenaActionCard(
                        icon: Icons.login_rounded,
                        color: StudioVisuals.teal,
                        imageAsset:
                            'assets/branding/studio_parkur_join_code.webp',
                        title: 'KODLA KATIL',
                        subtitle: 'Davet kodunla mevcut bir gruba katıl.',
                        trailing: 'KATIL',
                        onTap: _joinGroup,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _ArenaSectionTitle(
                      icon: Icons.groups_rounded,
                      title: 'GRUPLARIM',
                    ),
                    const SizedBox(height: 9),
                    StreamBuilder<List<ArenaGroup>>(
                      stream: _groups,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<List<ArenaGroup>> snapshot,
                          ) {
                            if (snapshot.hasError) {
                              return _ArenaInfo(
                                text: 'Gruplar yüklenemedi: ${snapshot.error}',
                              );
                            }
                            final List<ArenaGroup> groups =
                                snapshot.data ?? const <ArenaGroup>[];
                            if (groups.isEmpty) {
                              return const _ArenaInfo(
                                text:
                                    'Henüz bir grubun yok. Grup oluştur veya '
                                    'WhatsApp’tan gelen 6 karakterli kodla katıl.',
                              );
                            }
                            return Column(
                              children: groups
                                  .map(
                                    (ArenaGroup group) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _GroupCard(
                                        group: group,
                                        currentUid: _arena.currentUid,
                                        onTap: () => _openGroup(group),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
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

class ArenaGroupPage extends StatefulWidget {
  final String groupId;
  const ArenaGroupPage({super.key, required this.groupId});
  @override
  State<ArenaGroupPage> createState() => _ArenaGroupPageState();
}

class _ArenaGroupPageState extends State<ArenaGroupPage> {
  final ArenaService _arena = ArenaService.instance;
  final OnlineLeaderboardService _leaderboard =
      OnlineLeaderboardService.instance;
  late final Stream<ArenaGroup?> _groupStream;
  late final Stream<List<ArenaAttempt>> _groupAttemptsStream;
  late final Stream<List<ArenaEvent>> _groupEventsStream;
  Future<List<OnlineLeaderboardEntry>>? _memberProfilesFuture;
  String _memberProfilesKey = '';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final String groupId = widget.groupId.trim();
    _groupStream = _arena.watchGroup(groupId);
    _groupAttemptsStream = _arena.watchGroupAttempts(groupId);
    _groupEventsStream = _arena.watchGroupEvents(groupId);
  }

  Future<List<OnlineLeaderboardEntry>> _profilesForMembers(
    List<String> memberIds,
  ) {
    final List<String> normalizedIds = memberIds.toSet().toList()..sort();
    final String key = normalizedIds.join('|');
    if (_memberProfilesFuture == null || _memberProfilesKey != key) {
      _memberProfilesKey = key;
      _memberProfilesFuture = _leaderboard.fetchPlayersByUid(normalizedIds);
    }
    return _memberProfilesFuture!;
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _share(ArenaGroup group) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: '${group.name} • Zekâ Parkuru grup daveti',
        text:
            '${group.name} grubunda benimle yarış!\n'
            'Grup kodu: ${group.joinCode}\n'
            '${_arena.inviteUrl(group)}',
      ),
    );
  }

  Future<void> _createEvent(ArenaGroup group) async {
    if (_busy || group.memberIds.length < 2) {
      _message('Yarışma başlatmak için grupta en az 2 kişi olmalı.');
      return;
    }
    final String? activeEventId = group.activeEventId;
    if (activeEventId != null) {
      final ArenaEvent? activeEvent = await _arena.getEvent(activeEventId);
      if (!mounted) return;
      if (activeEvent != null && activeEvent.active) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                ArenaEventPage(group: group, initialEvent: activeEvent),
          ),
        );
        return;
      }
    }
    final _ArenaCreation? creation = await showDialog<_ArenaCreation>(
      context: context,
      builder: (_) => const _CreateArenaEventDialog(),
    );
    if (creation == null) return;
    setState(() => _busy = true);
    try {
      final ArenaEvent? event = await _arena.createEvent(
        group: group,
        rawTitle: creation.title,
        selectedGameIds: creation.gameIds,
      );
      if (!mounted) return;
      if (event == null) {
        final String? cause = _arena.lastEventError;
        _message(
          cause == 'permission-denied'
              ? 'Yarışma oluşturulamadı: sunucu izinleri güncel değil.'
              : 'Yarışma oluşturulamadı. Grup üyelerini ve bağlantıyı kontrol et.',
        );
        return;
      }
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ArenaEventPage(group: group, initialEvent: event),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ArenaGroup?>(
      stream: _groupStream,
      builder: (BuildContext context, AsyncSnapshot<ArenaGroup?> snapshot) {
        final ArenaGroup? group = snapshot.data;
        return Scaffold(
          backgroundColor: StudioVisuals.canvas,
          appBar: AppBar(
            backgroundColor: StudioVisuals.canvas,
            foregroundColor: StudioVisuals.ink,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              context.l10n.uppercaseLabel(group?.name ?? 'GRUP YÜKLENİYOR'),
              style: const TextStyle(
                color: StudioVisuals.ink,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            actions: <Widget>[
              if (group != null)
                IconButton(
                  tooltip: 'WhatsApp veya başka bir uygulamayla paylaş',
                  onPressed: () => _share(group),
                  icon: const Icon(Icons.share_rounded),
                ),
            ],
          ),
          body: group == null
              ? snapshot.hasError
                    ? Center(child: Text('Grup yüklenemedi: ${snapshot.error}'))
                    : const Center(child: CircularProgressIndicator())
              : ListView(
                  key: PageStorageKey<String>('arena_group_${group.id}'),
                  padding: const EdgeInsets.fromLTRB(
                    StudioVisuals.pageGutter,
                    12,
                    StudioVisuals.pageGutter,
                    32,
                  ),
                  children: <Widget>[
                    _GroupHero(
                      group: group,
                      onCopy: () async {
                        await Clipboard.setData(
                          ClipboardData(text: group.joinCode),
                        );
                        _message('Grup kodu kopyalandı.');
                      },
                      onShare: () => _share(group),
                    ),
                    const SizedBox(height: 16),
                    if (group.isOwner(_arena.currentUid))
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _createEvent(group),
                        icon: const Icon(Icons.emoji_events_rounded),
                        label: Text(
                          group.activeEventId == null
                              ? 'YENİ YARIŞMA BAŞLAT'
                              : 'AKTİF YARIŞMAYA DÖN',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: StudioVisuals.amber,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    const _ArenaSectionTitle(
                      icon: Icons.groups_2_rounded,
                      title: 'GRUP ÜYELERİ',
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<OnlineLeaderboardEntry>>(
                      future: _profilesForMembers(group.memberIds),
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<List<OnlineLeaderboardEntry>>
                            profileSnapshot,
                          ) {
                            final Map<String, OnlineLeaderboardEntry> profiles =
                                <String, OnlineLeaderboardEntry>{
                                  for (final OnlineLeaderboardEntry player
                                      in profileSnapshot.data ??
                                          const <OnlineLeaderboardEntry>[])
                                    player.uid: player,
                                };
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: group.memberIds
                                  .map((String uid) {
                                    final OnlineLeaderboardEntry? player =
                                        profiles[uid];
                                    return Chip(
                                      avatar: AvatarIcon(
                                        player?.avatar ?? '🧠',
                                        size: 28,
                                        borderRadius: 9,
                                      ),
                                      label: Text(
                                        player?.displayName ??
                                            (uid == _arena.currentUid
                                                ? 'Sen'
                                                : 'Oyuncu'),
                                      ),
                                      side: BorderSide(
                                        color: uid == group.ownerUid
                                            ? StudioVisuals.amber
                                            : StudioVisuals.line,
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            );
                          },
                    ),
                    const SizedBox(height: 22),
                    const _ArenaSectionTitle(
                      icon: Icons.calendar_view_week_rounded,
                      title: 'HAFTALIK GRUP LİGİ',
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<ArenaAttempt>>(
                      stream: _groupAttemptsStream,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<List<ArenaAttempt>> attemptSnapshot,
                          ) {
                            return FutureBuilder<List<OnlineLeaderboardEntry>>(
                              future: _profilesForMembers(group.memberIds),
                              builder:
                                  (
                                    BuildContext context,
                                    AsyncSnapshot<List<OnlineLeaderboardEntry>>
                                    profileSnapshot,
                                  ) {
                                    final List<ArenaWeeklyStanding> standings =
                                        _arena.buildWeeklyStandings(
                                          attempts:
                                              attemptSnapshot.data ??
                                              const <ArenaAttempt>[],
                                          profiles:
                                              profileSnapshot.data ??
                                              const <OnlineLeaderboardEntry>[],
                                        );
                                    return _WeeklyLeagueCard(
                                      standings: standings,
                                      currentUid: _arena.currentUid ?? '',
                                    );
                                  },
                            );
                          },
                    ),
                    const SizedBox(height: 22),
                    const _ArenaSectionTitle(
                      icon: Icons.military_tech_rounded,
                      title: 'YARIŞMALAR',
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<ArenaEvent>>(
                      stream: _groupEventsStream,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<List<ArenaEvent>> eventSnapshot,
                          ) {
                            if (eventSnapshot.hasError) {
                              return _ArenaInfo(
                                text:
                                    'Yarışmalar yüklenemedi: ${eventSnapshot.error}',
                              );
                            }
                            final List<ArenaEvent> events =
                                eventSnapshot.data ?? const <ArenaEvent>[];
                            if (events.isEmpty) {
                              return _ArenaInfo(
                                text:
                                    'Henüz yarışma yok. Grup yöneticisi '
                                    '${ArenaService.allGameIds.length} oyunluk '
                                    'havuzdan ${ArenaService.eventGameCount} farklı '
                                    'oyun seçilen ortak '
                                    'parkuru başlatabilir.',
                              );
                            }
                            return Column(
                              children: events
                                  .map(
                                    (ArenaEvent event) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _EventCard(
                                        event: event,
                                        onTap: () => Navigator.push<void>(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => ArenaEventPage(
                                              group: group,
                                              initialEvent: event,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            );
                          },
                    ),
                    const SizedBox(height: 12),
                    const _ArenaInfo(
                      icon: Icons.account_tree_rounded,
                      text:
                          'İlk 8 eleme tablosu; doğrudan sıralama sistemi '
                          'sahada doğrulandıktan sonra isteğe bağlı format olarak açılacak.',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class ArenaEventPage extends StatefulWidget {
  final ArenaGroup group;
  final ArenaEvent initialEvent;

  const ArenaEventPage({
    super.key,
    required this.group,
    required this.initialEvent,
  });

  @override
  State<ArenaEventPage> createState() => _ArenaEventPageState();
}

class _ArenaEventPageState extends State<ArenaEventPage> {
  static const Map<String, String> _reactionLabels = <String, String>{
    'good_game': 'İyi yarıştın 👏',
    'rematch': 'Rövanş? ⚔️',
    'close_game': 'Çok yakındı 😅',
    'congrats': 'Tebrikler 🏆',
  };

  final ArenaService _arena = ArenaService.instance;
  final ArenaRunProgressService _runProgress = ArenaRunProgressService.instance;
  final OnlineLeaderboardService _leaderboard =
      OnlineLeaderboardService.instance;

  late final Future<List<OnlineLeaderboardEntry>> _profiles;
  late final Stream<ArenaEvent?> _eventStream;
  late final Stream<List<ArenaAttempt>> _attemptsStream;
  late final Stream<List<ArenaReaction>> _reactionsStream;
  StreamSubscription<List<ArenaReaction>>? _reactionNoticeSubscription;

  final Map<String, String> _reactionState = <String, String>{};
  bool _reactionBaselineReady = false;
  bool _checkpointLoading = true;
  String _lastReconcileSignature = '';
  String? _playingGameId;
  bool _finishing = false;
  bool _reacting = false;
  ArenaRunCheckpoint? _checkpoint;
  ArenaEvent? _latestEvent;
  List<ArenaAttempt> _latestAttempts = const <ArenaAttempt>[];

  @override
  void initState() {
    super.initState();
    final String eventId = widget.initialEvent.id;
    _latestEvent = widget.initialEvent;
    _profiles = _leaderboard.fetchPlayersByUid(
      widget.initialEvent.participantIds,
    );
    _eventStream = _arena.watchEvent(eventId);
    _attemptsStream = _arena.watchAttempts(
      eventId: eventId,
      groupId: widget.initialEvent.groupId,
    );
    _reactionsStream = _arena
        .watchReactions(eventId: eventId, groupId: widget.initialEvent.groupId)
        .asBroadcastStream();
    _reactionNoticeSubscription = _reactionsStream.listen(
      _handleReactionNotices,
      onError: (Object error) {
        debugPrint('Arena reaction notice stream failed: $error');
      },
    );
    unawaited(_loadInitialCheckpoint(widget.initialEvent));
  }

  String _parkourFingerprint(ArenaEvent event) {
    return <String>[
      'arena-v2',
      event.id,
      '${event.schemaVersion}',
      '${event.level}',
      event.gameIds.join(','),
      event.gameIds
          .map((String gameId) => '${event.layoutCodeFor(gameId)}')
          .join(','),
    ].join('|');
  }

  _ArenaAttemptProgress _progressFromAttempts(
    ArenaEvent event,
    Iterable<ArenaAttempt> attempts,
  ) {
    final String uid = _arena.currentUid ?? '';
    final Map<String, ArenaAttempt> byGame = <String, ArenaAttempt>{};
    for (final ArenaAttempt attempt in attempts) {
      if (attempt.uid == uid && event.gameIds.contains(attempt.gameId)) {
        byGame.putIfAbsent(attempt.gameId, () => attempt);
      }
    }

    int nextIndex = 0;
    int totalPoints = 0;
    int totalStars = 0;
    int failedStages = 0;
    int skippedStages = 0;
    for (final String gameId in event.gameIds) {
      final ArenaAttempt? attempt = byGame[gameId];
      if (attempt == null) break;
      nextIndex += 1;
      totalPoints += attempt.points;
      totalStars += attempt.stars;
      if (attempt.outcome == ArenaAttemptOutcome.failed) {
        failedStages += 1;
      } else if (attempt.outcome == ArenaAttemptOutcome.skipped) {
        skippedStages += 1;
      }
    }

    return _ArenaAttemptProgress(
      nextStationIndex: nextIndex,
      totalPoints: totalPoints,
      totalStars: totalStars,
      failedStages: failedStages,
      skippedStages: skippedStages,
    );
  }

  Future<void> _loadInitialCheckpoint(ArenaEvent event) async {
    final String uid = _arena.currentUid ?? '';
    if (uid.isEmpty || !event.participantIds.contains(uid)) {
      if (mounted) setState(() => _checkpointLoading = false);
      return;
    }

    try {
      final List<ArenaAttempt> pending = await _arena
          .loadPendingAttemptsForEvent(event);
      final _ArenaAttemptProgress progress = _progressFromAttempts(
        event,
        pending,
      );
      final ArenaRunCheckpoint checkpoint = await _runProgress.loadOrCreate(
        eventId: event.id,
        playerUid: uid,
        parkourFingerprint: _parkourFingerprint(event),
        stationCount: event.gameIds.length,
        authoritativeNextStationIndex: progress.nextStationIndex,
        authoritativeTotalPoints: progress.totalPoints,
        authoritativeTotalStars: progress.totalStars,
        authoritativeFailedStages: progress.failedStages,
        authoritativeSkippedStages: progress.skippedStages,
      );
      if (!mounted) return;
      setState(() {
        _checkpoint = checkpoint;
        _checkpointLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Arena checkpoint load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _checkpointLoading = false);
        _message('Grup parkuru ilerlemesi hazırlanamadı. Tekrar dene.');
      }
    }
  }

  void _scheduleCheckpointReconcile(
    ArenaEvent event,
    List<ArenaAttempt> attempts,
  ) {
    final List<String> signatureParts = attempts
        .where((ArenaAttempt item) => item.uid == (_arena.currentUid ?? ''))
        .map(
          (ArenaAttempt item) =>
              '${item.id}:${item.outcome.name}:${item.points}:${item.stars}',
        )
        .toList(growable: false);
    signatureParts.sort();
    final String key = '${event.id}|${signatureParts.join(",")}';
    if (_checkpointLoading || key == _lastReconcileSignature) return;
    _lastReconcileSignature = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_reconcileCheckpoint(event, attempts));
    });
  }

  Future<void> _reconcileCheckpoint(
    ArenaEvent event,
    List<ArenaAttempt> attempts,
  ) async {
    final String uid = _arena.currentUid ?? '';
    if (uid.isEmpty || !event.participantIds.contains(uid)) return;
    try {
      final _ArenaAttemptProgress progress = _progressFromAttempts(
        event,
        attempts,
      );
      final ArenaRunCheckpoint checkpoint = await _runProgress.loadOrCreate(
        eventId: event.id,
        playerUid: uid,
        parkourFingerprint: _parkourFingerprint(event),
        stationCount: event.gameIds.length,
        authoritativeNextStationIndex: progress.nextStationIndex,
        authoritativeTotalPoints: progress.totalPoints,
        authoritativeTotalStars: progress.totalStars,
        authoritativeFailedStages: progress.failedStages,
        authoritativeSkippedStages: progress.skippedStages,
      );
      if (!mounted) return;
      final ArenaRunCheckpoint? current = _checkpoint;
      if (current == null ||
          current.nextStationIndex != checkpoint.nextStationIndex ||
          current.totalPoints != checkpoint.totalPoints ||
          current.totalStars != checkpoint.totalStars ||
          current.failedStages != checkpoint.failedStages ||
          current.skippedStages != checkpoint.skippedStages) {
        setState(() => _checkpoint = checkpoint);
      }
    } catch (error, stackTrace) {
      debugPrint('Arena checkpoint reconcile failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleReactionNotices(List<ArenaReaction> reactions) {
    final Map<String, String> next = <String, String>{
      for (final ArenaReaction reaction in reactions)
        reaction.id: reaction.reaction,
    };
    if (!_reactionBaselineReady) {
      _reactionState
        ..clear()
        ..addAll(next);
      _reactionBaselineReady = true;
      return;
    }
    final String currentUid = _arena.currentUid ?? '';
    for (final ArenaReaction reaction in reactions) {
      if (reaction.uid == currentUid ||
          _reactionState[reaction.id] == reaction.reaction) {
        continue;
      }
      SocialNotificationService.instance.showForegroundNotice(
        title: reaction.displayName,
        body:
            _reactionLabels[reaction.reaction] ??
            'Yeni bir grup yarışması mesajı geldi.',
      );
    }
    _reactionState
      ..clear()
      ..addAll(next);
  }

  @override
  void dispose() {
    unawaited(_reactionNoticeSubscription?.cancel());
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
      );
  }

  Future<void> _sendReaction(ArenaEvent event, String reaction) async {
    if (_reacting) return;
    setState(() => _reacting = true);
    try {
      final bool sent = await _arena.sendReaction(
        event: event,
        reaction: reaction,
      );
      if (!mounted) return;
      if (sent) {
        SocialNotificationService.instance.showForegroundNotice(
          title: 'Grup mesajı gönderildi',
          body:
              _reactionLabels[reaction] ??
              'Mesajın grup yarışmacılarına gönderildi.',
        );
      } else {
        _message('Mesaj gönderilemedi.');
      }
    } finally {
      if (mounted) setState(() => _reacting = false);
    }
  }

  ArenaAttempt? _attemptFor(
    List<ArenaAttempt> attempts,
    String uid,
    String gameId,
  ) {
    for (final ArenaAttempt attempt in attempts) {
      if (attempt.uid == uid && attempt.gameId == gameId) return attempt;
    }
    return null;
  }

  Future<void> _saveCheckpoint(ArenaRunCheckpoint checkpoint) async {
    if (mounted) {
      setState(() => _checkpoint = checkpoint);
    } else {
      _checkpoint = checkpoint;
    }
    try {
      await _runProgress.save(checkpoint);
    } catch (error, stackTrace) {
      debugPrint('Arena checkpoint save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _playParkour(ArenaEvent event) async {
    if (_playingGameId != null || !event.active || _checkpointLoading) return;
    if (!event.isPlayable) {
      _message(
        'Bu eski yarışma kaldırılmış oyun içeriyor. Güncel oyunlarla yeni bir yarışma başlat.',
      );
      return;
    }
    final String uid = _arena.currentUid ?? '';
    if (uid.isEmpty || !event.participantIds.contains(uid)) return;

    await _reconcileCheckpoint(event, _latestAttempts);
    if (!mounted) return;
    ArenaRunCheckpoint? checkpoint = _checkpoint;
    if (checkpoint == null) {
      await _loadInitialCheckpoint(event);
      checkpoint = _checkpoint;
    }
    if (!mounted || checkpoint == null) return;
    ArenaRunCheckpoint currentCheckpoint = checkpoint;

    if (currentCheckpoint.nextStationIndex > 0 &&
        currentCheckpoint.nextStationIndex < event.gameIds.length) {
      _message(
        'Parkura ${currentCheckpoint.nextStationIndex + 1}. bölümden devam ediliyor.',
      );
    }

    try {
      int index = currentCheckpoint.nextStationIndex;
      while (index < event.gameIds.length) {
        final ArenaEvent activeEvent = _latestEvent ?? event;
        if (!mounted || !activeEvent.active || !activeEvent.isPlayable) {
          _message('Yarışma artık aktif değil; kayıtlı ilerleme korunuyor.');
          return;
        }

        final String gameId = event.gameIds[index];
        final String gameName = challengeGameDefinition(gameId).name;
        bool stationResolved = false;

        while (!stationResolved) {
          if (!mounted) return;
          setState(() => _playingGameId = gameId);

          final Object? rawResult = await Navigator.push<Object?>(
            context,
            MaterialPageRoute<Object?>(
              builder: (_) => CompetitionStagePage(
                gameId: gameId,
                gameName: gameName,
                stageNumber: index + 1,
                stageCount: event.gameIds.length,
                gameBuilder: (_) => buildChallengeCompetitionPage(
                  gameId: gameId,
                  level: event.level,
                  layoutCode: event.layoutCodeFor(gameId),
                ),
              ),
            ),
          );
          if (!mounted) return;
          if (rawResult == CompetitionStageAction.leave) {
            _message(
              'İlerlemen kaydedildi. Parkura daha sonra devam edebilirsin.',
            );
            return;
          }

          DailyStageOutcome outcome = DailyStageOutcome.exited;
          int resultStars = 0;
          int rawScore = 0;
          if (rawResult is DailyStageResult && rawResult.gameId == gameId) {
            outcome = rawResult.outcome;
            resultStars = rawResult.stars;
            rawScore = rawResult.rawScore;
          } else if (rawResult is DailyCourseGameResult &&
              rawResult.gameId == gameId) {
            outcome = DailyStageOutcome.completed;
            resultStars = rawResult.stars;
            rawScore = rawResult.score;
          }

          if (outcome == DailyStageOutcome.exited) {
            setState(() => _playingGameId = null);
            final CompetitionExitDecision decision =
                await showCompetitionExitDecision(
                  context,
                  flowName: 'GRUP YARIŞI',
                  gameName: gameName,
                );
            if (!mounted) return;
            switch (decision) {
              case CompetitionExitDecision.retry:
                continue;
              case CompetitionExitDecision.leave:
                _message(
                  'İlerlemen kaydedildi. Bu bölüme kaldığın yerden '
                  'devam edebilirsin.',
                );
                return;
              case CompetitionExitDecision.skip:
                outcome = DailyStageOutcome.skipped;
                break;
            }
          }

          final ArenaAttemptOutcome attemptOutcome;
          switch (outcome) {
            case DailyStageOutcome.completed:
              attemptOutcome = ArenaAttemptOutcome.completed;
              break;
            case DailyStageOutcome.failed:
              attemptOutcome = ArenaAttemptOutcome.failed;
              resultStars = 0;
              rawScore = 0;
              break;
            case DailyStageOutcome.skipped:
              attemptOutcome = ArenaAttemptOutcome.skipped;
              resultStars = 0;
              rawScore = 0;
              break;
            case DailyStageOutcome.exited:
              continue;
          }

          final bool saved = await _arena.submitAttempt(
            event: event,
            gameId: gameId,
            outcome: attemptOutcome,
            rawScore: rawScore,
            stars: resultStars,
          );
          if (!mounted) return;
          if (!saved) {
            setState(() => _playingGameId = null);
            _message(
              'Bu bölüm kaydedilemedi. Parkur durduruldu; daha önce '
              'kaydedilen bölümler yeniden oynatılmayacak.',
            );
            return;
          }

          final int safeStars = attemptOutcome == ArenaAttemptOutcome.completed
              ? resultStars.clamp(0, 3).toInt()
              : 0;
          final int stagePoints =
              attemptOutcome == ArenaAttemptOutcome.completed
              ? ArenaService.competitionPoints(safeStars)
              : 0;
          currentCheckpoint = currentCheckpoint.copyWith(
            nextStationIndex: index + 1,
            totalPoints: currentCheckpoint.totalPoints + stagePoints,
            totalStars: currentCheckpoint.totalStars + safeStars,
            failedStages:
                currentCheckpoint.failedStages +
                (attemptOutcome == ArenaAttemptOutcome.failed ? 1 : 0),
            skippedStages:
                currentCheckpoint.skippedStages +
                (attemptOutcome == ArenaAttemptOutcome.skipped ? 1 : 0),
          );
          await _saveCheckpoint(currentCheckpoint);
          stationResolved = true;
          if (mounted) setState(() => _playingGameId = null);

          if (!mounted) return;
          await CompetitionStageTransition.show(
            context,
            completedCount: index + 1,
            totalCount: event.gameIds.length,
            stars: safeStars,
            score: stagePoints,
            flowName: 'GRUP YARIŞI',
            nextGameName: index + 1 < event.gameIds.length
                ? challengeGameDefinition(event.gameIds[index + 1]).name
                : null,
          );
        }

        index = currentCheckpoint.nextStationIndex;
      }

      if (mounted) {
        _message('${event.gameIds.length} oyunluk grup parkurun tamamlandı.');
      }
    } catch (error, stackTrace) {
      debugPrint('Arena parkour flow failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _message(
          'Grup parkuru durdu. Kaydedilen bölümden güvenle devam '
          'edebilirsin.',
        );
      }
    } finally {
      if (mounted && _playingGameId != null) {
        setState(() => _playingGameId = null);
      }
    }
  }

  Future<void> _finish(ArenaEvent event) async {
    if (_finishing) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('YARIŞMAYI BİTİR'),
        content: const Text(
          'Sıralama mevcut sonuçlarla kesinleşecek. Henüz tamamlamayanlar '
          'artık oyun oynayamayacak. Devam edilsin mi?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('BİTİR'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _finishing = true);
    final bool saved = await _arena.finishEvent(event);
    if (!mounted) return;
    setState(() => _finishing = false);
    if (saved) {
      final String uid = _arena.currentUid ?? '';
      if (uid.isNotEmpty) {
        await _runProgress.clear(eventId: event.id, playerUid: uid);
      }
    }
    if (mounted) {
      _message(saved ? 'Yarışma sonucu kesinleşti.' : 'Yarışma bitirilemedi.');
    }
  }

  Future<void> _shareResult(
    ArenaEvent event,
    List<ArenaStanding> standings,
  ) async {
    final StringBuffer result = StringBuffer()
      ..writeln('🏆 ${event.title} • Zekâ Parkuru Arena')
      ..writeln('${widget.group.name} grubunun kesin sonucu');
    final int podiumCount = standings.length < 3 ? standings.length : 3;
    for (int index = 0; index < podiumCount; index++) {
      final ArenaStanding item = standings[index];
      result.writeln(
        '${index + 1}. ${item.displayName} — '
        '${item.totalPoints} TP • ${item.totalStars} ⭐',
      );
    }
    result
      ..writeln()
      ..writeln('Grup kodu: ${widget.group.joinCode}')
      ..write(_arena.inviteUrl(widget.group));
    await SharePlus.instance.share(
      ShareParams(
        subject: '${event.title} • Arena sonucu',
        text: result.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ArenaEvent?>(
      stream: _eventStream,
      initialData: widget.initialEvent,
      builder: (BuildContext context, AsyncSnapshot<ArenaEvent?> eventSnapshot) {
        final ArenaEvent? event = eventSnapshot.data;
        if (event == null) {
          return Scaffold(
            backgroundColor: StudioVisuals.canvas,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        _latestEvent = event;

        return Scaffold(
          backgroundColor: StudioVisuals.canvas,
          appBar: AppBar(
            backgroundColor: StudioVisuals.canvas,
            foregroundColor: StudioVisuals.ink,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              context.l10n.uppercaseLabel(event.title),
              style: const TextStyle(
                color: StudioVisuals.ink,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            actions: <Widget>[
              IconButton(
                tooltip: 'Grup davetini paylaş',
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    subject: '${widget.group.name} Zekâ Yarışı',
                    text:
                        '${widget.group.name} grubundaki ${event.title} '
                        'yarışmasına katıl!\nKod: ${widget.group.joinCode}\n'
                        '${_arena.inviteUrl(widget.group)}',
                  ),
                ),
                icon: const Icon(Icons.share_rounded),
              ),
            ],
          ),
          body: FutureBuilder<List<OnlineLeaderboardEntry>>(
            future: _profiles,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<OnlineLeaderboardEntry>> profileSnapshot,
                ) {
                  return StreamBuilder<List<ArenaAttempt>>(
                    stream: _attemptsStream,
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<List<ArenaAttempt>> attemptSnapshot,
                        ) {
                          final List<ArenaAttempt> attempts =
                              attemptSnapshot.data ?? const <ArenaAttempt>[];
                          _latestAttempts = attempts;
                          if (attemptSnapshot.hasData) {
                            _scheduleCheckpointReconcile(event, attempts);
                          }

                          final String currentUid = _arena.currentUid ?? '';
                          final Set<String> resolvedByMe = attempts
                              .where(
                                (ArenaAttempt item) => item.uid == currentUid,
                              )
                              .map((ArenaAttempt item) => item.gameId)
                              .toSet();
                          final int localNext =
                              _checkpoint?.nextStationIndex ?? 0;
                          resolvedByMe.addAll(event.gameIds.take(localNext));

                          String? nextGameId;
                          for (final String gameId in event.gameIds) {
                            if (!resolvedByMe.contains(gameId)) {
                              nextGameId = gameId;
                              break;
                            }
                          }

                          final List<ArenaStanding> standings = _arena
                              .buildStandings(
                                event: event,
                                attempts: attempts,
                                profiles:
                                    profileSnapshot.data ??
                                    const <OnlineLeaderboardEntry>[],
                              );
                          final bool everyoneFinished =
                              standings.isNotEmpty &&
                              standings.every(
                                (ArenaStanding item) => item.finished,
                              );
                          final bool finalResult =
                              event.completed ||
                              event.expired ||
                              everyoneFinished;
                          final bool participant = event.participantIds
                              .contains(currentUid);
                          final bool attemptDataReady =
                              attemptSnapshot.hasData &&
                              !attemptSnapshot.hasError;
                          final bool canPlay =
                              event.active &&
                              participant &&
                              attemptDataReady &&
                              !_checkpointLoading &&
                              resolvedByMe.length < event.gameIds.length;

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(
                              StudioVisuals.pageGutter,
                              12,
                              StudioVisuals.pageGutter,
                              32,
                            ),
                            children: <Widget>[
                              _EventHero(
                                event: event,
                                finalResult: finalResult,
                                completedByMe: resolvedByMe.length,
                              ),
                              const SizedBox(height: 18),
                              if (!participant) ...<Widget>[
                                const _ArenaInfo(
                                  icon: Icons.visibility_rounded,
                                  text:
                                      'Bu yarışma sen gruba katılmadan '
                                      'önce başladı. Sonuçları '
                                      'izleyebilirsin; bir sonraki '
                                      'yarışmada katılımcı listesine '
                                      'otomatik ekleneceksin.',
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (attemptSnapshot.hasError) ...<Widget>[
                                _ArenaInfo(
                                  icon: Icons.cloud_off_rounded,
                                  text:
                                      'Sonuçlar doğrulanamadı: '
                                      '${attemptSnapshot.error}. '
                                      'Tekrar oynatmayı önlemek için '
                                      'parkur geçici olarak kilitlendi.',
                                ),
                                const SizedBox(height: 12),
                              ],
                              const _ArenaSectionTitle(
                                icon: Icons.sports_esports_rounded,
                                title: 'YARIŞMA OYUNLARI',
                              ),
                              const SizedBox(height: 8),
                              if (canPlay) ...<Widget>[
                                FilledButton.icon(
                                  onPressed: _playingGameId != null
                                      ? null
                                      : () => _playParkour(event),
                                  icon: const Icon(
                                    Icons.play_circle_fill_rounded,
                                  ),
                                  label: Text(
                                    resolvedByMe.isEmpty
                                        ? '${ArenaService.eventGameCount} '
                                              'OYUNLUK PARKURU BAŞLAT'
                                        : 'PARKURA DEVAM ET • '
                                              '${resolvedByMe.length}/'
                                              '${event.gameIds.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(54),
                                    backgroundColor: StudioVisuals.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              ...event.gameIds.map((String gameId) {
                                final _ArenaGameInfo info = _gameInfo(gameId);
                                final bool resolved = resolvedByMe.contains(
                                  gameId,
                                );
                                final ArenaAttempt? attempt = _attemptFor(
                                  attempts,
                                  currentUid,
                                  gameId,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: _CompetitionGameCard(
                                    info: info,
                                    resolved: resolved,
                                    outcome: attempt?.outcome,
                                    points: attempt?.points,
                                    stars: attempt?.stars,
                                    busy: _playingGameId == gameId,
                                    enabled:
                                        canPlay &&
                                        !resolved &&
                                        gameId == nextGameId,
                                    onPlay: () => _playParkour(event),
                                  ),
                                );
                              }),
                              const SizedBox(height: 18),
                              _ArenaSectionTitle(
                                icon: finalResult
                                    ? Icons.emoji_events_rounded
                                    : Icons.leaderboard_rounded,
                                title: finalResult
                                    ? 'KESİN SONUÇLAR'
                                    : 'CANLI SIRALAMA',
                              ),
                              const SizedBox(height: 8),
                              if (standings.isEmpty)
                                const _ArenaInfo(
                                  text: 'Henüz sonuç gönderilmedi.',
                                )
                              else ...<Widget>[
                                if (finalResult)
                                  ChampionCelebrationCard(
                                    key: ValueKey<String>(
                                      'arena_champion_${event.id}',
                                    ),
                                    title: 'MAŞALLAH!',
                                    subtitle:
                                        '${standings.first.displayName} '
                                        'grup şampiyonu 🏆',
                                    celebrate: true,
                                  ),
                                if (finalResult) const SizedBox(height: 10),
                                if (finalResult)
                                  _ArenaReactionPanel(
                                    event: event,
                                    reactionsStream: _reactionsStream,
                                    currentUid: currentUid,
                                    busy: _reacting,
                                    onReaction: (String reaction) =>
                                        _sendReaction(event, reaction),
                                  ),
                                if (finalResult) const SizedBox(height: 10),
                                if (finalResult) _Podium(standings: standings),
                                if (finalResult) const SizedBox(height: 10),
                                _StandingsList(
                                  standings: standings,
                                  currentUid: currentUid,
                                ),
                                if (finalResult) const SizedBox(height: 10),
                                if (finalResult)
                                  _ArenaResultShareCard(
                                    event: event,
                                    standings: standings,
                                    currentUid: currentUid,
                                    onShare: () =>
                                        _shareResult(event, standings),
                                  ),
                              ],
                              const SizedBox(height: 16),
                              _ArenaInfo(
                                icon: Icons.verified_rounded,
                                text:
                                    '${ArenaService.allGameIds.length} oyunluk '
                                    'havuzdan seçilen '
                                    '${ArenaService.eventGameCount} farklı '
                                    'oyunu herkes aynı sıra, seviye ve '
                                    'düzenle oynar. Tamamlanan, canları '
                                    'biten veya geçilen bölüm ikinci kez '
                                    'oynanamaz.',
                              ),
                              if (event.ownerUid == currentUid &&
                                  event.active) ...<Widget>[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _finishing
                                      ? null
                                      : () => _finish(event),
                                  icon: const Icon(Icons.flag_rounded),
                                  label: Text(
                                    _finishing
                                        ? 'BİTİRİLİYOR...'
                                        : 'YARIŞMAYI BİTİR VE SONUCU '
                                              'KESİNLEŞTİR',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    foregroundColor: StudioVisuals.amber,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                  );
                },
          ),
        );
      },
    );
  }
}

class _ArenaAttemptProgress {
  final int nextStationIndex;
  final int totalPoints;
  final int totalStars;
  final int failedStages;
  final int skippedStages;

  const _ArenaAttemptProgress({
    required this.nextStationIndex,
    required this.totalPoints,
    required this.totalStars,
    required this.failedStages,
    required this.skippedStages,
  });
}

class _ArenaCreation {
  final String title;
  final List<String> gameIds;
  const _ArenaCreation({required this.title, required this.gameIds});
}

class _CreateArenaEventDialog extends StatefulWidget {
  const _CreateArenaEventDialog();
  @override
  State<_CreateArenaEventDialog> createState() =>
      _CreateArenaEventDialogState();
}

class _CreateArenaEventDialogState extends State<_CreateArenaEventDialog> {
  final TextEditingController _titleController = TextEditingController(
    text: 'Haftanın Zekâ Yarışı',
  );
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ZpVisualPalette.of(context).surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
          child: Column(
            children: <Widget>[
              const Text(
                'YENİ YARIŞMA',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleController,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Yarışma adı',
                  border: OutlineInputBorder(),
                ),
              ),
              Expanded(
                child: Center(
                  child: _ArenaInfo(
                    icon: Icons.shuffle_rounded,
                    text:
                        'Sistem ${ArenaService.allGameIds.length} oyunluk '
                        'havuzdan ${ArenaService.eventGameCount} farklı oyunu '
                        'rastgele '
                        'seçecek. Gruptaki herkes aynı oyunları, aynı sırada '
                        've aynı ortak düzenlerle oynayacak.',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${ArenaService.eventGameCount} OYUNLUK RASTGELE PARKUR • 48 SAAT',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: StudioVisuals.teal,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('VAZGEÇ'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _ArenaCreation(
                          title: _titleController.text,
                          gameIds: ArenaService.allGameIds,
                        ),
                      ),
                      child: const Text('BAŞLAT'),
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

class _ArenaGameInfo {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _ArenaGameInfo({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const List<_ArenaGameInfo> _gameCatalog = <_ArenaGameInfo>[
  _ArenaGameInfo(
    id: 'numbers',
    name: 'Sayı Ustası',
    subtitle: 'Sayı kuralını bul',
    icon: Icons.calculate_rounded,
    color: Color(0xFF39B54A),
  ),
  _ArenaGameInfo(
    id: 'blocks',
    name: 'Blok Fırtınası',
    subtitle: 'Akıllı yerleşim',
    icon: Icons.grid_view_rounded,
    color: Color(0xFF168CFF),
  ),
  _ArenaGameInfo(
    id: 'memory',
    name: 'Hafıza Ustası',
    subtitle: 'Diziyi hatırla',
    icon: Icons.psychology_rounded,
    color: Color(0xFFE748CF),
  ),
  _ArenaGameInfo(
    id: 'card_pairs',
    name: 'Kart Çifti',
    subtitle: 'Değişen kuralla eşleri bul',
    icon: Icons.style_rounded,
    color: Color(0xFFE748CF),
  ),
  _ArenaGameInfo(
    id: 'focus_filter',
    name: 'Odak Filtresi',
    subtitle: 'Sinyali ele, hatalı alarmdan kaçın',
    icon: Icons.filter_center_focus_rounded,
    color: Color(0xFFD96767),
  ),
  _ArenaGameInfo(
    id: 'rhythm_memory',
    name: 'Ritim Hafızası',
    subtitle: 'Nota, aralık ve vurguyu tekrar et',
    icon: Icons.graphic_eq_rounded,
    color: Color(0xFF8974C9),
  ),
  _ArenaGameInfo(
    id: 'attention_tunnel',
    name: 'Dikkat Tüneli',
    subtitle: 'Kesişen hatlarda aynı hedefi izle',
    icon: Icons.blur_on_rounded,
    color: Color(0xFF6478C8),
  ),
  _ArenaGameInfo(
    id: 'hanoi',
    name: 'Hanoi Kulesi',
    subtitle: 'En az hamle',
    icon: Icons.account_tree_rounded,
    color: Color(0xFFFF5A3C),
  ),
  _ArenaGameInfo(
    id: 'word_hunt',
    name: 'Kelime Avı',
    subtitle: 'Gizli kelimeler',
    icon: Icons.travel_explore_rounded,
    color: Color(0xFF00D9A6),
  ),
  _ArenaGameInfo(
    id: 'meaning_match',
    name: 'Anlam Eşleştir',
    subtitle: 'Anlam kümelerini bul',
    icon: Icons.hub_rounded,
    color: Color(0xFF5B88C8),
  ),
  _ArenaGameInfo(
    id: 'sentence_builder',
    name: 'Cümle Kur',
    subtitle: 'Bağlaç ve cümle yapısını çöz',
    icon: Icons.format_align_left_rounded,
    color: Color(0xFF648B72),
  ),
  _ArenaGameInfo(
    id: 'near_meaning',
    name: 'Yakın Anlam',
    subtitle: 'Bağlamda sözcük nüansı seç',
    icon: Icons.manage_search_rounded,
    color: Color(0xFF648B72),
  ),
  _ArenaGameInfo(
    id: 'letter_maze',
    name: 'Harf Labirenti',
    subtitle: 'Harf rotasını kök kapısından geçir',
    icon: Icons.route_rounded,
    color: Color(0xFF648B72),
  ),
  _ArenaGameInfo(
    id: 'language_detective',
    name: 'Dil Dedektifi',
    subtitle: 'İddiayı kanıttan ayır',
    icon: Icons.manage_search_rounded,
    color: Color(0xFF648B72),
  ),
  _ArenaGameInfo(
    id: 'story_order',
    name: 'Hikâye Sırası',
    subtitle: 'Olayları kanıta göre sırala',
    icon: Icons.timeline_rounded,
    color: Color(0xFF5B88C8),
  ),
  _ArenaGameInfo(
    id: 'number_sort',
    name: '15 Taş Ustası',
    subtitle: 'Sayıları sırala',
    icon: Icons.grid_4x4_rounded,
    color: Color(0xFFB98548),
  ),
  _ArenaGameInfo(
    id: 'shape_puzzle',
    name: 'Şekil Birleştir',
    subtitle: 'Parçaları eşleştir',
    icon: Icons.interests_rounded,
    color: Color(0xFF8C6CFF),
  ),
  _ArenaGameInfo(
    id: 'reflex',
    name: 'Refleks Avı',
    subtitle: 'Hedefi yakala',
    icon: Icons.bolt_rounded,
    color: Color(0xFFFF5B5B),
  ),
];
_ArenaGameInfo _gameInfo(String gameId) {
  final _ArenaGameInfo definition = _gameCatalog.firstWhere(
    (_ArenaGameInfo item) => item.id == gameId,
    orElse: () {
      final GameDefinition? catalog = StudioGameCatalog.byId(gameId);
      return _ArenaGameInfo(
        id: gameId,
        name: catalog?.titleTr ?? 'Oyun',
        subtitle: 'Zekâ parkuru',
        icon: catalog?.gameClass.icon ?? Icons.sports_esports_rounded,
        color: catalog?.gameClass.accent ?? StudioVisuals.teal,
      );
    },
  );
  final Color accent = switch (definition.id) {
    'logic' ||
    'numbers' ||
    'memory' ||
    'card_pairs' ||
    'rhythm_memory' ||
    'attention_tunnel' => StudioVisuals.teal,
    'blocks' || 'hanoi' || 'number_sort' => StudioVisuals.amber,
    'reflex' || 'focus_filter' => StudioVisuals.danger,
    _ => StudioVisuals.muted,
  };
  return _ArenaGameInfo(
    id: definition.id,
    name: definition.name,
    subtitle: definition.subtitle,
    icon: definition.icon,
    color: accent,
  );
}

class _ArenaHero extends StatelessWidget {
  const _ArenaHero();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFE5F4F1), Color(0xFFFFFFFF)],
        ),
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.stadium_rounded, size: 42, color: StudioVisuals.teal),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ARKADAŞLARINLA AYNI PARKURDA YARIŞ',
                  style: TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '${ArenaService.allGameIds.length} oyunluk havuz • yarışmada '
            '${ArenaService.eventGameCount} farklı oyun • canlı sonuçlar • '
            'WhatsApp daveti',
            style: TextStyle(color: StudioVisuals.muted, height: 1.35),
          ),
          SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: double.infinity,
              height: 132,
              child: Image.asset(
                'assets/branding/studio_parkur_group_arena.webp',
                fit: BoxFit.cover,
                semanticLabel: 'Grup arenası görseli',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArenaActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailing;
  final String? imageAsset;
  final VoidCallback onTap;
  const _ArenaActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.imageAsset,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return StudioCard(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      minHeight: 96,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          if (imageAsset != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 62,
                height: 62,
                child: Image.asset(imageAsset!, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          Icon(Icons.chevron_right_rounded, color: color),
        ],
      ),
    );
  }
}

class _ArenaSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _ArenaSectionTitle({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: StudioVisuals.teal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ArenaInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ArenaInfo({
    this.icon = Icons.info_outline_rounded,
    required this.text,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: StudioVisuals.teal),
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
}

int _groupIdentityIndex(ArenaGroup group) {
  final String source = '${group.id}|${group.name}|${group.joinCode}';
  return source.codeUnits.fold<int>(
        0,
        (int value, int unit) => (value * 31 + unit) & 0x7fffffff,
      ) %
      6;
}

Color _groupIdentityColor(ArenaGroup group) => const <Color>[
  StudioVisuals.teal,
  Color(0xFFD69A43),
  Color(0xFF5B88C8),
  Color(0xFF648B72),
  Color(0xFF259C89),
  Color(0xFF758398),
][_groupIdentityIndex(group)];
IconData _groupIdentityIcon(ArenaGroup group) => const <IconData>[
  Icons.psychology_alt_rounded,
  Icons.rocket_launch_rounded,
  Icons.shield_rounded,
  Icons.bolt_rounded,
  Icons.auto_awesome_rounded,
  Icons.workspace_premium_rounded,
][_groupIdentityIndex(group)];
String _groupIdentityProfile(ArenaGroup group) => const <String>[
  'Meraklı zihinler takımı',
  'Hız ve strateji ekibi',
  'Kararlı parkur ustaları',
  'Günlük gelişim grubu',
  'Yıldız avcıları',
  'Dostça rekabet kulübü',
][_groupIdentityIndex(group)];

class _GroupCard extends StatelessWidget {
  final ArenaGroup group;
  final String? currentUid;
  final VoidCallback onTap;
  const _GroupCard({
    required this.group,
    required this.currentUid,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final Color identityColor = _groupIdentityColor(group);
    return _ArenaActionCard(
      icon: _groupIdentityIcon(group),
      color: group.isOwner(currentUid) ? StudioVisuals.amber : identityColor,
      title: context.l10n.uppercaseLabel(group.name),
      subtitle:
          '${_groupIdentityProfile(group)} • '
          '${group.memberIds.length}/30 oyuncu • Kod: ${group.joinCode}',
      trailing: group.isOwner(currentUid) ? 'YÖNETİCİ' : 'ÜYE',
      onTap: onTap,
    );
  }
}

class _GroupHero extends StatelessWidget {
  final ArenaGroup group;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  const _GroupHero({
    required this.group,
    required this.onCopy,
    required this.onShare,
  });
  @override
  Widget build(BuildContext context) {
    final Color identityColor = _groupIdentityColor(group);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            identityColor.withValues(alpha: 0.12),
            StudioVisuals.surface,
          ],
        ),
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: identityColor.withValues(alpha: 0.25)),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: identityColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: identityColor.withValues(alpha: 0.70),
                  ),
                ),
                child: Icon(
                  _groupIdentityIcon(group),
                  size: 31,
                  color: identityColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      group.name,
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      _groupIdentityProfile(group),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudioVisuals.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${group.memberIds.length}/30 oyuncu',
                      style: const TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: StudioVisuals.surfaceSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 360;
                final Widget codeActions = Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        group.joinCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_rounded, size: 20),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: onShare,
                      icon: const Icon(Icons.share_rounded, size: 20),
                    ),
                  ],
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'GRUP KODU',
                        style: TextStyle(
                          color: StudioVisuals.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      codeActions,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    const Text(
                      'GRUP KODU',
                      style: TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: codeActions),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyLeagueCard extends StatelessWidget {
  const _WeeklyLeagueCard({required this.standings, required this.currentUid});
  final List<ArenaWeeklyStanding> standings;
  final String currentUid;
  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return const _ArenaInfo(
        icon: Icons.hourglass_empty_rounded,
        text:
            'Bu hafta henüz Arena sonucu yok. İlk yarışma puanları '
            'otomatik olarak haftalık lige eklenecek.',
      );
    }
    final List<ArenaWeeklyStanding> visible = standings
        .take(5)
        .toList(growable: false);
    return Container(
      key: const ValueKey<String>('v9_arena_weekly_league'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[StudioVisuals.tealSoft, StudioVisuals.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        children: <Widget>[
          for (int index = 0; index < visible.length; index++) ...<Widget>[
            Builder(
              builder: (BuildContext context) {
                final ArenaWeeklyStanding item = visible[index];
                final bool me = item.uid == currentUid;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: me ? StudioVisuals.tealSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${index + 1}.',
                          style: TextStyle(
                            color: index == 0
                                ? StudioVisuals.amber
                                : StudioVisuals.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      AvatarIcon(item.avatar, size: 30, borderRadius: 9),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              me
                                  ? '${item.displayName} • SEN'
                                  : item.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: StudioVisuals.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${item.attemptCount} oyun • '
                              '${item.totalStars} ⭐',
                              style: const TextStyle(
                                color: StudioVisuals.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${item.totalPoints} TP',
                        style: const TextStyle(
                          color: StudioVisuals.amber,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (index != visible.length - 1)
              const Divider(height: 1, color: StudioVisuals.line),
          ],
          const SizedBox(height: 7),
          const Text(
            'Pazartesi 00.00’dan itibaren gönderilen Arena sonuçları',
            textAlign: TextAlign.center,
            style: TextStyle(color: StudioVisuals.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final ArenaEvent event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final bool open = event.active;
    return _ArenaActionCard(
      icon: open ? Icons.play_circle_fill_rounded : Icons.emoji_events_rounded,
      color: open ? StudioVisuals.teal : StudioVisuals.amber,
      title: context.l10n.uppercaseLabel(event.title),
      subtitle:
          '${event.gameIds.length} oyun • ${event.participantIds.length} yarışmacı • Doğrudan sıralama',
      trailing: open ? 'AKTİF' : 'SONUÇ',
      onTap: onTap,
    );
  }
}

class _EventHero extends StatelessWidget {
  final ArenaEvent event;
  final bool finalResult;
  final int completedByMe;
  const _EventHero({
    required this.event,
    required this.finalResult,
    required this.completedByMe,
  });
  @override
  Widget build(BuildContext context) {
    final double progress = event.gameIds.isEmpty
        ? 0
        : completedByMe / event.gameIds.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: finalResult
              ? const <Color>[StudioVisuals.amberSoft, StudioVisuals.surface]
              : const <Color>[StudioVisuals.tealSoft, StudioVisuals.surface],
        ),
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                finalResult
                    ? Icons.emoji_events_rounded
                    : Icons.stadium_rounded,
                size: 44,
                color: finalResult ? StudioVisuals.amber : StudioVisuals.teal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      '${event.participantIds.length} yarışmacı • ${event.gameIds.length} oyun',
                      style: const TextStyle(color: StudioVisuals.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: StudioVisuals.line,
            valueColor: const AlwaysStoppedAnimation<Color>(StudioVisuals.teal),
          ),
          const SizedBox(height: 7),
          Text(
            finalResult
                ? 'Sonuçlar kesinleşti'
                : 'Senin ilerlemen: $completedByMe/${event.gameIds.length}',
            style: const TextStyle(
              color: StudioVisuals.ink,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionGameCard extends StatelessWidget {
  final _ArenaGameInfo info;
  final bool resolved;
  final ArenaAttemptOutcome? outcome;
  final int? points;
  final int? stars;
  final bool busy;
  final bool enabled;
  final VoidCallback onPlay;

  const _CompetitionGameCard({
    required this.info,
    required this.resolved,
    required this.outcome,
    required this.points,
    required this.stars,
    required this.busy,
    required this.enabled,
    required this.onPlay,
  });

  String get _resultText {
    if (!resolved) return 'Ortak parkur • Seviye 1 • Tek hak';
    return switch (outcome) {
      ArenaAttemptOutcome.completed => '${stars ?? 0}/3 ⭐ • ${points ?? 0} TP',
      ArenaAttemptOutcome.failed => 'CANLAR TÜKENDİ • 0 TP',
      ArenaAttemptOutcome.skipped => 'GEÇİLDİ • 0 TP',
      null => 'SONUÇ KAYITLI',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: resolved ? StudioVisuals.teal : StudioVisuals.line,
        ),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(info.icon, color: info.color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  info.name,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _resultText,
                  style: TextStyle(
                    color: resolved ? StudioVisuals.teal : StudioVisuals.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: enabled && !busy ? onPlay : null,
            style: FilledButton.styleFrom(
              backgroundColor: resolved ? StudioVisuals.tealSoft : info.color,
              foregroundColor: StudioVisuals.ink,
            ),
            child: Text(
              busy
                  ? 'AÇILIYOR'
                  : resolved
                  ? 'KAYITLI'
                  : 'OYNA',
            ),
          ),
        ],
      ),
    );
  }
}

class _ArenaReactionPanel extends StatelessWidget {
  final ArenaEvent event;
  final Stream<List<ArenaReaction>> reactionsStream;
  final String currentUid;
  final bool busy;
  final Future<void> Function(String reaction) onReaction;
  const _ArenaReactionPanel({
    required this.event,
    required this.reactionsStream,
    required this.currentUid,
    required this.busy,
    required this.onReaction,
  });
  static const Map<String, String> _labels = <String, String>{
    'good_game': 'İyi yarıştın 👏',
    'rematch': 'Rövanş? ⚔️',
    'close_game': 'Çok yakındı 😅',
    'congrats': 'Tebrikler 🏆',
  };
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ArenaReaction>>(
      stream: reactionsStream,
      builder:
          (BuildContext context, AsyncSnapshot<List<ArenaReaction>> snapshot) {
            final List<ArenaReaction> reactions =
                snapshot.data ?? const <ArenaReaction>[];
            String? mine;
            for (final ArenaReaction reaction in reactions) {
              if (reaction.uid == currentUid) {
                mine = reaction.reaction;
                break;
              }
            }
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
                  if (reactions.isNotEmpty) ...<Widget>[
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: reactions
                          .take(8)
                          .map((ArenaReaction item) {
                            return Chip(
                              avatar: AvatarIcon(
                                item.avatar,
                                size: 28,
                                borderRadius: 9,
                              ),
                              label: Text(
                                '${item.displayName}: '
                                '${_labels[item.reaction] ?? item.reaction}',
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const Text(
                    'KISA MESAJ GÖNDER',
                    style: TextStyle(
                      color: StudioVisuals.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _labels.entries
                        .map((MapEntry<String, String> item) {
                          return ChoiceChip(
                            label: Text(item.value),
                            selected: mine == item.key,
                            onSelected: busy
                                ? null
                                : (_) {
                                    unawaited(onReaction(item.key));
                                  },
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
              ),
            );
          },
    );
  }
}

class _ArenaResultShareCard extends StatelessWidget {
  const _ArenaResultShareCard({
    required this.event,
    required this.standings,
    required this.currentUid,
    required this.onShare,
  });
  final ArenaEvent event;
  final List<ArenaStanding> standings;
  final String currentUid;
  final VoidCallback onShare;
  @override
  Widget build(BuildContext context) {
    final ArenaStanding winner = standings.first;
    final int myIndex = standings.indexWhere(
      (ArenaStanding item) => item.uid == currentUid,
    );
    final ArenaStanding? me = myIndex < 0 ? null : standings[myIndex];
    final int gap = me == null ? 0 : winner.totalPoints - me.totalPoints;
    return Container(
      key: const ValueKey<String>('v9_arena_result_share_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[StudioVisuals.amberSoft, StudioVisuals.surface],
        ),
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.amber.withValues(alpha: 0.28)),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AvatarIcon(winner.avatar, size: 46, borderRadius: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'ARENA KAZANANI',
                      style: TextStyle(
                        fontSize: 9,
                        color: StudioVisuals.ink,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      winner.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${winner.totalPoints} TP • ${winner.totalStars} ⭐',
                      style: const TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Kesin sonucu paylaş',
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded),
              ),
            ],
          ),
          if (me != null) ...<Widget>[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: StudioVisuals.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: StudioVisuals.line),
              ),
              child: Text(
                myIndex == 0
                    ? 'Tebrikler! Bu yarışmanın lideri sensin.'
                    : 'Sen ${myIndex + 1}. sıradasın • Liderle fark: $gap TP',
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${event.gameIds.length} ortak oyun • Tek deneme kuralı korundu',
            style: const TextStyle(color: StudioVisuals.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<ArenaStanding> standings;
  const _Podium({required this.standings});
  @override
  Widget build(BuildContext context) {
    final List<ArenaStanding> top = standings.take(3).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[StudioVisuals.amberSoft, StudioVisuals.surface],
        ),
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.amber.withValues(alpha: 0.25)),
        boxShadow: StudioVisuals.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(3, (int index) {
          if (index >= top.length) return const Expanded(child: SizedBox());
          final List<int> order = top.length >= 3
              ? <int>[1, 0, 2]
              : List<int>.generate(top.length, (int i) => i);
          final int actualIndex = index < order.length ? order[index] : index;
          final ArenaStanding shown = top[actualIndex];
          final int place = actualIndex + 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AvatarIcon(
                    shown.avatar,
                    size: place == 1 ? 54 : 44,
                    borderRadius: place == 1 ? 16 : 13,
                  ),
                  Text(
                    shown.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: place == 1
                        ? 70
                        : place == 2
                        ? 52
                        : 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: place == 1
                          ? const Color(0xFFFFD93D)
                          : place == 2
                          ? const Color(0xFFC7D0DA)
                          : const Color(0xFFCD7F32),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      '$place',
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Text(
                    '${shown.totalPoints} TP',
                    style: const TextStyle(
                      color: StudioVisuals.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StandingsList extends StatelessWidget {
  final List<ArenaStanding> standings;
  final String currentUid;
  const _StandingsList({required this.standings, required this.currentUid});
  @override
  Widget build(BuildContext context) {
    int displayedRank = 0;
    int? previousPoints;
    int? previousCompleted;
    return Column(
      children: List<Widget>.generate(standings.length, (int index) {
        final ArenaStanding item = standings[index];
        if (previousPoints != item.totalPoints ||
            previousCompleted != item.completedGames) {
          displayedRank = index + 1;
          previousPoints = item.totalPoints;
          previousCompleted = item.completedGames;
        }
        final bool me = item.uid == currentUid;
        return Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: me ? StudioVisuals.tealSoft : StudioVisuals.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: me ? StudioVisuals.teal : StudioVisuals.line,
            ),
            boxShadow: StudioVisuals.softShadow,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 32,
                child: Text(
                  '$displayedRank.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              AvatarIcon(item.avatar, size: 34, borderRadius: 10),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      me ? '${item.displayName} • SEN' : item.displayName,
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${item.completedGames}/${item.totalGames} oyun • ${item.totalStars} ⭐',
                      style: const TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${item.totalPoints} TP',
                style: const TextStyle(
                  color: StudioVisuals.amber,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ArenaOffline extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String? reason;
  const _ArenaOffline({required this.onRetry, required this.reason});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              size: 66,
              color: StudioVisuals.teal,
            ),
            const SizedBox(height: 14),
            const Text(
              'ARENA ÇEVRİM DIŞI',
              style: TextStyle(
                color: StudioVisuals.ink,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason?.trim().isNotEmpty == true
                  ? reason!
                  : 'Grup ve canlı sonuçlar için internet gerekir.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: StudioVisuals.muted),
            ),
            const SizedBox(height: 8),
            const Text(
              'Normal oyunlar çevrimdışı çalışmaya devam eder.',
              textAlign: TextAlign.center,
              style: TextStyle(color: StudioVisuals.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
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
}
