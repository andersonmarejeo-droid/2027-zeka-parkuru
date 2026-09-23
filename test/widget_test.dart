import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/games/candy_sort/candy_sort_game_page.dart';
import 'package:zeka_parkuru/games/number_sort/number_sort_game_page.dart';
import 'package:zeka_parkuru/games/picture_iq/picture_iq_game_page.dart';
import 'package:zeka_parkuru/games/shape_puzzle/shape_puzzle_game_page.dart';
import 'package:zeka_parkuru/games/word_hunt/word_hunt_game_page.dart';
import 'package:zeka_parkuru/services/daily_challenge_service.dart';
import 'package:zeka_parkuru/services/daily_course_service.dart';
import 'package:zeka_parkuru/services/unified_progress_service.dart';
import 'package:zeka_parkuru/services/zeka_scoring_service.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  test('V7 contains eleven unique courses', () {
    expect(DailyCourseService.gameIds.length, 11);
    expect(DailyCourseService.gameIds.toSet().length, 11);
    expect(DailyCourseService.gameIds, contains('reflex'));
    expect(DailyCourseService.gameIds, contains('word_hunt'));
    expect(DailyCourseService.gameIds, contains('picture_iq'));
    expect(DailyCourseService.gameIds, contains('candy_sort'));
    expect(DailyCourseService.gameIds, contains('number_sort'));
    expect(DailyCourseService.gameIds, contains('shape_puzzle'));
    expect(
      DailyChallengeService.gameLabels.keys.toSet(),
      DailyCourseService.gameIds.toSet(),
    );
  });

  test('daily course selects four unique games and rotates all courses', () {
    final Set<String> seen = <String>{};

    for (int day = 0; day < 120; day++) {
      final List<String> selection = DailyCourseService.instance.gamesForDate(
        DateTime(2026, 1, 1).add(Duration(days: day)),
      );

      expect(selection.length, DailyCourseService.dailyGameCount);
      expect(selection.toSet().length, DailyCourseService.dailyGameCount);
      seen.addAll(selection);
    }

    expect(seen, containsAll(DailyCourseService.gameIds));
  });

  test('fair course score ignores incompatible raw game score scales', () {
    const List<int> stars = <int>[3, 2, 1, 0, 0, 0, 0, 0, 0, 0];
    const ParkurProgressData lowRawScore = ParkurProgressData(
      acikSeviye: 4,
      yildizlar: stars,
      enIyiPuanlar: <int>[10, 20, 30, 0, 0, 0, 0, 0, 0, 0],
    );
    const ParkurProgressData highRawScore = ParkurProgressData(
      acikSeviye: 4,
      yildizlar: stars,
      enIyiPuanlar: <int>[10000, 20000, 30000, 0, 0, 0, 0, 0, 0, 0],
    );

    expect(
      ZekaScoringService.courseScore(lowRawScore),
      ZekaScoringService.courseScore(highRawScore),
    );
    expect(ZekaScoringService.dailyResultPoints(3), 250);
  });

  test('V7.2 score caps and eleven-course maximum stay synchronized', () {
    const ParkurProgressData fullCourse = ParkurProgressData(
      acikSeviye: 10,
      yildizlar: <int>[3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
      enIyiPuanlar: <int>[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    );
    const UnifiedProgressData fullProgress = UnifiedProgressData(
      mantik: fullCourse,
      sayi: fullCourse,
      blok: fullCourse,
      hafiza: fullCourse,
      hanoi: fullCourse,
      kelimeAvi: fullCourse,
      gorselIq: fullCourse,
      sekerSiralama: fullCourse,
      sayiPetegi: fullCourse,
      sekilBirlestir: fullCourse,
      refleks: fullCourse,
    );

    expect(ZekaScoringService.courseScore(fullCourse), 2000);
    expect(
      ZekaScoringService.calculate(
        progress: fullProgress,
        completedDailyCourses: 999,
        bestStreak: 999,
        perfectDays: 999,
      ).total,
      27650,
    );
  });

  test('every new course has ten progressive levels', () {
    expect(WordHuntGamePage.levels.length, 10);
    expect(PictureIqGamePage.levels.length, 10);
    expect(CandySortGamePage.levels.length, 10);
    expect(NumberSortGamePage.levels.length, 10);
    expect(ShapePuzzleGamePage.levels.length, 10);

    expect(
      WordHuntGamePage.levels.first.size,
      lessThan(WordHuntGamePage.levels.last.size),
    );
    expect(
      PictureIqGamePage.levels.first.questionCount,
      lessThan(PictureIqGamePage.levels.last.questionCount),
    );
    expect(
      CandySortGamePage.levels.first.colorCount,
      lessThan(CandySortGamePage.levels.last.colorCount),
    );
    expect(NumberSortGamePage.levels.first.dimension, 3);
    expect(NumberSortGamePage.levels.last.dimension, 4);
    expect(
      ShapePuzzleGamePage.levels.first.pieceCount,
      lessThan(ShapePuzzleGamePage.levels.last.pieceCount),
    );
  });

  test('overall totals match eleven ten-level courses', () {
    expect(UnifiedProgressData.maksimumSeviye, 110);
    expect(UnifiedProgressData.maksimumYildiz, 330);
  });

  testWidgets('new game play screens open on a small phone without errors', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final List<Widget> games = <Widget>[
      WordHuntPlayPage(
        level: WordHuntGamePage.levels.last,
        previousBestScore: 0,
      ),
      PictureIqPlayPage(
        level: PictureIqGamePage.levels.last,
        previousBestScore: 0,
      ),
      CandySortPlayPage(
        level: CandySortGamePage.levels.last,
        previousBestScore: 0,
      ),
      NumberSortPlayPage(
        level: NumberSortGamePage.levels.last,
        previousBestScore: 0,
      ),
      ShapePuzzlePlayPage(
        level: ShapePuzzleGamePage.levels.last,
        previousBestScore: 0,
      ),
    ];

    for (final Widget game in games) {
      await tester.pumpWidget(MaterialApp(home: game));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('word hunt requires exact endpoints and accepts direct drag', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: WordHuntPlayPage(
          level: WordHuntGamePage.levels.first,
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();

    final Finder targetFinder = find.byWidgetPredicate((Widget widget) {
      final Key? key = widget.key;
      return key is ValueKey<String> && key.value.startsWith('word_target_');
    });
    final List<String> targets = tester
        .widgetList<Widget>(targetFinder)
        .map(
          (Widget widget) =>
              (widget.key! as ValueKey<String>).value.substring(12),
        )
        .toList(growable: false);
    expect(targets.length, greaterThanOrEqualTo(3));

    final int size = WordHuntGamePage.levels.first.size;
    final List<List<String>> grid = List<List<String>>.generate(
      size,
      (int row) => List<String>.generate(size, (int column) {
        final Finder textFinder = find.descendant(
          of: find.byKey(ValueKey<String>('word_cell_${row}_$column')),
          matching: find.byType(Text),
        );
        return tester.widget<Text>(textFinder).data!;
      }),
    );

    List<Point<int>> pathFor(String word) {
      const List<Point<int>> directions = <Point<int>>[
        Point<int>(1, 0),
        Point<int>(-1, 0),
        Point<int>(0, 1),
        Point<int>(0, -1),
        Point<int>(1, 1),
        Point<int>(-1, -1),
        Point<int>(1, -1),
        Point<int>(-1, 1),
      ];
      final List<String> letters = word.runes
          .map((int rune) => String.fromCharCode(rune))
          .toList(growable: false);
      for (int row = 0; row < size; row++) {
        for (int column = 0; column < size; column++) {
          for (final Point<int> direction in directions) {
            final List<Point<int>> path = <Point<int>>[];
            bool matches = true;
            for (int index = 0; index < letters.length; index++) {
              final int x = column + direction.x * index;
              final int y = row + direction.y * index;
              if (x < 0 ||
                  y < 0 ||
                  x >= size ||
                  y >= size ||
                  grid[y][x] != letters[index]) {
                matches = false;
                break;
              }
              path.add(Point<int>(x, y));
            }
            if (matches) return path;
          }
        }
      }
      return const <Point<int>>[];
    }

    Finder cellFinder(Point<int> cell) =>
        find.byKey(ValueKey<String>('word_cell_${cell.y}_${cell.x}'));

    final List<Point<int>> tapPath = pathFor(targets[0]);
    expect(tapPath, isNotEmpty);
    await tester.ensureVisible(find.byKey(const ValueKey('word_hunt_board')));
    await tester.tapAt(tester.getCenter(cellFinder(tapPath.first)));
    await tester.pump();
    await tester.tapAt(tester.getCenter(cellFinder(tapPath.last)));
    await tester.pump();

    Text targetText(String word) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey<String>('word_target_$word')),
        matching: find.byType(Text),
      ),
    );
    expect(
      targetText(targets[0]).style?.decoration,
      TextDecoration.lineThrough,
    );

    final List<Point<int>> dragPath = pathFor(targets[1]);
    expect(dragPath, isNotEmpty);
    final Offset dragStart = tester.getCenter(cellFinder(dragPath.first));
    final Offset dragEnd = tester.getCenter(cellFinder(dragPath.last));
    await tester.dragFrom(dragStart, dragEnd - dragStart);
    await tester.pump();
    expect(
      targetText(targets[1]).style?.decoration,
      TextDecoration.lineThrough,
    );

    // Tahtanın kenarlığına yapılan rastgele dokunuşlar hiçbir hücreye
    // yuvarlanmamalı ve kalan kelimeyi bulundu olarak işaretlememelidir.
    final Finder boardFinder = find.byKey(const ValueKey('word_hunt_board'));
    final Rect boardRect = tester.getRect(boardFinder);
    await tester.tapAt(boardRect.topLeft + const Offset(1, 1));
    await tester.pump();
    await tester.tapAt(boardRect.bottomRight - const Offset(1, 1));
    await tester.pump();
    expect(targetText(targets[2]).style?.decoration, isNull);

    // Kelimenin başlangıç ve bitişine komşu olan iki farklı hücre de artık
    // gerçek kelime yoluna otomatik kilitlenmemelidir.
    final List<Point<int>> exactPath = pathFor(targets[2]);
    expect(exactPath, isNotEmpty);

    List<Point<int>> neighborsOf(Point<int> cell) {
      return <Point<int>>[
        for (int dy = -1; dy <= 1; dy++)
          for (int dx = -1; dx <= 1; dx++)
            if ((dx != 0 || dy != 0) &&
                cell.x + dx >= 0 &&
                cell.x + dx < size &&
                cell.y + dy >= 0 &&
                cell.y + dy < size)
              Point<int>(cell.x + dx, cell.y + dy),
      ];
    }

    Point<int>? nearbyStart;
    Point<int>? nearbyEnd;
    for (final Point<int> start in neighborsOf(exactPath.first)) {
      for (final Point<int> end in neighborsOf(exactPath.last)) {
        if (start != end) {
          nearbyStart = start;
          nearbyEnd = end;
          break;
        }
      }
      if (nearbyStart != null) break;
    }

    expect(nearbyStart, isNotNull);
    expect(nearbyEnd, isNotNull);
    await tester.tapAt(tester.getCenter(cellFinder(nearbyStart!)));
    await tester.pump();
    await tester.tapAt(tester.getCenter(cellFinder(nearbyEnd!)));
    await tester.pump();
    expect(targetText(targets[2]).style?.decoration, isNull);

    // Aynı kelimenin gerçek başlangıç ve bitiş hücreleri seçildiğinde kabul
    // edilir ve son kelime yeni tahta geçişini başlatır.
    await tester.tapAt(tester.getCenter(cellFinder(exactPath.first)));
    await tester.pump();
    await tester.tapAt(tester.getCenter(cellFinder(exactPath.last)));
    await tester.pump();
    expect(
      targetText(targets[2]).style?.decoration,
      TextDecoration.lineThrough,
    );
    expect(tester.takeException(), isNull);

    // Testi 650 ms'lik geçiş zamanlayıcısı çalışırken bitirmek sahte zaman
    // ortamında asılı Timer uyarısı üretir; animasyonu tamamla.
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('word hunt masks advanced target words', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: WordHuntPlayPage(
          level: WordHuntGamePage.levels[3],
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pump();

    final Finder targetFinder = find.byWidgetPredicate((Widget widget) {
      final Key? key = widget.key;
      return key is ValueKey<String> && key.value.startsWith('word_target_');
    });
    expect(targetFinder, findsWidgets);

    for (final Widget target in tester.widgetList<Widget>(targetFinder)) {
      final String word = (target.key! as ValueKey<String>).value.substring(12);
      final List<int> letters = word.runes.toList(growable: false);
      final String expected = <String>[
        String.fromCharCode(letters.first),
        for (int index = 1; index < letters.length; index++) '•',
      ].join(' ');

      final Text label = tester.widget<Text>(
        find.descendant(of: find.byWidget(target), matching: find.byType(Text)),
      );

      expect(label.data, expected);
      expect(label.data, isNot(word));
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('candy sort generator survives repeated openings', (
    WidgetTester tester,
  ) async {
    for (int index = 0; index < 20; index++) {
      await tester.pumpWidget(
        MaterialApp(
          home: CandySortPlayPage(
            key: ValueKey<int>(index),
            level: CandySortGamePage.levels.last,
            previousBestScore: 0,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
