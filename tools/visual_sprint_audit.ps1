param([switch]$Propose, [switch]$Legacy)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$entries = @(
  @('mine_detective','mine_detector/mine_detector_game_page.dart'),
  @('detective_notes','detective_notes/detective_notes_game_page.dart'),
  @('balance_scale','balance_scale/balance_scale_game_page.dart'),
  @('numbers','numbers/number_game_page.dart'),
  @('number_sort','number_sort/number_sort_game_page.dart'),
  @('target_24','target_24/target_24_game_page.dart'),
  @('mini_sudoku','mini_sudoku/mini_sudoku_game_page.dart'),
  @('kenken_cube','kenken_cube/kenken_cube_game_page.dart'),
  @('hidden_masses','hidden_masses/hidden_masses_game_page.dart'),
  @('kakuro','kakuro/kakuro_game_page.dart'),
  @('blocks','blocks/block_game_page.dart'),
  @('picture_iq','picture_iq/picture_iq_game_page.dart'),
  @('shape_puzzle','shape_puzzle/shape_puzzle_game_page.dart'),
  @('memory','memory/memory_game_page.dart'),
  @('memory','memory/shape_match_game_page.dart'),
  @('card_pairs','card_pairs/card_pairs_game_page.dart'),
  @('focus_filter','focus_filter/focus_filter_game_page.dart'),
  @('spot_change','spot_change/spot_change_game_page.dart'),
  @('rhythm_memory','rhythm_memory/rhythm_memory_game_page.dart'),
  @('attention_tunnel','attention_tunnel/attention_tunnel_game_page.dart'),
  @('hanoi','hanoi/hanoi_game_page.dart'),
  @('parking_puzzle','parking_puzzle/parking_puzzle_game_page.dart'),
  @('mini_chess_tactics','chess_mate/chess_mate_game_page.dart'),
  @('word_hunt','word_hunt/word_hunt_game_page.dart'),
  @('meaning_match','meaning_match/meaning_match_game_page.dart'),
  @('proverb_finish','proverb_finish/proverb_finish_game_page.dart'),
  @('word_wheel','word_wheel/word_wheel_game_page.dart'),
  @('sentence_builder','sentence_builder/sentence_builder_game_page.dart'),
  @('near_meaning','near_meaning/near_meaning_game_page.dart'),
  @('letter_maze','letter_maze/letter_maze_game_page.dart'),
  @('language_detective','language_detective/language_detective_game_page.dart'),
  @('story_order','story_order/story_order_game_page.dart'),
  @('reflex','reflex/reflex_game_page.dart'),
  @('slide_sweets','slide_sweets/slide_sweets_game_page.dart'),
  @('reversi_arena','reversi_arena/reversi_game_page.dart'),
  @('picross_master','picross_master/picross_game_page.dart'),
  @('arrow_route','arrow_route/arrow_game_page.dart'),
  @('loop_master','loop_master/loop_game_page.dart'),
  @('island_sea','island_sea/island_sea_game_page.dart'),
  @('futoshiki','futoshiki/futoshiki_game_page.dart'),
  @('skyscrapers','skyscrapers/skyscrapers_game_page.dart'),
  @('hitori','hitori/hitori_game_page.dart'),
  @('city_atlas','reference_games/atlas_find_game_page.dart'),
  @('katamino_workshop','reference_games/katamino_game_page.dart'),
  @('single_stroke','reference_games/single_stroke_game_page.dart'),
  @('arrow_maze','reference_games/arrow_maze_game_page.dart')
)
$design = Get-Content -LiteralPath (Join-Path $root 'lib/games/shared/game_visual_design.dart') -Raw -Encoding utf8
$colours = @{}
foreach($m in [regex]::Matches($design,"'([^']+)': GameVisualDesign\(\s*Color\((0x[0-9A-F]+)\)")) { $colours[$m.Groups[1].Value] = $m.Groups[2].Value }
function New-Change([string]$source, [System.Text.RegularExpressions.Match]$match, [string]$replacement) {
  $start = $source.LastIndexOf("`n", $match.Index) + 1
  $end = $source.IndexOf("`n", $match.Index + $match.Length)
  if($end -lt 0) {$end=$source.Length}
  $old = $source.Substring($start,$end-$start).TrimEnd("`r")
  $new = $source.Substring($start,$match.Index-$start) + $replacement + $source.Substring($match.Index+$match.Length,$end-$match.Index-$match.Length).TrimEnd("`r")
  return @{old=$old;new=$new;index=$start}
}
$records = foreach($entry in $entries) {
  $id = $entry[0]
  $relative = 'lib/games/' + $entry[1]
  $source = Get-Content -LiteralPath (Join-Path $root $relative) -Raw -Encoding utf8
  $changes = [System.Collections.Generic.List[object]]::new()
  if($Legacy) {
    if($id -notin @('numbers','number_sort','blocks','picture_iq','shape_puzzle','memory','hanoi','reflex','word_hunt')) {continue}
    $rgb = @{
      '06152B'='F6F8F6';'06142A'='F6F8F6';'081C35'='EEF3F0';'081B34'='EEF3F0';
      '07162E'='EEF3F0';'0A203D'='EEF3F0';'12365E'='FFFFFF';'102A4A'='FFFFFF';
      '102B4D'='EEF3F0';'0B1D3B'='FFFFFF';'0D1D3D'='FFFFFF';'0A1B33'='EEF3F0';
      '0B1F3D'='EEF3F0';'00D9FF'='3D7183';'00E9FF'='3D7183';'49CFFF'='3D7183';
      '00AEEF'='3D7183';'FFD334'='8B622C';'FFD93D'='8B622C';'FFC928'='8B622C';
      'FFC52C'='8B622C';'54E56B'='34715D';'52E86B'='34715D';'54C96B'='34715D';
      '6CFF9B'='34715D';'52D56C'='34715D';'8CFF9D'='34715D';'FF5A3C'='A84640';
      'FF5B5B'='A84640';'FF5E57'='A84640';'FF7474'='A84640';'B06CFF'='665AA2';
      '745CFF'='665AA2';'6C4DFF'='665AA2';'7655FF'='665AA2';'8C6CFF'='665AA2';
      'FF4FA3'='9C5471';'E040FB'='9C5471';'E748CF'='9C5471';'00D9A6'='34715D'
      '071D37'='EEF3F0';'0A1F3A'='EEF3F0';'123B5C'='E5EEE8';'173D61'='F0F4F0';
      '135D7A'='DDECE6';'243F6B'='30453E';'09162E'='FFFFFF';'09182E'='FFFFFF';
      '0D2342'='FFFFFF';'142A49'='EEF3F0';'123465'='F6F8F6';'492785'='E8F0EA';
      '235080'='8FA59A';'0E2341'='EEF3F0';'102949'='EEF3F0';'132F52'='F9FAF6';
      '123D73'='F6F8F6';'522C83'='E8EFEB';'0B203D'='EDF3ED';'10213F'='EEF3F0';
      '122E52'='F9FAF6';'162C55'='F3F5EF';'173D70'='F6F8F6';'263F73'='F8FAF6';
      '382567'='E8EFEB';'04101E'='6B614E';'09182F'='EEF3F0';'17314B'='AD9877';
      '21466E'='DDE7DF';'294B6A'='C6B088';'102B50'='FFFFFF';'12335E'='EEF3F0';
      '173254'='FFFFFF';'2B225C'='EEF3F0';'093E4B'='EEF3F0';'76FF03'='176D62';
      'FFB0D4'='9C5471';'7BEAFF'='3D7183';'FF6B6B'='AD7271'
    }
    $updated = [regex]::Replace($source,'Color\(0x([0-9A-F]{2})([0-9A-F]{6})\)', {
      param($m)
      if($rgb.ContainsKey($m.Groups[2].Value)) {return "Color(0x$($m.Groups[1].Value)$($rgb[$m.Groups[2].Value]))"}
      return $m.Value
    })
    $updated = [regex]::Replace($updated,'Colors\.white(?:54|60|70|38|30)\b','StudioVisuals.muted')
    $updated = [regex]::Replace($updated,'Colors\.white(?:24|12|10|08)\b','StudioVisuals.line')
    $updated = [regex]::Replace($updated,'(?s)TextStyle\((?:(?!\)).){0,300}?\bcolor:\s*Colors\.white\b', {
      param($m) return $m.Value.Replace('Colors.white','StudioVisuals.ink')
    })
    if(-not $source.Contains("theme/studio_visuals.dart'")) {
      $updated=$updated.Replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';`n`nimport '../../theme/studio_visuals.dart';")
    }
    if($source.Split("`n").Length -ne $updated.Split("`n").Length) {
      # Import-only insertion is a separate edit; keep all palette lines aligned.
      $updated=$updated.Replace("import 'package:flutter/material.dart';`n`nimport '../../theme/studio_visuals.dart';", "import 'package:flutter/material.dart';")
      $changes.Add(@{old="import 'package:flutter/material.dart';";new="import 'package:flutter/material.dart';`n`nimport '../../theme/studio_visuals.dart';";index=-1})
    }
    $oldLines=$source.Split("`n")
    $newLines=$updated.Split("`n")
    for($i=0;$i -lt $oldLines.Length;$i++) {
      if($oldLines[$i] -ne $newLines[$i]) {$changes.Add(@{old=$oldLines[$i].TrimEnd("`r");new=$newLines[$i].TrimEnd("`r");index=$i})}
    }
  } else {
  foreach($m in [regex]::Matches($source,'StudioGameSkin\.forClass\(\s*StudioGameClass\.\w+,?\s*\)')) {
    $changes.Add((New-Change $source $m "StudioGameSkin.forId('$id')"))
  }
  foreach($m in [regex]::Matches($source,'static const Color (_ink|_muted|_canvas|_surface) = [^;]+;')) {
    $token = @{_ink='ink';_muted='muted';_canvas='canvas';_surface='surface'}[$m.Groups[1].Value]
    $changes.Add((New-Change $source $m "static const Color $($m.Groups[1].Value) = StudioVisuals.$token;"))
  }
  foreach($m in [regex]::Matches($source,'static const Color _accent = Color\(0x[0-9A-F]+\);')) {
    if($colours.ContainsKey($id)) { $changes.Add((New-Change $source $m "static const Color _accent = Color($($colours[$id]));")) }
  }
  if($changes.Where({$_.new.Contains('StudioVisuals.')}).Count -gt 0 -and -not $source.Contains("theme/studio_visuals.dart'")) {
    $changes.Add(@{old="import 'package:flutter/material.dart';";new="import 'package:flutter/material.dart';`n`nimport '../../theme/studio_visuals.dart';";index=$source.IndexOf("import 'package:flutter/material.dart';")})
  }
  }
  [pscustomobject]@{
    id=$id;path=$relative;changes=@($changes | Where-Object {$_.old -ne $_.new} | Sort-Object index);
    darkCanvas=[regex]::Matches($source,'backgroundColor: (?:const )?Color\(0xFF0[0-9A-F]+\)').Count;
    whiteText=[regex]::Matches($source,'color: Colors\.white(?:54|60|70)?[,)]').Count
  }
}
if($Propose) {$records | ConvertTo-Json -Depth 5 -Compress} else {$records | Select-Object id,path,darkCanvas,whiteText | Format-Table -AutoSize}
