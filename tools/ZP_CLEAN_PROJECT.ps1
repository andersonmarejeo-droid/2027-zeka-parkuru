param([switch]$IncludeOldBackups)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$targets = @(
  '.dart_tool', 'build', 'android/.gradle', 'android/.kotlin',
  'functions/node_modules', '.firebase', 'test_reports'
)
foreach ($relative in $targets) {
  $path = Join-Path $root $relative
  if (Test-Path $path) { Remove-Item -Recurse -Force $path; Write-Host "Silindi: $relative" }
}
Get-ChildItem (Join-Path $root 'android') -Filter 'hs_err_pid*.log' -ErrorAction SilentlyContinue | Remove-Item -Force
if ($IncludeOldBackups) {
  Get-ChildItem (Join-Path $root 'lib') -Recurse -File | Where-Object { $_.Name -like '*.zp_yedek_*' } | Remove-Item -Force
}
Write-Host 'Uretilebilir cache/build dosyalari temizlendi.' -ForegroundColor Green
