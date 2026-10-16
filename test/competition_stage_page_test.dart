import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/reference_games/single_stroke_game_page.dart';
import 'package:zeka_parkuru/games/reference_games/single_stroke_puzzle.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/shared/studio_game_contracts.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/services/daily_course_service.dart';
import 'package:zeka_parkuru/widgets/competition_stage_page.dart';

import 'test_preferences.dart';

Widget _testHub(Object? result) => ParkurLevelHub(
  gameId: 'single_stroke',
  progressPrefix: 'single_stroke',
  titleTr: 'Test',
  titleEn: 'Test',
  taglineTr: 'Test',
  taglineEn: 'Test',
  accent: Colors.teal,
  icon: Icons.gesture_rounded,
  levels: const <ParkurLevelSpec>[
    ParkurLevelSpec(
      number: 1,
      titleTr: 'Test',
      titleEn: 'Test',
      subtitleTr: 'Test',
      subtitleEn: 'Test',
      difficulty: 'Test',
      icon: Icons.gesture_rounded,
    ),
  ],
  dailyCourseMode: true,
  competitionLevel: 1,
  competitionLayoutCode: 0,
  playBuilder: (context, level, best, layout, competition) => Scaffold(
    appBar: AppBar(title: const Text('OYUN EKRANI')),
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.of(context).pop(result),
        child: const Text('TAMAMLA'),
      ),
    ),
  ),
);

Future<void> _launch(
  WidgetTester tester,
  WidgetBuilder gameBuilder,
  List<Object?> results, {
  bool autoNext = false,
  bool controls = true,
  Size size = const Size(390, 1000),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData.light(useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              child: const Text('BAŞLAT'),
              onPressed: () async {
                final Object? result = await Navigator.of(context)
                    .push<Object?>(
                      MaterialPageRoute<Object?>(
                        builder: (_) => controls
                            ? CompetitionStagePage(
                                gameId: 'single_stroke',
                                gameName: 'Tek Çizgi Ustası',
                                stageNumber: 1,
                                stageCount: 6,
                                gameBuilder: gameBuilder,
                              )
                            : Builder(builder: gameBuilder),
                      ),
                    );
                results.add(result);
                if (autoNext &&
                    context.mounted &&
                    result is DailyStageResult &&
                    result.resolvesStage) {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const Scaffold(body: Text('SIRADAKİ OYUN AÇILDI')),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('BAŞLAT'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    installTestPreferences();
    final String sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
    final FontLoader font = FontLoader('Roboto')
      ..addFont(
        File('$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    await font.load();
  });
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  for (final bool controls in <bool>[false, true]) {
    testWidgets(
      'single stroke completion returns once and opens next stage (controls=$controls)',
      (tester) async {
        final List<Object?> results = <Object?>[];
        await _launch(
          tester,
          (_) => const SingleStrokeGamePage(
            dailyCourseMode: true,
            competitionLevel: 1,
            competitionLayoutCode: 0,
          ),
          results,
          controls: controls,
          autoNext: true,
        );
        final Finder finder = find.byKey(
          const ValueKey<String>('single_stroke_trace_board'),
        );
        expect(finder, findsOneWidget);
        if (controls) {
          expect(
            find.byKey(const ValueKey<String>('competition_skip_stage')),
            findsOneWidget,
          );
        }
        final RenderBox board = tester.renderObject(finder);
        final int pool = GameContentPolicy.poolIndexForGame(
          'single_stroke',
          1,
          0,
          stages: GameContentPolicy.nativeStages('single_stroke'),
        );
        final SingleStrokePuzzle puzzle = SingleStrokePuzzle.generate(1, pool);
        Offset point(int node) => board.localToGlobal(
          Offset(
            puzzle.points[node].x * board.size.width,
            puzzle.points[node].y * board.size.height,
          ),
        );
        final TestGesture trace = await tester.startGesture(
          point(puzzle.solution.first),
        );
        for (final int node in puzzle.solution.skip(1)) {
          await trace.moveTo(point(node));
          await tester.pump(const Duration(milliseconds: 40));
        }
        await trace.up();
        await tester.pumpAndSettle();
        expect(results, hasLength(1));
        final DailyStageResult result = results.single! as DailyStageResult;
        expect(result.gameId, 'single_stroke');
        expect(result.outcome, DailyStageOutcome.completed);
        expect(result.stars, greaterThan(0));
        expect(find.text('SIRADAKİ OYUN AÇILDI'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('legacy Parkur result still advances through the shared hub', (
    tester,
  ) async {
    final List<Object?> results = <Object?>[];
    await _launch(
      tester,
      (_) => _testHub(
        const ParkurGameResult(
          completed: true,
          stars: 2,
          score: 80,
          nextLevel: true,
        ),
      ),
      results,
      autoNext: true,
    );
    await tester.tap(find.text('TAMAMLA'));
    await tester.pumpAndSettle();
    expect(results, hasLength(1));
    expect((results.single! as DailyStageResult).stars, 2);
    expect(find.text('SIRADAKİ OYUN AÇILDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'skip is visible inside a nested game and advances with zero score',
    (tester) async {
      final List<Object?> results = <Object?>[];
      await _launch(tester, (_) => _testHub(null), results, autoNext: true);
      expect(find.text('OYUN EKRANI'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('competition_skip_stage')),
      );
      await tester.pumpAndSettle();
      expect(results, hasLength(1));
      final DailyStageResult result = results.single! as DailyStageResult;
      expect(result.outcome, DailyStageOutcome.skipped);
      expect(result.stars, 0);
      expect(result.rawScore, 0);
      expect(find.text('SIRADAKİ OYUN AÇILDI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'exit can return to the game or leave without resolving the stage',
    (tester) async {
      final List<Object?> results = <Object?>[];
      await _launch(tester, (_) => _testHub(null), results);
      await tester.tap(
        find.byKey(const ValueKey<String>('competition_exit_stage')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('competition_return_to_game')),
      );
      await tester.pumpAndSettle();
      expect(results, isEmpty);
      expect(find.text('OYUN EKRANI'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('competition_exit_stage')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('competition_leave_course')),
      );
      await tester.pumpAndSettle();
      expect(results, <Object?>[CompetitionStageAction.leave]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'game back can reopen the same nested stage without a blank screen',
    (tester) async {
      final List<Object?> results = <Object?>[];
      await _launch(tester, (_) => _testHub(null), results);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('competition_return_to_game')),
      );
      await tester.pumpAndSettle();
      expect(find.text('OYUN EKRANI'), findsOneWidget);
      expect(results, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('controls and exit actions fit a narrow phone at enlarged text', (
    tester,
  ) async {
    final List<Object?> results = <Object?>[];
    await _launch(
      tester,
      (_) => const Scaffold(body: Center(child: Text('OYUN'))),
      results,
      size: const Size(320, 600),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const ValueKey<String>('competition_exit_stage')),
    );
    await tester.pumpAndSettle();
    final Finder leave = find.byKey(
      const ValueKey<String>('competition_leave_course'),
    );
    await tester.ensureVisible(leave);
    expect(tester.getBottomLeft(leave).dy, lessThanOrEqualTo(600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('game completion while exit sheet is open still advances once', (
    tester,
  ) async {
    final List<Object?> results = <Object?>[];
    late BuildContext gameContext;
    await _launch(
      tester,
      (context) {
        gameContext = context;
        return const Scaffold(body: Text('OYUN'));
      },
      results,
      autoNext: true,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('competition_exit_stage')),
    );
    await tester.pumpAndSettle();
    Navigator.of(gameContext).pop(
      const DailyStageResult.completed(
        gameId: 'single_stroke',
        stars: 3,
        rawScore: 100,
      ),
    );
    await tester.pumpAndSettle();
    expect(results, hasLength(1));
    expect(find.text('SIRADAKİ OYUN AÇILDI'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('competition_return_to_game')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
