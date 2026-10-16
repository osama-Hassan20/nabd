param (
    [string]$Target = "apk"
)

# Run the Dart pre-build script
Write-Host "[INFO] Running pre-build baseUrl check..." -ForegroundColor Cyan
dart run scripts/check_base_url.dart

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Pre-build check failed. Stopping build." -ForegroundColor Red
    exit 1
}

# Run the flutter build
Write-Host "[SUCCESS] Running flutter build $Target..." -ForegroundColor Green
if ($Target -eq "apk") {
    flutter build apk --release
} elseif ($Target -eq "bundle") {
    flutter build appbundle --release
} elseif ($Target -eq "web") {
    flutter build web --release
} else {
    Write-Host "[ERROR] Unknown build target. Use apk, bundle, or web." -ForegroundColor Red
    exit 1
}
