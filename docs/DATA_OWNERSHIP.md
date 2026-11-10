# ReliefRoute data ownership

ReliefRoute now uses an explicit source-of-truth boundary. Existing records are
not deleted or migrated by this change.

## Firebase Authentication and Firestore

Firestore is the source of truth for Firebase patient-portal data:

- `users/{uid}`: the patient profile and role-protected profile fields.
- `medications`: patient-owned medication records, keyed by `userId`.
- `appointments`: patient-owned appointment requests, keyed by `userId`.
- `users/{uid}/reminders`: patient reminders.
- `users/{uid}/notifications`: server-created patient notifications.

The Flutter patient portal reads and writes these records directly with the
authenticated Firebase client. Firestore rules enforce ownership, while the
Spring Boot Admin SDK must enforce ownership explicitly whenever it accesses
these records.

## MySQL and Spring Boot

MySQL is the source of truth for transactional commerce and operational data:

- `medicines`: catalogue, prices, stock and prescription requirements.
- `orders`, `order_items`: checkout transactions and line items.
- `addresses`: checkout delivery addresses.
- `prescriptions`: the existing backend prescription workflow.

The Spring Boot API is the owner of these operations and requires a validated
Firebase ID token. The authenticated UID is taken from the token, never trusted
from a request body or URL for ownership decisions.

## Boundary enforcement

The generic Firestore CRUD endpoint is intentionally limited to administrator
medication operations. It no longer exposes generic Firestore orders,
prescriptions, deliveries, drivers, pharmacies or user records. Orders are
served by the dedicated MySQL controller, and patient profiles, medications and
appointments use the Firestore patient service.

The repository still contains legacy Firestore order services and historical
Firestore data. They are retained for compatibility and are not used as the
active patient checkout source. A future migration should be planned before
removing them; it must reconcile records and be backed up first.
