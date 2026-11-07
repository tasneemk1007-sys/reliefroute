package za.co.reliefroute.reliefroute_backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.storage.Bucket;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import com.google.firebase.cloud.StorageClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

@Configuration
public class FirebaseConfig {

    @Value("${reliefroute.firebase.service-account:}")
    private String credentialsFile;

    @Value("${reliefroute.firebase.storage-bucket}")
    private String storageBucket;

    @Value("${reliefroute.firebase.project-id:}")
    private String projectId;

    @Bean
    public FirebaseApp firebaseApp() throws IOException {
        if (!FirebaseApp.getApps().isEmpty()) {
            return FirebaseApp.getInstance();
        }
        FirebaseOptions.Builder options = FirebaseOptions.builder()
                .setCredentials(credentials());
        if (!projectId.isBlank()) {
            options.setProjectId(projectId);
        }
        if (storageBucket != null && !storageBucket.isBlank()) {
            options.setStorageBucket(storageBucket);
        }
        return FirebaseApp.initializeApp(options.build());
    }

    /**
     * Cloud Run supplies Application Default Credentials through its service
     * account. A local JSON key remains supported for local development only.
     */
    private GoogleCredentials credentials() throws IOException {
        if (credentialsFile != null && !credentialsFile.isBlank()) {
            Path path = Path.of(credentialsFile);
            if (Files.exists(path)) {
                try (InputStream key = Files.newInputStream(path)) {
                    return GoogleCredentials.fromStream(key);
                }
            }
            ClassPathResource resource = new ClassPathResource(credentialsFile);
            if (resource.exists()) {
                try (InputStream key = resource.getInputStream()) {
                    return GoogleCredentials.fromStream(key);
                }
            }
        }
        return GoogleCredentials.getApplicationDefault();
    }

    @Bean
    public Firestore firestore(FirebaseApp app) {
        return FirestoreClient.getFirestore(app);
    }

    @Bean
    @org.springframework.boot.autoconfigure.condition.ConditionalOnProperty(name = "reliefroute.firebase.storage-enabled", havingValue = "true")
    public Bucket storageBucket(FirebaseApp app) {
        return StorageClient.getInstance(app).bucket();
    }
}
