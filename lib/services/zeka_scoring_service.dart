import 'unified_progress_service.dart';

/// Zeka Parkuru'nun tek ve adil puanlama kaynağıdır.
///
/// Oyunların kendi ham skorları yalnızca o oyundaki kişisel rekor için
/// saklanır. Lig, seviye, rozet ve dünya sıralaması ise burada hesaplanan
/// Zeka Puanı'nı kullanır. Böylece yüksek ham skor üreten bir oyun diğer
/// parkurlara karşı avantaj sağlamaz.
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

  static const int pointsPerCompletedLevel = 100;
  static const int pointsPerStar = 25;
  static const int pointsPerBoss = 250;
  static const int pointsPerPlayedCourse = 50;
  static const int pointsPerDailyCourse = 100;
  static const int pointsPerBestStreakDay = 20;
  static const int pointsPerPerfectDay = 50;
  static const int dailyCompletionBasePoints = 100;
  static const int dailyStarPoints = 50;

  // Günlük bonuslar ana parkur ilerlemesinin önüne geçmesin diye sınırlıdır.
  static const int dailyCourseBonusCap = 30;
  static const int streakBonusCap = 30;
  static const int perfectDayBonusCap = 30;

  static int courseScore(ParkurProgressData course) {
    final bool bossCompleted =
        course.yildizlar.length >= 10 && course.yildizlar[9] > 0;

    return (course.tamamlananSeviye * pointsPerCompletedLevel) +
        (course.toplamYildiz * pointsPerStar) +
        (bossCompleted ? pointsPerBoss : 0);
  }

  static ZekaScoreBreakdown calculate({
    required UnifiedProgressData progress,
    required int completedDailyCourses,
    required int bestStreak,
    required int perfectDays,
  }) {
    final int bossCount = progress.parkurlar
        .where(
          (course) =>
              course.yildizlar.length >= 10 && course.yildizlar[9] > 0,
        )
        .length;
    final int playedCourseCount = progress.parkurlar
        .where((course) => course.tamamlananSeviye > 0)
        .length;

    return ZekaScoreBreakdown(
      levelPoints:
          progress.tamamlananSeviye * pointsPerCompletedLevel,
      starPoints: progress.toplamYildiz * pointsPerStar,
      bossPoints: bossCount * pointsPerBoss,
      varietyPoints: playedCourseCount * pointsPerPlayedCourse,
      dailyCoursePoints:
          completedDailyCourses.clamp(0, dailyCourseBonusCap).toInt() *
              pointsPerDailyCourse,
      streakPoints: bestStreak.clamp(0, streakBonusCap).toInt() *
          pointsPerBestStreakDay,
      perfectDayPoints:
          perfectDays.clamp(0, perfectDayBonusCap).toInt() *
              pointsPerPerfectDay,
    );
  }

  /// Günlük görev ve günlük parkurda oyun türünden bağımsız sonuç puanı.
  static int dailyResultPoints(int stars) {
    final int safeStars = stars.clamp(0, 3).toInt();
    return dailyCompletionBasePoints + (safeStars * dailyStarPoints);
  }
}
