# Firebase and Cloud Run setup

Use Google/Firebase project `reliefroute4`. Create Cloud Firestore in Native
mode and enable Firebase Storage in that project. Create a `medications` collection. Medication documents
should contain `name`, `description`, `category`, `price`, `stock_qty`,
`prescription_required`, `active`, and `pharmacy_id`.

For local development, use a `reliefroute4` service-account JSON path through
`GOOGLE_APPLICATION_CREDENTIALS`, plus `FIREBASE_PROJECT_ID=reliefroute4` and
`FIREBASE_STORAGE_BUCKET=reliefroute4.firebasestorage.app`, then run
`./mvnw.cmd spring-boot:run` from `backend`.
Cloud Run uses Application Default Credentials, so no JSON key belongs in the
container or repository.

After startup, `POST /api/admin/seed-medications` migrates the legacy medication
collection and creates entries from Storage images. Set real prices, stock,
prescription requirements, and active status before accepting orders.

From `backend`, authenticate `gcloud`, select the Firebase project, enable
Cloud Run, Artifact Registry, Cloud Build, Firestore, and Storage APIs, then
build and deploy the included Dockerfile. A typical deployment uses:

`gcloud builds submit --project reliefroute4 --tag REGION-docker.pkg.dev/reliefroute4/reliefroute/reliefroute-api:latest .`

`gcloud run deploy reliefroute-api --project reliefroute4 --image REGION-docker.pkg.dev/reliefroute4/reliefroute/reliefroute-api:latest --region REGION --allow-unauthenticated --set-env-vars FIREBASE_PROJECT_ID=reliefroute4,FIREBASE_STORAGE_BUCKET=reliefroute4.firebasestorage.app --port 8080`

Use a dedicated Cloud Run service account with only Firestore and Storage
permissions. Build Flutter with the deployed API URL using
`--dart-define=API_BASE_URL=https://SERVICE_URL/api`.

Firebase Auth and a real payment provider are still required before a public
medication-ordering launch; the current demo login is not production auth.
