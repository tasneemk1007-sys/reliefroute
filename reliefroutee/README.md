# ReliefRoute

ReliefRoute is a Flutter student project for a South African medication ordering and delivery app.

## Run

Install Flutter on the computer first. From the repository root, run `./run_reliefroute.ps1`. For Android, pass a backend URL reachable from the phone, such as `./run_reliefroute.ps1 -Device android -ApiBaseUrl http://192.168.1.10:8080/api`. Do not copy machine-specific build output or `android/local.properties`.

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

For the demonstration login, enter any username and a password with at least four characters, for example `Tasneem` and `demo1234`.

## Team handoff

The app uses Firebase Authentication and Firestore for sign-in and patient data, and the Spring Boot API with MySQL for the medicine catalogue and order checkout. Some staff and health-service features remain demonstrations or are marked Coming soon.

The data classes are kept in `lib/models.dart` and the sample data is in `lib/mock_repository.dart`. Do not store real passwords, payment details or medical files in this frontend.

## Verification

Run `flutter analyze` to check Dart changes.

## Backend connection

Start the Spring Boot API from the repository's `backend` folder. The catalogue and checkout use `http://localhost:8080/api` by default for web/desktop. On Android, set `API_BASE_URL` to the computer's LAN address as described above. The HTTP client is in `lib/api_service.dart`.

## Next integration work

1. Finish the staff, payment and prescription review integrations.
2. Configure Firebase and MySQL credentials for each deployment environment.
3. Validate delivery driver assignment and tracking with deployed Firebase rules.
