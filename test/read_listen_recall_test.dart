import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/mind_tools/read_listen_recall/read_listen_recall_page.dart';
import 'package:zeka_parkuru/mind_tools/read_listen_recall/reader_content.dart';
import 'package:zeka_parkuru/mind_tools/read_listen_recall/reader_progress_store.dart';

import 'test_preferences.dart';

void main() {
  setUp(installTestPreferences);
  tearDown(uninstallTestPreferences);

  test(
    'completion schedules local delayed recall and successful recall widens it',
    () async {
      final ReaderProgressStore progress = ReaderProgressStore();
      final DateTime completedAt = DateTime.utc(2026, 9, 1, 9);
      await progress.markCompleted('fog_lantern', now: completedAt);

      expect(await progress.dueReviews(now: completedAt), isEmpty);
      final DateTime firstDue = completedAt.add(const Duration(days: 1));
      expect(await progress.dueReviews(now: firstDue), hasLength(1));

      final ReaderReviewSchedule updated = await progress.recordReview(
        storyId: 'fog_lantern',
        rememberedAll: true,
        now: firstDue,
      );
      expect(updated.intervalDays, 3);
      expect(updated.reviewCount, 1);
      expect(updated.dueAt, firstDue.add(const Duration(days: 3)));
      expect(
        await progress.dueReviews(now: firstDue.add(const Duration(days: 2))),
        isEmpty,
      );
    },
  );

  test('a missed delayed recall keeps the next interval short', () async {
    final ReaderProgressStore progress = ReaderProgressStore();
    final DateTime completedAt = DateTime.utc(2026, 9, 1, 9);
    await progress.markCompleted('market_route', now: completedAt);
    final DateTime reviewAt = completedAt.add(const Duration(days: 1));

    final ReaderReviewSchedule updated = await progress.recordReview(
      storyId: 'market_route',
      rememberedAll: false,
      now: reviewAt,
    );
    expect(updated.intervalDays, 1);
    expect(updated.dueAt, reviewAt.add(const Duration(days: 1)));
  });

  test(
    'older completed passages receive an immediate local review slot',
    () async {
      final ReaderProgressStore progress = ReaderProgressStore();
      final DateTime now = DateTime.utc(2026, 9, 1, 9);

      final Map<String, ReaderReviewSchedule> schedules = await progress
          .ensureReviewSchedulesFor(<String>{'older_story'}, now: now);

      expect(schedules['older_story']?.dueAt, now);
      expect(await progress.dueReviews(now: now), hasLength(1));
    },
  );

  test('five original bilingual passages carry grounded recall questions', () {
    expect(
      RecallArticleLibrary.articles.map((article) => article.id).toSet(),
      hasLength(5),
    );
    for (final RecallArticle article in RecallArticleLibrary.articles) {
      expect(article.bodyTr.length, greaterThan(400));
      expect(article.bodyEn.length, greaterThan(400));
      for (final bool english in <bool>[false, true]) {
        final List<RecallQuestion> questions = article.questions(english);
        expect(questions, hasLength(2));
        for (final RecallQuestion question in questions) {
          expect(question.options, hasLength(3));
          expect(question.correctIndex, inInclusiveRange(0, 2));
          expect(question.evidence, isNotEmpty);
        }
      }
    }
  });

  testWidgets(
    '320×600 can read, fall back from missing speech, and recall from evidence',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ReaderProgressStore progress = ReaderProgressStore();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: ReadListenRecallPage(progressStore: progress),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Oku · Dinle · Hatırla'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('reader_article_fog_lantern')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sisli kıyıda üç ışık'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey<String>('reader_play_audio')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('reader_play_audio')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Kıyı kasabasının fener sorumlusu'),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const ValueKey<String>('reader_story_scroll')),
        const Offset(0, -1800),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('reader_answer_1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bir daha düşün.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('reader_answer_0')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey<String>('reader_story_scroll')),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('reader_continue')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Cem deftere hangi iki sütunu ekledi?'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('reader_answer_1')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey<String>('reader_story_scroll')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('reader_continue')));
      await tester.pumpAndSettle();
      expect(find.text('Metin akılda kaldı'), findsOneWidget);
      expect(await progress.completedStoryIds(), contains('fog_lantern'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('due review asks from memory before exposing the passage', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ReaderProgressStore progress = ReaderProgressStore();
    await progress.markCompleted(
      'fog_lantern',
      now: DateTime.now().subtract(const Duration(days: 2)),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ReadListenRecallPage(progressStore: progress),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('reader_review_fog_lantern')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('reader_review_fog_lantern')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gecikmeli hatırlama'), findsOneWidget);
    expect(find.text(RecallArticleLibrary.articles.first.bodyTr), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('reader_review_answer_0')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('reader_review_continue')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('reader_review_continue')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('reader_review_answer_1')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('reader_review_continue')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('reader_review_continue')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hatırlama turu tamamlandı'), findsOneWidget);
    final ReaderReviewSchedule schedule = (await progress
        .reviewSchedules())['fog_lantern']!;
    expect(schedule.intervalDays, 3);
    expect(schedule.reviewCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('800×1280 reader home card is actionable', (
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
          body: ReadListenRecallHomeCard(
            isEnglish: true,
            onTap: () => opened = true,
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('read_listen_recall_open')),
    );
    expect(opened, isTrue);
    expect(find.textContaining('Micro-stories'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
