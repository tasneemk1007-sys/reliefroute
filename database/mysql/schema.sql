-- ReliefRoute local MySQL schema for MySQL 8+.
-- This file mirrors the Flyway migrations. For an existing database, prefer
-- running the Spring Boot API so Flyway applies the migrations in order.
CREATE DATABASE IF NOT EXISTS reliefroute CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE reliefroute;
CREATE TABLE IF NOT EXISTS users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid VARCHAR(128) NOT NULL UNIQUE,
  email VARCHAR(320) NOT NULL UNIQUE,
  full_name VARCHAR(160) NOT NULL,
  role VARCHAR(32) NOT NULL DEFAULT 'customer',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS medicines (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  public_id VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(160) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(80) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  stock_quantity INT NOT NULL DEFAULT 0,
  prescription_required BOOLEAN NOT NULL DEFAULT FALSE,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_medicines_category (category, active)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS orders (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  reference VARCHAR(32) NOT NULL UNIQUE,
  firebase_uid VARCHAR(128) NOT NULL,
  address TEXT NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'placed',
  subtotal DECIMAL(10,2) NOT NULL,
  delivery_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_orders_user_created (firebase_uid, created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS order_items (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  medicine_id BIGINT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_order_items_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS deliveries (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  driver_id VARCHAR(128),
  status VARCHAR(32) NOT NULL DEFAULT 'pending',
  tracking_note VARCHAR(500),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS addresses (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  label VARCHAR(80) NOT NULL,
  address_line1 VARCHAR(200) NOT NULL,
  address_line2 VARCHAR(200),
  city VARCHAR(100) NOT NULL,
  province VARCHAR(100) NOT NULL,
  postal_code VARCHAR(16) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS prescriptions (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  reference VARCHAR(32) NOT NULL UNIQUE,
  user_id BIGINT NOT NULL,
  file_path VARCHAR(500) NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'pending',
  pharmacist_note TEXT,
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reminders (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  medicine_name VARCHAR(160) NOT NULL,
  reminder_time TIME NOT NULL,
  frequency VARCHAR(80) NOT NULL,
  completed BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS demo_medicines (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 generic_name VARCHAR(150) NOT NULL,
 category VARCHAR(100) NOT NULL,
 description VARCHAR(255) NOT NULL,
 strength_or_form VARCHAR(100) DEFAULT 'Multiple formulations - verify',
 price DECIMAL(10,2) DEFAULT NULL,
 stock_quantity INT NOT NULL DEFAULT 0,
 prescription_required BOOLEAN DEFAULT NULL,
 verification_status VARCHAR(60) NOT NULL DEFAULT 'NOT_VERIFIED',
 demo_record BOOLEAN NOT NULL DEFAULT TRUE,
 active BOOLEAN NOT NULL DEFAULT FALSE,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY uq_demo_medicines_generic_name (generic_name)
);

CREATE TABLE IF NOT EXISTS doctors (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 display_name VARCHAR(150) NOT NULL,
 specialty VARCHAR(120),
 practice_name VARCHAR(150),
 phone VARCHAR(40),
 email VARCHAR(150),
 address VARCHAR(255),
 verification_status VARCHAR(60) NOT NULL DEFAULT 'FICTIONAL_DEMO_ONLY',
 demo_record BOOLEAN NOT NULL DEFAULT TRUE,
 UNIQUE KEY uq_doctors_display_name (display_name)
);

CREATE TABLE IF NOT EXISTS pharmacies (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,
 pharmacy_name VARCHAR(150) NOT NULL,
 phone VARCHAR(40),
 email VARCHAR(150),
 address VARCHAR(255),
 city VARCHAR(100),
 verification_status VARCHAR(60) NOT NULL DEFAULT 'FICTIONAL_DEMO_ONLY',
 demo_record BOOLEAN NOT NULL DEFAULT TRUE,
 UNIQUE KEY uq_pharmacies_name (pharmacy_name)
);

INSERT IGNORE INTO demo_medicines
(generic_name, category, description, strength_or_form, price, stock_quantity, prescription_required, verification_status, demo_record)
VALUES
('Paracetamol','Pain and fever','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Ibuprofen','Pain and inflammation','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Aspirin','Pain and fever','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Cetirizine','Allergy','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Loratadine','Allergy','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Chlorpheniramine','Allergy','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Omeprazole','Digestive health','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Esomeprazole','Digestive health','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Loperamide','Digestive health','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Oral rehydration salts','Hydration','Demo entry; verify product details with a pharmacist.','Sachets - verify formulation',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Metformin','Diabetes care','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Gliclazide','Diabetes care','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Amlodipine','Blood pressure','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Losartan','Blood pressure','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Enalapril','Blood pressure','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Atorvastatin','Cholesterol','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Simvastatin','Cholesterol','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Salbutamol','Respiratory','Demo entry; verify product details with a pharmacist.','Inhaled formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Budesonide','Respiratory','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Amoxicillin','Antibiotic','Demo entry; pharmacist/clinician review required.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Azithromycin','Antibiotic','Demo entry; pharmacist/clinician review required.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Doxycycline','Antibiotic','Demo entry; pharmacist/clinician review required.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Fluconazole','Antifungal','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Clotrimazole','Antifungal','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Hydrocortisone','Skin care','Demo entry; verify product details with a pharmacist.','Topical formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Mupirocin','Skin care','Demo entry; verify product details with a pharmacist.','Topical formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Ferrous sulfate','Vitamins and minerals','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Folic acid','Vitamins and minerals','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Vitamin D3 (cholecalciferol)','Vitamins and minerals','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE),
('Calcium carbonate','Vitamins and minerals','Demo entry; verify product details with a pharmacist.','Multiple formulations - verify',NULL,0,NULL,'NOT_VERIFIED',TRUE);

INSERT IGNORE INTO doctors (display_name,specialty,practice_name,phone,email,address) VALUES
('Dr Demo A. Naidoo','General Practice','ReliefRoute Demo Clinic','000-000-0001','doctor1@example.invalid','Demo address, Durban'),
('Dr Demo B. Dlamini','Paediatrics','ReliefRoute Demo Clinic','000-000-0002','doctor2@example.invalid','Demo address, Durban'),
('Dr Demo C. Pillay','Dermatology','ReliefRoute Demo Clinic','000-000-0003','doctor3@example.invalid','Demo address, Durban'),
('Dr Demo D. Mokoena','Cardiology','ReliefRoute Demo Clinic','000-000-0004','doctor4@example.invalid','Demo address, Durban'),
('Dr Demo E. Khan','Family Medicine','ReliefRoute Demo Clinic','000-000-0005','doctor5@example.invalid','Demo address, Durban');

INSERT IGNORE INTO pharmacies (pharmacy_name,phone,email,address,city) VALUES
('ReliefRoute Demo Pharmacy - North','000-000-0101','north@example.invalid','Demo address 1','Durban'),
('ReliefRoute Demo Pharmacy - Central','000-000-0102','central@example.invalid','Demo address 2','Durban'),
('ReliefRoute Demo Pharmacy - South','000-000-0103','south@example.invalid','Demo address 3','Durban'),
('ReliefRoute Demo Pharmacy - West','000-000-0104','west@example.invalid','Demo address 4','Durban'),
('ReliefRoute Demo Pharmacy - Coast','000-000-0105','coast@example.invalid','Demo address 5','Durban');
