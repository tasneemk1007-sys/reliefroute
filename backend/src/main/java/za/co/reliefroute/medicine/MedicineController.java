package za.co.reliefroute.medicine;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController @RequestMapping("/api/medicines")
public class MedicineController {
  private final MedicineRepository repo;
  public MedicineController(MedicineRepository repo) { this.repo = repo; }
  @GetMapping public List<Medicine> list(@RequestParam(defaultValue="") String q) {
    return q.isBlank() ? repo.findAll().stream().filter(m -> m.active).toList() : repo.findByActiveTrueAndNameContainingIgnoreCaseOrActiveTrueAndCategoryContainingIgnoreCase(q,q);
  }
  @GetMapping("/{id}") public Medicine get(@PathVariable Long id) { return repo.findById(id).orElseThrow(); }
}
