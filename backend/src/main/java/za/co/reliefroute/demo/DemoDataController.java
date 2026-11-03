package za.co.reliefroute.demo;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;

/** Temporary demo endpoints used until the authenticated repositories are connected. */
@RestController @RequestMapping("/api")
public class DemoDataController {
  private final AtomicLong ids = new AtomicLong(1);
  private final List<Reminder> reminders = new CopyOnWriteArrayList<>();
  private final List<Order> orders = new CopyOnWriteArrayList<>();
  private final List<Prescription> prescriptions = new CopyOnWriteArrayList<>();

  @GetMapping("/reminders") public List<Reminder> reminders() { return reminders; }
  @PostMapping("/reminders") @ResponseStatus(HttpStatus.CREATED)
  public Reminder addReminder(@Valid @RequestBody ReminderRequest request) {
    var item = new Reminder(ids.getAndIncrement(), request.medicine(), request.time(), request.frequency(), false);
    reminders.add(item); return item;
  }
  @PutMapping("/reminders/{id}/complete")
  public Reminder complete(@PathVariable long id) {
    return reminders.stream().filter(r -> r.id() == id).findFirst()
      .map(r -> { var updated = new Reminder(r.id(), r.medicine(), r.time(), r.frequency(), true); reminders.set(reminders.indexOf(r), updated); return updated; })
      .orElseThrow(() -> new NoSuchElementException("Reminder not found"));
  }

  @GetMapping("/orders") public List<Order> orders() { return orders; }
  @PostMapping("/orders") @ResponseStatus(HttpStatus.CREATED)
  public Order createOrder(@Valid @RequestBody OrderRequest request) {
    var order = new Order("RR-" + String.format("%05d", ids.getAndIncrement()), request.address(), request.items(), "placed", Instant.now());
    orders.add(0, order); return order;
  }

  @GetMapping("/prescriptions") public List<Prescription> prescriptions() { return prescriptions; }
  @PostMapping("/prescriptions") @ResponseStatus(HttpStatus.CREATED)
  public Prescription submitPrescription(@Valid @RequestBody PrescriptionRequest request) {
    var item = new Prescription("RX-" + String.format("%04d", ids.getAndIncrement()), request.fileName(), "pending", Instant.now());
    prescriptions.add(0, item); return item;
  }

  public record Reminder(long id, String medicine, String time, String frequency, boolean completed) {}
  public record ReminderRequest(@NotBlank String medicine, @NotBlank String time, @NotBlank String frequency) {}
  public record Order(String reference, String address, List<String> items, String status, Instant createdAt) {}
  public record OrderRequest(@NotBlank String address, List<String> items) {}
  public record Prescription(String reference, String fileName, String status, Instant submittedAt) {}
  public record PrescriptionRequest(@NotBlank String fileName) {}
}
