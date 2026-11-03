package za.co.reliefroute.reliefroute_backend.service;

import com.google.cloud.storage.Blob;
import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.Storage;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Service
public class ImageService {

    // Folder in Firebase Storage that holds the medicine pictures.
    private static final String FOLDER = "Medicines pic/";

    private static final String[] IMAGE_FIELDS = {"imagePath", "image", "imageUrl", "image_url", "imageName"};
    private static final String[] NAME_FIELDS = {"name", "medicationName", "medication_name", "medName", "title"};

    private final Bucket bucket;

    public ImageService(Bucket bucket) {
        this.bucket = bucket;
    }

    // Every picture in the folder, with a temporary download link (valid 7 days).
    public List<Map<String, String>> listAll() {
        List<Map<String, String>> out = new ArrayList<>();
        for (Map.Entry<String, Blob> e : blobsByStem().entrySet()) {
            Map<String, String> item = new LinkedHashMap<>();
            item.put("name", e.getValue().getName());
            item.put("url", sign(e.getValue()));
            out.add(item);
        }
        return out;
    }

    // File names (e.g. "allergex-4.png") of every picture in the folder.
    public List<String> fileNames() {
        List<String> out = new ArrayList<>();
        for (Blob b : bucket.list(Storage.BlobListOption.prefix(FOLDER)).iterateAll()) {
            if (!b.getName().endsWith("/")) {
                out.add(b.getName().substring(FOLDER.length()));
            }
        }
        return out;
    }

    // Adds an "imageUrl" to each medication by matching it to a picture in Storage.
    public void addImageUrls(List<Map<String, Object>> medications) {
        Map<String, Blob> blobs = blobsByStem();
        for (Map<String, Object> med : medications) {
            addImageUrl(med, blobs);
        }
    }

    public void addImageUrl(Map<String, Object> med) {
        addImageUrl(med, blobsByStem());
    }

    private void addImageUrl(Map<String, Object> med, Map<String, Blob> blobs) {
        // 1. Already has a real web link? Leave it.
        for (String key : IMAGE_FIELDS) {
            Object v = med.get(key);
            if (v instanceof String s && s.startsWith("http")) {
                med.put("imageUrl", s);
                return;
            }
        }
        // 2. A file name / path saved in the document.
        for (String key : IMAGE_FIELDS) {
            Object v = med.get(key);
            if (v instanceof String s && !s.isBlank()) {
                Blob b = findBlob(blobs, stemOf(s.replace(FOLDER, "")));
                if (b != null) {
                    med.put("imageUrl", sign(b));
                    return;
                }
            }
        }
        // 3. Match by medicine name, e.g. "Allergex 4" -> "allergex-4.png".
        for (String key : NAME_FIELDS) {
            Object v = med.get(key);
            if (v instanceof String s && !s.isBlank()) {
                Blob b = findBlob(blobs, slug(s));
                if (b != null) {
                    med.put("imageUrl", sign(b));
                    return;
                }
            }
        }
        med.put("imageUrl", null);
    }

    private Blob findBlob(Map<String, Blob> blobs, String slug) {
        if (slug.isEmpty()) {
            return null;
        }
        Blob exact = blobs.get(slug);
        if (exact != null) {
            return exact;
        }
        // Looser match: "allergex-4mg" vs "allergex-4" (longest matching file name wins).
        Blob best = null;
        int bestLen = 0;
        for (Map.Entry<String, Blob> e : blobs.entrySet()) {
            String stem = e.getKey();
            if (stem.length() >= 4 && (slug.startsWith(stem) || stem.startsWith(slug))
                    && stem.length() > bestLen) {
                best = e.getValue();
                bestLen = stem.length();
            }
        }
        return best;
    }

    private Map<String, Blob> blobsByStem() {
        Map<String, Blob> out = new LinkedHashMap<>();
        for (Blob b : bucket.list(Storage.BlobListOption.prefix(FOLDER)).iterateAll()) {
            if (b.getName().endsWith("/")) {
                continue;
            }
            out.put(stemOf(b.getName().substring(FOLDER.length())), b);
        }
        return out;
    }

    private String stemOf(String file) {
        int dot = file.lastIndexOf('.');
        String stem = dot > 0 ? file.substring(0, dot) : file;
        return slug(stem);
    }

    private String slug(String s) {
        return s.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", "-").replaceAll("^-+|-+$", "");
    }

    private String sign(Blob blob) {
        return blob.signUrl(7, TimeUnit.DAYS, Storage.SignUrlOption.withV4Signature()).toString();
    }
}
