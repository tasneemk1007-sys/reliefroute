package za.co.reliefroute.reliefroute_backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.storage.Bucket;
import com.google.firebase.FirebaseApp;

@SpringBootTest
class ReliefrouteBackendApplicationTests {

	@MockitoBean
	FirebaseApp firebaseApp;

	@MockitoBean
	Firestore firestore;

	@MockitoBean
	Bucket storageBucket;

	@Test
	void contextLoads() {
	}

}
