# Flutter Diagnostic Script
$logFile = "flutter_diagnostic_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# 1. Flutter Doctor
"=== Flutter Doctor ===" | Out-File -FilePath $logFile -Append
flutter doctor -v | Out-File -FilePath $logFile -Append

# 2. Project Structure
"`n=== Project Structure ===" | Out-File -FilePath $logFile -Append
Get-ChildItem -Recurse | Select-Object FullName | Out-File -FilePath $logFile -Append

# 3. pubspec.yaml
"`n=== pubspec.yaml ===" | Out-File -FilePath $logFile -Append
if (Test-Path "pubspec.yaml") {
    Get-Content "pubspec.yaml" | Out-File -FilePath $logFile -Append
} else {
    "pubspec.yaml NOT FOUND" | Out-File -FilePath $logFile -Append
}

# 4. kurs_1.json check
"`n=== kurs_1.json ===" | Out-File -FilePath $logFile -Append
if (Test-Path "assets\kurs_1.json") {
    "File exists at assets\kurs_1.json" | Out-File -FilePath $logFile -Append
} else {
    "File NOT FOUND at assets\kurs_1.json" | Out-File -FilePath $logFile -Append
}

# 5. Flutter Build
"`n=== Flutter Build ===" | Out-File -FilePath $logFile -Append
flutter build -v | Out-File -FilePath $logFile -Append

# 6. Dart Analysis
"`n=== Dart Analysis ===" | Out-File -FilePath $logFile -Append
flutter analyze | Out-File -FilePath $logFile -Append

# 7. System Info
"`n=== System Info ===" | Out-File -FilePath $logFile -Append
systeminfo | Out-File -FilePath $logFile -Append

Write-Host "Diagnostic log saved to: $logFile"
'@ | Out-File -FilePath flutter_diagnostic.ps1 -Encoding UTF8