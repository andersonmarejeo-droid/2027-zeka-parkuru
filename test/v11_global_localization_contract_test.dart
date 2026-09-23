import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/word_hunt/word_hunt_locale_data.dart';
import 'package:zeka_parkuru/l10n/app_localizations.dart';
import 'package:zeka_parkuru/services/app_language_controller.dart';

void main() {
  const List<Locale> globalLocales = <Locale>[
    Locale('ar'),
    Locale('id'),
    Locale('pt', 'BR'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
  ];

  test('the application exposes exactly eight supported languages', () {
    expect(AppLocalizations.supportedLocales, const <Locale>[
      Locale('tr'),
      Locale('en'),
      Locale('ar'),
      Locale('id'),
      Locale('pt', 'BR'),
      Locale('es'),
      Locale('fr'),
      Locale('de'),
    ]);
    expect(AppLanguageMode.values.length, 9);
  });

  test('each new locale translates the critical application surface', () {
    for (final Locale locale in globalLocales) {
      final AppLocalizations l10n = GlobalAppLocalizations(locale);

      expect(l10n.isEnglish, isTrue, reason: '${locale.languageCode} fallback');
      expect(l10n.settingsTitle, isNot('SETTINGS'));
      expect(l10n.coursesTitle, isNot('COURSES'));
      expect(l10n.dailyChallenges, isNot('DAILY CHALLENGES'));
      expect(l10n.leaderboardCenter, isNot('LEADERBOARD CENTER'));
      expect(l10n.profileTitle, isNot('PROFILE'));
      expect(l10n.gameTitle('logic'), isNot('Logic Maze'));
      expect(l10n.gameTitle('word_hunt'), isNot('Word Hunt'));
      expect(l10n.gameUi('KOLAY'), isNot(anyOf('KOLAY', 'EASY')));
      expect(l10n.gameUi('NEW BOARD'), isNot('NEW BOARD'));
    }
  });

  test('missing rare copy falls back to English and never Turkish', () {
    const String rareCopy = 'A future game-specific sentence.';

    for (final Locale locale in globalLocales) {
      final AppLocalizations l10n = GlobalAppLocalizations(locale);
      expect(l10n.gameUi(rareCopy), rareCopy);
    }
  });

  test('each added language has a broad and valid Word Hunt pool', () {
    const Map<String, int> minimumWords = <String, int>{
      'ar': 120,
      'id': 120,
      'pt': 120,
      'es': 120,
      'fr': 120,
      'de': 120,
    };

    for (final MapEntry<String, int> entry in minimumWords.entries) {
      final List<String> alphabet = WordHuntLocaleData.alphabet(entry.key);
      final List<String> words = WordHuntLocaleData.words(entry.key);
      final Set<String> alphabetSet = alphabet.toSet();

      expect(alphabetSet.length, alphabet.length, reason: entry.key);
      expect(
        words.length,
        greaterThanOrEqualTo(entry.value),
        reason: entry.key,
      );
      expect(words.toSet().length, words.length, reason: entry.key);

      for (final String word in words) {
        expect(word, isNotEmpty, reason: entry.key);
        expect(word.contains(' '), isFalse, reason: '$entry: $word');
        expect(
          word.runes.map(String.fromCharCode).every(alphabetSet.contains),
          isTrue,
          reason: '$entry: $word',
        );
      }

      // Two boards are generated without repeating session words.
      expect(
        words.where((String word) => word.runes.length <= 4).length,
        greaterThanOrEqualTo(6),
      );
      expect(
        words.where((String word) => word.runes.length <= 5).length,
        greaterThanOrEqualTo(10),
      );
      expect(
        words.where((String word) => word.runes.length <= 6).length,
        greaterThanOrEqualTo(12),
      );
      expect(
        words.where((String word) => word.runes.length <= 7).length,
        greaterThanOrEqualTo(14),
      );
      expect(
        words.where((String word) => word.runes.length <= 8).length,
        greaterThanOrEqualTo(16),
      );
      expect(
        words.where((String word) => word.runes.length <= 9).length,
        greaterThanOrEqualTo(18),
      );
    }
  });

  testWidgets('Arabic locale activates right-to-left layout', (
    WidgetTester tester,
  ) async {
    TextDirection? direction;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (BuildContext context) {
            direction = Directionality.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(direction, TextDirection.rtl);
    expect(const GlobalAppLocalizations(Locale('ar')).isRtl, isTrue);
  });
}
