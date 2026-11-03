# ReliefRoute Spring Boot API

## Run locally

1. Install Java 17+ and Maven 3.9+.
2. From this folder run `docker compose up -d mysql`.
3. Run `mvn spring-boot:run`.
4. Check `http://localhost:8080/api/health` and `http://localhost:8080/api/medicines`.

The API uses MySQL for persistent data. Local development has authentication
disabled. For deployment, set `AUTH_REQUIRED=true` and add Firebase Admin token
verification before exposing protected endpoints. Never commit a service-account
JSON file.

The current Flutter demo still uses local mock data; the next client step is to
replace `MockRepository` calls with HTTP calls to this API and add Firebase
Flutter initialization using your own project configuration.

The API also exposes demo endpoints for `GET/POST /api/reminders`,
`GET/POST /api/orders`, and `GET/POST /api/prescriptions`. These endpoints keep
data in memory for classroom demonstration; the MySQL schema is ready for the
next repository layer.
