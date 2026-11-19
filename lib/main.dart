import 'dart:async';

import 'widgets/studio_game_artwork.dart';
import 'widgets/avatar_icon.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/balloon_catcher/balloon_catcher_game_page.dart';
import 'package:zeka_parkuru/games/bottle_target/bottle_target_game_page.dart';
import 'package:zeka_parkuru/games/color_reactor/color_reactor_game_page.dart';
import 'package:zeka_parkuru/games/ball_merge/ball_merge_game_page.dart';
import 'package:zeka_parkuru/games/tower_balance/tower_balance_game_page.dart';
import 'package:zeka_parkuru/games/magnet_path/magnet_path_game_page.dart';
import 'package:zeka_parkuru/games/mini_golf_route/mini_golf_game_page.dart';
import 'package:zeka_parkuru/games/slide_sweets/slide_sweets_game_page.dart';
import 'package:zeka_parkuru/games/ring_toss/ring_toss_game_page.dart';
import 'package:zeka_parkuru/games/little_fisher/little_fisher_game_page.dart';
import 'package:zeka_parkuru/games/marble_route/marble_route_game_page.dart';
import 'package:zeka_parkuru/games/block_flow/block_flow_game_page.dart';
import 'package:zeka_parkuru/games/paper_flight/paper_flight_game_page.dart';
import 'package:zeka_parkuru/games/neon_pinball/neon_pinball_game_page.dart';
import 'package:zeka_parkuru/games/kite_runner/kite_runner_game_page.dart';
import 'package:zeka_parkuru/games/rhythm_drums/rhythm_drums_game_page.dart';
import 'package:zeka_parkuru/games/skate_combo/skate_combo_game_page.dart';
import 'package:zeka_parkuru/games/snowboard_slalom/snowboard_slalom_game_page.dart';
import 'package:zeka_parkuru/games/jetpack_courier/jetpack_courier_game_page.dart';
import 'package:zeka_parkuru/games/orbit_rescue/orbit_rescue_game_page.dart';
import 'package:zeka_parkuru/games/drift_league/drift_league_game_page.dart';
import 'package:zeka_parkuru/games/table_tennis_rally/table_tennis_rally_game_page.dart';
import 'package:zeka_parkuru/games/penalty_mindgame/penalty_mindgame_game_page.dart';
import 'package:zeka_parkuru/games/air_hockey_arena/air_hockey_arena_game_page.dart';
import 'package:zeka_parkuru/games/relic_run/relic_run_game_page.dart';
import 'package:zeka_parkuru/games/lighthouse_defense/lighthouse_defense_game_page.dart';
import 'package:zeka_parkuru/games/museum_after_hours/museum_after_hours_game_page.dart';
import 'package:zeka_parkuru/games/deep_current/deep_current_game_page.dart';
import 'package:zeka_parkuru/games/cafe_shift/cafe_shift_game_page.dart';
import 'package:zeka_parkuru/games/interior_studio/interior_studio_game_page.dart';
import 'package:zeka_parkuru/games/tideglass_aquarium/tideglass_aquarium_game_page.dart';
import 'package:zeka_parkuru/games/pet_rescue_clinic/pet_rescue_clinic_game_page.dart';
import 'package:zeka_parkuru/games/boardwalk_builder/boardwalk_builder_game_page.dart';
import 'package:zeka_parkuru/games/moonbase_ops/moonbase_ops_game_page.dart';
import 'package:zeka_parkuru/games/museum_curator/museum_curator_game_page.dart';
import 'package:zeka_parkuru/games/festival_producer/festival_producer_game_page.dart';
import 'package:zeka_parkuru/games/secret_room_party/secret_room_party_game_page.dart';
import 'package:zeka_parkuru/games/dice_bluff_arena/dice_bluff_arena_game_page.dart';
import 'package:zeka_parkuru/games/signal_pair/signal_pair_game_page.dart';
import 'package:zeka_parkuru/games/deckforge_duel/deckforge_duel_game_page.dart';
import 'package:zeka_parkuru/games/bubble_shooter/bubble_shooter_game_page.dart';
import 'package:zeka_parkuru/games/arrow_route/arrow_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/arrow_maze_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/atlas_find_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/atlas_puzzle.dart';
import 'package:zeka_parkuru/games/reference_games/katamino_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/single_stroke_game_page.dart';
import 'package:zeka_parkuru/games/chess_mate/chess_mate_game_page.dart';
import 'package:zeka_parkuru/games/loop_master/loop_game_page.dart';
import 'package:zeka_parkuru/games/go_life_death/go_life_death_game_page.dart';
import 'package:zeka_parkuru/games/code_breaker/code_breaker_game_page.dart';
import 'package:zeka_parkuru/games/shogi_mate/shogi_mate_game_page.dart';
import 'package:zeka_parkuru/games/island_sea/island_sea_game_page.dart';
import 'package:zeka_parkuru/games/peg_solitaire/peg_solitaire_game_page.dart';
import 'package:zeka_parkuru/games/futoshiki/futoshiki_game_page.dart';
import 'package:zeka_parkuru/games/hex_connection/hex_connection_game_page.dart';
import 'package:zeka_parkuru/games/skyscrapers/skyscrapers_game_page.dart';
import 'package:zeka_parkuru/games/hitori/hitori_game_page.dart';
import 'package:zeka_parkuru/games/blocks/block_game_page.dart';
import 'package:zeka_parkuru/games/bridge_builder/bridge_builder_game_page.dart';
import 'package:zeka_parkuru/games/balance_scale/balance_scale_game_page.dart';
import 'package:zeka_parkuru/games/logic/logic_game_page.dart';
import 'package:zeka_parkuru/games/memory/memory_game_page.dart';
import 'package:zeka_parkuru/games/card_pairs/card_pairs_game_page.dart';
import 'package:zeka_parkuru/games/focus_filter/focus_filter_game_page.dart';
import 'package:zeka_parkuru/games/spot_change/spot_change_game_page.dart';
import 'package:zeka_parkuru/games/rhythm_memory/rhythm_memory_game_page.dart';
import 'package:zeka_parkuru/games/attention_tunnel/attention_tunnel_game_page.dart';
import 'package:zeka_parkuru/games/mini_sudoku/mini_sudoku_game_page.dart';
import 'package:zeka_parkuru/games/kenken_cube/kenken_cube_game_page.dart';
import 'package:zeka_parkuru/games/mahjong_layers/mahjong_layers_game_page.dart';
import 'package:zeka_parkuru/games/hidden_masses/hidden_masses_game_page.dart';
import 'package:zeka_parkuru/games/kakuro/kakuro_game_page.dart';
import 'package:zeka_parkuru/games/reversi_arena/reversi_game_page.dart';
import 'package:zeka_parkuru/games/mine_detector/mine_detector_game_page.dart';
import 'package:zeka_parkuru/games/warehouse_master/warehouse_master_game_page.dart';
import 'package:zeka_parkuru/games/numbers/number_game_page.dart';
import 'package:zeka_parkuru/games/parking_puzzle/parking_puzzle_game_page.dart';
import 'package:zeka_parkuru/games/picross_master/picross_game_page.dart';
import 'package:zeka_parkuru/games/tavla_master/tavla_game_page.dart';
import 'package:zeka_parkuru/games/pin_unlock/pin_unlock_game_page.dart';
import 'package:zeka_parkuru/games/hanoi/hanoi_game_page.dart';
import 'package:zeka_parkuru/games/candy_sort/candy_sort_game_page.dart';
import 'package:zeka_parkuru/games/circuit_repair/circuit_repair_game_page.dart';
import 'package:zeka_parkuru/games/detective_notes/detective_notes_game_page.dart';
import 'package:zeka_parkuru/games/flow_connect/flow_connect_game_page.dart';
import 'package:zeka_parkuru/games/gate_sequence/gate_sequence_game_page.dart';
import 'package:zeka_parkuru/games/number_sort/number_sort_game_page.dart';
import 'package:zeka_parkuru/games/picture_iq/picture_iq_game_page.dart';
import 'package:zeka_parkuru/games/reflex/reflex_game_page.dart';
import 'package:zeka_parkuru/games/shape_puzzle/shape_puzzle_game_page.dart';
import 'package:zeka_parkuru/games/shared/studio_game_skin.dart';
import 'package:zeka_parkuru/games/shared/game_visual_design.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/target_24/target_24_game_page.dart';
import 'package:zeka_parkuru/games/word_hunt/word_hunt_game_page.dart';
import 'package:zeka_parkuru/games/word_wheel/word_wheel_game_page.dart';
import 'package:zeka_parkuru/games/meaning_match/meaning_match_game_page.dart';
import 'package:zeka_parkuru/games/proverb_finish/proverb_finish_game_page.dart';
import 'package:zeka_parkuru/games/sentence_builder/sentence_builder_game_page.dart';
import 'package:zeka_parkuru/games/near_meaning/near_meaning_game_page.dart';
import 'package:zeka_parkuru/games/letter_maze/letter_maze_game_page.dart';
import 'package:zeka_parkuru/games/language_detective/language_detective_game_page.dart';
import 'package:zeka_parkuru/games/story_order/story_order_game_page.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/pages/animated_splash_page.dart';
import 'package:zeka_parkuru/pages/arena_page.dart';
import 'package:zeka_parkuru/pages/challenge_center_page.dart';
import 'package:zeka_parkuru/pages/daily_course_page.dart';
import 'package:zeka_parkuru/pages/daily_tasks_page.dart';
import 'package:zeka_parkuru/pages/leaderboard_page.dart';
import 'package:zeka_parkuru/pages/profile_page.dart';
import 'package:zeka_parkuru/pages/settings_page.dart';
import 'package:zeka_parkuru/services/app_analytics_service.dart';
import 'package:zeka_parkuru/services/app_error_monitoring_service.dart';
import 'package:zeka_parkuru/services/app_experience_controller.dart';
import 'package:zeka_parkuru/services/app_language_controller.dart';
import 'package:zeka_parkuru/services/daily_challenge_service.dart';
import 'package:zeka_parkuru/services/daily_reminder_service.dart';
import 'package:zeka_parkuru/services/game_audio_service.dart';
import 'package:zeka_parkuru/services/home_personalization_service.dart';
import 'package:zeka_parkuru/services/onboarding_preference_service.dart';
import 'package:zeka_parkuru/services/online_leaderboard_service.dart';
import 'package:zeka_parkuru/services/player_progress_service.dart';
import 'package:zeka_parkuru/services/social_notification_service.dart';
import 'package:zeka_parkuru/services/unified_progress_service.dart';
import 'package:zeka_parkuru/services/zeka_scoring_service.dart';
import 'package:zeka_parkuru/theme/app_visual_theme.dart';
import 'package:zeka_parkuru/theme/studio_game_visuals.dart';
import 'package:zeka_parkuru/theme/studio_visuals.dart';
import 'package:zeka_parkuru/widgets/fast_game_route.dart';
import 'package:zeka_parkuru/widgets/studio_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GestureBinding.instance.resamplingEnabled = true;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  AppErrorMonitoringService.instance.installGlobalHandlers();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    FirebaseMessaging.onBackgroundMessage(
      socialFirebaseMessagingBackgroundHandler,
    );
  }

  runApp(const ZekaParkuruApp());
}

class ZekaParkuruApp extends StatefulWidget {
  const ZekaParkuruApp({super.key});

  @override
  State<ZekaParkuruApp> createState() => _ZekaParkuruAppState();
}

class _ZekaParkuruAppState extends State<ZekaParkuruApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  OverlayEntry? _noticeOverlay;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    unawaited(AppExperienceController.instance.init());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SocialNotificationService.instance.start(
        onChallengeLink: _openChallenge,
        onArenaLink: _openArenaInvite,
        onForegroundNotice: _showForegroundNotice,
      );
      unawaited(
        DailyReminderService.instance.start(
          onOpenDailyCourse: _openDailyCourse,
        ),
      );
    });
  }

  void _openDailyCourse() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => const DailyCoursePage(),
        settings: const RouteSettings(name: '/daily-course'),
      ),
    );
  }

  void _openChallenge(String challengeId) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeCenterPage(initialChallengeId: challengeId),
      ),
    );
  }

  void _openArenaInvite(String groupId, String joinCode) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ArenaPage(initialGroupId: groupId, initialJoinCode: joinCode),
      ),
    );
  }

  void _showForegroundNotice(
    String title,
    String body,
    String? challengeId,
    String? arenaGroupId,
    String? arenaJoinCode,
  ) {
    final OverlayState? overlay = _navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    void openNotice() {
      _removeForegroundNotice();
      if (challengeId != null) {
        _openChallenge(challengeId);
      } else if (arenaGroupId != null && arenaJoinCode != null) {
        _openArenaInvite(arenaGroupId, arenaJoinCode);
      }
    }

    _removeForegroundNotice();
    _noticeOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 14,
        right: 14,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: challengeId == null && arenaGroupId == null
                ? _removeForegroundNotice
                : openNotice,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF173D5C), Color(0xFF492785)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFD93D), width: 2),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x88000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFD93D),
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFFFFD93D),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          body,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (challengeId != null || arenaGroupId != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'AÇ',
                        style: TextStyle(
                          color: Color(0xFF6CFF9B),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_noticeOverlay!);
    _noticeTimer = Timer(const Duration(seconds: 6), _removeForegroundNotice);
  }

  void _removeForegroundNotice() {
    _noticeTimer?.cancel();
    _noticeTimer = null;
    _noticeOverlay?.remove();
    _noticeOverlay = null;
  }

  @override
  void dispose() {
    _removeForegroundNotice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLanguageController language = AppLanguageController.instance;
    final AppExperienceController experience = AppExperienceController.instance;

    return AnimatedBuilder(
      animation: language,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: experience,
          builder: (context, _) {
            final ZpVisualPalette selectedPalette = ZpVisualPalette.forTheme(
              experience.visualTheme,
            );
            final ZpVisualPalette effectivePalette = experience.highContrast
                ? ZpVisualPalette.highContrast
                : selectedPalette;
            final bool darkTheme = experience.highContrast;
            final ColorScheme colorScheme = experience.highContrast
                ? const ColorScheme.dark(
                    primary: Color(0xFF00E9FF),
                    secondary: Color(0xFFFFFF00),
                    surface: Color(0xFF07162E),
                    onSurface: Colors.white,
                  )
                : ColorScheme.fromSeed(
                    seedColor: effectivePalette.primary,
                    brightness: darkTheme ? Brightness.dark : Brightness.light,
                  );

            return MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'Zeka Parkuru',
              debugShowCheckedModeBanner: false,
              locale: language.resolvedLocale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: ThemeData(
                useMaterial3: true,
                brightness: darkTheme ? Brightness.dark : Brightness.light,
                scaffoldBackgroundColor: effectivePalette.background,
                colorScheme: colorScheme,
                extensions: <ThemeExtension<dynamic>>[effectivePalette],
                cardTheme: CardThemeData(
                  color: effectivePalette.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: StudioVisuals.cardRadius,
                    side: BorderSide(
                      color: experience.highContrast
                          ? const Color(0xFF36506F)
                          : StudioVisuals.line,
                    ),
                  ),
                ),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                focusColor: experience.highContrast
                    ? const Color(0xFFFFFF00)
                    : null,
              ),
              builder: (BuildContext context, Widget? child) {
                final MediaQueryData media = MediaQuery.of(context);
                final bool reduceMotion = experience.reduceMotion(
                  systemRequestsReducedMotion: media.disableAnimations,
                );
                final double systemScale = media.textScaler.scale(1);
                final double requestedScale =
                    experience.largeText && systemScale < 1.15
                    ? 1.15
                    : systemScale;
                final double textScale = requestedScale
                    .clamp(0.80, 2.0)
                    .toDouble();
                return MediaQuery(
                  data: media.copyWith(
                    disableAnimations: reduceMotion,
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const AnimatedSplashPage(destination: AnaSayfa()),
            );
          },
        );
      },
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  static const double _gameOpeningSoundGain = 1 / 3;

  final UnifiedProgressService _progressService = UnifiedProgressService();
  final AppExperienceController _experience = AppExperienceController.instance;

  final GameAudioService _audio = GameAudioService.instance;

  final DailyChallengeService _daily = DailyChallengeService.instance;

  final OnboardingPreferenceService _preferences =
      OnboardingPreferenceService.instance;

  final HomePersonalizationService _personalization =
      const HomePersonalizationService();

  DailyChallengeData? gunlukVeri;
  OnboardingPreferences? tercihVeri;

  final PlayerProgressService _player = PlayerProgressService.instance;

  PlayerDashboardData? oyuncuVeri;

  final OnlineLeaderboardService _online = OnlineLeaderboardService.instance;

  final AppAnalyticsService _analytics = AppAnalyticsService.instance;

  bool yukleniyor = true;
  bool _gameOpening = false;
  Map<String, ParkurProgressSnapshot> _referenceGameProgress =
      const <String, ParkurProgressSnapshot>{};

  int toplamPuan = 0;
  int toplamYildiz = 0;

  int mantikSeviye = 1;
  int sayiSeviye = 1;
  int blokSeviye = 1;
  int hafizaSeviye = 1;
  int cardPairsSeviye = 1;
  int focusFilterSeviye = 1;
  int spotChangeSeviye = 1;
  int rhythmMemorySeviye = 1;
  int attentionTunnelSeviye = 1;
  int hanoiSeviye = 1;
  int kelimeSeviye = 1;
  int gorselIqSeviye = 1;
  int sekerSeviye = 1;
  int sayiPetegiSeviye = 1;
  int sekilSeviye = 1;
  int refleksSeviye = 1;
  int akisSeviye = 1;
  int devreSeviye = 1;
  int dedektifSeviye = 1;
  int kopruSeviye = 1;
  int kapiDizisiSeviye = 1;
  int parkYeriSeviye = 1;
  int kilitAcSeviye = 1;
  int agirlikDengesiSeviye = 1;
  int hedef24Seviye = 1;
  int miniSudokuSeviye = 1;
  int kenkenSeviye = 1;
  int mahjongSeviye = 1;
  int mayinSeviye = 1;
  int depoUstasiSeviye = 1;
  int kelimeCarkiSeviye = 1;
  int gizliKutleSeviye = 1;
  int kakuroSeviye = 1;
  int reversiSeviye = 1;
  int picrossSeviye = 1;
  int tavlaSeviye = 1;
  int arrowRouteSeviye = 1;
  int satrancMatiSeviye = 1;
  int donguUstasiSeviye = 1;
  int goYasamOlumSeviye = 1;
  int kodKiriciSeviye = 1;
  int shogiMatSeviye = 1;
  int adaDenizSeviye = 1;
  int tekTasSeviye = 1;
  int futoshikiSeviye = 1;
  int hexConnectionSeviye = 1;
  int skyscrapersSeviye = 1;
  int hitoriSeviye = 1;
  int balloonSeviye = 1;
  int bottleTargetSeviye = 1;
  int colorReactorSeviye = 1;
  int ballMergeSeviye = 1;
  int towerBalanceSeviye = 1;
  int magnetPathSeviye = 1;
  int miniGolfSeviye = 1;
  int slideSweetsSeviye = 1;
  int ringTossSeviye = 1;
  int littleFisherSeviye = 1;
  int marbleRouteSeviye = 1;
  int blockFlowSeviye = 1;
  int paperFlightSeviye = 1;
  int neonPinballSeviye = 1;
  int kiteRunnerSeviye = 1;
  int rhythmDrumsSeviye = 1;
  int skateComboSeviye = 1;
  int snowboardSlalomSeviye = 1;
  int jetpackCourierSeviye = 1;
  int orbitRescueSeviye = 1;
  int driftLeagueSeviye = 1;
  int tableTennisRallySeviye = 1;
  int penaltyMindgameSeviye = 1;
  int airHockeyArenaSeviye = 1;
  int relicRunSeviye = 1;
  int lighthouseDefenseSeviye = 1;
  int museumAfterHoursSeviye = 1;
  int deepCurrentSeviye = 1;
  int cafeShiftSeviye = 1;
  int interiorStudioSeviye = 1;
  int tideglassAquariumSeviye = 1;
  int petRescueClinicSeviye = 1;
  int boardwalkBuilderSeviye = 1;
  int moonbaseOpsSeviye = 1;
  int museumCuratorSeviye = 1;
  int festivalProducerSeviye = 1;
  int secretRoomPartySeviye = 1;
  int diceBluffArenaSeviye = 1;
  int signalPairSeviye = 1;
  int deckforgeDuelSeviye = 1;
  int meaningMatchSeviye = 1;
  int proverbFinishSeviye = 1;
  int sentenceBuilderSeviye = 1;
  int nearMeaningSeviye = 1;
  int letterMazeSeviye = 1;
  int languageDetectiveSeviye = 1;
  int storyOrderSeviye = 1;

  int mantikPuani = 0;
  int sayiPuani = 0;
  int blokPuani = 0;
  int hafizaPuani = 0;
  int cardPairsPuani = 0;
  int focusFilterPuani = 0;
  int spotChangePuani = 0;
  int rhythmMemoryPuani = 0;
  int attentionTunnelPuani = 0;
  int hanoiPuani = 0;
  int kelimePuani = 0;
  int gorselIqPuani = 0;
  int sekerPuani = 0;
  int sayiPetegiPuani = 0;
  int sekilPuani = 0;
  int refleksPuani = 0;
  int akisPuani = 0;
  int devrePuani = 0;
  int dedektifPuani = 0;
  int kopruPuani = 0;
  int kapiDizisiPuani = 0;
  int parkYeriPuani = 0;
  int kilitAcPuani = 0;
  int agirlikDengesiPuani = 0;
  int hedef24Puani = 0;
  int miniSudokuPuani = 0;
  int kenkenPuani = 0;
  int mahjongPuani = 0;
  int mayinPuani = 0;
  int depoUstasiPuani = 0;
  int kelimeCarkiPuani = 0;
  int gizliKutlePuani = 0;
  int kakuroPuani = 0;
  int reversiPuani = 0;
  int picrossPuani = 0;
  int tavlaPuani = 0;
  int arrowRoutePuani = 0;
  int satrancMatiPuani = 0;
  int donguUstasiPuani = 0;
  int goYasamOlumPuani = 0;
  int kodKiriciPuani = 0;
  int shogiMatPuani = 0;
  int adaDenizPuani = 0;
  int tekTasPuani = 0;
  int futoshikiPuani = 0;
  int hexConnectionPuani = 0;
  int skyscrapersPuani = 0;
  int hitoriPuani = 0;
  int balloonPuani = 0;
  int bottleTargetPuani = 0;
  int colorReactorPuani = 0;
  int ballMergePuani = 0;
  int towerBalancePuani = 0;
  int magnetPathPuani = 0;
  int miniGolfPuani = 0;
  int slideSweetsPuani = 0;
  int ringTossPuani = 0;
  int littleFisherPuani = 0;
  int marbleRoutePuani = 0;
  int blockFlowPuani = 0;
  int paperFlightPuani = 0;
  int neonPinballPuani = 0;
  int kiteRunnerPuani = 0;
  int rhythmDrumsPuani = 0;
  int skateComboPuani = 0;
  int snowboardSlalomPuani = 0;
  int jetpackCourierPuani = 0;
  int orbitRescuePuani = 0;
  int meaningMatchPuani = 0;
  int proverbFinishPuani = 0;
  int sentenceBuilderPuani = 0;
  int nearMeaningPuani = 0;
  int letterMazePuani = 0;
  int languageDetectivePuani = 0;
  int storyOrderPuani = 0;

  int mantikYildiz = 0;
  int sayiYildiz = 0;
  int blokYildiz = 0;
  int hafizaYildiz = 0;
  int cardPairsYildiz = 0;
  int focusFilterYildiz = 0;
  int spotChangeYildiz = 0;
  int rhythmMemoryYildiz = 0;
  int attentionTunnelYildiz = 0;
  int hanoiYildiz = 0;
  int kelimeYildiz = 0;
  int gorselIqYildiz = 0;
  int sekerYildiz = 0;
  int sayiPetegiYildiz = 0;
  int sekilYildiz = 0;
  int refleksYildiz = 0;
  int akisYildiz = 0;
  int devreYildiz = 0;
  int dedektifYildiz = 0;
  int kopruYildiz = 0;
  int kapiDizisiYildiz = 0;
  int parkYeriYildiz = 0;
  int kilitAcYildiz = 0;
  int agirlikDengesiYildiz = 0;
  int hedef24Yildiz = 0;
  int miniSudokuYildiz = 0;
  int kenkenYildiz = 0;
  int mahjongYildiz = 0;
  int mayinYildiz = 0;
  int depoUstasiYildiz = 0;
  int kelimeCarkiYildiz = 0;
  int gizliKutleYildiz = 0;
  int kakuroYildiz = 0;
  int reversiYildiz = 0;
  int picrossYildiz = 0;
  int tavlaYildiz = 0;
  int arrowRouteYildiz = 0;
  int satrancMatiYildiz = 0;
  int donguUstasiYildiz = 0;
  int goYasamOlumYildiz = 0;
  int kodKiriciYildiz = 0;
  int shogiMatYildiz = 0;
  int adaDenizYildiz = 0;
  int tekTasYildiz = 0;
  int futoshikiYildiz = 0;
  int hexConnectionYildiz = 0;
  int skyscrapersYildiz = 0;
  int hitoriYildiz = 0;
  int balloonYildiz = 0;
  int bottleTargetYildiz = 0;
  int colorReactorYildiz = 0;
  int ballMergeYildiz = 0;
  int towerBalanceYildiz = 0;
  int magnetPathYildiz = 0;
  int miniGolfYildiz = 0;
  int slideSweetsYildiz = 0;
  int ringTossYildiz = 0;
  int littleFisherYildiz = 0;
  int marbleRouteYildiz = 0;
  int blockFlowYildiz = 0;
  int paperFlightYildiz = 0;
  int neonPinballYildiz = 0;
  int kiteRunnerYildiz = 0;
  int rhythmDrumsYildiz = 0;
  int skateComboYildiz = 0;
  int snowboardSlalomYildiz = 0;
  int jetpackCourierYildiz = 0;
  int orbitRescueYildiz = 0;
  int driftLeagueYildiz = 0;
  int driftLeaguePuani = 0;
  int tableTennisRallyYildiz = 0;
  int tableTennisRallyPuani = 0;
  int penaltyMindgameYildiz = 0;
  int penaltyMindgamePuani = 0;
  int airHockeyArenaYildiz = 0;
  int airHockeyArenaPuani = 0;
  int relicRunYildiz = 0;
  int relicRunPuani = 0;
  int lighthouseDefenseYildiz = 0;
  int lighthouseDefensePuani = 0;
  int museumAfterHoursYildiz = 0;
  int museumAfterHoursPuani = 0;
  int deepCurrentYildiz = 0;
  int deepCurrentPuani = 0;
  int cafeShiftYildiz = 0;
  int cafeShiftPuani = 0;
  int interiorStudioYildiz = 0;
  int interiorStudioPuani = 0;
  int tideglassAquariumYildiz = 0;
  int tideglassAquariumPuani = 0;
  int petRescueClinicYildiz = 0;
  int petRescueClinicPuani = 0;
  int boardwalkBuilderYildiz = 0;
  int boardwalkBuilderPuani = 0;
  int moonbaseOpsYildiz = 0;
  int moonbaseOpsPuani = 0;
  int museumCuratorYildiz = 0;
  int museumCuratorPuani = 0;
  int festivalProducerYildiz = 0;
  int festivalProducerPuani = 0;
  int secretRoomPartyYildiz = 0;
  int secretRoomPartyPuani = 0;
  int diceBluffArenaYildiz = 0;
  int diceBluffArenaPuani = 0;
  int signalPairYildiz = 0;
  int signalPairPuani = 0;
  int deckforgeDuelYildiz = 0;
  int deckforgeDuelPuani = 0;
  int meaningMatchYildiz = 0;
  int proverbFinishYildiz = 0;
  int sentenceBuilderYildiz = 0;
  int nearMeaningYildiz = 0;
  int letterMazeYildiz = 0;
  int languageDetectiveYildiz = 0;
  int storyOrderYildiz = 0;

  int tamamlananSeviye = 0;

  @override
  void initState() {
    super.initState();
    _experience.addListener(_experienceChanged);

    unawaited(_analytics.logScreen('home'));
    anaSayfayiYenile();
    unawaited(_sesleriHazirla());
  }

  void _experienceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _experience.removeListener(_experienceChanged);
    super.dispose();
  }

  Future<void> _sesleriHazirla() async {
    // Ses sistemi yardımcı bir katmandır.
    // Asset hatası ana ekranı veya oyunları bloke etmemeli.
    try {
      await _audio.preload(GameAudioGroup.ui);
      await _audio.playOpeningJingle();
    } catch (error) {
      debugPrint('Ana sayfa ses hazırlığı atlandı: $error');
    }
  }

  Future<void> anaSayfayiYenile() async {
    // Bağımsız yerel okumalar aynı anda başlar; ana ekran ve oyun dönüşü
    // gereksiz yere üç ayrı bekleme süresi ödemez.
    final Future<UnifiedProgressData> progressFuture = _progressService
        .genelIlerlemeyiYukle();
    final Future<DailyChallengeData> dailyFuture = _daily.loadToday();
    final Future<PlayerDashboardData> playerFuture = _player.load();
    final Future<OnboardingPreferences> preferenceFuture = _preferences.load();
    final Map<String, Future<ParkurProgressSnapshot>> referenceProgressLoads =
        <String, Future<ParkurProgressSnapshot>>{
          'city_atlas': ParkurProgressStore(
            prefix: 'city_atlas',
            levelCount: AtlasFindGamePage.totalCases,
          ).load(),
          'world_atlas': ParkurProgressStore(
            prefix: 'world_atlas',
            levelCount: AtlasFindGamePage.totalCases,
          ).load(),
          'katamino_workshop': ParkurProgressStore(
            prefix: 'katamino_workshop',
            levelCount: KataminoGamePage.totalCases,
          ).load(),
          'single_stroke': ParkurProgressStore(
            prefix: 'single_stroke',
            levelCount: SingleStrokeGamePage.totalCases,
          ).load(),
          'arrow_maze': ParkurProgressStore(
            prefix: 'arrow_maze',
            levelCount: ArrowMazeGamePage.totalCases,
          ).load(),
          'bubble_shooter': ParkurProgressStore(
            prefix: 'bubble_shooter',
            levelCount: BubbleShooterGamePage.totalLevels,
          ).load(),
        };
    final Future<ParkurProgressSnapshot> flowProgressFuture =
        ParkurProgressStore(prefix: 'flow_connect', levelCount: 10).load();
    final Future<ParkurProgressSnapshot> cardPairsProgressFuture =
        ParkurProgressStore(
          prefix: 'card_pairs',
          levelCount: CardPairsGamePage.totalLevels,
        ).load();
    final Future<ParkurProgressSnapshot> focusFilterProgressFuture =
        ParkurProgressStore(
          prefix: 'focus_filter',
          levelCount: FocusFilterGamePage.totalLevels,
        ).load();
    final Future<ParkurProgressSnapshot> spotChangeProgressFuture =
        ParkurProgressStore(
          prefix: 'spot_change',
          levelCount: SpotChangeGamePage.totalLevels,
        ).load();
    final Future<ParkurProgressSnapshot> rhythmMemoryProgressFuture =
        ParkurProgressStore(
          prefix: 'rhythm_memory',
          levelCount: RhythmMemoryGamePage.totalLevels,
        ).load();
    final Future<ParkurProgressSnapshot> attentionTunnelProgressFuture =
        ParkurProgressStore(
          prefix: 'attention_tunnel',
          levelCount: AttentionTunnelGamePage.totalLevels,
        ).load();
    final Future<ParkurProgressSnapshot> circuitProgressFuture =
        ParkurProgressStore(prefix: 'circuit_repair', levelCount: 10).load();
    final Future<ParkurProgressSnapshot> detectiveProgressFuture =
        ParkurProgressStore(
          prefix: 'detective_notes',
          levelCount: GameContentPolicy.campaignLevels,
        ).load();
    final Future<ParkurProgressSnapshot> bridgeProgressFuture =
        ParkurProgressStore(
          prefix: 'bridge_builder',
          levelCount: BridgeBuilderGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> gateSequenceProgressFuture =
        ParkurProgressStore(
          prefix: 'gate_sequence',
          levelCount: GateSequenceGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> parkingProgressFuture =
        ParkurProgressStore(
          prefix: 'parking_puzzle',
          levelCount: ParkingPuzzleGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> pinUnlockProgressFuture =
        ParkurProgressStore(
          prefix: 'pin_unlock',
          levelCount: PinUnlockGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> balanceScaleProgressFuture =
        ParkurProgressStore(
          prefix: 'balance_scale',
          levelCount: BalanceScaleGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> target24ProgressFuture =
        ParkurProgressStore(
          prefix: 'target_24',
          levelCount: Target24GamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> miniSudokuProgressFuture =
        ParkurProgressStore(
          prefix: 'mini_sudoku',
          levelCount: MiniSudokuGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> kenkenProgressFuture =
        ParkurProgressStore(
          prefix: 'kenken_cube',
          levelCount: KenKenCubeGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> mahjongProgressFuture =
        ParkurProgressStore(
          prefix: 'mahjong_layers',
          levelCount: MahjongLayersGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> mineDetectorProgressFuture =
        ParkurProgressStore(
          prefix: 'mine_detective',
          levelCount: MineDetectorGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> warehouseMasterProgressFuture =
        ParkurProgressStore(
          prefix: 'warehouse_master',
          levelCount: WarehouseMasterGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> wordWheelProgressFuture =
        ParkurProgressStore(
          prefix: 'word_wheel',
          levelCount: WordWheelGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> meaningMatchProgressFuture =
        ParkurProgressStore(
          prefix: 'meaning_match',
          levelCount: MeaningMatchGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> proverbFinishProgressFuture =
        ParkurProgressStore(
          prefix: 'proverb_finish',
          levelCount: ProverbFinishGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> sentenceBuilderProgressFuture =
        ParkurProgressStore(
          prefix: 'sentence_builder',
          levelCount: SentenceBuilderGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> nearMeaningProgressFuture =
        ParkurProgressStore(
          prefix: 'near_meaning',
          levelCount: NearMeaningGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> letterMazeProgressFuture =
        ParkurProgressStore(
          prefix: 'letter_maze',
          levelCount: LetterMazeGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> languageDetectiveProgressFuture =
        ParkurProgressStore(
          prefix: 'language_detective',
          levelCount: LanguageDetectiveGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> storyOrderProgressFuture =
        ParkurProgressStore(
          prefix: 'story_order',
          levelCount: StoryOrderGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> hiddenMassesProgressFuture =
        ParkurProgressStore(
          prefix: 'hidden_masses',
          levelCount: HiddenMassesGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> kakuroProgressFuture =
        ParkurProgressStore(
          prefix: 'kakuro',
          levelCount: KakuroGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> reversiProgressFuture =
        ParkurProgressStore(
          prefix: 'reversi_arena',
          levelCount: ReversiGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> picrossProgressFuture =
        ParkurProgressStore(
          prefix: 'picross_master',
          levelCount: PicrossGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> tavlaProgressFuture =
        ParkurProgressStore(
          prefix: 'tavla_master',
          levelCount: TavlaGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> arrowRouteProgressFuture =
        ParkurProgressStore(
          prefix: 'arrow_route',
          levelCount: ArrowRouteGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> chessMateProgressFuture =
        ParkurProgressStore(
          prefix: 'mini_chess_tactics',
          levelCount: ChessMateGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> loopMasterProgressFuture =
        ParkurProgressStore(
          prefix: 'loop_master',
          levelCount: LoopMasterGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> goLifeDeathProgressFuture =
        ParkurProgressStore(
          prefix: 'go_life_death',
          levelCount: GoLifeDeathGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> codeBreakerProgressFuture =
        ParkurProgressStore(
          prefix: 'code_breaker',
          levelCount: CodeBreakerGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> shogiMateProgressFuture =
        ParkurProgressStore(
          prefix: 'shogi_mate',
          levelCount: ShogiMateGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> islandSeaProgressFuture =
        ParkurProgressStore(
          prefix: 'island_sea',
          levelCount: IslandSeaGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> pegSolitaireProgressFuture =
        ParkurProgressStore(
          prefix: 'peg_solitaire',
          levelCount: PegSolitaireGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> futoshikiProgressFuture =
        ParkurProgressStore(
          prefix: 'futoshiki',
          levelCount: FutoshikiGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> hexConnectionProgressFuture =
        ParkurProgressStore(
          prefix: 'hex_connection',
          levelCount: HexConnectionGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> skyscrapersProgressFuture =
        ParkurProgressStore(
          prefix: 'skyscrapers',
          levelCount: SkyscrapersGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> hitoriProgressFuture =
        ParkurProgressStore(
          prefix: 'hitori',
          levelCount: HitoriGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> balloonProgressFuture =
        ParkurProgressStore(
          prefix: 'balloon_pop',
          levelCount: BalloonCatcherGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> bottleTargetProgressFuture =
        ParkurProgressStore(
          prefix: 'bottle_target',
          levelCount: BottleTargetGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> colorReactorProgressFuture =
        ParkurProgressStore(
          prefix: 'color_match',
          levelCount: ColorReactorGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> ballMergeProgressFuture =
        ParkurProgressStore(
          prefix: 'ball_merge',
          levelCount: BallMergeGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> towerBalanceProgressFuture =
        ParkurProgressStore(
          prefix: 'tower_balance',
          levelCount: TowerBalanceGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> magnetPathProgressFuture =
        ParkurProgressStore(
          prefix: 'magnet_path',
          levelCount: MagnetPathGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> miniGolfProgressFuture =
        ParkurProgressStore(
          prefix: 'mini_golf_route',
          levelCount: MiniGolfGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> slideSweetsProgressFuture =
        ParkurProgressStore(
          prefix: 'slide_sweets',
          levelCount: SlideSweetsGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> ringTossProgressFuture =
        ParkurProgressStore(
          prefix: 'ring_toss',
          levelCount: RingTossGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> littleFisherProgressFuture =
        ParkurProgressStore(
          prefix: 'little_fisher',
          levelCount: LittleFisherGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> marbleRouteProgressFuture =
        ParkurProgressStore(
          prefix: 'marble_route',
          levelCount: MarbleRouteGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> blockFlowProgressFuture =
        ParkurProgressStore(
          prefix: 'block_flow',
          levelCount: BlockFlowGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> paperFlightProgressFuture =
        ParkurProgressStore(
          prefix: 'paper_flight',
          levelCount: PaperFlightGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> neonPinballProgressFuture =
        ParkurProgressStore(
          prefix: 'neon_pinball',
          levelCount: NeonPinballGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> kiteRunnerProgressFuture =
        ParkurProgressStore(
          prefix: 'kite_runner',
          levelCount: KiteRunnerGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> rhythmDrumsProgressFuture =
        ParkurProgressStore(
          prefix: 'rhythm_drums',
          levelCount: RhythmDrumsGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> skateComboProgressFuture =
        ParkurProgressStore(
          prefix: 'skate_combo',
          levelCount: SkateComboGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> snowboardSlalomProgressFuture =
        ParkurProgressStore(
          prefix: 'snowboard_slalom',
          levelCount: SnowboardSlalomGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> jetpackCourierProgressFuture =
        ParkurProgressStore(
          prefix: 'jetpack_courier',
          levelCount: JetpackCourierGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> orbitRescueProgressFuture =
        ParkurProgressStore(
          prefix: 'orbit_rescue',
          levelCount: OrbitRescueGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> driftLeagueProgressFuture =
        ParkurProgressStore(
          prefix: 'drift_league',
          levelCount: DriftLeagueGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> tableTennisRallyProgressFuture =
        ParkurProgressStore(
          prefix: 'table_tennis_rally',
          levelCount: TableTennisRallyGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> penaltyMindgameProgressFuture =
        ParkurProgressStore(
          prefix: 'penalty_mindgame',
          levelCount: PenaltyMindgamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> airHockeyArenaProgressFuture =
        ParkurProgressStore(
          prefix: 'air_hockey_arena',
          levelCount: AirHockeyArenaPage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> relicRunProgressFuture =
        ParkurProgressStore(
          prefix: 'relic_run',
          levelCount: RelicRunGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> lighthouseDefenseProgressFuture =
        ParkurProgressStore(
          prefix: 'lighthouse_defense',
          levelCount: LighthouseDefenseGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> museumAfterHoursProgressFuture =
        ParkurProgressStore(
          prefix: 'museum_after_hours',
          levelCount: MuseumAfterHoursPage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> deepCurrentProgressFuture =
        ParkurProgressStore(
          prefix: 'deep_current',
          levelCount: DeepCurrentGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> cafeShiftProgressFuture =
        ParkurProgressStore(
          prefix: 'cafe_shift',
          levelCount: CafeShiftGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> interiorStudioProgressFuture =
        ParkurProgressStore(
          prefix: 'interior_studio',
          levelCount: InteriorStudioGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> tideglassAquariumProgressFuture =
        ParkurProgressStore(
          prefix: 'tideglass_aquarium',
          levelCount: TideglassAquariumGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> petRescueClinicProgressFuture =
        ParkurProgressStore(
          prefix: 'pet_rescue_clinic',
          levelCount: PetRescueClinicGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> boardwalkBuilderProgressFuture =
        ParkurProgressStore(
          prefix: 'boardwalk_builder',
          levelCount: BoardwalkBuilderGamePage.totalParks,
        ).load();
    final Future<ParkurProgressSnapshot> moonbaseOpsProgressFuture =
        ParkurProgressStore(
          prefix: 'moonbase_ops',
          levelCount: MoonbaseOpsGamePage.totalMissions,
        ).load();
    final Future<ParkurProgressSnapshot> museumCuratorProgressFuture =
        ParkurProgressStore(
          prefix: 'museum_curator',
          levelCount: MuseumCuratorGamePage.totalExhibitions,
        ).load();
    final Future<ParkurProgressSnapshot> festivalProducerProgressFuture =
        ParkurProgressStore(
          prefix: 'festival_producer',
          levelCount: FestivalProducerGamePage.totalFestivals,
        ).load();
    final Future<ParkurProgressSnapshot> secretRoomPartyProgressFuture =
        ParkurProgressStore(
          prefix: 'secret_room_party',
          levelCount: SecretRoomPartyGamePage.totalCases,
        ).load();
    final Future<ParkurProgressSnapshot> diceBluffArenaProgressFuture =
        ParkurProgressStore(
          prefix: 'dice_bluff_arena',
          levelCount: DiceBluffArenaGamePage.totalMatches,
        ).load();
    final Future<ParkurProgressSnapshot> signalPairProgressFuture =
        ParkurProgressStore(
          prefix: 'signal_pair',
          levelCount: SignalPairGamePage.totalMissions,
        ).load();
    final Future<ParkurProgressSnapshot> deckforgeDuelProgressFuture =
        ParkurProgressStore(
          prefix: 'deckforge_duel',
          levelCount: DeckforgeDuelGamePage.totalMissions,
        ).load();

    final UnifiedProgressData veri = await progressFuture;
    final DailyChallengeData daily = await dailyFuture;
    final PlayerDashboardData player = await playerFuture;
    final OnboardingPreferences preferences = await preferenceFuture;
    final ParkurProgressSnapshot flowProgress = await flowProgressFuture;
    final ParkurProgressSnapshot circuitProgress = await circuitProgressFuture;
    final ParkurProgressSnapshot detectiveProgress =
        await detectiveProgressFuture;
    final ParkurProgressSnapshot bridgeProgress = await bridgeProgressFuture;
    final ParkurProgressSnapshot gateSequenceProgress =
        await gateSequenceProgressFuture;
    final ParkurProgressSnapshot parkingProgress = await parkingProgressFuture;
    final ParkurProgressSnapshot pinUnlockProgress =
        await pinUnlockProgressFuture;
    final ParkurProgressSnapshot balanceScaleProgress =
        await balanceScaleProgressFuture;
    final ParkurProgressSnapshot target24Progress =
        await target24ProgressFuture;
    final ParkurProgressSnapshot miniSudokuProgress =
        await miniSudokuProgressFuture;
    final ParkurProgressSnapshot kenkenProgress = await kenkenProgressFuture;
    final ParkurProgressSnapshot mahjongProgress = await mahjongProgressFuture;
    final ParkurProgressSnapshot mineDetectorProgress =
        await mineDetectorProgressFuture;
    final ParkurProgressSnapshot warehouseMasterProgress =
        await warehouseMasterProgressFuture;
    final ParkurProgressSnapshot wordWheelProgress =
        await wordWheelProgressFuture;
    final ParkurProgressSnapshot meaningMatchProgress =
        await meaningMatchProgressFuture;
    final ParkurProgressSnapshot proverbFinishProgress =
        await proverbFinishProgressFuture;
    final ParkurProgressSnapshot sentenceBuilderProgress =
        await sentenceBuilderProgressFuture;
    final ParkurProgressSnapshot nearMeaningProgress =
        await nearMeaningProgressFuture;
    final ParkurProgressSnapshot letterMazeProgress =
        await letterMazeProgressFuture;
    final ParkurProgressSnapshot languageDetectiveProgress =
        await languageDetectiveProgressFuture;
    final ParkurProgressSnapshot storyOrderProgress =
        await storyOrderProgressFuture;
    final ParkurProgressSnapshot cardPairsProgress =
        await cardPairsProgressFuture;
    final ParkurProgressSnapshot focusFilterProgress =
        await focusFilterProgressFuture;
    final ParkurProgressSnapshot spotChangeProgress =
        await spotChangeProgressFuture;
    final ParkurProgressSnapshot rhythmMemoryProgress =
        await rhythmMemoryProgressFuture;
    final ParkurProgressSnapshot attentionTunnelProgress =
        await attentionTunnelProgressFuture;
    final ParkurProgressSnapshot hiddenMassesProgress =
        await hiddenMassesProgressFuture;
    final ParkurProgressSnapshot kakuroProgress = await kakuroProgressFuture;
    final ParkurProgressSnapshot reversiProgress = await reversiProgressFuture;
    final ParkurProgressSnapshot picrossProgress = await picrossProgressFuture;
    final ParkurProgressSnapshot tavlaProgress = await tavlaProgressFuture;
    final ParkurProgressSnapshot arrowRouteProgress =
        await arrowRouteProgressFuture;
    final ParkurProgressSnapshot chessMateProgress =
        await chessMateProgressFuture;
    final ParkurProgressSnapshot loopMasterProgress =
        await loopMasterProgressFuture;
    final ParkurProgressSnapshot goLifeDeathProgress =
        await goLifeDeathProgressFuture;
    final ParkurProgressSnapshot codeBreakerProgress =
        await codeBreakerProgressFuture;
    final ParkurProgressSnapshot shogiMateProgress =
        await shogiMateProgressFuture;
    final ParkurProgressSnapshot islandSeaProgress =
        await islandSeaProgressFuture;
    final ParkurProgressSnapshot pegSolitaireProgress =
        await pegSolitaireProgressFuture;
    final ParkurProgressSnapshot futoshikiProgress =
        await futoshikiProgressFuture;
    final ParkurProgressSnapshot hexConnectionProgress =
        await hexConnectionProgressFuture;
    final ParkurProgressSnapshot skyscrapersProgress =
        await skyscrapersProgressFuture;
    final ParkurProgressSnapshot hitoriProgress = await hitoriProgressFuture;
    final ParkurProgressSnapshot balloonProgress = await balloonProgressFuture;
    final ParkurProgressSnapshot bottleTargetProgress =
        await bottleTargetProgressFuture;
    final ParkurProgressSnapshot colorReactorProgress =
        await colorReactorProgressFuture;
    final ParkurProgressSnapshot ballMergeProgress =
        await ballMergeProgressFuture;
    final ParkurProgressSnapshot towerBalanceProgress =
        await towerBalanceProgressFuture;
    final ParkurProgressSnapshot magnetPathProgress =
        await magnetPathProgressFuture;
    final ParkurProgressSnapshot miniGolfProgress =
        await miniGolfProgressFuture;
    final ParkurProgressSnapshot slideSweetsProgress =
        await slideSweetsProgressFuture;
    final ParkurProgressSnapshot ringTossProgress =
        await ringTossProgressFuture;
    final ParkurProgressSnapshot littleFisherProgress =
        await littleFisherProgressFuture;
    final ParkurProgressSnapshot marbleRouteProgress =
        await marbleRouteProgressFuture;
    final ParkurProgressSnapshot blockFlowProgress =
        await blockFlowProgressFuture;
    final ParkurProgressSnapshot paperFlightProgress =
        await paperFlightProgressFuture;
    final ParkurProgressSnapshot neonPinballProgress =
        await neonPinballProgressFuture;
    final ParkurProgressSnapshot kiteRunnerProgress =
        await kiteRunnerProgressFuture;
    final ParkurProgressSnapshot rhythmDrumsProgress =
        await rhythmDrumsProgressFuture;
    final ParkurProgressSnapshot skateComboProgress =
        await skateComboProgressFuture;
    final ParkurProgressSnapshot snowboardSlalomProgress =
        await snowboardSlalomProgressFuture;
    final ParkurProgressSnapshot jetpackCourierProgress =
        await jetpackCourierProgressFuture;
    final ParkurProgressSnapshot orbitRescueProgress =
        await orbitRescueProgressFuture;
    final ParkurProgressSnapshot driftLeagueProgress =
        await driftLeagueProgressFuture;
    final ParkurProgressSnapshot tableTennisRallyProgress =
        await tableTennisRallyProgressFuture;
    final ParkurProgressSnapshot penaltyMindgameProgress =
        await penaltyMindgameProgressFuture;
    final ParkurProgressSnapshot airHockeyArenaProgress =
        await airHockeyArenaProgressFuture;
    final ParkurProgressSnapshot relicRunProgress =
        await relicRunProgressFuture;
    final ParkurProgressSnapshot lighthouseDefenseProgress =
        await lighthouseDefenseProgressFuture;
    final ParkurProgressSnapshot museumAfterHoursProgress =
        await museumAfterHoursProgressFuture;
    final ParkurProgressSnapshot deepCurrentProgress =
        await deepCurrentProgressFuture;
    final ParkurProgressSnapshot cafeShiftProgress =
        await cafeShiftProgressFuture;
    final ParkurProgressSnapshot interiorStudioProgress =
        await interiorStudioProgressFuture;
    final ParkurProgressSnapshot tideglassAquariumProgress =
        await tideglassAquariumProgressFuture;
    final ParkurProgressSnapshot petRescueClinicProgress =
        await petRescueClinicProgressFuture;
    final ParkurProgressSnapshot boardwalkBuilderProgress =
        await boardwalkBuilderProgressFuture;
    final ParkurProgressSnapshot moonbaseOpsProgress =
        await moonbaseOpsProgressFuture;
    final ParkurProgressSnapshot museumCuratorProgress =
        await museumCuratorProgressFuture;
    final ParkurProgressSnapshot festivalProducerProgress =
        await festivalProducerProgressFuture;
    final ParkurProgressSnapshot secretRoomPartyProgress =
        await secretRoomPartyProgressFuture;
    final ParkurProgressSnapshot diceBluffArenaProgress =
        await diceBluffArenaProgressFuture;
    final ParkurProgressSnapshot signalPairProgress =
        await signalPairProgressFuture;
    final ParkurProgressSnapshot deckforgeDuelProgress =
        await deckforgeDuelProgressFuture;
    final List<MapEntry<String, ParkurProgressSnapshot>>
    referenceProgressEntries = await Future.wait(
      referenceProgressLoads.entries.map(
        (entry) async => MapEntry(entry.key, await entry.value),
      ),
    );

    if (!mounted) return;

    setState(() {
      _referenceGameProgress = <String, ParkurProgressSnapshot>{
        for (final MapEntry<String, ParkurProgressSnapshot> entry
            in referenceProgressEntries)
          entry.key: entry.value,
      };
      toplamPuan = player.zekaScore;
      toplamYildiz = veri.toplamYildiz;
      tamamlananSeviye = veri.tamamlananSeviye;

      mantikSeviye = veri.mantik.acikSeviye;
      sayiSeviye = veri.sayi.acikSeviye;
      blokSeviye = veri.blok.acikSeviye;
      hafizaSeviye = veri.hafiza.acikSeviye;
      cardPairsSeviye = cardPairsProgress.unlockedLevel;
      focusFilterSeviye = focusFilterProgress.unlockedLevel;
      spotChangeSeviye = spotChangeProgress.unlockedLevel;
      rhythmMemorySeviye = rhythmMemoryProgress.unlockedLevel;
      attentionTunnelSeviye = attentionTunnelProgress.unlockedLevel;
      hanoiSeviye = veri.hanoi.acikSeviye;
      kelimeSeviye = veri.kelimeAvi.acikSeviye;
      gorselIqSeviye = veri.gorselIq.acikSeviye;
      sekerSeviye = veri.sekerSiralama.acikSeviye;
      sayiPetegiSeviye = veri.sayiPetegi.acikSeviye;
      sekilSeviye = veri.sekilBirlestir.acikSeviye;
      refleksSeviye = veri.refleks.acikSeviye;
      akisSeviye = flowProgress.unlockedLevel;
      devreSeviye = circuitProgress.unlockedLevel;
      dedektifSeviye = detectiveProgress.unlockedLevel;
      kopruSeviye = bridgeProgress.unlockedLevel;
      kapiDizisiSeviye = gateSequenceProgress.unlockedLevel;
      parkYeriSeviye = parkingProgress.unlockedLevel;
      kilitAcSeviye = pinUnlockProgress.unlockedLevel;
      agirlikDengesiSeviye = balanceScaleProgress.unlockedLevel;
      hedef24Seviye = target24Progress.unlockedLevel;
      miniSudokuSeviye = miniSudokuProgress.unlockedLevel;
      kenkenSeviye = kenkenProgress.unlockedLevel;
      mahjongSeviye = mahjongProgress.unlockedLevel;
      mayinSeviye = mineDetectorProgress.unlockedLevel;
      depoUstasiSeviye = warehouseMasterProgress.unlockedLevel;
      kelimeCarkiSeviye = wordWheelProgress.unlockedLevel;
      meaningMatchSeviye = meaningMatchProgress.unlockedLevel;
      proverbFinishSeviye = proverbFinishProgress.unlockedLevel;
      sentenceBuilderSeviye = sentenceBuilderProgress.unlockedLevel;
      nearMeaningSeviye = nearMeaningProgress.unlockedLevel;
      letterMazeSeviye = letterMazeProgress.unlockedLevel;
      languageDetectiveSeviye = languageDetectiveProgress.unlockedLevel;
      storyOrderSeviye = storyOrderProgress.unlockedLevel;
      gizliKutleSeviye = hiddenMassesProgress.unlockedLevel;
      kakuroSeviye = kakuroProgress.unlockedLevel;
      reversiSeviye = reversiProgress.unlockedLevel;
      picrossSeviye = picrossProgress.unlockedLevel;
      tavlaSeviye = tavlaProgress.unlockedLevel;
      arrowRouteSeviye = arrowRouteProgress.unlockedLevel;
      satrancMatiSeviye = chessMateProgress.unlockedLevel;
      donguUstasiSeviye = loopMasterProgress.unlockedLevel;
      goYasamOlumSeviye = goLifeDeathProgress.unlockedLevel;
      kodKiriciSeviye = codeBreakerProgress.unlockedLevel;
      shogiMatSeviye = shogiMateProgress.unlockedLevel;
      adaDenizSeviye = islandSeaProgress.unlockedLevel;
      tekTasSeviye = pegSolitaireProgress.unlockedLevel;
      futoshikiSeviye = futoshikiProgress.unlockedLevel;
      hexConnectionSeviye = hexConnectionProgress.unlockedLevel;
      skyscrapersSeviye = skyscrapersProgress.unlockedLevel;
      hitoriSeviye = hitoriProgress.unlockedLevel;
      balloonSeviye = balloonProgress.unlockedLevel;
      bottleTargetSeviye = bottleTargetProgress.unlockedLevel;
      colorReactorSeviye = colorReactorProgress.unlockedLevel;
      ballMergeSeviye = ballMergeProgress.unlockedLevel;
      towerBalanceSeviye = towerBalanceProgress.unlockedLevel;
      magnetPathSeviye = magnetPathProgress.unlockedLevel;
      miniGolfSeviye = miniGolfProgress.unlockedLevel;
      slideSweetsSeviye = slideSweetsProgress.unlockedLevel;
      ringTossSeviye = ringTossProgress.unlockedLevel;
      littleFisherSeviye = littleFisherProgress.unlockedLevel;
      marbleRouteSeviye = marbleRouteProgress.unlockedLevel;
      blockFlowSeviye = blockFlowProgress.unlockedLevel;
      paperFlightSeviye = paperFlightProgress.unlockedLevel;
      neonPinballSeviye = neonPinballProgress.unlockedLevel;
      kiteRunnerSeviye = kiteRunnerProgress.unlockedLevel;
      rhythmDrumsSeviye = rhythmDrumsProgress.unlockedLevel;
      skateComboSeviye = skateComboProgress.unlockedLevel;
      snowboardSlalomSeviye = snowboardSlalomProgress.unlockedLevel;
      jetpackCourierSeviye = jetpackCourierProgress.unlockedLevel;
      orbitRescueSeviye = orbitRescueProgress.unlockedLevel;
      driftLeagueSeviye = driftLeagueProgress.unlockedLevel;
      tableTennisRallySeviye = tableTennisRallyProgress.unlockedLevel;
      penaltyMindgameSeviye = penaltyMindgameProgress.unlockedLevel;
      airHockeyArenaSeviye = airHockeyArenaProgress.unlockedLevel;
      relicRunSeviye = relicRunProgress.unlockedLevel;
      lighthouseDefenseSeviye = lighthouseDefenseProgress.unlockedLevel;
      museumAfterHoursSeviye = museumAfterHoursProgress.unlockedLevel;
      deepCurrentSeviye = deepCurrentProgress.unlockedLevel;
      cafeShiftSeviye = cafeShiftProgress.unlockedLevel;
      interiorStudioSeviye = interiorStudioProgress.unlockedLevel;
      tideglassAquariumSeviye = tideglassAquariumProgress.unlockedLevel;
      petRescueClinicSeviye = petRescueClinicProgress.unlockedLevel;
      boardwalkBuilderSeviye = boardwalkBuilderProgress.unlockedLevel;
      moonbaseOpsSeviye = moonbaseOpsProgress.unlockedLevel;
      museumCuratorSeviye = museumCuratorProgress.unlockedLevel;
      festivalProducerSeviye = festivalProducerProgress.unlockedLevel;
      secretRoomPartySeviye = secretRoomPartyProgress.unlockedLevel;
      diceBluffArenaSeviye = diceBluffArenaProgress.unlockedLevel;
      signalPairSeviye = signalPairProgress.unlockedLevel;
      deckforgeDuelSeviye = deckforgeDuelProgress.unlockedLevel;

      mantikPuani = ZekaScoringService.courseScore(veri.mantik);
      sayiPuani = ZekaScoringService.courseScore(veri.sayi);
      blokPuani = ZekaScoringService.courseScore(veri.blok);
      hafizaPuani = ZekaScoringService.courseScore(veri.hafiza);
      hanoiPuani = ZekaScoringService.courseScore(veri.hanoi);
      kelimePuani = ZekaScoringService.courseScore(veri.kelimeAvi);
      gorselIqPuani = ZekaScoringService.courseScore(veri.gorselIq);
      sekerPuani = ZekaScoringService.courseScore(veri.sekerSiralama);
      sayiPetegiPuani = ZekaScoringService.courseScore(veri.sayiPetegi);
      sekilPuani = ZekaScoringService.courseScore(veri.sekilBirlestir);
      refleksPuani = ZekaScoringService.courseScore(veri.refleks);
      akisPuani = flowProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      devrePuani = circuitProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      dedektifPuani = detectiveProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      kopruPuani = bridgeProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      kapiDizisiPuani = gateSequenceProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      parkYeriPuani = parkingProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      kilitAcPuani = pinUnlockProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      agirlikDengesiPuani = balanceScaleProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      hedef24Puani = target24Progress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      miniSudokuPuani = miniSudokuProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      kenkenPuani = kenkenProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      mahjongPuani = mahjongProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      mayinPuani = mineDetectorProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      depoUstasiPuani = warehouseMasterProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      kelimeCarkiPuani = wordWheelProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      meaningMatchPuani = meaningMatchProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      proverbFinishPuani = proverbFinishProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      sentenceBuilderPuani = sentenceBuilderProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      nearMeaningPuani = nearMeaningProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      letterMazePuani = letterMazeProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      languageDetectivePuani = languageDetectiveProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      storyOrderPuani = storyOrderProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      cardPairsPuani = cardPairsProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      focusFilterPuani = focusFilterProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      spotChangePuani = spotChangeProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      rhythmMemoryPuani = rhythmMemoryProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      attentionTunnelPuani = attentionTunnelProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      gizliKutlePuani = hiddenMassesProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      kakuroPuani = kakuroProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      reversiPuani = reversiProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      picrossPuani = picrossProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      tavlaPuani = tavlaProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      arrowRoutePuani = arrowRouteProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      satrancMatiPuani = chessMateProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      donguUstasiPuani = loopMasterProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      goYasamOlumPuani = goLifeDeathProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      kodKiriciPuani = codeBreakerProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      shogiMatPuani = shogiMateProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      adaDenizPuani = islandSeaProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      tekTasPuani = pegSolitaireProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      futoshikiPuani = futoshikiProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      hexConnectionPuani = hexConnectionProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      skyscrapersPuani = skyscrapersProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      hitoriPuani = hitoriProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      balloonPuani = balloonProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      bottleTargetPuani = bottleTargetProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      colorReactorPuani = colorReactorProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      ballMergePuani = ballMergeProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      towerBalancePuani = towerBalanceProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      magnetPathPuani = magnetPathProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      miniGolfPuani = miniGolfProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      slideSweetsPuani = slideSweetsProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      ringTossPuani = ringTossProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      littleFisherPuani = littleFisherProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      marbleRoutePuani = marbleRouteProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      blockFlowPuani = blockFlowProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      paperFlightPuani = paperFlightProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      neonPinballPuani = neonPinballProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      kiteRunnerPuani = kiteRunnerProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      rhythmDrumsPuani = rhythmDrumsProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      skateComboPuani = skateComboProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      snowboardSlalomPuani = snowboardSlalomProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      jetpackCourierPuani = jetpackCourierProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      orbitRescuePuani = orbitRescueProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );

      mantikYildiz = veri.mantik.toplamYildiz;
      sayiYildiz = veri.sayi.toplamYildiz;
      blokYildiz = veri.blok.toplamYildiz;
      hafizaYildiz = veri.hafiza.toplamYildiz;
      hanoiYildiz = veri.hanoi.toplamYildiz;
      kelimeYildiz = veri.kelimeAvi.toplamYildiz;
      gorselIqYildiz = veri.gorselIq.toplamYildiz;
      sekerYildiz = veri.sekerSiralama.toplamYildiz;
      sayiPetegiYildiz = veri.sayiPetegi.toplamYildiz;
      sekilYildiz = veri.sekilBirlestir.toplamYildiz;
      refleksYildiz = veri.refleks.toplamYildiz;
      akisYildiz = flowProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      devreYildiz = circuitProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      dedektifYildiz = detectiveProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      kopruYildiz = bridgeProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      kapiDizisiYildiz = gateSequenceProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      parkYeriYildiz = parkingProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      kilitAcYildiz = pinUnlockProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      agirlikDengesiYildiz = balanceScaleProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      hedef24Yildiz = target24Progress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      miniSudokuYildiz = miniSudokuProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      kenkenYildiz = kenkenProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      mahjongYildiz = mahjongProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      mayinYildiz = mineDetectorProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      depoUstasiYildiz = warehouseMasterProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      kelimeCarkiYildiz = wordWheelProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      meaningMatchYildiz = meaningMatchProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      proverbFinishYildiz = proverbFinishProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      sentenceBuilderYildiz = sentenceBuilderProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      nearMeaningYildiz = nearMeaningProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      letterMazeYildiz = letterMazeProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      languageDetectiveYildiz = languageDetectiveProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      storyOrderYildiz = storyOrderProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      cardPairsYildiz = cardPairsProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      focusFilterYildiz = focusFilterProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      spotChangeYildiz = spotChangeProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      rhythmMemoryYildiz = rhythmMemoryProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      attentionTunnelYildiz = attentionTunnelProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      gizliKutleYildiz = hiddenMassesProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      kakuroYildiz = kakuroProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      reversiYildiz = reversiProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      picrossYildiz = picrossProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      tavlaYildiz = tavlaProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      arrowRouteYildiz = arrowRouteProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      satrancMatiYildiz = chessMateProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      donguUstasiYildiz = loopMasterProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      goYasamOlumYildiz = goLifeDeathProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      kodKiriciYildiz = codeBreakerProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      shogiMatYildiz = shogiMateProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      adaDenizYildiz = islandSeaProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      tekTasYildiz = pegSolitaireProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      futoshikiYildiz = futoshikiProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      hexConnectionYildiz = hexConnectionProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      skyscrapersYildiz = skyscrapersProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      hitoriYildiz = hitoriProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      balloonYildiz = balloonProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      bottleTargetYildiz = bottleTargetProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      colorReactorYildiz = colorReactorProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      ballMergeYildiz = ballMergeProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      towerBalanceYildiz = towerBalanceProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      magnetPathYildiz = magnetPathProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      miniGolfYildiz = miniGolfProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      slideSweetsYildiz = slideSweetsProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      ringTossYildiz = ringTossProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      littleFisherYildiz = littleFisherProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      marbleRouteYildiz = marbleRouteProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      blockFlowYildiz = blockFlowProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      paperFlightYildiz = paperFlightProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      neonPinballYildiz = neonPinballProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      kiteRunnerYildiz = kiteRunnerProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      rhythmDrumsYildiz = rhythmDrumsProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      skateComboYildiz = skateComboProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      snowboardSlalomYildiz = snowboardSlalomProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      jetpackCourierYildiz = jetpackCourierProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      orbitRescueYildiz = orbitRescueProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      driftLeagueYildiz = driftLeagueProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      driftLeaguePuani = driftLeagueProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      tableTennisRallyYildiz = tableTennisRallyProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      tableTennisRallyPuani = tableTennisRallyProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      penaltyMindgameYildiz = penaltyMindgameProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      penaltyMindgamePuani = penaltyMindgameProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      airHockeyArenaYildiz = airHockeyArenaProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      airHockeyArenaPuani = airHockeyArenaProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      relicRunYildiz = relicRunProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      relicRunPuani = relicRunProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      lighthouseDefenseYildiz = lighthouseDefenseProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      lighthouseDefensePuani = lighthouseDefenseProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      museumAfterHoursYildiz = museumAfterHoursProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      museumAfterHoursPuani = museumAfterHoursProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      deepCurrentYildiz = deepCurrentProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      deepCurrentPuani = deepCurrentProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      cafeShiftYildiz = cafeShiftProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      cafeShiftPuani = cafeShiftProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      interiorStudioYildiz = interiorStudioProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      interiorStudioPuani = interiorStudioProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      tideglassAquariumYildiz = tideglassAquariumProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      tideglassAquariumPuani = tideglassAquariumProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      petRescueClinicYildiz = petRescueClinicProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      petRescueClinicPuani = petRescueClinicProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      boardwalkBuilderYildiz = boardwalkBuilderProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      boardwalkBuilderPuani = boardwalkBuilderProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      moonbaseOpsYildiz = moonbaseOpsProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      moonbaseOpsPuani = moonbaseOpsProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      museumCuratorYildiz = museumCuratorProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      museumCuratorPuani = museumCuratorProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      festivalProducerYildiz = festivalProducerProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      festivalProducerPuani = festivalProducerProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      secretRoomPartyYildiz = secretRoomPartyProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      secretRoomPartyPuani = secretRoomPartyProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      diceBluffArenaYildiz = diceBluffArenaProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      diceBluffArenaPuani = diceBluffArenaProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      signalPairYildiz = signalPairProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      signalPairPuani = signalPairProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );
      deckforgeDuelYildiz = deckforgeDuelProgress.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      );
      deckforgeDuelPuani = deckforgeDuelProgress.bestScores.fold<int>(
        0,
        (int total, int score) => total + score,
      );

      gunlukVeri = daily;
      oyuncuVeri = player;
      tercihVeri = preferences;
      yukleniyor = false;
    });

    unawaited(_online.syncCurrentPlayer(player));

    unawaited(
      _analytics.setPlayerProperties(
        level: player.level,
        league: player.league.shortName,
        language: AppLanguageController.instance.resolvedLocale.languageCode,
      ),
    );
  }

  String get rutbe {
    return oyuncuVeri?.rankTitle ?? 'ZEKA ÇIRAĞI';
  }

  _HomeRecommendationPresentation _homeRecommendation(BuildContext context) {
    final HomeGameRecommendation recommendation = _personalization.recommend(
      preferences: tercihVeri,
      unlockedLevels: <String, int>{
        'logic': mantikSeviye,
        'numbers': sayiSeviye,
        'blocks': blokSeviye,
        'memory': hafizaSeviye,
        'card_pairs': cardPairsSeviye,
        'focus_filter': focusFilterSeviye,
        'spot_change': spotChangeSeviye,
        'rhythm_memory': rhythmMemorySeviye,
        'attention_tunnel': attentionTunnelSeviye,
        'hanoi': hanoiSeviye,
        'word_hunt': kelimeSeviye,
        'picture_iq': gorselIqSeviye,
        'candy_sort': sekerSeviye,
        'number_sort': sayiPetegiSeviye,
        'shape_puzzle': sekilSeviye,
        'reflex': refleksSeviye,
        'pin_unlock': kilitAcSeviye,
        'balance_scale': agirlikDengesiSeviye,
        'target_24': hedef24Seviye,
        'mini_sudoku': miniSudokuSeviye,
        'kenken_cube': kenkenSeviye,
        'mahjong_layers': mahjongSeviye,
        'mine_detective': mayinSeviye,
        'warehouse_master': depoUstasiSeviye,
        'word_wheel': kelimeCarkiSeviye,
        'meaning_match': meaningMatchSeviye,
        'proverb_finish': proverbFinishSeviye,
        'sentence_builder': sentenceBuilderSeviye,
        'near_meaning': nearMeaningSeviye,
        'letter_maze': letterMazeSeviye,
        'language_detective': languageDetectiveSeviye,
        'story_order': storyOrderSeviye,
        'hidden_masses': gizliKutleSeviye,
        'kakuro': kakuroSeviye,
        'reversi_arena': reversiSeviye,
        'picross_master': picrossSeviye,
        'tavla_master': tavlaSeviye,
        'arrow_route': arrowRouteSeviye,
        'mini_chess_tactics': satrancMatiSeviye,
        'loop_master': donguUstasiSeviye,
        'go_life_death': goYasamOlumSeviye,
        'code_breaker': kodKiriciSeviye,
        'shogi_mate': shogiMatSeviye,
        'island_sea': adaDenizSeviye,
        'peg_solitaire': tekTasSeviye,
        'futoshiki': futoshikiSeviye,
        'hex_connection': hexConnectionSeviye,
        'skyscrapers': skyscrapersSeviye,
        'hitori': hitoriSeviye,
        'balloon_pop': balloonSeviye,
        'bottle_target': bottleTargetSeviye,
        'color_match': colorReactorSeviye,
        'ball_merge': ballMergeSeviye,
        'tower_balance': towerBalanceSeviye,
        'magnet_path': magnetPathSeviye,
        'mini_golf_route': miniGolfSeviye,
        'slide_sweets': slideSweetsSeviye,
        'ring_toss': ringTossSeviye,
        'little_fisher': littleFisherSeviye,
        'marble_route': marbleRouteSeviye,
        'block_flow': blockFlowSeviye,
        'paper_flight': paperFlightSeviye,
        'neon_pinball': neonPinballSeviye,
        'kite_runner': kiteRunnerSeviye,
        'rhythm_drums': rhythmDrumsSeviye,
        'skate_combo': skateComboSeviye,
        'snowboard_slalom': snowboardSlalomSeviye,
        'jetpack_courier': jetpackCourierSeviye,
        'orbit_rescue': orbitRescueSeviye,
        'drift_league': driftLeagueSeviye,
        'table_tennis_rally': tableTennisRallySeviye,
        'penalty_mindgame': penaltyMindgameSeviye,
        'air_hockey_arena': airHockeyArenaSeviye,
        'relic_run': relicRunSeviye,
        'lighthouse_defense': lighthouseDefenseSeviye,
        'museum_after_hours': museumAfterHoursSeviye,
        'deep_current': deepCurrentSeviye,
        'cafe_shift': cafeShiftSeviye,
        'interior_studio': interiorStudioSeviye,
        'tideglass_aquarium': tideglassAquariumSeviye,
        'pet_rescue_clinic': petRescueClinicSeviye,
        'boardwalk_builder': boardwalkBuilderSeviye,
        'moonbase_ops': moonbaseOpsSeviye,
        'museum_curator': museumCuratorSeviye,
        'festival_producer': festivalProducerSeviye,
        'secret_room_party': secretRoomPartySeviye,
        'dice_bluff_arena': diceBluffArenaSeviye,
        'signal_pair': signalPairSeviye,
        'deckforge_duel': deckforgeDuelSeviye,
        'city_atlas': _referenceGameProgress['city_atlas']?.unlockedLevel ?? 1,
        'world_atlas':
            _referenceGameProgress['world_atlas']?.unlockedLevel ?? 1,
        'katamino_workshop':
            _referenceGameProgress['katamino_workshop']?.unlockedLevel ?? 1,
        'single_stroke':
            _referenceGameProgress['single_stroke']?.unlockedLevel ?? 1,
        'arrow_maze': _referenceGameProgress['arrow_maze']?.unlockedLevel ?? 1,
        'bubble_shooter':
            _referenceGameProgress['bubble_shooter']?.unlockedLevel ?? 1,
      },
      earnedStars: <String, int>{
        'logic': mantikYildiz,
        'numbers': sayiYildiz,
        'blocks': blokYildiz,
        'memory': hafizaYildiz,
        'card_pairs': cardPairsYildiz,
        'focus_filter': focusFilterYildiz,
        'spot_change': spotChangeYildiz,
        'rhythm_memory': rhythmMemoryYildiz,
        'attention_tunnel': attentionTunnelYildiz,
        'hanoi': hanoiYildiz,
        'word_hunt': kelimeYildiz,
        'picture_iq': gorselIqYildiz,
        'candy_sort': sekerYildiz,
        'number_sort': sayiPetegiYildiz,
        'shape_puzzle': sekilYildiz,
        'reflex': refleksYildiz,
        'parking_puzzle': parkYeriYildiz,
        'pin_unlock': kilitAcYildiz,
        'balance_scale': agirlikDengesiYildiz,
        'target_24': hedef24Yildiz,
        'mini_sudoku': miniSudokuYildiz,
        'kenken_cube': kenkenYildiz,
        'mahjong_layers': mahjongYildiz,
        'mine_detective': mayinYildiz,
        'warehouse_master': depoUstasiYildiz,
        'word_wheel': kelimeCarkiYildiz,
        'meaning_match': meaningMatchYildiz,
        'proverb_finish': proverbFinishYildiz,
        'sentence_builder': sentenceBuilderYildiz,
        'near_meaning': nearMeaningYildiz,
        'letter_maze': letterMazeYildiz,
        'language_detective': languageDetectiveYildiz,
        'story_order': storyOrderYildiz,
        'hidden_masses': gizliKutleYildiz,
        'kakuro': kakuroYildiz,
        'reversi_arena': reversiYildiz,
        'picross_master': picrossYildiz,
        'tavla_master': tavlaYildiz,
        'arrow_route': arrowRouteYildiz,
        'mini_chess_tactics': satrancMatiYildiz,
        'loop_master': donguUstasiYildiz,
        'go_life_death': goYasamOlumYildiz,
        'code_breaker': kodKiriciYildiz,
        'shogi_mate': shogiMatYildiz,
        'island_sea': adaDenizYildiz,
        'peg_solitaire': tekTasYildiz,
        'futoshiki': futoshikiYildiz,
        'hex_connection': hexConnectionYildiz,
        'skyscrapers': skyscrapersYildiz,
        'hitori': hitoriYildiz,
        'balloon_pop': balloonYildiz,
        'bottle_target': bottleTargetYildiz,
        'color_match': colorReactorYildiz,
        'ball_merge': ballMergeYildiz,
        'tower_balance': towerBalanceYildiz,
        'magnet_path': magnetPathYildiz,
        'mini_golf_route': miniGolfYildiz,
        'slide_sweets': slideSweetsYildiz,
        'ring_toss': ringTossYildiz,
        'little_fisher': littleFisherYildiz,
        'marble_route': marbleRouteYildiz,
        'block_flow': blockFlowYildiz,
        'paper_flight': paperFlightYildiz,
        'neon_pinball': neonPinballYildiz,
        'kite_runner': kiteRunnerYildiz,
        'rhythm_drums': rhythmDrumsYildiz,
        'skate_combo': skateComboYildiz,
        'snowboard_slalom': snowboardSlalomYildiz,
        'jetpack_courier': jetpackCourierYildiz,
        'orbit_rescue': orbitRescueYildiz,
        'drift_league': driftLeagueYildiz,
        'table_tennis_rally': tableTennisRallyYildiz,
        'penalty_mindgame': penaltyMindgameYildiz,
        'air_hockey_arena': airHockeyArenaYildiz,
        'relic_run': relicRunYildiz,
        'lighthouse_defense': lighthouseDefenseYildiz,
        'museum_after_hours': museumAfterHoursYildiz,
        'deep_current': deepCurrentYildiz,
        'cafe_shift': cafeShiftYildiz,
        'interior_studio': interiorStudioYildiz,
        'tideglass_aquarium': tideglassAquariumYildiz,
        'pet_rescue_clinic': petRescueClinicYildiz,
        'boardwalk_builder': boardwalkBuilderYildiz,
        'moonbase_ops': moonbaseOpsYildiz,
        'museum_curator': museumCuratorYildiz,
        'festival_producer': festivalProducerYildiz,
        'secret_room_party': secretRoomPartyYildiz,
        'dice_bluff_arena': diceBluffArenaYildiz,
        'signal_pair': signalPairYildiz,
        'deckforge_duel': deckforgeDuelYildiz,
        'city_atlas': _referenceGameStars('city_atlas'),
        'world_atlas': _referenceGameStars('world_atlas'),
        'katamino_workshop': _referenceGameStars('katamino_workshop'),
        'single_stroke': _referenceGameStars('single_stroke'),
        'arrow_maze': _referenceGameStars('arrow_maze'),
        'bubble_shooter': _referenceGameStars('bubble_shooter'),
      },
    );

    final ({int number, IconData icon, Color color}) identity =
        switch (recommendation.gameId) {
          'numbers' => (
            number: 2,
            icon: Icons.calculate_rounded,
            color: const Color(0xFF39B54A),
          ),
          'blocks' => (
            number: 3,
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF168CFF),
          ),
          'memory' => (
            number: 4,
            icon: Icons.psychology_rounded,
            color: const Color(0xFFE748CF),
          ),
          'hanoi' => (
            number: 5,
            icon: Icons.account_tree_rounded,
            color: const Color(0xFFFF5A3C),
          ),
          'word_hunt' => (
            number: 6,
            icon: Icons.travel_explore_rounded,
            color: const Color(0xFF00D9A6),
          ),
          'word_wheel' => (
            number: 26,
            icon: Icons.casino_outlined,
            color: StudioGameClass.language.accent,
          ),
          'meaning_match' => (
            number: 64,
            icon: Icons.hub_rounded,
            color: StudioGameClass.language.accent,
          ),
          'proverb_finish' => (
            number: 65,
            icon: Icons.menu_book_rounded,
            color: StudioGameClass.language.accent,
          ),
          'sentence_builder' => (
            number: 66,
            icon: Icons.format_align_left_rounded,
            color: StudioGameClass.language.accent,
          ),
          'near_meaning' => (
            number: 67,
            icon: Icons.manage_search_rounded,
            color: StudioGameClass.language.accent,
          ),
          'letter_maze' => (
            number: 68,
            icon: Icons.route_rounded,
            color: StudioGameClass.language.accent,
          ),
          'language_detective' => (
            number: 69,
            icon: Icons.manage_search_rounded,
            color: StudioGameClass.language.accent,
          ),
          'story_order' => (
            number: 70,
            icon: Icons.timeline_rounded,
            color: StudioGameClass.language.accent,
          ),
          'picture_iq' => (
            number: 7,
            icon: Icons.auto_awesome_mosaic_rounded,
            color: const Color(0xFFFF4FA3),
          ),
          'candy_sort' => (
            number: 8,
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF318C82),
          ),
          'number_sort' => (
            number: 9,
            icon: Icons.grid_4x4_rounded,
            color: const Color(0xFFB98548),
          ),
          'shape_puzzle' => (
            number: 10,
            icon: Icons.interests_rounded,
            color: const Color(0xFF8C6CFF),
          ),
          'reflex' => (
            number: 11,
            icon: Icons.bolt_rounded,
            color: const Color(0xFFFF5B5B),
          ),
          'parking_puzzle' => (
            number: 17,
            icon: Icons.directions_car_filled_rounded,
            color: StudioGameClass.strategy.accent,
          ),
          'pin_unlock' => (
            number: 18,
            icon: Icons.lock_open_rounded,
            color: StudioGameClass.logic.accent,
          ),
          'balance_scale' => (
            number: 19,
            icon: Icons.balance_rounded,
            color: StudioGameClass.logic.accent,
          ),
          'hidden_masses' => (
            number: 27,
            icon: Icons.scale_outlined,
            color: StudioGameClass.logic.accent,
          ),
          'kakuro' => (
            number: 28,
            icon: Icons.grid_on_rounded,
            color: StudioGameClass.numbers.accent,
          ),
          'reversi_arena' => (
            number: 29,
            icon: Icons.change_circle_outlined,
            color: StudioGameClass.strategy.accent,
          ),
          'picross_master' => (
            number: 30,
            icon: Icons.grid_4x4_rounded,
            color: StudioGameClass.visual.accent,
          ),
          'tavla_master' => (
            number: 31,
            icon: Icons.casino_outlined,
            color: StudioGameClass.strategy.accent,
          ),
          'arrow_route' => (
            number: 32,
            icon: Icons.near_me_outlined,
            color: StudioGameClass.visual.accent,
          ),
          'mini_chess_tactics' => (
            number: 33,
            icon: Icons.grid_4x4_rounded,
            color: StudioGameClass.strategy.accent,
          ),
          'loop_master' => (
            number: 34,
            icon: Icons.loop_rounded,
            color: StudioGameClass.logic.accent,
          ),
          'go_life_death' => (
            number: 35,
            icon: Icons.circle_outlined,
            color: StudioGameClass.strategy.accent,
          ),
          'code_breaker' => (
            number: 36,
            icon: Icons.password_rounded,
            color: StudioGameClass.logic.accent,
          ),
          'shogi_mate' => (
            number: 37,
            icon: Icons.grid_on_rounded,
            color: StudioGameClass.strategy.accent,
          ),
          'island_sea' => (
            number: 38,
            icon: Icons.waves_rounded,
            color: StudioGameClass.logic.accent,
          ),
          'peg_solitaire' => (
            number: 39,
            icon: Icons.circle_outlined,
            color: StudioGameClass.strategy.accent,
          ),
          'futoshiki' => (
            number: 40,
            icon: Icons.grid_4x4_rounded,
            color: StudioGameClass.numbers.accent,
          ),
          'hex_connection' => (
            number: 41,
            icon: Icons.hexagon_outlined,
            color: StudioGameClass.strategy.accent,
          ),
          'skyscrapers' => (
            number: 42,
            icon: Icons.location_city_outlined,
            color: StudioGameClass.logic.accent,
          ),
          'hitori' => (
            number: 43,
            icon: Icons.grid_view_rounded,
            color: StudioGameClass.logic.accent,
          ),
          'balloon_pop' => (
            number: 44,
            icon: Icons.air_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'bottle_target' => (
            number: 45,
            icon: Icons.sports_baseball_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'color_match' => (
            number: 46,
            icon: Icons.bubble_chart_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'ball_merge' => (
            number: 47,
            icon: Icons.blur_circular_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'tower_balance' => (
            number: 48,
            icon: Icons.balance_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'magnet_path' => (
            number: 49,
            icon: Icons.flare_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'mini_golf_route' => (
            number: 50,
            icon: Icons.sports_golf_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'slide_sweets' => (
            number: 51,
            icon: Icons.factory_rounded,
            color: StudioGameClass.speed.accent,
          ),
          'ring_toss' => (
            number: 52,
            icon: Icons.sports_handball_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'little_fisher' => (
            number: 53,
            icon: Icons.phishing_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'marble_route' => (
            number: 54,
            icon: Icons.sports_handball_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'block_flow' => (
            number: 55,
            icon: Icons.view_in_ar_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'paper_flight' => (
            number: 56,
            icon: Icons.airplanemode_active_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'neon_pinball' => (
            number: 57,
            icon: Icons.sports_esports_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'kite_runner' => (
            number: 58,
            icon: Icons.air_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'rhythm_drums' => (
            number: 59,
            icon: Icons.graphic_eq_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'skate_combo' => (
            number: 60,
            icon: Icons.skateboarding_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'snowboard_slalom' => (
            number: 61,
            icon: Icons.downhill_skiing_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'jetpack_courier' => (
            number: 62,
            icon: Icons.rocket_launch_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'orbit_rescue' => (
            number: 63,
            icon: Icons.public_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'drift_league' => (
            number: 80,
            icon: Icons.sports_motorsports_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'table_tennis_rally' => (
            number: 81,
            icon: Icons.sports_tennis_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'penalty_mindgame' => (
            number: 82,
            icon: Icons.sports_soccer_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'air_hockey_arena' => (
            number: 83,
            icon: Icons.sports_hockey_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'relic_run' => (
            number: 84,
            icon: Icons.explore_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'lighthouse_defense' => (
            number: 85,
            icon: Icons.light_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'museum_after_hours' => (
            number: 86,
            icon: Icons.museum_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'deep_current' => (
            number: 87,
            icon: Icons.sailing_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'cafe_shift' => (
            number: 88,
            icon: Icons.local_cafe_rounded,
            color: StudioGameClass.fun.accent,
          ),
          'target_24' => (
            number: 20,
            icon: Icons.functions_rounded,
            color: StudioGameClass.numbers.accent,
          ),
          'mini_sudoku' => (
            number: 21,
            icon: Icons.grid_on_rounded,
            color: StudioGameClass.numbers.accent,
          ),
          'kenken_cube' => (
            number: 22,
            icon: Icons.functions_rounded,
            color: StudioGameClass.numbers.accent,
          ),
          'mahjong_layers' => (
            number: 23,
            icon: Icons.layers_rounded,
            color: StudioGameClass.visual.accent,
          ),
          'mine_detective' => (
            number: 24,
            icon: Icons.radar_rounded,
            color: StudioGameClass.logic.accent,
          ),
          'warehouse_master' => (
            number: 25,
            icon: Icons.inventory_2_outlined,
            color: StudioGameClass.strategy.accent,
          ),
          'city_atlas' => (
            number: 123,
            icon: Icons.map_outlined,
            color: StudioGameClass.visual.accent,
          ),
          'world_atlas' => (
            number: 124,
            icon: Icons.public_rounded,
            color: StudioGameClass.visual.accent,
          ),
          'katamino_workshop' => (
            number: 125,
            icon: Icons.extension_rounded,
            color: StudioGameClass.visual.accent,
          ),
          'single_stroke' => (
            number: 126,
            icon: Icons.gesture_rounded,
            color: StudioGameClass.logic.accent,
          ),
          'arrow_maze' => (
            number: 127,
            icon: Icons.alt_route_rounded,
            color: StudioGameClass.logic.accent,
          ),
          'bubble_shooter' => (
            number: 128,
            icon: Icons.bubble_chart_rounded,
            color: StudioGameClass.fun.accent,
          ),
          _ => (
            number: 1,
            icon: Icons.extension_rounded,
            color: const Color(0xFF8A4FFF),
          ),
        };

    return _HomeRecommendationPresentation(
      gameId: recommendation.gameId,
      number: identity.number,
      icon: identity.icon,
      color: identity.color,
      reason: recommendation.reason(isEnglish: context.l10n.isEnglish),
    );
  }

  Future<void> ayarlariAc() async {
    unawaited(_analytics.logScreen('settings'));

    unawaited(_audio.play(GameSound.uiClick));

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  Future<void> gunlukGorevleriAc() async {
    unawaited(_analytics.logScreen('daily_challenges'));

    unawaited(_audio.play(GameSound.uiClick));

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DailyTasksPage()),
    );

    await anaSayfayiYenile();
  }

  Future<void> liderligiAc() async {
    unawaited(_analytics.logScreen('leaderboard'));

    unawaited(_audio.play(GameSound.uiClick));

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaderboardPage()),
    );

    await anaSayfayiYenile();
  }

  Future<void> arenayiAc() async {
    unawaited(_analytics.logScreen('arena'));
    unawaited(_audio.play(GameSound.uiClick));
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const ArenaPage()),
    );
    await anaSayfayiYenile();
  }

  Future<void> profiliAc() async {
    unawaited(_analytics.logScreen('profile'));

    unawaited(_audio.play(GameSound.uiClick));

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );

    await anaSayfayiYenile();
  }

  void altMenuSec(int index) {
    if (index == 0) {
      return;
    }

    if (index == 1) {
      gunlukGorevleriAc();
      return;
    }

    if (index == 2) {
      liderligiAc();
      return;
    }

    if (index == 3) {
      profiliAc();
    }
  }

  Future<void> oyunuAc(int oyun) async {
    if (_gameOpening || !mounted) return;

    final _GameLaunchTarget? target = switch (oyun) {
      1 => _GameLaunchTarget(
        gameId: 'logic',
        icon: Icons.extension_rounded,
        accentColor: const Color(0xFF8A4FFF),
        builder: () => const LogicGamePage(),
      ),
      2 => _GameLaunchTarget(
        gameId: 'numbers',
        icon: Icons.calculate_rounded,
        accentColor: const Color(0xFF39B54A),
        builder: () => const NumberGamePage(),
      ),
      3 => _GameLaunchTarget(
        gameId: 'blocks',
        icon: Icons.grid_view_rounded,
        accentColor: const Color(0xFF168CFF),
        builder: () => const BlockGamePage(),
      ),
      4 => _GameLaunchTarget(
        gameId: 'memory',
        icon: Icons.psychology_rounded,
        accentColor: const Color(0xFFE748CF),
        builder: () => const MemoryGamePage(),
      ),
      72 => _GameLaunchTarget(
        gameId: 'card_pairs',
        icon: Icons.style_rounded,
        accentColor: StudioGameClass.memory.accent,
        builder: () => const CardPairsGamePage(),
      ),
      73 => _GameLaunchTarget(
        gameId: 'focus_filter',
        icon: Icons.filter_center_focus_rounded,
        accentColor: StudioGameClass.speed.accent,
        builder: () => const FocusFilterGamePage(),
      ),
      74 => _GameLaunchTarget(
        gameId: 'spot_change',
        icon: Icons.compare_rounded,
        accentColor: StudioGameClass.memory.accent,
        builder: () => const SpotChangeGamePage(),
      ),
      75 => _GameLaunchTarget(
        gameId: 'rhythm_memory',
        icon: Icons.graphic_eq_rounded,
        accentColor: StudioGameClass.memory.accent,
        builder: () => const RhythmMemoryGamePage(),
      ),
      78 => _GameLaunchTarget(
        gameId: 'attention_tunnel',
        icon: Icons.blur_on_rounded,
        accentColor: StudioGameClass.memory.accent,
        builder: () => const AttentionTunnelGamePage(),
      ),
      5 => _GameLaunchTarget(
        gameId: 'hanoi',
        icon: Icons.account_tree_rounded,
        accentColor: const Color(0xFFFF5A3C),
        builder: () => const HanoiGamePage(),
      ),
      6 => _GameLaunchTarget(
        gameId: 'word_hunt',
        icon: Icons.travel_explore_rounded,
        accentColor: const Color(0xFF00D9A6),
        builder: () => const WordHuntGamePage(),
      ),
      7 => _GameLaunchTarget(
        gameId: 'picture_iq',
        icon: Icons.auto_awesome_mosaic_rounded,
        accentColor: const Color(0xFFFF4FA3),
        builder: () => const PictureIqGamePage(),
      ),
      8 => _GameLaunchTarget(
        gameId: 'candy_sort',
        icon: Icons.water_drop_rounded,
        accentColor: const Color(0xFF318C82),
        builder: () => const CandySortGamePage(),
      ),
      9 => _GameLaunchTarget(
        gameId: 'number_sort',
        icon: Icons.grid_4x4_rounded,
        accentColor: const Color(0xFFB98548),
        builder: () => const NumberSortGamePage(),
      ),
      10 => _GameLaunchTarget(
        gameId: 'shape_puzzle',
        icon: Icons.interests_rounded,
        accentColor: const Color(0xFF8C6CFF),
        builder: () => const ShapePuzzleGamePage(),
      ),
      11 => _GameLaunchTarget(
        gameId: 'reflex',
        icon: Icons.bolt_rounded,
        accentColor: const Color(0xFFFF5B5B),
        builder: () => const ReflexGamePage(),
      ),
      12 => _GameLaunchTarget(
        gameId: 'flow_connect',
        icon: Icons.device_hub_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const FlowConnectGamePage(),
      ),
      13 => _GameLaunchTarget(
        gameId: 'circuit_repair',
        icon: Icons.electric_bolt_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const CircuitRepairGamePage(),
      ),
      14 => _GameLaunchTarget(
        gameId: 'detective_notes',
        icon: Icons.manage_search_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const DetectiveNotesGamePage(),
      ),
      15 => _GameLaunchTarget(
        gameId: 'bridge_builder',
        icon: Icons.account_tree_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const BridgeBuilderGamePage(),
      ),
      16 => _GameLaunchTarget(
        gameId: 'gate_sequence',
        icon: Icons.door_front_door_outlined,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const GateSequenceGamePage(),
      ),
      17 => _GameLaunchTarget(
        gameId: 'parking_puzzle',
        icon: Icons.directions_car_filled_rounded,
        accentColor: StudioGameClass.strategy.accent,
        builder: () => const ParkingPuzzleGamePage(),
      ),
      18 => _GameLaunchTarget(
        gameId: 'pin_unlock',
        icon: Icons.lock_open_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const PinUnlockGamePage(),
      ),
      19 => _GameLaunchTarget(
        gameId: 'balance_scale',
        icon: Icons.balance_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const BalanceScaleGamePage(),
      ),
      20 => _GameLaunchTarget(
        gameId: 'target_24',
        icon: Icons.functions_rounded,
        accentColor: StudioGameClass.numbers.accent,
        builder: () => const Target24GamePage(),
      ),
      21 => _GameLaunchTarget(
        gameId: 'mini_sudoku',
        icon: Icons.grid_on_rounded,
        accentColor: StudioGameClass.numbers.accent,
        builder: () => const MiniSudokuGamePage(),
      ),
      22 => _GameLaunchTarget(
        gameId: 'kenken_cube',
        icon: Icons.functions_rounded,
        accentColor: StudioGameClass.numbers.accent,
        builder: () => const KenKenCubeGamePage(),
      ),
      23 => _GameLaunchTarget(
        gameId: 'mahjong_layers',
        icon: Icons.layers_rounded,
        accentColor: StudioGameClass.visual.accent,
        builder: () => const MahjongLayersGamePage(),
      ),
      24 => _GameLaunchTarget(
        gameId: 'mine_detective',
        icon: Icons.radar_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const MineDetectorGamePage(),
      ),
      25 => _GameLaunchTarget(
        gameId: 'warehouse_master',
        icon: Icons.inventory_2_outlined,
        accentColor: StudioGameClass.strategy.accent,
        builder: () => const WarehouseMasterGamePage(),
      ),
      26 => _GameLaunchTarget(
        gameId: 'word_wheel',
        icon: Icons.casino_outlined,
        accentColor: StudioGameClass.language.accent,
        builder: () => const WordWheelGamePage(),
      ),
      27 => _GameLaunchTarget(
        gameId: 'hidden_masses',
        icon: Icons.scale_outlined,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const HiddenMassesGamePage(),
      ),
      28 => _GameLaunchTarget(
        gameId: 'kakuro',
        icon: Icons.grid_on_rounded,
        accentColor: StudioGameClass.numbers.accent,
        builder: () => const KakuroGamePage(),
      ),
      29 => _GameLaunchTarget(
        gameId: 'reversi_arena',
        icon: Icons.change_circle_outlined,
        accentColor: StudioGameClass.strategy.accent,
        builder: () => const ReversiGamePage(),
      ),
      30 => _GameLaunchTarget(
        gameId: 'picross_master',
        icon: Icons.grid_4x4_rounded,
        accentColor: StudioGameClass.visual.accent,
        builder: () => const PicrossGamePage(),
      ),
      31 => _GameLaunchTarget(
        gameId: 'tavla_master',
        icon: Icons.casino_outlined,
        accentColor: StudioGameClass.strategy.accent,
        builder: () => const TavlaGamePage(),
      ),
      32 => _GameLaunchTarget(
        gameId: 'arrow_route',
        icon: Icons.near_me_outlined,
        accentColor: StudioGameClass.visual.accent,
        builder: () => const ArrowRouteGamePage(),
      ),
      33 => _GameLaunchTarget(
        gameId: 'mini_chess_tactics',
        icon: Icons.grid_4x4_rounded,
        accentColor: StudioGameClass.strategy.accent,
        builder: () => const ChessMateGamePage(),
      ),
      34 => _GameLaunchTarget(
        gameId: 'loop_master',
        icon: Icons.loop_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const LoopMasterGamePage(),
      ),
      35 => _GameLaunchTarget(
        gameId: 'go_life_death',
        icon: Icons.circle_outlined,
        accentColor: StudioGameClass.strategy.accent,
        builder: () => const GoLifeDeathGamePage(),
      ),
      36 => _GameLaunchTarget(
        gameId: 'code_breaker',
        icon: Icons.password_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const CodeBreakerGamePage(),
      ),
      37 => _GameLaunchTarget(
        gameId: 'shogi_mate',
        icon: Icons.grid_on_rounded,
        accentColor: StudioGameClass.strategy.accent,
        builder: () => const ShogiMateGamePage(),
      ),
      38 => _GameLaunchTarget(
        gameId: 'island_sea',
        icon: Icons.waves_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const IslandSeaGamePage(),
      ),
      39 => _GameLaunchTarget(
        gameId: 'peg_solitaire',
        icon: Icons.circle_outlined,
        accentColor: StudioGameClass.strategy.accent,
        builder: () => const PegSolitaireGamePage(),
      ),
      40 => _GameLaunchTarget(
        gameId: 'futoshiki',
        icon: Icons.grid_4x4_rounded,
        accentColor: StudioGameClass.numbers.accent,
        builder: () => const FutoshikiGamePage(),
      ),
      41 => _GameLaunchTarget(
        gameId: 'hex_connection',
        icon: Icons.hexagon_outlined,
        accentColor: StudioGameClass.strategy.accent,
        builder: () => const HexConnectionGamePage(),
      ),
      42 => _GameLaunchTarget(
        gameId: 'skyscrapers',
        icon: Icons.location_city_outlined,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const SkyscrapersGamePage(),
      ),
      43 => _GameLaunchTarget(
        gameId: 'hitori',
        icon: Icons.grid_view_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const HitoriGamePage(),
      ),
      44 => _GameLaunchTarget(
        gameId: 'balloon_pop',
        icon: Icons.air_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const BalloonCatcherGamePage(),
      ),
      45 => _GameLaunchTarget(
        gameId: 'bottle_target',
        icon: Icons.sports_baseball_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const BottleTargetGamePage(),
      ),
      46 => _GameLaunchTarget(
        gameId: 'color_match',
        icon: Icons.bubble_chart_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const ColorReactorGamePage(),
      ),
      47 => _GameLaunchTarget(
        gameId: 'ball_merge',
        icon: Icons.blur_circular_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const BallMergeGamePage(),
      ),
      48 => _GameLaunchTarget(
        gameId: 'tower_balance',
        icon: Icons.balance_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const TowerBalanceGamePage(),
      ),
      49 => _GameLaunchTarget(
        gameId: 'magnet_path',
        icon: Icons.flare_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const MagnetPathGamePage(),
      ),
      50 => _GameLaunchTarget(
        gameId: 'mini_golf_route',
        icon: Icons.sports_golf_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const MiniGolfGamePage(),
      ),
      51 => _GameLaunchTarget(
        gameId: 'slide_sweets',
        icon: Icons.factory_rounded,
        accentColor: StudioGameClass.speed.accent,
        builder: () => const SlideSweetsGamePage(),
      ),
      52 => _GameLaunchTarget(
        gameId: 'ring_toss',
        icon: Icons.sports_handball_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const RingTossGamePage(),
      ),
      53 => _GameLaunchTarget(
        gameId: 'little_fisher',
        icon: Icons.phishing_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const LittleFisherGamePage(),
      ),
      54 => _GameLaunchTarget(
        gameId: 'marble_route',
        icon: Icons.sports_handball_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const MarbleRouteGamePage(),
      ),
      55 => _GameLaunchTarget(
        gameId: 'block_flow',
        icon: Icons.view_in_ar_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const BlockFlowGamePage(),
      ),
      56 => _GameLaunchTarget(
        gameId: 'paper_flight',
        icon: Icons.airplanemode_active_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const PaperFlightGamePage(),
      ),
      57 => _GameLaunchTarget(
        gameId: 'neon_pinball',
        icon: Icons.sports_esports_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const NeonPinballGamePage(),
      ),
      58 => _GameLaunchTarget(
        gameId: 'kite_runner',
        icon: Icons.air_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const KiteRunnerGamePage(),
      ),
      59 => _GameLaunchTarget(
        gameId: 'rhythm_drums',
        icon: Icons.graphic_eq_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const RhythmDrumsGamePage(),
      ),
      60 => _GameLaunchTarget(
        gameId: 'skate_combo',
        icon: Icons.skateboarding_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const SkateComboGamePage(),
      ),
      61 => _GameLaunchTarget(
        gameId: 'snowboard_slalom',
        icon: Icons.downhill_skiing_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const SnowboardSlalomGamePage(),
      ),
      62 => _GameLaunchTarget(
        gameId: 'jetpack_courier',
        icon: Icons.rocket_launch_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const JetpackCourierGamePage(),
      ),
      63 => _GameLaunchTarget(
        gameId: 'orbit_rescue',
        icon: Icons.public_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const OrbitRescueGamePage(),
      ),
      64 => _GameLaunchTarget(
        gameId: 'meaning_match',
        icon: Icons.hub_rounded,
        accentColor: StudioGameClass.language.accent,
        builder: () => const MeaningMatchGamePage(),
      ),
      65 => _GameLaunchTarget(
        gameId: 'proverb_finish',
        icon: Icons.menu_book_rounded,
        accentColor: StudioGameClass.language.accent,
        builder: () => const ProverbFinishGamePage(),
      ),
      66 => _GameLaunchTarget(
        gameId: 'sentence_builder',
        icon: Icons.format_align_left_rounded,
        accentColor: StudioGameClass.language.accent,
        builder: () => const SentenceBuilderGamePage(),
      ),
      67 => _GameLaunchTarget(
        gameId: 'near_meaning',
        icon: Icons.manage_search_rounded,
        accentColor: StudioGameClass.language.accent,
        builder: () => const NearMeaningGamePage(),
      ),
      68 => _GameLaunchTarget(
        gameId: 'letter_maze',
        icon: Icons.route_rounded,
        accentColor: StudioGameClass.language.accent,
        builder: () => const LetterMazeGamePage(),
      ),
      69 => _GameLaunchTarget(
        gameId: 'language_detective',
        icon: Icons.manage_search_rounded,
        accentColor: StudioGameClass.language.accent,
        builder: () => const LanguageDetectiveGamePage(),
      ),
      70 => _GameLaunchTarget(
        gameId: 'story_order',
        icon: Icons.timeline_rounded,
        accentColor: StudioGameClass.language.accent,
        builder: () => const StoryOrderGamePage(),
      ),
      80 => _GameLaunchTarget(
        gameId: 'drift_league',
        icon: Icons.sports_motorsports_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const DriftLeagueGamePage(),
      ),
      81 => _GameLaunchTarget(
        gameId: 'table_tennis_rally',
        icon: Icons.sports_tennis_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const TableTennisRallyGamePage(),
      ),
      82 => _GameLaunchTarget(
        gameId: 'penalty_mindgame',
        icon: Icons.sports_soccer_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const PenaltyMindgamePage(),
      ),
      83 => _GameLaunchTarget(
        gameId: 'air_hockey_arena',
        icon: Icons.sports_hockey_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const AirHockeyArenaPage(),
      ),
      84 => _GameLaunchTarget(
        gameId: 'relic_run',
        icon: Icons.explore_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const RelicRunGamePage(),
      ),
      85 => _GameLaunchTarget(
        gameId: 'lighthouse_defense',
        icon: Icons.light_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const LighthouseDefenseGamePage(),
      ),
      86 => _GameLaunchTarget(
        gameId: 'museum_after_hours',
        icon: Icons.museum_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const MuseumAfterHoursPage(),
      ),
      87 => _GameLaunchTarget(
        gameId: 'deep_current',
        icon: Icons.sailing_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const DeepCurrentGamePage(),
      ),
      88 => _GameLaunchTarget(
        gameId: 'cafe_shift',
        icon: Icons.local_cafe_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const CafeShiftGamePage(),
      ),
      89 => _GameLaunchTarget(
        gameId: 'interior_studio',
        icon: Icons.chair_alt_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const InteriorStudioGamePage(),
      ),
      90 => _GameLaunchTarget(
        gameId: 'tideglass_aquarium',
        icon: Icons.water_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const TideglassAquariumGamePage(),
      ),
      91 => _GameLaunchTarget(
        gameId: 'pet_rescue_clinic',
        icon: Icons.pets_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const PetRescueClinicGamePage(),
      ),
      92 => _GameLaunchTarget(
        gameId: 'boardwalk_builder',
        icon: Icons.attractions_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const BoardwalkBuilderGamePage(),
      ),
      93 => _GameLaunchTarget(
        gameId: 'moonbase_ops',
        icon: Icons.rocket_launch_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const MoonbaseOpsGamePage(),
      ),
      94 => _GameLaunchTarget(
        gameId: 'museum_curator',
        icon: Icons.museum_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const MuseumCuratorGamePage(),
      ),
      95 => _GameLaunchTarget(
        gameId: 'festival_producer',
        icon: Icons.festival_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const FestivalProducerGamePage(),
      ),
      96 => _GameLaunchTarget(
        gameId: 'secret_room_party',
        icon: Icons.visibility_off_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const SecretRoomPartyGamePage(),
      ),
      97 => _GameLaunchTarget(
        gameId: 'dice_bluff_arena',
        icon: Icons.casino_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const DiceBluffArenaGamePage(),
      ),
      98 => _GameLaunchTarget(
        gameId: 'signal_pair',
        icon: Icons.sensors_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const SignalPairGamePage(),
      ),
      99 => _GameLaunchTarget(
        gameId: 'deckforge_duel',
        icon: Icons.style_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const DeckforgeDuelGamePage(),
      ),
      123 => _GameLaunchTarget(
        gameId: 'city_atlas',
        icon: Icons.map_outlined,
        accentColor: StudioGameClass.visual.accent,
        builder: () => const AtlasFindGamePage(kind: AtlasKind.turkey),
      ),
      124 => _GameLaunchTarget(
        gameId: 'world_atlas',
        icon: Icons.public_rounded,
        accentColor: StudioGameClass.visual.accent,
        builder: () => const AtlasFindGamePage(kind: AtlasKind.world),
      ),
      125 => _GameLaunchTarget(
        gameId: 'katamino_workshop',
        icon: Icons.extension_rounded,
        accentColor: StudioGameClass.visual.accent,
        builder: () => const KataminoGamePage(),
      ),
      126 => _GameLaunchTarget(
        gameId: 'single_stroke',
        icon: Icons.gesture_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const SingleStrokeGamePage(),
      ),
      127 => _GameLaunchTarget(
        gameId: 'arrow_maze',
        icon: Icons.alt_route_rounded,
        accentColor: StudioGameClass.logic.accent,
        builder: () => const ArrowMazeGamePage(),
      ),
      128 => _GameLaunchTarget(
        gameId: 'bubble_shooter',
        icon: Icons.bubble_chart_rounded,
        accentColor: StudioGameClass.fun.accent,
        builder: () => const BubbleShooterGamePage(),
      ),
      _ => null,
    };

    if (target == null ||
        StudioGameCatalog.byId(target.gameId)?.isRetired == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.l10n.courseUnavailable),
        ),
      );
      return;
    }

    _gameOpening = true;

    // Navigasyonu sesin tamamlanmasına bağlamıyoruz.
    // Ses asset'i olmasa bile oyun anında açılır.
    // Keep the launch feedback audible but calmer than in-game effects.
    unawaited(_audio.play(GameSound.uiClick, gain: _gameOpeningSoundGain));
    unawaited(
      _audio.play(GameSound.transition, gain: 0.62 * _gameOpeningSoundGain),
    );

    unawaited(_analytics.logGameOpen(target.gameId));

    try {
      await Navigator.of(context).push<void>(
        buildFastGameRoute<void>(
          gameId: target.gameId,
          gameBuilder: target.builder,
          gameTitle: context.l10n.gameTitle(target.gameId),
          gameIcon: target.icon,
          accentColor: target.accentColor,
          reduceMotion: AppExperienceController.instance.reduceMotion(
            systemRequestsReducedMotion: MediaQuery.disableAnimationsOf(
              context,
            ),
          ),
          animationScale: AppExperienceController.instance.animationScale,
          settings: RouteSettings(name: '/game/${target.gameId}'),
        ),
      );

      if (mounted) {
        await anaSayfayiYenile();
      }
    } finally {
      _gameOpening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool gardenTheme =
        _experience.visualTheme == AppVisualTheme.studioGarden;
    final List<_StudioPlayableGame> playableGames = _visiblePlayableGames();
    return Scaffold(
      key: const ValueKey<String>('v9_pro_home'),
      backgroundColor: StudioVisuals.canvas,

      extendBody: true,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 14,
        title: Row(
          children: <Widget>[
            const _StudioMark(),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Zeka Parkuru',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: gardenTheme ? 17 : 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          if (gardenTheme) ...<Widget>[
            _StudioGardenScoreAction(
              score: toplamPuan,
              avatar: oyuncuVeri?.profile.avatar ?? '🧠',
              onProfileTap: profiliAc,
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            tooltip: context.l10n.settings,
            onPressed: ayarlariAc,
            style: IconButton.styleFrom(
              backgroundColor: StudioVisuals.surface,
              foregroundColor: StudioVisuals.ink,
              side: const BorderSide(color: StudioVisuals.line),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 14),
        ],
      ),

      body: StudioPageFrame(
        child: SafeArea(
          top: false,
          child: yukleniyor
              ? const SizedBox.expand()
              : RefreshIndicator(
                  color: StudioVisuals.teal,
                  backgroundColor: StudioVisuals.surface,
                  onRefresh: anaSayfayiYenile,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      StudioVisuals.pageGutter,
                      12,
                      StudioVisuals.pageGutter,
                      112,
                    ),
                    children: [
                      if (!gardenTheme) ...<Widget>[
                        _TopPanel(player: oyuncuVeri, totalScore: toplamPuan),
                        const SizedBox(height: 18),
                      ],

                      if (gardenTheme)
                        _StudioGardenDailyCard(
                          data: gunlukVeri,
                          onTap: gunlukGorevleriAc,
                        )
                      else
                        _DailyPanel(data: gunlukVeri, onTap: gunlukGorevleriAc),

                      if (gardenTheme) ...<Widget>[
                        const SizedBox(height: 18),
                        _StudioGardenCategorySection(
                          isEnglish: context.l10n.isEnglish,
                          games: playableGames,
                          loadGames: _visiblePlayableGames,
                          onOpenGame: oyunuAc,
                        ),
                      ],

                      const SizedBox(height: 18),

                      _HomeArenaCard(onTap: arenayiAc),

                      const SizedBox(height: 26),

                    ],
                  ),
                ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: StudioVisuals.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: StudioVisuals.line),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: StudioVisuals.ink.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NavigationBar(
                selectedIndex: 0,
                onDestinationSelected: altMenuSec,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                height: 68,
                indicatorColor: StudioVisuals.tealSoft,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
                  return TextStyle(
                    color: states.contains(WidgetState.selected)
                        ? StudioVisuals.ink
                        : StudioVisuals.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  );
                }),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.grid_view_outlined),
                    selectedIcon: const Icon(
                      Icons.grid_view_rounded,
                      color: StudioVisuals.teal,
                    ),
                    label: context.l10n.home,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.auto_awesome_outlined),
                    selectedIcon: const Icon(
                      Icons.auto_awesome_rounded,
                      color: StudioVisuals.teal,
                    ),
                    label: context.l10n.tasks,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.military_tech_outlined),
                    selectedIcon: const Icon(
                      Icons.military_tech_rounded,
                      color: StudioVisuals.teal,
                    ),
                    label: context.l10n.leaderboard,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const Icon(
                      Icons.person_rounded,
                      color: StudioVisuals.teal,
                    ),
                    label: context.l10n.profile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _referenceGameStars(String gameId) =>
      _referenceGameProgress[gameId]?.stars.fold<int>(
        0,
        (int total, int stars) => total + stars,
      ) ??
      0;

  _StudioPlayableGame _referencePlayableGame({
    required int number,
    required String gameId,
    required StudioGameClass gameClass,
    required IconData icon,
  }) {
    final ParkurProgressSnapshot? progress = _referenceGameProgress[gameId];
    return _StudioPlayableGame(
      number: number,
      gameId: gameId,
      gameClass: gameClass,
      icon: icon,
      level: progress?.unlockedLevel ?? 1,
      stars: _referenceGameStars(gameId),
      score:
          progress?.bestScores.fold<int>(
            0,
            (int total, int score) => total + score,
          ) ??
          0,
      starTarget: 30,
      onTap: () => oyunuAc(number),
    );
  }

  List<_StudioPlayableGame> _visiblePlayableGames() =>
      <_StudioPlayableGame>[
            _StudioPlayableGame(
              number: 1,
              gameId: 'logic',
              gameClass: StudioGameClass.logic,
              icon: Icons.extension_rounded,
              level: mantikSeviye,
              stars: mantikYildiz,
              score: mantikPuani,
              onTap: () => oyunuAc(1),
            ),
            _StudioPlayableGame(
              number: 12,
              gameId: 'flow_connect',
              gameClass: StudioGameClass.logic,
              icon: Icons.device_hub_rounded,
              level: akisSeviye,
              stars: akisYildiz,
              score: akisPuani,
              onTap: () => oyunuAc(12),
            ),
            _StudioPlayableGame(
              number: 13,
              gameId: 'circuit_repair',
              gameClass: StudioGameClass.logic,
              icon: Icons.electric_bolt_rounded,
              level: devreSeviye,
              stars: devreYildiz,
              score: devrePuani,
              onTap: () => oyunuAc(13),
            ),
            _StudioPlayableGame(
              number: 14,
              gameId: 'detective_notes',
              gameClass: StudioGameClass.logic,
              icon: Icons.manage_search_rounded,
              level: dedektifSeviye,
              stars: dedektifYildiz,
              score: dedektifPuani,
              starTarget: DetectiveNotesGamePage.totalStars,
              onTap: () => oyunuAc(14),
            ),
            _StudioPlayableGame(
              number: 15,
              gameId: 'bridge_builder',
              gameClass: StudioGameClass.logic,
              icon: Icons.account_tree_rounded,
              level: kopruSeviye,
              stars: kopruYildiz,
              score: kopruPuani,
              starTarget: BridgeBuilderGamePage.totalStars,
              onTap: () => oyunuAc(15),
            ),
            _StudioPlayableGame(
              number: 16,
              gameId: 'gate_sequence',
              gameClass: StudioGameClass.logic,
              icon: Icons.door_front_door_outlined,
              level: kapiDizisiSeviye,
              stars: kapiDizisiYildiz,
              score: kapiDizisiPuani,
              starTarget: GateSequenceGamePage.totalStars,
              onTap: () => oyunuAc(16),
            ),
            _StudioPlayableGame(
              number: 17,
              gameId: 'parking_puzzle',
              gameClass: StudioGameClass.strategy,
              icon: Icons.directions_car_filled_rounded,
              level: parkYeriSeviye,
              stars: parkYeriYildiz,
              score: parkYeriPuani,
              starTarget: ParkingPuzzleGamePage.totalStars,
              onTap: () => oyunuAc(17),
            ),
            _StudioPlayableGame(
              number: 18,
              gameId: 'pin_unlock',
              gameClass: StudioGameClass.logic,
              icon: Icons.lock_open_rounded,
              level: kilitAcSeviye,
              stars: kilitAcYildiz,
              score: kilitAcPuani,
              starTarget: PinUnlockGamePage.totalStars,
              onTap: () => oyunuAc(18),
            ),
            _StudioPlayableGame(
              number: 19,
              gameId: 'balance_scale',
              gameClass: StudioGameClass.logic,
              icon: Icons.balance_rounded,
              level: agirlikDengesiSeviye,
              stars: agirlikDengesiYildiz,
              score: agirlikDengesiPuani,
              starTarget: BalanceScaleGamePage.totalStars,
              onTap: () => oyunuAc(19),
            ),
            _StudioPlayableGame(
              number: 20,
              gameId: 'target_24',
              gameClass: StudioGameClass.numbers,
              icon: Icons.functions_rounded,
              level: hedef24Seviye,
              stars: hedef24Yildiz,
              score: hedef24Puani,
              starTarget: Target24GamePage.totalStars,
              onTap: () => oyunuAc(20),
            ),
            _StudioPlayableGame(
              number: 21,
              gameId: 'mini_sudoku',
              gameClass: StudioGameClass.numbers,
              icon: Icons.grid_on_rounded,
              level: miniSudokuSeviye,
              stars: miniSudokuYildiz,
              score: miniSudokuPuani,
              starTarget: MiniSudokuGamePage.totalStars,
              onTap: () => oyunuAc(21),
            ),
            _StudioPlayableGame(
              number: 22,
              gameId: 'kenken_cube',
              gameClass: StudioGameClass.numbers,
              icon: Icons.functions_rounded,
              level: kenkenSeviye,
              stars: kenkenYildiz,
              score: kenkenPuani,
              starTarget: KenKenCubeGamePage.totalStars,
              onTap: () => oyunuAc(22),
            ),
            _StudioPlayableGame(
              number: 23,
              gameId: 'mahjong_layers',
              gameClass: StudioGameClass.visual,
              icon: Icons.layers_rounded,
              level: mahjongSeviye,
              stars: mahjongYildiz,
              score: mahjongPuani,
              starTarget: MahjongLayersGamePage.totalStars,
              onTap: () => oyunuAc(23),
            ),
            _StudioPlayableGame(
              number: 24,
              gameId: 'mine_detective',
              gameClass: StudioGameClass.logic,
              icon: Icons.radar_rounded,
              level: mayinSeviye,
              stars: mayinYildiz,
              score: mayinPuani,
              starTarget: MineDetectorGamePage.totalStars,
              onTap: () => oyunuAc(24),
            ),
            _StudioPlayableGame(
              number: 25,
              gameId: 'warehouse_master',
              gameClass: StudioGameClass.strategy,
              icon: Icons.inventory_2_outlined,
              level: depoUstasiSeviye,
              stars: depoUstasiYildiz,
              score: depoUstasiPuani,
              starTarget: WarehouseMasterGamePage.totalStars,
              onTap: () => oyunuAc(25),
            ),
            _StudioPlayableGame(
              number: 2,
              gameId: 'numbers',
              gameClass: StudioGameClass.numbers,
              icon: Icons.calculate_rounded,
              level: sayiSeviye,
              stars: sayiYildiz,
              score: sayiPuani,
              onTap: () => oyunuAc(2),
            ),
            _StudioPlayableGame(
              number: 9,
              gameId: 'number_sort',
              gameClass: StudioGameClass.numbers,
              icon: Icons.grid_4x4_rounded,
              level: sayiPetegiSeviye,
              stars: sayiPetegiYildiz,
              score: sayiPetegiPuani,
              onTap: () => oyunuAc(9),
            ),
            _StudioPlayableGame(
              number: 3,
              gameId: 'blocks',
              gameClass: StudioGameClass.visual,
              icon: Icons.grid_view_rounded,
              level: blokSeviye,
              stars: blokYildiz,
              score: blokPuani,
              onTap: () => oyunuAc(3),
            ),
            _StudioPlayableGame(
              number: 7,
              gameId: 'picture_iq',
              gameClass: StudioGameClass.visual,
              icon: Icons.auto_awesome_mosaic_rounded,
              level: gorselIqSeviye,
              stars: gorselIqYildiz,
              score: gorselIqPuani,
              onTap: () => oyunuAc(7),
            ),
            _StudioPlayableGame(
              number: 10,
              gameId: 'shape_puzzle',
              gameClass: StudioGameClass.visual,
              icon: Icons.interests_rounded,
              level: sekilSeviye,
              stars: sekilYildiz,
              score: sekilPuani,
              onTap: () => oyunuAc(10),
            ),
            _StudioPlayableGame(
              number: 4,
              gameId: 'memory',
              gameClass: StudioGameClass.memory,
              icon: Icons.psychology_rounded,
              level: hafizaSeviye,
              stars: hafizaYildiz,
              score: hafizaPuani,
              onTap: () => oyunuAc(4),
            ),
            _StudioPlayableGame(
              number: 5,
              gameId: 'hanoi',
              gameClass: StudioGameClass.strategy,
              icon: Icons.account_tree_rounded,
              level: hanoiSeviye,
              stars: hanoiYildiz,
              score: hanoiPuani,
              onTap: () => oyunuAc(5),
            ),
            _StudioPlayableGame(
              number: 8,
              gameId: 'candy_sort',
              gameClass: StudioGameClass.strategy,
              icon: Icons.water_drop_rounded,
              level: sekerSeviye,
              stars: sekerYildiz,
              score: sekerPuani,
              onTap: () => oyunuAc(8),
            ),
            _StudioPlayableGame(
              number: 6,
              gameId: 'word_hunt',
              gameClass: StudioGameClass.language,
              icon: Icons.travel_explore_rounded,
              level: kelimeSeviye,
              stars: kelimeYildiz,
              score: kelimePuani,
              onTap: () => oyunuAc(6),
            ),
            _StudioPlayableGame(
              number: 26,
              gameId: 'word_wheel',
              gameClass: StudioGameClass.language,
              icon: Icons.casino_outlined,
              level: kelimeCarkiSeviye,
              stars: kelimeCarkiYildiz,
              score: kelimeCarkiPuani,
              starTarget: WordWheelGamePage.totalStars,
              onTap: () => oyunuAc(26),
            ),
            _StudioPlayableGame(
              number: 64,
              gameId: 'meaning_match',
              gameClass: StudioGameClass.language,
              icon: Icons.hub_rounded,
              level: meaningMatchSeviye,
              stars: meaningMatchYildiz,
              score: meaningMatchPuani,
              starTarget: MeaningMatchGamePage.totalStars,
              onTap: () => oyunuAc(64),
            ),
            _StudioPlayableGame(
              number: 65,
              gameId: 'proverb_finish',
              gameClass: StudioGameClass.language,
              icon: Icons.menu_book_rounded,
              level: proverbFinishSeviye,
              stars: proverbFinishYildiz,
              score: proverbFinishPuani,
              starTarget: ProverbFinishGamePage.totalStars,
              onTap: () => oyunuAc(65),
            ),
            _StudioPlayableGame(
              number: 66,
              gameId: 'sentence_builder',
              gameClass: StudioGameClass.language,
              icon: Icons.format_align_left_rounded,
              level: sentenceBuilderSeviye,
              stars: sentenceBuilderYildiz,
              score: sentenceBuilderPuani,
              starTarget: SentenceBuilderGamePage.totalStars,
              onTap: () => oyunuAc(66),
            ),
            _StudioPlayableGame(
              number: 67,
              gameId: 'near_meaning',
              gameClass: StudioGameClass.language,
              icon: Icons.manage_search_rounded,
              level: nearMeaningSeviye,
              stars: nearMeaningYildiz,
              score: nearMeaningPuani,
              starTarget: NearMeaningGamePage.totalStars,
              onTap: () => oyunuAc(67),
            ),
            _StudioPlayableGame(
              number: 68,
              gameId: 'letter_maze',
              gameClass: StudioGameClass.language,
              icon: Icons.route_rounded,
              level: letterMazeSeviye,
              stars: letterMazeYildiz,
              score: letterMazePuani,
              starTarget: LetterMazeGamePage.totalStars,
              onTap: () => oyunuAc(68),
            ),
            _StudioPlayableGame(
              number: 69,
              gameId: 'language_detective',
              gameClass: StudioGameClass.language,
              icon: Icons.manage_search_rounded,
              level: languageDetectiveSeviye,
              stars: languageDetectiveYildiz,
              score: languageDetectivePuani,
              starTarget: LanguageDetectiveGamePage.totalStars,
              onTap: () => oyunuAc(69),
            ),
            _StudioPlayableGame(
              number: 70,
              gameId: 'story_order',
              gameClass: StudioGameClass.language,
              icon: Icons.timeline_rounded,
              level: storyOrderSeviye,
              stars: storyOrderYildiz,
              score: storyOrderPuani,
              starTarget: StoryOrderGamePage.totalStars,
              onTap: () => oyunuAc(70),
            ),
            _StudioPlayableGame(
              number: 72,
              gameId: 'card_pairs',
              gameClass: StudioGameClass.memory,
              icon: Icons.style_rounded,
              level: cardPairsSeviye,
              stars: cardPairsYildiz,
              score: cardPairsPuani,
              starTarget: CardPairsGamePage.totalStars,
              onTap: () => oyunuAc(72),
            ),
            _StudioPlayableGame(
              number: 73,
              gameId: 'focus_filter',
              gameClass: StudioGameClass.speed,
              icon: Icons.filter_center_focus_rounded,
              level: focusFilterSeviye,
              stars: focusFilterYildiz,
              score: focusFilterPuani,
              starTarget: FocusFilterGamePage.totalStars,
              onTap: () => oyunuAc(73),
            ),
            _StudioPlayableGame(
              number: 74,
              gameId: 'spot_change',
              gameClass: StudioGameClass.memory,
              icon: Icons.compare_rounded,
              level: spotChangeSeviye,
              stars: spotChangeYildiz,
              score: spotChangePuani,
              starTarget: SpotChangeGamePage.totalStars,
              onTap: () => oyunuAc(74),
            ),
            _StudioPlayableGame(
              number: 75,
              gameId: 'rhythm_memory',
              gameClass: StudioGameClass.memory,
              icon: Icons.graphic_eq_rounded,
              level: rhythmMemorySeviye,
              stars: rhythmMemoryYildiz,
              score: rhythmMemoryPuani,
              starTarget: RhythmMemoryGamePage.totalStars,
              onTap: () => oyunuAc(75),
            ),
            _StudioPlayableGame(
              number: 78,
              gameId: 'attention_tunnel',
              gameClass: StudioGameClass.memory,
              icon: Icons.blur_on_rounded,
              level: attentionTunnelSeviye,
              stars: attentionTunnelYildiz,
              score: attentionTunnelPuani,
              starTarget: AttentionTunnelGamePage.totalStars,
              onTap: () => oyunuAc(78),
            ),
            _StudioPlayableGame(
              number: 27,
              gameId: 'hidden_masses',
              gameClass: StudioGameClass.logic,
              icon: Icons.scale_outlined,
              level: gizliKutleSeviye,
              stars: gizliKutleYildiz,
              score: gizliKutlePuani,
              starTarget: HiddenMassesGamePage.totalStars,
              onTap: () => oyunuAc(27),
            ),
            _StudioPlayableGame(
              number: 28,
              gameId: 'kakuro',
              gameClass: StudioGameClass.numbers,
              icon: Icons.grid_on_rounded,
              level: kakuroSeviye,
              stars: kakuroYildiz,
              score: kakuroPuani,
              starTarget: KakuroGamePage.totalStars,
              onTap: () => oyunuAc(28),
            ),
            _StudioPlayableGame(
              number: 29,
              gameId: 'reversi_arena',
              gameClass: StudioGameClass.strategy,
              icon: Icons.change_circle_outlined,
              level: reversiSeviye,
              stars: reversiYildiz,
              score: reversiPuani,
              starTarget: ReversiGamePage.totalStars,
              onTap: () => oyunuAc(29),
            ),
            _StudioPlayableGame(
              number: 30,
              gameId: 'picross_master',
              gameClass: StudioGameClass.visual,
              icon: Icons.grid_4x4_rounded,
              level: picrossSeviye,
              stars: picrossYildiz,
              score: picrossPuani,
              starTarget: PicrossGamePage.totalStars,
              onTap: () => oyunuAc(30),
            ),
            _StudioPlayableGame(
              number: 31,
              gameId: 'tavla_master',
              gameClass: StudioGameClass.strategy,
              icon: Icons.casino_outlined,
              level: tavlaSeviye,
              stars: tavlaYildiz,
              score: tavlaPuani,
              starTarget: TavlaGamePage.totalStars,
              onTap: () => oyunuAc(31),
            ),
            _StudioPlayableGame(
              number: 32,
              gameId: 'arrow_route',
              gameClass: StudioGameClass.visual,
              icon: Icons.near_me_outlined,
              level: arrowRouteSeviye,
              stars: arrowRouteYildiz,
              score: arrowRoutePuani,
              starTarget: ArrowRouteGamePage.totalStars,
              onTap: () => oyunuAc(32),
            ),
            _StudioPlayableGame(
              number: 33,
              gameId: 'mini_chess_tactics',
              gameClass: StudioGameClass.strategy,
              icon: Icons.grid_4x4_rounded,
              level: satrancMatiSeviye,
              stars: satrancMatiYildiz,
              score: satrancMatiPuani,
              starTarget: ChessMateGamePage.totalStars,
              onTap: () => oyunuAc(33),
            ),
            _StudioPlayableGame(
              number: 34,
              gameId: 'loop_master',
              gameClass: StudioGameClass.logic,
              icon: Icons.loop_rounded,
              level: donguUstasiSeviye,
              stars: donguUstasiYildiz,
              score: donguUstasiPuani,
              starTarget: LoopMasterGamePage.totalStars,
              onTap: () => oyunuAc(34),
            ),
            _StudioPlayableGame(
              number: 35,
              gameId: 'go_life_death',
              gameClass: StudioGameClass.strategy,
              icon: Icons.circle_outlined,
              level: goYasamOlumSeviye,
              stars: goYasamOlumYildiz,
              score: goYasamOlumPuani,
              starTarget: GoLifeDeathGamePage.totalStars,
              onTap: () => oyunuAc(35),
            ),
            _StudioPlayableGame(
              number: 36,
              gameId: 'code_breaker',
              gameClass: StudioGameClass.logic,
              icon: Icons.password_rounded,
              level: kodKiriciSeviye,
              stars: kodKiriciYildiz,
              score: kodKiriciPuani,
              starTarget: CodeBreakerGamePage.totalStars,
              onTap: () => oyunuAc(36),
            ),
            _StudioPlayableGame(
              number: 37,
              gameId: 'shogi_mate',
              gameClass: StudioGameClass.strategy,
              icon: Icons.grid_on_rounded,
              level: shogiMatSeviye,
              stars: shogiMatYildiz,
              score: shogiMatPuani,
              starTarget: ShogiMateGamePage.totalStars,
              onTap: () => oyunuAc(37),
            ),
            _StudioPlayableGame(
              number: 38,
              gameId: 'island_sea',
              gameClass: StudioGameClass.logic,
              icon: Icons.waves_rounded,
              level: adaDenizSeviye,
              stars: adaDenizYildiz,
              score: adaDenizPuani,
              starTarget: IslandSeaGamePage.totalStars,
              onTap: () => oyunuAc(38),
            ),
            _StudioPlayableGame(
              number: 39,
              gameId: 'peg_solitaire',
              gameClass: StudioGameClass.strategy,
              icon: Icons.circle_outlined,
              level: tekTasSeviye,
              stars: tekTasYildiz,
              score: tekTasPuani,
              starTarget: PegSolitaireGamePage.totalStars,
              onTap: () => oyunuAc(39),
            ),
            _StudioPlayableGame(
              number: 40,
              gameId: 'futoshiki',
              gameClass: StudioGameClass.numbers,
              icon: Icons.grid_4x4_rounded,
              level: futoshikiSeviye,
              stars: futoshikiYildiz,
              score: futoshikiPuani,
              starTarget: FutoshikiGamePage.totalStars,
              onTap: () => oyunuAc(40),
            ),
            _StudioPlayableGame(
              number: 41,
              gameId: 'hex_connection',
              gameClass: StudioGameClass.strategy,
              icon: Icons.hexagon_outlined,
              level: hexConnectionSeviye,
              stars: hexConnectionYildiz,
              score: hexConnectionPuani,
              starTarget: HexConnectionGamePage.totalStars,
              onTap: () => oyunuAc(41),
            ),
            _StudioPlayableGame(
              number: 42,
              gameId: 'skyscrapers',
              gameClass: StudioGameClass.logic,
              icon: Icons.location_city_outlined,
              level: skyscrapersSeviye,
              stars: skyscrapersYildiz,
              score: skyscrapersPuani,
              starTarget: SkyscrapersGamePage.totalStars,
              onTap: () => oyunuAc(42),
            ),
            _StudioPlayableGame(
              number: 43,
              gameId: 'hitori',
              gameClass: StudioGameClass.logic,
              icon: Icons.grid_view_rounded,
              level: hitoriSeviye,
              stars: hitoriYildiz,
              score: hitoriPuani,
              starTarget: HitoriGamePage.totalStars,
              onTap: () => oyunuAc(43),
            ),
            _StudioPlayableGame(
              number: 44,
              gameId: 'balloon_pop',
              gameClass: StudioGameClass.fun,
              icon: Icons.air_rounded,
              level: balloonSeviye,
              stars: balloonYildiz,
              score: balloonPuani,
              starTarget: BalloonCatcherGamePage.totalStars,
              onTap: () => oyunuAc(44),
            ),
            _StudioPlayableGame(
              number: 45,
              gameId: 'bottle_target',
              gameClass: StudioGameClass.fun,
              icon: Icons.sports_baseball_rounded,
              level: bottleTargetSeviye,
              stars: bottleTargetYildiz,
              score: bottleTargetPuani,
              starTarget: BottleTargetGamePage.totalStars,
              onTap: () => oyunuAc(45),
            ),
            _StudioPlayableGame(
              number: 46,
              gameId: 'color_match',
              gameClass: StudioGameClass.fun,
              icon: Icons.bubble_chart_rounded,
              level: colorReactorSeviye,
              stars: colorReactorYildiz,
              score: colorReactorPuani,
              starTarget: ColorReactorGamePage.totalStars,
              onTap: () => oyunuAc(46),
            ),
            _StudioPlayableGame(
              number: 47,
              gameId: 'ball_merge',
              gameClass: StudioGameClass.fun,
              icon: Icons.blur_circular_rounded,
              level: ballMergeSeviye,
              stars: ballMergeYildiz,
              score: ballMergePuani,
              starTarget: BallMergeGamePage.totalStars,
              onTap: () => oyunuAc(47),
            ),
            _StudioPlayableGame(
              number: 48,
              gameId: 'tower_balance',
              gameClass: StudioGameClass.fun,
              icon: Icons.balance_rounded,
              level: towerBalanceSeviye,
              stars: towerBalanceYildiz,
              score: towerBalancePuani,
              starTarget: TowerBalanceGamePage.totalStars,
              onTap: () => oyunuAc(48),
            ),
            _StudioPlayableGame(
              number: 49,
              gameId: 'magnet_path',
              gameClass: StudioGameClass.fun,
              icon: Icons.flare_rounded,
              level: magnetPathSeviye,
              stars: magnetPathYildiz,
              score: magnetPathPuani,
              starTarget: MagnetPathGamePage.totalStars,
              onTap: () => oyunuAc(49),
            ),
            _StudioPlayableGame(
              number: 50,
              gameId: 'mini_golf_route',
              gameClass: StudioGameClass.fun,
              icon: Icons.sports_golf_rounded,
              level: miniGolfSeviye,
              stars: miniGolfYildiz,
              score: miniGolfPuani,
              starTarget: MiniGolfGamePage.totalStars,
              onTap: () => oyunuAc(50),
            ),
            _StudioPlayableGame(
              number: 51,
              gameId: 'slide_sweets',
              gameClass: StudioGameClass.speed,
              icon: Icons.factory_rounded,
              level: slideSweetsSeviye,
              stars: slideSweetsYildiz,
              score: slideSweetsPuani,
              starTarget: SlideSweetsGamePage.totalStars,
              onTap: () => oyunuAc(51),
            ),
            _StudioPlayableGame(
              number: 52,
              gameId: 'ring_toss',
              gameClass: StudioGameClass.fun,
              icon: Icons.sports_handball_rounded,
              level: ringTossSeviye,
              stars: ringTossYildiz,
              score: ringTossPuani,
              starTarget: RingTossGamePage.totalStars,
              onTap: () => oyunuAc(52),
            ),
            _StudioPlayableGame(
              number: 53,
              gameId: 'little_fisher',
              gameClass: StudioGameClass.fun,
              icon: Icons.phishing_rounded,
              level: littleFisherSeviye,
              stars: littleFisherYildiz,
              score: littleFisherPuani,
              starTarget: LittleFisherGamePage.totalStars,
              onTap: () => oyunuAc(53),
            ),
            _StudioPlayableGame(
              number: 54,
              gameId: 'marble_route',
              gameClass: StudioGameClass.fun,
              icon: Icons.sports_handball_rounded,
              level: marbleRouteSeviye,
              stars: marbleRouteYildiz,
              score: marbleRoutePuani,
              starTarget: MarbleRouteGamePage.totalStars,
              onTap: () => oyunuAc(54),
            ),
            _StudioPlayableGame(
              number: 55,
              gameId: 'block_flow',
              gameClass: StudioGameClass.fun,
              icon: Icons.view_in_ar_rounded,
              level: blockFlowSeviye,
              stars: blockFlowYildiz,
              score: blockFlowPuani,
              starTarget: BlockFlowGamePage.totalStars,
              onTap: () => oyunuAc(55),
            ),
            _StudioPlayableGame(
              number: 56,
              gameId: 'paper_flight',
              gameClass: StudioGameClass.fun,
              icon: Icons.airplanemode_active_rounded,
              level: paperFlightSeviye,
              stars: paperFlightYildiz,
              score: paperFlightPuani,
              starTarget: PaperFlightGamePage.totalStars,
              onTap: () => oyunuAc(56),
            ),
            _StudioPlayableGame(
              number: 57,
              gameId: 'neon_pinball',
              gameClass: StudioGameClass.fun,
              icon: Icons.sports_esports_rounded,
              level: neonPinballSeviye,
              stars: neonPinballYildiz,
              score: neonPinballPuani,
              starTarget: NeonPinballGamePage.totalStars,
              onTap: () => oyunuAc(57),
            ),
            _StudioPlayableGame(
              number: 58,
              gameId: 'kite_runner',
              gameClass: StudioGameClass.fun,
              icon: Icons.air_rounded,
              level: kiteRunnerSeviye,
              stars: kiteRunnerYildiz,
              score: kiteRunnerPuani,
              starTarget: KiteRunnerGamePage.totalStars,
              onTap: () => oyunuAc(58),
            ),
            _StudioPlayableGame(
              number: 59,
              gameId: 'rhythm_drums',
              gameClass: StudioGameClass.fun,
              icon: Icons.graphic_eq_rounded,
              level: rhythmDrumsSeviye,
              stars: rhythmDrumsYildiz,
              score: rhythmDrumsPuani,
              starTarget: RhythmDrumsGamePage.totalStars,
              onTap: () => oyunuAc(59),
            ),
            _StudioPlayableGame(
              number: 60,
              gameId: 'skate_combo',
              gameClass: StudioGameClass.fun,
              icon: Icons.skateboarding_rounded,
              level: skateComboSeviye,
              stars: skateComboYildiz,
              score: skateComboPuani,
              starTarget: SkateComboGamePage.totalStars,
              onTap: () => oyunuAc(60),
            ),
            _StudioPlayableGame(
              number: 61,
              gameId: 'snowboard_slalom',
              gameClass: StudioGameClass.fun,
              icon: Icons.downhill_skiing_rounded,
              level: snowboardSlalomSeviye,
              stars: snowboardSlalomYildiz,
              score: snowboardSlalomPuani,
              starTarget: SnowboardSlalomGamePage.totalStars,
              onTap: () => oyunuAc(61),
            ),
            _StudioPlayableGame(
              number: 62,
              gameId: 'jetpack_courier',
              gameClass: StudioGameClass.fun,
              icon: Icons.rocket_launch_rounded,
              level: jetpackCourierSeviye,
              stars: jetpackCourierYildiz,
              score: jetpackCourierPuani,
              starTarget: JetpackCourierGamePage.totalStars,
              onTap: () => oyunuAc(62),
            ),
            _StudioPlayableGame(
              number: 63,
              gameId: 'orbit_rescue',
              gameClass: StudioGameClass.fun,
              icon: Icons.public_rounded,
              level: orbitRescueSeviye,
              stars: orbitRescueYildiz,
              score: orbitRescuePuani,
              starTarget: OrbitRescueGamePage.totalStars,
              onTap: () => oyunuAc(63),
            ),
            _StudioPlayableGame(
              number: 80,
              gameId: 'drift_league',
              gameClass: StudioGameClass.fun,
              icon: Icons.sports_motorsports_rounded,
              level: driftLeagueSeviye,
              stars: driftLeagueYildiz,
              score: driftLeaguePuani,
              starTarget: DriftLeagueGamePage.totalStars,
              onTap: () => oyunuAc(80),
            ),
            _StudioPlayableGame(
              number: 81,
              gameId: 'table_tennis_rally',
              gameClass: StudioGameClass.fun,
              icon: Icons.sports_tennis_rounded,
              level: tableTennisRallySeviye,
              stars: tableTennisRallyYildiz,
              score: tableTennisRallyPuani,
              starTarget: TableTennisRallyGamePage.totalStars,
              onTap: () => oyunuAc(81),
            ),
            _StudioPlayableGame(
              number: 82,
              gameId: 'penalty_mindgame',
              gameClass: StudioGameClass.fun,
              icon: Icons.sports_soccer_rounded,
              level: penaltyMindgameSeviye,
              stars: penaltyMindgameYildiz,
              score: penaltyMindgamePuani,
              starTarget: PenaltyMindgamePage.totalStars,
              onTap: () => oyunuAc(82),
            ),
            _StudioPlayableGame(
              number: 83,
              gameId: 'air_hockey_arena',
              gameClass: StudioGameClass.fun,
              icon: Icons.sports_hockey_rounded,
              level: airHockeyArenaSeviye,
              stars: airHockeyArenaYildiz,
              score: airHockeyArenaPuani,
              starTarget: AirHockeyArenaPage.totalStars,
              onTap: () => oyunuAc(83),
            ),
            _StudioPlayableGame(
              number: 84,
              gameId: 'relic_run',
              gameClass: StudioGameClass.fun,
              icon: Icons.explore_rounded,
              level: relicRunSeviye,
              stars: relicRunYildiz,
              score: relicRunPuani,
              starTarget: RelicRunGamePage.totalStars,
              onTap: () => oyunuAc(84),
            ),
            _StudioPlayableGame(
              number: 85,
              gameId: 'lighthouse_defense',
              gameClass: StudioGameClass.fun,
              icon: Icons.light_rounded,
              level: lighthouseDefenseSeviye,
              stars: lighthouseDefenseYildiz,
              score: lighthouseDefensePuani,
              starTarget: LighthouseDefenseGamePage.totalStars,
              onTap: () => oyunuAc(85),
            ),
            _StudioPlayableGame(
              number: 86,
              gameId: 'museum_after_hours',
              gameClass: StudioGameClass.fun,
              icon: Icons.museum_rounded,
              level: museumAfterHoursSeviye,
              stars: museumAfterHoursYildiz,
              score: museumAfterHoursPuani,
              starTarget: MuseumAfterHoursPage.totalStars,
              onTap: () => oyunuAc(86),
            ),
            _StudioPlayableGame(
              number: 87,
              gameId: 'deep_current',
              gameClass: StudioGameClass.fun,
              icon: Icons.sailing_rounded,
              level: deepCurrentSeviye,
              stars: deepCurrentYildiz,
              score: deepCurrentPuani,
              starTarget: DeepCurrentGamePage.totalStars,
              onTap: () => oyunuAc(87),
            ),
            _StudioPlayableGame(
              number: 88,
              gameId: 'cafe_shift',
              gameClass: StudioGameClass.fun,
              icon: Icons.local_cafe_rounded,
              level: cafeShiftSeviye,
              stars: cafeShiftYildiz,
              score: cafeShiftPuani,
              starTarget: CafeShiftGamePage.totalStars,
              onTap: () => oyunuAc(88),
            ),
            _StudioPlayableGame(
              number: 89,
              gameId: 'interior_studio',
              gameClass: StudioGameClass.fun,
              icon: Icons.chair_alt_rounded,
              level: interiorStudioSeviye,
              stars: interiorStudioYildiz,
              score: interiorStudioPuani,
              starTarget: InteriorStudioGamePage.totalStars,
              onTap: () => oyunuAc(89),
            ),
            _StudioPlayableGame(
              number: 90,
              gameId: 'tideglass_aquarium',
              gameClass: StudioGameClass.fun,
              icon: Icons.water_rounded,
              level: tideglassAquariumSeviye,
              stars: tideglassAquariumYildiz,
              score: tideglassAquariumPuani,
              starTarget: TideglassAquariumGamePage.totalStars,
              onTap: () => oyunuAc(90),
            ),
            _StudioPlayableGame(
              number: 91,
              gameId: 'pet_rescue_clinic',
              gameClass: StudioGameClass.fun,
              icon: Icons.pets_rounded,
              level: petRescueClinicSeviye,
              stars: petRescueClinicYildiz,
              score: petRescueClinicPuani,
              starTarget: PetRescueClinicGamePage.totalStars,
              onTap: () => oyunuAc(91),
            ),
            _StudioPlayableGame(
              number: 92,
              gameId: 'boardwalk_builder',
              gameClass: StudioGameClass.fun,
              icon: Icons.attractions_rounded,
              level: boardwalkBuilderSeviye,
              stars: boardwalkBuilderYildiz,
              score: boardwalkBuilderPuani,
              starTarget: BoardwalkBuilderGamePage.totalStars,
              onTap: () => oyunuAc(92),
            ),
            _StudioPlayableGame(
              number: 93,
              gameId: 'moonbase_ops',
              gameClass: StudioGameClass.fun,
              icon: Icons.rocket_launch_rounded,
              level: moonbaseOpsSeviye,
              stars: moonbaseOpsYildiz,
              score: moonbaseOpsPuani,
              starTarget: MoonbaseOpsGamePage.totalStars,
              onTap: () => oyunuAc(93),
            ),
            _StudioPlayableGame(
              number: 94,
              gameId: 'museum_curator',
              gameClass: StudioGameClass.fun,
              icon: Icons.museum_rounded,
              level: museumCuratorSeviye,
              stars: museumCuratorYildiz,
              score: museumCuratorPuani,
              starTarget: MuseumCuratorGamePage.totalStars,
              onTap: () => oyunuAc(94),
            ),
            _StudioPlayableGame(
              number: 95,
              gameId: 'festival_producer',
              gameClass: StudioGameClass.fun,
              icon: Icons.festival_rounded,
              level: festivalProducerSeviye,
              stars: festivalProducerYildiz,
              score: festivalProducerPuani,
              starTarget: FestivalProducerGamePage.totalStars,
              onTap: () => oyunuAc(95),
            ),
            _StudioPlayableGame(
              number: 96,
              gameId: 'secret_room_party',
              gameClass: StudioGameClass.fun,
              icon: Icons.visibility_off_rounded,
              level: secretRoomPartySeviye,
              stars: secretRoomPartyYildiz,
              score: secretRoomPartyPuani,
              starTarget: SecretRoomPartyGamePage.totalStars,
              onTap: () => oyunuAc(96),
            ),
            _StudioPlayableGame(
              number: 97,
              gameId: 'dice_bluff_arena',
              gameClass: StudioGameClass.fun,
              icon: Icons.casino_rounded,
              level: diceBluffArenaSeviye,
              stars: diceBluffArenaYildiz,
              score: diceBluffArenaPuani,
              starTarget: DiceBluffArenaGamePage.totalStars,
              onTap: () => oyunuAc(97),
            ),
            _StudioPlayableGame(
              number: 98,
              gameId: 'signal_pair',
              gameClass: StudioGameClass.fun,
              icon: Icons.sensors_rounded,
              level: signalPairSeviye,
              stars: signalPairYildiz,
              score: signalPairPuani,
              starTarget: SignalPairGamePage.totalStars,
              onTap: () => oyunuAc(98),
            ),
            _StudioPlayableGame(
              number: 99,
              gameId: 'deckforge_duel',
              gameClass: StudioGameClass.fun,
              icon: Icons.style_rounded,
              level: deckforgeDuelSeviye,
              stars: deckforgeDuelYildiz,
              score: deckforgeDuelPuani,
              starTarget: DeckforgeDuelGamePage.totalStars,
              onTap: () => oyunuAc(99),
            ),
            _referencePlayableGame(
              number: 123,
              gameId: 'city_atlas',
              gameClass: StudioGameClass.visual,
              icon: Icons.map_outlined,
            ),
            _referencePlayableGame(
              number: 124,
              gameId: 'world_atlas',
              gameClass: StudioGameClass.visual,
              icon: Icons.public_rounded,
            ),
            _referencePlayableGame(
              number: 125,
              gameId: 'katamino_workshop',
              gameClass: StudioGameClass.visual,
              icon: Icons.extension_rounded,
            ),
            _referencePlayableGame(
              number: 126,
              gameId: 'single_stroke',
              gameClass: StudioGameClass.logic,
              icon: Icons.gesture_rounded,
            ),
            _referencePlayableGame(
              number: 127,
              gameId: 'arrow_maze',
              gameClass: StudioGameClass.logic,
              icon: Icons.alt_route_rounded,
            ),
            _referencePlayableGame(
              number: 128,
              gameId: 'bubble_shooter',
              gameClass: StudioGameClass.fun,
              icon: Icons.bubble_chart_rounded,
            ),
            _StudioPlayableGame(
              number: 11,
              gameId: 'reflex',
              gameClass: StudioGameClass.speed,
              icon: Icons.bolt_rounded,
              level: refleksSeviye,
              stars: refleksYildiz,
              score: refleksPuani,
              onTap: () => oyunuAc(11),
            ),
          ]
          .where((game) => StudioGameCatalog.isAvailable(game.gameId))
          .toList(growable: false);
}

class _GameLaunchTarget {
  const _GameLaunchTarget({
    required this.gameId,
    required this.icon,
    required this.accentColor,
    required this.builder,
  });

  final String gameId;
  final IconData icon;
  final Color accentColor;
  final DeferredGameBuilder builder;
}

class _StudioMark extends StatelessWidget {
  const _StudioMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: StudioVisuals.tealSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StudioVisuals.teal.withValues(alpha: 0.22)),
      ),
      child: const Icon(
        Icons.psychology_rounded,
        color: StudioVisuals.teal,
        size: 23,
      ),
    );
  }
}

class _StudioSkillOverview extends StatelessWidget {
  const _StudioSkillOverview({
    required this.logicStars,
    required this.memoryStars,
    required this.speedStars,
  });

  final int logicStars;
  final int memoryStars;
  final int speedStars;

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = context.l10n.isEnglish;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            isEnglish ? 'YOUR SKILL MAP' : 'BECERİ HARİTAN',
            style: const TextStyle(
              color: StudioVisuals.muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _StudioSkillMetric(
                icon: Icons.account_tree_outlined,
                label: isEnglish ? 'Logic' : 'Mantık',
                value: logicStars,
                color: StudioVisuals.teal,
              ),
              const SizedBox(width: 10),
              _StudioSkillMetric(
                icon: Icons.visibility_outlined,
                label: isEnglish ? 'Focus' : 'Dikkat',
                value: memoryStars,
                color: StudioVisuals.amber,
              ),
              const SizedBox(width: 10),
              _StudioSkillMetric(
                icon: Icons.bolt_outlined,
                label: isEnglish ? 'Speed' : 'Hız',
                value: speedStars,
                color: StudioVisuals.ink,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudioSkillMetric extends StatelessWidget {
  const _StudioSkillMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: StudioVisuals.compactRadius,
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 5),
            Text(
              '$value',
              style: const TextStyle(
                color: StudioVisuals.ink,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: StudioVisuals.muted,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudioSectionHeading extends StatelessWidget {
  const _StudioSectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: StudioVisuals.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _StudioPlayableGame {
  const _StudioPlayableGame({
    required this.number,
    required this.gameId,
    required this.gameClass,
    required this.icon,
    required this.level,
    required this.stars,
    required this.score,
    required this.onTap,
    this.starTarget = GameContentPolicy.campaignLevels * 3,
  });

  final int number;
  final String gameId;
  final StudioGameClass gameClass;
  final IconData icon;
  final int level;
  final int stars;
  final int score;
  final VoidCallback onTap;
  final int starTarget;
}

// Retained as a compatibility widget for older saved navigation snapshots.
// ignore: unused_element
class _StudioClassExplorer extends StatelessWidget {
  const _StudioClassExplorer({
    required this.isEnglish,
    required this.games,
    required this.loadGames,
    required this.onOpenGame,
  });

  final bool isEnglish;
  final List<_StudioPlayableGame> games;
  final List<_StudioPlayableGame> Function() loadGames;
  final Future<void> Function(int gameNumber) onOpenGame;

  @override
  Widget build(BuildContext context) {
    final List<_StudioClassInfo> classes = StudioGameClass.values
        .map((StudioGameClass gameClass) {
          final int playableCount = games
              .where((game) => game.gameClass == gameClass)
              .length;
          return _StudioClassInfo(
            gameClass: gameClass,
            icon: gameClass.icon,
            title: gameClass.title(english: isEnglish),
            playableCount: playableCount,
            targetCount: StudioGameCatalog.inClass(gameClass).length,
            color: StudioGameSkin.forClass(gameClass).accent,
          );
        })
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioVisuals.surface,
        borderRadius: StudioVisuals.cardRadius,
        border: Border.all(color: StudioVisuals.line),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints limits) {
          const double gap = 8;
          final double itemWidth = (limits.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: classes
                .asMap()
                .entries
                .map((MapEntry<int, _StudioClassInfo> entry) {
                  final _StudioClassInfo item = entry.value;
                  final bool finalOddItem =
                      classes.length.isOdd && entry.key == classes.length - 1;
                  return SizedBox(
                    width: finalOddItem ? limits.maxWidth : itemWidth,
                    child: _StudioClassTile(
                      item: item,
                      gameLabel: isEnglish ? 'games' : 'oyun',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => _StudioClassGamesPage(
                            gameClass: item.gameClass,
                            isEnglish: isEnglish,
                            loadGames: loadGames,
                            onOpenGame: onOpenGame,
                          ),
                          settings: RouteSettings(
                            name: '/catalog/${item.gameClass.name}',
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
    );
  }
}

class _StudioGardenScoreAction extends StatelessWidget {
  const _StudioGardenScoreAction({
    required this.score,
    required this.avatar,
    required this.onProfileTap,
  });

  final int score;
  final String avatar;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: StudioVisuals.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: StudioVisuals.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.stars_rounded,
                  size: 15,
                  color: StudioVisuals.amber,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 38),
                  child: Text(
                    '$score',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Semantics(
            button: true,
            label: context.l10n.profile,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                key: const ValueKey<String>('studio_garden_profile_action'),
                onTap: onProfileTap,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: StudioVisuals.tealSoft,
                    child: AvatarIcon(avatar, size: 34, borderRadius: 17),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioGardenDailyCard extends StatelessWidget {
  const _StudioGardenDailyCard({required this.data, required this.onTap});

  final DailyChallengeData? data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    final int completed = data?.completedTaskCount ?? 0;
    final int total = data?.tasks.length ?? 3;
    final String progressLabel = english
        ? '$completed of $total today'
        : 'Bugün $completed / $total görev';

    return Semantics(
      button: true,
      label: english ? 'Daily challenge. Tap anywhere to play.' : 'Günlük meydan okuma. Oynamak için kartın herhangi bir yerine dokun.',
      child: Material(
        color: Colors.transparent,
        borderRadius: StudioVisuals.cardRadius,
        child: InkWell(
          key: const ValueKey<String>('studio_garden_daily_card'),
          onTap: onTap,
          borderRadius: StudioVisuals.cardRadius,
          child: Ink(
            height: 222,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  Color(0xFFEAF6F2),
                  Color(0xFFEAF6F2),
                  Color(0xFFE4F2ED),
                ],
              ),
              borderRadius: StudioVisuals.cardRadius,
              border: Border.all(color: const Color(0xFFDCEBE5)),
              boxShadow: StudioVisuals.softShadow,
            ),
            child: ClipRRect(
              borderRadius: StudioVisuals.cardRadius,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    'assets/branding/studio_garden_daily_hero.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    filterQuality: FilterQuality.high,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: <double>[0, 0.40, 0.62, 0.82],
                        colors: <Color>[
                          Color(0xFFF0F8F4),
                          Color(0xEEF0F8F4),
                          Color(0xB8F0F8F4),
                          Color(0x00F0F8F4),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    top: 19,
                    bottom: 18,
                    right: 104,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          english ? 'DAILY CHALLENGE' : 'GÜNLÜK MEYDAN OKUMA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudioVisuals.teal,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          english
                              ? 'What will you challenge today?'
                              : 'Bugün neye meydan okuyacaksın?',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudioVisuals.ink,
                            fontSize: 20,
                            height: 1.06,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progressLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudioVisuals.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: StudioVisuals.teal,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x24259C89),
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                english ? 'PLAY NOW' : 'ŞİMDİ OYNA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.35,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudioGardenCategorySection extends StatelessWidget {
  const _StudioGardenCategorySection({
    required this.isEnglish,
    required this.games,
    required this.loadGames,
    required this.onOpenGame,
  });

  final bool isEnglish;
  final List<_StudioPlayableGame> games;
  final List<_StudioPlayableGame> Function() loadGames;
  final Future<void> Function(int gameNumber) onOpenGame;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          isEnglish ? 'Categories' : 'Kategoriler',
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 10),
        ...() {
          final List<StudioGameClass> visibleClasses = StudioGameClass.values
              .where(
                (StudioGameClass gameClass) => games.any(
                  (_StudioPlayableGame game) => game.gameClass == gameClass,
                ),
              )
              .toList(growable: false);
          return <Widget>[
            for (
              int index = 0;
              index < visibleClasses.length;
              index++
            ) ...<Widget>[
              if (index > 0) const SizedBox(height: 10),
              _StudioGardenCategoryCard(
                gameClass: visibleClasses[index],
                index: StudioGameClass.values.indexOf(visibleClasses[index]),
                isEnglish: isEnglish,
                gameCount: games
                    .where(
                      (game) => game.gameClass == visibleClasses[index],
                    )
                    .length,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => _StudioClassGamesPage(
                      gameClass: visibleClasses[index],
                      isEnglish: isEnglish,
                      loadGames: loadGames,
                      onOpenGame: onOpenGame,
                    ),
                    settings: RouteSettings(
                      name: '/catalog/${visibleClasses[index].name}',
                    ),
                  ),
                ),
              ),
            ],
          ];
        }(),
      ],
    );
  }
}

class _StudioGardenCategoryCard extends StatelessWidget {
  const _StudioGardenCategoryCard({
    required this.gameClass,
    required this.index,
    required this.isEnglish,
    required this.gameCount,
    required this.onTap,
  });

  final StudioGameClass gameClass;
  final int index;
  final bool isEnglish;
  final int gameCount;
  final VoidCallback onTap;

  String get _atlasPath => index < 4
      ? 'assets/branding/studio_category_atlas_primary.png'
      : 'assets/branding/studio_category_atlas_secondary.png';

  @override
  Widget build(BuildContext context) {
    final Color accent = StudioGameSkin.forClass(gameClass).accent;
    final String gameWord = gameCount == 1
        ? (isEnglish ? 'game' : 'oyun')
        : (isEnglish ? 'games' : 'oyun');
    final String label = gameClass.title(english: isEnglish);

    return StudioCard(
      key: ValueKey<String>('studio_garden_category_${gameClass.name}'),
      semanticLabel: '$label, $gameCount $gameWord',
      onTap: onTap,
      minHeight: 104,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: _StudioCategoryAtlasArt(
              key: ValueKey<String>(
                'studio_garden_category_art_${gameClass.name}',
              ),
              assetPath: _atlasPath,
              quadrant: index % 4,
              size: 72,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$gameCount $gameWord',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: StudioVisuals.tealSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.chevron_right_rounded,
              color: StudioVisuals.ink,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioCategoryAtlasArt extends StatelessWidget {
  const _StudioCategoryAtlasArt({
    required this.assetPath,
    required this.quadrant,
    required this.size,
    super.key,
  });

  final String assetPath;
  final int quadrant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final int column = quadrant % 2;
    final int row = quadrant ~/ 2;
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment(column == 0 ? -1 : 1, row == 0 ? -1 : 1),
          minWidth: size * 2,
          maxWidth: size * 2,
          minHeight: size * 2,
          maxHeight: size * 2,
          child: Image.asset(
            assetPath,
            width: size * 2,
            height: size * 2,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _StudioClassTile extends StatelessWidget {
  const _StudioClassTile({
    required this.item,
    required this.gameLabel,
    required this.onTap,
  });

  final _StudioClassInfo item;
  final String gameLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String countLabel = gameLabel == 'games' && item.playableCount == 1
        ? 'game'
        : gameLabel;
    final String availabilityLabel = item.playableCount == 0
        ? (gameLabel == 'games'
              ? '${item.targetCount} planned'
              : '${item.targetCount} planlandı')
        : '${item.playableCount} $countLabel · ${item.targetCount}';
    return StudioCard(
      key: ValueKey<String>('studio_class_${item.gameClass.name}'),
      semanticLabel: '${item.title}, $availabilityLabel',
      onTap: onTap,
      minHeight: 88,
      padding: const EdgeInsets.all(12),
      color: item.color.withValues(alpha: 0.07),
      borderRadius: StudioVisuals.compactRadius,
      elevated: false,
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 20, color: item.color),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.ink,
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  availabilityLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudioVisuals.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.arrow_forward_rounded, size: 14, color: item.color),
        ],
      ),
    );
  }
}

class _StudioClassInfo {
  const _StudioClassInfo({
    required this.gameClass,
    required this.icon,
    required this.title,
    required this.playableCount,
    required this.targetCount,
    required this.color,
  });

  final StudioGameClass gameClass;
  final IconData icon;
  final String title;
  final int playableCount;
  final int targetCount;
  final Color color;
}

class _StudioClassGamesPage extends StatefulWidget {
  const _StudioClassGamesPage({
    required this.gameClass,
    required this.isEnglish,
    required this.loadGames,
    required this.onOpenGame,
  });

  final StudioGameClass gameClass;
  final bool isEnglish;
  final List<_StudioPlayableGame> Function() loadGames;
  final Future<void> Function(int gameNumber) onOpenGame;

  @override
  State<_StudioClassGamesPage> createState() => _StudioClassGamesPageState();
}

class _StudioClassGamesPageState extends State<_StudioClassGamesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late List<_StudioPlayableGame> _games;

  @override
  void initState() {
    super.initState();
    _refreshGames();
  }

  void _refreshGames() {
    _games = widget
        .loadGames()
        .where((game) => game.gameClass == widget.gameClass)
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openGame(int gameNumber) async {
    await widget.onOpenGame(gameNumber);
    if (!mounted) return;
    setState(_refreshGames);
  }

  @override
  Widget build(BuildContext context) {
    final StudioGameClass gameClass = widget.gameClass;
    final Color accent = StudioGameSkin.forClass(gameClass).accent;
    final List<GameDefinition> plannedGames = StudioGameCatalog.inClass(
      gameClass,
    ).where((game) => !game.isPlayable).toList(growable: false);
    final String countLabel = widget.isEnglish
        ? '${_games.length} games'
        : '${_games.length} oyun';
    final String plannedLabel = widget.isEnglish
        ? '${plannedGames.length} planned'
        : '${plannedGames.length} planlandı';
    final String normalizedQuery = _query.trim().toLowerCase();
    final List<_StudioPlayableGame> visibleGames = _games
        .where((game) {
          if (normalizedQuery.isEmpty) return true;
          final String title = context.l10n
              .gameTitle(game.gameId)
              .toLowerCase();
          final String description = context.l10n
              .gameDescription(game.gameId)
              .toLowerCase();
          return title.contains(normalizedQuery) ||
              description.contains(normalizedQuery);
        })
        .toList(growable: false);
    final List<GameDefinition> visiblePlannedGames =
        gameClass == StudioGameClass.fun
        ? plannedGames
              .where((GameDefinition game) {
                if (normalizedQuery.isEmpty) return true;
                final String title = game
                    .title(english: widget.isEnglish)
                    .toLowerCase();
                return title.contains(normalizedQuery) ||
                    (widget.isEnglish
                        ? 'coming soon next release'.contains(normalizedQuery)
                        : 'yakında bir sonraki sürüm'.contains(
                            normalizedQuery,
                          ));
              })
              .toList(growable: false)
        : const <GameDefinition>[];

    return Scaffold(
      key: ValueKey<String>('studio_class_catalog_${gameClass.name}'),
      backgroundColor: StudioVisuals.canvas,
      appBar: AppBar(
        backgroundColor: StudioVisuals.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(
          gameClass.title(english: widget.isEnglish),
          style: const TextStyle(
            color: StudioVisuals.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const ValueKey<String>('studio_class_games_list'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: StudioVisuals.surface,
                    borderRadius: StudioVisuals.cardRadius,
                    border: Border.all(color: StudioVisuals.line),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          gameClass.catalogHeaderIcon,
                          color: accent,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              countLabel,
                              style: const TextStyle(
                                color: StudioVisuals.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (plannedGames.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 3),
                              Text(
                                plannedLabel,
                                style: const TextStyle(
                                  color: StudioVisuals.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey<String>('studio_class_game_search'),
                  controller: _searchController,
                  onChanged: (String value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: widget.isEnglish ? 'Search games' : 'Oyun ara',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: widget.isEnglish ? 'Clear' : 'Temizle',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: StudioVisuals.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: StudioVisuals.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: StudioVisuals.line),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (
                  int index = 0;
                  index < visibleGames.length;
                  index++
                ) ...<Widget>[
                  if (index > 0) const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _GameCard(
                      gameId: visibleGames[index].gameId,
                      number: visibleGames[index].number,
                      category: gameClass.title(english: widget.isEnglish),
                      title: context.l10n.gameTitle(visibleGames[index].gameId),
                      description: context.l10n.gameDescription(
                        visibleGames[index].gameId,
                      ),
                      icon: visibleGames[index].icon,
                      color: accent,
                      unlocked: true,
                      level: visibleGames[index].level,
                      onTap: () => _openGame(visibleGames[index].number),
                    ),
                  ),
                ],
                for (
                  int index = 0;
                  index < visiblePlannedGames.length;
                  index++
                ) ...<Widget>[
                  if (visibleGames.isNotEmpty || index > 0)
                    const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _GameCard(
                      cardKey: ValueKey<String>(
                        'v9_upcoming_game_card_${visiblePlannedGames[index].id}',
                      ),
                      gameId: visiblePlannedGames[index].id,
                      number: index + 1,
                      category: gameClass.title(english: widget.isEnglish),
                      title: visiblePlannedGames[index].title(
                        english: widget.isEnglish,
                      ),
                      description: widget.isEnglish
                          ? 'Coming in the next release.'
                          : 'Bir sonraki sürümde.',
                      icon: _plannedGameIcon(visiblePlannedGames[index].id),
                      color: accent,
                      unlocked: false,
                      upcoming: true,
                      level: 0,
                      onTap: null,
                    ),
                  ),
                ],
                if (visibleGames.isEmpty && visiblePlannedGames.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      normalizedQuery.isNotEmpty
                          ? (widget.isEnglish
                                ? 'No games match your search.'
                                : 'Aramanla eşleşen oyun yok.')
                          : (widget.isEnglish
                                ? 'Games in this group are being prepared.'
                                : 'Bu başlıktaki oyunlar hazırlık aşamasında.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: StudioVisuals.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopPanel extends StatelessWidget {
  final PlayerDashboardData? player;
  final int totalScore;

  const _TopPanel({required this.player, required this.totalScore});

  @override
  Widget build(BuildContext context) {
    final PlayerDashboardData? data = player;
    final String name =
        data?.profile.displayName == null ||
            data!.profile.displayName == 'Oyuncu'
        ? context.l10n.player
        : data.profile.displayName;
    final String avatar = data?.profile.avatar ?? '🧠';
    final int level = data?.level ?? 1;
    final int score = data?.zekaScore ?? totalScore;
    final int pointsToNext = data?.xpForNextLevel ?? 0;
    final double progress = pointsToNext <= 0
        ? 1
        : ((data?.xpIntoLevel ?? 0) / pointsToNext).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
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
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StudioVisuals.tealSoft,
                  border: Border.all(
                    color: StudioVisuals.teal.withValues(alpha: 0.24),
                  ),
                ),
                child: AvatarIcon(avatar, size: 58, borderRadius: 29),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$score ${context.l10n.isEnglish ? 'points' : 'puan'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: StudioVisuals.tealSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      '$level',
                      style: const TextStyle(
                        color: StudioVisuals.teal,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      context.l10n.level.toUpperCase(),
                      style: TextStyle(
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
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: StudioVisuals.teal,
              backgroundColor: StudioVisuals.surfaceSoft,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                pointsToNext <= 0
                    ? (context.l10n.isEnglish
                          ? 'MAX LEVEL'
                          : 'EN YÜKSEK SEVİYE')
                    : context.l10n.isEnglish
                    ? 'PROGRESS TO LEVEL ${level + 1}'
                    : 'SEVİYE ${level + 1} İLERLEMESİ',
                style: TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                pointsToNext <= 0
                    ? (context.l10n.isEnglish ? 'MAX' : 'SON')
                    : '${data?.xpIntoLevel ?? 0}/$pointsToNext',
                style: const TextStyle(
                  color: StudioVisuals.ink,
                  fontSize: 10,
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

class _DailyPanel extends StatelessWidget {
  final DailyChallengeData? data;
  final VoidCallback onTap;

  const _DailyPanel({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final DailyChallengeData? daily = data;
    final int streak = daily?.currentStreak ?? 0;
    final int completed = daily?.completedTaskCount ?? 0;
    final bool activeToday = daily?.activeToday ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: StudioVisuals.cardRadius,
        child: Ink(
          height: 124,
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
          decoration: BoxDecoration(
            color: StudioVisuals.surface,
            borderRadius: StudioVisuals.cardRadius,
            border: Border.all(color: StudioVisuals.line),
            boxShadow: StudioVisuals.softShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: StudioVisuals.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.isEnglish
                              ? 'TODAY\'S SESSION'
                              : 'BUGÜNÜN OTURUMU',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudioVisuals.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      streak > 0
                          ? context.l10n.streakTitle(streak)
                          : context.l10n.dailyCourse,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudioVisuals.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.dailySummary(completed),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: activeToday
                            ? StudioVisuals.tealSoft
                            : StudioVisuals.amberSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$completed/3 · ${activeToday ? (context.l10n.isEnglish ? 'done' : 'tamam') : (context.l10n.isEnglish ? 'start' : 'başla')}',
                        style: const TextStyle(
                          color: StudioVisuals.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 106,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    Positioned.fill(
                      child: Image.asset(
                        'assets/branding/studio_daily_puzzle_hero.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.centerRight,
                      ),
                    ),
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: StudioVisuals.ink,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeRecommendationPresentation {
  const _HomeRecommendationPresentation({
    required this.gameId,
    required this.number,
    required this.icon,
    required this.color,
    required this.reason,
  });

  final String gameId;
  final int number;
  final IconData icon;
  final Color color;
  final String reason;
}

class _HomeArenaCard extends StatelessWidget {
  const _HomeArenaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: StudioVisuals.cardRadius,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: StudioVisuals.surface,
          borderRadius: StudioVisuals.cardRadius,
          border: Border.all(color: StudioVisuals.line),
          boxShadow: StudioVisuals.softShadow,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: StudioGameClass.strategy.accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/branding/studio_parkur_group_arena.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.l10n.isEnglish
                        ? 'CHALLENGE YOUR FRIENDS'
                        : 'ARKADAŞLARINA MEYDAN OKU',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudioVisuals.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      height: 1.08,
                      letterSpacing: .15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.isEnglish
                        ? 'Duel or team up in a group race.'
                        : 'Düello yap veya grup yarışına katıl.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: StudioVisuals.teal,
              size: 25,
            ),
          ],
        ),
      ),
    ),
  );
}

class _PersonalRecommendationCard extends StatelessWidget {
  const _PersonalRecommendationCard({
    required this.recommendation,
    required this.title,
    required this.onTap,
  });

  final _HomeRecommendationPresentation recommendation;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = context.l10n.isEnglish;
    return RepaintBoundary(
      key: const ValueKey<String>('v9_personal_recommendation'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: StudioVisuals.cardRadius,
          child: Ink(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: StudioVisuals.surface,
              borderRadius: StudioVisuals.cardRadius,
              border: Border.all(color: StudioVisuals.line),
              boxShadow: StudioVisuals.softShadow,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: recommendation.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: StudioGameArtwork(gameId: recommendation.gameId),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isEnglish ? 'YOUR NEXT COURSE' : 'SIRADAKİ PARKURUN',
                        style: TextStyle(
                          color: StudioVisuals.teal,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: StudioVisuals.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        recommendation.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: StudioVisuals.muted,
                          fontSize: 10,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: StudioVisuals.teal,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _plannedGameIcon(String gameId) => switch (gameId) {
  'tiny_chef_dash' => Icons.restaurant_rounded,
  'treasure_trail' => Icons.explore_rounded,
  'jungle_jump' => Icons.forest_rounded,
  'comet_courier' => Icons.rocket_launch_rounded,
  'color_carnival' => Icons.celebration_rounded,
  _ => Icons.extension_rounded,
};

class _GameCard extends StatelessWidget {
  final String gameId;
  final int number;
  final String category;
  final String title;
  final String description;

  final IconData icon;
  final Color color;

  final bool unlocked;

  final int level;
  final bool upcoming;
  final Key? cardKey;

  final VoidCallback? onTap;

  const _GameCard({
    required this.gameId,
    required this.number,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
    required this.level,
    required this.onTap,
    this.upcoming = false,
    this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    // Category pages use the authored game palette so neighbouring cards never
    // collapse into one class colour. The launcher/home surface is untouched.
    final Color cardAccent = upcoming
        ? color
        : GameVisualDesign.forGame(gameId).accent;
    final String? upcomingStatus = upcoming
        ? (context.l10n.isEnglish
              ? 'COMING SOON · NEXT RELEASE'
              : 'YAKINDA · BİR SONRAKİ SÜRÜM')
        : null;
    final String? upcomingSemanticLabel = upcoming
        ? (context.l10n.isEnglish
              ? '$title, coming in the next release'
              : '$title, bir sonraki sürümde')
        : null;

    return RepaintBoundary(
      key: cardKey ?? ValueKey<String>('v9_game_card_$number'),
      child: StudioGameCard(
        accent: cardAccent,
        onTap: upcoming ? null : onTap,
        semanticLabel: upcomingSemanticLabel,
        disabled: !unlocked && !upcoming,
        minHeight: 112,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: MediaQuery.sizeOf(context).width < 360 ? 72 : 84,
              height: 78,
              decoration: StudioGameVisuals.artworkDecoration(
                accent: cardAccent,
                disabled: !unlocked && !upcoming,
              ),
              child: upcoming
                  ? Icon(icon, color: color, size: 31)
                  : StudioGameArtwork(gameId: gameId, locked: !unlocked),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: unlocked || upcoming
                              ? cardAccent.withValues(alpha: 0.15)
                              : StudioVisuals.surfaceSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$number',
                          style: TextStyle(
                            color: unlocked || upcoming
                                ? cardAccent
                                : StudioVisuals.muted,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              category.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unlocked || upcoming
                                    ? cardAccent
                                    : StudioVisuals.muted,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.45,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                height: 1.15,
                                color: unlocked || upcoming
                                    ? StudioVisuals.ink
                                    : StudioVisuals.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unlocked || upcoming
                          ? StudioVisuals.muted
                          : StudioVisuals.muted.withValues(alpha: 0.55),
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 3),

                  if (unlocked)
                    Text(
                      context.l10n.levelValue(level),
                      style: TextStyle(
                        color: cardAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  else if (upcoming)
                    Text(
                      upcomingStatus!,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.25,
                      ),
                    )
                  else
                    Text(
                      context.l10n.comingSoon,
                      style: TextStyle(
                        color: StudioVisuals.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
