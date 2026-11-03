package za.co.reliefroute.demo;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.*;

@RestController @RequestMapping("/api")
public class PersistentDataController {
  private final JdbcTemplate db;
  public PersistentDataController(JdbcTemplate db) { this.db = db; }

  private long demoUserId() { return db.queryForObject("SELECT id FROM users WHERE firebase_uid = 'demo-user'", Long.class); }
  private long defaultAddressId() { return db.queryForObject("SELECT id FROM addresses WHERE user_id = ? AND is_default = TRUE LIMIT 1", Long.class, demoUserId()); }

  @GetMapping("/reminders")
  public List<Map<String, Object>> reminders() { return db.queryForList("SELECT id, medicine_name medicine, TIME_FORMAT(reminder_time, '%H:%i') time, frequency, completed FROM reminders WHERE user_id = ? ORDER BY reminder_time", demoUserId()); }

  @PostMapping("/reminders") @ResponseStatus(HttpStatus.CREATED)
  public Map<String, Object> addReminder(@Valid @RequestBody ReminderRequest r) {
    db.update("INSERT INTO reminders (user_id, medicine_name, reminder_time, frequency) VALUES (?, ?, ?, ?)", demoUserId(), r.medicine(), r.time(), r.frequency());
    return db.queryForMap("SELECT id, medicine_name medicine, TIME_FORMAT(reminder_time, '%H:%i') time, frequency, completed FROM reminders WHERE user_id = ? ORDER BY id DESC LIMIT 1", demoUserId());
  }

  @PutMapping("/reminders/{id}/complete")
  public Map<String, Object> complete(@PathVariable long id) {
    db.update("UPDATE reminders SET completed = TRUE WHERE id = ? AND user_id = ?", id, demoUserId());
    return db.queryForMap("SELECT id, medicine_name medicine, TIME_FORMAT(reminder_time, '%H:%i') time, frequency, completed FROM reminders WHERE id = ?", id);
  }

  @GetMapping("/orders")
  public List<Map<String, Object>> orders() { return db.queryForList("SELECT reference, status, payment_status paymentStatus, subtotal, delivery_fee deliveryFee, total, created_at createdAt FROM orders WHERE user_id = ? ORDER BY created_at DESC", demoUserId()); }

  @PostMapping("/orders") @ResponseStatus(HttpStatus.CREATED) @Transactional
  public Map<String, Object> createOrder(@Valid @RequestBody OrderRequest request) {
    double subtotal = 0;
    for (String item : Optional.ofNullable(request.items()).orElse(List.of())) {
      subtotal += db.queryForObject("SELECT price FROM medicines WHERE public_id = ? AND active = TRUE", Double.class, item);
    }
    String reference = "RR-" + System.currentTimeMillis();
    db.update("INSERT INTO orders (reference, user_id, address_id, subtotal, delivery_fee, total) VALUES (?, ?, ?, ?, 35.00, ?)", reference, demoUserId(), defaultAddressId(), subtotal, subtotal + 35);
    long orderId = db.queryForObject("SELECT id FROM orders WHERE reference = ?", Long.class, reference);
    for (String item : Optional.ofNullable(request.items()).orElse(List.of())) {
      db.update("INSERT INTO order_items (order_id, medicine_id, quantity, unit_price) SELECT ?, id, 1, price FROM medicines WHERE public_id = ?", orderId, item);
    }
    return db.queryForMap("SELECT reference, status, payment_status paymentStatus, subtotal, delivery_fee deliveryFee, total, created_at createdAt FROM orders WHERE id = ?", orderId);
  }

  @GetMapping("/prescriptions")
  public List<Map<String, Object>> prescriptions() { return db.queryForList("SELECT reference, file_path fileName, status, submitted_at submittedAt, pharmacist_note note FROM prescriptions WHERE user_id = ? ORDER BY submitted_at DESC", demoUserId()); }

  @PostMapping("/prescriptions") @ResponseStatus(HttpStatus.CREATED)
  public Map<String, Object> submit(@Valid @RequestBody PrescriptionRequest request) {
    String reference = "RX-" + System.currentTimeMillis();
    db.update("INSERT INTO prescriptions (reference, user_id, file_path) VALUES (?, ?, ?)", reference, demoUserId(), request.fileName());
    return db.queryForMap("SELECT reference, file_path fileName, status, submitted_at submittedAt, pharmacist_note note FROM prescriptions WHERE reference = ?", reference);
  }

  public record ReminderRequest(@NotBlank String medicine, @NotBlank String time, @NotBlank String frequency) {}
  public record OrderRequest(String address, List<String> items) {}
  public record PrescriptionRequest(@NotBlank String fileName) {}
}
