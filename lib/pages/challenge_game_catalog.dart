import '../games/shared/studio_game_contracts.dart';

import 'package:flutter/material.dart';

import '../features/catalog/domain/studio_game_catalog.dart';
import '../theme/app_visual_theme.dart';

import '../games/balance_scale/balance_scale_game_page.dart';
import '../games/blocks/block_game_page.dart';
import '../games/candy_sort/candy_sort_game_page.dart';
import '../games/chess_mate/chess_mate_game_page.dart';
import '../games/detective_notes/detective_notes_game_page.dart';
import '../games/arrow_route/arrow_game_page.dart';
import '../games/futoshiki/futoshiki_game_page.dart';
import '../games/hanoi/hanoi_game_page.dart';
import '../games/hidden_masses/hidden_masses_game_page.dart';
import '../games/hitori/hitori_game_page.dart';
import '../games/island_sea/island_sea_game_page.dart';
import '../games/kakuro/kakuro_game_page.dart';
import '../games/kenken_cube/kenken_cube_game_page.dart';
import '../games/logic/logic_game_page.dart';
import '../games/memory/memory_game_page.dart';
import '../games/mini_sudoku/mini_sudoku_game_page.dart';
import '../games/number_sort/number_sort_game_page.dart';
import '../games/numbers/number_game_page.dart';
import '../games/parking_puzzle/parking_puzzle_game_page.dart';
import '../games/picross_master/picross_game_page.dart';
import '../games/picture_iq/picture_iq_game_page.dart';
import '../games/reflex/reflex_game_page.dart';
import '../games/reversi_arena/reversi_game_page.dart';
import '../games/shape_puzzle/shape_puzzle_game_page.dart';
import '../games/skyscrapers/skyscrapers_game_page.dart';
import '../games/slide_sweets/slide_sweets_game_page.dart';
import '../games/target_24/target_24_game_page.dart';
import '../games/word_hunt/word_hunt_game_page.dart';
import '../games/word_wheel/word_wheel_game_page.dart';
import '../games/meaning_match/meaning_match_game_page.dart';
import '../games/proverb_finish/proverb_finish_game_page.dart';
import '../games/sentence_builder/sentence_builder_game_page.dart';
import '../games/near_meaning/near_meaning_game_page.dart';
import '../games/letter_maze/letter_maze_game_page.dart';
import '../games/language_detective/language_detective_game_page.dart';
import '../games/card_pairs/card_pairs_game_page.dart';
import '../games/focus_filter/focus_filter_game_page.dart';
import '../games/spot_change/spot_change_game_page.dart';
import '../games/rhythm_memory/rhythm_memory_game_page.dart';
import '../games/attention_tunnel/attention_tunnel_game_page.dart';
import '../games/story_order/story_order_game_page.dart';
import '../games/reference_games/arrow_maze_game_page.dart';
import '../games/reference_games/atlas_find_game_page.dart';
import '../games/reference_games/atlas_puzzle.dart';
import '../games/reference_games/katamino_game_page.dart';
import '../games/reference_games/single_stroke_game_page.dart';

class ChallengeGameDefinition {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const ChallengeGameDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<ChallengeGameDefinition> challengeGameDefinitions =
    <ChallengeGameDefinition>[
      ChallengeGameDefinition(
        id: 'logic',
        name: 'Mantık',
        icon: Icons.account_tree_outlined,
        color: Color(0xFF665AA2),
      ),
      ChallengeGameDefinition(
        id: 'numbers',
        name: 'Sayı Arenası',
        icon: Icons.calculate_rounded,
        color: Color(0xFFFFC52C),
      ),
      ChallengeGameDefinition(
        id: 'blocks',
        name: 'Blok Plus',
        icon: Icons.grid_view_rounded,
        color: Color(0xFF168CFF),
      ),
      ChallengeGameDefinition(
        id: 'memory',
        name: 'Hafıza',
        icon: Icons.psychology_rounded,
        color: Color(0xFFE748CF),
      ),
      ChallengeGameDefinition(
        id: 'card_pairs',
        name: 'Kart Çifti',
        icon: Icons.style_rounded,
        color: Color(0xFFE748CF),
      ),
      ChallengeGameDefinition(
        id: 'focus_filter',
        name: 'Odak Filtresi',
        icon: Icons.filter_center_focus_rounded,
        color: Color(0xFFD96767),
      ),
      ChallengeGameDefinition(
        id: 'rhythm_memory',
        name: 'Ritim Hafızası',
        icon: Icons.graphic_eq_rounded,
        color: Color(0xFF8974C9),
      ),
      ChallengeGameDefinition(
        id: 'attention_tunnel',
        name: 'Dikkat Tüneli',
        icon: Icons.blur_on_rounded,
        color: Color(0xFF6478C8),
      ),
      ChallengeGameDefinition(
        id: 'reflex',
        name: 'Refleks Avı',
        icon: Icons.bolt_rounded,
        color: Color(0xFFFF5B5B),
      ),
      ChallengeGameDefinition(
        id: 'hanoi',
        name: 'Hanoi',
        icon: Icons.account_tree_rounded,
        color: Color(0xFFFF5A3C),
      ),
      ChallengeGameDefinition(
        id: 'word_hunt',
        name: 'Kelime Avı',
        icon: Icons.travel_explore_rounded,
        color: Color(0xFF00D9A6),
      ),
      ChallengeGameDefinition(
        id: 'meaning_match',
        name: 'Anlam Eşleştir',
        icon: Icons.hub_rounded,
        color: Color(0xFF5B88C8),
      ),
      ChallengeGameDefinition(
        id: 'proverb_finish',
        name: 'Atasözü Tamamla',
        icon: Icons.menu_book_rounded,
        color: Color(0xFF648B72),
      ),
      ChallengeGameDefinition(
        id: 'sentence_builder',
        name: 'Cümle Kur',
        icon: Icons.format_align_left_rounded,
        color: Color(0xFF648B72),
      ),
      ChallengeGameDefinition(
        id: 'near_meaning',
        name: 'Yakın Anlam',
        icon: Icons.manage_search_rounded,
        color: Color(0xFF648B72),
      ),
      ChallengeGameDefinition(
        id: 'letter_maze',
        name: 'Harf Labirenti',
        icon: Icons.route_rounded,
        color: Color(0xFF648B72),
      ),
      ChallengeGameDefinition(
        id: 'language_detective',
        name: 'Dil Dedektifi',
        icon: Icons.manage_search_rounded,
        color: Color(0xFF648B72),
      ),
      ChallengeGameDefinition(
        id: 'story_order',
        name: 'Hikâye Sırası',
        icon: Icons.timeline_rounded,
        color: Color(0xFF5B88C8),
      ),
      ChallengeGameDefinition(
        id: 'picture_iq',
        name: 'Görsel IQ',
        icon: Icons.auto_awesome_mosaic_rounded,
        color: Color(0xFFFF4FA3),
      ),
      ChallengeGameDefinition(
        id: 'number_sort',
        name: '15 Taş Ustası',
        icon: Icons.grid_4x4_rounded,
        color: Color(0xFFB98548),
      ),
      ChallengeGameDefinition(
        id: 'shape_puzzle',
        name: 'Şekil Birleştir',
        icon: Icons.interests_rounded,
        color: Color(0xFF8C6CFF),
      ),
    ];

ChallengeGameDefinition challengeGameDefinition(String gameId) {
  for (final ChallengeGameDefinition definition in challengeGameDefinitions) {
    if (definition.id == gameId) return definition;
  }

  final GameDefinition? catalog = StudioGameCatalog.byId(gameId);
  return ChallengeGameDefinition(
    id: gameId,
    name: catalog?.titleTr ?? 'Meydan Okuma',
    icon: catalog?.gameClass.icon ?? Icons.sports_esports_rounded,
    color: catalog?.gameClass.accent ?? const Color(0xFF7655FF),
  );
}

String challengeDifficultyLabel(int level) =>
    GameContentPolicy.difficulty(level);

Widget buildChallengeCompetitionPage({
  required String gameId,
  required int level,
  required int layoutCode,
}) {
  switch (gameId) {
    case 'logic':
      return LogicGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'numbers':
      return NumberGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'blocks':
      return BlockGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'memory':
      return MemoryGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'card_pairs':
      return CardPairsGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'focus_filter':
      return FocusFilterGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'spot_change':
      return SpotChangeGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'rhythm_memory':
      return RhythmMemoryGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'attention_tunnel':
      return AttentionTunnelGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'reflex':
      return ReflexGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'hanoi':
      return HanoiGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'word_hunt':
      return WordHuntGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'meaning_match':
      return MeaningMatchGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'proverb_finish':
      return ProverbFinishGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'sentence_builder':
      return SentenceBuilderGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'near_meaning':
      return NearMeaningGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'letter_maze':
      return LetterMazeGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'language_detective':
      return LanguageDetectiveGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'story_order':
      return StoryOrderGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'picture_iq':
      return PictureIqGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'candy_sort':
      return CandySortGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'number_sort':
      return NumberSortGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'shape_puzzle':
      return ShapePuzzleGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    case 'detective_notes':
      return DetectiveNotesGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'balance_scale':
      return BalanceScaleGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'target_24':
      return Target24GamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'mini_sudoku':
      return MiniSudokuGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'kenken_cube':
      return KenKenCubeGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'hidden_masses':
      return HiddenMassesGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'kakuro':
      return KakuroGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'parking_puzzle':
      return ParkingPuzzleGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'mini_chess_tactics':
      return ChessMateGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'word_wheel':
      return WordWheelGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'slide_sweets':
      return SlideSweetsGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'reversi_arena':
      return ReversiGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'picross_master':
      return PicrossGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'arrow_route':
      return ArrowRouteGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'island_sea':
      return IslandSeaGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'futoshiki':
      return FutoshikiGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'skyscrapers':
      return SkyscrapersGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'hitori':
      return HitoriGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'city_atlas':
      return AtlasFindGamePage(
        kind: AtlasKind.turkey,
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'world_atlas':
      return AtlasFindGamePage(
        kind: AtlasKind.world,
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'katamino_workshop':
      return KataminoGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'single_stroke':
      return SingleStrokeGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );
    case 'arrow_maze':
      return ArrowMazeGamePage(
        dailyCourseMode: true,
        competitionLevel: level,
        competitionLayoutCode: layoutCode,
      );

    default:
      return const Scaffold(
        backgroundColor: Color(0xFF07162E),
        body: Center(
          child: Text(
            'Meydan okuma oyunu bulunamadı.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
  }
}

Future<String?> showChallengeGamePicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF0B1D3B),
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext sheetContext) {
      return const FractionallySizedBox(
        heightFactor: 0.86,
        child: _ChallengeGamePickerSheet(),
      );
    },
  );
}

class _ChallengeGamePickerSheet extends StatelessWidget {
  const _ChallengeGamePickerSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      child: Column(
        children: <Widget>[
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'MEYDAN OKUMA OYUNU',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Oyunu sen seç • Zorluğu sistem belirlesin • aynı içerikte yarışın',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.builder(
              itemCount: challengeGameDefinitions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (BuildContext context, int index) {
                final ChallengeGameDefinition definition =
                    challengeGameDefinitions[index];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context, definition.id),
                    child: Ink(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: ZpVisualPalette.of(context).surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: definition.color.withValues(alpha: 0.55),
                          width: 1.3,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: definition.color.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: definition.color.withValues(alpha: 0.55),
                              ),
                            ),
                            child: Icon(
                              definition.icon,
                              color: definition.color,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              definition.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'EŞİT BÖLÜM • EŞİT OYUN DÜZENİ',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
