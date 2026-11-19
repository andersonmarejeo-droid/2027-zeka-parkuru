import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/games/bubble_shooter/bubble_shooter_game_page.dart';
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
import 'package:zeka_parkuru/games/blocks/block_game_page.dart';
import 'package:zeka_parkuru/games/bridge_builder/bridge_builder_game_page.dart';
import 'package:zeka_parkuru/games/balance_scale/balance_scale_game_page.dart';
import 'package:zeka_parkuru/games/candy_sort/candy_sort_game_page.dart';
import 'package:zeka_parkuru/games/flow_connect/flow_connect_game_page.dart';
import 'package:zeka_parkuru/games/gate_sequence/gate_sequence_game_page.dart';
import 'package:zeka_parkuru/games/circuit_repair/circuit_repair_game_page.dart';
import 'package:zeka_parkuru/games/detective_notes/detective_notes_game_page.dart';
import 'package:zeka_parkuru/games/hanoi/hanoi_game_page.dart';
import 'package:zeka_parkuru/games/logic/logic_game_page.dart';
import 'package:zeka_parkuru/games/memory/memory_game_page.dart';
import 'package:zeka_parkuru/games/mini_sudoku/mini_sudoku_game_page.dart';
import 'package:zeka_parkuru/games/kenken_cube/kenken_cube_game_page.dart';
import 'package:zeka_parkuru/games/mahjong_layers/mahjong_layers_game_page.dart';
import 'package:zeka_parkuru/games/mine_detector/mine_detector_game_page.dart';
import 'package:zeka_parkuru/games/warehouse_master/warehouse_master_game_page.dart';
import 'package:zeka_parkuru/games/hidden_masses/hidden_masses_game_page.dart';
import 'package:zeka_parkuru/games/kakuro/kakuro_game_page.dart';
import 'package:zeka_parkuru/games/reversi_arena/reversi_game_page.dart';
import 'package:zeka_parkuru/games/number_sort/number_sort_game_page.dart';
import 'package:zeka_parkuru/games/numbers/number_game_page.dart';
import 'package:zeka_parkuru/games/parking_puzzle/parking_puzzle_game_page.dart';
import 'package:zeka_parkuru/games/picross_master/picross_game_page.dart';
import 'package:zeka_parkuru/games/arrow_route/arrow_game_page.dart';
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
import 'package:zeka_parkuru/games/tavla_master/tavla_game_page.dart';
import 'package:zeka_parkuru/games/pin_unlock/pin_unlock_game_page.dart';
import 'package:zeka_parkuru/games/picture_iq/picture_iq_game_page.dart';
import 'package:zeka_parkuru/games/reflex/reflex_game_page.dart';
import 'package:zeka_parkuru/games/shape_puzzle/shape_puzzle_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/katamino_game_page.dart';
import 'package:zeka_parkuru/games/word_hunt/word_hunt_game_page.dart';
import 'package:zeka_parkuru/games/word_wheel/word_wheel_game_page.dart';
import 'package:zeka_parkuru/games/meaning_match/meaning_match_game_page.dart';
import 'package:zeka_parkuru/games/proverb_finish/proverb_finish_game_page.dart';
import 'package:zeka_parkuru/games/sentence_builder/sentence_builder_game_page.dart';
import 'package:zeka_parkuru/games/near_meaning/near_meaning_game_page.dart';
import 'package:zeka_parkuru/games/letter_maze/letter_maze_game_page.dart';
import 'package:zeka_parkuru/games/language_detective/language_detective_game_page.dart';
import 'package:zeka_parkuru/games/story_order/story_order_game_page.dart';
import 'package:zeka_parkuru/games/card_pairs/card_pairs_game_page.dart';
import 'package:zeka_parkuru/games/focus_filter/focus_filter_game_page.dart';
import 'package:zeka_parkuru/games/spot_change/spot_change_game_page.dart';
import 'package:zeka_parkuru/games/rhythm_memory/rhythm_memory_game_page.dart';
import 'package:zeka_parkuru/games/attention_tunnel/attention_tunnel_game_page.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/target_24/target_24_game_page.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/theme/app_visual_theme.dart';

import 'test_preferences.dart';

const List<(String, Widget)> _gameHubs = <(String, Widget)>[
  ('Mantık Labirenti', LogicGamePage()),
  ('Akış Bağlantısı', FlowConnectGamePage()),
  ('Devre Tamiri', CircuitRepairGamePage()),
  ('Dedektif Notları', DetectiveNotesGamePage()),
  ('Köprü Kur', BridgeBuilderGamePage()),
  ('Masa Tenisi Rallisi', TableTennisRallyGamePage()),
  ('Penaltı Zihin Oyunu', PenaltyMindgamePage()),
  ('Air Hockey Arena', AirHockeyArenaPage()),
  ('Kalıntı Seferi', RelicRunGamePage()),
  ('Fener Savunması', LighthouseDefenseGamePage()),
  ('Müze: Gece Vardiyası', MuseumAfterHoursPage()),
  ('Derin Akıntı', DeepCurrentGamePage()),
  ('Kafe Vardiyası', CafeShiftGamePage()),
  ('İç Mekân Atölyesi', InteriorStudioGamePage()),
  ('Deniz Camı Akvaryumu', TideglassAquariumGamePage()),
  ('Dostlar Kurtarma Kliniği', PetRescueClinicGamePage()),
  ('Sahil Parkı Kurucusu', BoardwalkBuilderGamePage()),
  ('Ay Üssü Operasyonları', MoonbaseOpsGamePage()),
  ('Müze Küratörü', MuseumCuratorGamePage()),
  ('Festival Yapımcısı', FestivalProducerGamePage()),
  ('Gizli Oda: Sosyal Çıkarım', SecretRoomPartyGamePage()),
  ('Zar ve Hançer', DiceBluffArenaGamePage()),
  ('Sinyal Ortağı', SignalPairGamePage()),
  ('Deste Ustası', DeckforgeDuelGamePage()),
  ('Kapı Dizisi', GateSequenceGamePage()),
  ('Park Yeri', ParkingPuzzleGamePage()),
  ('Kilit Aç', PinUnlockGamePage()),
  ('Ağırlık Dengesi', BalanceScaleGamePage()),
  ('Hedef 24', Target24GamePage()),
  ('Su Doku', MiniSudokuGamePage()),
  ('KenKen Küpü', KenKenCubeGamePage()),
  ('Mahjong Katmanları', MahjongLayersGamePage()),
  ('Mayın Dedektifi', MineDetectorGamePage()),
  ('Depo Ustası', WarehouseMasterGamePage()),
  ('Kelime Çarkı', WordWheelGamePage()),
  ('Anlam Eşleştir', MeaningMatchGamePage()),
  ('Atasözü Tamamla', ProverbFinishGamePage()),
  ('Cümle Kur', SentenceBuilderGamePage()),
  ('Yakın Anlam', NearMeaningGamePage()),
  ('Harf Labirenti', LetterMazeGamePage()),
  ('Dil Dedektifi', LanguageDetectiveGamePage()),
  ('Hikâye Sırası', StoryOrderGamePage()),
  ('Kart Çifti', CardPairsGamePage()),
  ('Odak Filtresi', FocusFilterGamePage()),
  ('Değişeni Bul', SpotChangeGamePage()),
  ('Ritim Hafızası', RhythmMemoryGamePage()),
  ('Dikkat Tüneli', AttentionTunnelGamePage()),
  ('Gizli Kütleler', HiddenMassesGamePage()),
  ('Kakuro Izgarası', KakuroGamePage()),
  ('Reversi Arenası', ReversiGamePage()),
  ('Picross Ustası', PicrossGamePage()),
  ('Tavla Ustası', TavlaGamePage()),
  ('Ok Rotası', ArrowRouteGamePage()),
  ('Satranç Matı', ChessMateGamePage()),
  ('Döngü Ustası', LoopMasterGamePage()),
  ('Go Yaşam-Ölüm', GoLifeDeathGamePage()),
  ('Kod Kırıcı', CodeBreakerGamePage()),
  ('Shogi Mat', ShogiMateGamePage()),
  ('Ada ve Deniz', IslandSeaGamePage()),
  ('Tek Taş', PegSolitaireGamePage()),
  ('Futoshiki', FutoshikiGamePage()),
  ('Hex Bağlantısı', HexConnectionGamePage()),
  ('Gökdelenler', SkyscrapersGamePage()),
  ('Hitori', HitoriGamePage()),
  ('Balon Avcısı', BalloonCatcherGamePage()),
  ('Şişe Kırmaca', BottleTargetGamePage()),
  ('Renk Reaktörü', ColorReactorGamePage()),
  ('Top Birleştir', BallMergeGamePage()),
  ('Kule Denge', TowerBalanceGamePage()),
  ('Mıknatıs Rotası', MagnetPathGamePage()),
  ('Mini Golf Rota', MiniGolfGamePage()),
  ('Şeker Konveyörü', SlideSweetsGamePage()),
  ('Halka At', RingTossGamePage()),
  ('Küçük Balıkçı', LittleFisherGamePage()),
  ('Mermer Rota', MarbleRouteGamePage()),
  ('Blok Akışı', BlockFlowGamePage()),
  ('Kâğıt Uçak Şampiyonası', PaperFlightGamePage()),
  ('Neon Pinball', NeonPinballGamePage()),
  ('Uçurtma Pilotu', KiteRunnerGamePage()),
  ('Ritim Atölyesi', RhythmDrumsGamePage()),
  ('Kaykay Akışı', SkateComboGamePage()),
  ('Kar Sörfü Slalomu', SnowboardSlalomGamePage()),
  ('Jetpack Kurye', JetpackCourierGamePage()),
  ('Yörünge Kurtarma', OrbitRescueGamePage()),
  ('Drift Ligi', DriftLeagueGamePage()),
  (
    'Picross oyun tahtası',
    PicrossPlayPage(
      level: ParkurLevelSpec(
        number: 1,
        titleTr: 'Picross 01',
        titleEn: 'Picross 01',
        subtitleTr: 'Silüeti çöz',
        subtitleEn: 'Solve the silhouette',
        difficulty: 'USTALAŞMA',
        icon: Icons.grid_4x4_rounded,
      ),
      previousBestScore: 0,
    ),
  ),
  (
    'Tavla oyun tahtası',
    TavlaPlayPage(
      level: ParkurLevelSpec(
        number: 1,
        titleTr: 'Tavla 01',
        titleEn: 'Backgammon 01',
        subtitleTr: 'Zarı oku ve planla',
        subtitleEn: 'Read and plan the dice',
        difficulty: 'USTALAŞMA',
        icon: Icons.casino_outlined,
      ),
      previousBestScore: 0,
    ),
  ),
  (
    'Reversi oyun tahtası',
    ReversiPlayPage(
      level: ParkurLevelSpec(
        number: 1,
        titleTr: 'Reversi 01',
        titleEn: 'Reversi 01',
        subtitleTr: 'Taşları çevir',
        subtitleEn: 'Flip the discs',
        difficulty: 'USTALAŞMA',
        icon: Icons.change_circle_outlined,
      ),
      previousBestScore: 0,
    ),
  ),
  (
    'Park Yeri oyun tahtası',
    ParkingPuzzlePlayPage(
      level: ParkurLevelSpec(
        number: 1,
        titleTr: 'Parkur 1',
        titleEn: 'Route 1',
        subtitleTr: 'Paket 1 · Aşama 1 / 10',
        subtitleEn: 'Chapter 1 · Stage 1 / 10',
        difficulty: 'PLANLA',
        icon: Icons.directions_car_filled_rounded,
      ),
      previousBestScore: 0,
    ),
  ),
  (
    'Kilit Aç oyun tahtası',
    PinUnlockPlayPage(
      level: ParkurLevelSpec(
        number: 1,
        titleTr: 'Kilit 1',
        titleEn: 'Lock 1',
        subtitleTr: 'Pim kısıtlarını birleştir',
        subtitleEn: 'Combine pin constraints',
        difficulty: 'USTALAŞMA',
        icon: Icons.lock_open_rounded,
      ),
      previousBestScore: 0,
    ),
  ),
  (
    'Ağırlık Dengesi oyun tahtası',
    BalanceScalePlayPage(
      level: ParkurLevelSpec(
        number: 1,
        titleTr: 'Terazi 1',
        titleEn: 'Balance 1',
        subtitleTr: 'Kütleleri ve ipuçlarını eşleştir',
        subtitleEn: 'Match weights and clues',
        difficulty: 'USTALAŞMA',
        icon: Icons.balance_rounded,
      ),
      previousBestScore: 0,
    ),
  ),
  (
    'Kapı Dizisi oyun tahtası',
    GateSequencePlayPage(
      level: ParkurLevelSpec(
        number: 1,
        titleTr: 'Dizi 1',
        titleEn: 'Sequence 1',
        subtitleTr: 'Sırala',
        subtitleEn: 'Order',
        difficulty: 'ÇIRAK',
        icon: Icons.door_front_door_outlined,
      ),
      previousBestScore: 0,
    ),
  ),
  (
    'Köprü Kur oyun tahtası',
    BridgeBuilderPlayPage(
      level: ParkurLevelSpec(
        number: 1,
        titleTr: 'Ada 1',
        titleEn: 'Network 1',
        subtitleTr: 'Bağla',
        subtitleEn: 'Connect',
        difficulty: 'MÜHENDİS ADAYI',
        icon: Icons.account_tree_rounded,
      ),
      previousBestScore: 0,
    ),
  ),
  (
    'Dedektif Notları oyun tahtası',
    DetectiveNotesPlayPage(
      level: ParkurLevelSpec(
        number: 1,
        titleTr: 'Dosya 1',
        titleEn: 'Case 1',
        subtitleTr: 'Çöz',
        subtitleEn: 'Solve',
        difficulty: 'GÖZLEMCİ',
        icon: Icons.manage_search_rounded,
      ),
      previousBestScore: 0,
    ),
  ),
  ('Sayı Ustası', NumberGamePage()),
  ('Blok Atölyesi', BlockGamePage()),
  ('Hafıza Labirenti', MemoryGamePage()),
  ('Hanoi Kulesi', HanoiGamePage()),
  ('Kelime Avı', WordHuntGamePage()),
  ('Görsel IQ', PictureIqGamePage()),
  ('Şeker Sıralama', CandySortGamePage()),
  ('15 Taş Ustası', NumberSortGamePage()),
  ('Baloncuk Arenası', BubbleShooterGamePage()),
  ('Şekil Birleştir', ShapePuzzleGamePage()),
  ('Katamino Atölyesi', KataminoGamePage()),
  ('Refleks Avı', ReflexGamePage()),
];

final ThemeData _studioGardenTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: ZpVisualPalette.garden.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ZpVisualPalette.garden.primary,
    brightness: Brightness.light,
  ),
  extensions: const <ThemeExtension<dynamic>>[ZpVisualPalette.garden],
);

Future<void> _openEveryGame(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;

  for (final (String name, Widget page) in _gameHubs) {
    await resetTestPreferences();

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: _studioGardenTheme,
        home: page,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    final Object? layoutIssue = tester.takeException();
    expect(
      layoutIssue,
      isNull,
      reason: layoutIssue is FlutterError
          ? '$name açılırken Flutter hatası oluştu:\n${layoutIssue.toStringDeep()}'
          : '$name açılırken Flutter hatası oluştu: $layoutIssue',
    );
    expect(find.byType(Scaffold), findsWidgets, reason: name);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('oyun ekranları küçük Android ekranda taşmadan açılır', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _openEveryGame(
      tester,
      size: const Size(320, 600),
      locale: const Locale('tr'),
    );
  });

  testWidgets('oyun ekranları İngilizce tablet boyutunda açılır', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _openEveryGame(
      tester,
      size: const Size(800, 1280),
      locale: const Locale('en'),
    );
  });

  testWidgets('balon atıcısı küçük telefonda ilk görünümde görünür', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: _studioGardenTheme,
        home: BubbleShooterPlayPage(
          level: BubbleShooterGamePage.levels.first,
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    final Finder playField = find.byKey(
      const ValueKey<String>('bubble_shooter_play_field'),
    );
    expect(playField, findsOneWidget);
    expect(
      tester.getRect(playField).bottom,
      lessThanOrEqualTo(600),
      reason: 'Balon atıcısı ilk görünümde ekranda kalmalı.',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Katamino tahta dokunuşunda parçayı otomatik oturtur', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: _studioGardenTheme,
        home: const KataminoGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    final Finder level = find.text('1. Döşeme 01');
    expect(level, findsOneWidget);
    await tester.tap(level);
    await tester.pumpAndSettle();

    final Finder piece = find.byType(LongPressDraggable<int>).first;
    await tester.ensureVisible(piece);
    await tester.tap(piece);
    await tester.pumpAndSettle();

    final Finder board = find.byType(GridView).first;
    await tester.ensureVisible(board);
    final Rect boardBounds = tester.getRect(board);
    await tester.tapAt(boardBounds.bottomRight - const Offset(4, 4));
    await tester.pump();

    expect(find.textContaining('Yerleşen: 4/16'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
