package za.co.reliefroute.firebase;

import com.google.cloud.storage.Blob;
import com.google.firebase.cloud.StorageClient;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

@RestController @RequestMapping("/api/storage")
public class StorageController {
  @GetMapping("/file")
  public ResponseEntity<byte[]> file(@RequestParam String path) {
    var decoded = URLDecoder.decode(path, StandardCharsets.UTF_8);
    if (!(decoded.startsWith("Medicines pic/") || decoded.startsWith("prescriptions/"))) {
      return ResponseEntity.badRequest().build();
    }
    Blob blob = StorageClient.getInstance().bucket().get(decoded);
    if (blob == null) return ResponseEntity.notFound().build();
    var type = blob.getContentType() == null ? MediaType.APPLICATION_OCTET_STREAM_VALUE : blob.getContentType();
    return ResponseEntity.ok().contentType(MediaType.parseMediaType(type)).body(blob.getContent());
  }
}
