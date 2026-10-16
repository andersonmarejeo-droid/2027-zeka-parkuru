import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/theme/app_visual_theme.dart';
import 'package:zeka_parkuru/theme/studio_visuals.dart';

String _source(String relativePath) => File(relativePath).readAsStringSync();

void main() {
  group('Tek tema sozlesmesi', () {
    test('uygulamada yalniz Zihin Bahcesi temasi secilebilir', () {
      expect(AppVisualTheme.values, <AppVisualTheme>[
        AppVisualTheme.studioGarden,
      ]);
      expect(AppVisualTheme.studioGarden.storageValue, 'studio_garden');
      expect(
        AppVisualTheme.fromStorage('studio_garden'),
        AppVisualTheme.studioGarden,
      );
      expect(
        AppVisualTheme.fromStorage('classic_neon'),
        AppVisualTheme.studioGarden,
      );
      expect(
        AppVisualTheme.fromStorage('pink_neon'),
        AppVisualTheme.studioGarden,
      );
      expect(
        AppVisualTheme.fromStorage('bilinmeyen'),
        AppVisualTheme.studioGarden,
      );
      expect(AppVisualTheme.fromStorage(null), AppVisualTheme.studioGarden);
    });

    test('bahce paleti acik yuzeyleri ve teal vurguyu korur', () {
      const ZpVisualPalette palette = ZpVisualPalette.garden;

      expect(palette.background, const Color(0xFFF6F8F6));
      expect(palette.surface, Colors.white);
      expect(palette.primary, const Color(0xFF238F81));
      expect(ZpVisualPalette.forTheme(AppVisualTheme.studioGarden), palette);
      expect(StudioVisuals.canvas, palette.background);
      expect(StudioVisuals.teal, palette.primary);
      expect(StudioVisuals.amber, palette.secondary);
      expect(palette.onboardingBackground, palette.background);
      expect(palette.onboardingSurface, palette.surface);
      expect(palette.onboardingAccent, palette.primary);
      expect(StudioVisuals.pageGutter, 20);
      expect(StudioVisuals.cardMinTapHeight, greaterThanOrEqualTo(88));
      expect(StudioVisuals.cardRadius, BorderRadius.circular(22));
    });

    test('erisebilirlik icin yuksek kontrast paleti korunur', () {
      expect(ZpVisualPalette.highContrast.background, const Color(0xFF07162E));
      expect(ZpVisualPalette.highContrast.primary, const Color(0xFF6C4DFF));
    });
  });

  group('Tema secenegi ekrandan kaldirildi', () {
    test('Ayarlar ve ilk kurulum alternatif tema sunmaz', () {
      final String firstRun = _source('lib/pages/first_run_profile_page.dart');
      final String settings = _source('lib/pages/settings_page.dart');
      final String controller = _source(
        'lib/services/app_experience_controller.dart',
      );

      expect(firstRun, contains('AppVisualTheme.studioGarden'));
      expect(firstRun, isNot(contains('_ThemeStep')));
      expect(firstRun, isNot(contains('Renk temanı seç')));
      expect(settings, isNot(contains('visual_theme_setting_')));
      expect(settings, isNot(contains('Mavi–Mor Neon')));
      expect(settings, isNot(contains('Pembe Neon')));
      expect(controller, contains("visualThemeKey = 'zp_visual_theme_v1'"));
      expect(controller, contains('AppVisualTheme.studioGarden'));
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
