# ReliefRoute Spring Boot API

This backend uses Firebase Admin SDK for the `reliefroute-90279` Firestore and
Storage project. The service account key is private and is intentionally not in
the repository.

## Run locally

1. Install Java 21+ and Maven 3.9+.
2. Ask the database owner for Firebase Console access and generate a service
   account key. Keep it outside this repository.
3. Set `GOOGLE_APPLICATION_CREDENTIALS` to the JSON file's absolute path.
4. From this folder run `mvn spring-boot:run`.
5. Check `http://localhost:8080/api/firebase-check`.

The generic Firestore API supports medications, pharmacies, users, drivers,
orders, order_items, deliveries, prescriptions, and refill_reminders. Storage
paths are `Medicines pic/` and `prescriptions/`. Never commit a service-account
JSON file.

The current Flutter demo still uses local mock data; the next client step is to
replace `MockRepository` calls with HTTP calls to this API and add Firebase
Flutter initialization using your own project configuration.

The API also exposes demo endpoints for `GET/POST /api/reminders`,
`GET/POST /api/orders`, and `GET/POST /api/prescriptions`. These endpoints keep
data in memory for classroom demonstration; the MySQL schema is ready for the
next repository layer.
