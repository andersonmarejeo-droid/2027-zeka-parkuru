$ErrorActionPreference = "Stop"

function Invoke-NativeChecked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command"
    }
}

$projectPath = (Get-Location).Path
$pubspecPath = Join-Path $projectPath "pubspec.yaml"
$dailyPath = Join-Path $projectPath "lib\pages\daily_course_page.dart"
$dailyServicePath = Join-Path $projectPath "lib\services\daily_course_service.dart"
$keyPropertiesPath = Join-Path $projectPath "android\key.properties"
$keystorePath = Join-Path $env:USERPROFILE "zeka-parkuru-upload-keystore.jks"
$apkPath = Join-Path $projectPath "build\app\outputs\flutter-apk\app-release.apk"

foreach ($requiredPath in @(
        $pubspecPath,
        $dailyPath,
        $dailyServicePath,
        $keyPropertiesPath,
        $keystorePath
    )) {
    if (!(Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required file not found: $requiredPath"
    }
}

$pubspec = [System.IO.File]::ReadAllText(
    $pubspecPath,
    [System.Text.Encoding]::UTF8
)
if ($pubspec -notmatch "(?m)^name:\s*zeka_parkuru\s*$") {
    throw "This does not look like the zeka_parkuru project root."
}

$keyProperties = [System.IO.File]::ReadAllText(
    $keyPropertiesPath,
    [System.Text.Encoding]::UTF8
)
if ($keyProperties -notmatch "(?m)^\s*keyAlias\s*=\s*upload\s*$") {
    throw "android/key.properties does not use the expected upload alias."
}
if ($keyProperties -notmatch "zeka-parkuru-upload-keystore\.jks") {
    throw "android/key.properties does not point to the expected upload keystore."
}

if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter command was not found in PATH."
}

$desktopPath = [System.Environment]::GetFolderPath("Desktop")
if ([string]::IsNullOrWhiteSpace($desktopPath) -or
    !(Test-Path -LiteralPath $desktopPath -PathType Container)) {
    throw "Windows Desktop folder could not be resolved."
}

$timestamp = Get-Date -Format yyyyMMdd_HHmmss_fff
$desktopApkPath = Join-Path `
    $desktopPath `
    "zeka_parkuru_release_$timestamp.apk"

if (Test-Path -LiteralPath $desktopApkPath) {
    throw "Desktop target already exists; refusing to overwrite it: $desktopApkPath"
}

try {
    Write-Host "Release preflight passed." -ForegroundColor Green
    Write-Host "Signing keystore: $keystorePath" -ForegroundColor Yellow
    Write-Host "No Firebase deploy and no AAB build will be performed." -ForegroundColor Yellow

    Write-Host "Checking the two recently changed daily-course files..." -ForegroundColor Cyan
    Invoke-NativeChecked `
        -Command "flutter" `
        -Arguments @(
            "analyze",
            $dailyPath,
            $dailyServicePath
        )

    Write-Host "Resolving packages..." -ForegroundColor Cyan
    Invoke-NativeChecked `
        -Command "flutter" `
        -Arguments @("pub", "get")

    Write-Host "Building release APK..." -ForegroundColor Cyan
    Invoke-NativeChecked `
        -Command "flutter" `
        -Arguments @("build", "apk", "--release")

    if (!(Test-Path -LiteralPath $apkPath -PathType Leaf)) {
        throw "Flutter reported success, but app-release.apk was not found: $apkPath"
    }

    $apkInfo = Get-Item -LiteralPath $apkPath
    if ($apkInfo.Length -le 0) {
        throw "The generated APK is empty."
    }

    Copy-Item -LiteralPath $apkPath -Destination $desktopApkPath

    $desktopInfo = Get-Item -LiteralPath $desktopApkPath
    if ($desktopInfo.Length -ne $apkInfo.Length) {
        throw "Desktop APK size does not match the build output."
    }

    $hash = (Get-FileHash -LiteralPath $desktopApkPath -Algorithm SHA256).Hash

    Write-Host ""
    Write-Host "Release APK created successfully." -ForegroundColor Green
    Write-Host "Desktop file: $desktopApkPath" -ForegroundColor Green
    Write-Host ("Size: {0:N0} bytes" -f $desktopInfo.Length)
    Write-Host "SHA-256: $hash" -ForegroundColor Yellow
    Write-Host "Source files were not changed." -ForegroundColor Green
}
catch {
    Write-Host "Release build failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
