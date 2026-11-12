# ReliefRoute implementation checklist

This checklist records the audit and remaining production work. The canonical
Flutter app is the repository root. The Spring Boot backend remains in
`backend/`.

## Completed in this pass

- Read and checked `docs/ui-ux-spec.md` against the existing screens.
- Confirmed the existing Flutter app, Android project, and Web project.
- Confirmed Firebase project `reliefroute4` is configured for Android and Web.
- Preserved the existing Android package identifier.
- Confirmed `lib/firebase_options.dart`, `android/app/google-services.json`, and Firebase rules target `reliefroute4`.
- Confirmed Firebase initialization is present in `main.dart`.
- Confirmed offline demo mode remains available.
- Added baseline, care/delivery, and demo seed Flyway migrations to the Spring Boot backend.
- Added environment-based datasource configuration; no database password is stored in Flutter.

## Remaining implementation work

- Replace Firestore CRUD and order services with MySQL repositories.
- Remove backend password hashing and use Firebase ID-token verification.
- Add authenticated request filtering and patient/pharmacist/admin authorization.
- Finish pharmacist review, order status administration, and payment integration.
- Attach Firebase ID tokens to Flutter API requests.
- Implement Firebase Storage prescription upload with rules and plan verification.
- Connect order, prescription, reminder, profile, and settings screens to real APIs.
- Add registration, password reset, auth-state restoration, and sign-out flows.
- Add API contract, security, repository, and Flutter integration tests.
- Run Flutter analysis, tests, and Android build from the repository root.
- Run CocoaPods/Xcode build on macOS; this cannot be verified on Windows.
- Configure staging/production environment variables and deployment secrets.
