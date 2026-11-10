# Firebase Admin credentials

The Spring Boot backend uses Google Application Default Credentials to access
Firebase Admin services. For local development, set
`GOOGLE_APPLICATION_CREDENTIALS` to the absolute path of your private service
account JSON file:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\outside\this\repository\service-account.json"
```

Never upload this JSON file to GitHub, place it in the Flutter `lib` folder,
send it to anyone, or include it in an APK or other application download.

Keep credentials in a dedicated folder outside this repository. The repository
ignores common credential filenames and folders as an additional safeguard.
Do not add a blanket `*.json` ignore rule: this project legitimately tracks
Firebase and platform configuration JSON files.
