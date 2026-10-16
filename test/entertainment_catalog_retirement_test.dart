import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/pages/challenge_game_catalog.dart';
import 'package:zeka_parkuru/services/arena_service.dart';
import 'package:zeka_parkuru/services/daily_challenge_service.dart';
import 'package:zeka_parkuru/services/daily_course_service.dart';
import 'package:zeka_parkuru/services/home_personalization_service.dart';
import 'package:zeka_parkuru/services/onboarding_preference_service.dart';

void main() {
  test('catalog keeps selected fun games retired', () {
    const Set<String> expectedActive = <String>{};

    final Set<String> active = StudioGameCatalog.inClass(StudioGameClass.fun)
        .where((GameDefinition game) => game.isPlayable)
        .map((GameDefinition game) => game.id)
        .toSet();

    expect(StudioGameCatalog.retiredGameIds, hasLength(61));
    expect(active, expectedActive);
    expect(StudioGameCatalog.playable, hasLength(44));
    expect(StudioGameCatalog.byId('slide_sweets')?.isPlayable, isTrue);
    expect(
      StudioGameCatalog.byId('slide_sweets')?.gameClass,
      StudioGameClass.speed,
    );

    const Set<String> newestFunRetirements = <String>{
      'ball_merge',
      'neon_pinball',
      'lighthouse_defense',
      'boardwalk_builder',
      'deckforge_duel',
    };
    expect(StudioGameCatalog.retiredGameIds, containsAll(newestFunRetirements));

    for (final String retiredId in StudioGameCatalog.retiredGameIds) {
      expect(StudioGameCatalog.byId(retiredId), isNotNull);
      expect(StudioGameCatalog.byId(retiredId)?.isRetired, isTrue);
      expect(StudioGameCatalog.byId(retiredId)?.isPlayable, isFalse);
    }
  });

  test('selected games are absent from active surfaces', () {
    const Set<String> selectedForRetirement = <String>{
      'warehouse_master',
      'tavla_master',
      'go_life_death',
      'shogi_mate',
      'peg_solitaire',
      'hex_connection',
      'mahjong_layers',
      'logic',
      'flow_connect',
      'circuit_repair',
      'bridge_builder',
      'gate_sequence',
      'code_breaker',
      'symbol_stream',
      'silent_count',
      'dual_task',
      'light_sequence',
      'mini_golf_route',
      'pin_unlock',
      'bubble_shooter',
      'drift_league',
      'air_hockey_arena',
      'secret_room_party',
      'spot_change',
      'loop_master',
      'mine_detective',
    };

    expect(
      StudioGameCatalog.retiredGameIds,
      containsAll(selectedForRetirement),
    );
    for (final String id in selectedForRetirement) {
      expect(StudioGameCatalog.byId(id)?.isPlayable, isFalse, reason: id);
      expect(StudioGameCatalog.isAvailable(id), isFalse, reason: id);
      expect(DailyCourseService.gameIds, isNot(contains(id)), reason: id);
      expect(
        StudioGameCatalog.playable.any((GameDefinition game) => game.id == id),
        isFalse,
        reason: '$id oynanabilir katalogda yer almamalı.',
      );
      expect(
        StudioGameClass.values.any(
          (StudioGameClass gameClass) =>
              StudioGameCatalog.inClass(gameClass)
                  .any((GameDefinition game) => game.id == id),
        ),
        isFalse,
        reason: '$id kategori listelerinde yer almamalı.',
      );
      expect(
        HomePersonalizationService.allGameIds.contains(id),
        isFalse,
        reason: '$id yedek öneri havuzunda yer almamalı.',
      );
    }

    expect(
      challengeGameDefinitions.every(
        (ChallengeGameDefinition definition) =>
            StudioGameCatalog.isAvailable(definition.id),
      ),
      isTrue,
      reason: 'Meydan okuma kataloğu emekli oyun içermemeli.',
    );

    const Set<String> newlyRetired = <String>{
      'symbol_stream',
      'silent_count',
      'dual_task',
      'light_sequence',
      'pin_unlock',
      'bubble_shooter',
      'spot_change',
      'loop_master',
      'mine_detective',
    };
    for (final String id in newlyRetired) {
      expect(DailyCourseService.gameIds, isNot(contains(id)), reason: id);
      expect(DailyChallengeService.gameLabels, isNot(contains(id)), reason: id);
      expect(ArenaService.allGameIds, isNot(contains(id)), reason: id);
      expect(
        challengeGameDefinitions.any(
          (ChallengeGameDefinition definition) => definition.id == id,
        ),
        isFalse,
        reason: '$id düello seçicisinde yer almamalı.',
      );
    }
  });

  test('home recommendations never return a retired game', () {
    const HomePersonalizationService service = HomePersonalizationService();
    for (final PlayerGameGoal? goal in PlayerGameGoal.values) {
      for (final PlayerAgeGroup age in PlayerAgeGroup.values) {
        final String recommendation = service
            .recommend(
              preferences: OnboardingPreferences(
                ageGroup: age,
                gameGoal: goal,
                completed: true,
              ),
              unlockedLevels: const <String, int>{},
              earnedStars: const <String, int>{},
            )
            .gameId;

        expect(
          StudioGameCatalog.retiredGameIds,
          isNot(contains(recommendation)),
          reason: 'goal=$goal, age=$age',
        );
      }
    }
    expect(
      HomePersonalizationService.allGameIds.where(
        StudioGameCatalog.retiredGameIds.contains,
      ),
      isEmpty,
    );
  });

  test('no retired game can be selected or resumed in a group race', () {
    for (final String id in StudioGameCatalog.retiredGameIds) {
      expect(ArenaService.allGameIds, isNot(contains(id)), reason: id);
      final ArenaEvent oldEvent = ArenaEvent(
        id: 'old-race',
        groupId: 'group',
        ownerUid: 'owner',
        title: 'Old race',
        format: 'direct',
        status: 'active',
        level: 1,
        gameIds: <String>['memory', id],
        participantIds: const <String>['owner', 'guest'],
        layoutCodes: const <String, int>{},
        createdAt: null,
        updatedAt: null,
        endsAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(oldEvent.isPlayable, isFalse, reason: id);
    }
  });
}
