package za.co.reliefroute.reliefroute_backend.controller;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import za.co.reliefroute.reliefroute_backend.service.AuthService;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthService auth;
    public AuthController(AuthService auth) { this.auth = auth; }
    @PostMapping("/register") @ResponseStatus(HttpStatus.CREATED)
    public Map<String,Object> register(@RequestBody Map<String,Object> body) throws Exception {
        return auth.register(String.valueOf(body.getOrDefault("email", "")), String.valueOf(body.getOrDefault("password", "")), String.valueOf(body.getOrDefault("name", "")));
    }
    @PostMapping("/login")
    public Map<String,Object> login(@RequestBody Map<String,Object> body) throws Exception {
        return auth.login(String.valueOf(body.getOrDefault("email", "")), String.valueOf(body.getOrDefault("password", "")));
    }
}
