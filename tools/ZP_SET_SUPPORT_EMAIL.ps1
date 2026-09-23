param(
    [Parameter(Mandatory = $true)]
    [string]$Email
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if ($Email -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') {
    Write-Host 'HATA: Gecerli bir destek e-postasi girin.' -ForegroundColor Red
    exit 1
}
$privacyPath = Join-Path $root 'hosting/privacy.html'
$content = Get-Content -Raw -Encoding UTF8 $privacyPath
$content = $content.Replace('REPLACE_WITH_SUPPORT_EMAIL', $Email.Trim())
$content | Set-Content -Encoding UTF8 $privacyPath
Write-Host "Gizlilik politikasi destek e-postasi guncellendi: $Email" -ForegroundColor Green
