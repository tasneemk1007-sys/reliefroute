package za.co.reliefroute.reliefroute_backend.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class DirectoryJdbcService {
    private final JdbcTemplate jdbc;

    public DirectoryJdbcService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> doctors() {
        return jdbc.queryForList("""
                SELECT id,display_name AS name,specialty,practice_name,phone,email,address,
                       verification_status,demo_record
                FROM doctors ORDER BY display_name
                """);
    }

    public List<Map<String, Object>> pharmacies() {
        return jdbc.queryForList("""
                SELECT id,pharmacy_name AS name,phone,email,address,city,
                       verification_status,demo_record
                FROM pharmacies ORDER BY pharmacy_name
                """);
    }
}
