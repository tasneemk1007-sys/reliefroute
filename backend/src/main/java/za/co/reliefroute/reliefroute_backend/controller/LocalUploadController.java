package za.co.reliefroute.reliefroute_backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import za.co.reliefroute.reliefroute_backend.service.FirestoreService;
import java.nio.file.*;
import java.util.Map;
import java.util.UUID;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.springframework.beans.factory.annotation.Value;

@RestController
@RequestMapping("/api/uploads")
public class LocalUploadController {
    private final FirestoreService db;
    @Value("${supabase.url}") private String supabaseUrl;
    @Value("${supabase.bucket}") private String bucket;
    @Value("${supabase.secret-key:}") private String secretKey;
    public LocalUploadController(FirestoreService db) { this.db = db; }
    @PostMapping("/prescription") @ResponseStatus(HttpStatus.CREATED)
    public Map<String,Object> upload(@RequestParam("file") MultipartFile file, @RequestParam String userId) throws Exception {
        if (file.isEmpty()) throw new IllegalArgumentException("File is empty");
        String safe = UUID.randomUUID() + "-" + Path.of(file.getOriginalFilename() == null ? "prescription" : file.getOriginalFilename()).getFileName();
        if (secretKey.isBlank()) throw new IllegalStateException("SUPABASE_SECRET_KEY is not configured");
        String objectPath = "prescriptions/" + safe;
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(supabaseUrl + "/storage/v1/object/" + bucket + "/" + objectPath))
                .header("Authorization", "Bearer " + secretKey)
                .header("apikey", secretKey)
                .header("Content-Type", file.getContentType() == null ? "application/octet-stream" : file.getContentType())
                .header("x-upsert", "false")
                .PUT(HttpRequest.BodyPublishers.ofByteArray(file.getBytes())).build();
        HttpResponse<String> response = HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) throw new IllegalStateException("Supabase upload failed: " + response.body());
        return db.create("prescriptions", Map.of("user_id", userId, "file_name", safe, "storage_path", objectPath, "status", "Pending", "storage", "supabase"));
    }
}
