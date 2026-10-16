import '../target_24/target_24_puzzle.dart';

import 'dart:convert';

import 'package:flutter/services.dart';

import '../kenken_cube/kenken_cube_puzzle.dart';
import '../mine_detector/mine_detector_puzzle.dart';
import '../parking_puzzle/parking_puzzle.dart';
import '../picross_master/picross_puzzle.dart';
import '../loop_master/loop_puzzle.dart';
import '../island_sea/island_sea_puzzle.dart';
import '../arrow_route/arrow_puzzle.dart';
import '../chess_mate/chess_mate_puzzle.dart';
import '../futoshiki/futoshiki_puzzle.dart';
import '../skyscrapers/skyscrapers_puzzle.dart';
import '../hitori/hitori_puzzle.dart';

/// Solver-certified release data. Only the selected game's compact bank is
/// decoded; expensive search never runs on the UI thread during normal play.
abstract final class CampaignAssetBank {
  static final Map<String, Future<void>> _loads = {};
  static final Set<String> _ready = {};
  static const gameIds = {
    'target_24',
    'kenken_cube',
    'mine_detective',
    'parking_puzzle',
    'picross_master',
    'loop_master',
    'island_sea',
    'arrow_route',
    'mini_chess_tactics',
    'futoshiki',
    'skyscrapers',
    'hitori',
  };
  static Future<void> prepare(String id) {
    if (!gameIds.contains(id) || _ready.contains(id)) {
      return Future<void>.value();
    }
    return _loads
        .putIfAbsent(id, () async {
          final source = await rootBundle.loadString(
            'assets/campaign300/$id.json',
          );
          final boards = jsonDecode(source) as List<dynamic>;
          switch (id) {
            case 'target_24':
              Target24Puzzle.installCampaignBank(boards);
            case 'kenken_cube':
              KenKenPuzzle.installCampaignBank(boards);
            case 'mine_detective':
              MineDetectorPuzzle.installCampaignBank(boards);
            case 'parking_puzzle':
              ParkingPuzzle.installCampaignBank(boards);
            case 'picross_master':
              PicrossPuzzle.installCampaignBank(boards);
            case 'loop_master':
              LoopPuzzle.installCampaignBank(boards);
            case 'island_sea':
              IslandSeaPuzzle.installCampaignBank(boards);
            case 'arrow_route':
              ArrowPuzzle.installCampaignBank(boards);
            case 'mini_chess_tactics':
              ChessMatePuzzle.installCampaignBank(boards);
            case 'futoshiki':
              FutoshikiPuzzle.installCampaignBank(boards);
            case 'skyscrapers':
              SkyscrapersPuzzle.installCampaignBank(boards);
            case 'hitori':
              HitoriPuzzle.installCampaignBank(boards);
          }
          _ready.add(id);
        })
        .catchError((Object error, StackTrace trace) {
          _loads.remove(id);
          Error.throwWithStackTrace(error, trace);
        });
  }
}
