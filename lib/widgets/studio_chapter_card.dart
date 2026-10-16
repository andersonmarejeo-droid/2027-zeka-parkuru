import 'package:flutter/material.dart';

import '../games/shared/game_visual_design.dart';
import '../theme/studio_game_visuals.dart';
import '../l10n/app_localizations.dart';
import '../theme/studio_visuals.dart';
import 'studio_game_artwork.dart';

/// Compact, consistent chapter card for legacy game hubs.
class StudioChapterCard extends StatelessWidget {
  const StudioChapterCard({
    super.key,
    required this.gameId,
    required this.number,
    required this.title,
    required this.detail,
    required this.difficulty,
    required this.unlocked,
    required this.stars,
    required this.onTap,
    this.best = 0,
  });

  final String gameId;
  final int number;
  final String title;
  final String detail;
  final String difficulty;
  final bool unlocked;
  final int stars;
  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = GameVisualDesign.forGame(gameId).accent;
    return Semantics(
      button: true,
      enabled: unlocked,
      label: '$number. $title. $detail',
      child: Material(
        color: Colors.transparent,
        borderRadius: StudioVisuals.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: unlocked ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: StudioGameVisuals.cardDecoration(
              accent: accent,
              disabled: !unlocked,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width < 360 ? 68 : 78,
                  height: 74,
                  child: StudioGameArtwork(
                    gameId: gameId,
                    locked: !unlocked,
                    variant: number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.gameUi(difficulty),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$number. ${context.l10n.gameUi(title)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: StudioVisuals.ink,
                          fontSize: 14,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.gameUi(
                          unlocked
                              ? detail
                              : (context.l10n.isEnglish
                                    ? 'Complete the previous chapter.'
                                    : 'Önceki bölümü tamamla.'),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: StudioVisuals.muted,
                          fontSize: 10,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < 3; i++)
                                Icon(
                                  i < stars
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 15,
                                  color: i < stars
                                      ? StudioVisuals.amberInk
                                      : StudioVisuals.muted,
                                ),
                            ],
                          ),
                          if (best > 0)
                            Text(
                              '$best',
                              style: const TextStyle(
                                color: StudioVisuals.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
