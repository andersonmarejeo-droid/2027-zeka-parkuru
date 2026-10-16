import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zeka_parkuru/widgets/fast_game_route.dart';

void main() {
  testWidgets('oyun ilk kareden sonra yüklenir ve boş ekran gösterilmez', (
    WidgetTester tester,
  ) async {
    int gameBuildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: const <Locale>[Locale('tr'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      buildFastGameRoute<void>(
                        gameId: 'numbers',
                        gameTitle: 'MANTIK PARKURU',
                        gameIcon: Icons.extension_rounded,
                        accentColor: const Color(0xFF8A4FFF),
                        gameBuilder: () {
                          gameBuildCount++;
                          return const Scaffold(
                            body: Center(child: Text('OYUN HAZIR')),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('AÇ'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('AÇ'));
    // Ilk pump Navigator'in sifirinci route karesini olusturur. Ikinci pump
    // gorunur kareyi cizer; toplam sure 48 ms oyun gecikmesinin altindadir.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      find.byKey(const ValueKey<String>('zp_fast_game_launch_surface')),
      findsOneWidget,
    );
    expect(find.text('MANTIK PARKURU'), findsOneWidget);
    expect(gameBuildCount, 0);

    await tester.pump(const Duration(milliseconds: 60));
    expect(gameBuildCount, 1);
    expect(find.text('OYUN HAZIR'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('OYUN HAZIR'))).brightness,
      Brightness.light,
    );

    await tester.pumpAndSettle();
    expect(gameBuildCount, 1);
  });
}
