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

  group('Kelime Çarkı Yeni Kurallar ve Dil Uyarlamaları', () {
    test('2 ve 3 harfli kelimeleri kesinlikle kabul etmez (en az 4 harf zorunlu)', () {
      final puzzleTr = WordWheelPuzzle.forLevel(1, languageCode: 'tr');
      // KALEM çarkında K, A, L, E, M harfleri var.
      // 2 ve 3 harfli gerçek Türkçe kelimeler:
      expect(puzzleTr.canBuildWord('EL'), isFalse);
      expect(puzzleTr.canBuildWord('EK'), isFalse);
      expect(puzzleTr.canBuildWord('KAL'), isFalse);
      expect(puzzleTr.canBuildWord('KEL'), isFalse);
      expect(puzzleTr.canBuildWord('ELA'), isFalse);
      expect(puzzleTr.canBuildWord('KAM'), isFalse);
      expect(puzzleTr.isKnownWord('EL'), isFalse);
      expect(puzzleTr.isKnownWord('KAL'), isFalse);

      // Ancak 4 ve 5 harfli kelimeler kabul edilir:
      expect(puzzleTr.canBuildWord('KALE'), isTrue);
      expect(puzzleTr.canBuildWord('ELMA'), isTrue);
      expect(puzzleTr.canBuildWord('KALEM'), isTrue);

      // İngilizce için de 2 ve 3 harfliler reddedilmeli:
      final puzzleEn = WordWheelPuzzle.forLevel(1, languageCode: 'en');
      expect(puzzleEn.canBuildWord('AS'), isFalse);
      expect(puzzleEn.canBuildWord('CAR'), isFalse);
      expect(puzzleEn.canBuildWord('ARC'), isFalse);
      expect(puzzleEn.canBuildWord('CARE'), isTrue);
      expect(puzzleEn.canBuildWord('CARES'), isTrue);

      // Arapça için de 2 ve 3 harfliler reddedilmeli:
      final puzzleAr = WordWheelPuzzle.forLevel(1, languageCode: 'ar');
      expect(puzzleAr.canBuildWord('مس'), isFalse);
      expect(puzzleAr.canBuildWord('سر'), isFalse);
      expect(puzzleAr.canBuildWord('سمر'), isFalse);
      expect(puzzleAr.canBuildWord('سفر'), isFalse);
      expect(puzzleAr.canBuildWord('مسار'), isTrue);
      expect(puzzleAr.canBuildWord('مسافر'), isTrue);
    });

    test('Arapça dili için Arapça çark ve kelimeler doğru yüklenir', () {
      final puzzleAr = WordWheelPuzzle.forLevel(1, languageCode: 'ar');
      expect(puzzleAr.languageCode, 'ar');
      expect(puzzleAr.wheelLetters, containsAll(<String>['م', 'س', 'ا', 'ف', 'ر']));
      expect(puzzleAr.answers.every((w) => w.runes.length >= 4), isTrue);
      expect(puzzleAr.canBuildWord('مسافر'), isTrue);
      expect(puzzleAr.canBuildWord('فارس'), isTrue);
    });

    testWidgets('Aynı kelime tekrar girildiğinde puan vermez ve uyarı gösterir', (
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

      final puzzle = WordWheelPuzzle.forLevel(1, languageCode: 'tr');
      final firstAnswer = puzzle.answers.first; // örn: KALEM

      Future<void> tapWord(String word) async {
        final Map<String, List<int>> remaining = <String, List<int>>{};
        for (int index = 0; index < puzzle.wheelLetters.length; index++) {
          remaining
              .putIfAbsent(puzzle.wheelLetters[index], () => <int>[])
              .add(index);
        }
        for (final int rune in word.runes) {
          final String letter = String.fromCharCode(rune);
          final int wheelIndex = remaining[letter]!.removeLast();
          final Finder letterTile = find.byKey(
            ValueKey<String>('word_wheel_letter_$wheelIndex'),
          );
          await tester.tapAt(tester.getCenter(letterTile));
          await tester.pump();
        }
      }

      // Kelimeyi ilk kez gir
      await tapWord(firstAnswer);
      await tester.tap(find.byKey(const ValueKey<String>('word_wheel_submit')));
      await tester.pumpAndSettle();

      expect(find.text('$firstAnswer bulundu — +${firstAnswer.runes.length * firstAnswer.runes.length * 24} puan.'), findsOneWidget);

      // Kelimeyi ikinci kez tekrar gir
      await tapWord(firstAnswer);
      await tester.tap(find.byKey(const ValueKey<String>('word_wheel_submit')));
      await tester.pumpAndSettle();

      // Tekrar puan verilmediği ve aynı kelime uyarısı çıktığı doğrulanır:
      expect(find.text('Bu kelimeyi zaten buldun! (Tekrar puan verilmez)'), findsOneWidget);
    });

    testWidgets('Hedef dışındaki geçerli kelimeler bonus olarak sepete eklenir ve rozet gösterilir', (WidgetTester tester) async {
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

      final WordWheelPuzzle puzzle = WordWheelPuzzle.forLevel(1);
      expect(puzzle.answers, isNotEmpty);
      expect(find.byType(WordWheelPlayPage), findsOneWidget);

      // Başlangıçta bonus rozeti henüz gösterilmez
      expect(find.byKey(const ValueKey<String>('word_wheel_bonus_badge')), findsNothing);
    });
  });
}
