import 'package:flutter/material.dart';

class AdvancedResultBanner extends StatelessWidget {
  final int score;
  final int previousBestScore;
  final bool english;
  final Color accentColor;

  const AdvancedResultBanner({
    super.key,
    required this.score,
    required this.previousBestScore,
    required this.english,
    required this.accentColor,
  });

  bool get _isFirstRecord => previousBestScore <= 0;
  bool get _isNewRecord => score > previousBestScore;
  bool get _isEqualRecord =>
      previousBestScore > 0 && score == previousBestScore;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = _isNewRecord || _isEqualRecord;
    final Color statusColor = _isNewRecord
        ? const Color(0xFFFFD334)
        : _isEqualRecord
            ? const Color(0xFF6CFF9B)
            : accentColor;

    final String title = _isNewRecord
        ? english
            ? 'NEW PERSONAL RECORD!'
            : 'YENİ KİŞİSEL REKOR!'
        : _isEqualRecord
            ? english
                ? 'RECORD MATCHED'
                : 'REKORUNU EŞİTLEDİN'
            : english
                ? 'PERSONAL BEST'
                : 'KİŞİSEL EN İYİ';

    final String description;
    if (_isNewRecord && _isFirstRecord) {
      description = english
          ? 'Your first score is now the target to beat.'
          : 'İlk puanın artık aşman gereken yeni hedef.';
    } else if (_isNewRecord) {
      final int improvement = score - previousBestScore;
      description = english
          ? '+$improvement points above your previous best.'
          : 'Önceki rekorundan +$improvement puan daha iyi.';
    } else if (_isEqualRecord) {
      description = english
          ? 'One more strong run can set a new record.'
          : 'Bir güçlü tur daha yeni rekoru getirebilir.';
    } else {
      final int remaining = previousBestScore - score;
      description = english
          ? '$remaining points left to reach your record.'
          : 'Rekoruna ulaşmak için $remaining puan kaldı.';
    }

    final int bestScore = score > previousBestScore
        ? score
        : previousBestScore;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0.94, end: 1),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: highlighted
                ? <Color>[
                    statusColor.withValues(alpha: 0.22),
                    statusColor.withValues(alpha: 0.07),
                  ]
                : <Color>[
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.035),
                  ],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: statusColor.withValues(
              alpha: highlighted ? 0.75 : 0.35,
            ),
          ),
          boxShadow: highlighted
              ? <BoxShadow>[
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: -7,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isNewRecord
                    ? Icons.workspace_premium_rounded
                    : _isEqualRecord
                        ? Icons.auto_awesome_rounded
                        : Icons.flag_rounded,
                color: statusColor,
                size: 25,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(
                minWidth: 58,
                maxWidth: 72,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$bestScore',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    english ? 'BEST' : 'REKOR',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
