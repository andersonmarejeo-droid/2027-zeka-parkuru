import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/pages/first_run_profile_page.dart';
import 'package:zeka_parkuru/services/app_experience_controller.dart';
import 'package:zeka_parkuru/services/onboarding_preference_service.dart';
import 'package:zeka_parkuru/theme/app_visual_theme.dart';

import 'test_preferences.dart';

void main() {
  setUpAll(installTestPreferences);
  setUp(resetTestPreferences);
  tearDownAll(uninstallTestPreferences);

  test('yalnızca kararlaştırılan yaş ve hedef seçenekleri kullanılır', () {
    expect(PlayerAgeGroup.values.map((group) => group.storageValue), <String>[
      '6-8',
      '9-12',
      '13-17',
      '18-40',
      '40+',
      'prefer_not_to_say',
    ]);
    expect(PlayerGameGoal.values.map((goal) => goal.storageValue), <String>[
      'have_fun',
      'improve_mind',
      'daily_exercise',
      'compete_with_friends',
    ]);
  });

  test(
    'ilk durumda profil tamamlanmamıştır; seçimler yerelde korunur',
    () async {
      final OnboardingPreferenceService service =
          OnboardingPreferenceService.instance;

      expect(await service.isComplete(), isFalse);

      await service.save(
        ageGroup: PlayerAgeGroup.age18To40,
        gameGoal: PlayerGameGoal.competeWithFriends,
      );

      final OnboardingPreferences saved = await service.load();
      expect(saved.isComplete, isTrue);
      expect(saved.ageGroup, PlayerAgeGroup.age18To40);
      expect(saved.gameGoal, PlayerGameGoal.competeWithFriends);
    },
  );

  testWidgets('320 px ekranda üç adımlı ilk kullanım akışı tamamlanır', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: <Locale>[Locale('tr'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: FirstRunProfilePage(
          destination: Scaffold(body: Center(child: Text('ANA SAYFA HAZIR'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('18-40'), findsOneWidget);
    await tester.ensureVisible(find.text('18-40'));
    await tester.tap(find.text('18-40'));
    await tester.pump();
    await tester.tap(find.text('DEVAM ET'));
    await tester.pumpAndSettle();

    expect(find.text('Arkadaşlarımla yarışmak istiyorum'), findsOneWidget);
    await tester.ensureVisible(find.text('Arkadaşlarımla yarışmak istiyorum'));
    await tester.tap(find.text('Arkadaşlarımla yarışmak istiyorum'));
    await tester.pump();
    await tester.tap(find.text('DEVAM ET'));
    await tester.pumpAndSettle();

    expect(find.text('Pembe Neon'), findsOneWidget);
    await tester.tap(find.text('Pembe Neon'));
    await tester.pump();
    await tester.tap(find.text('OYUNA BAŞLA'));
    await tester.pumpAndSettle();

    expect(find.text('ANA SAYFA HAZIR'), findsOneWidget);
    expect(
      AppExperienceController.instance.visualTheme,
      AppVisualTheme.pinkNeon,
    );
  });
}
