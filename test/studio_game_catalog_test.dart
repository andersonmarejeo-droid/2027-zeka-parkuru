import 'package:flutter_test/flutter_test.dart';
import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';

void main() {
  test('catalog has stable, unique entries and class coverage', () {
    final Set<String> ids = StudioGameCatalog.games
        .map((GameDefinition game) => game.id)
        .toSet();
    final Set<int> orders = StudioGameCatalog.games
        .map((GameDefinition game) => game.order)
        .toSet();

    expect(StudioGameCatalog.games, hasLength(133));
    expect(ids, hasLength(133));
    expect(
      StudioGameCatalog.games.where(
        (GameDefinition game) => game.gameClass == StudioGameClass.fun,
      ),
      hasLength(45),
    );
    expect(
      orders,
      equals(Set<int>.from(List<int>.generate(133, (i) => i + 1))),
    );
    expect(StudioGameCatalog.playable, hasLength(44));
    expect(StudioGameCatalog.inClass(StudioGameClass.fun), hasLength(5));
    expect(StudioGameCatalog.playableCountFor(StudioGameClass.fun), 0);
    expect(StudioGameCatalog.plannedCountFor(StudioGameClass.fun), 5);
    for (final String id in <String>[
      'tiny_chef_dash',
      'treasure_trail',
      'jungle_jump',
      'comet_courier',
      'color_carnival',
    ]) {
      expect(StudioGameCatalog.byId(id)?.isPlayable, isFalse);
    }
    expect(
      StudioGameCatalog.inClass(StudioGameClass.speed)
          .any((GameDefinition game) => game.id == 'slide_sweets'),
      isTrue,
    );
    expect(
      StudioGameCatalog.byId('focus_filter')?.gameClass,
      StudioGameClass.speed,
    );
    expect(
      StudioGameCatalog.inClass(StudioGameClass.memory)
          .any((GameDefinition game) => game.id == 'focus_filter'),
      isFalse,
    );
    expect(StudioGameCatalog.retiredGameIds, hasLength(61));
    expect(StudioGameCatalog.byId('city_atlas')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('world_atlas')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('katamino_workshop')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('single_stroke')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('arrow_maze')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('bubble_shooter')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('spot_change')?.isPlayable, isFalse);
    expect(
      StudioGameCatalog.byId('bubble_shooter')?.gameClass,
      StudioGameClass.fun,
    );
  });

  test('shipped games keep their known catalog identities', () {
    expect(StudioGameCatalog.byId('blocks')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('flow_connect')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('circuit_repair')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('beam_director')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('detective_notes')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('bridge_builder')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('drift_league')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('table_tennis_rally')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('penalty_mindgame')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('air_hockey_arena')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('relic_run')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('lighthouse_defense')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('museum_after_hours')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('deep_current')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('cafe_shift')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('interior_studio')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('tideglass_aquarium')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('pet_rescue_clinic')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('boardwalk_builder')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('moonbase_ops')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('museum_curator')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('festival_producer')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('secret_room_party')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('dice_bluff_arena')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('signal_pair')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('deckforge_duel')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('gate_sequence')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('mine_detective')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('mine_detective')?.isRetired, isTrue);
    expect(StudioGameCatalog.byId('warehouse_master')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('word_wheel')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('meaning_match')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('proverb_finish')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('sentence_builder')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('near_meaning')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('letter_maze')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('language_detective')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('story_order')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('light_sequence')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('light_sequence')?.isRetired, isTrue);
    expect(StudioGameCatalog.byId('card_pairs')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('focus_filter')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('spot_change')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('rhythm_memory')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('attention_tunnel')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('symbol_stream')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('silent_count')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('dual_task')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('hidden_masses')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('kakuro')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('reversi_arena')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('picross_master')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('tavla_master')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('arrow_route')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('mini_chess_tactics')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('loop_master')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('go_life_death')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('code_breaker')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('shogi_mate')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('island_sea')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('peg_solitaire')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('futoshiki')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('hex_connection')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('skyscrapers')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('hitori')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('jetpack_courier')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('orbit_rescue')?.isPlayable, isFalse);
    expect(
      StudioGameCatalog.byId('picross_master')?.gameClass,
      StudioGameClass.visual,
    );
    expect(
      StudioGameCatalog.byId('tavla_master')?.gameClass,
      StudioGameClass.strategy,
    );
    expect(
      StudioGameCatalog.byId('arrow_route')?.gameClass,
      StudioGameClass.visual,
    );
    expect(
      StudioGameCatalog.byId('mini_chess_tactics')?.gameClass,
      StudioGameClass.strategy,
    );
    expect(
      StudioGameCatalog.byId('loop_master')?.gameClass,
      StudioGameClass.logic,
    );
    expect(
      StudioGameCatalog.byId('go_life_death')?.gameClass,
      StudioGameClass.strategy,
    );
    expect(
      StudioGameCatalog.byId('code_breaker')?.gameClass,
      StudioGameClass.logic,
    );
    expect(
      StudioGameCatalog.byId('shogi_mate')?.gameClass,
      StudioGameClass.strategy,
    );
    expect(
      StudioGameCatalog.byId('island_sea')?.gameClass,
      StudioGameClass.logic,
    );
    expect(
      StudioGameCatalog.byId('peg_solitaire')?.gameClass,
      StudioGameClass.strategy,
    );
    expect(
      StudioGameCatalog.byId('futoshiki')?.gameClass,
      StudioGameClass.numbers,
    );
    expect(
      StudioGameCatalog.byId('hex_connection')?.gameClass,
      StudioGameClass.strategy,
    );
    expect(
      StudioGameCatalog.byId('skyscrapers')?.gameClass,
      StudioGameClass.logic,
    );
    expect(StudioGameCatalog.byId('hitori')?.gameClass, StudioGameClass.logic);
    expect(StudioGameCatalog.byId('balloon_pop')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('balloon_pop')?.titleTr, 'Balon Avcısı');
    expect(StudioGameCatalog.byId('bottle_target')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('bottle_target')?.titleTr, 'Şişe Kırmaca');
    expect(StudioGameCatalog.byId('color_match')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('color_match')?.titleTr, 'Renk Reaktörü');
    expect(StudioGameCatalog.byId('ball_merge')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('ball_merge')?.titleTr, 'Top Birleştir');
    expect(StudioGameCatalog.byId('tower_balance')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('tower_balance')?.titleTr, 'Kule Denge');
    expect(StudioGameCatalog.byId('magnet_path')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('magnet_path')?.titleTr, 'Mıknatıs Rotası');
    expect(StudioGameCatalog.byId('mini_golf_route')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('pin_unlock')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('candy_sort')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('candy_sort')?.titleTr, 'Şeker Sıralama');
    expect(
      StudioGameCatalog.byId('mini_golf_route')?.titleTr,
      'Mini Golf Rota',
    );
    expect(StudioGameCatalog.byId('slide_sweets')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('slide_sweets')?.titleTr, 'Şeker Konveyörü');
    expect(
      StudioGameCatalog.byId('slide_sweets')?.gameClass,
      StudioGameClass.speed,
    );
    expect(StudioGameCatalog.byId('ring_toss')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('little_fisher')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('marble_route')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('block_flow')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('paper_flight')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('neon_pinball')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('neon_pinball')?.titleEn, 'Neon Pinball');
    expect(StudioGameCatalog.byId('kite_runner')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('kite_runner')?.titleTr, 'Uçurtma Pilotu');
    expect(StudioGameCatalog.byId('rhythm_drums')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('rhythm_drums')?.titleTr, 'Ritim Atölyesi');
    expect(StudioGameCatalog.byId('skate_combo')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('skate_combo')?.titleTr, 'Kaykay Akışı');
    expect(StudioGameCatalog.byId('snowboard_slalom')?.isPlayable, isFalse);
    expect(
      StudioGameCatalog.byId('snowboard_slalom')?.titleTr,
      'Kar Sörfü Slalomu',
    );
    expect(
      StudioGameCatalog.byId('balloon_pop')?.gameClass,
      StudioGameClass.fun,
    );
    expect(
      StudioGameCatalog.byId('reversi_arena')?.gameClass,
      StudioGameClass.strategy,
    );
    expect(
      StudioGameCatalog.byId('kakuro')?.gameClass,
      StudioGameClass.numbers,
    );
    expect(
      StudioGameCatalog.byId('hidden_masses')?.gameClass,
      StudioGameClass.logic,
    );
    expect(StudioGameCatalog.byId('parking_puzzle')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('pin_unlock')?.isPlayable, isFalse);
    expect(StudioGameCatalog.byId('balance_scale')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('target_24')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('mini_sudoku')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('kenken_cube')?.isPlayable, isTrue);
    expect(StudioGameCatalog.byId('mahjong_layers')?.isPlayable, isFalse);
    expect(
      StudioGameCatalog.byId('word_hunt')?.gameClass,
      StudioGameClass.language,
    );
    expect(StudioGameCatalog.byId('block_flow')?.isPlayable, isFalse);
    expect(
      StudioGameCatalog.byId('neon_pinball')?.gameClass,
      StudioGameClass.fun,
    );
    expect(
      StudioGameCatalog.byId('kite_runner')?.gameClass,
      StudioGameClass.fun,
    );
  });
}
