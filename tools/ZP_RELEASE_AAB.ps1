$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Push-Location $root
try {
    & "$root\tools\ZP_RELEASE_PREFLIGHT.ps1" -RequireSigning
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Host 'HATA: Flutter PATH icinde bulunamadi.' -ForegroundColor Red
        exit 1
    }
    flutter clean
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    flutter analyze
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    flutter test --reporter expanded
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host ''
    Write-Host 'AAB hazir:' -ForegroundColor Green
    Write-Host "$root\build\app\outputs\bundle\release\app-release.aab"
} finally {
    Pop-Location
}
