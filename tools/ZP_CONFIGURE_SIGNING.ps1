param(
    [Parameter(Mandatory = $true)]
    [string]$StoreFile,
    [string]$KeyAlias = 'upload'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not (Test-Path $StoreFile -PathType Leaf)) {
    Write-Host "HATA: Keystore bulunamadi: $StoreFile" -ForegroundColor Red
    exit 1
}
$storeSecure = Read-Host 'Keystore parolasi' -AsSecureString
$keySecure = Read-Host 'Key parolasi (ayniysa ayni parolayi girin)' -AsSecureString
function Reveal([Security.SecureString]$value) {
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($value)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}
$storePassword = Reveal $storeSecure
$keyPassword = Reveal $keySecure
$escaped = (Resolve-Path $StoreFile).Path.Replace('\', '\\')
$keyProps = @(
    "storePassword=$storePassword",
    "keyPassword=$keyPassword",
    "keyAlias=$KeyAlias",
    "storeFile=$escaped"
)
$keyProps | Set-Content -Encoding UTF8 (Join-Path $root 'android/key.properties')
$storePassword = $null
$keyPassword = $null
Write-Host 'android/key.properties olusturuldu. Bu dosyayi veya keystore dosyasini paylasmayin.' -ForegroundColor Green
