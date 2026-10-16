enum VocabularyReviewGrade { again, hard, good, easy }

class VocabularyCard {
  const VocabularyCard({
    required this.id,
    required this.word,
    required this.meaning,
    required this.example,
    required this.createdAt,
    required this.dueAt,
    required this.intervalDays,
    required this.reviewCount,
    this.lastReviewedAt,
  });

  final String id;
  final String word;
  final String meaning;
  final String example;
  final DateTime createdAt;
  final DateTime dueAt;
  final int intervalDays;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  bool isDueAt(DateTime date) => !dueAt.isAfter(date);

  VocabularyCard reviewed(VocabularyReviewGrade grade, {required DateTime at}) {
    final int nextInterval = switch (grade) {
      VocabularyReviewGrade.again => 0,
      VocabularyReviewGrade.hard =>
        intervalDays == 0 ? 1 : (intervalDays * 1.2).ceil().clamp(1, 3650),
      VocabularyReviewGrade.good =>
        intervalDays == 0
            ? 1
            : intervalDays == 1
            ? 3
            : (intervalDays * 2.1).round().clamp(1, 3650),
      VocabularyReviewGrade.easy =>
        intervalDays == 0 ? 3 : (intervalDays * 2.8).round().clamp(3, 3650),
    };
    final Duration delay = grade == VocabularyReviewGrade.again
        ? const Duration(minutes: 10)
        : Duration(days: nextInterval);
    return VocabularyCard(
      id: id,
      word: word,
      meaning: meaning,
      example: example,
      createdAt: createdAt,
      dueAt: at.add(delay),
      intervalDays: nextInterval,
      reviewCount: reviewCount + 1,
      lastReviewedAt: at,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'word': word,
    'meaning': meaning,
    'example': example,
    'createdAt': createdAt.toIso8601String(),
    'dueAt': dueAt.toIso8601String(),
    'intervalDays': intervalDays,
    'reviewCount': reviewCount,
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
  };

  factory VocabularyCard.fromJson(Map<String, Object?> json) {
    DateTime parseDate(Object? value, String field) {
      if (value is! String) throw FormatException('Missing $field date.');
      return DateTime.parse(value);
    }

    final String id = json['id'] as String? ?? '';
    final String word = json['word'] as String? ?? '';
    final String meaning = json['meaning'] as String? ?? '';
    if (id.isEmpty || word.trim().isEmpty || meaning.trim().isEmpty) {
      throw const FormatException('Vocabulary card is missing required text.');
    }
    final Object? interval = json['intervalDays'];
    final Object? count = json['reviewCount'];
    return VocabularyCard(
      id: id,
      word: word,
      meaning: meaning,
      example: json['example'] as String? ?? '',
      createdAt: parseDate(json['createdAt'], 'createdAt'),
      dueAt: parseDate(json['dueAt'], 'dueAt'),
      intervalDays: interval is int ? interval.clamp(0, 3650) : 0,
      reviewCount: count is int ? count.clamp(0, 1000000) : 0,
      lastReviewedAt: json['lastReviewedAt'] is String
          ? DateTime.tryParse(json['lastReviewedAt']! as String)
          : null,
    );
  }
}
