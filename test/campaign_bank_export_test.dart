import 'package:zeka_parkuru/games/target_24/target_24_puzzle.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/games/kenken_cube/kenken_cube_puzzle.dart';
import 'package:zeka_parkuru/games/mine_detector/mine_detector_puzzle.dart';
import 'package:zeka_parkuru/games/parking_puzzle/parking_puzzle.dart';
import 'package:zeka_parkuru/games/picross_master/picross_puzzle.dart';
import 'package:zeka_parkuru/games/loop_master/loop_puzzle.dart';
import 'package:zeka_parkuru/games/island_sea/island_sea_puzzle.dart';
import 'package:zeka_parkuru/games/arrow_route/arrow_puzzle.dart';
import 'package:zeka_parkuru/games/chess_mate/chess_mate_puzzle.dart';
import 'package:zeka_parkuru/games/futoshiki/futoshiki_puzzle.dart';
import 'package:zeka_parkuru/games/skyscrapers/skyscrapers_puzzle.dart';
import 'package:zeka_parkuru/games/hitori/hitori_puzzle.dart';

void main() {
  test('export target_24: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(300, (i) => Target24Puzzle.forLevel(i + 1));
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    Target24Puzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(Target24Puzzle.forLevel(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/target_24.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('export kenken_cube: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(300, (i) => KenKenPuzzle.forLevel(i + 1));
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    KenKenPuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(KenKenPuzzle.forLevel(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/kenken_cube.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('export mine_detective: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(
      300,
      (i) => MineDetectorPuzzle.forLevel(i + 1),
    );
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    MineDetectorPuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(MineDetectorPuzzle.forLevel(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/mine_detective.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('export parking_puzzle: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(300, (i) => ParkingPuzzle.forLevel(i + 1));
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    ParkingPuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(ParkingPuzzle.forLevel(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/parking_puzzle.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('export picross_master: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(
      300,
      (i) => PicrossPuzzle.forPracticeBoard(i + 1),
    );
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    PicrossPuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(PicrossPuzzle.forPracticeBoard(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/picross_master.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('export loop_master: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(
      300,
      (i) => LoopPuzzle.forPracticeBoard(i + 1),
    );
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    LoopPuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(LoopPuzzle.forPracticeBoard(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/loop_master.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('export island_sea: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(
      300,
      (i) => IslandSeaPuzzle.forPracticeBoard(i + 1),
    );
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    IslandSeaPuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(IslandSeaPuzzle.forPracticeBoard(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/island_sea.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('export arrow_route: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(
      300,
      (i) => ArrowPuzzle.forPracticeBoard(i + 1),
    );
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    ArrowPuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(ArrowPuzzle.forPracticeBoard(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/arrow_route.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('export mini_chess_tactics: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(
      300,
      (i) => ChessMatePuzzle.forPracticeBoard(i + 1),
    );
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    ChessMatePuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(ChessMatePuzzle.forPracticeBoard(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/mini_chess_tactics.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('export futoshiki: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(
      300,
      (i) => FutoshikiPuzzle.forPracticeBoard(i + 1),
    );
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    FutoshikiPuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(FutoshikiPuzzle.forPracticeBoard(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/futoshiki.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('export skyscrapers: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(
      300,
      (i) => SkyscrapersPuzzle.forPracticeBoard(i + 1),
    );
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    SkyscrapersPuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(
        SkyscrapersPuzzle.forPracticeBoard(i + 1).toCampaignMap(),
        maps[i],
      );
    }
    await File('${directory.path}/skyscrapers.json')
        .writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('export hitori: 300 solver-certified boards', () async {
    final directory = Directory('assets/campaign300');
    await directory.create(recursive: true);
    final boards = List.generate(
      300,
      (i) => HitoriPuzzle.forPracticeBoard(i + 1),
    );
    final maps = boards.map((board) => board.toCampaignMap()).toList();
    HitoriPuzzle.installCampaignBank(
      jsonDecode(jsonEncode(maps)) as List<dynamic>,
    );
    for (int i = 0; i < 300; i++) {
      expect(HitoriPuzzle.forPracticeBoard(i + 1).toCampaignMap(), maps[i]);
    }
    await File('${directory.path}/hitori.json').writeAsString(jsonEncode(maps));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
