param(
    [switch]$RequireSigning
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Require-File([string]$relative) {
    $path = Join-Path $root $relative
    if (-not (Test-Path $path -PathType Leaf)) { $errors.Add("Eksik dosya: $relative") }
}
function Require-Directory([string]$relative) {
    $path = Join-Path $root $relative
    if (-not (Test-Path $path -PathType Container)) { $errors.Add("Eksik klasor: $relative") }
}
function Require-Text([string]$relative, [string]$pattern, [string]$message) {
    $path = Join-Path $root $relative
    if (-not (Test-Path $path)) { $errors.Add("Eksik dosya: $relative"); return }
    $content = Get-Content -Raw -Encoding UTF8 $path
    if ($content -notmatch $pattern) { $errors.Add($message) }
}
function Forbid-Text([string]$relative, [string]$pattern, [string]$message) {
    $path = Join-Path $root $relative
    if (-not (Test-Path $path)) { return }
    $content = Get-Content -Raw -Encoding UTF8 $path
    if ($content -match $pattern) { $errors.Add($message) }
}

Require-File 'pubspec.yaml'
Require-File 'android/app/build.gradle.kts'
Require-File 'android/app/src/main/AndroidManifest.xml'
Require-File 'android/app/google-services.json'
Require-File 'firestore.rules'
Require-File 'firestore.indexes.json'
Require-File 'firebase.json'
Require-File 'functions/index.js'
Require-File 'functions/package.json'
Require-Directory 'lib/games/picture_iq'
Require-File 'hosting/davet.html'
Require-File 'hosting/arena.html'
Require-File 'hosting/privacy.html'
Require-File 'lib/pages/privacy_policy_page.dart'

Require-Text 'android/app/build.gradle.kts' 'compileSdk\s*=\s*36' 'Android compileSdk 36 degil.'
Require-Text 'android/app/build.gradle.kts' 'targetSdk\s*=\s*36' 'Android targetSdk 36 degil.'
Forbid-Text 'android/app/build.gradle.kts' 'signingConfigs\.getByName\("debug"\)' 'Release hala debug anahtariyla imzalaniyor.'
Require-Text 'android/app/build.gradle.kts' 'hasReleaseSigning' 'Guvenli release signing kontrolu bulunamadi.'
Require-Text 'lib/pages/settings_page.dart' 'privacy_policy_button' 'Ayarlar ekraninda gizlilik politikasi girisi yok.'
Require-Text 'firebase.json' '"public"\s*:\s*"hosting"' 'Firebase Hosting public klasoru hosting olarak ayarli degil.'

$keyProps = Join-Path $root 'android/key.properties'
if ($RequireSigning -and -not (Test-Path $keyProps -PathType Leaf)) {
    $errors.Add('Release imzalama icin android/key.properties eksik.')
} elseif (-not (Test-Path $keyProps -PathType Leaf)) {
    $warnings.Add('android/key.properties yok: debug testleri calisir; release AAB imzalanamaz.')
}

$privacyPath = Join-Path $root 'hosting/privacy.html'
if ($RequireSigning -and (Test-Path $privacyPath)) {
    $privacyText = Get-Content -Raw -Encoding UTF8 $privacyPath
    if ($privacyText -match 'REPLACE_WITH_SUPPORT_EMAIL') {
        $errors.Add('privacy.html icindeki REPLACE_WITH_SUPPORT_EMAIL yayin oncesi doldurulmali.')
    }
}

$assetLinks = Join-Path $root 'hosting/.well-known/assetlinks.json'
if (-not (Test-Path $assetLinks -PathType Leaf)) {
    $warnings.Add('Dogrulanmis App Links icin assetlinks.json henuz yok. Play App Signing SHA-256 alindiktan sonra template doldurulmali.')
}

$privacy = Join-Path $root 'hosting/privacy.html'
if (Test-Path $privacy) {
    $privacyText = Get-Content -Raw -Encoding UTF8 $privacy
    if ($privacyText -match 'destek e-postasi') {
        $warnings.Add('privacy.html icinde yayin oncesi destek e-postasi dogrulama notu var; Play Console ile birlikte tamamlayin.')
    }
}

Write-Host ''
Write-Host 'ZEKA PARKURU RELEASE PREFLIGHT' -ForegroundColor Cyan
Write-Host ('-' * 64)
foreach ($warning in $warnings) { Write-Host "UYARI: $warning" -ForegroundColor Yellow }
foreach ($error in $errors) { Write-Host "HATA: $error" -ForegroundColor Red }
Write-Host ('-' * 64)
Write-Host ("Hata: {0} | Uyari: {1}" -f $errors.Count, $warnings.Count)

if ($errors.Count -gt 0) { exit 1 }
exit 0
