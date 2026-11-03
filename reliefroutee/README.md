# ReliefRoute

ReliefRoute is a Flutter student project for a South African medication ordering and delivery app.

## Run

Install Flutter on the computer first. Do not copy machine-specific build output or `android/local.properties`; Flutter/Android tooling creates local configuration for each developer.

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

For the demonstration login, enter any username and a password with at least four characters, for example `Tasneem` and `demo1234`.

## Team handoff

The current application uses sample data so that the screens can be tested without a live service. The medicine finder searches the local catalogue. Medical-aid benefits, doctor availability, pharmacy stock, payments, prescription review, authentication, notifications and delivery tracking still need service connections.

The data classes are kept in `lib/models.dart` and the sample data is in `lib/mock_repository.dart`. Do not store real passwords, payment details or medical files in this frontend.

## Verification

The widget tests cover the welcome screen and successful demo login. Run `flutter test` before each handoff. Run `flutter analyze` to catch lint and compatibility issues.

## Backend connection

Start the Spring Boot API from the repository's `backend` folder. The medicine
finder calls `http://localhost:8080/api/medicines`. If the API is offline, it
uses the local sample catalogue instead. The HTTP client is in
`lib/api_service.dart`.

## Next integration work

1. Connect the remaining Flutter screens to the Spring Boot API.
2. Add login and user roles.
3. Connect the catalogue, stock, orders and prescriptions to MySQL.
4. Add payment and file storage using services that meet the project requirements.
5. Test the app with sample users and sample orders.
