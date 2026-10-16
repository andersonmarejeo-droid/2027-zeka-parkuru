import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/pages/challenge_center_page.dart';
import 'package:zeka_parkuru/services/social_challenge_service.dart';
import 'package:zeka_parkuru/widgets/avatar_icon.dart';

SocialChallenge _challenge({
  String challengerName = 'Oyuncu',
  String opponentName = 'Oyuncu',
  String status = 'pending',
}) {
  return SocialChallenge(
    id: 'test-challenge',
    challengerUid: 'challenger',
    challengerName: challengerName,
    challengerAvatar: 'animal_fox',
    targetUid: 'opponent',
    opponentUid: 'opponent',
    opponentName: opponentName,
    opponentAvatar: 'animal_panda',
    participantIds: const <String>['challenger', 'opponent'],
    status: status,
    gameId: 'logic',
    level: 1,
    seed: 1,
    schemaVersion: 2,
    gameIds: List<String>.filled(8, 'logic'),
    levels: List<int>.filled(8, 1),
    layoutCodes: List<int>.filled(8, 1),
    challengerScore: null,
    challengerStars: null,
    challengerTimeMs: null,
    challengerSkips: null,
    opponentScore: null,
    opponentStars: null,
    opponentTimeMs: null,
    opponentSkips: null,
    challengerReaction: null,
    opponentReaction: null,
    winnerUid: null,
    createdAt: null,
    updatedAt: null,
    expiresAt: null,
  );
}

Future<void> _pumpNarrow(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('challenge list uses an avatar image and keeps status readable', (
    tester,
  ) async {
    await _pumpNarrow(
      tester,
      ChallengeCard(
        challenge: _challenge(),
        currentUid: 'challenger',
        onOpen: () {},
      ),
    );

    expect(find.byType(AvatarIcon), findsOneWidget);
    expect(find.text('animal_panda'), findsNothing);
    expect(find.text('Rakip'), findsOneWidget);
    expect(find.text('KABUL BEKLİYOR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long opponent names do not squeeze the challenge status', (
    tester,
  ) async {
    const String longName = 'Çok Uzun Bir Rakip İsmi';
    await _pumpNarrow(
      tester,
      ChallengeCard(
        challenge: _challenge(opponentName: longName),
        currentUid: 'challenger',
        onOpen: () {},
      ),
    );

    final Text name = tester.widget<Text>(find.text(longName));
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(find.text('KABUL BEKLİYOR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duel hero shows roles instead of raw avatar identifiers', (
    tester,
  ) async {
    await _pumpNarrow(
      tester,
      ChallengeDuelHero(challenge: _challenge(), currentUid: 'challenger'),
    );

    expect(find.text('8 OYUNLUK MEYDAN OKUMA'), findsOneWidget);
    expect(find.text('Sen'), findsOneWidget);
    expect(find.text('Rakip'), findsOneWidget);
    expect(find.textContaining('animal_'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
