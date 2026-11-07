package za.co.reliefroute.reliefroute_backend.service;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.List;
import java.util.Map;

@Service
public class AuthService {
    private final FirestoreService db;
    private final SecureRandom random = new SecureRandom();

    public AuthService(FirestoreService db) { this.db = db; }

    public Map<String, Object> register(String email, String password, String name) throws Exception {
        email = email.trim().toLowerCase();
        if (email.isBlank() || password.length() < 8) throw bad("Email and password of at least 8 characters are required");
        for (Map<String, Object> user : db.list("users")) {
            if (email.equals(String.valueOf(user.get("email")))) throw bad("An account with this email already exists");
        }
        byte[] salt = new byte[16]; random.nextBytes(salt);
        Map<String, Object> user = db.create("users", Map.of(
                "email", email, "name", name.trim(), "password_hash", hash(password, salt),
                "password_salt", Base64.getEncoder().encodeToString(salt), "role", "patient"));
        user.remove("password_hash"); user.remove("password_salt");
        return user;
    }

    public Map<String, Object> login(String email, String password) throws Exception {
        email = email.trim().toLowerCase();
        List<Map<String, Object>> users = db.list("users");
        for (Map<String, Object> user : users) {
            if (email.equals(String.valueOf(user.get("email")))) {
                byte[] salt = Base64.getDecoder().decode(String.valueOf(user.get("password_salt")));
                if (!hash(password, salt).equals(user.get("password_hash"))) throw unauthorized();
                user.remove("password_hash"); user.remove("password_salt"); return user;
            }
        }
        throw unauthorized();
    }

    private String hash(String password, byte[] salt) throws Exception {
        PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 120000, 256);
        return Base64.getEncoder().encodeToString(SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).getEncoded());
    }
    private ResponseStatusException bad(String m) { return new ResponseStatusException(HttpStatus.BAD_REQUEST, m); }
    private ResponseStatusException unauthorized() { return new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid email or password"); }
}
