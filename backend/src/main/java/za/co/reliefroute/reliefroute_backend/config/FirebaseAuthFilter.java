package za.co.reliefroute.reliefroute_backend.config;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;

/** Verifies Firebase ID tokens before protected API requests reach controllers. */
public class FirebaseAuthFilter extends OncePerRequestFilter {
    private final boolean required;

    public FirebaseAuthFilter(boolean required) {
        this.required = required;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return !required || request.getMethod().equalsIgnoreCase("OPTIONS")
                || path.equals("/actuator/health")
                || path.equals("/api/auth/login")
                || path.equals("/api/auth/register");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Bearer token required");
            return;
        }
        try {
            FirebaseToken token = FirebaseAuth.getInstance().verifyIdToken(header.substring(7));
            request.setAttribute("firebaseUid", token.getUid());
            request.setAttribute("firebaseClaims", token.getClaims());
            Map<String, Object> claims = token.getClaims();
            String role = String.valueOf(claims.getOrDefault("role", "customer"));
            String path = request.getRequestURI();
            if (path.startsWith("/api/admin") && !role.equals("admin")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Administrator role required");
                return;
            }
            if (path.matches("/api/orders/user/[^/]+") && !path.endsWith("/" + token.getUid())) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You may only access your own orders");
                return;
            }
            chain.doFilter(request, response);
        } catch (Exception e) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid or expired Firebase token");
        }
    }
}
