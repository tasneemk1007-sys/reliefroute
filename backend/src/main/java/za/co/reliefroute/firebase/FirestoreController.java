package za.co.reliefroute.firebase;

import com.google.cloud.firestore.Firestore;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.util.*;
import java.util.concurrent.ExecutionException;

@RestController @RequestMapping("/api")
public class FirestoreController {
  private static final Set<String> COLLECTIONS = Set.of("medications", "pharmacies", "users", "drivers", "orders", "order_items", "deliveries", "prescriptions", "refill_reminders");
  private final Firestore firestore;
  public FirestoreController(Firestore firestore) { this.firestore = firestore; }

  private void check(String collection) { if (!COLLECTIONS.contains(collection)) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Collection not available"); }
  private Map<String, Object> withId(String id, Map<String, Object> data) { var result = new HashMap<>(data); result.put("id", id); return result; }

  @GetMapping("/{collection}")
  public List<Map<String, Object>> list(@PathVariable String collection) throws Exception {
    check(collection); var snapshots = firestore.collection(collection).get().get().getDocuments();
    return snapshots.stream().map(s -> withId(s.getId(), s.getData())).toList();
  }

  @PostMapping("/{collection}") @ResponseStatus(HttpStatus.CREATED)
  public Map<String, Object> create(@PathVariable String collection, @RequestBody Map<String, Object> data) throws Exception {
    check(collection); var ref = firestore.collection(collection).document(); ref.set(data).get(); return withId(ref.getId(), data);
  }

  @GetMapping("/{collection}/{id}")
  public Map<String, Object> get(@PathVariable String collection, @PathVariable String id) throws Exception {
    check(collection); var snapshot = firestore.collection(collection).document(id).get().get();
    if (!snapshot.exists()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Document not found");
    return withId(id, snapshot.getData());
  }

  @PutMapping("/{collection}/{id}")
  public Map<String, Object> update(@PathVariable String collection, @PathVariable String id, @RequestBody Map<String, Object> data) throws Exception {
    check(collection); firestore.collection(collection).document(id).set(data).get(); return withId(id, data);
  }

  @DeleteMapping("/{collection}/{id}") @ResponseStatus(HttpStatus.NO_CONTENT)
  public void delete(@PathVariable String collection, @PathVariable String id) throws Exception {
    check(collection); firestore.collection(collection).document(id).delete().get();
  }

  @GetMapping("/firebase-check")
  public Map<String, Object> check() throws Exception {
    firestore.listCollections(); return Map.of("status", "connected", "database", "firestore");
  }
}
