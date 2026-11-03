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
import za.co.reliefroute.reliefroute_backend.service.OrderService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderService orders;

    public OrderController(OrderService orders) {
        this.orders = orders;
    }

    // POST /api/orders/place
    // { "user_id":"user_001", "pharmacy_id":"pharmacy_001", "prescription_id":"",
    //   "address":"15 Example Street, Durban",
    //   "items":[ {"medication_id":"med_001","quantity":2} ] }
    @PostMapping("/place")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> place(@RequestBody Map<String, Object> body) throws Exception {
        return orders.place(body);
    }

    // GET /api/orders/{id}/tracking -> order + items + delivery + driver
    @GetMapping("/{id}/tracking")
    public Map<String, Object> tracking(@PathVariable String id) throws Exception {
        return orders.tracking(id);
    }

    // GET /api/orders/user/{userId} -> a customer's orders, newest first
    @GetMapping("/user/{userId}")
    public List<Map<String, Object>> forUser(@PathVariable String userId) throws Exception {
        return orders.ordersForUser(userId);
    }

    // PUT /api/orders/{id}/status   { "status": "Out for Delivery" }
    // Allowed: Pending, Confirmed, Out for Delivery, Delivered
    @PutMapping("/{id}/status")
    public Map<String, Object> status(@PathVariable String id, @RequestBody Map<String, Object> body) throws Exception {
        return orders.updateStatus(id, String.valueOf(body.getOrDefault("status", "")).trim());
    }

    // PUT /api/orders/{id}/assign-driver   { "driver_id": "driver_001" }
    @PutMapping("/{id}/assign-driver")
    public Map<String, Object> assignDriver(@PathVariable String id, @RequestBody Map<String, Object> body) throws Exception {
        return orders.assignDriver(id, String.valueOf(body.getOrDefault("driver_id", "")).trim());
    }
}
