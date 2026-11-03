# RELIEFROUTE

ReliefRoute is a cross-platform Flutter medication ordering and delivery
platform for patients who may face pharmacy queues, repeated trips,
transportation limitations, mobility barriers, age, chronic illness, or
physical disability.

## Technology

- Frontend: Flutter and Dart
- Backend: Java and Spring Boot
- Database: Firebase Cloud Firestore
- Authentication: Firebase Authentication
- Storage: Firebase Storage
- Maps: OpenStreetMap tiles with `flutter_map`
- Currency: South African Rand (ZAR)

## Run the Flutter app

```bash
cd reliefroutee
flutter pub get
flutter run
```

## Main features

Patient features include medicine browsing, prescriptions, cart and checkout,
order tracking, order history, reminders, and favourites. The planned staff
areas cover pharmacist prescription review, driver delivery updates, inventory,
user management, and reporting.

The current release is a student project using sample data in some screens.
Firebase production setup requires the private service-account file described
in `backend/README.md`; that file must never be committed.

## Brand colours

Teal `#087F8C`, Navy `#123047`, Mint `#E5F6F2`, Canvas `#F6F8FA`, Ink `#1F2937`,
and Muted `#64748B`.
