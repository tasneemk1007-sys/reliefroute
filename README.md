# ReliefRoute

ReliefRoute is a Flutter medication ordering and delivery application with a
separate Spring Boot API. The official Flutter project is this repository root;
the Java backend remains in `backend/`.

## Flutter app

Run Flutter commands from the repository root:

```powershell
flutter pub get
flutter run -d chrome
```

For an Android emulator, use the emulator's host-loopback address. For a
physical phone, use the computer's LAN address:

```powershell
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
flutter run -d android --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

The optional PowerShell launcher is `./run_reliefroute.ps1`; it now runs from
the repository root.

## Verify Flutter

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

## Backend and database

The Spring Boot API is independent and remains under `backend/`. See
[`backend/README.md`](backend/README.md) for Java, MySQL, Firebase credentials,
and run instructions. Flyway migrations are in
`backend/src/main/resources/db/migration/`. The Workbench seed script is in
[`database/mysql/ReliefRoute_Demo_Seed_Data.sql`](database/mysql/ReliefRoute_Demo_Seed_Data.sql).

## Project structure

- `lib/`, `test/`, `assets/`, `web/`, `android/`: the canonical Flutter app.
- `firebase/`: Firebase rules, indexes, and Flutter configuration.
- `database/`: MySQL schema and demo seed data.
- `backend/`: independently runnable Spring Boot API and migrations.
- `docs/`: design, integration, and deployment notes.

The demo provider records are fictional, and demo medicines have no verified
price or stock. They are not available for ordering.
