import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_visual_theme.dart';

enum AppAnimationIntensity {
  system('system'),
  full('full'),
  balanced('balanced'),
  reduced('reduced');

  const AppAnimationIntensity(this.storageValue);

  final String storageValue;

  static AppAnimationIntensity fromStorage(String? value) {
    for (final AppAnimationIntensity intensity in values) {
      if (intensity.storageValue == value) return intensity;
    }
    return AppAnimationIntensity.system;
  }
}

/// Device-only visual and accessibility preferences.
///
/// These values never enter scoring, leaderboards, Firebase or Arena data.
class AppExperienceController extends ChangeNotifier {
  AppExperienceController._();

  static final AppExperienceController instance = AppExperienceController._();

  static const String animationKey = 'zp_animation_intensity_v1';
  static const String highContrastKey = 'zp_high_contrast_v1';
  static const String largeTextKey = 'zp_large_text_v1';
  static const String visualThemeKey = 'zp_visual_theme_v1';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  AppAnimationIntensity _animationIntensity = AppAnimationIntensity.system;
  bool _highContrast = false;
  bool _largeText = false;
  AppVisualTheme _visualTheme = AppVisualTheme.studioGarden;

  Future<void>? _initializing;

  AppAnimationIntensity get animationIntensity => _animationIntensity;
  bool get highContrast => _highContrast;
  bool get largeText => _largeText;
  AppVisualTheme get visualTheme => _visualTheme;

  Future<void> init() => _initializing ??= _load();

  Future<void> _load() async {
    final List<Object?> values = await Future.wait<Object?>(<Future<Object?>>[
      _prefs.getString(animationKey),
      _prefs.getBool(highContrastKey),
      _prefs.getBool(largeTextKey),
      _prefs.getString(visualThemeKey),
    ]);

    _animationIntensity = AppAnimationIntensity.fromStorage(
      values[0] as String?,
    );
    _highContrast = values[1] as bool? ?? false;
    _largeText = values[2] as bool? ?? false;
    _visualTheme = AppVisualTheme.fromStorage(values[3] as String?);
    if (values[3] != _visualTheme.storageValue) {
      await _prefs.setString(visualThemeKey, _visualTheme.storageValue);
    }
    notifyListeners();
  }

  bool reduceMotion({required bool systemRequestsReducedMotion}) {
    return switch (_animationIntensity) {
      AppAnimationIntensity.reduced => true,
      AppAnimationIntensity.system => systemRequestsReducedMotion,
      AppAnimationIntensity.full || AppAnimationIntensity.balanced => false,
    };
  }

  double get animationScale => switch (_animationIntensity) {
    AppAnimationIntensity.reduced => 0,
    AppAnimationIntensity.balanced => 0.72,
    AppAnimationIntensity.system || AppAnimationIntensity.full => 1,
  };

  Future<void> setAnimationIntensity(AppAnimationIntensity value) async {
    if (_animationIntensity == value) return;
    _animationIntensity = value;
    notifyListeners();
    await _prefs.setString(animationKey, value.storageValue);
  }

  Future<void> setHighContrast(bool value) async {
    if (_highContrast == value) return;
    _highContrast = value;
    notifyListeners();
    await _prefs.setBool(highContrastKey, value);
  }

  Future<void> setLargeText(bool value) async {
    if (_largeText == value) return;
    _largeText = value;
    notifyListeners();
    await _prefs.setBool(largeTextKey, value);
  }

  Future<void> setVisualTheme(AppVisualTheme value) async {
    if (_visualTheme != value) {
      _visualTheme = value;
      notifyListeners();
    }
    await _prefs.setString(visualThemeKey, value.storageValue);
  }

  Future<void> resetDefaults() async {
    _animationIntensity = AppAnimationIntensity.system;
    _highContrast = false;
    _largeText = false;
    _visualTheme = AppVisualTheme.studioGarden;
    notifyListeners();

    await Future.wait<void>(<Future<void>>[
      _prefs.setString(animationKey, AppAnimationIntensity.system.storageValue),
      _prefs.setBool(highContrastKey, false),
      _prefs.setBool(largeTextKey, false),
      _prefs.setString(
        visualThemeKey,
        AppVisualTheme.studioGarden.storageValue,
      ),
    ]);
  }
}
