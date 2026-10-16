import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/mind_tools/daily_dialogues/daily_dialogues_page.dart';
import 'package:zeka_parkuru/mind_tools/daily_dialogues/dialogue_content.dart';
import 'package:zeka_parkuru/mind_tools/daily_dialogues/dialogue_progress_store.dart';

import 'test_preferences.dart';

void main() {
  setUp(installTestPreferences);
  tearDown(uninstallTestPreferences);

  test('four bilingual conversation trees are connected and bounded', () {
    expect(
      DailyDialogueLibrary.scenarios
          .map((DialogueScenario value) => value.id)
          .toSet(),
      hasLength(4),
    );
    for (final DialogueScenario scenario in DailyDialogueLibrary.scenarios) {
      expect(scenario.steps.keys.toSet(), hasLength(scenario.steps.length));
      expect(scenario.steps[scenario.startStepId], isNotNull);
      final Set<String> reached = <String>{scenario.startStepId};
      final List<String> pending = <String>[scenario.startStepId];
      while (pending.isNotEmpty) {
        final DialogueStep step = scenario.steps[pending.removeLast()]!;
        for (final bool english in <bool>[false, true]) {
          if (!step.isEnding) {
            expect(step.otherPerson(english), isNotEmpty);
            expect(step.prompt(english), isNotEmpty);
            expect(step.options, hasLength(2));
          }
          for (final DialogueOption option in step.options) {
            expect(scenario.steps.containsKey(option.nextStepId), isTrue);
            expect(option.reply(english), isNotEmpty);
            expect(option.response(english), isNotEmpty);
            expect(option.coaching(english), isNotEmpty);
            expect(option.clarityPoints, inInclusiveRange(0, 2));
            if (reached.add(option.nextStepId)) pending.add(option.nextStepId);
          }
        }
      }
      expect(reached, hasLength(scenario.steps.length), reason: scenario.id);
      expect(
        scenario.steps.values.where((DialogueStep step) => step.isEnding),
        hasLength(2),
      );
    }
  });

  test(
    'progress stores only the best conversation clarity on device',
    () async {
      final DialogueProgressStore store = DialogueProgressStore();
      await store.recordCompletion('cafe_allergy', 2);
      await store.recordCompletion('station_directions', 3);
      await store.recordCompletion('cafe_allergy', 1);
      await store.recordCompletion('cafe_allergy', 4);
      expect(await DialogueProgressStore().loadBestClarity(), <String, int>{
        'cafe_allergy': 4,
        'station_directions': 3,
      });
      await expectLater(
        store.recordCompletion('cafe_allergy', 5),
        throwsRangeError,
      );
    },
  );

  testWidgets(
    '320×600 branching chat handles both turns and completes locally',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final DialogueProgressStore progress = DialogueProgressStore();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: DailyDialoguesPage(progressStore: progress),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Günlük konuşmalar'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('dialogue_scenario_cafe_allergy')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kafede açık sipariş'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('dialogue_choice_0')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('dialogue_choice_0')));
      await tester.pumpAndSettle();
      expect(find.textContaining('İçerik hassasiyetini'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey<String>('dialogue_practice_scroll')),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('dialogue_continue')));
      await tester.pumpAndSettle();
      expect(find.textContaining('çapraz temas'), findsWidgets);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('dialogue_choice_0')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('dialogue_choice_0')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey<String>('dialogue_practice_scroll')),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('dialogue_continue')));
      await tester.pumpAndSettle();
      expect(find.text('Konuşma tamamlandı'), findsOneWidget);
      expect(find.text('Netlik · 4 / 4'), findsOneWidget);
      expect(await progress.loadBestClarity(), <String, int>{
        'cafe_allergy': 4,
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('800×1280 English conversation card is actionable', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool opened = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: DailyDialoguesHomeCard(
            isEnglish: true,
            onTap: () => opened = true,
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('daily_dialogues_open')),
    );
    expect(opened, isTrue);
    expect(find.text('Daily Conversation Tasks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
