param(
  [ValidateSet('chrome', 'android', 'edge')]
  [string]$Device = 'chrome',
  [string]$ApiBaseUrl = ''
)

$ErrorActionPreference = 'Stop'
$project = $PSScriptRoot
Set-Location $project

Write-Host "Starting ReliefRoute from $project on $Device..." -ForegroundColor Cyan
flutter pub get
$runArgs = @('-d', $Device)
if ($Device -eq 'android') {
  if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $ApiBaseUrl = Read-Host 'Enter the API URL reachable from your phone (for example http://192.168.1.10:8080/api)'
  }
  if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    throw 'Android needs an API URL reachable from the phone. Use -ApiBaseUrl with your computer LAN address.'
  }
}
if (-not [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  $runArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl"
}
flutter run @runArgs
