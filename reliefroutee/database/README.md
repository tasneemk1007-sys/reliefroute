# ReliefRoute database setup

## MySQL

Run `mysql -u root -p < database/mysql/schema.sql` against a MySQL 8+ server.
The schema stores catalogue, stock, orders, prescriptions and reminders. Passwords
are intentionally not stored in MySQL; Firebase Authentication owns them.

### Demo records and application integration

`mysql/ReliefRoute_Demo_Seed_Data.sql` is the Workbench-ready demo import. Open
it in MySQL Workbench and execute it against the local MySQL server. It creates
`demo_medicines`, `doctors`, and `pharmacies` in the `reliefroute` database. The
records are explicitly unverified/fictional. Demo medicines have no price or
stock and cannot be ordered.

The same schema and rows are included in the Spring Boot Flyway migration
`backend/src/main/resources/db/migration/V2__demo_seed_data.sql`. The backend
uses the MySQL datasource configured by `DB_URL`, `DB_USERNAME`, and
`DB_PASSWORD` in `backend/src/main/resources/application.yml`. On startup,
Flyway creates/updates the schema and applies the demo seed. Do not configure
Flutter to connect directly to MySQL; the authenticated API exposes the
catalogue and `/api/directory/doctors` and `/api/directory/pharmacies`.

## Firebase

Create a Firebase project, enable Email/Password Authentication and Firestore,
then deploy `firebase/firestore.rules` and `firebase/firestore.indexes.json` with
the Firebase CLI. Do not commit Firebase configuration files, service-account
JSON, or database passwords.

The Flutter app should call a trusted backend for MySQL operations. A Flutter web
client must never contain a MySQL password or connect directly to MySQL.
