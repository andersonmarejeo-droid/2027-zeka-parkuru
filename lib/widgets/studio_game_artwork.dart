import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../games/chess_mate/chess_mate_puzzle.dart';
import '../games/chess_mate/chess_piece_painter.dart';
import '../games/reference_games/atlas_map_painter.dart';
import '../games/reference_games/atlas_puzzle.dart';
import '../games/shared/game_visual_design.dart';
import '../theme/studio_visuals.dart';

/// A crop from one of the reviewed category concept sheets. The source sheets
/// are deliberately kept as a single asset so the artwork can be audited and
/// replaced without duplicating or recompressing every tile.
class _CatalogArtworkCrop {
  const _CatalogArtworkCrop({
    required this.asset,
    required this.index,
    this.columns = 2,
    this.rows = 4,
    this.hasLabelBand = true,
  });

  final String asset;
  final int index;
  final int columns;
  final int rows;
  final bool hasLabelBand;

  int get column => index % columns;
  int get row => index ~/ columns;
}

const Map<String, _CatalogArtworkCrop> _catalogArtwork =
    <String, _CatalogArtworkCrop>{
      // Mantık ve çözüm
      'detective_notes': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/logic_sheet_v2.webp',
        index: 0,
        hasLabelBand: false,
      ),
      'circuit_repair': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/logic_sheet_v2.webp',
        index: 1,
        hasLabelBand: false,
      ),
      'bridge_builder': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/logic_sheet_v2.webp',
        index: 2,
        hasLabelBand: false,
      ),
      'island_sea': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/logic_sheet_v2.webp',
        index: 3,
        hasLabelBand: false,
      ),
      'skyscrapers': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/logic_sheet_v2.webp',
        index: 4,
        hasLabelBand: false,
      ),
      'hitori': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/logic_sheet_v2.webp',
        index: 5,
        hasLabelBand: false,
      ),
      'code_breaker': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/logic_sheet_v2.webp',
        index: 6,
        hasLabelBand: false,
      ),
      'beam_director': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/logic_sheet_v2.webp',
        index: 7,
        hasLabelBand: false,
      ),

      // Sayılar
      'numbers': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/numbers_sheet_v2.webp',
        index: 0,
        hasLabelBand: false,
      ),
      'number_sort': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/numbers_sheet_v2.webp',
        index: 1,
        hasLabelBand: false,
      ),
      'target_24': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/numbers_sheet_v2.webp',
        index: 2,
        hasLabelBand: false,
      ),
      'mini_sudoku': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/numbers_sheet_v2.webp',
        index: 3,
        hasLabelBand: false,
      ),
      'kenken_cube': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/numbers_sheet_v2.webp',
        index: 4,
        hasLabelBand: false,
      ),
      'kakuro': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/numbers_sheet_v2.webp',
        index: 5,
        hasLabelBand: false,
      ),
      'fraction_factory': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/numbers_sheet_v2.webp',
        index: 6,
        hasLabelBand: false,
      ),
      'clock_master': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/numbers_sheet_v2.webp',
        index: 7,
        hasLabelBand: false,
      ),
      'balance_scale': _CatalogArtworkCrop(
        asset: 'assets/game_visuals/weight_objects_sheet.webp',
        index: 0,
        columns: 3,
        rows: 3,
        hasLabelBand: false,
      ),
      'hidden_masses': _CatalogArtworkCrop(
        asset: 'assets/game_visuals/weight_objects_sheet.webp',
        index: 7,
        columns: 3,
        rows: 3,
        hasLabelBand: false,
      ),

      // Görsel ve uzamsal
      'blocks': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/visual_sheet.webp',
        index: 0,
      ),
      'picture_iq': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/visual_sheet_v2.webp',
        index: 1,
        hasLabelBand: false,
      ),
      'shape_puzzle': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/visual_sheet_v2.webp',
        index: 2,
        hasLabelBand: false,
      ),
      'shadow_match': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/visual_sheet_v2.webp',
        index: 3,
        hasLabelBand: false,
      ),
      'perspective_cube': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/visual_sheet_v2.webp',
        index: 4,
        hasLabelBand: false,
      ),
      'piece_park': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/visual_sheet_v2.webp',
        index: 5,
        hasLabelBand: false,
      ),
      'mirror_symmetry': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/visual_sheet_v2.webp',
        index: 6,
        hasLabelBand: false,
      ),
      'mahjong_layers': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/visual_sheet_v2.webp',
        index: 7,
        hasLabelBand: false,
      ),

      // Hafıza ve dikkat (strict 2×4 final sheet)
      'memory': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/memory_sheet_v2.webp',
        index: 0,
        hasLabelBand: false,
      ),
      'light_sequence': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/memory_sheet_v2.webp',
        index: 1,
        hasLabelBand: false,
      ),
      'card_pairs': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/memory_sheet_v2.webp',
        index: 2,
        hasLabelBand: false,
      ),
      'spot_change': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/memory_sheet_v2.webp',
        index: 3,
        hasLabelBand: false,
      ),
      'rhythm_memory': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/memory_sheet_v2.webp',
        index: 4,
        hasLabelBand: false,
      ),
      'silent_count': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/memory_sheet_v2.webp',
        index: 6,
        hasLabelBand: false,
      ),
      'attention_tunnel': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/memory_sheet_v2.webp',
        index: 7,
        hasLabelBand: false,
      ),
      'dual_task': _CatalogArtworkCrop(
        asset: 'assets/game_visuals/realistic_tokens_sheet.webp',
        index: 5,
        columns: 4,
        rows: 3,
        hasLabelBand: false,
      ),
      'symbol_stream': _CatalogArtworkCrop(
        asset: 'assets/game_visuals/realistic_tokens_sheet.webp',
        index: 10,
        columns: 4,
        rows: 3,
        hasLabelBand: false,
      ),
      'focus_filter': _CatalogArtworkCrop(
        asset: 'assets/focus_filter/focus_shapes_sheet.webp',
        index: 4,
        columns: 4,
        rows: 3,
        hasLabelBand: false,
      ),

      // Planlama ve strateji
      'hanoi': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/strategy_sheet.webp',
        index: 0,
      ),
      'candy_sort': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/strategy_sheet.webp',
        index: 1,
      ),
      'parking_puzzle': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/strategy_sheet_v2.webp',
        index: 2,
        hasLabelBand: false,
      ),
      'resource_route': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/strategy_sheet_v2.webp',
        index: 3,
        hasLabelBand: false,
      ),
      'garden_order': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/strategy_sheet_v2.webp',
        index: 4,
        hasLabelBand: false,
      ),
      'warehouse_master': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/strategy_sheet_v2.webp',
        index: 5,
        hasLabelBand: false,
      ),
      'mini_chess_tactics': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/strategy_sheet_v2.webp',
        index: 6,
        hasLabelBand: false,
      ),
      'timeline_planner': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/strategy_sheet_v2.webp',
        index: 7,
        hasLabelBand: false,
      ),

      // Dil ve kelime
      'word_hunt': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/language_sheet_v2.webp',
        index: 0,
        hasLabelBand: false,
      ),
      'meaning_match': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/language_sheet_v2.webp',
        index: 1,
        hasLabelBand: false,
      ),
      'proverb_finish': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/language_sheet_v2.webp',
        index: 2,
        hasLabelBand: false,
      ),
      'word_wheel': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/language_sheet_v2.webp',
        index: 3,
        hasLabelBand: false,
      ),
      'sentence_builder': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/language_sheet_v2.webp',
        index: 4,
        hasLabelBand: false,
      ),
      'near_meaning': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/language_sheet_v2.webp',
        index: 5,
        hasLabelBand: false,
      ),
      'letter_maze': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/language_sheet_v2.webp',
        index: 6,
        hasLabelBand: false,
      ),
      'story_order': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/language_sheet_v2.webp',
        index: 7,
        hasLabelBand: false,
      ),
      'language_detective': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/language_detective_icon_v2.webp',
        index: 0,
        columns: 1,
        rows: 1,
        hasLabelBand: false,
      ),

      // Hız ve tepki
      'reflex': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/speed_sheet_v2.webp',
        index: 0,
        hasLabelBand: false,
      ),
      'color_brake': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/speed_sheet_v2.webp',
        index: 1,
        hasLabelBand: false,
      ),
      'target_rain': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/speed_sheet_v2.webp',
        index: 2,
        hasLabelBand: false,
      ),
      'direction_switch': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/speed_sheet_v2.webp',
        index: 3,
        hasLabelBand: false,
      ),
      'silent_alarm': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/speed_sheet_v2.webp',
        index: 4,
        hasLabelBand: false,
      ),
      'double_tap': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/speed_sheet_v2.webp',
        index: 5,
        hasLabelBand: false,
      ),
      'time_gate': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/speed_sheet_v2.webp',
        index: 6,
        hasLabelBand: false,
      ),
      'route_sprint': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/speed_sheet_v2.webp',
        index: 7,
        hasLabelBand: false,
      ),

      // Eğlence oyunları
      'block_flow': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/fun_sheet.webp',
        index: 0,
      ),
      'balloon_pop': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/fun_sheet_v2.webp',
        index: 1,
        hasLabelBand: false,
      ),
      'bottle_target': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/fun_sheet_v2.webp',
        index: 2,
        hasLabelBand: false,
      ),
      'color_match': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/fun_sheet_v2.webp',
        index: 3,
        hasLabelBand: false,
      ),
      'ball_merge': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/fun_sheet_v2.webp',
        index: 4,
        hasLabelBand: false,
      ),
      'tower_balance': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/fun_sheet_v2.webp',
        index: 5,
        hasLabelBand: false,
      ),
      'magnet_path': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/fun_sheet_v2.webp',
        index: 6,
        hasLabelBand: false,
      ),
      'mini_golf_route': _CatalogArtworkCrop(
        asset: 'assets/branding/game_catalog/fun_sheet_v2.webp',
        index: 7,
        hasLabelBand: false,
      ),
    };

/// Literal, resolution-independent previews of the game objects. These are
/// backed by reviewed category artwork where available, with the deterministic
/// painter retained for routes and legacy ids that do not have an authored tile.
class StudioGameArtwork extends StatelessWidget {
  const StudioGameArtwork({
    super.key,
    required this.gameId,
    this.variant = 0,
    this.locked = false,
  });

  final String gameId;
  final int variant;
  final bool locked;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: gameId == 'candy_sort'
          ? _DirectCatalogArtwork(
              asset: 'assets/branding/game_catalog/candy_sort_icon.webp',
              locked: locked,
            )
          : _catalogArtwork.containsKey(gameId)
          ? _CatalogSheetArtwork(crop: _catalogArtwork[gameId]!, locked: locked)
          : gameId == 'city_atlas' || gameId == 'world_atlas'
          ? FutureBuilder<List<AtlasFeature>>(
              initialData: AtlasDataset.cached(
                gameId == 'city_atlas' ? AtlasKind.turkey : AtlasKind.world,
              ),
              future: AtlasDataset.load(
                gameId == 'city_atlas' ? AtlasKind.turkey : AtlasKind.world,
              ),
              builder: (context, snapshot) => CustomPaint(
                painter: snapshot.hasData
                    ? _AtlasArtworkPainter(gameId, snapshot.data!, locked)
                    : _GameArtworkPainter(gameId, variant, locked),
                size: const Size(160, 132),
                isComplex: true,
              ),
            )
          : CustomPaint(
              painter: _GameArtworkPainter(gameId, variant, locked),
              size: const Size(160, 132),
              isComplex: true,
            ),
    ),
  );
}

class _DirectCatalogArtwork extends StatelessWidget {
  const _DirectCatalogArtwork({required this.asset, required this.locked});

  final String asset;
  final bool locked;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
      if (locked)
        Positioned.fill(
          child: ColoredBox(color: Colors.white.withValues(alpha: .58)),
        ),
    ],
  );
}

class _CatalogSheetArtwork extends StatelessWidget {
  const _CatalogSheetArtwork({required this.crop, required this.locked});

  final _CatalogArtworkCrop crop;
  final bool locked;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final double width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : 160;
      final double height = constraints.hasBoundedHeight
          ? constraints.maxHeight
          : 132;
      // The concept sheets reserve a lower label band for presentation. Crop
      // that band out of the in-app tile while keeping the artwork's original
      // card proportions and gutters.
      final double sourceRowScale = crop.hasLabelBand ? 1.16 : 1;
      // The refreshed v2 sheets contain true 4:3 tiles. The catalog slot is
      // slightly narrower than 4:3, so scale from height and crop the excess
      // horizontally instead of stretching the artwork vertically.
      final bool preserveTileAspect = crop.asset.contains('_v2.');
      final double sourceTileWidth = preserveTileAspect
          ? height * 4 / 3
          : width;
      final double horizontalCrop = preserveTileAspect
          ? (sourceTileWidth - width) / 2
          : 0;
      final double imageWidth = sourceTileWidth * crop.columns;
      final double imageHeight = height * crop.rows * sourceRowScale;
      return SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                left: -crop.column * sourceTileWidth - horizontalCrop,
                top: -crop.row * height * sourceRowScale,
                width: imageWidth,
                height: imageHeight,
                child: Image.asset(
                  crop.asset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
              ),
              if (locked)
                Positioned.fill(
                  child: ColoredBox(color: Colors.white.withValues(alpha: .58)),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _AtlasArtworkPainter extends CustomPainter {
  const _AtlasArtworkPainter(this.gameId, this.features, this.locked);
  final String gameId;
  final List<AtlasFeature> features;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final bool turkey = gameId == 'city_atlas';
    canvas.save();
    canvas.scale(size.width / 160, size.height / 132);
    final background = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 160, 132),
      const Radius.circular(18),
    );
    canvas.drawRRect(background, Paint()..color = StudioVisuals.surfaceSoft);
    canvas.save();
    canvas.translate(8, turkey ? 37 : 15);
    AtlasMapPainter(
      kind: turkey ? AtlasKind.turkey : AtlasKind.world,
      features: features,
    ).paint(canvas, Size(144, turkey ? 54 : 86));
    canvas.restore();
    final label = TextPainter(
      text: TextSpan(
        text: turkey ? '81' : '200+',
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: StudioVisuals.tealInk,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(80 - label.width / 2, 106));
    if (locked) {
      canvas.drawRRect(
        background,
        Paint()..color = Colors.white.withValues(alpha: .58),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AtlasArtworkPainter oldDelegate) =>
      gameId != oldDelegate.gameId ||
      features != oldDelegate.features ||
      locked != oldDelegate.locked;
}

class _GameArtworkPainter extends CustomPainter {
  const _GameArtworkPainter(this.gameId, this.variant, this.locked);
  final String gameId;
  final int variant;
  final bool locked;

  Color get accent => GameVisualDesign.forGame(gameId).accent;

  void _panel(Canvas c, Rect r, Color color, {double radius = 8}) {
    final RRect shape = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawShadow(Path()..addRRect(shape), const Color(0xFF33463D), 4, false);
    final Color highlight = Color.lerp(color, Colors.white, .18)!;
    final Color shade = Color.lerp(color, Colors.black, .13)!;
    c.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[highlight, color, shade],
          stops: const <double>[0, .46, 1],
        ).createShader(r),
    );
    c.drawRRect(
      shape,
      Paint()
        ..color = Color.lerp(color, const Color(0xFF6D8075), .34)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9,
    );
    c.drawLine(
      Offset(r.left + radius, r.top + 1.5),
      Offset(r.right - radius, r.top + 1.5),
      Paint()
        ..color = Colors.white.withValues(alpha: .72)
        ..strokeWidth = 1.15,
    );
    c.drawLine(
      Offset(r.left + radius, r.bottom - 1.5),
      Offset(r.right - radius, r.bottom - 1.5),
      Paint()
        ..color = Colors.black.withValues(alpha: .08)
        ..strokeWidth = .9,
    );
  }

  void _text(Canvas c, String value, Offset center, double size, Color color) {
    final TextPainter text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(c, center - Offset(text.width / 2, text.height / 2));
  }

  void _icon(Canvas c, IconData icon, Offset center, double size, Color color) {
    final TextPainter text = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(c, center - Offset(text.width / 2, text.height / 2));
  }

  void _grid(
    Canvas c,
    int n,
    List<String> values, {
    Set<int> filled = const {},
    bool wood = false,
    Color? boardColor,
    Color? cellColor,
    Color? filledColor,
  }) {
    _panel(
      c,
      const Rect.fromLTWH(20, 12, 120, 108),
      boardColor ?? (wood ? const Color(0xFFAB7C52) : const Color(0xFFD6E2DA)),
    );
    final double cell = 96 / n;
    for (int i = 0; i < n * n; i++) {
      final Rect r = Rect.fromLTWH(
        32 + i % n * cell,
        18 + i ~/ n * cell,
        cell - 2,
        cell - 2,
      );
      final Color surface = filled.contains(i)
          ? (filledColor ?? accent)
          : cellColor ??
                (wood ? const Color(0xFFE4CBA5) : const Color(0xFFFAFBF7));
      _panel(c, r, surface, radius: 3);
      if (i < values.length && values[i].isNotEmpty) {
        final String value = values[i];
        final Paint shape = Paint()..color = accent;
        if (value == '●') {
          c.drawCircle(r.center, r.width * .24, shape);
          continue;
        }
        if (value == '▲') {
          c.drawPath(
            Path()
              ..moveTo(r.center.dx, r.top + r.height * .22)
              ..lineTo(r.right - r.width * .22, r.bottom - r.height * .22)
              ..lineTo(r.left + r.width * .22, r.bottom - r.height * .22)
              ..close(),
            shape,
          );
          continue;
        }
        if (value == '■') {
          c.drawRect(
            Rect.fromCenter(
              center: r.center,
              width: r.width * .5,
              height: r.height * .5,
            ),
            shape,
          );
          continue;
        }
        _text(
          c,
          values[i],
          r.center,
          n == 4 ? 15 : 18,
          filled.contains(i) ? Colors.white : StudioVisuals.ink,
        );
      }
    }
  }

  void _route(
    Canvas c, {
    bool maze = false,
    bool arrows = false,
    bool loop = false,
  }) {
    _panel(c, const Rect.fromLTWH(14, 10, 132, 112), StudioVisuals.paper);
    final Paint grid = Paint()
      ..color = const Color(0xFFDDE5DC)
      ..strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      c.drawLine(Offset(30 + i * 25, 22), Offset(30 + i * 25, 110), grid);
      c.drawLine(Offset(28, 24 + i * 20), Offset(130, 24 + i * 20), grid);
    }
    final List<Offset> points = loop
        ? const [
            Offset(30, 44),
            Offset(55, 44),
            Offset(55, 24),
            Offset(105, 24),
            Offset(105, 64),
            Offset(130, 64),
            Offset(130, 104),
            Offset(30, 104),
            Offset(30, 44),
          ]
        : const [
            Offset(30, 104),
            Offset(55, 104),
            Offset(55, 64),
            Offset(80, 64),
            Offset(80, 84),
            Offset(105, 84),
            Offset(105, 24),
            Offset(130, 24),
          ];
    final Path p = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      p.lineTo(point.dx, point.dy);
    }
    c.drawPath(
      p,
      Paint()
        ..color = accent.withValues(alpha: .14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      p,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    if (maze) {
      c.drawLine(
        const Offset(27, 48),
        const Offset(49, 48),
        Paint()
          ..color = const Color(0xFF8B9F94)
          ..strokeWidth = 3,
      );
      c.drawLine(
        const Offset(85, 42),
        const Offset(99, 42),
        Paint()
          ..color = const Color(0xFF8B9F94)
          ..strokeWidth = 3,
      );
    }
    if (arrows) {
      _icon(c, Icons.arrow_forward_rounded, const Offset(78, 64), 21, accent);
      _icon(c, Icons.arrow_upward_rounded, const Offset(105, 48), 21, accent);
    }
    if (!loop) {
      c.drawCircle(points.first, 5, Paint()..color = const Color(0xFFB88137));
      _icon(c, Icons.flag_rounded, points.last, 22, accent);
    }
  }

  void _singleStroke(Canvas c) {
    _panel(c, const Rect.fromLTWH(14, 10, 132, 112), const Color(0xFFF3F0FA));
    final Paint grid = Paint()
      ..color = const Color(0xFFD9D2EC)
      ..strokeWidth = .8;
    for (int i = 0; i < 5; i++) {
      c.drawLine(Offset(28 + i * 26, 22), Offset(28 + i * 26, 110), grid);
      c.drawLine(Offset(28, 22 + i * 22), Offset(132, 22 + i * 22), grid);
    }
    const List<Offset> points = <Offset>[
      Offset(32, 101),
      Offset(32, 73),
      Offset(59, 73),
      Offset(59, 91),
      Offset(86, 91),
      Offset(86, 43),
      Offset(126, 43),
    ];
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final Offset point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB9A9E8).withValues(alpha: .34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF51419A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (int i = 0; i < points.length; i++) {
      final bool endpoint = i == 0 || i == points.length - 1;
      c.drawCircle(
        points[i],
        endpoint ? 7 : 5,
        Paint()..color = i == 0 ? const Color(0xFFC58A36) : Colors.white,
      );
      c.drawCircle(
        points[i],
        endpoint ? 7 : 5,
        Paint()
          ..color = const Color(0xFF51419A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
    _icon(c, Icons.flag_rounded, points.last, 15, const Color(0xFF51419A));
  }

  void _arrowMaze(Canvas c) {
    _panel(c, const Rect.fromLTWH(13, 9, 134, 114), const Color(0xFF123F4B));
    const int columns = 5;
    const double cell = 20;
    const double left = 29;
    const double top = 20;
    final Paint grid = Paint()
      ..color = const Color(0xFF3F7881)
      ..strokeWidth = 1;
    for (int i = 0; i <= columns; i++) {
      c.drawLine(
        Offset(left + i * cell, top),
        Offset(left + i * cell, top + columns * cell),
        grid,
      );
      c.drawLine(
        Offset(left, top + i * cell),
        Offset(left + columns * cell, top + i * cell),
        grid,
      );
    }
    const List<(int, int, int)> arrows = <(int, int, int)>[
      (1, 0, 1),
      (2, 0, 2),
      (3, 0, 1),
      (4, 0, 2),
      (1, 1, 2),
      (2, 1, 1),
      (3, 1, 2),
      (4, 1, 3),
      (2, 2, 1),
      (3, 2, 2),
      (4, 2, 2),
      (1, 3, 0),
      (2, 3, 1),
      (3, 3, 2),
      (4, 3, 1),
    ];
    for (final (int column, int row, int direction) in arrows) {
      final Offset center = Offset(
        left + column * cell + cell / 2,
        top + row * cell + cell / 2,
      );
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(direction * math.pi / 2);
      _icon(
        c,
        Icons.arrow_forward_rounded,
        Offset.zero,
        15,
        const Color(0xFF6FD1C1),
      );
      c.restore();
    }
    c.drawCircle(
      Offset(left + cell / 2, top + cell / 2),
      6,
      Paint()..color = const Color(0xFFF0B44C),
    );
    final Offset finish = Offset(
      left + 4 * cell + cell / 2,
      top + 4 * cell + cell / 2,
    );
    c.drawCircle(finish, 6, Paint()..color = const Color(0xFFE5A64A));
    _icon(c, Icons.flag_rounded, finish, 14, const Color(0xFF123F4B));
  }

  void _cards(Canvas c, {bool scene = false, bool story = false}) {
    for (int i = 0; i < 3; i++) {
      c.save();
      c.translate(34 + i * 43.0, 66);
      c.rotate((i - 1) * .08);
      _panel(c, const Rect.fromLTWH(-26, -43, 52, 86), const Color(0xFFFEFCF6));
      final IconData symbol = scene
          ? (i == 1 ? Icons.sailing_rounded : Icons.cottage_rounded)
          : story
          ? (i == 0
                ? Icons.eco_rounded
                : i == 1
                ? Icons.park_rounded
                : Icons.local_florist_rounded)
          : gameId == 'attention_tunnel'
          ? (i == 1 ? Icons.directions_car_rounded : Icons.cottage_rounded)
          : Icons.sailing_rounded;
      _icon(
        c,
        symbol,
        const Offset(0, -5),
        35,
        i == 1 ? accent : const Color(0xFF617C74),
      );
      c.drawLine(
        const Offset(-15, 27),
        const Offset(15, 27),
        Paint()
          ..color = accent.withValues(alpha: .35)
          ..strokeWidth = 2,
      );
      if (story) _text(c, '${i + 1}', const Offset(0, -30), 11, accent);
      c.restore();
    }
  }

  void _blocks(Canvas c, {bool parquet = false}) {
    _panel(
      c,
      const Rect.fromLTWH(15, 12, 130, 108),
      parquet ? const Color(0xFF8F6848) : const Color(0xFFC8D6D0),
    );
    const List<int> pieces = [
      0,
      0,
      1,
      1,
      2,
      0,
      3,
      1,
      2,
      2,
      3,
      3,
      1,
      2,
      4,
      4,
      3,
      4,
      4,
      4,
    ];
    const List<Color> colors = [
      Color(0xFF568E83),
      Color(0xFFBE8C50),
      Color(0xFF7284AD),
      Color(0xFFA56767),
      Color(0xFF7D9867),
    ];
    for (int i = 0; i < 20; i++) {
      final int piece = pieces[i];
      final Rect r = Rect.fromLTWH(
        23 + (i % 5) * 23.0,
        20 + (i ~/ 5) * 23.0,
        22,
        22,
      );
      final Color color = parquet
          ? Color.lerp(
              const Color(0xFF956340),
              const Color(0xFFE2BC80),
              piece / 4,
            )!
          : colors[piece];
      _panel(c, r, color, radius: 3);
      if (parquet) {
        for (int j = 0; j < 3; j++) {
          c.drawLine(
            Offset(r.left + 3, r.top + 5 + j * 5),
            Offset(r.right - 3, r.top + 4 + j * 5),
            Paint()
              ..color = const Color(0xFF6E4B31).withValues(alpha: .16)
              ..strokeWidth = .7,
          );
        }
      }
    }
  }

  void _balance(Canvas c, {bool hidden = false}) {
    _panel(
      c,
      const Rect.fromLTWH(14, 16, 132, 102),
      hidden ? const Color(0xFFD8E8E8) : const Color(0xFFEEE5D2),
    );
    final Paint metal = Paint()
      ..color = const Color(0xFF826747)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(80, 40), const Offset(80, 103), metal);
    c.drawLine(const Offset(41, 47), Offset(119, hidden ? 44 : 39), metal);
    _panel(
      c,
      const Rect.fromLTWH(57, 101, 46, 7),
      const Color(0xFF967245),
      radius: 2,
    );
    for (final double x in [43, 117]) {
      c.drawLine(Offset(x, 44), Offset(x - 17, 80), metal..strokeWidth = 1.4);
      c.drawLine(Offset(x, 44), Offset(x + 17, 80), metal);
      _panel(
        c,
        Rect.fromLTWH(x - 20, 79, 40, 6),
        const Color(0xFFAD895A),
        radius: 3,
      );
      if (hidden) {
        _panel(
          c,
          Rect.fromLTWH(x - 13, 57, 26, 24),
          x < 80 ? const Color(0xFF1D6271) : const Color(0xFFB47A2A),
          radius: 5,
        );
        c.drawLine(
          Offset(x - 8, 62),
          Offset(x + 8, 76),
          Paint()
            ..color = Colors.white.withValues(alpha: .55)
            ..strokeWidth = 1.5,
        );
        c.drawLine(
          Offset(x + 8, 62),
          Offset(x - 8, 76),
          Paint()
            ..color = Colors.white.withValues(alpha: .55)
            ..strokeWidth = 1.5,
        );
      } else {
        _panel(
          c,
          Rect.fromLTWH(x - 12, 58, 24, 22),
          x < 80 ? const Color(0xFF547B72) : const Color(0xFFBA8B58),
          radius: 4,
        );
        _text(c, x < 80 ? '?' : '8', Offset(x, 69), 14, Colors.white);
      }
    }
    c.drawCircle(
      const Offset(80, 43),
      4,
      Paint()..color = const Color(0xFFE0C68D),
    );
  }

  void _hiddenMasses(Canvas c) {
    _panel(c, const Rect.fromLTWH(13, 10, 134, 112), const Color(0xFF164B57));
    final Paint guide = Paint()
      ..color = const Color(0xFF75C1C1).withValues(alpha: .32)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      c.drawLine(Offset(24 + i * 29.0, 24), Offset(24 + i * 29.0, 108), guide);
    }
    for (int i = 0; i < 4; i++) {
      c.drawLine(Offset(24, 24 + i * 28.0), Offset(136, 24 + i * 28.0), guide);
    }
    final List<Color> boxes = <Color>[
      const Color(0xFF2B8990),
      const Color(0xFFB9782D),
      const Color(0xFF5A6FB0),
    ];
    for (int i = 0; i < 3; i++) {
      final double x = 29 + i * 37.0;
      _panel(c, Rect.fromLTWH(x, 47, 30, 31), boxes[i], radius: 6);
      c.drawLine(
        Offset(x + 5, 53),
        Offset(x + 25, 72),
        Paint()
          ..color = Colors.white.withValues(alpha: .46)
          ..strokeWidth = 1.4,
      );
      c.drawLine(
        Offset(x + 25, 53),
        Offset(x + 5, 72),
        Paint()
          ..color = Colors.white.withValues(alpha: .46)
          ..strokeWidth = 1.4,
      );
      _text(
        c,
        String.fromCharCode(65 + i),
        Offset(x + 15, 91),
        10,
        Colors.white,
      );
    }
    c.drawCircle(
      const Offset(116, 39),
      13,
      Paint()
        ..color = const Color(0xFFE5B55B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    c.drawLine(
      const Offset(125, 48),
      const Offset(135, 58),
      Paint()
        ..color = const Color(0xFFE5B55B)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    _text(c, '?', const Offset(116, 39), 13, const Color(0xFFE5B55B));
  }

  void _chess(Canvas c, {bool reversi = false}) {
    _panel(c, const Rect.fromLTWH(22, 10, 116, 112), const Color(0xFFB19A7B));
    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 4; x++) {
        final Rect r = Rect.fromLTWH(30 + x * 25.0, 16 + y * 25.0, 25, 25);
        c.drawRect(
          r,
          Paint()
            ..color = reversi
                ? const Color(0xFF337961)
                : (x + y) % 2 == 0
                ? const Color(0xFFEEE5D2)
                : const Color(0xFF7E9385),
        );
        if (reversi && y > 0 && y < 3 && x > 0 && x < 3) {
          c.drawCircle(
            r.center + const Offset(0, 1),
            10,
            Paint()..color = const Color(0xFF173F34),
          );
          c.drawCircle(
            r.center,
            9,
            Paint()
              ..color = (x + y) % 2 == 0
                  ? const Color(0xFFFBFAEF)
                  : const Color(0xFF273A3E),
          );
        }
      }
    }
    if (!reversi) {
      c.save();
      c.translate(48, 29);
      const ChessPiecePainter(
        piece: ChessPiece(ChessSide.black, ChessPieceType.queen),
      ).paint(c, const Size(40, 42));
      c.restore();
      c.save();
      c.translate(80, 70);
      const ChessPiecePainter(
        piece: ChessPiece(ChessSide.white, ChessPieceType.king),
      ).paint(c, const Size(40, 42));
      c.restore();
    }
  }

  void _hanoi(Canvas c) {
    _panel(c, const Rect.fromLTWH(13, 18, 134, 100), const Color(0xFFF1E7D8));
    _panel(
      c,
      const Rect.fromLTWH(21, 105, 118, 8),
      const Color(0xFF96704E),
      radius: 3,
    );
    for (final double x in [43, 80, 117]) {
      _panel(
        c,
        Rect.fromLTWH(x - 2, 35, 4, 70),
        const Color(0xFFC2A377),
        radius: 2,
      );
    }
    for (int i = 0; i < 4; i++) {
      _panel(
        c,
        Rect.fromLTWH(43 - 24 + i * 4.0, 96 - i * 12.0, 48 - i * 8.0, 11),
        Color.lerp(const Color(0xFF9E6439), const Color(0xFFD5B27C), i / 3)!,
        radius: 4,
      );
    }
    _icon(c, Icons.arrow_forward_rounded, const Offset(94, 74), 25, accent);
  }

  void _words(Canvas c) {
    _panel(c, const Rect.fromLTWH(18, 14, 124, 104), const Color(0xFFF8F5EA));
    if (gameId == 'word_hunt' || gameId == 'letter_maze') {
      const String letters = 'KELİMEAROTAOKUDİL';
      for (int i = 0; i < 16; i++) {
        final Rect r = Rect.fromLTWH(
          30 + (i % 4) * 25.0,
          20 + (i ~/ 4) * 23.0,
          23,
          21,
        );
        _panel(c, r, i < 4 ? accent : const Color(0xFFEEEBDD), radius: 3);
        _text(
          c,
          letters[i],
          r.center,
          14,
          i < 4 ? Colors.white : StudioVisuals.ink,
        );
      }
    } else if (gameId == 'word_wheel') {
      c.drawCircle(
        const Offset(80, 65),
        39,
        Paint()..color = const Color(0xFFE3E8DC),
      );
      const String letters = 'KELİM';
      for (int i = 0; i < 5; i++) {
        final double a = i * math.pi * 2 / 5 - math.pi / 2;
        final Offset p = Offset(80 + 29 * math.cos(a), 65 + 29 * math.sin(a));
        c.drawCircle(p, 13, Paint()..color = const Color(0xFFFBFBF3));
        _text(c, letters[i], p, 15, accent);
      }
      _text(c, 'E', const Offset(80, 65), 18, accent);
    } else if (gameId == 'sentence_builder') {
      const words = ['BİR', 'KÜÇÜK', 'ADIM'];
      for (int i = 0; i < words.length; i++) {
        _panel(
          c,
          Rect.fromLTWH(29, 27 + i * 28.0, 102, 23),
          const Color(0xFFFDFCF7),
          radius: 4,
        );
        _text(c, '${i + 1}', Offset(41, 39 + i * 28.0), 11, accent);
        _text(c, words[i], Offset(87, 39 + i * 28.0), 13, StudioVisuals.ink);
      }
    } else if (gameId == 'meaning_match' || gameId == 'near_meaning') {
      final pairs = gameId == 'meaning_match'
          ? ['DENİZ', 'GÖL', 'DALGA', 'KIYI']
          : ['HIZLI', 'SERİ', 'YAVAŞ', 'AĞIR'];
      for (int i = 0; i < 4; i++) {
        final r = Rect.fromLTWH(28 + i % 2 * 55.0, 30 + i ~/ 2 * 43.0, 50, 35);
        _panel(
          c,
          r,
          i < 2 ? const Color(0xFFE0EBE4) : const Color(0xFFFDFCF7),
          radius: 5,
        );
        _text(c, pairs[i], r.center, 10, StudioVisuals.ink);
      }
      _icon(c, Icons.compare_arrows_rounded, const Offset(80, 66), 16, accent);
    } else {
      _icon(
        c,
        gameId == 'language_detective'
            ? Icons.manage_search_rounded
            : Icons.menu_book_rounded,
        const Offset(80, 47),
        41,
        accent,
      );
      for (int i = 0; i < 3; i++) {
        c.drawLine(
          Offset(36, 80 + i * 10.0),
          Offset(i == 2 ? 107 : 124, 80 + i * 10.0),
          Paint()
            ..color = const Color(0xFF85998B)
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _map(Canvas c) {
    _panel(c, const Rect.fromLTWH(12, 12, 136, 108), const Color(0xFFDDE9E7));
    // While the local map is decoding, show a compass, never invented borders.
    _icon(c, Icons.explore_outlined, const Offset(80, 64), 62, accent);
  }

  void _numberPuzzle(Canvas c) {
    if (gameId == 'kakuro') {
      _panel(c, const Rect.fromLTWH(20, 12, 120, 108), const Color(0xFFCBD8D4));
      for (int i = 0; i < 16; i++) {
        final r = Rect.fromLTWH(32 + i % 4 * 24.0, 18 + i ~/ 4 * 24.0, 23, 23);
        final clue = i < 4 || i % 4 == 0;
        _panel(
          c,
          r,
          clue ? const Color(0xFF344747) : StudioVisuals.paper,
          radius: 2,
        );
        if (clue && i > 0) {
          c.drawLine(
            r.topLeft,
            r.bottomRight,
            Paint()
              ..color = const Color(0xFF9DB1AA)
              ..strokeWidth = 1,
          );
          _text(c, '${i + 5}', r.center + const Offset(4, -5), 8, Colors.white);
        } else if (!clue && i.isEven) {
          _text(c, '${i % 8 + 1}', r.center, 15, StudioVisuals.ink);
        }
      }
      return;
    }
    final bool sudoku = gameId == 'mini_sudoku';
    final bool kenken = gameId == 'kenken_cube';
    final bool hitori = gameId == 'hitori';
    _grid(
      c,
      4,
      [
        '1',
        '',
        '3',
        '4',
        '',
        '3',
        '2',
        '',
        '3',
        '',
        '4',
        '2',
        '4',
        '2',
        '',
        '1',
      ],
      filled: hitori ? {2, 9} : {},
      boardColor: sudoku
          ? const Color(0xFF244D78)
          : kenken
          ? const Color(0xFF1D5B46)
          : hitori
          ? const Color(0xFF53345D)
          : null,
      cellColor: sudoku
          ? const Color(0xFFE8F1FC)
          : kenken
          ? const Color(0xFFE6F4EC)
          : hitori
          ? const Color(0xFFF6EAF5)
          : null,
      filledColor: hitori ? const Color(0xFF2F203A) : null,
    );
    if (sudoku) {
      final edge = Paint()
        ..color = accent
        ..strokeWidth = 2.2;
      c.drawLine(const Offset(79, 18), const Offset(79, 113), edge);
      c.drawLine(const Offset(32, 65), const Offset(127, 65), edge);
      // A single highlighted square makes the Sudoku identity obvious at
      // thumbnail size without pretending to show a full puzzle state.
      _panel(
        c,
        const Rect.fromLTWH(80, 66, 22, 22),
        const Color(0xFF78B5E8),
        radius: 3,
      );
      _text(c, '6', const Offset(91, 77), 13, Colors.white);
    } else if (kenken) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(33, 19, 45, 46),
          const Radius.circular(3),
        ),
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _panel(
        c,
        const Rect.fromLTWH(33, 19, 19, 12),
        const Color(0xFFE4EAD8),
        radius: 2,
      );
      _text(c, '8+', const Offset(42, 25), 9, accent);
      c.drawLine(
        const Offset(80, 66),
        const Offset(126, 66),
        Paint()
          ..color = accent
          ..strokeWidth = 2,
      );
      // Cage corners and a small operation mark separate KenKen from Sudoku.
      c.drawLine(
        const Offset(80, 19),
        const Offset(126, 19),
        Paint()
          ..color = accent.withValues(alpha: .8)
          ..strokeWidth = 2,
      );
      _text(c, '×', const Offset(121, 27), 10, accent);
    } else if (gameId == 'futoshiki') {
      _text(c, '>', const Offset(79, 29), 13, accent);
      _text(c, '<', const Offset(103, 77), 13, accent);
    } else if (hitori) {
      for (final Offset p in <Offset>[
        const Offset(44, 31),
        const Offset(112, 89),
      ]) {
        c.drawLine(
          p + const Offset(-6, -6),
          p + const Offset(6, 6),
          Paint()
            ..color = const Color(0xFFE6B6D7)
            ..strokeWidth = 2,
        );
        c.drawLine(
          p + const Offset(6, -6),
          p + const Offset(-6, 6),
          Paint()
            ..color = const Color(0xFFE6B6D7)
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _equation(Canvas c) {
    final bool target = gameId == 'target_24';
    _panel(
      c,
      const Rect.fromLTWH(15, 14, 130, 104),
      target ? const Color(0xFF542B26) : const Color(0xFF164744),
    );
    final List<String> digits = gameId == 'target_24'
        ? ['3', '8', '4', '6']
        : ['7', '+', '5', '='];
    for (int i = 0; i < 4; i++) {
      _panel(
        c,
        Rect.fromLTWH(30 + i % 2 * 51.0, 23 + i ~/ 2 * 38.0, 44, 32),
        target ? const Color(0xFFFCE6D8) : const Color(0xFFE7F5F1),
      );
      _text(
        c,
        digits[i],
        Offset(52 + i % 2 * 51.0, 39 + i ~/ 2 * 38.0),
        22,
        accent,
      );
    }
    _text(
      c,
      gameId == 'target_24' ? '24' : '12',
      const Offset(80, 106),
      13,
      accent,
    );
  }

  void _reflex(Canvas c) {
    _panel(c, const Rect.fromLTWH(15, 13, 130, 105), const Color(0xFFF9F6EE));
    const List<Color> colors = [
      Color(0xFF649688),
      Color(0xFFAD7271),
      Color(0xFFC19D65),
    ];
    if (gameId == 'slide_sweets') {
      _panel(
        c,
        const Rect.fromLTWH(20, 53, 120, 29),
        const Color(0xFF43514E),
        radius: 10,
      );
      for (int i = 0; i < 4; i++) {
        _panel(
          c,
          Rect.fromLTWH(27 + i * 28.0, 57, 23, 21),
          colors[i % 3],
          radius: 6,
        );
        c.drawLine(
          Offset(33 + i * 28.0, 65),
          Offset(42 + i * 28.0, 65),
          Paint()
            ..color = Colors.white.withValues(alpha: .55)
            ..strokeWidth = 2,
        );
      }
      _icon(c, Icons.arrow_forward_rounded, const Offset(80, 102), 22, accent);
    } else {
      for (int i = 0; i < 3; i++) {
        c.drawCircle(Offset(41 + i * 39.0, 66), 17, Paint()..color = colors[i]);
      }
      final Offset p = gameId == 'focus_filter'
          ? const Offset(80, 66)
          : const Offset(119, 66);
      c.drawCircle(
        p,
        23,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _icon(
        c,
        gameId == 'focus_filter'
            ? Icons.check_rounded
            : Icons.touch_app_outlined,
        p,
        23,
        Colors.white,
      );
    }
  }

  int _catalogSeed() => gameId.codeUnits.fold(
    23,
    (int value, int code) => (value * 31 + code) & 0x7fffffff,
  );

  Color _catalogAccent() {
    const List<Color> palette = <Color>[
      Color(0xFF0D7180),
      Color(0xFF8D3D58),
      Color(0xFF4C559D),
      Color(0xFFB16B25),
      Color(0xFF26735D),
      Color(0xFF7A4A85),
      Color(0xFF2A668E),
    ];
    return palette[_catalogSeed() % palette.length];
  }

  /// A polished, deterministic fallback for catalog entries that do not yet
  /// have a dedicated board painter. It keeps each card recognizable and
  /// colorful without falling back to the same anonymous number grid.
  void _catalogScene(Canvas c) {
    final Color tone = _catalogAccent();
    final Color deep = Color.lerp(tone, const Color(0xFF101E29), .68)!;
    final Color light = Color.lerp(tone, Colors.white, .76)!;
    final int seed = _catalogSeed();
    _panel(c, const Rect.fromLTWH(13, 10, 134, 112), deep);

    final List<IconData> symbols = <IconData>[
      Icons.account_tree_rounded,
      Icons.extension_rounded,
      Icons.bolt_rounded,
      Icons.explore_rounded,
      Icons.auto_awesome_rounded,
      Icons.shield_rounded,
    ];
    final IconData symbol = symbols[seed % symbols.length];
    _icon(c, symbol, const Offset(80, 40), 29, light);

    // Three dimensional tiles make the thumbnail read as a real game object.
    for (int i = 0; i < 3; i++) {
      final double x = 27 + i * 38.0;
      final Color tile = i == seed % 3
          ? Color.lerp(tone, Colors.white, .12)!
          : Color.lerp(tone, const Color(0xFF12222B), .28)!;
      _panel(c, Rect.fromLTWH(x, 70, 33, 33), tile, radius: 7);
      if ((seed + i) % 2 == 0) {
        c.drawCircle(
          Offset(x + 16.5, 86.5),
          7,
          Paint()..color = light.withValues(alpha: .88),
        );
      } else {
        c.drawLine(
          Offset(x + 9, 94),
          Offset(x + 24, 79),
          Paint()
            ..color = light.withValues(alpha: .88)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // The small footer badge changes with the id, so adjacent planned games
    // never look like clones even before their full board is implemented.
    _panel(
      c,
      const Rect.fromLTWH(52, 108, 56, 8),
      Color.lerp(tone, Colors.white, .3)!,
      radius: 4,
    );
    c.drawCircle(
      const Offset(61, 112),
      1.7,
      Paint()..color = Colors.white.withValues(alpha: .86),
    );
    c.drawCircle(
      Offset(99, 112),
      1.7,
      Paint()..color = Colors.white.withValues(alpha: .58),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 132);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 160, 132),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(accent, Colors.white, .18)!,
            Color.lerp(accent, const Color(0xFF0E1B22), .72)!,
          ],
        ).createShader(const Rect.fromLTWH(0, 0, 160, 132)),
    );
    switch (gameId) {
      case 'city_atlas':
      case 'world_atlas':
        _map(canvas);
      case 'katamino_workshop':
      case 'number_sort':
        if (gameId == 'number_sort') {
          _grid(canvas, 4, [
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '10',
            '11',
            '12',
            '13',
            '14',
            '',
            '15',
          ], wood: true);
        } else {
          _blocks(canvas, parquet: true);
        }
      case 'blocks':
      case 'shape_puzzle':
        _blocks(canvas, parquet: gameId == 'shape_puzzle');
      case 'mini_chess_tactics':
      case 'reversi_arena':
        _chess(canvas, reversi: gameId == 'reversi_arena');
      case 'hanoi':
        _hanoi(canvas);
      case 'balance_scale':
        _balance(canvas);
      case 'hidden_masses':
        _hiddenMasses(canvas);
      case 'card_pairs':
      case 'attention_tunnel':
      case 'spot_change':
      case 'story_order':
        _cards(
          canvas,
          scene: gameId == 'spot_change',
          story: gameId == 'story_order',
        );
      case 'word_hunt':
      case 'word_wheel':
      case 'meaning_match':
      case 'proverb_finish':
      case 'sentence_builder':
      case 'near_meaning':
      case 'letter_maze':
      case 'language_detective':
        _words(canvas);
      case 'numbers':
      case 'target_24':
        _equation(canvas);
      case 'mini_sudoku':
      case 'kenken_cube':
      case 'kakuro':
      case 'futoshiki':
      case 'hitori':
        _numberPuzzle(canvas);
      case 'picross_master':
        _grid(
          canvas,
          4,
          List.filled(16, ''),
          filled: {1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14},
        );
      case 'mine_detective':
        _grid(
          canvas,
          4,
          [
            '1',
            '1',
            '',
            '',
            '2',
            '',
            '1',
            '',
            '',
            '1',
            '2',
            '',
            '',
            '',
            '1',
            '',
          ],
          filled: {2, 3, 5, 7, 8, 11, 12, 13, 15},
        );
      case 'picture_iq':
        _grid(canvas, 3, ['●', '▲', '■', '▲', '■', '●', '■', '●', '?']);
      case 'skyscrapers':
        _grid(
          canvas,
          3,
          ['2', '1', '3', '3', '2', '1', '1', '3', '2'],
          boardColor: const Color(0xFF303A67),
          cellColor: const Color(0xFFF1F3FF),
        );
        // A skyline silhouette distinguishes this from a plain number grid.
        for (final (double x, double h) in <(double, double)>[
          (39, 20),
          (62, 30),
          (85, 14),
          (108, 25),
        ]) {
          canvas.drawRect(
            Rect.fromLTWH(x, 111 - h, 12, h),
            Paint()..color = accent.withValues(alpha: .78),
          );
          canvas.drawCircle(
            Offset(x + 6, 108 - h),
            1.5,
            Paint()..color = const Color(0xFFFFD77A),
          );
        }
      case 'island_sea':
        _grid(
          canvas,
          4,
          ['2', '', '', '3', '', '', '', '', '', '2', '', '', '', '', '', '1'],
          filled: {1, 2, 4, 6, 8, 10, 11, 12, 13, 14},
          boardColor: const Color(0xFF0F4C61),
          cellColor: const Color(0xFFE8F6F5),
          filledColor: const Color(0xFF25A1B6),
        );
        canvas.drawArc(
          const Rect.fromLTWH(26, 93, 28, 10),
          0,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFF9BE3E4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case 'arrow_route':
      case 'loop_master':
        _route(
          canvas,
          arrows: gameId == 'arrow_route',
          loop: gameId == 'loop_master',
        );
      case 'memory':
        _route(canvas, maze: true);
      case 'single_stroke':
        _singleStroke(canvas);
      case 'arrow_maze':
        _arrowMaze(canvas);
      case 'reflex':
      case 'focus_filter':
      case 'slide_sweets':
        _reflex(canvas);
      case 'rhythm_memory':
        _panel(
          canvas,
          const Rect.fromLTWH(14, 15, 132, 104),
          const Color(0xFFEDE4D4),
        );
        for (int i = 0; i < 4; i++) {
          _panel(
            canvas,
            Rect.fromLTWH(24 + i * 29.0, 35, 25, 65 - i * 7.0),
            i == 1 ? accent : const Color(0xFFB88D5C),
            radius: 6,
          );
        }
      case 'parking_puzzle':
        _panel(
          canvas,
          const Rect.fromLTWH(15, 12, 130, 108),
          const Color(0xFF43514E),
        );
        for (int i = 0; i < 3; i++) {
          _panel(
            canvas,
            Rect.fromLTWH(26 + i * 36.0, 24, 25, 55),
            i == 1 ? const Color(0xFFB8784F) : const Color(0xFF74959A),
            radius: 8,
          );
          _panel(
            canvas,
            Rect.fromLTWH(30 + i * 36.0, 38, 17, 20),
            const Color(0xFF2E4B51),
            radius: 4,
          );
        }
        _icon(
          canvas,
          Icons.arrow_forward_rounded,
          const Offset(80, 99),
          25,
          const Color(0xFFEBD7B4),
        );
      case 'detective_notes':
        _panel(
          canvas,
          const Rect.fromLTWH(21, 12, 118, 109),
          const Color(0xFFF7F1E4),
        );
        _icon(
          canvas,
          Icons.manage_search_rounded,
          const Offset(80, 39),
          35,
          accent,
        );
        for (int i = 0; i < 3; i++) {
          _text(
            canvas,
            i == 1 ? '✓' : '—',
            Offset(42, 70 + i * 14.0),
            13,
            accent,
          );
          canvas.drawLine(
            Offset(57, 70 + i * 14.0),
            Offset(122, 70 + i * 14.0),
            Paint()
              ..color = const Color(0xFFABB5A6)
              ..strokeWidth = 2,
          );
        }
      default:
        _catalogScene(canvas);
    }
    if (locked) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 160, 132),
        Paint()..color = StudioVisuals.surface.withValues(alpha: .62),
      );
      _icon(
        canvas,
        Icons.lock_outline_rounded,
        const Offset(80, 66),
        37,
        StudioVisuals.muted,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GameArtworkPainter old) =>
      old.gameId != gameId || old.variant != variant || old.locked != locked;
}
