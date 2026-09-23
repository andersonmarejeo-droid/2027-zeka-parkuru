import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zeka_parkuru/games/blocks/block_game_page.dart';
import 'package:zeka_parkuru/services/app_experience_controller.dart';
import 'package:zeka_parkuru/services/arena_service.dart';
import 'package:zeka_parkuru/services/home_personalization_service.dart';
import 'package:zeka_parkuru/services/onboarding_preference_service.dart';
import 'package:zeka_parkuru/theme/app_visual_theme.dart';

import 'test_preferences.dart';

String _source(String relativePath) => File(relativePath).readAsStringSync();

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  group('V9.1 kişisel ana menü', () {
    test('öneri hedefe uyar ve daha az ilerlenen parkuru seçer', () {
      const HomePersonalizationService service = HomePersonalizationService();
      const OnboardingPreferences preferences = OnboardingPreferences(
        ageGroup: PlayerAgeGroup.age18To40,
        gameGoal: PlayerGameGoal.improveMind,
        completed: true,
      );

      final HomeGameRecommendation first = service.recommend(
        preferences: preferences,
        unlockedLevels: const <String, int>{},
        earnedStars: const <String, int>{},
      );
      final HomeGameRecommendation balanced = service.recommend(
        preferences: preferences,
        unlockedLevels: const <String, int>{
          'logic': 10,
          'numbers': 2,
          'hanoi': 5,
        },
        earnedStars: const <String, int>{
          'logic': 30,
          'numbers': 3,
          'hanoi': 12,
        },
      );
      final HomeGameRecommendation ageFallback = service.recommend(
        preferences: preferences,
        unlockedLevels: const <String, int>{
          'logic': 10,
          'numbers': 10,
          'hanoi': 10,
        },
        earnedStars: const <String, int>{
          'logic': 30,
          'numbers': 30,
          'hanoi': 30,
        },
      );

      expect(first.gameId, 'logic');
      expect(balanced.gameId, 'numbers');
      expect(ageFallback.gameId, 'number_sort');
      expect(HomePersonalizationService.allGameIds.length, 11);
    });

    test('ana ekran öneri, seri ve 11 kart işaretlerini taşır', () {
      final String source = _source('lib/main.dart');
      expect(source, contains("'v9_personal_recommendation'"));
      expect(source, contains('currentStreak'));
      expect(source, contains("'v9_game_card_\$number'"));
      expect(RegExp(r'_GameCard\(').allMatches(source).length, 12);
    });
  });

  group('V9.2 içerik ve tekrar oynanabilirlik', () {
    test('11 oyun V9 içerik hedeflerinin kaynak sözleşmelerini korur', () {
      final Map<String, List<String>> requiredMarkers = <String, List<String>>{
        'lib/games/logic/logic_game_page.dart': <String>[
          'ReplayabilityService',
          'hedefler',
          'ipucuGoster',
          'yenidenBaslat',
        ],
        'lib/games/numbers/number_game_page.dart': <String>[
          'ReplayabilityService',
          'randomFor',
          'ipucuGoster',
        ],
        'lib/games/blocks/block_game_page.dart': <String>[
          'ReplayabilityService',
          'targetCombo',
          'Future<void> _newGame()',
        ],
        'lib/games/memory/memory_game_page.dart': <String>[
          'ReplayabilityService',
          'combo',
          'TEKRAR OYNA',
        ],
        'lib/games/hanoi/hanoi_game_page.dart': <String>[
          'targetPeg',
          'tutorial',
          '_undoMove',
          'HanoiSolver.nextMove',
        ],
        'lib/games/word_hunt/word_hunt_game_page.dart': <String>[
          'boardCount: 2',
          'localPosition.dx < boardInset',
          'ParkurResultAction.replay',
        ],
        'lib/games/picture_iq/picture_iq_game_page.dart': <String>[
          'questionCount: 12',
          'ParkurResultAction.replay',
        ],
        'lib/games/candy_sort/candy_sort_game_page.dart': <String>[
          '_undo',
          '_hint',
          'ParkurResultAction.replay',
        ],
        'lib/games/number_sort/number_sort_game_page.dart': <String>[
          '_solutionValues',
          '_undo',
          '_hint',
          'ParkurResultAction.replay',
        ],
        'lib/games/shape_puzzle/shape_puzzle_game_page.dart': <String>[
          'clipBehavior: Clip.none',
          'questionCount: 12',
          'ParkurResultAction.replay',
        ],
        'lib/games/reflex/reflex_game_page.dart': <String>[
          'ReplayabilityService',
          'targetShape',
          'combo',
          'TEKRAR OYNA',
        ],
      };

      expect(requiredMarkers.length, 11);
      requiredMarkers.forEach((String path, List<String> markers) {
        final String source = _source(path);
        for (final String marker in markers) {
          expect(source, contains(marker), reason: '$path → $marker');
        }
      });
    });
  });

  group('V9.3 Arena profesyonel katmanı', () {
    test('haftalık lig yalnız pazartesiden sonraki sonuçları toplar', () {
      final DateTime now = DateTime.utc(2026, 8, 24, 12);
      final List<ArenaAttempt> attempts = <ArenaAttempt>[
        ArenaAttempt(
          id: 'a',
          eventId: 'e1',
          groupId: 'g1',
          uid: 'u1',
          displayName: 'Ada',
          avatar: '🧠',
          gameId: 'logic',
          rawScore: 900,
          stars: 3,
          points: 1000,
          submittedAt: DateTime.utc(2026, 8, 24, 8),
        ),
        ArenaAttempt(
          id: 'b',
          eventId: 'e1',
          groupId: 'g1',
          uid: 'u2',
          displayName: 'Can',
          avatar: '⚡',
          gameId: 'logic',
          rawScore: 700,
          stars: 2,
          points: 700,
          submittedAt: DateTime.utc(2026, 8, 24, 9),
        ),
        ArenaAttempt(
          id: 'old',
          eventId: 'old-event',
          groupId: 'g1',
          uid: 'u2',
          displayName: 'Can',
          avatar: '⚡',
          gameId: 'blocks',
          rawScore: 9999,
          stars: 3,
          points: 1000,
          submittedAt: DateTime.utc(2026, 8, 23, 23, 59),
        ),
      ];

      final List<ArenaWeeklyStanding> standings = ArenaService.instance
          .buildWeeklyStandings(attempts: attempts, now: now);

      expect(
        standings.map((ArenaWeeklyStanding item) => item.uid),
        orderedEquals(<String>['u1', 'u2']),
      );
      expect(standings.first.totalPoints, 1000);
      expect(standings.last.totalPoints, 700);
    });

    test('koleksiyon ve tek deneme sözleşmeleri değişmeden kalır', () {
      final String service = _source('lib/services/arena_service.dart');
      final String rules = _source('firestore.rules');
      final String page = _source('lib/pages/arena_page.dart');

      expect(service, contains("collection('arena_groups_v1')"));
      expect(service, contains("collection('arena_events_v1')"));
      expect(service, contains("collection('arena_attempts_v1')"));
      expect(service, contains("'\${event.id}--\$uid--\$gameId'"));
      expect(rules, contains('validArenaGroupJoin'));
      expect(rules, contains('allow update, delete: if false'));
      expect(page, contains("'v9_arena_weekly_league'"));
      expect(page, contains("'v9_arena_result_share_card'"));
      expect(page, isNot(contains("'v9_arena_rematch'")));
    });
  });

  group('V9.4 erişilebilirlik ve performans', () {
    test('deneyim ayarları cihazda ayrı anahtarlara kaydedilir', () async {
      final AppExperienceController controller =
          AppExperienceController.instance;
      await controller.setAnimationIntensity(AppAnimationIntensity.reduced);
      await controller.setHighContrast(true);
      await controller.setLargeText(true);
      await controller.setVisualTheme(AppVisualTheme.pinkNeon);

      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      expect(
        await preferences.getString(AppExperienceController.animationKey),
        'reduced',
      );
      expect(
        await preferences.getBool(AppExperienceController.highContrastKey),
        isTrue,
      );
      expect(
        await preferences.getBool(AppExperienceController.largeTextKey),
        isTrue,
      );
      expect(
        await preferences.getString(AppExperienceController.visualThemeKey),
        'pink_neon',
      );

      await controller.resetDefaults();
      expect(controller.visualTheme, AppVisualTheme.classicNeon);
      expect(
        await preferences.getString(AppExperienceController.visualThemeKey),
        'classic_neon',
      );
    });

    test('hızlı rota azaltılmış hareket ve boyalı ilk kareyi destekler', () {
      final String route = _source('lib/widgets/fast_game_route.dart');
      final String splash = _source('lib/animated_zp_logo.dart');
      final String settings = _source('lib/pages/settings_page.dart');

      expect(route, contains('animationScale'));
      expect(route, contains("'zp_fast_game_launch_surface'"));
      expect(splash, contains('MediaQuery.disableAnimationsOf(context)'));
      expect(settings, contains("'v9_animation_intensity_setting'"));
      expect(settings, contains("'v9_high_contrast_setting'"));
      expect(settings, contains("'v9_large_text_setting'"));
    });
  });

  group('V9.5 blok LED yerleştirme önizlemesi', () {
    test('tek parça yatay ve dikey hattı önceden bulur', () {
      final List<List<Color?>> board = List<List<Color?>>.generate(
        8,
        (_) => List<Color?>.filled(8, null),
      );

      const Color occupiedColor = Color(0xFF745CFF);

      for (int col = 0; col < 8; col++) {
        if (col != 4) board[3][col] = occupiedColor;
      }

      for (int row = 0; row < 8; row++) {
        if (row != 3) board[row][4] = occupiedColor;
      }

      const GamePiece piece = GamePiece(
        cells: <BlockCell>[BlockCell(0, 0)],
        color: Color(0xFF00D9FF),
      );

      final Set<String> preview = blockLineClearPreviewCells(
        board: board,
        piece: piece,
        startRow: 3,
        startCol: 4,
      );

      expect(preview.length, 15);

      expect(
        preview,
        containsAll(<String>{
          for (int col = 0; col < 8; col++) '3-$col',
          for (int row = 0; row < 8; row++) '$row-4',
        }),
      );

      // Önizleme gerçek tahtayı değiştirmemelidir.
      expect(board[3][4], isNull);
    });

    test('geçersiz veya hat tamamlamayan konum LED yakmaz', () {
      final List<List<Color?>> board = List<List<Color?>>.generate(
        8,
        (_) => List<Color?>.filled(8, null),
      );

      const GamePiece piece = GamePiece(
        cells: <BlockCell>[BlockCell(0, 0)],
        color: Color(0xFFFF4F9A),
      );

      board[0][0] = const Color(0xFF52E86B);

      expect(
        blockLineClearPreviewCells(
          board: board,
          piece: piece,
          startRow: 0,
          startCol: 0,
        ),
        isEmpty,
      );

      expect(
        blockLineClearPreviewCells(
          board: board,
          piece: piece,
          startRow: 2,
          startCol: 2,
        ),
        isEmpty,
      );
    });
  });
}
