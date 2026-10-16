import 'dart:math' as math;

enum DetectiveClueKind {
  personSeat,
  personRelic,
  personRoom,
  before,
  adjacent,
  relicInRoom,
}

enum DetectiveMark { unknown, crossed, confirmed }

class DetectiveNotesLabels {
  const DetectiveNotesLabels({
    required this.people,
    required this.relicsTr,
    required this.roomsTr,
    required this.relicsEn,
    required this.roomsEn,
  });

  final List<String> people;
  final List<String> relicsTr;
  final List<String> roomsTr;
  final List<String> relicsEn;
  final List<String> roomsEn;
}

class DetectiveSolution {
  const DetectiveSolution({
    required this.personAtSeat,
    required this.relicByPerson,
    required this.roomByPerson,
  });

  /// Person index at seat 0..3; the visible names come from the case labels.
  final List<int> personAtSeat;

  /// Relic index held by each person.
  final List<int> relicByPerson;

  /// Room index assigned to each person.
  final List<int> roomByPerson;

  int get seatCount => personAtSeat.length;

  int seatOfPerson(int person) => personAtSeat.indexOf(person);

  bool hasRelic(int person, int relic) => relicByPerson[person] == relic;

  bool isInRoom(int person, int room) => roomByPerson[person] == room;

  bool relicIsInRoom(int room, int relic) {
    for (int person = 0; person < seatCount; person++) {
      if (roomByPerson[person] == room && relicByPerson[person] == relic) {
        return true;
      }
    }
    return false;
  }
}

class DetectiveClue {
  const DetectiveClue({
    required this.kind,
    required this.first,
    this.second = -1,
  });

  final DetectiveClueKind kind;
  final int first;
  final int second;

  bool matches(DetectiveSolution solution) => switch (kind) {
    DetectiveClueKind.personSeat => solution.seatOfPerson(first) == second,
    DetectiveClueKind.personRelic => solution.hasRelic(first, second),
    DetectiveClueKind.personRoom => solution.isInRoom(first, second),
    DetectiveClueKind.before =>
      solution.seatOfPerson(first) < solution.seatOfPerson(second),
    DetectiveClueKind.adjacent =>
      (solution.seatOfPerson(first) - solution.seatOfPerson(second)).abs() == 1,
    DetectiveClueKind.relicInRoom => solution.relicIsInRoom(first, second),
  };

  String text({required bool english, DetectiveNotesLabels? labels}) {
    final DetectiveNotesLabels activeLabels =
        labels ?? DetectiveNotesPuzzle.defaultLabels;
    final String person = activeLabels.people[first];
    final String other =
        activeLabels.people[second < 0 ? 0 : second];
    final String relic = english
        ? activeLabels.relicsEn[second < 0 ? 0 : second]
        : activeLabels.relicsTr[second < 0 ? 0 : second];
    final int roomIndex = kind == DetectiveClueKind.personRoom ? second : first;
    final String room = english
        ? activeLabels.roomsEn[roomIndex]
        : activeLabels.roomsTr[roomIndex];
    return switch (kind) {
      DetectiveClueKind.personSeat =>
        english
            ? '$person sat in seat ${second + 1}.'
            : '$person, ${second + 1}. sırada oturdu.',
      DetectiveClueKind.personRelic =>
        english
            ? '$person carried the $relic.'
            : '$person, $relic eserini taşıyordu.',
      DetectiveClueKind.personRoom =>
        english
            ? '$person was assigned to the $room.'
            : '$person, $room odasındaydı.',
      DetectiveClueKind.before =>
        english
            ? '$person arrived before $other.'
            : '$person, $other kişisinden önce geldi.',
      DetectiveClueKind.adjacent =>
        english
            ? '$person and $other sat in neighboring seats.'
            : '$person ile $other yan yana oturdu.',
      DetectiveClueKind.relicInRoom =>
        english
            ? 'The $relic was found in the $room.'
            : '$relic, $room odasında bulundu.',
    };
  }
}

class DetectiveNotesPuzzle {
  static const int maximumUniqueCases = 13824;

  const DetectiveNotesPuzzle({
    required this.level,
    required this.solution,
    required this.clues,
    this.labels = defaultLabels,
  });

  static const List<String> people = <String>['Ada', 'Bora', 'Cem', 'Defne'];
  static const List<String> relics = <String>[
    'Kehribar Pusula',
    'Gümüş Anahtar',
    'Yeşim Mühür',
    'Yakut Mercek',
  ];
  static const List<String> rooms = <String>[
    'Arşiv',
    'Galeri',
    'Sera',
    'Gözlemevi',
  ];
  static const List<String> relicsEn = <String>[
    'Amber Compass',
    'Silver Key',
    'Jade Seal',
    'Ruby Lens',
  ];
  static const List<String> roomsEn = <String>[
    'Archive',
    'Gallery',
    'Greenhouse',
    'Observatory',
  ];
  static const DetectiveNotesLabels defaultLabels = DetectiveNotesLabels(
    people: people,
    relicsTr: relics,
    roomsTr: rooms,
    relicsEn: relicsEn,
    roomsEn: roomsEn,
  );
  static const List<DetectiveNotesLabels> _labelSets =
      <DetectiveNotesLabels>[
    defaultLabels,
    DetectiveNotesLabels(
      people: <String>['Aylin', 'Berk', 'Ceren', 'Doruk'],
      relicsTr: <String>[
        'Fildişi Heykel',
        'Bronz Anahtar',
        'Lacivert Mühür',
        'Opal Mercek',
      ],
      roomsTr: <String>[
        'Atölye',
        'Kule',
        'Kütüphane',
        'Seramik Salonu',
      ],
      relicsEn: <String>[
        'Ivory Statue',
        'Bronze Key',
        'Navy Seal',
        'Opal Lens',
      ],
      roomsEn: <String>[
        'Workshop',
        'Tower',
        'Library',
        'Ceramics Hall',
      ],
    ),
    DetectiveNotesLabels(
      people: <String>['Ece', 'Fırat', 'Gizem', 'Hakan'],
      relicsTr: <String>[
        'Eski Harita',
        'Bakır Pusula',
        'Kristal Rozet',
        'Sedef Kutu',
      ],
      roomsTr: <String>[
        'Arşiv Odası',
        'Çalışma Salonu',
        'Kış Bahçesi',
        'Saat Kulesi',
      ],
      relicsEn: <String>[
        'Old Map',
        'Copper Compass',
        'Crystal Badge',
        'Mother-of-pearl Box',
      ],
      roomsEn: <String>[
        'Archive Room',
        'Study Hall',
        'Winter Garden',
        'Clock Tower',
      ],
    ),
    DetectiveNotesLabels(
      people: <String>['İpek', 'Kaan', 'Lale', 'Mert'],
      relicsTr: <String>[
        'Oniks Yüzük',
        'Çelik Anahtar',
        'Fıstık Mührü',
        'Safir Lens',
      ],
      roomsTr: <String>[
        'Depo',
        'Mavi Salon',
        'Kışlık Sera',
        'Gözlem Kulesi',
      ],
      relicsEn: <String>[
        'Onyx Ring',
        'Steel Key',
        'Pistachio Seal',
        'Sapphire Lens',
      ],
      roomsEn: <String>[
        'Storage Room',
        'Blue Hall',
        'Winter Greenhouse',
        'Observation Tower',
      ],
    ),
    DetectiveNotesLabels(
      people: <String>['Nehir', 'Okan', 'Pelin', 'Rıza'],
      relicsTr: <String>[
        'Koral Heykel',
        'Altın Anahtar',
        'Vişne Mühür',
        'Dumanlı Cam',
      ],
      roomsTr: <String>[
        'Harita Odası',
        'Koleksiyon Salonu',
        'Avlu',
        'Çatı Katı',
      ],
      relicsEn: <String>[
        'Coral Statue',
        'Golden Key',
        'Cherry Seal',
        'Smoky Glass',
      ],
      roomsEn: <String>[
        'Map Room',
        'Collection Hall',
        'Courtyard',
        'Attic',
      ],
    ),
    DetectiveNotesLabels(
      people: <String>['Selin', 'Tolga', 'Ufuk', 'Zeynep'],
      relicsTr: <String>[
        'Bakır Kutu',
        'Kayıp Madalya',
        'Lal Taş',
        'Eski Fener',
      ],
      roomsTr: <String>[
        'Kayıt Odası',
        'Batı Galeri',
        'Bitki Odası',
        'Kuzey Teras',
      ],
      relicsEn: <String>[
        'Copper Box',
        'Lost Medal',
        'Ruby Stone',
        'Old Lantern',
      ],
      roomsEn: <String>[
        'Records Room',
        'West Gallery',
        'Plant Room',
        'North Terrace',
      ],
    ),
    DetectiveNotesLabels(
      people: <String>['Buse', 'Can', 'Derya', 'Emre'],
      relicsTr: <String>[
        'Mavi Küre',
        'Gümüş Rozet',
        'Amber Broş',
        'Kızıl Kristal',
      ],
      roomsTr: <String>[
        'Sergi Salonu',
        'Konservatuvar',
        'Taş Avlu',
        'Seyir Odası',
      ],
      relicsEn: <String>[
        'Blue Sphere',
        'Silver Badge',
        'Amber Brooch',
        'Scarlet Crystal',
      ],
      roomsEn: <String>[
        'Exhibition Hall',
        'Conservatory',
        'Stone Courtyard',
        'Viewing Room',
      ],
    ),
    DetectiveNotesLabels(
      people: <String>['Aslı', 'Baran', 'Cansu', 'Deniz'],
      relicsTr: <String>[
        'Parşömen',
        'Bronz Kupa',
        'Yeşil Taş',
        'Yakut Kutu',
      ],
      roomsTr: <String>[
        'Arka Arşiv',
        'Büyük Galeri',
        'Çiçeklik',
        'Kubbe',
      ],
      relicsEn: <String>[
        'Parchment',
        'Bronze Cup',
        'Green Stone',
        'Ruby Box',
      ],
      roomsEn: <String>[
        'Back Archive',
        'Grand Gallery',
        'Flower Room',
        'Dome',
      ],
    ),
  ];
  static final List<DetectiveSolution> _possibleWorlds =
      _generateAllSolutions();

  final int level;
  final DetectiveSolution solution;
  final List<DetectiveClue> clues;
  final DetectiveNotesLabels labels;

  int get assignmentCount => people.length * 2;

  bool get hasUniqueSolution => solve(clues).length == 1;

  bool isSolved(
    List<List<DetectiveMark>> relicMarks,
    List<List<DetectiveMark>> roomMarks,
    List<List<DetectiveMark>> seatMarks,
  ) {
    if (relicMarks.length != people.length ||
        roomMarks.length != people.length ||
        seatMarks.length != people.length) {
      return false;
    }
    for (int person = 0; person < people.length; person++) {
      final List<int> relicYes = <int>[
        for (int relic = 0; relic < relics.length; relic++)
          if (relicMarks[person][relic] == DetectiveMark.confirmed) relic,
      ];
      final List<int> roomYes = <int>[
        for (int room = 0; room < rooms.length; room++)
          if (roomMarks[person][room] == DetectiveMark.confirmed) room,
      ];
      final List<int> seatYes = <int>[
        for (int seat = 0; seat < people.length; seat++)
          if (seatMarks[person][seat] == DetectiveMark.confirmed) seat,
      ];
      if (relicYes.length != 1 ||
          relicYes.single != solution.relicByPerson[person] ||
          roomYes.length != 1 ||
          roomYes.single != solution.roomByPerson[person] ||
          seatYes.length != 1 ||
          seatYes.single != solution.seatOfPerson(person)) {
        return false;
      }
    }
    return true;
  }

  static int guidedFactBudgetForChapter(int chapter) =>
      8 - ((chapter.clamp(1, 30) - 1) ~/ 6) * 2;

  static DetectiveNotesPuzzle forLevel(int level, {bool progressive = false}) {
    if (level < 1 || level > maximumUniqueCases) {
      throw RangeError.range(level, 1, maximumUniqueCases, 'level');
    }
    final int normalized = level;
    final int seed = 0x51A7 + normalized * 9973;
    final int round = normalized - 1;
    // Walk the full 24 x 24 x 24 solution space with a coprime stride so
    // each deduction axis keeps changing throughout the campaign.
    final int caseCode = (round * 7919 + 45) % maximumUniqueCases;
    final DetectiveSolution solution = DetectiveSolution(
      personAtSeat: _permutationAt(caseCode % 24),
      relicByPerson: _permutationAt((caseCode ~/ 24) % 24),
      roomByPerson: _permutationAt(caseCode ~/ 576),
    );
    final List<DetectiveClue> clues = _uniqueClues(
      solution,
      seed,
      chapter: progressive ? (level - 1) ~/ 10 + 1 : null,
    );
    return DetectiveNotesPuzzle(
      level: normalized,
      solution: solution,
      clues: List<DetectiveClue>.unmodifiable(clues),
      labels: _labelSets[round % _labelSets.length],
    );
  }

  static List<DetectiveSolution> solve(List<DetectiveClue> clues) {
    return _possibleWorlds
        .where(
          (DetectiveSolution candidate) =>
              clues.every((DetectiveClue clue) => clue.matches(candidate)),
        )
        .take(2)
        .toList(growable: false);
  }

  static List<DetectiveClue> _uniqueClues(
    DetectiveSolution solution,
    int seed, {
    int? chapter,
  }) {
    final List<DetectiveClue> candidates = <DetectiveClue>[];
    for (int person = 0; person < people.length; person++) {
      candidates.add(
        DetectiveClue(
          kind: DetectiveClueKind.personSeat,
          first: person,
          second: solution.seatOfPerson(person),
        ),
      );
      candidates.add(
        DetectiveClue(
          kind: DetectiveClueKind.personRelic,
          first: person,
          second: solution.relicByPerson[person],
        ),
      );
      candidates.add(
        DetectiveClue(
          kind: DetectiveClueKind.personRoom,
          first: person,
          second: solution.roomByPerson[person],
        ),
      );
      for (int other = person + 1; other < people.length; other++) {
        if (solution.seatOfPerson(person) < solution.seatOfPerson(other)) {
          candidates.add(
            DetectiveClue(
              kind: DetectiveClueKind.before,
              first: person,
              second: other,
            ),
          );
        } else {
          candidates.add(
            DetectiveClue(
              kind: DetectiveClueKind.before,
              first: other,
              second: person,
            ),
          );
        }
        if ((solution.seatOfPerson(person) - solution.seatOfPerson(other))
                .abs() ==
            1) {
          candidates.add(
            DetectiveClue(
              kind: DetectiveClueKind.adjacent,
              first: person,
              second: other,
            ),
          );
        }
      }
      candidates.add(
        DetectiveClue(
          kind: DetectiveClueKind.relicInRoom,
          first: solution.roomByPerson[person],
          second: solution.relicByPerson[person],
        ),
      );
    }

    _shuffleInPlace(candidates, seed);
    if (chapter != null) {
      final direct = candidates.where((clue) => clue.kind.index <= 2).toList();
      final relational = candidates
          .where((clue) => clue.kind.index > 2)
          .toList();
      final budget = guidedFactBudgetForChapter(chapter);
      // Reduce explicit facts in five steps. Later cases require combining
      // relationships; the same uniqueness solver still certifies every case.
      candidates
        ..clear()
        ..addAll(direct.take(budget))
        ..addAll(relational)
        ..addAll(direct.skip(budget));
    }
    final List<DetectiveClue> selected = <DetectiveClue>[];
    List<DetectiveSolution> possibilities = _possibleWorlds;
    for (final DetectiveClue clue in candidates) {
      selected.add(clue);
      possibilities = possibilities
          .where((DetectiveSolution answer) => clue.matches(answer))
          .toList(growable: false);
      if (possibilities.length == 1) break;
    }
    if (possibilities.length != 1) {
      throw StateError(
        'Detective puzzle generator could not make a unique case.',
      );
    }
    return selected;
  }

  static List<DetectiveSolution> _generateAllSolutions() {
    final List<List<int>> permutations = _permutations();
    return List<DetectiveSolution>.unmodifiable(<DetectiveSolution>[
      for (final List<int> seats in permutations)
        for (final List<int> relics in permutations)
          for (final List<int> rooms in permutations)
            DetectiveSolution(
              personAtSeat: seats,
              relicByPerson: relics,
              roomByPerson: rooms,
            ),
    ]);
  }

  static List<List<int>> _permutations() {
    final List<List<int>> results = <List<int>>[];
    void visit(List<int> prefix, List<int> remaining) {
      if (remaining.isEmpty) {
        results.add(List<int>.unmodifiable(prefix));
        return;
      }
      for (final int value in remaining) {
        visit(
          <int>[...prefix, value],
          remaining.where((int item) => item != value).toList(growable: false),
        );
      }
    }

    visit(<int>[], <int>[0, 1, 2, 3]);
    return results;
  }

  static List<int> _permutationAt(int rank) {
    final List<int> remaining = <int>[0, 1, 2, 3];
    final List<int> result = <int>[];
    int remainder = rank;
    for (int length = remaining.length; length > 0; length--) {
      int blockSize = 1;
      for (int factor = 1; factor < length; factor++) {
        blockSize *= factor;
      }
      final int choice = remainder ~/ blockSize;
      remainder %= blockSize;
      result.add(remaining.removeAt(choice));
    }
    return List<int>.unmodifiable(result);
  }

  static void _shuffleInPlace<T>(List<T> values, int seed) {
    final math.Random random = math.Random(seed);
    for (int index = values.length - 1; index > 0; index--) {
      final int other = random.nextInt(index + 1);
      final T held = values[index];
      values[index] = values[other];
      values[other] = held;
    }
  }
}
