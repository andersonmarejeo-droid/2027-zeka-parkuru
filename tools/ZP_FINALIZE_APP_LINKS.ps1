param(
    [Parameter(Mandatory = $true)]
    [string]$Sha256
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$fingerprint = $Sha256.Trim().ToUpperInvariant()
if ($fingerprint -notmatch '^([0-9A-F]{2}:){31}[0-9A-F]{2}$') {
    Write-Host 'HATA: SHA-256 parmak izi AA:BB:... biçiminde 32 bayt olmalıdır.' -ForegroundColor Red
    exit 1
}
$template = Join-Path $root 'hosting/.well-known/assetlinks.json.template'
$output = Join-Path $root 'hosting/.well-known/assetlinks.json'
$content = Get-Content -Raw -Encoding UTF8 $template
$content = $content.Replace('REPLACE_WITH_PLAY_APP_SIGNING_SHA256', $fingerprint)
$content | Set-Content -Encoding UTF8 $output

$manifestPath = Join-Path $root 'android/app/src/main/AndroidManifest.xml'
$manifest = Get-Content -Raw -Encoding UTF8 $manifestPath
$manifest = $manifest.Replace('intent-filter android:autoVerify="false"', 'intent-filter android:autoVerify="true"')
$manifest | Set-Content -Encoding UTF8 $manifestPath
Write-Host 'App Links tamamlandi:' -ForegroundColor Green
Write-Host "  $output"
Write-Host '  AndroidManifest.xml autoVerify=true'
