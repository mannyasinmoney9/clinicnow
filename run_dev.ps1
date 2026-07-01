# ClinicNow Flutter launcher — run from clinic_now\
# Usage:
#   .\run_dev.ps1              -> emulator (default)
#   .\run_dev.ps1 phone        -> Samsung A12 via USB

param([string]$target = "emulator")

$FLUTTER_SDK  = "C:\Users\DELL GAMING\Documents\flutter_windows_3.41.5-stable\flutter"
$SAMSUNG_ID   = "R58R41QZAYL"

# ---- Fix: map F: drive so Dart binary has no spaces in path ----
if (-not (Test-Path "F:\")) {
    subst F: $FLUTTER_SDK
    Write-Host "Mapped F: -> $FLUTTER_SDK" -ForegroundColor Green
} else {
    Write-Host "F: drive already mapped" -ForegroundColor Green
}

# ---- Fix: junction C:\pc so PUB_CACHE has no spaces ----
if (-not (Test-Path "C:\pc")) {
    cmd /c mklink /J C:\pc "C:\Users\DELL GAMING\AppData\Local\Pub\Cache" | Out-Null
    Write-Host "Created C:\pc junction for PUB_CACHE" -ForegroundColor Green
}
$env:PUB_CACHE = "C:\pc"

# ---- Pick target ----
if ($target -eq "phone") {
    $API_URL = "http://127.0.0.1:8080"
    Write-Host "Target: Samsung A12 — running adb reverse..." -ForegroundColor Cyan
    adb -s $SAMSUNG_ID reverse tcp:8080 tcp:8080
    Write-Host "Running on phone (ID: $SAMSUNG_ID)" -ForegroundColor Cyan
    & "F:\bin\flutter.bat" run -d $SAMSUNG_ID "--dart-define=API_BASE_URL=$API_URL"
} else {
    $API_URL = "http://10.0.2.2:8080"
    Write-Host "Target: Android emulator" -ForegroundColor Cyan
    & "F:\bin\flutter.bat" run "--dart-define=API_BASE_URL=$API_URL"
}