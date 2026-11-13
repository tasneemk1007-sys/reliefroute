package za.co.reliefroute.reliefroute_backend.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import org.springframework.dao.DuplicateKeyException;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class OrderJdbcService {
    private final JdbcTemplate jdbc;
    private final FirestoreService firestore;

    public OrderJdbcService(JdbcTemplate jdbc, FirestoreService firestore) {
        this.jdbc = jdbc;
        this.firestore = firestore;
    }

    @Transactional
    public Map<String, Object> place(Map<String, Object> body) {
        String firebaseUid = text(body.get("user_id"));
        String address = text(body.get("address"));
        Object raw = body.get("items");
        if (firebaseUid.isBlank() || address.length() < 8 || !(raw instanceof List<?> items) || items.isEmpty()) {
            throw bad("user_id, a complete delivery address and a non-empty items list are required");
        }
        ensurePatient(firebaseUid, text(body.get("user_email")), text(body.get("user_name")));
        BigDecimal subtotal = BigDecimal.ZERO;
        List<Map<String, Object>> lines = new ArrayList<>();
        for (Object value : items) {
            if (!(value instanceof Map<?, ?> item)) throw bad("Each item must be an object");
            String medicineId = text(item.get("medication_id"));
            int quantity = number(item.get("quantity"));
            if (medicineId.isBlank() || quantity <= 0) throw bad("Invalid medicine item");
            Map<String, Object> medicine;
            try {
                medicine = jdbc.queryForMap("SELECT id,name,price,stock_quantity,prescription_required FROM medicines WHERE public_id=? AND active=TRUE FOR UPDATE", medicineId);
            } catch (org.springframework.dao.EmptyResultDataAccessException e) {
                throw notFound("Medicine not found: " + medicineId);
            }
            if (Boolean.TRUE.equals(medicine.get("prescription_required"))) {
                throw bad("Prescription medicine requires pharmacist review");
            }
            int stock = ((Number) medicine.get("stock_quantity")).intValue();
            if (stock < quantity) throw bad("Not enough stock for " + medicine.get("name"));
            BigDecimal price = new BigDecimal(String.valueOf(medicine.get("price")));
            subtotal = subtotal.add(price.multiply(BigDecimal.valueOf(quantity)));
            jdbc.update("UPDATE medicines SET stock_quantity=stock_quantity-? WHERE id=?", quantity, medicine.get("id"));
            lines.add(Map.of("medicine_id", medicine.get("id"), "quantity", quantity, "unit_price", price));
        }
        BigDecimal delivery = new BigDecimal("35.00");
        BigDecimal total = subtotal.add(delivery);
        BigDecimal expectedTotal = decimal(body.get("expected_total"));
        if (expectedTotal != null && expectedTotal.compareTo(total) != 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "The order total changed. Review the updated total before placing the order.");
        }
        String reference = "RR-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        jdbc.update("INSERT INTO orders(reference,firebase_uid,address,status,subtotal,delivery_fee,total) VALUES(?,?,?,?,?,?,?)", reference, firebaseUid, address, "placed", subtotal, delivery, total);
        Long orderId = jdbc.queryForObject("SELECT id FROM orders WHERE reference=?", Long.class, reference);
        for (Map<String, Object> line : lines) jdbc.update("INSERT INTO order_items(order_id,medicine_id,quantity,unit_price) VALUES(?,?,?,?)", orderId, line.get("medicine_id"), line.get("quantity"), line.get("unit_price"));
        return Map.of("id", orderId, "reference", reference, "status", "placed", "subtotal", subtotal, "delivery_fee", delivery, "total", total, "items", lines);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> quote(Map<String, Object> body) {
        String address = text(body.get("address"));
        Object raw = body.get("items");
        if (address.length() < 8 || !(raw instanceof List<?> items) || items.isEmpty()) {
            throw bad("A complete delivery address and non-empty items list are required");
        }
        BigDecimal subtotal = BigDecimal.ZERO;
        List<Map<String, Object>> pricedItems = new ArrayList<>();
        for (Object value : items) {
            if (!(value instanceof Map<?, ?> item)) throw bad("Each item must be an object");
            String medicineId = text(item.get("medication_id"));
            int quantity = number(item.get("quantity"));
            if (medicineId.isBlank() || quantity <= 0) throw bad("Invalid medicine item");

            Map<String, Object> medicine;
            try {
                medicine = jdbc.queryForMap("""
                        SELECT id,name,price,stock_quantity,prescription_required
                        FROM medicines WHERE public_id=? AND active=TRUE
                        """, medicineId);
            } catch (org.springframework.dao.EmptyResultDataAccessException missing) {
                throw notFound("Medicine not found: " + medicineId);
            }
            if (Boolean.TRUE.equals(medicine.get("prescription_required"))) {
                throw bad("Prescription medicine requires pharmacist review");
            }
            if (((Number) medicine.get("stock_quantity")).intValue() < quantity) {
                throw bad("Not enough stock for " + medicine.get("name"));
            }
            BigDecimal unitPrice = new BigDecimal(String.valueOf(medicine.get("price")));
            BigDecimal lineTotal = unitPrice.multiply(BigDecimal.valueOf(quantity));
            subtotal = subtotal.add(lineTotal);
            pricedItems.add(Map.of(
                    "medication_id", medicineId,
                    "medicine_name", medicine.get("name"),
                    "quantity", quantity,
                    "unit_price", unitPrice,
                    "line_total", lineTotal));
        }
        BigDecimal delivery = new BigDecimal("35.00");
        return Map.of(
                "items", pricedItems,
                "subtotal", subtotal,
                "delivery_fee", delivery,
                "total", subtotal.add(delivery));
    }

    @Transactional
    public Map<String, Object> assignDriver(String reference, String driverUid) {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT firebase_uid FROM orders WHERE reference=?", reference);
        if (rows.isEmpty()) throw notFound("Order not found");
        Map<String, Object> delivery = new LinkedHashMap<>();
        delivery.put("orderReference", reference);
        delivery.put("customerId", String.valueOf(rows.get(0).get("firebase_uid")));
        delivery.put("driverId", driverUid);
        try {
            return firestore.set("deliveries", reference, delivery);
        } catch (Exception error) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                    "Could not create delivery tracking", error);
        }
    }

    private void ensurePatient(String uid, String email, String name) {
        if (uid.isBlank() || email.isBlank() || !email.contains("@")) {
            throw bad("A verified Firebase account with an email address is required");
        }
        String fullName = name.isBlank() ? email.substring(0, email.indexOf('@')) : name;
        List<Map<String, Object>> existing = jdbc.queryForList(
                "SELECT email FROM users WHERE firebase_uid=?", uid);
        if (!existing.isEmpty()) {
            if (!email.equalsIgnoreCase(String.valueOf(existing.get(0).get("email")))) {
                try {
                    jdbc.update("UPDATE users SET email=?,full_name=? WHERE firebase_uid=?",
                            email, fullName, uid);
                } catch (DuplicateKeyException conflict) {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT, "This email belongs to another patient account");
                }
            }
            return;
        }
        try {
            jdbc.update("""
                    INSERT INTO users(firebase_uid,email,full_name,role)
                    VALUES(?,?,?,'customer')
                    """, uid, email, fullName);
        } catch (DuplicateKeyException concurrentCreate) {
            // Allow a retry that raced another request for the same Firebase UID.
            if (jdbc.queryForList("SELECT id FROM users WHERE firebase_uid=?", uid).isEmpty()) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT, "This email belongs to another patient account");
            }
        }
    }

    public List<Map<String, Object>> forUser(String firebaseUid) {
        return jdbc.queryForList("SELECT o.reference,o.status,o.subtotal,o.delivery_fee,o.total,o.created_at FROM orders o WHERE o.firebase_uid=? ORDER BY o.created_at DESC", firebaseUid);
    }

    public Map<String, Object> tracking(String reference, String firebaseUid) {
        try {
            return jdbc.queryForMap("SELECT o.id,o.reference,o.status,o.subtotal,o.delivery_fee,o.total,o.created_at,o.updated_at FROM orders o WHERE o.reference=? AND o.firebase_uid=?", reference, firebaseUid);
        } catch (org.springframework.dao.EmptyResultDataAccessException e) {
            throw notFound("Order not found");
        }
    }

    private static String text(Object value) { return value == null ? "" : String.valueOf(value).trim(); }
    private static int number(Object value) { return value instanceof Number n ? n.intValue() : -1; }
    private static BigDecimal decimal(Object value) {
        if (value == null) return null;
        try {
            return new BigDecimal(String.valueOf(value));
        } catch (NumberFormatException error) {
            throw bad("Invalid expected total");
        }
    }
    private static ResponseStatusException bad(String message) { return new ResponseStatusException(HttpStatus.BAD_REQUEST, message); }
    private static ResponseStatusException notFound(String message) { return new ResponseStatusException(HttpStatus.NOT_FOUND, message); }
}
