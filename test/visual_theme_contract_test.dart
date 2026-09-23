import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/theme/app_visual_theme.dart';

String _source(String relativePath) => File(relativePath).readAsStringSync();

void main() {
  group('Gorsel tema veri sozlesmesi', () {
    test('kayit degerleri kararlidir ve bilinmeyen deger klasige doner', () {
      expect(AppVisualTheme.classicNeon.storageValue, 'classic_neon');
      expect(AppVisualTheme.pinkNeon.storageValue, 'pink_neon');
      expect(AppVisualTheme.fromStorage('pink_neon'), AppVisualTheme.pinkNeon);
      expect(
        AppVisualTheme.fromStorage('bilinmeyen'),
        AppVisualTheme.classicNeon,
      );
      expect(AppVisualTheme.fromStorage(null), AppVisualTheme.classicNeon);
    });

    test('klasik tema mevcut renkleri birebir korur', () {
      const ZpVisualPalette palette = ZpVisualPalette.classic;

      expect(palette.background, const Color(0xFF07162E));
      expect(palette.surface, const Color(0xFF10274B));
      expect(palette.surfaceAlternative, const Color(0xFF0B1A31));
      expect(palette.primary, const Color(0xFF6C4DFF));
      expect(palette.secondary, const Color(0xFF00D9FF));
      expect(palette.onboardingBackground, const Color(0xFF000322));
      expect(palette.onboardingSurface, const Color(0xFF0D1941));
      expect(palette.onboardingAccent, const Color(0xFFFF7200));
      expect(palette.headerGradientEnd, const Color(0xFF34236F));
      expect(palette.homeHeaderGradientEnd, const Color(0xFF172F61));
      expect(palette.arenaGradientEnd, const Color(0xFF008DB2));
      expect(palette.gamePanelGradientEnd, const Color(0xFF0D3353));
    });

    test('pembe tema yalniz gorsel paleti degistirir', () {
      const ZpVisualPalette classic = ZpVisualPalette.classic;
      const ZpVisualPalette pink = ZpVisualPalette.pink;

      expect(pink.background, isNot(classic.background));
      expect(pink.surface, isNot(classic.surface));
      expect(pink.primary, isNot(classic.primary));
      expect(pink.secondary, isNot(classic.secondary));
      expect(pink.onboardingAccent, isNot(classic.onboardingAccent));
    });
  });

  group('Tema ekranlari kaynak sozlesmesi', () {
    test('ilk giris ve Ayarlar ayni tema seceneklerini kullanir', () {
      final String firstRun = _source('lib/pages/first_run_profile_page.dart');
      final String settings = _source('lib/pages/settings_page.dart');
      final String controller = _source(
        'lib/services/app_experience_controller.dart',
      );
      final String main = _source('lib/main.dart');

      expect(firstRun, contains('_ThemeStep'));
      expect(firstRun, contains('AppVisualTheme.pinkNeon'));
      expect(firstRun, contains('Pembe Neon'));
      expect(settings, contains('visual_theme_setting_'));
      expect(settings, contains('AppVisualTheme.pinkNeon'));
      expect(settings, contains('Mavi–Mor Neon'));
      expect(settings, contains('Pembe Neon'));
      expect(controller, contains("visualThemeKey = 'zp_visual_theme_v1'"));
      expect(main, contains('extensions: <ThemeExtension<dynamic>>'));
      expect(main, contains('experience.visualTheme'));
    });

    test('tema secimi cinsiyet verisi istemez', () {
      final String theme = _source('lib/theme/app_visual_theme.dart');
      final String firstRun = _source('lib/pages/first_run_profile_page.dart')
          .toLowerCase();

      expect(theme.toLowerCase(), isNot(contains('gender')));
      expect(firstRun, isNot(contains('cinsiyet')));
      expect(firstRun, isNot(contains('gender')));
    });
  });
}
