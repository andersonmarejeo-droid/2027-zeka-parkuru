param(
  [string]$ServiceAccount = "",
  [string]$Uid = "",
  [switch]$Execute
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root "functions\admin_tools\process_account_deletions.js"

if (-not (Test-Path $scriptPath)) {
    throw "Yönetici JS dosyası bulunamadı: $scriptPath"
}

if ([string]::IsNullOrWhiteSpace($ServiceAccount)) {
    $ServiceAccount = Read-Host "Service account JSON dosyasının tam yolunu girin"
}

if (-not (Test-Path -LiteralPath $ServiceAccount)) {
    throw "Service account JSON bulunamadı: $ServiceAccount"
}

$argsList = @($scriptPath, "--service-account", $ServiceAccount)

if (-not [string]::IsNullOrWhiteSpace($Uid)) {
    $argsList += @("--uid", $Uid)
}

if ($Execute) {
    Write-Host ""
    Write-Host "DİKKAT: GERÇEK SİLME MODU" -ForegroundColor Yellow
    $confirm = Read-Host "Devam etmek için TAMAM yazın"
    if ($confirm -ne "TAMAM") {
        Write-Host "İşlem iptal edildi. Hiçbir veri değiştirilmedi." -ForegroundColor Cyan
        exit 0
    }
    $argsList += "--execute"
} else {
    Write-Host "DRY-RUN modu: hiçbir veri değiştirilmeyecek." -ForegroundColor Cyan
}

& node @argsList
exit $LASTEXITCODE
