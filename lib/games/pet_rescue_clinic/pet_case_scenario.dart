import 'dart:math' as math;

enum RescueAnimal { cat, dog, rabbit, parrot }

enum CareStep {
  quietRoom,
  freshWater,
  towelDry,
  gentleBrush,
  refreshBedding,
  gentlePlay,
  calmRest,
}

extension RescueAnimalLabel on RescueAnimal {
  String label(bool english) => switch (this) {
    RescueAnimal.cat => english ? 'CAT' : 'KEDİ',
    RescueAnimal.dog => english ? 'DOG' : 'KÖPEK',
    RescueAnimal.rabbit => english ? 'RABBIT' : 'TAVŞAN',
    RescueAnimal.parrot => english ? 'PARROT' : 'PAPAĞAN',
  };
}

extension CareStepInfo on CareStep {
  String label(bool english) => switch (this) {
    CareStep.quietRoom => english ? 'QUIET ROOM' : 'SAKİN ODA',
    CareStep.freshWater => english ? 'FRESH WATER' : 'TEMİZ SU',
    CareStep.towelDry => english ? 'SOFT TOWEL' : 'YUMUŞAK HAVLU',
    CareStep.gentleBrush => english ? 'GENTLE BRUSH' : 'NAZİK FIRÇA',
    CareStep.refreshBedding => english ? 'FRESH BED' : 'TEMİZ YATAK',
    CareStep.gentlePlay => english ? 'CALM PLAY' : 'SAKİN OYUN',
    CareStep.calmRest => english ? 'REST TIME' : 'DİNLENME',
  };

  String prompt(bool english, int stepNumber) => switch (this) {
    CareStep.quietRoom =>
      english
          ? 'First, let the visitor settle in a low-noise, familiar space.'
          : 'Önce ziyaretçinin sessiz ve tanıdık bir alana yerleşmesini sağla.',
    CareStep.freshWater =>
      english
          ? 'The clean bowl is empty. Offer fresh water before any activity.'
          : 'Temiz su kabı boş. Herhangi bir etkinlikten önce su sun.',
    CareStep.towelDry =>
      english
          ? 'The coat is damp after the walk. Pat it dry before grooming.'
          : 'Gezinti sonrası tüyleri nemli. Bakımdan önce yumuşakça kurula.',
    CareStep.gentleBrush =>
      english
          ? 'The visitor is settled and dry. Smooth the coat with a gentle brush.'
          : 'Ziyaretçi sakin ve kuru. Tüylerini nazikçe fırçala.',
    CareStep.refreshBedding =>
      english
          ? 'Prepare a clean, soft resting place for the next quiet moment.'
          : 'Bir sonraki sakin an için yumuşak ve temiz bir yatak hazırla.',
    CareStep.gentlePlay =>
      english
          ? 'The visitor is settled and hydrated. Offer a short, calm play session.'
          : 'Ziyaretçi sakinleşti ve su içti. Kısa, sakin bir oyun sun.',
    CareStep.calmRest =>
      english
          ? 'The visit is winding down. Finish with a quiet, comfortable rest.'
          : 'Ziyaret sona yaklaşıyor. Sessiz ve rahat bir dinlenmeyle bitir.',
  };

  String get semanticHint => switch (this) {
    CareStep.quietRoom => 'quiet',
    CareStep.freshWater => 'water',
    CareStep.towelDry => 'towel',
    CareStep.gentleBrush => 'groom',
    CareStep.refreshBedding => 'bed',
    CareStep.gentlePlay => 'play',
    CareStep.calmRest => 'rest',
  };
}

class PetCaseScenario {
  const PetCaseScenario({
    required this.level,
    required this.seed,
    required this.animal,
    required this.steps,
    required this.difficulty,
    required this.caseNote,
    required this.caseNoteTr,
  });

  final int level;
  final int seed;
  final RescueAnimal animal;
  final List<CareStep> steps;
  final int difficulty;
  final String caseNote;
  final String caseNoteTr;

  String get signature =>
      '$seed|${animal.name}|${steps.map((CareStep s) => s.name).join(',')}|$caseNote';
  String get planSignature =>
      '${animal.name}|${steps.map((CareStep s) => s.name).join(',')}|$caseNote';

  static const int campaignLevels = 20;
  static const int practiceCases = 300;
  static const List<CareStep> _careCycle = CareStep.values;
  static const List<String> _notes = <String>[
    'A rainy walk left the visitor damp and ready for a quiet welcome.',
    'The room is busy; prepare a gentle visit with water and a soft bed.',
    'A calm visitor arrives after a long trip and needs a soft reset.',
    'The coat needs care, then a little play and a comfortable goodbye.',
    'A quiet arrival and fresh bedding make this visit feel safe.',
  ];
  static const List<String> _notesTr = <String>[
    'Yağmurlu gezinti ziyaretçiyi ıslattı; sessiz bir karşılama iyi olur.',
    'Oda hareketli; su ve temiz yatakla sakin bir ziyaret hazırla.',
    'Uzun yolculuk sonrası gelen ziyaretçi yumuşak bir başlangıç istiyor.',
    'Tüy bakımı, kısa oyun ve rahat bir vedayı doğru sıraya koy.',
    'Sessiz karşılama ve temiz yatak bu ziyareti rahatlatacak.',
  ];

  static PetCaseScenario forLevel(int level) {
    final int safe = level.clamp(1, campaignLevels).toInt();
    final int count = switch (safe) {
      <= 3 => 3,
      <= 6 => 4,
      <= 10 => 5,
      <= 15 => 6,
      _ => 7,
    };
    final int offset = safe % _careCycle.length;
    final List<CareStep> shuffled = List<CareStep>.generate(
      _careCycle.length,
      (int i) => _careCycle[(offset + i * 2) % _careCycle.length],
    );
    // The affine order is verified for uniqueness: it has a coprime stride over 7.
    return PetCaseScenario(
      level: safe,
      seed: 33000 + safe * 197,
      animal: RescueAnimal.values[(safe - 1) % RescueAnimal.values.length],
      steps: List<CareStep>.unmodifiable(shuffled.take(count)),
      difficulty: safe,
      caseNote: _notes[(safe - 1) % _notes.length],
      caseNoteTr: _notesTr[(safe - 1) % _notesTr.length],
    );
  }

  static PetCaseScenario forPractice(int index) {
    final int safe = index.clamp(1, practiceCases).toInt();
    final math.Random random = math.Random(0xCAFE + safe * 6151);
    final int count = 3 + safe % 5;
    final List<CareStep> bag = List<CareStep>.of(CareStep.values)
      ..shuffle(random);
    final RescueAnimal animal =
        RescueAnimal.values[random.nextInt(RescueAnimal.values.length)];
    final int noteIndex = random.nextInt(_notes.length);
    final List<CareStep> steps = bag.take(count).toList();
    return PetCaseScenario(
      level: campaignLevels,
      seed: 500000 + safe * 2683,
      animal: animal,
      steps: List<CareStep>.unmodifiable(steps),
      difficulty: safe,
      caseNote: '${_notes[noteIndex]} · ${safe % 17} ${animal.name}',
      caseNoteTr:
          '${_notesTr[noteIndex]} · ${safe % 17} ${animal.label(false)}',
    );
  }
}
