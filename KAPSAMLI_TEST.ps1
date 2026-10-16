param(
    [switch]$Release
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $root

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command
    )

    Write-Host "`n== $Label ==" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Label başarısız oldu (exit code $LASTEXITCODE)."
    }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter PATH üzerinde bulunamadı.'
}

foreach ($required in @(
        'pubspec.yaml',
        'android/app/google-services.json',
        'android/key.properties',
        'firestore.rules',
        'firebase.json'
    )) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $required))) {
        throw "Gerekli yayın dosyası bulunamadı: $required"
    }
}

Invoke-Checked 'Bağımlılıkları doğrula' { flutter pub get }
Invoke-Checked 'Dart analizini çalıştır' { flutter analyze }
Invoke-Checked 'Flutter testlerini çalıştır' { flutter test --reporter expanded }
Invoke-Checked 'Debug APK smoke derlemesi' { flutter build apk --debug }

if ($Release) {
    Invoke-Checked 'Release AAB derlemesi' { flutter build appbundle --release }
    Write-Host "`nRelease AAB hazır: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Green
}

Write-Host "`nKapsamlı kontrol tamamlandı." -ForegroundColor Green
