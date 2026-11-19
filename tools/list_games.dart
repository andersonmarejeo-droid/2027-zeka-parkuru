import 'package:zeka_parkuru/features/catalog/domain/studio_game_catalog.dart';

void main() {
  print('=== AKTIF OYNANABILIR OYUNLAR (PLAYABLE) ===');
  final active = StudioGameCatalog.playable;
  print('Toplam aktif oynanabilir: ${active.length}');
  for (var g in active) {
    print('${g.order} | ${g.id} | ${g.titleTr} (${g.titleEn}) | ${g.gameClass.name}');
  }

  print('\n=== EMEKLIYE AYRILMIS OYUNLAR (RETIRED) ===');
  print('Toplam emekli: ${StudioGameCatalog.retiredGameIds.length}');
  for (var id in StudioGameCatalog.retiredGameIds) {
    final def = StudioGameCatalog.byId(id);
    print('${id} -> ${def?.titleTr ?? "Tanimsiz"}');
  }
}
