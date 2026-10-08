# Script to build APK and copy it to target destination
param(
    [string]$OutputDir = "C:\Users\Dell\Desktop\cdcdcd"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "BYD DiLink Offline Voice Assistant Builder" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Check Flutter SDK
if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Flutter SDK is not detected in your PATH." -ForegroundColor Yellow
    Write-Host "Please install Flutter SDK from https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    Write-Host "and ensure Android SDK is configured via Android Studio or cmdline-tools." -ForegroundColor Yellow
    exit 1
}

# 2. Check Target Directory
if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "[+] Resolving dependencies..." -ForegroundColor Green
flutter pub get

Write-Host "[+] Building Release APK for Android (arm64-v8a)..." -ForegroundColor Green
flutter build apk --release --target-platform android-arm64

$BuiltApk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path -LiteralPath $BuiltApk) {
    $DestinationApk = Join-Path -Path $OutputDir -ChildPath "byd_assistant_v1.0.apk"
    Copy-Item -LiteralPath $BuiltApk -Destination $DestinationApk -Force
    Write-Host "[SUCCESS] APK built and copied successfully to: $DestinationApk" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Could not find output APK at $BuiltApk" -ForegroundColor Red
    exit 1
}
