# ReliefRoute

ReliefRoute is a Flutter frontend for a South African medication ordering and delivery platform.

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

The current application is frontend-only. The medicine finder searches local catalogue data. Medical-aid benefits, doctor availability, pharmacy stock, payments, prescription review, authentication, notifications and delivery tracking are not connected to real services.

Typed domain foundations are kept in `lib/models.dart` and `lib/mock_repository.dart` so approved repositories can replace local data later. Do not store real passwords, payment credentials or medical files in this frontend.

## Verification

The widget tests cover the welcome screen and successful demo login. Run `flutter test` before each handoff. Run `flutter analyze` to catch lint and compatibility issues.

## Next integration work

1. Confirm the approved backend and database architecture.
2. Add secure authentication and role-based access control.
3. Connect catalogue, stock, order and prescription repositories.
4. Add an approved payment gateway without storing card details.
5. Configure secure file storage and pharmacist workflows.
6. Add notification and location services only after permissions and privacy requirements are approved.
