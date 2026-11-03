package za.co.reliefroute.reliefroute_backend.controller;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import za.co.reliefroute.reliefroute_backend.service.SeedService;
import za.co.reliefroute.reliefroute_backend.service.SymptomService;

import java.util.Map;

// Development helpers - remove (or protect) before going live.
@RestController
public class AdminController {

    private final SeedService seed;
    private final SymptomService symptoms;

    public AdminController(SeedService seed, SymptomService symptoms) {
        this.seed = seed;
        this.symptoms = symptoms;
    }

    // POST /api/admin/seed-medications
    @PostMapping("/api/admin/seed-medications")
    public Map<String, Object> seedMedications() throws Exception {
        return seed.seedMedications();
    }

    // POST /api/admin/tag-symptoms            (skips medicines that already have symptoms)
    // POST /api/admin/tag-symptoms?overwrite=true
    @PostMapping("/api/admin/tag-symptoms")
    public Map<String, Object> tagSymptoms(@RequestParam(defaultValue = "false") boolean overwrite) throws Exception {
        return symptoms.tagMedications(overwrite);
    }
}
