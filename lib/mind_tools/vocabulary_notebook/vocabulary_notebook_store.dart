import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'vocabulary_card.dart';

class VocabularyNotebookStore {
  VocabularyNotebookStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String storageKey = 'mind_tool_vocabulary_notebook_v1';
  static final math.Random _random = math.Random.secure();
  static int _idSequence = 0;

  final SharedPreferencesAsync _preferences;

  Future<List<VocabularyCard>> loadAll() async {
    final String? raw = await _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return <VocabularyCard>[];
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<Object?>) {
      throw const FormatException('Vocabulary notebook data must be a list.');
    }
    final List<VocabularyCard> cards = decoded.map((Object? item) {
      if (item is! Map<String, Object?>) {
        throw const FormatException('Invalid vocabulary card.');
      }
      return VocabularyCard.fromJson(item);
    }).toList();
    final Set<String> ids = <String>{};
    for (final VocabularyCard card in cards) {
      if (!ids.add(card.id)) {
        throw const FormatException('Duplicate vocabulary card identifier.');
      }
    }
    return cards;
  }

  Future<VocabularyCard> add({
    required String word,
    required String meaning,
    String example = '',
    DateTime? now,
  }) async {
    final DateTime created = now ?? DateTime.now();
    final String cleanWord = word.trim();
    final String cleanMeaning = meaning.trim();
    final String cleanExample = example.trim();
    _validateText(cleanWord, cleanMeaning);
    final List<VocabularyCard> cards = await loadAll();
    _ensureUnique(cards, cleanWord);
    final VocabularyCard card = VocabularyCard(
      id: '${created.microsecondsSinceEpoch}_${_idSequence++}_${_random.nextInt(1 << 32)}',
      word: cleanWord,
      meaning: cleanMeaning,
      example: cleanExample,
      createdAt: created,
      dueAt: created,
      intervalDays: 0,
      reviewCount: 0,
    );
    await _write(<VocabularyCard>[...cards, card]);
    return card;
  }

  Future<VocabularyCard> update({
    required String id,
    required String word,
    required String meaning,
    String example = '',
  }) async {
    final List<VocabularyCard> cards = await loadAll();
    final int index = cards.indexWhere((VocabularyCard card) => card.id == id);
    if (index < 0) throw StateError('Vocabulary card no longer exists.');
    final String cleanWord = word.trim();
    final String cleanMeaning = meaning.trim();
    _validateText(cleanWord, cleanMeaning);
    _ensureUnique(cards, cleanWord, exceptId: id);
    final VocabularyCard old = cards[index];
    final VocabularyCard updated = VocabularyCard(
      id: old.id,
      word: cleanWord,
      meaning: cleanMeaning,
      example: example.trim(),
      createdAt: old.createdAt,
      dueAt: old.dueAt,
      intervalDays: old.intervalDays,
      reviewCount: old.reviewCount,
      lastReviewedAt: old.lastReviewedAt,
    );
    cards[index] = updated;
    await _write(cards);
    return updated;
  }

  Future<void> delete(String id) async {
    final List<VocabularyCard> cards = await loadAll();
    cards.removeWhere((VocabularyCard card) => card.id == id);
    await _write(cards);
  }

  Future<VocabularyCard> recordReview(
    String id,
    VocabularyReviewGrade grade, {
    DateTime? now,
  }) async {
    final List<VocabularyCard> cards = await loadAll();
    final int index = cards.indexWhere((VocabularyCard card) => card.id == id);
    if (index < 0) throw StateError('Vocabulary card no longer exists.');
    final VocabularyCard reviewed = cards[index].reviewed(
      grade,
      at: now ?? DateTime.now(),
    );
    cards[index] = reviewed;
    await _write(cards);
    return reviewed;
  }

  Future<List<VocabularyCard>> dueCards({DateTime? now}) async {
    final DateTime date = now ?? DateTime.now();
    final List<VocabularyCard> due = (await loadAll())
        .where((VocabularyCard card) => card.isDueAt(date))
        .toList();
    due.sort((VocabularyCard a, VocabularyCard b) {
      final int dateOrder = a.dueAt.compareTo(b.dueAt);
      return dateOrder != 0
          ? dateOrder
          : a.word.toLowerCase().compareTo(b.word.toLowerCase());
    });
    return due;
  }

  Future<void> _write(List<VocabularyCard> cards) => _preferences.setString(
    storageKey,
    jsonEncode(cards.map((VocabularyCard card) => card.toJson()).toList()),
  );

  void _ensureUnique(
    List<VocabularyCard> cards,
    String word, {
    String? exceptId,
  }) {
    final String key = _normalise(word);
    if (cards.any(
      (VocabularyCard card) =>
          card.id != exceptId && _normalise(card.word) == key,
    )) {
      throw StateError('This word is already in the notebook.');
    }
  }

  String _normalise(String value) => value.trim().toLowerCase();

  void _validateText(String word, String meaning) {
    if (word.isEmpty || meaning.isEmpty) {
      throw ArgumentError('Both a word and its meaning are required.');
    }
  }
}
