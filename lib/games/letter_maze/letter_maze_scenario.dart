import 'dart:math' as math;

import '../shared/content_seed.dart';

class LetterMazeLexeme {
  const LetterMazeLexeme({
    required this.id,
    required this.minimumStage,
    required this.wordTr,
    required this.wordEn,
    required this.partsTr,
    required this.partsEn,
    required this.clueTr,
    required this.clueEn,
    required this.explanationTr,
    required this.explanationEn,
  });

  final String id;
  final int minimumStage;
  final String wordTr;
  final String wordEn;
  final List<String> partsTr;
  final List<String> partsEn;
  final String clueTr;
  final String clueEn;
  final String explanationTr;
  final String explanationEn;
}

class LetterMazeTile {
  const LetterMazeTile({required this.index, required this.letter});

  final int index;
  final String letter;
}

/// A route-and-morpheme word puzzle. The answer is not visible on the board:
/// players trace adjacent letter cells from the entrance, pass the root gate,
/// and reach the exit with the word supported by the clue.
class LetterMazeScenario {
  const LetterMazeScenario({
    required this.lexeme,
    required this.stage,
    required this.english,
    required this.isPractice,
    required this.round,
    required this.tiles,
    required this.solutionPath,
    required this.checkpointIndex,
  });

  static const int campaignLevels = 20;
  static const int uniquePracticeRounds = 300;
  static const int gridSide = 5;

  static const List<LetterMazeLexeme> _bank = <LetterMazeLexeme>[
    LetterMazeLexeme(
      id: 'bookcase',
      minimumStage: 1,
      wordTr: 'kitaplık',
      wordEn: 'bookcase',
      partsTr: <String>['kitap', 'lık'],
      partsEn: <String>['book', 'case'],
      clueTr: 'Kitapları düzenli biçimde saklayan mobilya.',
      clueEn: 'A piece of furniture for storing books neatly.',
      explanationTr: 'Kitap + -lık: kitapların konduğu eşyanın adı.',
      explanationEn: 'Book + case: a piece of furniture that holds books.',
    ),
    LetterMazeLexeme(
      id: 'bookseller',
      minimumStage: 1,
      wordTr: 'kitapçı',
      wordEn: 'bookseller',
      partsTr: <String>['kitap', 'çı'],
      partsEn: <String>['book', 'seller'],
      clueTr: 'Kitapları okura sunan ve satan kişi ya da dükkân.',
      clueEn: 'A person or shop that offers books for sale.',
      explanationTr: 'Kitap + -çı: kitapla çalışan meslek veya dükkân.',
      explanationEn: 'Book + seller: someone who sells books.',
    ),
    LetterMazeLexeme(
      id: 'eyewear',
      minimumStage: 1,
      wordTr: 'gözlükçü',
      wordEn: 'eyewear',
      partsTr: <String>['gözlük', 'çü'],
      partsEn: <String>['eye', 'wear'],
      clueTr: 'Görmeyi desteklemek için göze takılan araçlar.',
      clueEn: 'Items worn in front of the eyes to support vision.',
      explanationTr: 'Gözlük + -çü, gözlük işiyle uğraşan kişiyi anlatır.',
      explanationEn: 'Eye + wear describes articles worn over the eyes.',
    ),
    LetterMazeLexeme(
      id: 'fisherman',
      minimumStage: 1,
      wordTr: 'balıkçı',
      wordEn: 'fisherman',
      partsTr: <String>['balık', 'çı'],
      partsEn: <String>['fisher', 'man'],
      clueTr: 'Geçimini balık yakalayarak sağlayan kişi.',
      clueEn: 'A person whose work is catching fish.',
      explanationTr: 'Balık + -çı: balık yakalamayı iş edinen kişi.',
      explanationEn: 'Fish + man: a person who catches fish for a living.',
    ),
    LetterMazeLexeme(
      id: 'friendship',
      minimumStage: 1,
      wordTr: 'arkadaşlık',
      wordEn: 'friendship',
      partsTr: <String>['arkadaş', 'lık'],
      partsEn: <String>['friend', 'ship'],
      clueTr: 'Birbirine güvenen ve destek olan kişiler arasındaki bağ.',
      clueEn: 'A close bond between people who trust and support each other.',
      explanationTr: 'Arkadaş + -lık, arkadaş olma durumunu adlandırır.',
      explanationEn: 'Friend + ship names the state of being friends.',
    ),
    LetterMazeLexeme(
      id: 'rootless',
      minimumStage: 1,
      wordTr: 'köksüz',
      wordEn: 'rootless',
      partsTr: <String>['kök', 'süz'],
      partsEn: <String>['root', 'less'],
      clueTr: 'Bir bitkinin toprağa tutunmasını sağlayan bölümü olmayan.',
      clueEn: 'Lacking the part that anchors a plant in the soil.',
      explanationTr: 'Kök + -süz: kökü bulunmayan.',
      explanationEn: 'Root + less: without a root.',
    ),
    LetterMazeLexeme(
      id: 'sunny',
      minimumStage: 3,
      wordTr: 'güneşli',
      wordEn: 'sunny',
      partsTr: <String>['güneş', 'li'],
      partsEn: <String>['sun', 'ny'],
      clueTr: 'Gökyüzünün bulutsuz olduğu, güneş ışığının görüldüğü hava.',
      clueEn: 'Weather with plenty of visible sunshine.',
      explanationTr: 'Güneş + -li: güneşi bol olan hava.',
      explanationEn: 'Sun + -y: bright with sunshine.',
    ),
    LetterMazeLexeme(
      id: 'soundless',
      minimumStage: 3,
      wordTr: 'gürültüsüz',
      wordEn: 'soundless',
      partsTr: <String>['gürültü', 'süz'],
      partsEn: <String>['sound', 'less'],
      clueTr: 'Rahatsız edici sesin bulunmadığı ortam.',
      clueEn: 'A setting in which no sound can be heard.',
      explanationTr: 'Gürültü + -süz: gürültüsü olmayan.',
      explanationEn: 'Sound + less: without sound.',
    ),
    LetterMazeLexeme(
      id: 'traveler',
      minimumStage: 3,
      wordTr: 'yolcu',
      wordEn: 'traveler',
      partsTr: <String>['yol', 'cu'],
      partsEn: <String>['travel', 'er'],
      clueTr: 'Bir yerden başka bir yere ulaşmak için yola çıkan kişi.',
      clueEn: 'A person who goes from one place to another.',
      explanationTr: 'Yol + -cu: yolculuk eden kişi.',
      explanationEn: 'Travel + er: a person who travels.',
    ),
    LetterMazeLexeme(
      id: 'unbalanced',
      minimumStage: 3,
      wordTr: 'dengesiz',
      wordEn: 'unbalanced',
      partsTr: <String>['denge', 'siz'],
      partsEn: <String>['un', 'balanced'],
      clueTr: 'Ağırlığı ya da davranışı kararlı biçimde dağılım göstermeyen.',
      clueEn: 'Not steady or evenly distributed.',
      explanationTr: 'Denge + -siz: dengesini koruyamayan.',
      explanationEn: 'Un + balanced: not held in a steady balance.',
    ),
    LetterMazeLexeme(
      id: 'reader',
      minimumStage: 5,
      wordTr: 'okuyucu',
      wordEn: 'reader',
      partsTr: <String>['oku', 'yucu'],
      partsEn: <String>['read', 'er'],
      clueTr: 'Bir metni anlamak için gözden geçiren kişi.',
      clueEn: 'A person who reads a text or book.',
      explanationTr: 'Oku- + -yucu: okuma eylemini yapan kişi.',
      explanationEn: 'Read + er: a person who reads.',
    ),
    LetterMazeLexeme(
      id: 'software',
      minimumStage: 5,
      wordTr: 'yazılım',
      wordEn: 'software',
      partsTr: <String>['yazı', 'lım'],
      partsEn: <String>['soft', 'ware'],
      clueTr: 'Bilgisayara hangi işlemleri yapacağını söyleyen programlar.',
      clueEn: 'Programs that tell a computer what tasks to perform.',
      explanationTr:
          'Yaz- kökünden türeyen, bilgisayar programlarını anlatan ad.',
      explanationEn: 'Soft + ware: the programs that run on a computer.',
    ),
    LetterMazeLexeme(
      id: 'durable',
      minimumStage: 5,
      wordTr: 'dayanıklı',
      wordEn: 'durable',
      partsTr: <String>['dayan', 'ıklı'],
      partsEn: <String>['dur', 'able'],
      clueTr: 'Zor kullanıma rağmen kolayca yıpranmayan.',
      clueEn: 'Able to last through heavy use without wearing out.',
      explanationTr: 'Dayan- kökünden: uzun süre dayanmaya elverişli.',
      explanationEn: 'Dur + able: able to last over time.',
    ),
    LetterMazeLexeme(
      id: 'invisible',
      minimumStage: 5,
      wordTr: 'görünmez',
      wordEn: 'invisible',
      partsTr: <String>['görün', 'mez'],
      partsEn: <String>['in', 'visible'],
      clueTr: 'Gözle seçilemeyen, görülemeyen.',
      clueEn: 'Unable to be seen with the eyes.',
      explanationTr: 'Görün- + -mez: görülemeyen.',
      explanationEn: 'In + visible: not visible.',
    ),
    LetterMazeLexeme(
      id: 'sharing',
      minimumStage: 7,
      wordTr: 'paylaşım',
      wordEn: 'sharing',
      partsTr: <String>['paylaş', 'ım'],
      partsEn: <String>['shar', 'ing'],
      clueTr: 'Bir şeyi başkalarının da kullanmasına sunma eylemi.',
      clueEn: 'The act of letting others use or receive part of something.',
      explanationTr: 'Paylaş- + -ım: paylaşma eylemi ya da sonucu.',
      explanationEn: 'Shar(e) + ing: the act of sharing something.',
    ),
    LetterMazeLexeme(
      id: 'inconsistent',
      minimumStage: 7,
      wordTr: 'tutarsız',
      wordEn: 'inconsistent',
      partsTr: <String>['tutar', 'sız'],
      partsEn: <String>['in', 'consistent'],
      clueTr: 'Söyledikleri veya sonuçları birbiriyle uyuşmayan.',
      clueEn: 'Not staying in agreement with earlier facts or statements.',
      explanationTr: 'Tutar- + -sız: kendi içinde uyum göstermeyen.',
      explanationEn: 'In + consistent: not consistent with the evidence.',
    ),
    LetterMazeLexeme(
      id: 'uncertain',
      minimumStage: 7,
      wordTr: 'belirsiz',
      wordEn: 'uncertain',
      partsTr: <String>['belir', 'siz'],
      partsEn: <String>['un', 'certain'],
      clueTr: 'Sonucu ya da niteliği henüz açıkça bilinmeyen.',
      clueEn: 'Not yet known or settled with confidence.',
      explanationTr: 'Belir- + -siz: açıkça belirlenememiş.',
      explanationEn: 'Un + certain: not known for sure.',
    ),
    LetterMazeLexeme(
      id: 'foresight',
      minimumStage: 9,
      wordTr: 'öngörü',
      wordEn: 'foresight',
      partsTr: <String>['ön', 'görü'],
      partsEn: <String>['fore', 'sight'],
      clueTr: 'Bilgi ve deneyime dayanarak olası sonucu önceden kestirme.',
      clueEn: 'The ability to anticipate likely outcomes before they happen.',
      explanationTr: 'Ön + görü: olacakları önceden görebilme yetisi.',
      explanationEn: 'Fore + sight: the ability to look ahead.',
    ),
    LetterMazeLexeme(
      id: 'inventive',
      minimumStage: 9,
      wordTr: 'yaratıcı',
      wordEn: 'inventive',
      partsTr: <String>['yarat', 'ıcı'],
      partsEn: <String>['invent', 'ive'],
      clueTr: 'Alışılmışın dışında işe yarar fikirler üretebilen.',
      clueEn: 'Able to produce original and useful ideas.',
      explanationTr: 'Yarat- + -ıcı: yeni şeyler ortaya koyabilen.',
      explanationEn: 'Invent + ive: skilled at making new ideas or things.',
    ),
    LetterMazeLexeme(
      id: 'unanswered',
      minimumStage: 10,
      wordTr: 'karşılıksız',
      wordEn: 'unanswered',
      partsTr: <String>['karşılık', 'sız'],
      partsEn: <String>['un', 'answered'],
      clueTr: 'Gönderilmiş olmasına rağmen yanıt gelmemiş mesaj.',
      clueEn: 'A message that has received no reply.',
      explanationTr: 'Karşılık + -sız: yanıtı bulunmayan.',
      explanationEn: 'Un + answered: not answered by anyone.',
    ),
    LetterMazeLexeme(
      id: 'inconsistency_noun',
      minimumStage: 10,
      wordTr: 'tutarsızlık',
      wordEn: 'inconsistency',
      partsTr: <String>['tutarsız', 'lık'],
      partsEn: <String>['in', 'consistency'],
      clueTr: 'Bir düşünce ya da davranışın kendi içinde uyuşmaması.',
      clueEn: 'A lack of agreement among facts, actions or statements.',
      explanationTr: 'Tutarsız + -lık: uyum bulunmama durumu.',
      explanationEn: 'In + consistency: the state of not being consistent.',
    ),
    LetterMazeLexeme(
      id: 'uncertainty_noun',
      minimumStage: 10,
      wordTr: 'belirsizlik',
      wordEn: 'uncertainty',
      partsTr: <String>['belirsiz', 'lik'],
      partsEn: <String>['un', 'certainty'],
      clueTr: 'Bir sonucun kesinleşmemiş olmasından doğan bilinmezlik.',
      clueEn: 'The state of not knowing what will happen or what is true.',
      explanationTr: 'Belirsiz + -lik: kesinlik bulunmayan durum.',
      explanationEn: 'Un + certainty: the state of not being certain.',
    ),
    LetterMazeLexeme(
      id: 'unintelligibility',
      minimumStage: 10,
      wordTr: 'anlaşılmazlık',
      wordEn: 'unintelligibility',
      partsTr: <String>['anlaşılmaz', 'lık'],
      partsEn: <String>['un', 'intelligibility'],
      clueTr: 'Bir anlatımın kolayca kavranamaması özelliği.',
      clueEn: 'The quality of being difficult or impossible to understand.',
      explanationTr: 'Anlaşılmaz + -lık: kavranması güç olma durumu.',
      explanationEn:
          'Un + intelligibility: the quality of not being understandable.',
    ),
    LetterMazeLexeme(
      id: 'shortsightedness',
      minimumStage: 10,
      wordTr: 'öngörüsüzlük',
      wordEn: 'shortsightedness',
      partsTr: <String>['öngörü', 'süzlük'],
      partsEn: <String>['short', 'sightedness'],
      clueTr: 'Bir kararın ileride doğuracağı sonuçları hesaba katmama.',
      clueEn: 'Failure to consider the future consequences of a decision.',
      explanationTr: 'Öngörü + -süzlük: geleceği hesaba katmama durumu.',
      explanationEn:
          'Short + sightedness: inability to plan for later consequences.',
    ),
  ];

  static const List<int> _campaignOrder = <int>[
    6,
    5,
    10,
    8,
    14,
    1,
    4,
    7,
    15,
    19,
    0,
    11,
    12,
    2,
    3,
    13,
    20,
    21,
    22,
    23,
  ];

  final LetterMazeLexeme lexeme;
  final int stage;
  final bool english;
  final bool isPractice;
  final int round;
  final List<LetterMazeTile> tiles;
  final List<int> solutionPath;
  final int checkpointIndex;

  String get answer => english ? lexeme.wordEn : lexeme.wordTr;
  String get clue => english ? lexeme.clueEn : lexeme.clueTr;
  String get explanation =>
      english ? lexeme.explanationEn : lexeme.explanationTr;
  String get rootLabel => english ? 'ROOT GATE' : 'KÖK KAPISI';

  String get boardSignature => <String>[
    lexeme.id,
    tiles.map((LetterMazeTile tile) => tile.letter).join(),
    solutionPath.join(','),
    '$checkpointIndex',
  ].join('|');

  bool acceptsRoute(List<int> route) {
    if (route.length != answer.runes.length || route.isEmpty) return false;
    if (route.any((int index) => index < 0 || index >= tiles.length)) {
      return false;
    }
    if (route.first != solutionPath.first || route.last != solutionPath.last) {
      return false;
    }
    if (!route.contains(checkpointIndex) || !_isAdjacentRoute(route)) {
      return false;
    }
    return route.map((int index) => tiles[index].letter).join() == answer;
  }

  bool _isAdjacentRoute(List<int> route) {
    if (route.toSet().length != route.length) return false;
    for (int index = 1; index < route.length; index++) {
      final int previous = route[index - 1];
      final int current = route[index];
      if (previous < 0 || current < 0 || current >= tiles.length) return false;
      final int rowDelta = (previous ~/ gridSide) - (current ~/ gridSide);
      final int columnDelta = (previous % gridSide) - (current % gridSide);
      if (rowDelta.abs() + columnDelta.abs() != 1) return false;
    }
    return true;
  }

  static LetterMazeScenario forCampaignLevel(
    int level, {
    bool english = false,
  }) {
    if (level < 1 || level > campaignLevels) {
      throw RangeError.range(level, 1, 20);
    }
    final int bankIndex = _campaignOrder[level - 1];
    final LetterMazeLexeme lexeme = _bank[bankIndex];
    return _build(
      lexeme: lexeme,
      stage: level,
      english: english,
      isPractice: false,
      round: level,
      random: ContentSeed.randomFor(
        gameId: 'letter_maze:campaign',
        level: level,
      ),
    );
  }

  static LetterMazeScenario forPracticeRound(
    int round, {
    bool english = false,
  }) {
    if (round < 1 || round > uniquePracticeRounds) {
      throw RangeError.range(round, 1, uniquePracticeRounds);
    }
    final int bankIndex = (round - 1) % _bank.length;
    final int stage = ((round - 1) % campaignLevels) + 1;
    return _build(
      lexeme: _bank[bankIndex],
      stage: stage,
      english: english,
      isPractice: true,
      round: round,
      random: ContentSeed.randomFor(
        gameId: 'letter_maze:practice:${_bank[bankIndex].id}',
        level: round,
      ),
    );
  }

  static LetterMazeScenario _build({
    required LetterMazeLexeme lexeme,
    required int stage,
    required bool english,
    required bool isPractice,
    required int round,
    required math.Random random,
  }) {
    final String word = english ? lexeme.wordEn : lexeme.wordTr;
    final List<String> letters = word.runes
        .map((int rune) => String.fromCharCode(rune))
        .toList(growable: false);
    if (letters.length > gridSide * gridSide) {
      throw StateError('Letter Maze answer does not fit the board: $word');
    }
    final List<String> parts = english ? lexeme.partsEn : lexeme.partsTr;
    if (parts.length < 2 || parts.join() != word) {
      throw StateError('Invalid morpheme split for ${lexeme.id}: $word');
    }
    final int checkpointOffset = parts.first.runes.length - 1;
    if (checkpointOffset < 1 || checkpointOffset >= letters.length - 1) {
      throw StateError('Invalid root gate for ${lexeme.id}: $word');
    }
    final List<int> path = _makePath(letters.length, random);
    final List<String> alphabet = english
        ? 'abcdefghijklmnopqrstuvwxyz'.split('')
        : 'abcçdefgğhıijklmnoöprsştuüvyz'.split('');
    final List<String> board = List<String>.generate(
      gridSide * gridSide,
      (int _) => alphabet[random.nextInt(alphabet.length)],
      growable: false,
    );
    for (int index = 0; index < path.length; index++) {
      board[path[index]] = letters[index];
    }
    return LetterMazeScenario(
      lexeme: lexeme,
      stage: stage,
      english: english,
      isPractice: isPractice,
      round: round,
      tiles: List<LetterMazeTile>.generate(
        board.length,
        (int index) => LetterMazeTile(index: index, letter: board[index]),
        growable: false,
      ),
      solutionPath: List<int>.unmodifiable(path),
      checkpointIndex: path[checkpointOffset],
    );
  }

  static List<int> _makePath(int length, math.Random random) {
    for (int attempt = 0; attempt < 96; attempt++) {
      final List<int> path = <int>[random.nextInt(gridSide * gridSide)];
      final Set<int> visited = <int>{path.first};
      while (path.length < length) {
        final int current = path.last;
        final List<int> candidates = _neighbors(current)
            .where((int candidate) => !visited.contains(candidate))
            .toList();
        if (candidates.isEmpty) break;
        candidates.shuffle(random);
        final int next = candidates.first;
        path.add(next);
        visited.add(next);
      }
      if (path.length == length) return path;
    }
    throw StateError('Could not generate a $length-tile letter maze.');
  }

  static List<int> _neighbors(int index) {
    final int row = index ~/ gridSide;
    final int column = index % gridSide;
    return <int>[
      if (row > 0) index - gridSide,
      if (row < gridSide - 1) index + gridSide,
      if (column > 0) index - 1,
      if (column < gridSide - 1) index + 1,
    ];
  }
}
