import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/shared/parkur_game_kit.dart';
import 'package:zeka_parkuru/games/word_wheel/word_wheel_game_page.dart';
import 'package:zeka_parkuru/games/word_wheel/word_wheel_puzzle.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('320×600 Turkish phone sees wheel controls without scrolling', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: WordWheelPlayPage(
          level: ParkurLevelSpec(
            number: 1,
            titleTr: 'Harf Çarkı 01',
            titleEn: 'Letter Wheel 01',
            subtitleTr: 'Harf çarkından kelime bul',
            subtitleEn: 'Find words in the wheel',
            difficulty: 'USTALAŞMA',
            icon: Icons.casino_outlined,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('word_wheel_scroll')),
      findsNothing,
    );
    expect(find.text('KELİME IZGARASI'), findsNothing);
    expect(find.text('BULUNAN KELİMELER'), findsOneWidget);
    final Rect wheelRect = tester.getRect(
      find.byKey(const ValueKey<String>('word_wheel_letter_wheel')),
    );
    expect(wheelRect.top, greaterThanOrEqualTo(0));
    expect(wheelRect.bottom, lessThanOrEqualTo(600));

    final WordWheelPuzzle puzzle = WordWheelPuzzle.forLevel(1);
    for (final String answer in puzzle.answers) {
      final Map<String, List<int>> remaining = <String, List<int>>{};
      for (int index = 0; index < puzzle.wheelLetters.length; index++) {
        remaining
            .putIfAbsent(puzzle.wheelLetters[index], () => <int>[])
            .add(index);
      }
      for (final int rune in answer.runes) {
        final String letter = String.fromCharCode(rune);
        final List<int>? options = remaining[letter];
        final int? wheelIndex = options == null || options.isEmpty
            ? null
            : options.removeLast();
        expect(wheelIndex, isNotNull, reason: '$answer must be formable');
        final Finder letterTile = find.byKey(
          ValueKey<String>('word_wheel_letter_$wheelIndex'),
        );
        await tester.tapAt(tester.getCenter(letterTile));
        await tester.pump();
      }
      final Finder submit = find.byKey(
        const ValueKey<String>('word_wheel_submit'),
      );
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('word_wheel_complete_button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('KELİME ÇARKI TAMAMLANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a word is accepted by swiping without lifting the finger', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: WordWheelPlayPage(
          level: ParkurLevelSpec(
            number: 1,
            titleTr: 'Harf Çarkı 01',
            titleEn: 'Letter Wheel 01',
            subtitleTr: 'Harf çarkından kelime bul',
            subtitleEn: 'Find a word in the wheel',
            difficulty: 'BAŞLANGIÇ',
            icon: Icons.casino_outlined,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final WordWheelPuzzle puzzle = WordWheelPuzzle.forLevel(1);
    final String answer = puzzle.answers.first;
    final Map<String, List<int>> indices = <String, List<int>>{};
    for (int index = 0; index < puzzle.wheelLetters.length; index++) {
      indices.putIfAbsent(puzzle.wheelLetters[index], () => <int>[]).add(index);
    }
    final List<int> path = <int>[];
    for (final int rune in answer.runes) {
      path.add(indices[String.fromCharCode(rune)]!.removeLast());
    }
    final List<Offset> centers = path
        .map(
          (int index) => tester.getCenter(
            find.byKey(ValueKey<String>('word_wheel_letter_$index')),
          ),
        )
        .toList(growable: false);
    final TestGesture gesture = await tester.startGesture(centers.first);
    await _dragAroundWheel(tester, gesture, centers);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('word_wheel_found_count')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('word_wheel_found_count')),
          )
          .data,
      startsWith('1/'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('SIRT is accepted by a swipe after the wheel is rotated', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: WordWheelPlayPage(
          level: ParkurLevelSpec(
            number: 7,
            titleTr: 'Harf Çarkı 07',
            titleEn: 'Letter Wheel 07',
            subtitleTr: 'Harf çarkından kelime bul',
            subtitleEn: 'Find a word in the wheel',
            difficulty: 'USTALAŞMA',
            icon: Icons.casino_outlined,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('word_wheel_shuffle')));
    await tester.pumpAndSettle();

    final WordWheelPuzzle puzzle = WordWheelPuzzle.forLevel(7);
    final List<int> path = <int>[
      for (final String letter in <String>['S', 'I', 'R', 'T'])
        puzzle.wheelLetters.indexOf(letter),
    ];
    expect(path.every((int index) => index >= 0), isTrue);
    final List<Offset> centers = path
        .map(
          (int index) => tester.getCenter(
            find.byKey(ValueKey<String>('word_wheel_letter_$index')),
          ),
        )
        .toList(growable: false);

    final TestGesture gesture = await tester.startGesture(centers.first);
    await _dragAroundWheel(tester, gesture, centers);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.textContaining('SIRT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('joker opens an uppercase keyboard and keeps the chosen letter', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: WordWheelPlayPage(
          level: ParkurLevelSpec(
            number: 1,
            titleTr: 'Harf Çarkı 01',
            titleEn: 'Letter Wheel 01',
            subtitleTr: 'Harf çarkından kelime bul',
            subtitleEn: 'Find words in the wheel',
            difficulty: 'BAŞLANGIÇ',
            icon: Icons.casino_outlined,
          ),
          previousBestScore: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final int jokerIndex = WordWheelPuzzle.forLevel(1).wheelLetters.length;
    await tester.tap(
      find.byKey(ValueKey<String>('word_wheel_letter_$jokerIndex')),
    );
    await tester.pumpAndSettle();
    expect(find.text('JOKER HARFİ SEÇ'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('word_wheel_joker_key_A')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('word_wheel_joker_key_A')),
    );
    await tester.pumpAndSettle();
    expect(find.text('JOKER HARFİ SEÇ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 English hub shows 30 chapters over a 700-round pool', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: WordWheelGamePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Word Wheel'), findsOneWidget);
    expect(find.textContaining('Letter Wheel 01'), findsOneWidget);
    expect(WordWheelGamePage.totalCases, 30);
    expect(WordWheelPuzzle.poolSize, 700);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _dragAroundWheel(
  WidgetTester tester,
  TestGesture gesture,
  List<Offset> centers,
) async {
  final Rect wheel = tester.getRect(
    find.byKey(const ValueKey<String>('word_wheel_letter_wheel')),
  );
  final Offset center = wheel.center;
  final double halfSide = math.min(wheel.width, wheel.height) / 2;
  const int segments = 8;

  for (int targetIndex = 1; targetIndex < centers.length; targetIndex++) {
    final Offset from = centers[targetIndex - 1];
    final Offset to = centers[targetIndex];
    final double fromAngle = math.atan2(
      from.dy - center.dy,
      from.dx - center.dx,
    );
    final double toAngle = math.atan2(to.dy - center.dy, to.dx - center.dx);
    double angleDelta = toAngle - fromAngle;
    while (angleDelta > math.pi) {
      angleDelta -= 2 * math.pi;
    }
    while (angleDelta < -math.pi) {
      angleDelta += 2 * math.pi;
    }

    for (int step = 1; step <= segments; step++) {
      final double progress = step / segments;
      final double startRadius = (from - center).distance;
      final double radius = startRadius + (halfSide - startRadius) * progress;
      await gesture.moveTo(
        center + Offset(math.cos(fromAngle), math.sin(fromAngle)) * radius,
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    for (int step = 1; step <= segments; step++) {
      final double progress = step / segments;
      final double angle = fromAngle + angleDelta * progress;
      await gesture.moveTo(
        center + Offset(math.cos(angle), math.sin(angle)) * halfSide,
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    for (int step = 1; step <= segments; step++) {
      final double progress = step / segments;
      final double targetRadius = (to - center).distance;
      final double radius = halfSide + (targetRadius - halfSide) * progress;
      await gesture.moveTo(
        center + Offset(math.cos(toAngle), math.sin(toAngle)) * radius,
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
  }
}
