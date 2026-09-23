import 'package:shared_preferences/shared_preferences.dart';

enum PlayerAgeGroup {
  age6To8('6-8'),
  age9To12('9-12'),
  age13To17('13-17'),
  age18To40('18-40'),
  age40Plus('40+'),
  preferNotToSay('prefer_not_to_say');

  const PlayerAgeGroup(this.storageValue);

  final String storageValue;

  static PlayerAgeGroup? fromStorage(String? value) {
    for (final PlayerAgeGroup group in values) {
      if (group.storageValue == value) return group;
    }
    return null;
  }
}

enum PlayerGameGoal {
  haveFun('have_fun'),
  improveMind('improve_mind'),
  dailyExercise('daily_exercise'),
  competeWithFriends('compete_with_friends');

  const PlayerGameGoal(this.storageValue);

  final String storageValue;

  static PlayerGameGoal? fromStorage(String? value) {
    for (final PlayerGameGoal goal in values) {
      if (goal.storageValue == value) return goal;
    }
    return null;
  }
}

class OnboardingPreferences {
  const OnboardingPreferences({
    required this.ageGroup,
    required this.gameGoal,
    required this.completed,
  });

  final PlayerAgeGroup? ageGroup;
  final PlayerGameGoal? gameGoal;
  final bool completed;

  bool get isComplete => completed && ageGroup != null && gameGoal != null;
}

/// Stores only broad age range and game goal on this device.
///
/// These values are not included in scoring, leaderboards or Arena results.
class OnboardingPreferenceService {
  OnboardingPreferenceService._();

  static final OnboardingPreferenceService instance =
      OnboardingPreferenceService._();

  static const String _ageKey = 'zp_onboarding_age_v1';
  static const String _goalKey = 'zp_onboarding_goal_v1';
  static const String _completedKey = 'zp_onboarding_completed_v1';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<OnboardingPreferences> load() async {
    final String? savedAge = await _prefs.getString(_ageKey);
    final String? savedGoal = await _prefs.getString(_goalKey);
    final bool completed = await _prefs.getBool(_completedKey) ?? false;

    return OnboardingPreferences(
      ageGroup: PlayerAgeGroup.fromStorage(savedAge),
      gameGoal: PlayerGameGoal.fromStorage(savedGoal),
      completed: completed,
    );
  }

  Future<bool> isComplete() async => (await load()).isComplete;

  Future<void> save({
    required PlayerAgeGroup ageGroup,
    required PlayerGameGoal gameGoal,
  }) async {
    await _prefs.setString(_ageKey, ageGroup.storageValue);
    await _prefs.setString(_goalKey, gameGoal.storageValue);
    await _prefs.setBool(_completedKey, true);
  }
}
