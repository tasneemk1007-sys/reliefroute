# ReliefRoute database setup

## MySQL

Run `mysql -u root -p < database/mysql/schema.sql` against a MySQL 8+ server.
The schema stores catalogue, stock, orders, prescriptions and reminders. Passwords
are intentionally not stored in MySQL; Firebase Authentication owns them.

## Firebase

Create a Firebase project, enable Email/Password Authentication and Firestore,
then deploy `firebase/firestore.rules` and `firebase/firestore.indexes.json` with
the Firebase CLI. Do not commit Firebase configuration files, service-account
JSON, or database passwords.

The Flutter app should call a trusted backend for MySQL operations. A Flutter web
client must never contain a MySQL password or connect directly to MySQL.
