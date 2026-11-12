$ErrorActionPreference = 'Stop'
$backend = $PSScriptRoot
$environmentNames = @(
  'DB_URL', 'DB_USERNAME', 'DB_PASSWORD',
  'FIREBASE_PROJECT_ID', 'FIREBASE_STORAGE_BUCKET',
  'FIREBASE_STORAGE_ENABLED', 'FIREBASE_SERVICE_ACCOUNT', 'JAVA_HOME'
)
$oldEnvironment = @{}
foreach ($name in $environmentNames) {
  $oldEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

$securePassword = $null
$passwordPointer = [IntPtr]::Zero
try {
  $databaseUrl = Read-Host 'MySQL JDBC URL [jdbc:mysql://localhost:3306/reliefroute?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC]'
  if ([string]::IsNullOrWhiteSpace($databaseUrl)) {
    $databaseUrl = 'jdbc:mysql://localhost:3306/reliefroute?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC'
  }
  $databaseUser = Read-Host 'MySQL username'
  if ([string]::IsNullOrWhiteSpace($databaseUser)) { throw 'A MySQL username is required.' }
  $securePassword = Read-Host 'MySQL password' -AsSecureString
  $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
  $databasePassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)

  $env:DB_URL = $databaseUrl
  $env:DB_USERNAME = $databaseUser
  $env:DB_PASSWORD = $databasePassword
  $env:FIREBASE_PROJECT_ID = 'reliefroute4'
  $env:FIREBASE_STORAGE_BUCKET = 'reliefroute4.firebasestorage.app'
  $env:FIREBASE_STORAGE_ENABLED = 'true'

  if ([string]::IsNullOrWhiteSpace($env:FIREBASE_SERVICE_ACCOUNT) -and
      [string]::IsNullOrWhiteSpace($env:GOOGLE_APPLICATION_CREDENTIALS)) {
    $serviceAccount = Read-Host 'Path to a reliefroute4 service-account JSON (leave blank to use Application Default Credentials)'
    if (-not [string]::IsNullOrWhiteSpace($serviceAccount)) {
      if (-not (Test-Path -LiteralPath $serviceAccount -PathType Leaf)) {
        throw 'The service-account JSON file was not found.'
      }
      $env:FIREBASE_SERVICE_ACCOUNT = (Resolve-Path -LiteralPath $serviceAccount).Path
    }
  }

  if ([string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
    $androidStudioJdk = 'C:\Program Files\Android\Android Studio\jbr'
    if (Test-Path -LiteralPath (Join-Path $androidStudioJdk 'bin\java.exe')) {
      $env:JAVA_HOME = $androidStudioJdk
    }
  }

  Set-Location $backend
  & .\mvnw.cmd spring-boot:run
  exit $LASTEXITCODE
}
finally {
  if ($passwordPointer -ne [IntPtr]::Zero) {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
  }
  foreach ($name in $environmentNames) {
    [Environment]::SetEnvironmentVariable($name, $oldEnvironment[$name], 'Process')
  }
}
