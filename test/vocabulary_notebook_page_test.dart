import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/mind_tools/vocabulary_notebook/vocabulary_notebook_page.dart';

import 'test_preferences.dart';

void main() {
  setUp(installTestPreferences);
  tearDown(uninstallTestPreferences);

  testWidgets(
    '320×600 adds a word, recalls it, and schedules the next review',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: VocabularyNotebookPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kelime defteri'), findsOneWidget);
      expect(find.text('Kendi kelime koleksiyonunu oluştur'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('vocabulary_add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('vocabulary_word_field')),
        'sonder',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('vocabulary_meaning_field')),
        'başka insanların da derin bir hayatı olduğunu fark etmek',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('vocabulary_example_field')),
        'Pencereden bakarken bu duyguyu yaşadı.',
      );
      await tester.tap(find.byKey(const ValueKey<String>('vocabulary_save')));
      await tester.pumpAndSettle();

      expect(find.text('sonder'), findsOneWidget);
      expect(find.text('1 kelime tekrar için hazır'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('vocabulary_review_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hatırlama turu'), findsOneWidget);
      expect(find.text('sonder'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('vocabulary_reveal')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey<String>('vocabulary_reveal')));
      await tester.pumpAndSettle();
      expect(find.textContaining('başka insanların'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('vocabulary_grade_good')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('vocabulary_grade_good')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tekrar tamamlandı'), findsOneWidget);
      await tester.tap(find.text('Deftere dön'));
      await tester.pumpAndSettle();
      expect(find.text('0 kelime tekrar için hazır'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('800×1280 entry card opens the local-first notebook', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: VocabularyNotebookHomeCard(
            isEnglish: true,
            onTap: () => tester
                .element(find.byType(Scaffold))
                .findAncestorStateOfType<NavigatorState>()!
                .push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const VocabularyNotebookPage(),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('vocabulary_notebook_open')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vocabulary notebook'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
