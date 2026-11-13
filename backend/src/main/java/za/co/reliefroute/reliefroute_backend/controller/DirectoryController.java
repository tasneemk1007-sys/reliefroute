package za.co.reliefroute.reliefroute_backend.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import za.co.reliefroute.reliefroute_backend.service.DirectoryJdbcService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/directory")
public class DirectoryController {
    private final DirectoryJdbcService directory;

    public DirectoryController(DirectoryJdbcService directory) {
        this.directory = directory;
    }

    @GetMapping("/doctors")
    public List<Map<String, Object>> doctors(HttpServletRequest request) {
        requirePatient(request);
        return directory.doctors();
    }

    @GetMapping("/pharmacies")
    public List<Map<String, Object>> pharmacies(HttpServletRequest request) {
        requirePatient(request);
        return directory.pharmacies();
    }

    private void requirePatient(HttpServletRequest request) {
        if (request.getAttribute("firebaseUid") == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authenticated user required");
        }
    }
}
