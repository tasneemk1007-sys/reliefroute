package za.co.reliefroute.reliefroute_backend.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import za.co.reliefroute.reliefroute_backend.service.CareJdbcService;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/care")
public class CareController {
    private final CareJdbcService care;
    public CareController(CareJdbcService care) { this.care = care; }
    @GetMapping("/reminders") public List<Map<String,Object>> reminders(HttpServletRequest r) { return care.reminders(uid(r)); }
    @PostMapping("/reminders") @ResponseStatus(HttpStatus.CREATED) public Map<String,Object> addReminder(HttpServletRequest r, @RequestBody Map<String,Object> b) { return care.addReminder(uid(r), b); }
    @GetMapping("/prescriptions") public List<Map<String,Object>> prescriptions(HttpServletRequest r) { return care.prescriptions(uid(r)); }
    @PostMapping("/prescriptions") @ResponseStatus(HttpStatus.CREATED) public Map<String,Object> addPrescription(HttpServletRequest r, @RequestBody Map<String,Object> b) { return care.addPrescription(uid(r), b); }
    @GetMapping("/addresses") public List<Map<String,Object>> addresses(HttpServletRequest r) { return care.addresses(uid(r)); }
    @PostMapping("/addresses") @ResponseStatus(HttpStatus.CREATED) public Map<String,Object> addAddress(HttpServletRequest r, @RequestBody Map<String,Object> b) { return care.addAddress(uid(r), b); }
    private String uid(HttpServletRequest r) { return String.valueOf(r.getAttribute("firebaseUid")); }
}
