import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/services/daily_challenge_service.dart';
import 'package:zeka_parkuru/services/daily_course_service.dart';
import 'package:zeka_parkuru/services/player_progress_service.dart';
import 'package:zeka_parkuru/services/replayability_service.dart';
import 'package:zeka_parkuru/services/unified_progress_service.dart';
import 'package:zeka_parkuru/services/zeka_scoring_service.dart';

import 'test_preferences.dart';

const ParkurProgressData _emptyCourse = ParkurProgressData(
  acikSeviye: 1,
  yildizlar: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  enIyiPuanlar: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
);

const UnifiedProgressData _emptyProgress = UnifiedProgressData(
  mantik: _emptyCourse,
  sayi: _emptyCourse,
  blok: _emptyCourse,
  hafiza: _emptyCourse,
  hanoi: _emptyCourse,
  kelimeAvi: _emptyCourse,
  gorselIq: _emptyCourse,
  sekerSiralama: _emptyCourse,
  sayiPetegi: _emptyCourse,
  sekilBirlestir: _emptyCourse,
  refleks: _emptyCourse,
);

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  group('Yerel kayıt güvenliği', () {
    test('parkur kaydı bozuk değerleri güvenli sınırlara çeker', () async {
      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      await preferences.setInt('qa_unlocked_level', 99);
      await preferences.setStringList('qa_stars', <String>['-2', '4', 'bozuk']);
      await preferences.setStringList('qa_best_scores', <String>[
        '-50',
        '250',
        'bozuk',
      ]);

      final ParkurProgressStore store = ParkurProgressStore(
        prefix: 'qa',
        levelCount: 10,
      );
      final ParkurProgressSnapshot result = await store.load();

      expect(result.unlockedLevel, 10);
      expect(result.stars.length, 10);
      expect(result.stars.take(3), orderedEquals(<int>[0, 3, 0]));
      expect(result.bestScores.length, 10);
      expect(result.bestScores.take(3), orderedEquals(<int>[0, 250, 0]));
    });

    test('kaydet-yükle döngüsü yıldız ve puanları korur', () async {
      final ParkurProgressStore store = ParkurProgressStore(
        prefix: 'round_trip',
        levelCount: 10,
      );

      await store.save(
        const ParkurProgressSnapshot(
          unlockedLevel: 4,
          stars: <int>[3, 2, 1, 0, 0, 0, 0, 0, 0, 0],
          bestScores: <int>[900, 700, 500, 0, 0, 0, 0, 0, 0, 0],
        ),
      );

      final ParkurProgressSnapshot result = await store.load();
      expect(result.unlockedLevel, 4);
      expect(result.stars.take(4), orderedEquals(<int>[3, 2, 1, 0]));
      expect(result.bestScores.take(4), orderedEquals(<int>[900, 700, 500, 0]));
    });
  });

  group('Tekrar oynanabilirlik', () {
    test('aynı parkur düzeni kodu aynı rastgele diziyi üretir', () {
      final ReplayabilityService service = ReplayabilityService();
      final Random first = service.randomFor(
        sessionSeed: 123456,
        round: 2,
        salt: 77,
      );
      final Random second = service.randomFor(
        sessionSeed: 123456,
        round: 2,
        salt: 77,
      );

      expect(
        List<int>.generate(20, (_) => first.nextInt(100000)),
        orderedEquals(List<int>.generate(20, (_) => second.nextInt(100000))),
      );
    });

    test('aynı soru parmak izi tekrar gelirse reddedilir', () async {
      final ReplayabilityService service = ReplayabilityService();

      expect(
        await service.registerFingerprint(
          gameId: 'numbers',
          level: 1,
          fingerprint: 'soru-A',
        ),
        isTrue,
      );
      expect(
        await service.registerFingerprint(
          gameId: 'numbers',
          level: 1,
          fingerprint: 'soru-A',
        ),
        isFalse,
      );
      expect(
        await service.registerFingerprint(
          gameId: 'numbers',
          level: 1,
          fingerprint: 'soru-B',
        ),
        isTrue,
      );
    });
  });

  group('Günlük parkur ve görevler', () {
    test('günlük parkur aynı oyunu iki kez puanlamaz', () async {
      final DailyCourseService service = DailyCourseService.instance;
      final DailyCourseData initial = await service.loadToday();
      final String gameId = initial.games.first;

      final DailyCourseData first = await service.recordGameCompleted(
        DailyCourseGameResult(gameId: gameId, stars: 9, score: 999999),
      );
      final DailyCourseData duplicate = await service.recordGameCompleted(
        DailyCourseGameResult(gameId: gameId, stars: 1, score: 1),
      );

      expect(first.completedCount, 1);
      expect(first.totalStars, 3);
      expect(first.totalScore, 250);
      expect(duplicate.completedCount, 1);
      expect(duplicate.totalStars, first.totalStars);
      expect(duplicate.totalScore, first.totalScore);
    });

    test(
      'başarısız ve geçilen bölümler sıfır puanla rotayı ilerletir',
      () async {
        final DailyCourseService service = DailyCourseService.instance;
        final DailyCourseData initial = await service.loadToday();
        final String failedGame = initial.games.first;
        final String skippedGame = initial.games[1];

        final DailyCourseData failed = await service.recordStageResult(
          DailyStageResult.failed(gameId: failedGame),
          expectedDateKey: initial.dateKey,
        );
        expect(failed.completedCount, 1);
        expect(failed.failedGames, contains(failedGame));
        expect(failed.successfulGames, isNot(contains(failedGame)));
        expect(failed.totalStars, 0);
        expect(failed.totalScore, 0);
        expect(failed.nextGameId, skippedGame);

        final DailyCourseData skipped = await service.recordStageResult(
          DailyStageResult.skipped(gameId: skippedGame),
          expectedDateKey: initial.dateKey,
        );
        expect(skipped.completedCount, 2);
        expect(skipped.skippedGames, contains(skippedGame));
        expect(skipped.totalStars, 0);
        expect(skipped.totalScore, 0);
        expect(skipped.nextGameId, initial.games[2]);
      },
    );

    test('geri çıkış günlük bölümü çözülmüş saymaz', () async {
      final DailyCourseService service = DailyCourseService.instance;
      final DailyCourseData initial = await service.loadToday();
      final String gameId = initial.games.first;

      final DailyCourseData afterExit = await service.recordStageResult(
        DailyStageResult.exited(gameId: gameId),
        expectedDateKey: initial.dateKey,
      );

      expect(afterExit.completedCount, 0);
      expect(afterExit.nextGameId, gameId);
      expect(afterExit.totalStars, 0);
      expect(afterExit.totalScore, 0);
    });

    test('aynı günlük bölüm aynı seviye ve düzen kodunu korur', () {
      final DailyCourseService service = DailyCourseService.instance;
      final DateTime date = DateTime(2026, 9, 4);

      final int firstLevel = service.levelForDailyCourse(
        date: date,
        gameId: 'logic',
        runNumber: 0,
      );
      final int firstLayout = service.layoutCodeForDailyCourse(
        date: date,
        gameId: 'logic',
        runNumber: 0,
      );

      expect(
        service.levelForDailyCourse(date: date, gameId: 'logic', runNumber: 0),
        firstLevel,
      );
      expect(
        service.layoutCodeForDailyCourse(
          date: date,
          gameId: 'logic',
          runNumber: 0,
        ),
        firstLayout,
      );
      expect(
        service.layoutCodeForDailyCourse(
          date: date,
          gameId: 'logic',
          runNumber: 1,
        ),
        isNot(firstLayout),
      );
    });

    test('tanımsız oyun günlük görevlere ilerleme yazmaz', () async {
      final DailyRecordResult result = await DailyChallengeService.instance
          .recordLevelCompleted(
            gameId: 'bilinmeyen_oyun',
            stars: 3,
            score: 9999,
          );

      expect(result.data.levelsCompleted, 0);
      expect(result.data.starsEarned, 0);
      expect(result.data.scoreEarned, 0);
      expect(result.newlyCompletedTasks, 0);
      expect(result.streakAdvanced, isFalse);
    });
  });

  group('Puan ve ilerleme sınırları', () {
    test('negatif bonus girdileri sıfıra, aşırı girdiler tavana çekilir', () {
      final ZekaScoreBreakdown negative = ZekaScoringService.calculate(
        progress: _emptyProgress,
        completedDailyCourses: -5,
        bestStreak: -8,
        perfectDays: -2,
      );
      final ZekaScoreBreakdown capped = ZekaScoringService.calculate(
        progress: _emptyProgress,
        completedDailyCourses: 999,
        bestStreak: 999,
        perfectDays: 999,
      );

      expect(negative.total, 0);
      expect(capped.dailyCoursePoints, 3000);
      expect(capped.streakPoints, 600);
      expect(capped.perfectDayPoints, 1500);
    });

    test('ilerleme ve rozet oranları 0-1 aralığında kalır', () {
      const PlayerAchievementData overflow = PlayerAchievementData(
        id: 'qa',
        title: 'QA',
        description: 'QA',
        emoji: '🧪',
        current: 50,
        target: 10,
        unlocked: true,
      );
      const PlayerAchievementData emptyTarget = PlayerAchievementData(
        id: 'qa_zero',
        title: 'QA',
        description: 'QA',
        emoji: '🧪',
        current: 0,
        target: 0,
        unlocked: true,
      );

      expect(_emptyProgress.genelIlerlemeOrani, 0.0);
      expect(overflow.progress, 1.0);
      expect(emptyTarget.progress, 1.0);
    });
  });
}
