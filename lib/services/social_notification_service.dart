import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap_service.dart';

@pragma('vm:entry-point')
Future<void> socialFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

typedef ChallengeLinkHandler = void Function(String challengeId);
typedef ArenaLinkHandler = void Function(String groupId, String joinCode);
typedef ForegroundNoticeHandler = void Function(
  String title,
  String body,
  String? challengeId,
  String? arenaGroupId,
  String? arenaJoinCode,
);

class SocialNotificationService {
  SocialNotificationService._();

  static final SocialNotificationService instance =
      SocialNotificationService._();

  final FirebaseBootstrapService _firebase = FirebaseBootstrapService.instance;

  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _challengeStateSubscription;

  final Map<String, Map<String, dynamic>> _challengeState =
      <String, Map<String, dynamic>>{};

  bool _challengeBaselineReady = false;

  Timer? _startupRetryTimer;
  ChallengeLinkHandler? _onChallengeLink;
  ArenaLinkHandler? _onArenaLink;
  ForegroundNoticeHandler? _onForegroundNotice;
  bool _started = false;
  bool _messagingStarted = false;
  String? _lastChallengeId;
  DateTime? _lastChallengeAt;
  String? _lastArenaInvite;
  DateTime? _lastArenaAt;

  bool get _supportsNativeMessaging =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> start({
    required ChallengeLinkHandler onChallengeLink,
    required ArenaLinkHandler onArenaLink,
    required ForegroundNoticeHandler onForegroundNotice,
  }) async {
    _onChallengeLink = onChallengeLink;
    _onArenaLink = onArenaLink;
    _onForegroundNotice = onForegroundNotice;
    if (!_supportsNativeMessaging) return;

    if (!_started) {
      _started = true;
      try {
        final AppLinks appLinks = AppLinks();
        final Uri? initialLink = await appLinks.getInitialLink();
        _openUri(initialLink);
        _linkSubscription = appLinks.uriLinkStream.listen(
          _openUri,
          onError: (Object error) {
            debugPrint('Challenge link stream failed: $error');
          },
        );
      } catch (error) {
        debugPrint('Challenge link initialization failed: $error');
      }
    }

    await _firebase.initialize();
    if (!_firebase.ready) {
      _scheduleStartupRetry();
      return;
    }
    _startupRetryTimer?.cancel();
    _startupRetryTimer = null;
    await _ensureMessagingListeners();
    await _ensureChallengeStateListener();
  }

  void _scheduleStartupRetry() {
    if (_startupRetryTimer?.isActive == true) return;
    _startupRetryTimer = Timer(const Duration(minutes: 1), () {
      _startupRetryTimer = null;
      final ChallengeLinkHandler? challenge = _onChallengeLink;
      final ArenaLinkHandler? arena = _onArenaLink;
      final ForegroundNoticeHandler? notice = _onForegroundNotice;
      if (challenge == null || arena == null || notice == null) return;
      unawaited(
        start(
          onChallengeLink: challenge,
          onArenaLink: arena,
          onForegroundNotice: notice,
        ),
      );
    });
  }

  Future<void> _ensureMessagingListeners({
    bool registerAuthorizedDevice = true,
  }) async {
    if (_messagingStarted) return;
    _messagingStarted = true;
    try {
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _openMessage,
      );
      _messageSubscription = FirebaseMessaging.onMessage.listen((
        RemoteMessage message,
      ) {
        _onForegroundNotice?.call(
          message.notification?.title ?? 'Zeka Parkuru',
          message.notification?.body ?? 'Yeni bir düello güncellemen var.',
          _challengeIdFromMessage(message),
          _arenaGroupIdFromMessage(message),
          _arenaJoinCodeFromMessage(message),
        );
      });

      final RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      _openMessage(initialMessage);

      final NotificationSettings settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (registerAuthorizedDevice &&
          _isAuthorized(settings.authorizationStatus)) {
        await _registerDevice();
      }
    } catch (error) {
      await _openedSubscription?.cancel();
      await _messageSubscription?.cancel();
      _openedSubscription = null;
      _messageSubscription = null;
      _messagingStarted = false;
      debugPrint('Social notifications initialization failed: $error');
    }
  }

  Future<void> _ensureChallengeStateListener() async {
    if (_challengeStateSubscription != null) return;

    final String? uid = _firebase.uid;
    if (uid == null || uid.isEmpty) return;

    _challengeState.clear();
    _challengeBaselineReady = false;

    _challengeStateSubscription = FirebaseFirestore.instance
        .collection('challenges_v1')
        .where('participantIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          _handleChallengeStateSnapshot,
          onError: (Object error) {
            debugPrint('Live challenge notification stream failed: $error');
          },
        );
  }

  void _handleChallengeStateSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final String? uid = _firebase.uid;
    if (uid == null || uid.isEmpty) return;

    final Map<String, Map<String, dynamic>> next =
        <String, Map<String, dynamic>>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>> document
        in snapshot.docs) {
      next[document.id] = Map<String, dynamic>.from(document.data());
    }

    // İlk snapshot yalnız mevcut durumu baz alır.
    // Uygulama açılır açılmaz eski düellolar için bildirim üretmeyiz.
    if (!_challengeBaselineReady) {
      _challengeState
        ..clear()
        ..addAll(next);

      _challengeBaselineReady = true;
      return;
    }

    for (final MapEntry<String, Map<String, dynamic>> item in next.entries) {
      final String challengeId = item.key;
      final Map<String, dynamic> current = item.value;
      final Map<String, dynamic>? previous = _challengeState[challengeId];

      final String challengerUid = _socialText(current['challengerUid']) ?? '';

      final String? opponentUid = _socialText(current['opponentUid']);

      final String? targetUid = _socialText(current['targetUid']);

      final String status = _socialText(current['status']) ?? '';

      // --------------------------------------------------------
      // YENİ DOĞRUDAN MEYDAN OKUMA
      // --------------------------------------------------------

      if (previous == null) {
        if (status == 'pending' &&
            challengerUid.isNotEmpty &&
            challengerUid != uid &&
            targetUid == uid) {
          final String challengerName =
              _socialText(current['challengerName']) ?? 'Bir oyuncu';

          _emitChallengeNotice(
            title: 'Meydan Okuma',
            body: '$challengerName sana meydan okudu.',
            challengeId: challengeId,
          );
        }

        continue;
      }

      final int schemaVersion = current['schemaVersion'] is num
          ? (current['schemaVersion'] as num).toInt()
          : 1;

      // --------------------------------------------------------
      // RAKİBİN SERİYİ TAMAMLAMASI
      // --------------------------------------------------------

      if (schemaVersion >= 2) {
        dynamic oldOtherScore;
        dynamic newOtherScore;

        if (uid == challengerUid) {
          oldOtherScore = previous['opponentScore'];
          newOtherScore = current['opponentScore'];
        } else if (uid == opponentUid) {
          oldOtherScore = previous['challengerScore'];
          newOtherScore = current['challengerScore'];
        }

        if (oldOtherScore == null && newOtherScore is num) {
          _emitChallengeNotice(
            title: 'Meydan Okuma',
            body: 'Rakibin seriyi tamamladı.',
            challengeId: challengeId,
          );
        }
      }

      // --------------------------------------------------------
      // RÖVANŞ TEPKİSİ
      // --------------------------------------------------------

      String? oldOtherReaction;
      String? newOtherReaction;

      if (uid == challengerUid) {
        oldOtherReaction = _socialText(previous['opponentReaction']);
        newOtherReaction = _socialText(current['opponentReaction']);
      } else if (uid == opponentUid) {
        oldOtherReaction = _socialText(previous['challengerReaction']);
        newOtherReaction = _socialText(current['challengerReaction']);
      }

      const Map<String, String> reactionMessages = <String, String>{
        'good_game': 'İyi oynadın 👏',
        'rematch': 'Rövanş isteği geldi. ⚔️',
        'close_game': 'Çok yakındı 😅',
        'congrats': 'Tebrikler 🏆',
      };

      if (newOtherReaction != null &&
          newOtherReaction != oldOtherReaction &&
          reactionMessages.containsKey(newOtherReaction)) {
        _emitChallengeNotice(
          title: newOtherReaction == 'rematch'
              ? 'Rövanş'
              : 'Meydan Okuma Mesajı',
          body: reactionMessages[newOtherReaction]!,
          challengeId: challengeId,
        );
      }
    }

    _challengeState
      ..clear()
      ..addAll(next);
  }

  String? _socialText(dynamic value) {
    if (value is! String) return null;

    final String normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void showForegroundNotice({
    required String title,
    required String body,
    String? challengeId,
    String? arenaGroupId,
    String? arenaJoinCode,
  }) {
    _onForegroundNotice?.call(
      title,
      body,
      challengeId,
      arenaGroupId,
      arenaJoinCode,
    );
  }
  void _emitChallengeNotice({
    required String title,
    required String body,
    required String challengeId,
  }) {
    _onForegroundNotice?.call(title, body, challengeId, null, null);
  }

  Future<bool> enableNotifications() async {
    if (!_supportsNativeMessaging) return false;
    await _firebase.initialize();
    if (!_firebase.ready) return false;

    try {
      final NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
      if (!_isAuthorized(settings.authorizationStatus)) return false;
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      await _ensureMessagingListeners(registerAuthorizedDevice: false);
      return await _registerDevice();
    } catch (error) {
      debugPrint('Notification permission failed: $error');
      return false;
    }
  }

  bool _isAuthorized(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<bool> _registerDevice() async {
    final String? uid = _firebase.uid;
    if (uid == null || uid.isEmpty) return false;

    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return false;
      await _saveToken(uid, token);
      await _tokenSubscription?.cancel();
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
        newToken,
      ) {
        _saveToken(uid, newToken);
      });
      return true;
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
      return false;
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('player_devices_v1')
          .doc(uid)
          .set(<String, dynamic>{
            'uid': uid,
            'token': token,
            'platform': 'android',
            'locale': Platform.localeName,
            'updatedAt': FieldValue.serverTimestamp(),
            'schemaVersion': 1,
          });
    } catch (error) {
      debugPrint('FCM token save failed: $error');
    }
  }

  void _openMessage(RemoteMessage? message) {
    if (message == null) return;
    final String? challengeId = _challengeIdFromMessage(message);
    if (challengeId != null) {
      _dispatchChallenge(challengeId);
      return;
    }
    final String? groupId = _arenaGroupIdFromMessage(message);
    final String? joinCode = _arenaJoinCodeFromMessage(message);
    if (groupId != null && joinCode != null) {
      _dispatchArena(groupId, joinCode);
    }
  }

  String? _challengeIdFromMessage(RemoteMessage message) {
    final dynamic raw = message.data['challengeId'];
    if (raw is! String || raw.trim().isEmpty) return null;
    return raw.trim();
  }

  String? _arenaGroupIdFromMessage(RemoteMessage message) {
    final dynamic raw = message.data['groupId'];
    if (raw is! String || raw.trim().isEmpty) return null;
    return raw.trim();
  }

  String? _arenaJoinCodeFromMessage(RemoteMessage message) {
    final dynamic raw = message.data['joinCode'];
    if (raw is! String || raw.trim().isEmpty) return null;
    return raw.trim();
  }

  void _openUri(Uri? uri) {
    if (uri == null) return;
    String? challengeId;
    String? groupId;
    String? joinCode;
    if (uri.scheme == 'zekaparkuru' && uri.host == 'challenge') {
      challengeId = uri.queryParameters['id'];
    } else if (uri.scheme == 'zekaparkuru' && uri.host == 'arena') {
      groupId = uri.queryParameters['g'];
      joinCode = uri.queryParameters['code'];
    } else if (uri.scheme == 'https' &&
        uri.host == 'zeka-parkuru-eu-2026.web.app' &&
        uri.path == '/davet.html') {
      challengeId = uri.queryParameters['c'];
    } else if (uri.scheme == 'https' &&
        uri.host == 'zeka-parkuru-eu-2026.web.app' &&
        uri.path == '/arena.html') {
      groupId = uri.queryParameters['g'];
      joinCode = uri.queryParameters['code'];
    }
    if (challengeId != null && challengeId.trim().isNotEmpty) {
      _dispatchChallenge(challengeId.trim());
    }
    if (groupId != null &&
        groupId.trim().isNotEmpty &&
        joinCode != null &&
        joinCode.trim().isNotEmpty) {
      _dispatchArena(groupId.trim(), joinCode.trim());
    }
  }

  void _dispatchChallenge(String challengeId) {
    final DateTime now = DateTime.now();
    if (_lastChallengeId == challengeId &&
        _lastChallengeAt != null &&
        now.difference(_lastChallengeAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastChallengeId = challengeId;
    _lastChallengeAt = now;
    Future<void>.delayed(Duration.zero, () {
      _onChallengeLink?.call(challengeId);
    });
  }

  void _dispatchArena(String groupId, String joinCode) {
    final DateTime now = DateTime.now();
    final String invite = '$groupId:$joinCode';
    if (_lastArenaInvite == invite &&
        _lastArenaAt != null &&
        now.difference(_lastArenaAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastArenaInvite = invite;
    _lastArenaAt = now;
    Future<void>.delayed(Duration.zero, () {
      _onArenaLink?.call(groupId, joinCode);
    });
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _challengeStateSubscription?.cancel();

    _challengeStateSubscription = null;
    _challengeState.clear();
    _challengeBaselineReady = false;

    _startupRetryTimer?.cancel();
    _startupRetryTimer = null;
    _started = false;
    _messagingStarted = false;
  }
}
