package za.co.reliefroute.reliefroute_backend.service;

import com.google.api.core.ApiFuture;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.Transaction;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutionException;

@Service
public class OrderService {

    private static final Set<String> STATUSES = Set.of("Pending", "Confirmed", "Out for Delivery", "Delivered");

    private final Firestore firestore;
    private final FirestoreService db;

    public OrderService(Firestore firestore, FirestoreService db) {
        this.firestore = firestore;
        this.db = db;
    }

    /**
     * Places an order in one go: checks the medicines, checks stock, works out the total from
     * the medicine prices, reduces stock, and creates the order, its order_items and a delivery.
     * Either everything succeeds or nothing is saved.
     */
    public Map<String, Object> place(Map<String, Object> body) throws Exception {
        final String userId = text(body.get("user_id"));
        final String pharmacyId = text(body.get("pharmacy_id"));
        final String prescriptionId = text(body.get("prescription_id"));
        final String address = text(body.get("address"));
        if (userId.isEmpty()) {
            throw bad("user_id is required");
        }
        Object rawObj = body.get("items");
        if (!(rawObj instanceof List<?>) || ((List<?>) rawObj).isEmpty()) {
            throw bad("items must be a non-empty list of {medication_id, quantity}");
        }

        // Combine duplicates so stock is checked against the total asked for.
        final Map<String, Double> wanted = new LinkedHashMap<>();
        for (Object o : (List<?>) rawObj) {
            if (!(o instanceof Map<?, ?>)) {
                throw bad("each item must be an object");
            }
            Map<?, ?> m = (Map<?, ?>) o;
            String medId = text(m.get("medication_id"));
            Double qty = number(m.get("quantity"));
            if (medId.isEmpty() || qty == null || qty <= 0) {
                throw bad("each item needs a medication_id and a quantity above 0");
            }
            wanted.merge(medId, qty, Double::sum);
        }

        final CollectionReference meds = db.collectionRef("medications");
        final CollectionReference itemsCol = firestore.collection("order_items");
        final DocumentReference orderRef = firestore.collection("orders").document();
        final DocumentReference deliveryRef = firestore.collection("deliveries").document();
        final Timestamp now = Timestamp.now();

        ApiFuture<Map<String, Object>> future = firestore.runTransaction(
                (Transaction.Function<Map<String, Object>>) tx -> {
                    // ---- reads first (Firestore requires all reads before any write) ----
                    Map<String, DocumentSnapshot> snaps = new LinkedHashMap<>();
                    for (String medId : wanted.keySet()) {
                        snaps.put(medId, tx.get(meds.document(medId)).get());
                    }

                    double total = 0;
                    String pharmacy = pharmacyId;
                    List<Map<String, Object>> lines = new ArrayList<>();
                    List<Object[]> stockUpdates = new ArrayList<>();

                    for (Map.Entry<String, Double> e : wanted.entrySet()) {
                        DocumentSnapshot s = snaps.get(e.getKey());
                        if (!s.exists()) {
                            throw bad("Medication not found: " + e.getKey());
                        }
                        String name = text(s.get("name"));
                        Double price = number(s.get("prices"));
                        if (price == null || price <= 0) {
                            throw bad(name + " has no price set");
                        }
                        Double stock = number(s.get("stock_qty"));
                        double available = stock == null ? 0 : stock;
                        if (available < e.getValue()) {
                            throw bad("Not enough stock for " + name + " (available: " + available + ")");
                        }
                        if (Boolean.TRUE.equals(s.get("prescription_required")) && prescriptionId.isEmpty()) {
                            throw bad(name + " needs a prescription (send prescription_id)");
                        }
                        if (pharmacy.isEmpty()) {
                            pharmacy = text(s.get("pharmacy_id"));
                        }
                        total += price * e.getValue();

                        Map<String, Object> line = new LinkedHashMap<>();
                        line.put("medication_id", e.getKey());
                        line.put("quantity", e.getValue());
                        line.put("unit_price", price);
                        lines.add(line);
                        stockUpdates.add(new Object[]{s.getReference(), available - e.getValue()});
                    }
                    total = Math.round(total * 100.0) / 100.0;

                    // ---- writes ----
                    for (Object[] u : stockUpdates) {
                        tx.update((DocumentReference) u[0], "stock_qty", u[1]);
                    }

                    Map<String, Object> order = new LinkedHashMap<>();
                    order.put("order_date", now);
                    order.put("pharmacy_id", pharmacy);
                    order.put("prescription_id", prescriptionId);
                    order.put("status", "Pending");
                    order.put("total_amount", total);
                    order.put("user_id", userId);
                    tx.set(orderRef, order);

                    for (Map<String, Object> line : lines) {
                        Map<String, Object> item = new LinkedHashMap<>(line);
                        item.put("order_id", orderRef.getId());
                        tx.set(itemsCol.document(), item);
                    }

                    Map<String, Object> result = new LinkedHashMap<>();
                    result.put("id", orderRef.getId());
                    result.put("user_id", userId);
                    result.put("pharmacy_id", pharmacy);
                    result.put("prescription_id", prescriptionId);
                    result.put("status", "Pending");
                    result.put("total_amount", total);
                    result.put("order_date", now.toDate().toInstant().toString());
                    result.put("items", lines);

                    if (!address.isEmpty()) {
                        Map<String, Object> delivery = new LinkedHashMap<>();
                        delivery.put("address", address);
                        delivery.put("driver_id", "");
                        delivery.put("order_id", orderRef.getId());
                        delivery.put("status", "Pending");
                        delivery.put("tracking_time", now);
                        tx.set(deliveryRef, delivery);
                        result.put("delivery_id", deliveryRef.getId());
                    }
                    return result;
                });

        try {
            return future.get();
        } catch (ExecutionException e) {
            // Show our friendly errors (not enough stock, etc.) instead of a generic 500.
            Throwable t = e;
            while (t != null) {
                if (t instanceof ResponseStatusException r) {
                    throw r;
                }
                t = t.getCause();
            }
            throw e;
        }
    }

    public Map<String, Object> updateStatus(String orderId, String status) throws Exception {
        if (!STATUSES.contains(status)) {
            throw bad("status must be one of: " + STATUSES);
        }
        DocumentReference orderRef = firestore.collection("orders").document(orderId);
        if (!orderRef.get().get().exists()) {
            throw notFound("Order not found: " + orderId);
        }
        orderRef.update("status", status).get();

        DocumentSnapshot delivery = deliveryFor(orderId);
        if (delivery != null && (status.equals("Out for Delivery") || status.equals("Delivered"))) {
            delivery.getReference().update("status", status, "tracking_time", Timestamp.now()).get();
        }
        return tracking(orderId);
    }

    public Map<String, Object> assignDriver(String orderId, String driverId) throws Exception {
        if (driverId.isEmpty()) {
            throw bad("driver_id is required");
        }
        DocumentSnapshot driver = firestore.collection("drivers").document(driverId).get().get();
        if (!driver.exists()) {
            throw notFound("Driver not found: " + driverId);
        }
        DocumentReference orderRef = firestore.collection("orders").document(orderId);
        DocumentSnapshot order = orderRef.get().get();
        if (!order.exists()) {
            throw notFound("Order not found: " + orderId);
        }
        DocumentSnapshot delivery = deliveryFor(orderId);
        if (delivery == null) {
            throw notFound("This order has no delivery (it was placed without an address)");
        }
        delivery.getReference().update("driver_id", driverId, "status", "Assigned",
                "tracking_time", Timestamp.now()).get();
        if ("Pending".equals(order.getString("status"))) {
            orderRef.update("status", "Confirmed").get();
        }
        return tracking(orderId);
    }

    // Everything the app needs to show an order: order + items + delivery + driver.
    public Map<String, Object> tracking(String orderId) throws Exception {
        DocumentSnapshot order = firestore.collection("orders").document(orderId).get().get();
        if (!order.exists()) {
            throw notFound("Order not found: " + orderId);
        }
        Map<String, Object> out = db.toMap(order);

        List<Map<String, Object>> items = new ArrayList<>();
        for (QueryDocumentSnapshot d : firestore.collection("order_items")
                .whereEqualTo("order_id", orderId).get().get().getDocuments()) {
            items.add(db.toMap(d));
        }
        out.put("items", items);

        DocumentSnapshot delivery = deliveryFor(orderId);
        if (delivery != null) {
            Map<String, Object> d = db.toMap(delivery);
            out.put("delivery", d);
            String driverId = text(d.get("driver_id"));
            if (!driverId.isEmpty()) {
                DocumentSnapshot driver = firestore.collection("drivers").document(driverId).get().get();
                if (driver.exists()) {
                    out.put("driver", db.toMap(driver));
                }
            }
        }
        return out;
    }

    public List<Map<String, Object>> ordersForUser(String userId) throws Exception {
        List<Map<String, Object>> out = new ArrayList<>();
        for (QueryDocumentSnapshot d : firestore.collection("orders")
                .whereEqualTo("user_id", userId).get().get().getDocuments()) {
            out.add(db.toMap(d));
        }
        // newest first (order_date is an ISO string after conversion, so text sort works)
        out.sort((a, b) -> String.valueOf(b.getOrDefault("order_date", ""))
                .compareTo(String.valueOf(a.getOrDefault("order_date", ""))));
        return out;
    }

    private DocumentSnapshot deliveryFor(String orderId) throws Exception {
        List<QueryDocumentSnapshot> docs = firestore.collection("deliveries")
                .whereEqualTo("order_id", orderId).get().get().getDocuments();
        return docs.isEmpty() ? null : docs.get(0);
    }

    private static String text(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }

    private static Double number(Object o) {
        return o instanceof Number n ? n.doubleValue() : null;
    }

    private static ResponseStatusException bad(String msg) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, msg);
    }

    private static ResponseStatusException notFound(String msg) {
        return new ResponseStatusException(HttpStatus.NOT_FOUND, msg);
    }
}
