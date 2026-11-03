package za.co.reliefroute.medicine;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity @Table(name="medicines")
public class Medicine {
  @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id;
  @Column(name="public_id", nullable=false, unique=true) public String publicId;
  @Column(nullable=false) public String name;
  @Column(nullable=false, columnDefinition="TEXT") public String description;
  @Column(nullable=false) public String category;
  @Column(nullable=false, precision=10, scale=2) public BigDecimal price;
  @Column(name="stock_quantity", nullable=false) public int stockQuantity;
  @Column(name="prescription_required", nullable=false) public boolean prescriptionRequired;
  @Column(nullable=false) public boolean active = true;
}
