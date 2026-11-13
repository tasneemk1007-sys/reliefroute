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
