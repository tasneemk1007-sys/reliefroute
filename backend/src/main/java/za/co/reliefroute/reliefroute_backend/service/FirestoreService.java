package za.co.reliefroute.reliefroute_backend.service;

import com.google.cloud.Timestamp;
import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.GeoPoint;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.SetOptions;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

@Service
public class FirestoreService {

    // Only these collections can be reached through the API.
    private static final Set<String> ALLOWED = Set.of(
            "medications", "appointments", "pharmacies", "users", "orders", "order_items",
            "prescriptions", "deliveries", "drivers", "refill_reminders");

    // Your medications collection currently has a leading space in its name (" medications").
    // Until you create a proper "medications" collection, we fall back to the old one.
    private static final Map<String, String> LEGACY_NAMES = Map.of("medications", " medications");

    private final Firestore firestore;

    public FirestoreService(Firestore firestore) {
        this.firestore = firestore;
    }

    public boolean isAllowed(String collection) {
        return ALLOWED.contains(collection);
    }

    public CollectionReference collectionRef(String name) throws Exception {
        String collectionName = Objects.requireNonNull(name, "collection name must not be null");
        CollectionReference main = firestore.collection(collectionName);
        String legacy = LEGACY_NAMES.get(name);
        if (legacy != null && main.limit(1).get().get().isEmpty()) {
            CollectionReference old = firestore.collection(legacy);
            if (!old.limit(1).get().get().isEmpty()) {
                return old;
            }
        }
        return main;
    }

    public List<Map<String, Object>> list(String name) throws Exception {
        List<Map<String, Object>> out = new ArrayList<>();
        for (QueryDocumentSnapshot d : collectionRef(name).get().get().getDocuments()) {
            out.add(toMap(d));
        }
        return out;
    }

    public Map<String, Object> get(String name, String id) throws Exception {
        DocumentSnapshot d = collectionRef(name).document(required(id, "document id")).get().get();
        return d.exists() ? toMap(d) : null;
    }

    public Map<String, Object> create(String name, Map<String, Object> data) throws Exception {
        Map<String, Object> payload = Objects.requireNonNull(data, "document data must not be null");
        DocumentReference ref = collectionRef(name).add(payload).get();
        Map<String, Object> out = new LinkedHashMap<>(payload);
        out.put("id", ref.getId());
        return out;
    }

    // Partial update: only the fields you send are changed.
    public boolean update(String name, String id, Map<String, Object> data) throws Exception {
        Map<String, Object> payload = Objects.requireNonNull(data, "document data must not be null");
        DocumentReference ref = collectionRef(name).document(required(id, "document id"));
        if (!ref.get().get().exists()) {
            return false;
        }
        ref.set(payload, SetOptions.merge()).get();
        return true;
    }

    public Map<String, Object> set(String name, String id, Map<String, Object> data) throws Exception {
        Map<String, Object> payload = Objects.requireNonNull(data, "document data must not be null");
        DocumentReference ref = collectionRef(name).document(required(id, "document id"));
        ref.set(payload).get();
        Map<String, Object> result = new LinkedHashMap<>(payload);
        result.put("id", ref.getId());
        return result;
    }

    public boolean delete(String name, String id) throws Exception {
        DocumentReference ref = collectionRef(name).document(required(id, "document id"));
        if (!ref.get().get().exists()) {
            return false;
        }
        ref.delete().get();
        return true;
    }

    private String required(String value, String description) {
        return Objects.requireNonNull(value, description + " must not be null");
    }

    // "id" in every result is the Firestore document ID.
    public Map<String, Object> toMap(DocumentSnapshot d) {
        Map<String, Object> out = new LinkedHashMap<>();
        Map<String, Object> data = d.getData();
        if (data != null) {
            for (Map.Entry<String, Object> e : data.entrySet()) {
                out.put(e.getKey(), clean(e.getValue()));
            }
        }
        out.put("id", d.getId());
        return out;
    }

    // Turns Firestore-specific types into plain JSON-friendly values.
    private Object clean(Object v) {
        if (v instanceof Timestamp t) {
            return t.toDate().toInstant().toString();
        }
        if (v instanceof GeoPoint g) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("latitude", g.getLatitude());
            m.put("longitude", g.getLongitude());
            return m;
        }
        if (v instanceof DocumentReference r) {
            return r.getPath();
        }
        if (v instanceof Map<?, ?> map) {
            Map<String, Object> out = new LinkedHashMap<>();
            for (Map.Entry<?, ?> e : map.entrySet()) {
                out.put(String.valueOf(e.getKey()), clean(e.getValue()));
            }
            return out;
        }
        if (v instanceof List<?> list) {
            List<Object> out = new ArrayList<>();
            for (Object o : list) {
                out.add(clean(o));
            }
            return out;
        }
        return v;
    }
}
