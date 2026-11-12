package za.co.reliefroute.reliefroute_backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.storage.Bucket;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import com.google.firebase.cloud.StorageClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

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
            FirebaseApp existing = FirebaseApp.getInstance();
            verifyProject(existing.getOptions().getProjectId());
            return existing;
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
            if (!Files.isRegularFile(path)) {
                throw new IOException("FIREBASE_SERVICE_ACCOUNT must point to a readable JSON file outside the repository");
            }
            try (InputStream key = Files.newInputStream(path)) {
                GoogleCredentials credentials = GoogleCredentials.fromStream(key);
                verifyCredentialsProject(credentials);
                return credentials;
            }
        }
        GoogleCredentials credentials = GoogleCredentials.getApplicationDefault();
        verifyCredentialsProject(credentials);
        return credentials;
    }

    private void verifyCredentialsProject(GoogleCredentials credentials) throws IOException {
        if (credentials instanceof ServiceAccountCredentials serviceAccount) {
            verifyProject(serviceAccount.getProjectId());
        }
    }

    private void verifyProject(String credentialProjectId) throws IOException {
        if (projectId == null || projectId.isBlank()) {
            throw new IOException("FIREBASE_PROJECT_ID must be set to reliefroute4");
        }
        if (credentialProjectId == null || credentialProjectId.isBlank()) {
            throw new IOException("Firebase service-account credentials do not specify a project_id");
        }
        if (!projectId.equals(credentialProjectId)) {
            throw new IOException("Firebase credentials belong to project " + credentialProjectId
                    + "; expected " + projectId);
        }
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
