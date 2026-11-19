import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';
import 'package:zeka_parkuru/services/unified_progress_service.dart';
import 'package:zeka_parkuru/services/zeka_scoring_service.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('Tüm aktif oyunların puan sistemine dahil olduğunu ve puan verdiğini doğrula', () async {
    final activePlayable = StudioGameCatalog.games
        .where((g) => g.isPlayable && !StudioGameCatalog.isGameRetired(g.id))
        .map((g) => g.id)
        .toList();

    final prefs = SharedPreferencesAsync();

    // 36 aktif oyunun her biri için simüle edilmiş seviye tamamlama
    for (final gameId in activePlayable) {
      if (gameId == 'numbers') {
        await prefs.setInt('number_acik_seviye', 2);
        await prefs.setStringList('number_yildizlar', ['3']);
        await prefs.setStringList('number_en_iyi_puanlar', ['100']);
        await prefs.setStringList('numbers_common_points', ['10']);
      } else if (gameId == 'blocks') {
        await prefs.setInt('block_acik_seviye', 2);
        await prefs.setStringList('block_yildizlar', ['3']);
        await prefs.setStringList('block_en_iyi_puanlar', ['100']);
        await prefs.setStringList('blocks_common_points', ['10']);
      } else {
        await prefs.setInt('${gameId}_unlocked_level', 2);
        await prefs.setStringList('${gameId}_stars', ['3']);
        await prefs.setStringList('${gameId}_best_scores', ['100']);
        await prefs.setStringList('${gameId}_common_points', ['10']);
      }
    }

    final service = UnifiedProgressService();
    final progress = await service.genelIlerlemeyiYukle();

    final List<String> zeroScoreGames = [];
    for (final gameId in activePlayable) {
      final gameProgress = progress.gameProgressById[gameId];
      if (gameProgress == null || gameProgress.toplamOrtakPuan == 0) {
        zeroScoreGames.add(gameId);
      }
    }

    final zekaScore = ZekaScoringService.calculate(progress: progress);
    expect(zeroScoreGames, isEmpty, reason: 'Puan vermeyen oyunlar: $zeroScoreGames');
    expect(progress.toplamOrtakPuan, activePlayable.length * 10);
    expect(zekaScore.total, activePlayable.length * 10);
  });
}
