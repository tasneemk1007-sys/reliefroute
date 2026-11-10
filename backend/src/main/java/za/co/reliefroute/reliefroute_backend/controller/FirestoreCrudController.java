package za.co.reliefroute.reliefroute_backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import jakarta.servlet.http.HttpServletRequest;
import za.co.reliefroute.reliefroute_backend.service.FirestoreService;
import za.co.reliefroute.reliefroute_backend.service.ImageService;
import za.co.reliefroute.reliefroute_backend.service.MedicineJdbcService;

import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * One set of endpoints for every collection:
 *   GET    /api/{collection}          list all
 *   GET    /api/{collection}/{id}     get one
 *   POST   /api/{collection}          create (JSON body)
 *   PUT    /api/{collection}/{id}     update the fields you send
 *   DELETE /api/{collection}/{id}     delete
 * Collections: medications, pharmacies, users, orders, order_items,
 *              prescriptions, deliveries, drivers, refill_reminders
 */
@RestController
@RequestMapping("/api")
public class FirestoreCrudController {

    private static final Set<String> GENERIC_ADMIN_COLLECTIONS = Set.of("medications");

    private final FirestoreService db;
    private final ImageService images;
    private final MedicineJdbcService medicines;

    public FirestoreCrudController(FirestoreService db, ImageService images, MedicineJdbcService medicines) {
        this.db = db;
        this.images = images;
        this.medicines = medicines;
    }

    @GetMapping("/{collection}")
    public List<Map<String, Object>> list(@PathVariable String collection,
                                          @org.springframework.web.bind.annotation.RequestParam(defaultValue = "") String q,
                                          HttpServletRequest request) throws Exception {
        checkRead(collection, request);
        if (collection.equals("medications")) {
            return medicines.list(q);
        }
        List<Map<String, Object>> items = db.list(collection);
        if (collection.equals("medications")) {
            images.addImageUrls(items);
        }
        return items;
    }

    @GetMapping("/{collection}/{id}")
    public Map<String, Object> get(@PathVariable String collection, @PathVariable String id,
                                   HttpServletRequest request) throws Exception {
        checkRead(collection, request);
        if (collection.equals("medications")) {
            try {
                return medicines.get(id);
            } catch (org.springframework.dao.EmptyResultDataAccessException e) {
                throw notFound(collection + "/" + id + " not found");
            }
        }
        Map<String, Object> item = db.get(collection, id);
        if (item == null) {
            throw notFound(collection + "/" + id + " not found");
        }
        if (collection.equals("medications")) {
            images.addImageUrl(item);
        }
        return item;
    }

    @PostMapping("/{collection}")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@PathVariable String collection,
                                      @RequestBody Map<String, Object> body,
                                      HttpServletRequest request) throws Exception {
        requireAdmin(collection, request);
        return db.create(collection, body);
    }

    @PutMapping("/{collection}/{id}")
    public Map<String, Object> update(@PathVariable String collection, @PathVariable String id,
                                      @RequestBody Map<String, Object> body,
                                      HttpServletRequest request) throws Exception {
        requireAdmin(collection, request);
        if (!db.update(collection, id, body)) {
            throw notFound(collection + "/" + id + " not found");
        }
        return get(collection, id, request);
    }

    @DeleteMapping("/{collection}/{id}")
    public Map<String, Object> delete(@PathVariable String collection, @PathVariable String id) throws Exception {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Generic collection deletes are disabled");
    }

    private void requireAdmin(String collection, HttpServletRequest request) {
        if (!GENERIC_ADMIN_COLLECTIONS.contains(collection)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Collection is not available through this API");
        }
        if (!isAdmin(request)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Administrator role required");
        }
    }

    private boolean isAdmin(HttpServletRequest request) {
        Object claims = request.getAttribute("firebaseClaims");
        return claims instanceof Map<?, ?> map && "admin".equals(String.valueOf(map.get("role")));
    }

    private void checkRead(String collection, HttpServletRequest request) {
        if (!collection.equals("medications") || !db.isAllowed(collection)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Collection is not available through this API");
        }
        if (request.getAttribute("firebaseUid") == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authenticated user required");
        }
    }

    private void check(String collection) {
        if (!db.isAllowed(collection)) {
            throw notFound("Unknown collection: " + collection);
        }
    }

    private ResponseStatusException notFound(String msg) {
        return new ResponseStatusException(HttpStatus.NOT_FOUND, msg);
    }
}
