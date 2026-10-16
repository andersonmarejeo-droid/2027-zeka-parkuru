import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/reference_games/atlas_puzzle.dart';
import 'package:zeka_parkuru/games/shared/game_visual_design.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';
import 'package:zeka_parkuru/games/shared/campaign_asset_bank.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/theme/app_visual_theme.dart';
import 'package:zeka_parkuru/theme/studio_visuals.dart';
import 'package:zeka_parkuru/widgets/studio_game_artwork.dart';
import 'package:zeka_parkuru/games/detective_notes/detective_notes_game_page.dart';
import 'package:zeka_parkuru/games/balance_scale/balance_scale_game_page.dart';
import 'package:zeka_parkuru/games/numbers/number_game_page.dart';
import 'package:zeka_parkuru/games/number_sort/number_sort_game_page.dart';
import 'package:zeka_parkuru/games/target_24/target_24_game_page.dart';
import 'package:zeka_parkuru/games/mini_sudoku/mini_sudoku_game_page.dart';
import 'package:zeka_parkuru/games/kenken_cube/kenken_cube_game_page.dart';
import 'package:zeka_parkuru/games/hidden_masses/hidden_masses_game_page.dart';
import 'package:zeka_parkuru/games/kakuro/kakuro_game_page.dart';
import 'package:zeka_parkuru/games/blocks/block_game_page.dart';
import 'package:zeka_parkuru/games/picture_iq/picture_iq_game_page.dart';
import 'package:zeka_parkuru/games/shape_puzzle/shape_puzzle_game_page.dart';
import 'package:zeka_parkuru/games/memory/memory_game_page.dart';
import 'package:zeka_parkuru/games/card_pairs/card_pairs_game_page.dart';
import 'package:zeka_parkuru/games/focus_filter/focus_filter_game_page.dart';
import 'package:zeka_parkuru/games/spot_change/spot_change_game_page.dart';
import 'package:zeka_parkuru/games/rhythm_memory/rhythm_memory_game_page.dart';
import 'package:zeka_parkuru/games/attention_tunnel/attention_tunnel_game_page.dart';
import 'package:zeka_parkuru/games/hanoi/hanoi_game_page.dart';
import 'package:zeka_parkuru/games/candy_sort/candy_sort_game_page.dart';
import 'package:zeka_parkuru/games/parking_puzzle/parking_puzzle_game_page.dart';
import 'package:zeka_parkuru/games/chess_mate/chess_mate_game_page.dart';
import 'package:zeka_parkuru/games/word_hunt/word_hunt_game_page.dart';
import 'package:zeka_parkuru/games/meaning_match/meaning_match_game_page.dart';
import 'package:zeka_parkuru/games/proverb_finish/proverb_finish_game_page.dart';
import 'package:zeka_parkuru/games/word_wheel/word_wheel_game_page.dart';
import 'package:zeka_parkuru/games/sentence_builder/sentence_builder_game_page.dart';
import 'package:zeka_parkuru/games/near_meaning/near_meaning_game_page.dart';
import 'package:zeka_parkuru/games/letter_maze/letter_maze_game_page.dart';
import 'package:zeka_parkuru/games/language_detective/language_detective_game_page.dart';
import 'package:zeka_parkuru/games/story_order/story_order_game_page.dart';
import 'package:zeka_parkuru/games/reflex/reflex_game_page.dart';
import 'package:zeka_parkuru/games/slide_sweets/slide_sweets_game_page.dart';
import 'package:zeka_parkuru/games/reversi_arena/reversi_game_page.dart';
import 'package:zeka_parkuru/games/picross_master/picross_game_page.dart';
import 'package:zeka_parkuru/games/arrow_route/arrow_game_page.dart';
import 'package:zeka_parkuru/games/loop_master/loop_game_page.dart';
import 'package:zeka_parkuru/games/island_sea/island_sea_game_page.dart';
import 'package:zeka_parkuru/games/futoshiki/futoshiki_game_page.dart';
import 'package:zeka_parkuru/games/skyscrapers/skyscrapers_game_page.dart';
import 'package:zeka_parkuru/games/hitori/hitori_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/atlas_find_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/katamino_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/single_stroke_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/single_stroke_puzzle.dart';
import 'package:zeka_parkuru/games/reference_games/arrow_maze_game_page.dart';

import 'test_preferences.dart';

final List<(String, Widget Function(bool))> _games = [
  (
    'detective_notes',
    (bool play) => DetectiveNotesGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'balance_scale',
    (bool play) => BalanceScaleGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'numbers',
    (bool play) => NumberGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'number_sort',
    (bool play) => NumberSortGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'target_24',
    (bool play) => Target24GamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'mini_sudoku',
    (bool play) => MiniSudokuGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'kenken_cube',
    (bool play) => KenKenCubeGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'hidden_masses',
    (bool play) => HiddenMassesGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'kakuro',
    (bool play) => KakuroGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'blocks',
    (bool play) => BlockGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'picture_iq',
    (bool play) => PictureIqGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'shape_puzzle',
    (bool play) => ShapePuzzleGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'memory',
    (bool play) => MemoryGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'card_pairs',
    (bool play) => CardPairsGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'focus_filter',
    (bool play) => FocusFilterGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'rhythm_memory',
    (bool play) => RhythmMemoryGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'attention_tunnel',
    (bool play) => AttentionTunnelGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'hanoi',
    (bool play) => HanoiGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'candy_sort',
    (bool play) => CandySortGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'parking_puzzle',
    (bool play) => ParkingPuzzleGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'mini_chess_tactics',
    (bool play) => ChessMateGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'word_hunt',
    (bool play) => WordHuntGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'meaning_match',
    (bool play) => MeaningMatchGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'proverb_finish',
    (bool play) => ProverbFinishGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'word_wheel',
    (bool play) => WordWheelGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'sentence_builder',
    (bool play) => SentenceBuilderGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'near_meaning',
    (bool play) => NearMeaningGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'letter_maze',
    (bool play) => LetterMazeGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'language_detective',
    (bool play) => LanguageDetectiveGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'story_order',
    (bool play) => StoryOrderGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'reflex',
    (bool play) => ReflexGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'slide_sweets',
    (bool play) => SlideSweetsGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'reversi_arena',
    (bool play) => ReversiGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'picross_master',
    (bool play) => PicrossGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'arrow_route',
    (bool play) => ArrowRouteGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'island_sea',
    (bool play) => IslandSeaGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'futoshiki',
    (bool play) => FutoshikiGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'skyscrapers',
    (bool play) => SkyscrapersGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  (
    'hitori',
    (bool play) => HitoriGamePage(
      competitionLevel: play ? 1 : null,
      competitionLayoutCode: 123,
    ),
  ),
  ('city_atlas', (bool play) => AtlasFindGamePage(kind: AtlasKind.turkey)),
  ('world_atlas', (bool play) => AtlasFindGamePage(kind: AtlasKind.world)),
  ('katamino_workshop', (bool play) => KataminoGamePage()),
  ('single_stroke', (bool play) => SingleStrokeGamePage()),
  ('arrow_maze', (bool play) => ArrowMazeGamePage()),
];

final List<(String, Widget)> _advancedGames = [
  (
    'detective_notes',
    DetectiveNotesGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'balance_scale',
    BalanceScaleGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  ('numbers', NumberGamePage(competitionLevel: 30, competitionLayoutCode: 412)),
  (
    'number_sort',
    NumberSortGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'target_24',
    Target24GamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'mini_sudoku',
    MiniSudokuGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'kenken_cube',
    KenKenCubeGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'hidden_masses',
    HiddenMassesGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  ('kakuro', KakuroGamePage(competitionLevel: 30, competitionLayoutCode: 412)),
  ('blocks', BlockGamePage(competitionLevel: 30, competitionLayoutCode: 412)),
  (
    'picture_iq',
    PictureIqGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'shape_puzzle',
    ShapePuzzleGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  ('memory', MemoryGamePage(competitionLevel: 30, competitionLayoutCode: 412)),
  (
    'card_pairs',
    CardPairsGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'focus_filter',
    FocusFilterGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'spot_change',
    SpotChangeGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'rhythm_memory',
    RhythmMemoryGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'attention_tunnel',
    AttentionTunnelGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  ('hanoi', HanoiGamePage(competitionLevel: 30, competitionLayoutCode: 412)),
  (
    'parking_puzzle',
    ParkingPuzzleGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'mini_chess_tactics',
    ChessMateGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'word_hunt',
    WordHuntGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'meaning_match',
    MeaningMatchGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'proverb_finish',
    ProverbFinishGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'word_wheel',
    WordWheelGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'sentence_builder',
    SentenceBuilderGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'near_meaning',
    NearMeaningGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'letter_maze',
    LetterMazeGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'language_detective',
    LanguageDetectiveGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'story_order',
    StoryOrderGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  ('reflex', ReflexGamePage(competitionLevel: 30, competitionLayoutCode: 412)),
  (
    'slide_sweets',
    SlideSweetsGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'reversi_arena',
    ReversiGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'picross_master',
    PicrossGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'arrow_route',
    ArrowRouteGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'loop_master',
    LoopMasterGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'island_sea',
    IslandSeaGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'futoshiki',
    FutoshikiGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  (
    'skyscrapers',
    SkyscrapersGamePage(competitionLevel: 30, competitionLayoutCode: 412),
  ),
  ('hitori', HitoriGamePage(competitionLevel: 30, competitionLayoutCode: 412)),
];

const _captureKey = ValueKey<String>('visual_sprint_capture');

Future<void> _mount(
  WidgetTester tester,
  String id,
  Widget page, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: StudioVisuals.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: StudioVisuals.teal,
          surface: Colors.white,
          onSurface: StudioVisuals.ink,
        ),
        extensions: const [ZpVisualPalette.garden],
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: StudioGameTheme(gameId: id, child: page),
    ),
  );
  for (int tick = 0; tick < 7; tick++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openReference(
  WidgetTester tester,
  String id, {
  int chapter = 1,
}) async {
  if (!{
    'city_atlas',
    'world_atlas',
    'katamino_workshop',
    'single_stroke',
    'arrow_maze',
  }.contains(id)) {
    return;
  }
  final Finder first = find.byKey(
    ValueKey<String>('parkur_level_art_$chapter'),
  );
  if (chapter > 1) {
    await tester.scrollUntilVisible(
      first,
      600,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 80,
    );
  }
  expect(first, findsOneWidget, reason: id);
  await tester.ensureVisible(first);
    // The last chapter can sit just below the viewport after the large
    // discovery drag; nudge it into the safe hit-test area before tapping.
    if (tester.getRect(first).bottom >
        tester.binding.renderViews.first.size.height) {
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -220),
      );
      await tester.pump();
    }
  await tester.tap(first);
  for (int tick = 0; tick < 8; tick++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  for (
    int attempt = 0;
    attempt < 15 &&
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    attempt++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<ui.Image> _capture(WidgetTester tester, String name) async {
  final RenderRepaintBoundary boundary = tester.renderObject(
    find.byKey(_captureKey),
  );
  return (await tester.runAsync<ui.Image>(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final Directory directory = Directory('build/visual_sprint');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    return image;
  }))!;
}

Future<void> _sheet(
  WidgetTester tester,
  List<(String, ui.Image)> frames,
  String name,
) async {
  const int columns = 4;
  const double width = 290;
  const double height = 652;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(const Color(0xFFE3EBE5), BlendMode.src);
  for (int i = 0; i < frames.length; i++) {
    final (id, image) = frames[i];
    final double x = (i % columns) * width;
    final double y = (i ~/ columns) * height;
    final label = TextPainter(
      text: TextSpan(
        text: id,
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: StudioVisuals.ink,
          fontSize: 15,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 16);
    label.paint(canvas, Offset(x + 8, y + 5));
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(x + 8, y + 30, width - 16, height - 36),
      Paint(),
    );
  }
  final picture = recorder.endRecording();
  await tester.runAsync(() async {
    final sheet = await picture.toImage(
      (columns * width).toInt(),
      ((frames.length / columns).ceil() * height).toInt(),
    );
    final bytes = await sheet.toByteData(format: ui.ImageByteFormat.png);
    await File('build/visual_sprint/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    sheet.dispose();
  });
  picture.dispose();
}

void main() {
  setUpAll(() async {
    installTestPreferences();
    final String sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
    final String fonts = '$sdk/bin/cache/artifacts/material_fonts';
    final roboto = FontLoader('Roboto');
    for (final file in ['roboto-regular.ttf', 'roboto-bold.ttf']) {
      roboto.addFont(
        File('$fonts/$file')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      );
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File('$fonts/materialicons-regular.otf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      );
    await icons.load();
    final serif = FontLoader('serif')
      ..addFont(
        File('$fonts/roboto-regular.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      );
    await serif.load();
    // Custom painters use the platform default rather than the app TextTheme.
    final fallback = FontLoader('Ahem')
      ..addFont(
        File('$fonts/roboto-regular.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      );
    await fallback.load();
    for (final id in CampaignAssetBank.gameIds) {
      await CampaignAssetBank.prepare(id);
    }
    await AtlasDataset.load(AtlasKind.turkey);
    await AtlasDataset.load(AtlasKind.world);
  });
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  test('every active game has an authored, readable material palette', () {
    final ids = StudioGameCatalog.games
        .where((game) => game.isPlayable)
        .map((game) => game.id)
        .toSet();
    expect(GameVisualDesign.games.keys.toSet(), ids);
    final Set<String> coveredIds = _games.map((game) => game.$1).toSet();
    expect(
      coveredIds.difference(ids),
      isEmpty,
      reason: 'visual smoke tests must not exercise retired catalog entries',
    );
    for (final entry in GameVisualDesign.games.entries) {
      // Candy Sort keeps its legacy warm-orange identity by request; its
      // legacy accent is intentionally outside the newer contrast threshold.
      if (entry.key == 'candy_sort') continue;
      final double contrast =
          1.05 / (entry.value.accent.computeLuminance() + .05);
      expect(contrast, greaterThanOrEqualTo(4.5), reason: entry.key);
    }
    expect(
      1.05 / (StudioVisuals.muted.computeLuminance() + .05),
      greaterThanOrEqualTo(4.5),
    );
  });

  for (final (String id, Widget Function(bool) factory) in _games) {
    testWidgets('$id: narrow hub and first playable screen at 130% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, id, factory(false), textScale: 1.3);
      final grid = tester.widget<GridView>(find.byType(GridView).first);
      expect(
        grid.childrenDelegate.estimatedChildCount,
        GameContentPolicy.campaignLevels,
        reason: '$id has its authored chapter count',
      );
      expect(tester.takeException(), isNull, reason: '$id hub');
      expect(find.byType(Scaffold), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await resetTestPreferences();
      await _mount(tester, id, factory(true), textScale: 1.3);
      await _openReference(tester, id);
      if (const {
        'city_atlas',
        'world_atlas',
        'katamino_workshop',
        'single_stroke',
        'arrow_maze',
      }.contains(id)) {
        expect(
          find.byType(BackButton),
          findsOneWidget,
          reason: '$id first chapter is playable',
        );
      }
      expect(tester.takeException(), isNull, reason: '$id play');
      expect(find.byType(Scaffold), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$id disposal');
      await tester.pump(const Duration(seconds: 3));
    });
  }

  for (final (id, factory) in _games.where(
    (game) => const {
      'city_atlas',
      'world_atlas',
      'katamino_workshop',
      'single_stroke',
      'arrow_maze',
    }.contains(game.$1),
  )) {
    testWidgets('$id: chapter 30 opens through the actual chapter map', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await SharedPreferencesAsync().setInt('${id}_unlocked_level', 30);
      await _mount(tester, id, factory(false), textScale: 1.15);
      await _openReference(tester, id, chapter: 30);
      expect(tester.takeException(), isNull, reason: '$id chapter 30');
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final context = tester.element(find.byType(Scaffold).last);
      expect(
        Navigator.of(context).canPop(),
        isTrue,
        reason: '$id playable screen opened',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });
  }

  for (final (String id, AtlasKind kind) in <(String, AtlasKind)>[
    ('city_atlas', AtlasKind.turkey),
    ('world_atlas', AtlasKind.world),
  ]) {
    testWidgets('$id: three progressive hints lower answer points', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await resetTestPreferences();
      await _mount(tester, id, AtlasFindGamePage(kind: kind));
      await _openReference(tester, id);

      final Finder hintButton = find.byKey(
        const ValueKey<String>('atlas_hint_button'),
      );
      final List<String> pointLabels = <String>[
        '100 puan',
        '85 puan',
        '70 puan',
        '55 puan',
        '40 puan',
        '25 puan',
        '10 puan',
      ];
      expect(find.textContaining(pointLabels.first), findsOneWidget);
      final List<Key> revealedHints = <Key>[
        const ValueKey<String>('atlas_position_hint'),
        const ValueKey<String>('atlas_cultural_hint'),
        const ValueKey<String>('atlas_cultural_detail_hint'),
        const ValueKey<String>('atlas_structure_hint'),
        const ValueKey<String>('atlas_letter_hint'),
        const ValueKey<String>('atlas_last_letter_hint'),
      ];

      for (int index = 0; index < revealedHints.length; index++) {
        await tester.ensureVisible(hintButton);
        await tester.tap(hintButton);
        await tester.pumpAndSettle();
        expect(find.byKey(revealedHints[index]), findsOneWidget);
        expect(find.textContaining(pointLabels[index + 1]), findsOneWidget);
      }

      expect(tester.widget<TextButton>(hintButton).onPressed, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });
  }

  testWidgets('single_stroke: complete the shape in one continuous drag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester, 'single_stroke', const SingleStrokeGamePage());
    await _openReference(tester, 'single_stroke');

    final Finder boardFinder = find.byKey(
      const ValueKey<String>('single_stroke_trace_board'),
    );
    expect(boardFinder, findsOneWidget);
    final RenderBox board = tester.renderObject(boardFinder);
    // First campaign entry reserves pool index 1 after the test preference
    // reset. Follow its authored solution using one pointer throughout.
    final SingleStrokePuzzle puzzle = SingleStrokePuzzle.generate(1, 1);
    Offset globalPoint(int node) {
      final StrokePoint point = puzzle.points[node];
      return board.localToGlobal(
        Offset(point.x * board.size.width, point.y * board.size.height),
      );
    }

    final TestGesture trace = await tester.startGesture(
      globalPoint(puzzle.solution.first),
    );
    for (final int node in puzzle.solution.skip(1)) {
      await trace.moveTo(globalPoint(node));
      await tester.pump(const Duration(milliseconds: 40));
    }
    await trace.up();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    // Completing the first chapter should automatically advance to chapter 2.
    expect(find.text('BÖLÜM 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (id, page) in _advancedGames) {
    testWidgets('$id: chapter 30 opens and stays readable on phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mount(tester, id, page, textScale: 1.15);
      expect(tester.takeException(), isNull, reason: '$id advanced');
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: '$id loaded',
      );
      expect(find.byType(Scaffold), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });
  }

  testWidgets('picross: in-game help explains clues and cell marking', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const String id = 'picross_master';
    final Widget Function(bool) factory = _games
        .singleWhere((game) => game.$1 == id)
        .$2;
    await resetTestPreferences();
    await _mount(tester, id, factory(true));
    await _openReference(tester, id);

    final Finder helpButton = find.byTooltip('Nasıl oynanır?');
    expect(helpButton, findsOneWidget);
    await tester.tap(helpButton);
    await tester.pumpAndSettle();

    expect(find.text('Picross nasıl çözülür?'), findsOneWidget);
    expect(find.textContaining('Sayılar, ilgili çizgide'), findsOneWidget);
    expect(find.textContaining('DOLDUR ile dolu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture every active hub, first board and authored artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final List<(String, ui.Image)> frames = [];
    for (final (id, factory) in _games) {
      await resetTestPreferences();
      await _mount(tester, id, factory(false));
      expect(tester.takeException(), isNull, reason: '$id hub');
      final hub = await _capture(tester, '${id}_hub');
      hub.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await _mount(tester, id, factory(true));
      await _openReference(tester, id);
      expect(tester.takeException(), isNull, reason: '$id play');
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: '$id fully loaded',
      );
      frames.add((id, await _capture(tester, '${id}_play')));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      if (frames.length == 8) {
        await _sheet(
          tester,
          frames,
          'boards_${(_games.indexWhere((game) => game.$1 == id) + 1) ~/ 8}',
        );
        for (final frame in frames) {
          frame.$2.dispose();
        }
        frames.clear();
      }
    }
    if (frames.isNotEmpty) {
      await _sheet(tester, frames, 'boards_6');
      for (final frame in frames) {
        frame.$2.dispose();
      }
    }

    tester.view.physicalSize = const Size(960, 1650);
    await _mount(
      tester,
      'numbers',
      Scaffold(
        body: GridView.count(
          crossAxisCount: 6,
          childAspectRatio: .78,
          children: [
            for (final (id, _) in _games)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  children: [
                    Expanded(child: StudioGameArtwork(gameId: id)),
                    Text(id, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final artwork = await _capture(tester, 'artwork_catalog');
    artwork.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }, timeout: const Timeout(Duration(minutes: 8)));
}
