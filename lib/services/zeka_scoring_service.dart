import 'unified_progress_service.dart';

/// Zeka Parkuru'nun tek ve adil puanlama kaynağıdır.
///
/// Oyunların kendi ham skorları yalnızca o oyundaki kişisel rekor için
/// saklanır. Genel puan yalnızca ortak bölüm puanlarının toplamıdır.
class ZekaScoreBreakdown {
  final int levelPoints;
  final int starPoints;
  final int bossPoints;
  final int varietyPoints;
  final int dailyCoursePoints;
  final int streakPoints;
  final int perfectDayPoints;

  const ZekaScoreBreakdown({
    required this.levelPoints,
    required this.starPoints,
    required this.bossPoints,
    required this.varietyPoints,
    required this.dailyCoursePoints,
    required this.streakPoints,
    required this.perfectDayPoints,
  });

  int get total =>
      levelPoints +
      starPoints +
      bossPoints +
      varietyPoints +
      dailyCoursePoints +
      streakPoints +
      perfectDayPoints;
}

class ZekaScoringService {
  ZekaScoringService._();

  static const int pointsPerCompletedLevel = 10;
  static const int dailyCompletionBasePoints = 100;
  static const int dailyStarPoints = 50;

  static int courseScore(ParkurProgressData course) {
    return course.toplamOrtakPuan;
  }

  static ZekaScoreBreakdown calculate({required UnifiedProgressData progress}) {
    return ZekaScoreBreakdown(
      levelPoints: progress.toplamOrtakPuan,
      starPoints: 0,
      bossPoints: 0,
      varietyPoints: 0,
      dailyCoursePoints: 0,
      streakPoints: 0,
      perfectDayPoints: 0,
    );
  }

  /// Günlük görev ve günlük parkurda oyun türünden bağımsız sonuç puanı.
  static int dailyResultPoints(int stars) {
    final int safeStars = stars.clamp(0, 3).toInt();
    return dailyCompletionBasePoints + (safeStars * dailyStarPoints);
  }
}
