package za.co.reliefroute.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

@Configuration
public class FirebaseConfig {
  @Value("${reliefroute.firebase.project-id}") String projectId;
  @Value("${reliefroute.firebase.storage-bucket}") String storageBucket;
  @Value("${reliefroute.firebase.service-account}") String serviceAccount;

  @Bean
  public FirebaseApp firebaseApp() throws Exception {
    if (!FirebaseApp.getApps().isEmpty()) return FirebaseApp.getInstance();
    InputStream key = Files.newInputStream(Path.of("src/main/resources", serviceAccount));
    var options = FirebaseOptions.builder().setCredentials(GoogleCredentials.fromStream(key))
      .setProjectId(projectId).setStorageBucket(storageBucket).build();
    return FirebaseApp.initializeApp(options);
  }

  @Bean public Firestore firestore(FirebaseApp app) { return FirestoreClient.getFirestore(app); }
}
