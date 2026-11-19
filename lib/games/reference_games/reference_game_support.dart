import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/studio_visuals.dart';

import '../../games/shared/parkur_game_kit.dart';

/// Reserves one of 300 deterministic variants for a game/level pair. The
/// cursor survives app restarts, so a replay does not immediately recycle a
/// board that was just seen.
abstract final class ReferenceRoundStore {
  static const int variantsPerLevel = 300;
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static Future<int> reserve({
    required String gameId,
    required int level,
  }) async {
    final String key = '${gameId}_variant_cursor_$level';
    final int cursor = await _preferences.getInt(key) ?? 0;
    await _preferences.setInt(key, cursor + 1);
    return cursor % variantsPerLevel;
  }

  static int seed(String gameId, int level, int variant) {
    int hash = 0x345678;
    for (final int code in gameId.codeUnits) {
      hash = ((hash * 1000003) ^ code) & 0x7fffffff;
    }
    return (hash + level * 65537 + variant * 104729) & 0x7fffffff;
  }
}

List<ParkurLevelSpec> referenceLevels({
  required String titleTr,
  required String titleEn,
  required IconData icon,
  required bool english,
}) => List<ParkurLevelSpec>.generate(10, (int index) {
  final int level = index + 1;
  final String difficulty = level <= 3
      ? (english ? 'FOUNDATION' : 'TEMEL')
      : level <= 6
      ? (english ? 'MASTERY' : 'USTALAÅMA')
      : level <= 8
      ? (english ? 'ADVANCED' : 'Ä°LERÄ°')
      : level == 9
      ? (english ? 'EXPERT' : 'UZMAN')
      : (english ? 'MASTER' : 'USTA');
  return ParkurLevelSpec(
    number: level,
    titleTr: '$titleTr ${level.toString().padLeft(2, '0')}',
    titleEn: '$titleEn ${level.toString().padLeft(2, '0')}',
    subtitleTr: level >= 9 ? 'UstalÄ±k parkuru' : 'Her bÃ¶lÃ¼mde yeni bir dÃ¼zen',
    subtitleEn: level >= 9 ? 'Master challenge' : 'A fresh layout every round',
    difficulty: difficulty,
    icon: icon,
  );
});

class ReferenceCard extends StatelessWidget {
  const ReferenceCard({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: StudioVisuals.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: StudioVisuals.line),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x0B263A35),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class ReferencePlayScaffold extends StatelessWidget {
  const ReferencePlayScaffold({
    super.key,
    required this.title,
    required this.level,
    required this.accent,
    required this.child,
    this.english = false,
    this.scrollable = true,
  });

  final String title;
  final int level;
  final Color accent;
  final Widget child;
  final bool english;
  final bool scrollable;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: StudioVisuals.canvas,
    appBar: AppBar(
      backgroundColor: StudioVisuals.canvas,
      surfaceTintColor: Colors.transparent,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${english ? 'LEVEL' : 'BÃ–LÃœM'} $level',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: scrollable
          ? SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
              child: child,
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: child,
            ),
    ),
  );
}

class ReferencePrimaryButton extends StatelessWidget {
  const ReferencePrimaryButton({
    super.key,
    required this.label,
    required this.accent,
    required this.onPressed,
    this.icon = Icons.check_rounded,
    this.enabled = true,
  });

  final String label;
  final Color accent;
  final VoidCallback onPressed;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          disabledBackgroundColor: accent.withValues(alpha: .28),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    ),
  );
}

String variantSignature(Iterable<Object> values) => values.join('|');

int mixedSeed(String namespace, int level, int variant) {
  final int base = ReferenceRoundStore.seed(namespace, level, variant);
  return Random(base).nextInt(0x7fffffff);
}
