import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_analytics_service.dart';

enum AppLanguageMode {
  system,
  turkish,
  english,
  arabic,
  indonesian,
  brazilianPortuguese,
  spanish,
  french,
  german,
}

class AppLanguageController extends ChangeNotifier {
  AppLanguageController._();

  static final AppLanguageController instance = AppLanguageController._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const String _languageKey = 'app_language_v1';

  AppLanguageMode _mode = AppLanguageMode.system;

  AppLanguageMode get mode => _mode;

  Locale get resolvedLocale {
    switch (_mode) {
      case AppLanguageMode.turkish:
        return const Locale('tr');
      case AppLanguageMode.english:
        return const Locale('en');
      case AppLanguageMode.arabic:
        return const Locale('ar');
      case AppLanguageMode.indonesian:
        return const Locale('id');
      case AppLanguageMode.brazilianPortuguese:
        return const Locale('pt', 'BR');
      case AppLanguageMode.spanish:
        return const Locale('es');
      case AppLanguageMode.french:
        return const Locale('fr');
      case AppLanguageMode.german:
        return const Locale('de');
      case AppLanguageMode.system:
        final String code = PlatformDispatcher.instance.locale.languageCode
            .toLowerCase();
        switch (code) {
          case 'tr':
          case 'en':
          case 'ar':
          case 'id':
          case 'es':
          case 'fr':
          case 'de':
            return Locale(code);
          case 'pt':
            return const Locale('pt', 'BR');
          default:
            return const Locale('en');
        }
    }
  }

  Future<void> init() async {
    final String? saved = await _prefs.getString(_languageKey);

    _mode = switch (saved) {
      'tr' => AppLanguageMode.turkish,
      'en' => AppLanguageMode.english,
      'ar' => AppLanguageMode.arabic,
      'id' => AppLanguageMode.indonesian,
      'pt-BR' => AppLanguageMode.brazilianPortuguese,
      'es' => AppLanguageMode.spanish,
      'fr' => AppLanguageMode.french,
      'de' => AppLanguageMode.german,
      _ => AppLanguageMode.system,
    };

    notifyListeners();
  }

  Future<void> setMode(AppLanguageMode mode) async {
    if (_mode == mode) return;

    _mode = mode;

    final String stored = switch (mode) {
      AppLanguageMode.system => 'system',
      AppLanguageMode.turkish => 'tr',
      AppLanguageMode.english => 'en',
      AppLanguageMode.arabic => 'ar',
      AppLanguageMode.indonesian => 'id',
      AppLanguageMode.brazilianPortuguese => 'pt-BR',
      AppLanguageMode.spanish => 'es',
      AppLanguageMode.french => 'fr',
      AppLanguageMode.german => 'de',
    };

    await _prefs.setString(_languageKey, stored);
    notifyListeners();

    await AppAnalyticsService.instance.logLanguageChange(
      resolvedLocale.languageCode,
    );
  }
}
