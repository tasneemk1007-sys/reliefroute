# ReliefRoute database setup

## MySQL

For a fresh database, `mysql/schema.sql` mirrors the Flyway migrations. Prefer
letting the Spring Boot backend apply Flyway so the schema and seed versions stay
in sync. Configure `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD`;
`backend/run-backend.ps1` prompts for these locally without writing the password
to a file.

### Demo records and application integration

`mysql/ReliefRoute_Demo_Seed_Data.sql` is the Workbench-ready demo import. Open
it in MySQL Workbench and execute it against the local MySQL server. It creates
`demo_medicines`, `doctors`, and `pharmacies` in the `reliefroute` database. The
records are explicitly unverified/fictional. Demo medicines have no price or
stock and cannot be ordered.

The same schema and rows are included in the Spring Boot Flyway migration
`backend/src/main/resources/db/migration/V3__demo_seed_data.sql`. On startup,
Flyway creates/updates the schema and applies the demo seed. Do not configure
Flutter to connect directly to MySQL; the authenticated API exposes the
catalogue and `/api/directory/doctors` and `/api/directory/pharmacies`.

## Firebase

Use only the existing Firebase project `reliefroute4`. Enable Email/Password
Authentication, Firestore, and Storage there, then deploy
`firebase/firestore.rules` and `firebase/firestore.indexes.json` with the Firebase
CLI. Do not commit service-account JSON or database passwords.

The Flutter app should call a trusted backend for MySQL operations. A Flutter web
client must never contain a MySQL password or connect directly to MySQL.
