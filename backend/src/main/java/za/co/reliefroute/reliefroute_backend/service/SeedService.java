package za.co.reliefroute.reliefroute_backend.service;

import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

@Service
public class SeedService {

    private final Firestore firestore;
    private final ImageService images;

    public SeedService(Firestore firestore, ImageService images) {
        this.firestore = firestore;
        this.images = images;
    }

    /**
     * 1. Copies anything in the old " medications" collection (leading space) into "medications".
     * 2. Creates one medication per picture in "Medicines pic/" (skips ones that already exist).
     * Safe to run more than once.
     */
    public Map<String, Object> seedMedications() throws Exception {
        CollectionReference target = firestore.collection("medications");
        int migrated = 0;
        int created = 0;
        int skipped = 0;

        for (QueryDocumentSnapshot d : firestore.collection(" medications").get().get().getDocuments()) {
            DocumentReference dest = target.document(d.getId());
            if (!dest.get().get().exists()) {
                dest.set(d.getData()).get();
                migrated++;
            }
        }

        for (String file : images.fileNames()) {
            int dot = file.lastIndexOf('.');
            String stem = dot > 0 ? file.substring(0, dot) : file;
            String id = "med_" + stem.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", "_").replaceAll("^_+|_+$", "");
            DocumentReference ref = target.document(id);
            if (ref.get().get().exists()) {
                skipped++;
                continue;
            }
            Map<String, Object> data = new LinkedHashMap<>();
            data.put("name", titleCase(stem));
            data.put("description", "");
            data.put("prices", 0.0);
            data.put("stock_qty", 50.0);
            data.put("prescription_required", false);
            data.put("pharmacy_id", "pharmacy_001");
            data.put("imagePath", file);
            ref.set(data).get();
            created++;
        }

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("migratedFromOldCollection", migrated);
        out.put("created", created);
        out.put("alreadyExisted", skipped);
        out.put("note", "Prices are 0 - set real prices with PUT /api/medications/{id} before placing orders.");
        return out;
    }

    // "allergex-4" -> "Allergex 4"
    private String titleCase(String stem) {
        StringBuilder sb = new StringBuilder();
        for (String part : stem.split("[-_\\s]+")) {
            if (part.isEmpty()) {
                continue;
            }
            if (sb.length() > 0) {
                sb.append(' ');
            }
            sb.append(Character.toUpperCase(part.charAt(0))).append(part.substring(1));
        }
        return sb.toString();
    }
}
