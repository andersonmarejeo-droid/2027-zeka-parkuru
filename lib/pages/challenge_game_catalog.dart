import 'package:flutter/material.dart';

import '../theme/app_visual_theme.dart';

import '../games/blocks/block_game_page.dart';
import '../games/candy_sort/candy_sort_game_page.dart';
import '../games/hanoi/hanoi_game_page.dart';
import '../games/logic/logic_game_page.dart';
import '../games/memory/memory_game_page.dart';
import '../games/number_sort/number_sort_game_page.dart';
import '../games/numbers/number_game_page.dart';
import '../games/picture_iq/picture_iq_game_page.dart';
import '../games/reflex/reflex_game_page.dart';
import '../games/shape_puzzle/shape_puzzle_game_page.dart';
import '../games/word_hunt/word_hunt_game_page.dart';

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
        name: 'Mantık Labirenti',
        icon: Icons.extension_rounded,
        color: Color(0xFF8A4FFF),
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
        id: 'picture_iq',
        name: 'Görsel IQ',
        icon: Icons.auto_awesome_mosaic_rounded,
        color: Color(0xFFFF4FA3),
      ),
      ChallengeGameDefinition(
        id: 'candy_sort',
        name: 'Şeker Sıralama',
        icon: Icons.cookie_rounded,
        color: Color(0xFFFF8A3D),
      ),
      ChallengeGameDefinition(
        id: 'number_sort',
        name: 'Sayı Peteği',
        icon: Icons.hive_rounded,
        color: Color(0xFFFFD334),
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

  return const ChallengeGameDefinition(
    id: 'unknown',
    name: 'Meydan Okuma',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFF7655FF),
  );
}

String challengeDifficultyLabel(int level) {
  if (level >= 8) return 'İLERİ';
  if (level >= 5) return 'ORTA–İLERİ';
  return 'KLASİK';
}

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
            'Oyunu sen seç • Bölüm 5–10 arasından sistem belirlesin',
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
            '5–7 ORTA–İLERİ  •  8–10 İLERİ',
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
