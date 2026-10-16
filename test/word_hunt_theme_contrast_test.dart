import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/word_hunt/word_hunt_game_page.dart';
import 'package:zeka_parkuru/theme/studio_visuals.dart';

import 'test_preferences.dart';

double _contrastRatio(Color foreground, Color background) {
  final double lighter = math.max(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  final double darker = math.min(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  testWidgets('Kelime Avı hedef kelimeleri açık temada okunaklı kalır', (
    WidgetTester tester,
  ) async {
    const Color seed = Color(0xFF238F81);
    final ThemeData theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: WordHuntPlayPage(
          level: WordHuntGamePage.levels.first,
          previousBestScore: 0,
          fixedSessionSeed: 412,
        ),
      ),
    );
    await tester.pump();

    final Finder firstTarget = find.byWidgetPredicate((Widget widget) {
      final Key? key = widget.key;
      return key is ValueKey<String> && key.value.startsWith('word_target_');
    }).first;
    expect(firstTarget, findsOneWidget);

    final AnimatedContainer chip = tester.widget<AnimatedContainer>(
      firstTarget,
    );
    final BoxDecoration decoration = chip.decoration! as BoxDecoration;
    final Text target = tester.widget<Text>(
      find.descendant(of: firstTarget, matching: find.byType(Text)),
    );

    expect(decoration.color, theme.colorScheme.surface);
    expect(target.style?.color, theme.colorScheme.onSurface);
    expect(
      _contrastRatio(target.style!.color!, decoration.color!),
      greaterThanOrEqualTo(4.5),
    );

    final letters = find.byWidgetPredicate((Widget widget) {
      final Key? key = widget.key;
      return key is ValueKey<String> && key.value.startsWith('word_cell_');
    });
    expect(letters, findsWidgets);
    for (final element in letters.evaluate()) {
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byWidget(element.widget),
          matching: find.byType(Text),
        ),
      );
      expect(text.style!.color, StudioVisuals.ink);
      expect(
        _contrastRatio(text.style!.color!, StudioVisuals.surfaceSoft),
        greaterThanOrEqualTo(4.5),
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
