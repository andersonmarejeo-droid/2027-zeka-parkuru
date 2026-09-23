param(
    [switch]$BuildDebugApk
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$reportDirectory = Join-Path $root 'test_reports'
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$reportPath = Join-Path $reportDirectory "challenge_revision_$timestamp.txt"

New-Item -ItemType Directory -Force $reportDirectory | Out-Null

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [string[]]$Arguments = @()
    )

    Write-Host ''
    Write-Host "[$Label]" -ForegroundColor Cyan
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Label başarısız oldu. Çıkış kodu: $LASTEXITCODE"
    }
    Write-Host "${Label}: BAŞARILI" -ForegroundColor Green
}

Push-Location $root
try {
    Start-Transcript -Path $reportPath -Force | Out-Null

    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'Flutter PATH içinde bulunamadı. Android Studio Flutter terminalini kullanın.'
    }
    if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
        throw 'Dart PATH içinde bulunamadı.'
    }

    Invoke-CheckedCommand 'Flutter sürümü' 'flutter' @('--version')
    Invoke-CheckedCommand 'Bağımlılık çözümü' 'flutter' @('pub', 'get')
    Invoke-CheckedCommand 'Statik analiz' 'flutter' @('analyze')
    Invoke-CheckedCommand `
        'Meydan Okuma kontrol noktası testi' `
        'flutter' `
        @('test', 'test/challenge_run_progress_test.dart', '--reporter', 'expanded')
    Invoke-CheckedCommand `
        'Sistem bütünlüğü testi' `
        'flutter' `
        @('test', 'test/system_integrity_test.dart', '--reporter', 'expanded')
    Invoke-CheckedCommand 'Tüm testler' 'flutter' @('test', '--reporter', 'expanded')

    if ($BuildDebugApk) {
        Invoke-CheckedCommand 'Debug APK' 'flutter' @('build', 'apk', '--debug')
    }

    Write-Host ''
    Write-Host 'TÜM KONTROLLER BAŞARILI' -ForegroundColor Green
    Write-Host "Rapor: $reportPath"
} catch {
    Write-Host ''
    Write-Host "KONTROL DURDU: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Son değişikliği korumadan önce hatayı düzeltin veya geri alın.' -ForegroundColor Yellow
    exit 1
} finally {
    try { Stop-Transcript | Out-Null } catch {}
    Pop-Location
}

exit 0
