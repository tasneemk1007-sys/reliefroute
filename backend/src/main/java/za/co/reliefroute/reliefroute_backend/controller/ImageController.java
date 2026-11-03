package za.co.reliefroute.reliefroute_backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import za.co.reliefroute.reliefroute_backend.service.ImageService;

import java.util.List;
import java.util.Map;

@RestController
public class ImageController {

    private final ImageService images;

    public ImageController(ImageService images) {
        this.images = images;
    }

    // GET /api/images -> every picture in "Medicines pic/" with a temporary link
    @GetMapping("/api/images")
    public List<Map<String, String>> list() {
        return images.listAll();
    }
}
