package za.co.reliefroute.reliefroute_backend.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class OrderJdbcService {
    private final JdbcTemplate jdbc;

    public OrderJdbcService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @Transactional
    public Map<String, Object> place(Map<String, Object> body) {
        String firebaseUid = text(body.get("user_id"));
        String address = text(body.get("address"));
        Object raw = body.get("items");
        if (firebaseUid.isBlank() || address.isBlank() || !(raw instanceof List<?> items) || items.isEmpty()) {
            throw bad("user_id, address and a non-empty items list are required");
        }
        Integer userCount = jdbc.queryForObject("SELECT COUNT(*) FROM users WHERE firebase_uid = ?", Integer.class, firebaseUid);
        if (userCount == null || userCount == 0) throw notFound("User is not registered");
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
            int stock = ((Number) medicine.get("stock_quantity")).intValue();
            if (stock < quantity) throw bad("Not enough stock for " + medicine.get("name"));
            BigDecimal price = new BigDecimal(String.valueOf(medicine.get("price")));
            subtotal = subtotal.add(price.multiply(BigDecimal.valueOf(quantity)));
            jdbc.update("UPDATE medicines SET stock_quantity=stock_quantity-? WHERE id=?", quantity, medicine.get("id"));
            lines.add(Map.of("medicine_id", medicine.get("id"), "quantity", quantity, "unit_price", price));
        }
        BigDecimal delivery = new BigDecimal("35.00");
        BigDecimal total = subtotal.add(delivery);
        String reference = "RR-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        jdbc.update("INSERT INTO orders(reference,firebase_uid,address,status,subtotal,delivery_fee,total) VALUES(?,?,?,?,?,?,?)", reference, firebaseUid, address, "placed", subtotal, delivery, total);
        Long orderId = jdbc.queryForObject("SELECT id FROM orders WHERE reference=?", Long.class, reference);
        for (Map<String, Object> line : lines) jdbc.update("INSERT INTO order_items(order_id,medicine_id,quantity,unit_price) VALUES(?,?,?,?)", orderId, line.get("medicine_id"), line.get("quantity"), line.get("unit_price"));
        return Map.of("id", orderId, "reference", reference, "status", "placed", "subtotal", subtotal, "delivery_fee", delivery, "total", total, "items", lines);
    }

    public List<Map<String, Object>> forUser(String firebaseUid) {
        return jdbc.queryForList("SELECT o.reference,o.status,o.subtotal,o.delivery_fee,o.total,o.created_at FROM orders o WHERE o.firebase_uid=? ORDER BY o.created_at DESC", firebaseUid);
    }

    public Map<String, Object> tracking(String reference, String firebaseUid) {
        try {
            return jdbc.queryForMap("SELECT o.reference,o.status,o.subtotal,o.delivery_fee,o.total,o.created_at,o.updated_at FROM orders o WHERE o.reference=? AND o.firebase_uid=?", reference, firebaseUid);
        } catch (org.springframework.dao.EmptyResultDataAccessException e) {
            throw notFound("Order not found");
        }
    }

    private static String text(Object value) { return value == null ? "" : String.valueOf(value).trim(); }
    private static int number(Object value) { return value instanceof Number n ? n.intValue() : -1; }
    private static ResponseStatusException bad(String message) { return new ResponseStatusException(HttpStatus.BAD_REQUEST, message); }
    private static ResponseStatusException notFound(String message) { return new ResponseStatusException(HttpStatus.NOT_FOUND, message); }
}
