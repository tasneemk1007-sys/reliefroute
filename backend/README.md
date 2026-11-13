# ReliefRoute Spring Boot API

This backend uses Firebase Admin SDK for the `reliefroute-90279` Firestore and
Storage project. The service account key is private and is intentionally not in
the repository.

## Run locally

1. Install Java 17+ (or use the JDK bundled with Android Studio). Maven Wrapper
   is included, so no system Maven install is required.
2. Ask the database owner for Firebase Console access and generate a service
   account key. Keep it outside this repository.
3. Set `GOOGLE_APPLICATION_CREDENTIALS` to the JSON file's absolute path.
4. Configure `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD` for the local MySQL 8+
   `reliefroute` database. Flyway applies `V1` and the demo-record `V2` migration
   on startup.
5. From this folder run `./mvnw spring-boot:run` (PowerShell: `./mvnw.cmd
   spring-boot:run`).
6. Check `http://localhost:8080/api/firebase-check`.

Firestore remains the store for user profiles, carts, and driver location
documents. The verified medicine catalogue, doctor/pharmacy directory, and
orders use MySQL. Storage paths are `Medicines pic/` and `prescriptions/`.
Never commit a service-account JSON file or database password.

The Flutter client uses this API for the medicine catalogue, provider directory
and checkout. The imported doctor and pharmacy records are fictional demo data;
demo medicines have no verified price or stock and are not orderable. Real
provider data and medicine inventory must be verified before use. The API
endpoints `/api/directory/doctors` and `/api/directory/pharmacies` are
authenticated. Its
default URL is `http://localhost:8080/api` for web/desktop. For Android, pass
the host computer's LAN address, for example:
`flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api`.

The Firebase Flutter client and this Spring Boot API run as separate processes:
Firebase handles authentication and live carts, while this API handles
catalogue stock and order placement.

Medicine catalogue, doctor directory, pharmacy directory, and checkout queries
read from MySQL. Firebase handles authentication and live carts.
