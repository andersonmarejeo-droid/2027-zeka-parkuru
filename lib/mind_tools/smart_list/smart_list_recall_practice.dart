import 'smart_list_models.dart';

/// Evaluates a voluntary, in-memory recall attempt without persisting answers.
class SmartListRecallResult {
  const SmartListRecallResult({
    required this.rememberedItems,
    required this.missedItems,
    required this.extraAnswerCount,
  });

  final List<SmartListItem> rememberedItems;
  final List<SmartListItem> missedItems;
  final int extraAnswerCount;

  int get rememberedCount => rememberedItems.length;
}

SmartListRecallResult evaluateSmartListRecall({
  required List<SmartListItem> expectedItems,
  required String response,
  bool turkishCaseRules = true,
}) {
  final Set<String> submitted = response
      .split(RegExp(r'[\r\n]+'))
      .map(
        (String answer) =>
            _normaliseRecallAnswer(answer, turkishCaseRules: turkishCaseRules),
      )
      .where((String answer) => answer.isNotEmpty)
      .toSet();
  final Set<String> expected = expectedItems
      .map(
        (SmartListItem item) => _normaliseRecallAnswer(
          item.text,
          turkishCaseRules: turkishCaseRules,
        ),
      )
      .toSet();
  final List<SmartListItem> remembered = <SmartListItem>[];
  final List<SmartListItem> missed = <SmartListItem>[];
  for (final SmartListItem item in expectedItems) {
    if (submitted.contains(
      _normaliseRecallAnswer(item.text, turkishCaseRules: turkishCaseRules),
    )) {
      remembered.add(item);
    } else {
      missed.add(item);
    }
  }
  return SmartListRecallResult(
    rememberedItems: List<SmartListItem>.unmodifiable(remembered),
    missedItems: List<SmartListItem>.unmodifiable(missed),
    extraAnswerCount: submitted.difference(expected).length,
  );
}

String _normaliseRecallAnswer(String value, {required bool turkishCaseRules}) {
  final String caseFolded = turkishCaseRules
      ? value.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase()
      : value.toLowerCase().replaceAll('İ', 'i').replaceAll('ı', 'i');
  return caseFolded
      .trim()
      .replaceAll(RegExp(r'[.,;:!?]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}
