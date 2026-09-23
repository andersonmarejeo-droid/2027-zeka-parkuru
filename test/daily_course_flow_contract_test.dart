import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/services/daily_course_service.dart';

import 'test_preferences.dart';

String _source(String relativePath) => File(relativePath).readAsStringSync();

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  test('geri çıkış bölümü çözmez ve aynı bölümü bekletir', () async {
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

  test('başarısızlık ve geçme sıfır ödülle sonraki bölüme ilerler', () async {
    final DailyCourseService service = DailyCourseService.instance;
    final DailyCourseData initial = await service.loadToday();

    final DailyCourseData failed = await service.recordStageResult(
      DailyStageResult.failed(gameId: initial.games[0]),
      expectedDateKey: initial.dateKey,
    );
    expect(failed.failedGames, contains(initial.games[0]));
    expect(failed.nextGameId, initial.games[1]);
    expect(failed.totalScore, 0);

    final DailyCourseData skipped = await service.recordStageResult(
      DailyStageResult.skipped(gameId: initial.games[1]),
      expectedDateKey: initial.dateKey,
    );
    expect(skipped.skippedGames, contains(initial.games[1]));
    expect(skipped.nextGameId, initial.games[2]);
    expect(skipped.totalScore, 0);
  });

  test('günlük sayfa 11 oyuna kararlı düzen kodu taşır', () {
    final String page = _source('lib/pages/daily_course_page.dart');

    expect(
      RegExp(r'competitionLayoutCode:\s*layoutCode').allMatches(page).length,
      11,
    );
    expect(page, contains("'daily_course_skip_button'"));
    expect(page, contains('Future<bool> _showStageTransition'));
    expect(page, contains('onPopInvokedWithResult'));
    expect(page, contains('_close(false)'));
    expect(page, contains('class _DailyCourseUnavailablePage'));
  });

  test('aynı tarih, oyun ve tur aynı seviye ile düzeni üretir', () {
    final DailyCourseService service = DailyCourseService.instance;
    final DateTime date = DateTime(2026, 9, 4);

    final int level = service.levelForDailyCourse(
      date: date,
      gameId: 'logic',
      runNumber: 0,
    );
    final int layout = service.layoutCodeForDailyCourse(
      date: date,
      gameId: 'logic',
      runNumber: 0,
    );

    expect(
      service.levelForDailyCourse(date: date, gameId: 'logic', runNumber: 0),
      level,
    );
    expect(
      service.layoutCodeForDailyCourse(
        date: date,
        gameId: 'logic',
        runNumber: 0,
      ),
      layout,
    );
  });

  test('11 oyun günlük dört durumlu sonuç köprüsünü kullanır', () {
    const List<String> directHubs = <String>[
      'lib/games/logic/logic_game_page.dart',
      'lib/games/numbers/number_game_page.dart',
      'lib/games/blocks/block_game_page.dart',
      'lib/games/memory/memory_game_page.dart',
      'lib/games/hanoi/hanoi_game_page.dart',
      'lib/games/reflex/reflex_game_page.dart',
    ];

    for (final String path in directHubs) {
      final String source = _source(path);
      final int dailyBranch = source.indexOf('if (widget.dailyCourseMode)');
      final int competitionBranch = source.indexOf(
        'if (widget.competitionLevel != null)',
        dailyBranch,
      );
      expect(dailyBranch, greaterThanOrEqualTo(0), reason: path);
      expect(competitionBranch, greaterThan(dailyBranch), reason: path);
      expect(source, contains('DailyStageResult.exited'), reason: path);
      expect(source, contains('DailyStageResult.completed'), reason: path);
      expect(source, contains('DailyStageResult.failed'), reason: path);
    }

    final String shared = _source('lib/games/shared/parkur_game_kit.dart');
    final int dailyBranch = shared.indexOf('if (widget.dailyCourseMode)');
    final int competitionBranch = shared.indexOf(
      'if (widget.competitionLevel != null)',
      dailyBranch,
    );
    expect(dailyBranch, greaterThanOrEqualTo(0));
    expect(competitionBranch, greaterThan(dailyBranch));
    expect(shared, contains('DailyStageResult.exited'));
    expect(shared, contains('DailyStageResult.completed'));
    expect(shared, contains('DailyStageResult.failed'));
  });

  test('hafıza can bitişi günlük akışta başarısızlığa çevrilir', () {
    final String memory = _source('lib/games/memory/memory_game_page.dart');

    expect(memory, contains('result.stars == 0 && result.score == 0'));
    expect(memory, contains("DailyStageResult.failed(gameId: 'memory')"));
  });
}
