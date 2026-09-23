import 'dart:math';

import 'recent_content_store.dart';

class ContentCandidate<T> {
  final String family;
  final String fingerprint;
  final double difficulty;
  final T value;

  const ContentCandidate({
    required this.family,
    required this.fingerprint,
    required this.difficulty,
    required this.value,
  });
}

typedef ContentCandidateFactory<T> = ContentCandidate<T> Function(
  String family,
  Random random,
);

class SessionComposer<T> {
  final RecentContentStore history;

  SessionComposer({RecentContentStore? history})
    : history = history ?? RecentContentStore();

  Future<List<ContentCandidate<T>>> compose({
    required String gameId,
    required int level,
    required int count,
    required List<String> families,
    required Random random,
    required ContentCandidateFactory<T> build,
    double minimumDifficulty = 0,
    double maximumDifficulty = 1,
    int maxConsecutiveFamily = 2,
    int attemptLimitPerItem = 80,
  }) async {
    if (count <= 0 || families.isEmpty) return <ContentCandidate<T>>[];

    final Set<String> recent = await history.recentItems(
      gameId: gameId,
      level: level,
    );
    final Set<String> selectedFingerprints = <String>{};
    final List<ContentCandidate<T>> result = <ContentCandidate<T>>[];

    while (result.length < count) {
      ContentCandidate<T>? fallback;
      for (int attempt = 0; attempt < attemptLimitPerItem; attempt++) {
        final List<String> allowedFamilies = _allowedFamilies(
          families: families,
          selected: result,
          maxConsecutiveFamily: maxConsecutiveFamily,
        );
        final String family =
            allowedFamilies[random.nextInt(allowedFamilies.length)];
        final ContentCandidate<T> candidate = build(family, random);

        if (candidate.difficulty < minimumDifficulty ||
            candidate.difficulty > maximumDifficulty ||
            selectedFingerprints.contains(candidate.fingerprint)) {
          continue;
        }

        fallback ??= candidate;
        if (recent.contains(candidate.fingerprint)) continue;

        fallback = candidate;
        break;
      }

      if (fallback == null) {
        throw StateError(
          'Content session could not be composed for $gameId level $level.',
        );
      }

      result.add(fallback);
      selectedFingerprints.add(fallback.fingerprint);
    }

    await history.rememberItems(
      gameId: gameId,
      level: level,
      fingerprints: result.map((ContentCandidate<T> item) => item.fingerprint),
    );

    return result;
  }

  List<String> _allowedFamilies({
    required List<String> families,
    required List<ContentCandidate<T>> selected,
    required int maxConsecutiveFamily,
  }) {
    if (selected.length < maxConsecutiveFamily || maxConsecutiveFamily <= 0) {
      return families;
    }

    final String lastFamily = selected.last.family;
    final bool reachedLimit = selected.reversed
        .take(maxConsecutiveFamily)
        .every((ContentCandidate<T> item) => item.family == lastFamily);

    if (!reachedLimit) return families;
    final List<String> alternatives = families
        .where((String family) => family != lastFamily)
        .toList();
    return alternatives.isEmpty ? families : alternatives;
  }
}
