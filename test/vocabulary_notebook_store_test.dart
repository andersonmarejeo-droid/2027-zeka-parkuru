import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/mind_tools/vocabulary_notebook/vocabulary_card.dart';
import 'package:zeka_parkuru/mind_tools/vocabulary_notebook/vocabulary_notebook_store.dart';

import 'test_preferences.dart';

void main() {
  late VocabularyNotebookStore store;

  setUp(() {
    installTestPreferences();
    store = VocabularyNotebookStore();
  });

  tearDown(uninstallTestPreferences);

  group('Vocabulary notebook local review store', () {
    final DateTime start = DateTime(2026, 9, 1, 9);

    test(
      'persists user-created word, meaning, example and due date locally',
      () async {
        final VocabularyCard added = await store.add(
          word: '  sonder  ',
          meaning: 'anlamı başka bir dilde olmayan özel bir sözcük',
          example: 'Bu kavramı not defterime yazdım.',
          now: start,
        );
        final List<VocabularyCard> loaded = await VocabularyNotebookStore()
            .loadAll();

        expect(loaded, hasLength(1));
        expect(loaded.single.id, added.id);
        expect(loaded.single.word, 'sonder');
        expect(loaded.single.meaning, contains('özel'));
        expect(loaded.single.example, contains('not defterime'));
        expect(loaded.single.dueAt, start);
        expect(loaded.single.reviewCount, 0);
      },
    );

    test(
      'requires both fields and rejects case-insensitive duplicates',
      () async {
        await expectLater(
          store.add(word: ' ', meaning: 'Anlam', now: start),
          throwsArgumentError,
        );
        await store.add(
          word: 'Resilience',
          meaning: 'dayanıklılık',
          now: start,
        );
        await expectLater(
          store.add(word: ' resilience ', meaning: 'başka anlam', now: start),
          throwsStateError,
        );
        expect(await store.loadAll(), hasLength(1));
      },
    );

    test(
      'again, hard, good and easy schedule spaced recalls independently',
      () async {
        final VocabularyCard added = await store.add(
          word: 'laconic',
          meaning: 'az ve öz konuşan',
          now: start,
        );

        final VocabularyCard again = await store.recordReview(
          added.id,
          VocabularyReviewGrade.again,
          now: start,
        );
        expect(again.dueAt, start.add(const Duration(minutes: 10)));
        expect(again.intervalDays, 0);

        final VocabularyCard hard = await store.recordReview(
          added.id,
          VocabularyReviewGrade.hard,
          now: start.add(const Duration(minutes: 10)),
        );
        expect(hard.intervalDays, 1);
        expect(hard.dueAt, start.add(const Duration(days: 1, minutes: 10)));

        final VocabularyCard good = await store.recordReview(
          added.id,
          VocabularyReviewGrade.good,
          now: hard.dueAt,
        );
        expect(good.intervalDays, 3);
        expect(good.reviewCount, 3);

        final VocabularyCard easy = await store.recordReview(
          added.id,
          VocabularyReviewGrade.easy,
          now: good.dueAt,
        );
        expect(easy.intervalDays, greaterThan(good.intervalDays));
        expect(easy.dueAt, good.dueAt.add(Duration(days: easy.intervalDays)));
        expect(await store.dueCards(now: good.dueAt), isEmpty);
        expect(await store.dueCards(now: easy.dueAt), hasLength(1));
      },
    );

    test(
      'edit keeps review history and delete removes only the selected word',
      () async {
        final VocabularyCard first = await store.add(
          word: 'lucid',
          meaning: 'açık',
          now: start,
        );
        final VocabularyCard second = await store.add(
          word: 'nimble',
          meaning: 'çevik',
          now: start.add(const Duration(seconds: 1)),
        );
        final VocabularyCard reviewed = await store.recordReview(
          first.id,
          VocabularyReviewGrade.good,
          now: start,
        );
        final VocabularyCard edited = await store.update(
          id: first.id,
          word: 'lucidly',
          meaning: 'açık ve anlaşılır biçimde',
          example: 'Cevabı lucidly anlattı.',
        );

        expect(edited.reviewCount, reviewed.reviewCount);
        expect(edited.dueAt, reviewed.dueAt);
        expect(edited.word, 'lucidly');
        await store.delete(second.id);
        expect(
          (await store.loadAll()).map((VocabularyCard card) => card.id),
          <String>[first.id],
        );
      },
    );
  });
}
