package za.co.reliefroute.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.List;

@Configuration
public class SecurityConfig {
  @Value("${reliefroute.auth.required:false}") boolean authRequired;
  @Bean SecurityFilterChain security(HttpSecurity http) throws Exception {
    return http.csrf(c -> c.disable()).cors(c -> {}).sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
      .authorizeHttpRequests(a -> { a.requestMatchers("/actuator/health", "/api/health", "/error").permitAll();
        a.requestMatchers(HttpMethod.GET, "/api/medicines/**").permitAll();
        if (authRequired) a.anyRequest().authenticated(); else a.anyRequest().permitAll(); }).build();
  }
  @Bean CorsConfigurationSource cors() {
    var c = new CorsConfiguration(); c.setAllowedOrigins(List.of("http://localhost:5000", "http://localhost:3000"));
    c.setAllowedMethods(List.of("GET","POST","PUT","DELETE","OPTIONS")); c.setAllowedHeaders(List.of("*"));
    var source = new UrlBasedCorsConfigurationSource(); source.registerCorsConfiguration("/**", c); return source;
  }
}
