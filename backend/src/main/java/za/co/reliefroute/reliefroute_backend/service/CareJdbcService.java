package za.co.reliefroute.reliefroute_backend.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class CareJdbcService {
    private final JdbcTemplate jdbc;
    public CareJdbcService(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public List<Map<String,Object>> reminders(String uid) {
        return jdbc.queryForList("SELECT r.id,r.medicine_name,r.reminder_time,r.frequency,r.completed FROM reminders r JOIN users u ON u.id=r.user_id WHERE u.firebase_uid=? ORDER BY r.reminder_time", uid);
    }
    public Map<String,Object> addReminder(String uid, Map<String,Object> body) {
        Long user = userId(uid);
        jdbc.update("INSERT INTO reminders(user_id,medicine_name,reminder_time,frequency) VALUES(?,?,?,?)", user, body.get("medicine"), body.get("time"), body.get("frequency"));
        return jdbc.queryForMap("SELECT * FROM reminders WHERE id=LAST_INSERT_ID()");
    }
    public List<Map<String,Object>> prescriptions(String uid) {
        return jdbc.queryForList("SELECT p.reference,p.file_path,p.status,p.pharmacist_note,p.submitted_at,p.reviewed_at FROM prescriptions p JOIN users u ON u.id=p.user_id WHERE u.firebase_uid=? ORDER BY p.submitted_at DESC", uid);
    }
    public Map<String,Object> addPrescription(String uid, Map<String,Object> body) {
        Long user = userId(uid);
        String ref = "RX-" + UUID.randomUUID().toString().substring(0,8).toUpperCase();
        jdbc.update("INSERT INTO prescriptions(reference,user_id,file_path) VALUES(?,?,?)", ref, user, String.valueOf(body.getOrDefault("filePath", body.getOrDefault("fileName", ""))));
        return jdbc.queryForMap("SELECT * FROM prescriptions WHERE reference=?", ref);
    }
    public List<Map<String,Object>> addresses(String uid) {
        return jdbc.queryForList("SELECT a.* FROM addresses a JOIN users u ON u.id=a.user_id WHERE u.firebase_uid=? ORDER BY a.is_default DESC,a.id", uid);
    }
    public Map<String,Object> addAddress(String uid, Map<String,Object> body) {
        Long user = userId(uid);
        jdbc.update("INSERT INTO addresses(user_id,label,address_line1,address_line2,city,province,postal_code,is_default) VALUES(?,?,?,?,?,?,?,?)", user, body.get("label"), body.get("addressLine1"), body.get("addressLine2"), body.get("city"), body.get("province"), body.get("postalCode"), Boolean.TRUE.equals(body.get("isDefault")));
        return jdbc.queryForMap("SELECT * FROM addresses WHERE id=LAST_INSERT_ID()");
    }
    private Long userId(String uid) { return jdbc.queryForObject("SELECT id FROM users WHERE firebase_uid=?", Long.class, uid); }
}
