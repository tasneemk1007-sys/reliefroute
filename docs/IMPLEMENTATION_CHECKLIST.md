# ReliefRoute implementation checklist

This checklist records the audit and the remaining production work. The
canonical Flutter app is `reliefroutee`; the temporary ZIP opened in the IDE
is not the working source tree.

## Completed in this pass

- Read and checked `docs/ui-ux-spec.md` against the existing screens.
- Confirmed the existing Flutter app, Android project, iOS project, and Web project.
- Confirmed Firebase project `reliefroute4` is configured for Android, Web, and iOS.
- Registered the existing Android package and iOS bundle identifier without inventing new identifiers.
- Generated `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`.
- Confirmed Firebase initialization is present in `main.dart`.
- Confirmed offline demo mode remains available.
- Added MySQL/Flyway dependencies and a baseline migration to the Spring Boot backend.
- Added environment-based datasource configuration; no database password is stored in Flutter.

## Remaining implementation work

- Replace Firestore CRUD and order services with MySQL repositories.
- Remove backend password hashing and use Firebase ID-token verification.
- Add authenticated request filtering and patient/pharmacist/admin authorization.
- Add MySQL entities and APIs for prescriptions, reminders, addresses, and deliveries.
- Attach Firebase ID tokens to Flutter API requests.
- Implement Firebase Storage prescription upload with rules and plan verification.
- Connect order, prescription, reminder, profile, and settings screens to real APIs.
- Add registration, password reset, auth-state restoration, and sign-out flows.
- Add API contract, security, repository, and Flutter integration tests.
- Run Flutter analyze/tests and Android build to completion.
- Run CocoaPods/Xcode build on macOS; this cannot be verified on Windows.
- Configure staging/production environment variables and deployment secrets.
