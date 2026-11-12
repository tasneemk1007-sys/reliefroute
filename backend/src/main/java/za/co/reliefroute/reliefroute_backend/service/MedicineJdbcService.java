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
                    SELECT public_id AS id,name,description,category,price,stock_quantity,
                           prescription_required,active,'ACTIVE_CATALOGUE' AS verification_status,
                           FALSE AS demo_record
                    FROM medicines WHERE active=TRUE
                    UNION ALL
                    SELECT CONCAT('DEMO-',id) AS id,generic_name AS name,description,category,
                           price,stock_quantity,prescription_required,active,verification_status,
                           demo_record
                    FROM demo_medicines
                    ORDER BY name
                    """);
        }
        return jdbc.queryForList("""
                SELECT * FROM (
                    SELECT public_id AS id,name,description,category,price,stock_quantity,
                           prescription_required,active,'ACTIVE_CATALOGUE' AS verification_status,
                           FALSE AS demo_record
                    FROM medicines WHERE active=TRUE
                    UNION ALL
                    SELECT CONCAT('DEMO-',id) AS id,generic_name AS name,description,category,
                           price,stock_quantity,prescription_required,active,verification_status,
                           demo_record
                    FROM demo_medicines
                ) catalogue
                WHERE name LIKE ? OR category LIKE ?
                ORDER BY name
                """, "%" + term + "%", "%" + term + "%");
    }

    public Map<String, Object> get(String id) {
        if (id.startsWith("DEMO-")) {
            return jdbc.queryForMap("""
                    SELECT CONCAT('DEMO-',id) AS id,generic_name AS name,description,category,
                           price,stock_quantity,prescription_required,active,verification_status,
                           demo_record
                    FROM demo_medicines WHERE id=?
                    """, Long.parseLong(id.substring("DEMO-".length())));
        }
        return jdbc.queryForMap("""
                SELECT public_id AS id,name,description,category,price,stock_quantity,
                       prescription_required,active,'ACTIVE_CATALOGUE' AS verification_status,
                       FALSE AS demo_record
                FROM medicines WHERE public_id=? AND active=TRUE
                """, id);
    }
}
