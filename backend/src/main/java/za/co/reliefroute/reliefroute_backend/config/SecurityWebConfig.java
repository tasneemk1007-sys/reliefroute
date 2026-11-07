package za.co.reliefroute.reliefroute_backend.config;

import jakarta.servlet.Filter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SecurityWebConfig {
    @Bean
    FilterRegistrationBean<Filter> firebaseAuthFilter(
            @Value("${reliefroute.auth.required:false}") boolean required) {
        FilterRegistrationBean<Filter> registration = new FilterRegistrationBean<>();
        registration.setFilter(new FirebaseAuthFilter(required));
        registration.addUrlPatterns("/api/*");
        registration.setOrder(1);
        return registration;
    }
}
