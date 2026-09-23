$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = (Get-Location).Path

if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'firebase.json'))) {
    throw 'Run this script from the zeka_parkuru project root.'
}
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    throw 'firebase command was not found. Install or open the Firebase CLI first.'
}

Write-Host 'Firestore rules are being validated and deployed...' -ForegroundColor Cyan
& firebase deploy --only firestore:rules
if ($LASTEXITCODE -ne 0) {
    throw "Firebase deploy failed with exit code $LASTEXITCODE"
}

Write-Host 'SUCCESS: Firestore rules were deployed.' -ForegroundColor Green
