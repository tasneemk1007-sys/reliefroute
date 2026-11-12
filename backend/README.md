# ReliefRoute Spring Boot API

This backend uses Firebase project `reliefroute4` for Authentication token
verification, Firestore, and Cloud Storage. Never commit a service-account key.

## Run locally

1. Install Java 17+ (or use the JDK bundled with Android Studio). Maven Wrapper
   is included, so no system Maven install is required.
2. Set up Application Default Credentials for `reliefroute4`, or create a
   service-account JSON in Firebase Console > Project settings > Service
   accounts. The key must belong to `reliefroute4` and stay outside this repo.
3. Set `GOOGLE_APPLICATION_CREDENTIALS` to that JSON file's absolute path, or
   set `FIREBASE_SERVICE_ACCOUNT` to the same path. The backend rejects a
   service-account JSON whose `project_id` does not match `reliefroute4`.
4. Run `./run-backend.ps1` in PowerShell to enter the MySQL URL, username and
   password at launch. It keeps the password in the process environment only,
   sets Firebase defaults to `reliefroute4`, and lets you select a service key
   outside the repo or use existing ADC. Flyway applies `V1` (baseline), `V2`
   (care and delivery tables), and `V3` (demo records) on startup.
5. To launch without the helper, set `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD`
   plus Firebase credentials in your shell, then run `./mvnw spring-boot:run`
   (PowerShell: `./mvnw.cmd spring-boot:run`).
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
