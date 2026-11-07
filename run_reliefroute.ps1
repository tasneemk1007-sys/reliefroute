param(
  [ValidateSet('chrome', 'android', 'edge')]
  [string]$Device = 'chrome'
)

$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot 'reliefroutee'
Set-Location $project

Write-Host "Starting ReliefRoute from $project on $Device..." -ForegroundColor Cyan
flutter pub get
flutter run -d $Device
