package za.co.reliefroute.reliefroute_backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import za.co.reliefroute.reliefroute_backend.service.SymptomService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/symptoms")
public class SymptomController {

    private final SymptomService symptoms;

    public SymptomController(SymptomService symptoms) {
        this.symptoms = symptoms;
    }

    // GET /api/symptoms -> list of symptoms the app understands (for a picker)
    @GetMapping
    public List<String> list() {
        return symptoms.allSymptoms();
    }

    // GET /api/symptoms/search?text=I have a headache and a blocked nose
    @GetMapping("/search")
    public Map<String, Object> search(@RequestParam String text) throws Exception {
        return symptoms.search(text);
    }
}
