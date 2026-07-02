# ClinicNow launcher — run from clinic_now\
# Usage:
#   .\run_dev.ps1              -> Flutter only  (backend already running)
#   .\run_dev.ps1 phone        -> phone target  (adb reverse + flutter run)
#   .\run_dev.ps1 emulator     -> emulator target
#   .\run_dev.ps1 backend      -> start backend only
#   .\run_dev.ps1 all          -> backend + phone

param([string]$target = "phone")

$FLUTTER_SDK  = "C:\Users\DELL GAMING\Documents\flutter_windows_3.41.5-stable\flutter"
$SAMSUNG_ID   = "R58R41QZAYL"
$JAVA_HOME    = "C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot"
$MVN          = "C:\Users\DELL GAMING\Desktop\Intelli Niga\IntelliJ IDEA 2025.3.2\plugins\maven\lib\maven3\bin\mvn.cmd"
$BACKEND_DIR  = "C:\Users\DELL GAMING\Desktop\ClinicNow2\backend"

# ---- Java ----
$env:JAVA_HOME = $JAVA_HOME
$env:Path = "$JAVA_HOME\bin;$env:Path"

# ---- Fix: map F: drive (no spaces in Flutter path) ----
if (-not (Test-Path "F:\")) {
    subst F: $FLUTTER_SDK
    Write-Host "Mapped F: -> $FLUTTER_SDK" -ForegroundColor Green
} else {
    Write-Host "F: drive already mapped" -ForegroundColor Green
}

# ---- Fix: junction C:\pc (no spaces in PUB_CACHE) ----
if (-not (Test-Path "C:\pc")) {
    cmd /c mklink /J C:\pc "C:\Users\DELL GAMING\AppData\Local\Pub\Cache" | Out-Null
    Write-Host "Created C:\pc junction" -ForegroundColor Green
}
$env:PUB_CACHE = "C:\pc"

function Start-Backend {
    Write-Host "Starting Spring Boot backend..." -ForegroundColor Cyan
    Start-Process powershell -ArgumentList @(
        "-NoExit", "-Command",
        "`$env:JAVA_HOME='$JAVA_HOME'; `$env:Path=`"`$env:JAVA_HOME\bin;`$env:Path`"; Set-Location '$BACKEND_DIR'; & '$MVN' spring-boot:run"
    ) -WindowStyle Normal
    Write-Host "Waiting 25s for backend to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 25
}

function Start-Flutter([string]$apiUrl, [string]$device) {
    Write-Host "Running Flutter (API=$apiUrl)..." -ForegroundColor Cyan

    # Load .env if present (optional — values can also be set in the shell before running)
    $envFile = Join-Path $PSScriptRoot ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
            }
        }
    }

    $AGORA_APP_ID        = $env:AGORA_APP_ID        ?? "8be3ac62ad80495886db03d0e99d426f"
    $EMAILJS_SERVICE_ID  = $env:EMAILJS_SERVICE_ID  ?? ""
    $EMAILJS_TEMPLATE_ID = $env:EMAILJS_TEMPLATE_ID ?? ""
    $EMAILJS_PUBLIC_KEY  = $env:EMAILJS_PUBLIC_KEY  ?? ""

    $defines = @(
        "--dart-define=API_BASE_URL=$apiUrl",
        "--dart-define=AGORA_APP_ID=$AGORA_APP_ID",
        "--dart-define=EMAILJS_SERVICE_ID=$EMAILJS_SERVICE_ID",
        "--dart-define=EMAILJS_TEMPLATE_ID=$EMAILJS_TEMPLATE_ID",
        "--dart-define=EMAILJS_PUBLIC_KEY=$EMAILJS_PUBLIC_KEY"
    )

    if ($device) {
        & "F:\bin\flutter.bat" run -d $device @defines
    } else {
        & "F:\bin\flutter.bat" run @defines
    }
}

switch ($target) {
    "backend" {
        Start-Backend
    }
    "all" {
        Start-Backend
        adb -s $SAMSUNG_ID reverse tcp:8080 tcp:8080
        Start-Flutter "http://127.0.0.1:8080" $SAMSUNG_ID
    }
    "phone" {
        Write-Host "Target: Samsung A12 (adb reverse)" -ForegroundColor Cyan
        adb -s $SAMSUNG_ID reverse tcp:8080 tcp:8080
        Start-Flutter "http://127.0.0.1:8080" $SAMSUNG_ID
    }
    "emulator" {
        Write-Host "Target: Android emulator" -ForegroundColor Cyan
        Start-Flutter "http://10.0.2.2:8080" ""
    }
    default {
        Write-Host "Target: Samsung A12 (adb reverse)" -ForegroundColor Cyan
        adb -s $SAMSUNG_ID reverse tcp:8080 tcp:8080
        Start-Flutter "http://127.0.0.1:8080" $SAMSUNG_ID
    }
}