package za.co.reliefroute.reliefroute_backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import jakarta.servlet.http.HttpServletRequest;
import za.co.reliefroute.reliefroute_backend.service.OrderJdbcService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderJdbcService orders;

    public OrderController(OrderJdbcService orders) {
        this.orders = orders;
    }

    // POST /api/orders/place
    // { "user_id":"user_001", "pharmacy_id":"pharmacy_001", "prescription_id":"",
    //   "address":"15 Example Street, Durban",
    //   "items":[ {"medication_id":"med_001","quantity":2} ] }
    @PostMapping("/place")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> place(@RequestBody Map<String, Object> body,
                                     HttpServletRequest request) throws Exception {
        return orders.place(ownedBody(body, request));
    }

    @PostMapping("/quote")
    public Map<String, Object> quote(@RequestBody Map<String, Object> body,
                                    HttpServletRequest request) {
        return orders.quote(ownedBody(body, request));
    }

    // GET /api/orders/{id}/tracking -> order + items + delivery + driver
    @GetMapping("/{id}/tracking")
    public Map<String, Object> tracking(@PathVariable String id, HttpServletRequest request) throws Exception {
        return orders.tracking(id, authenticatedUid(request));
    }

    // GET /api/orders/user/{userId} -> a customer's orders, newest first
    @GetMapping("/user/{userId}")
    public List<Map<String, Object>> forUser(@PathVariable String userId, HttpServletRequest request) throws Exception {
        String uid = authenticatedUid(request);
        if (!uid.equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.NOT_FOUND, "Orders not found");
        }
        return orders.forUser(uid);
    }

    // PUT /api/orders/{id}/status   { "status": "Out for Delivery" }
    // Allowed: Pending, Confirmed, Out for Delivery, Delivered
    @PutMapping("/{id}/status")
    public Map<String, Object> status(@PathVariable String id, @RequestBody Map<String, Object> body) throws Exception {
        throw new org.springframework.web.server.ResponseStatusException(HttpStatus.NOT_IMPLEMENTED, "Order status updates are being migrated to MySQL");
    }

    // PUT /api/orders/{id}/assign-driver   { "driver_id": "driver_001" }
    @PutMapping("/{id}/assign-driver")
    public Map<String, Object> assignDriver(@PathVariable String id,
                                            @RequestBody Map<String, Object> body,
                                            HttpServletRequest request) {
        Object rawClaims = request.getAttribute("firebaseClaims");
        if (!(rawClaims instanceof Map<?, ?> claims)
                || !"admin".equals(String.valueOf(claims.get("role")))) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.FORBIDDEN, "Administrator role required");
        }
        String driverUid = String.valueOf(body.getOrDefault("driver_id", "")).trim();
        if (driverUid.isEmpty()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "driver_id is required");
        }
        return orders.assignDriver(id, driverUid);
    }

    private Map<String, Object> ownedBody(Map<String, Object> body,
                                          HttpServletRequest request) {
        String uid = authenticatedUid(request);
        Map<String, Object> ownedBody = new java.util.LinkedHashMap<>(body);
        ownedBody.put("user_id", uid);
        Object rawClaims = request.getAttribute("firebaseClaims");
        if (rawClaims instanceof Map<?, ?> claims) {
            ownedBody.put("user_email", claims.get("email") == null ? "" : claims.get("email"));
            ownedBody.put("user_name", claims.get("name") == null ? "" : claims.get("name"));
        }
        return ownedBody;
    }

    private String authenticatedUid(HttpServletRequest request) {
        Object uid = request.getAttribute("firebaseUid");
        if (uid == null || String.valueOf(uid).isBlank()) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authenticated user required");
        }
        return String.valueOf(uid);
    }
}
