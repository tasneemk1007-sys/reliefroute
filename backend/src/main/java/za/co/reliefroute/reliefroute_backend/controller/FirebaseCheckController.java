package za.co.reliefroute.reliefroute_backend.controller;

import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.storage.Blob;
import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.Storage;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
public class FirebaseCheckController {

    private final Firestore firestore;
    private final Bucket bucket;

    public FirebaseCheckController(Firestore firestore, Bucket bucket) {
        this.firestore = firestore;
        this.bucket = bucket;
    }

    // Open http://localhost:8080/api/firebase-check
    // Shows your Firestore collections and the first few files in Storage.
    @GetMapping("/api/firebase-check")
    public Map<String, Object> check() {
        List<String> collections = new ArrayList<>();
        for (CollectionReference c : firestore.listCollections()) {
            collections.add(c.getId());
        }
        List<String> files = new ArrayList<>();
        for (Blob b : bucket.list(Storage.BlobListOption.pageSize(10)).getValues()) {
            files.add(b.getName());
        }
        return Map.of("connected", true, "collections", collections,
                "bucket", bucket.getName(), "storageFiles", files);
    }
}
