package za.co.reliefroute.reliefroute_backend.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class MedicineJdbcService {
    private final JdbcTemplate jdbc;

    public MedicineJdbcService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> list(String query) {
        String term = query == null ? "" : query.trim();
        if (term.isEmpty()) {
            return jdbc.queryForList("""
                    SELECT public_id AS id, name, description, category, price,
                           stock_quantity, prescription_required, active
                    FROM medicines WHERE active = TRUE ORDER BY name
                    """);
        }
        return jdbc.queryForList("""
                SELECT public_id AS id, name, description, category, price,
                       stock_quantity, prescription_required, active
                FROM medicines
                WHERE active = TRUE AND (name LIKE ? OR category LIKE ?)
                ORDER BY name
                """, "%" + term + "%", "%" + term + "%");
    }

    public Map<String, Object> get(String id) {
        return jdbc.queryForMap("""
                SELECT public_id AS id, name, description, category, price,
                       stock_quantity, prescription_required, active
                FROM medicines WHERE public_id = ? AND active = TRUE
                """, id);
    }
}
