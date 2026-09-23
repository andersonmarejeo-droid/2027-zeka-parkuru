import 'dart:math';

import 'package:flutter/material.dart';

class CompetitionStageTransition {
  const CompetitionStageTransition._();

  static Future<void> show(
    BuildContext context, {
    required int completedCount,
    required int totalCount,
    required int stars,
    required int score,
    required String flowName,
    String? nextGameName,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Yarışma geçişi',
      barrierColor: const Color(0xD907162E),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => _CompetitionStageTransitionCard(
        completedCount: completedCount,
        totalCount: totalCount,
        stars: stars,
        score: score,
        flowName: flowName,
        nextGameName: nextGameName,
      ),
      transitionBuilder: (_, Animation<double> animation, _, Widget child) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }
}

class _CompetitionStageTransitionCard extends StatefulWidget {
  final int completedCount;
  final int totalCount;
  final int stars;
  final int score;
  final String flowName;
  final String? nextGameName;

  const _CompetitionStageTransitionCard({
    required this.completedCount,
    required this.totalCount,
    required this.stars,
    required this.score,
    required this.flowName,
    required this.nextGameName,
  });

  @override
  State<_CompetitionStageTransitionCard> createState() =>
      _CompetitionStageTransitionCardState();
}

class _CompetitionStageTransitionCardState
    extends State<_CompetitionStageTransitionCard> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 950), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool successful = widget.stars > 0 || widget.score > 0;
    final bool finished = widget.completedCount >= widget.totalCount;
    final Color accent = successful
        ? const Color(0xFF6CFF9B)
        : const Color(0xFFFFB44A);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Container(
            width: min(MediaQuery.sizeOf(context).width - 36, 430.0),
            margin: const EdgeInsets.all(18),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF173B69), Color(0xFF31215D)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: accent, width: 1.6),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 34,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  finished
                      ? Icons.emoji_events_rounded
                      : successful
                      ? Icons.check_circle_rounded
                      : Icons.flag_circle_rounded,
                  color: accent,
                  size: 54,
                ),
                const SizedBox(height: 10),
                Text(
                  finished
                      ? '${widget.flowName} TAMAMLANDI'
                      : successful
                      ? 'BÖLÜM TAMAMLANDI'
                      : 'BÖLÜM KAYDEDİLDİ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.completedCount}/${widget.totalCount}  •  '
                  '${widget.stars.clamp(0, 3)} ★  •  ${widget.score} puan',
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!finished && widget.nextGameName != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Sırada: ${widget.nextGameName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
