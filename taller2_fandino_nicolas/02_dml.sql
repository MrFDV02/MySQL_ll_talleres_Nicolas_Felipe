-- =====================================================================
-- 02_dml.sql
-- =====================================================================

USE flotaya;

-- 1. Catálogos: geografía y sedes (sección 1.1)

INSERT INTO departments (name) VALUES
('Bogotá D.C.'),
('Antioquia'),
('Bolívar'),
('Valle del Cauca'),
('Santander'),
('Quindío'),
('Magdalena');

INSERT INTO cities (department_id, name) VALUES
(1, 'Bogotá'),
(2, 'Medellín'),
(2, 'Rionegro'),
(3, 'Cartagena'),
(4, 'Cali'),
(5, 'Bucaramanga'),
(6, 'Armenia');

INSERT INTO branches (city_id, name, address, phone, is_airport) VALUES
(1, 'FlotaYa Bogotá Calle 26', 'Avenida Calle 26 # 69-76', '6017001001', FALSE),
(1, 'FlotaYa Aeropuerto El Dorado', 'Avenida El Dorado # 103-09', '6017001002', TRUE),
(2, 'FlotaYa Medellín El Poblado', 'Carrera 43A # 7-50', '6047001003', FALSE),
(3, 'FlotaYa Aeropuerto José María Córdova', 'Vía Aeropuerto JMC km 1', '6047001004', TRUE),
(4, 'FlotaYa Cartagena Bocagrande', 'Carrera 2 # 8-120', '6057001005', FALSE),
(5, 'FlotaYa Cali Granada', 'Avenida 9N # 15-20', '6027001006', FALSE);

-- 2. Empleados: 10, los cuatro roles y un asesor por sede

INSERT INTO employees (branch_id, full_name, email, hire_date, role) VALUES
(1, 'Mónica Gaitán',      'monica.gaitan@flotaya.example.com',    '2018-02-01', 'ADMINISTRADOR'),
(1, 'Gustavo Pérez',      'gustavo.perez@flotaya.example.com',    '2019-05-15', 'MECANICO'),
(1, 'Laura Restrepo',     'laura.restrepo@flotaya.example.com',   '2021-03-08', 'ASESOR'),
(2, 'Andrés Cárdenas',    'andres.cardenas@flotaya.example.com',  '2020-07-01', 'ASESOR'),
(3, 'Camila Ospina',      'camila.ospina@flotaya.example.com',    '2019-11-12', 'ASESOR'),
(4, 'Julián Betancur',    'julian.betancur@flotaya.example.com',  '2022-01-17', 'ASESOR'),
(5, 'Valentina Ruiz',     'valentina.ruiz@flotaya.example.com',   '2023-04-03', 'ASESOR'),
(6, 'Sebastián Mena',     'sebastian.mena@flotaya.example.com',   '2022-09-19', 'ASESOR'),
(2, 'Carolina Zapata',    'carolina.zapata@flotaya.example.com',  '2021-06-14', 'INSPECTOR'),
(4, 'Diego Salcedo',      'diego.salcedo@flotaya.example.com',    '2023-02-06', 'INSPECTOR');

-- 3. Categorías, temporadas y tarifas (sección 1.2)

INSERT INTO categories (name, min_age, deposit_amount) VALUES
('Económico',      21, 1500000),
('Compacto',       21, 1500000),
('SUV',            23, 2500000),
('Camioneta 4x4',  25, 3000000),
('Van',            25, 3000000),
('Lujo',           30, 5000000);

INSERT INTO seasons (name, season_type, start_date, end_date) VALUES
('Fin de año 2025',                'ALTA',  '2025-12-15', '2026-01-15'),
('Baja de inicio de año',          'BAJA',  '2026-01-16', '2026-03-28'),
('Semana Santa',                   'ALTA',  '2026-03-29', '2026-04-05'),
('Baja de abril a junio',          'BAJA',  '2026-04-06', '2026-06-12'),
('Vacaciones de mitad de año',     'ALTA',  '2026-06-13', '2026-07-19'),
('Baja de segundo semestre',       'BAJA',  '2026-07-20', '2026-10-02'),
('Receso escolar de octubre',      'MEDIA', '2026-10-03', '2026-10-12'),
('Baja de noviembre',              'BAJA',  '2026-10-13', '2026-11-30'),
('Temporada de novenas',           'MEDIA', '2026-12-01', '2026-12-14'),
('Fin de año 2026',                'ALTA',  '2026-12-15', '2027-01-15');

-- 6 categorías × 3 tipos de temporada = 18 tarifas
INSERT INTO season_rates (category_id, season_type, daily_rate) VALUES
(1, 'BAJA', 120000), (1, 'MEDIA', 140000), (1, 'ALTA', 180000),
(2, 'BAJA', 150000), (2, 'MEDIA', 175000), (2, 'ALTA', 220000),
(3, 'BAJA', 230000), (3, 'MEDIA', 270000), (3, 'ALTA', 340000),
(4, 'BAJA', 300000), (4, 'MEDIA', 350000), (4, 'ALTA', 430000),
(5, 'BAJA', 320000), (5, 'MEDIA', 370000), (5, 'ALTA', 460000),
(6, 'BAJA', 450000), (6, 'MEDIA', 520000), (6, 'ALTA', 650000);

-- 4. Marcas, modelos y flota (sección 1.3)

INSERT INTO brands (name) VALUES
('Renault'), ('Kia'), ('Chevrolet'), ('Mazda'), ('Toyota'), ('Hyundai'), ('Nissan');

INSERT INTO models (brand_id, category_id, name, transmission, fuel, seats) VALUES
(1, 1, 'Kwid',           'MECANICA',   'GASOLINA',  5),
(2, 1, 'Picanto',        'AUTOMATICA', 'GASOLINA',  5),
(3, 2, 'Onix',           'AUTOMATICA', 'GASOLINA',  5),
(4, 2, 'Mazda 2',        'AUTOMATICA', 'GASOLINA',  5),
(1, 3, 'Duster',         'MECANICA',   'GASOLINA',  5),
(2, 3, 'Sportage',       'AUTOMATICA', 'HIBRIDO',   5),
(5, 4, 'Hilux',          'MECANICA',   'DIESEL',    5),
(6, 5, 'Staria',         'AUTOMATICA', 'DIESEL',   11),
(4, 3, 'CX-30',          'AUTOMATICA', 'GASOLINA',  5);

INSERT INTO vehicles (model_id, plate, model_year, color, mileage_km, status, branch_id) VALUES
(1, 'KWD101', 2024, 'Blanco', 18950, 'DISPONIBLE',         1),
(1, 'KWD102', 2024, 'Gris',   22100, 'DISPONIBLE',         2),
(1, 'KWD103', 2021, 'Blanco', 98400, 'FUERA_DE_SERVICIO',  6),
(2, 'PCN201', 2025, 'Rojo',   10450, 'DISPONIBLE',         2),
(2, 'PCN202', 2025, 'Blanco', 12400, 'DISPONIBLE',         3),
(3, 'ONX301', 2024, 'Plata',  30500, 'ALQUILADO',          2),
(3, 'ONX302', 2023, 'Negro',  41890, 'MANTENIMIENTO',      5),
(4, 'MZD401', 2025, 'Azul',    9310, 'DISPONIBLE',         4),
(4, 'MZD402', 2024, 'Rojo',   26300, 'ALQUILADO',          4),
(5, 'DST501', 2023, 'Blanco', 48620, 'DISPONIBLE',         1),
(5, 'DST502', 2024, 'Gris',   22710, 'DISPONIBLE',         6),
(6, 'SPT601', 2025, 'Negro',  11500, 'ALQUILADO',          2),
(6, 'SPT602', 2025, 'Blanco',  9600, 'DISPONIBLE',         4),
(7, 'HLX701', 2023, 'Plata',  64380, 'DISPONIBLE',         3),
(7, 'HLX702', 2022, 'Blanco', 88100, 'MANTENIMIENTO',      6),
(8, 'STR801', 2024, 'Gris',   35700, 'DISPONIBLE',         2),
(8, 'STR802', 2025, 'Blanco', 15480, 'DISPONIBLE',         5);

-- 5. Mantenimientos: 7, con los dos en curso y un vehículo repetido

INSERT INTO maintenances (vehicle_id, maintenance_type, description, workshop, start_date, end_date, cost) VALUES
(15, 'CORRECTIVO',  'Cambio de embrague',                     'Diésel del Valle',         '2026-11-16', NULL,         NULL),
(7,  'LATONERIA',   'Reparación de latonería',                'Latonería Caribe',         '2026-10-26', NULL,         NULL),
(3,  'CORRECTIVO',  'Diagnóstico de motor (pérdida total)',   'Taller FlotaYa Bogotá',    '2026-09-01', '2026-09-12', 1250000),
(3,  'PREVENTIVO',  'Cambio de aceite y filtros',             'Taller FlotaYa Bogotá',    '2026-06-10', '2026-06-10', 240000),
(10, 'PREVENTIVO',  'Revisión de 50.000 km',                  'Taller FlotaYa Bogotá',    '2026-10-05', '2026-10-06', 620000),
(16, 'CORRECTIVO',  'Cambio de bomba de agua',                'Serviteca El Dorado',      '2026-09-20', '2026-09-24', 890000),
(11, 'PREVENTIVO',  'Cambio de aceite',                       'Serviteca Granada',        '2026-10-14', '2026-10-14', 310000);

-- 6. Extras (sección 1.5)

INSERT INTO extras (name, daily_price) VALUES
('GPS',               15000),
('Silla de bebé',     12000),
('Seguro total',      45000),
('Conductor adicional', 20000),
('Wi-Fi portátil',    10000),
('Portabicicletas',   18000);

-- 7. Clientes, licencias y conductores adicionales (sección 1.4)

INSERT INTO customers (document_type, document_number, first_name, last_name, email, phone, birth_date, city_id, registered_at, status) VALUES
('CC',        '1020304050', 'Andrea',  'Salazar',   'andrea.salazar@example.com',   '3105551001', '1990-04-12', 1, '2025-01-10 09:00:00', 'ACTIVO'),
('CC',        '71234567',   'Carlos',  'Mejía',     'carlos.mejia@example.com',     '3105551002', '1985-09-30', 2, '2025-02-14 10:30:00', 'ACTIVO'),
('CC',        '1012456789', 'Juliana', 'Patiño',    'juliana.patino@example.com',   '3105551003', '2004-07-15', 1, '2025-03-02 11:45:00', 'ACTIVO'),
('CE',        '512345',     'Lucas',   'Ferreira',  'lucas.ferreira@example.com',   '3105551004', '1979-02-02', 4, '2025-04-21 08:15:00', 'ACTIVO'),
('CC',        '1112345678', 'Diana',   'Rozo',      'diana.rozo@example.com',       '3105551005', '1993-11-25', 5, '2025-05-09 14:20:00', 'ACTIVO'),
('PASAPORTE', 'CA4455667',  'Emma',    'Walker',    'emma.walker@example.com',      '3105551006', '1988-06-18', 4, '2025-06-18 16:00:00', 'ACTIVO'),
('CC',        '70567890',   'Jorge',   'Arango',    'jorge.arango@example.com',     '3105551007', '1975-01-09', 2, '2025-07-04 09:30:00', 'ACTIVO'),
('CC',        '1032456789', 'Paola',   'Quintero',  'paola.quintero@example.com',   '3105551008', '1999-12-03', 1, '2025-08-12 15:10:00', 'ACTIVO'),
('CC',        '1098765432', 'Esteban', 'Rueda',     'esteban.rueda@example.com',    '3105551009', '2002-05-21', 6, '2025-09-01 12:00:00', 'ACTIVO'),
('CC',        '41678901',   'Martha',  'Cifuentes', 'martha.cifuentes@example.com', '3105551010', '1968-03-14', 1, '2025-09-15 10:40:00', 'BLOQUEADO'),
('CC',        '1004567890', 'Kevin',   'Morales',   'kevin.morales@example.com',    '3105551011', '2005-10-02', 5, '2025-10-06 13:25:00', 'ACTIVO'),
('CC',        '1025678901', 'Laura',   'Benítez',   'laura.benitez@example.com',     NULL,        '1996-08-08', 2, '2025-10-20 17:05:00', 'ACTIVO'),
('CC',        '79456789',   'Ricardo', 'Lozano',    'ricardo.lozano@example.com',   '3105551013', '1982-12-24', 1, '2025-11-03 08:50:00', 'ACTIVO'),
('CC',        '1015987654', 'Sofía',   'Herrera',   'sofia.herrera@example.com',    '3105551014', '2001-01-30', 3, '2026-09-07 09:15:00', 'ACTIVO');

-- Jorge Arango conserva su licencia vieja vencida y la nueva vigente
INSERT INTO driver_licenses (customer_id, license_number, category, issue_date, expiry_date, country) VALUES
(1,  'LIC-1001', 'B1', '2019-05-10', '2028-05-10', 'Colombia'),
(2,  'LIC-1002', 'B1', '2015-02-20', '2027-02-20', 'Colombia'),
(3,  'LIC-1003', 'B1', '2022-08-01', '2032-08-01', 'Colombia'),
(4,  'LIC-1004', 'B1', '2019-12-31', '2026-12-31', 'Brasil'),
(5,  'LIC-1005', 'B1', '2018-11-30', '2029-11-30', 'Colombia'),
(6,  'LIC-1006', 'B1', '2021-06-01', '2031-06-01', 'Canadá'),
(7,  'LIC-1007', 'C1', '2000-01-15', '2010-01-15', 'Colombia'),
(7,  'LIC-1008', 'C1', '2010-01-15', '2030-01-15', 'Colombia'),
(8,  'LIC-1009', 'B1', '2016-12-10', '2026-12-10', 'Colombia'),
(9,  'LIC-1010', 'B1', '2019-08-01', '2026-08-01', 'Colombia'),
(10, 'LIC-1011', 'B1', '2018-04-04', '2028-04-04', 'Colombia'),
(11, 'LIC-1012', 'B1', '2023-10-10', '2033-10-10', 'Colombia'),
(13, 'LIC-1013', 'B1', '2017-12-24', '2027-12-24', 'Colombia'),
(14, 'LIC-1014', 'B1', '2019-02-01', '2029-02-01', 'Colombia');

INSERT INTO additional_drivers (document_number, full_name, birth_date, license_number, license_expiry_date) VALUES
('1014567890', 'Felipe Salazar',  '1988-03-03', 'LIC-A1001', '2029-03-03'),
('43765432',   'Mónica Arango',   '1977-07-07', 'LIC-A1002', '2028-07-07'),
('1009876543', 'Tomás Ferreira',  '2006-03-03', 'LIC-A1003', '2030-03-03'),
('1067891234', 'Natalia Rozo',    '1995-05-05', 'LIC-A1004', '2026-09-30');

-- 8. Reservas: 14, con los cuatro estados y las vivas de la sección 1.6

INSERT INTO reservations (customer_id, vehicle_id, pickup_branch_id, return_branch_id, pickup_date, return_date, quoted_value, created_at, status) VALUES
(3,  1,  1, 1, '2026-11-27', '2026-12-02',  620000, '2026-11-05 10:15:00', 'CONFIRMADA'),
(5,  16, 2, 2, '2026-12-18', '2026-12-23', 2300000, '2026-11-06 15:40:00', 'CONFIRMADA'),
(11, 5,  3, 3, '2026-12-10', '2026-12-17',  980000, '2026-11-08 11:05:00', 'PENDIENTE'),
(14, 13, 4, 4, '2026-12-05', '2026-12-09', 1080000, '2026-11-09 16:20:00', 'PENDIENTE'),
(4,  17, 5, 5, '2026-10-01', '2026-10-06', 1750000, '2026-09-20 09:30:00', 'CONVERTIDA'),
(7,  14, 3, 3, '2026-10-15', '2026-10-20', 1500000, '2026-10-01 14:00:00', 'CONVERTIDA'),
(6,  7,  5, 5, '2026-10-20', '2026-10-24',  600000, '2026-10-05 10:45:00', 'CONVERTIDA'),
(5,  11, 6, 6, '2026-10-08', '2026-10-12',  920000, '2026-09-25 12:10:00', 'CONVERTIDA'),
(8,  12, 2, 2, '2026-11-15', '2026-11-22', 1610000, '2026-11-02 09:00:00', 'CONVERTIDA'),
(13, 6,  2, 1, '2026-11-17', '2026-11-21',  600000, '2026-11-10 17:30:00', 'CONVERTIDA'),
(2,  9,  4, 4, '2026-11-18', '2026-11-25', 1050000, '2026-11-12 10:20:00', 'CONVERTIDA'),
(1,  2,  2, 2, '2026-09-05', '2026-09-09',  480000, '2026-08-25 08:45:00', 'CONVERTIDA'),
(10, 4,  2, 2, '2026-10-10', '2026-10-14',  540000, '2026-10-01 09:00:00', 'CANCELADA'),
(9,  2,  6, 6, '2026-09-20', '2026-09-23',  360000, '2026-09-01 10:30:00', 'CANCELADA');

-- 9. Contratos: 8, con los tres abiertos de la sección 1.6

INSERT INTO contracts (reservation_id, vehicle_id, employee_id, start_date, expected_end_date, actual_return_date, rental_value, status) VALUES
(505, 17, 7, '2026-10-01', '2026-10-06', '2026-10-06', 1750000, 'CERRADO'),
(506, 14, 5, '2026-10-15', '2026-10-20', '2026-10-20', 1500000, 'CERRADO'),
(507, 7,  7, '2026-10-20', '2026-10-24', '2026-10-24',  600000, 'CERRADO'),
(508, 11, 8, '2026-10-08', '2026-10-12', '2026-10-13', 1350000, 'CERRADO'),
(509, 12, 4, '2026-11-15', '2026-11-22', NULL,        1610000, 'ABIERTO'),
(510, 6,  4, '2026-11-17', '2026-11-21', NULL,         600000, 'ABIERTO'),
(511, 9,  6, '2026-11-18', '2026-11-25', NULL,        1050000, 'ABIERTO'),
(512, 2,  4, '2026-09-05', '2026-09-09', '2026-09-09',  480000, 'CERRADO');

-- Conductores adicionales por contrato (nunca dos veces el mismo)
INSERT INTO contract_drivers (contract_id, additional_driver_id) VALUES
(9001, 3),  -- Tomás Ferreira
(9002, 4),  -- Natalia Rozo
(9005, 1),  -- Felipe Salazar
(9007, 2);  -- Mónica Arango

-- Extras pactados con su precio del día (regla 17)
INSERT INTO contract_extras (contract_id, extra_id, quantity, agreed_price) VALUES
(9001, 4, 1, 20000),  -- Conductor adicional
(9002, 4, 1, 20000),  -- Conductor adicional
(9003, 1, 1, 15000),  -- GPS
(9005, 3, 1, 45000),  -- Seguro total
(9005, 4, 1, 20000),  -- Conductor adicional
(9006, 1, 1, 15000),  -- GPS
(9007, 4, 1, 20000),  -- Conductor adicional
(9007, 2, 2, 12000),  -- 2 sillas de bebé
(9008, 1, 1, 15000);  -- GPS

-- =====================================================================
-- 10. Entregas e inspecciones de entrega (una por contrato)
-- =====================================================================

INSERT INTO deliveries (contract_id, occurred_at, mileage_km, fuel_pct, branch_id, employee_id) VALUES
(9001, '2026-10-01 09:00:00', 15010, 100, 5, 7),
(9002, '2026-10-15 08:30:00', 63900, 100, 3, 5),
(9003, '2026-10-20 10:00:00', 41300,  90, 5, 7),
(9004, '2026-10-08 11:00:00', 21900, 100, 6, 8),
(9005, '2026-11-15 09:00:00', 11500, 100, 2, 4),
(9006, '2026-11-17 08:30:00', 30500,  75, 2, 4),
(9007, '2026-11-18 16:00:00', 26300, 100, 4, 6),
(9008, '2026-09-05 07:45:00', 21700, 100, 2, 4);

INSERT INTO inspections (contract_id, stage, occurred_at, exterior_ok, interior_ok, notes, employee_id) VALUES
(9001, 'ENTREGA',    '2026-10-01 09:10:00', FALSE, TRUE, 'Rayón previo en el bómper trasero (no se cobra)', 7),
(9002, 'ENTREGA',    '2026-10-15 08:40:00', TRUE,  TRUE, NULL, 5),
(9003, 'ENTREGA',    '2026-10-20 10:10:00', TRUE,  TRUE, NULL, 7),
(9004, 'ENTREGA',    '2026-10-08 11:10:00', TRUE,  TRUE, NULL, 8),
(9005, 'ENTREGA',    '2026-11-15 09:10:00', TRUE,  TRUE, NULL, 4),
(9006, 'ENTREGA',    '2026-11-17 08:40:00', TRUE,  TRUE, NULL, 4),
(9007, 'ENTREGA',    '2026-11-18 16:10:00', TRUE,  TRUE, NULL, 6),
(9008, 'ENTREGA',    '2026-09-05 07:55:00', TRUE,  TRUE, NULL, 4);

-- 11. Devoluciones e inspecciones de devolución (solo contratos cerrados)

INSERT INTO vehicle_returns (contract_id, occurred_at, mileage_km, fuel_pct, branch_id, employee_id) VALUES
(9001, '2026-10-06 17:00:00', 15480,  90, 5, 7),
(9002, '2026-10-20 18:30:00', 64380, 100, 3, 5),
(9003, '2026-10-24 09:00:00', 41890,  80, 5, 7),
(9004, '2026-10-13 10:15:00', 22710,  50, 6, 8),
(9008, '2026-09-09 16:30:00', 22100,  95, 2, 4);

INSERT INTO inspections (contract_id, stage, occurred_at, exterior_ok, interior_ok, notes, employee_id) VALUES
(9001, 'DEVOLUCION', '2026-10-06 17:10:00', TRUE,  TRUE, NULL, 7),
(9002, 'DEVOLUCION', '2026-10-20 18:40:00', FALSE, TRUE, 'Rayón en la puerta del conductor', 5),
(9003, 'DEVOLUCION', '2026-10-24 09:10:00', FALSE, TRUE, 'Golpe en la puerta trasera derecha', 7),
(9004, 'DEVOLUCION', '2026-10-13 10:25:00', TRUE,  TRUE, NULL, 8),
(9008, 'DEVOLUCION', '2026-09-09 16:40:00', TRUE,  TRUE, NULL, 4);

-- 12. Daños: 3 (uno previo que no se cobra y dos cobrables)

INSERT INTO damages (inspection_id, description, severity, repair_cost, charged_to_customer) VALUES
(1,  'Rayón previo en el bómper trasero',    'LEVE',  180000, FALSE),
(10, 'Rayón en la puerta del conductor',     'LEVE',  350000, TRUE),
(11, 'Golpe en la puerta trasera derecha',   'GRAVE', 2400000, TRUE);

-- 13. Depósitos: uno por contrato

INSERT INTO deposits (contract_id, amount, retained_at, released_at, applied_to_damages, status) VALUES
(9001, 3000000, '2026-10-01 09:00:00', '2026-10-06 17:00:00',       0, 'LIBERADO'),
(9002, 3000000, '2026-10-15 08:30:00', '2026-10-20 18:30:00',       0, 'LIBERADO'),
(9003, 1500000, '2026-10-20 10:00:00', '2026-10-24 09:00:00', 1500000, 'APLICADO'),
(9004, 2500000, '2026-10-08 11:00:00', '2026-10-13 10:15:00',       0, 'LIBERADO'),
(9005, 2500000, '2026-11-15 09:00:00', NULL,                         0, 'RETENIDO'),
(9006, 1500000, '2026-11-17 08:30:00', NULL,                         0, 'RETENIDO'),
(9007, 1500000, '2026-11-18 16:00:00', NULL,                         0, 'RETENIDO'),
(9008, 1500000, '2026-09-05 07:45:00', '2026-09-09 16:30:00',       0, 'LIBERADO');

-- 14. Pagos: 12, con contratos de más de un pago y los cuatro medios

INSERT INTO payments (contract_id, concept, amount, method, paid_at, card_last4, authorization_code) VALUES
(9001, 'ALQUILER', 1750000, 'TARJETA',       '2026-10-01 09:05:00', '4521', 'AUT-100231'),
(9001, 'EXTRAS',    100000, 'TARJETA',       '2026-10-06 17:20:00', '4521', 'AUT-100877'),
(9002, 'ALQUILER', 1500000, 'TARJETA',       '2026-10-15 08:35:00', '7812', 'AUT-101544'),
(9002, 'EXTRAS',    100000, 'EFECTIVO',      '2026-10-20 18:45:00', NULL,   NULL),
(9003, 'ALQUILER',  600000, 'TARJETA',       '2026-10-20 10:05:00', '3390', 'AUT-102310'),
(9003, 'EXTRAS',     60000, 'TARJETA',       '2026-10-20 10:06:00', '3390', 'AUT-102311'),
(9003, 'DAÑOS',    1500000, 'DEPOSITO',      '2026-10-24 09:30:00', NULL,   NULL),
(9004, 'ALQUILER', 1350000, 'TRANSFERENCIA', '2026-10-13 10:40:00', NULL,   NULL),
(9008, 'ALQUILER',  480000, 'EFECTIVO',      '2026-09-05 07:50:00', NULL,   NULL),
(9008, 'EXTRAS',     60000, 'TARJETA',       '2026-09-09 16:45:00', '9012', 'AUT-100099'),
(9005, 'ALQUILER', 1610000, 'TARJETA',       '2026-11-15 09:05:00', '5544', 'AUT-110515'),
(9006, 'ALQUILER',  600000, 'TARJETA',       '2026-11-17 08:35:00', '1234', 'AUT-110717');

-- =====================================================================
-- Conteo de cierre de las semillas (resultado esperado en el comentario)
-- =====================================================================
SELECT 'departments' AS tabla, COUNT(*) AS filas FROM departments
UNION ALL SELECT 'cities',          COUNT(*) FROM cities
UNION ALL SELECT 'branches',        COUNT(*) FROM branches
UNION ALL SELECT 'employees',       COUNT(*) FROM employees
UNION ALL SELECT 'categories',      COUNT(*) FROM categories
UNION ALL SELECT 'brands',          COUNT(*) FROM brands
UNION ALL SELECT 'models',          COUNT(*) FROM models
UNION ALL SELECT 'vehicles',        COUNT(*) FROM vehicles
UNION ALL SELECT 'seasons',         COUNT(*) FROM seasons
UNION ALL SELECT 'season_rates',    COUNT(*) FROM season_rates
UNION ALL SELECT 'maintenances',    COUNT(*) FROM maintenances
UNION ALL SELECT 'extras',          COUNT(*) FROM extras
UNION ALL SELECT 'customers',       COUNT(*) FROM customers
UNION ALL SELECT 'driver_licenses', COUNT(*) FROM driver_licenses
UNION ALL SELECT 'additional_drivers', COUNT(*) FROM additional_drivers
UNION ALL SELECT 'reservations',    COUNT(*) FROM reservations
UNION ALL SELECT 'contracts',       COUNT(*) FROM contracts
UNION ALL SELECT 'contract_drivers', COUNT(*) FROM contract_drivers
UNION ALL SELECT 'contract_extras', COUNT(*) FROM contract_extras
UNION ALL SELECT 'deliveries',      COUNT(*) FROM deliveries
UNION ALL SELECT 'vehicle_returns', COUNT(*) FROM vehicle_returns
UNION ALL SELECT 'inspections',     COUNT(*) FROM inspections
UNION ALL SELECT 'damages',         COUNT(*) FROM damages
UNION ALL SELECT 'deposits',        COUNT(*) FROM deposits
UNION ALL SELECT 'payments',        COUNT(*) FROM payments;
-- Esperado: departments 7 · cities 7 · branches 6 · employees 10 · categories 6
-- brands 7 · models 9 · vehicles 17 · seasons 10 · season_rates 18 · maintenances 7
-- extras 6 · customers 14 · driver_licenses 14 · additional_drivers 4
-- reservations 14 · contracts 8 · contract_drivers 4 · contract_extras 9
-- deliveries 8 · vehicle_returns 5 · inspections 13 · damages 3 · deposits 8 · payments 12

-- =====================================================================
-- OPERACIONES DEL DÍA
-- =====================================================================

-- Op. 1 · FlotaYa abre en Bucaramanga

(6, 'FlotaYa Bucaramanga Cabecera', 'Carrera 35 # 48-20', '6077001007');

INSERT INTO employees (branch_id, full_name, email, hire_date, role) VALUES
(7, 'Daniel Rojas', 'daniel.rojas@flotaya.example.com', '2026-11-20', 'ASESOR');

INSERT INTO vehicles (model_id, plate, model_year, color, mileage_km, branch_id) VALUES
(5, 'DST503', 2026, 'Rojo', 1200, 7);

-- Una sola fila: sede, si es de aeropuerto, ciudad, asesor y vehículo
SELECT b.name          AS sede,
       b.is_airport    AS es_aeropuerto,
       ci.name         AS ciudad,
       e.full_name     AS asesor,
       CONCAT(v.plate, ' · ', m.name) AS vehiculo,
       v.status        AS estado
FROM branches AS b
JOIN cities AS ci ON ci.id = b.city_id
LEFT JOIN employees AS e ON e.branch_id = b.id AND e.role = 'ASESOR'
LEFT JOIN vehicles AS v ON v.branch_id = b.id
LEFT JOIN models AS m ON m.id = v.model_id
WHERE b.name = 'FlotaYa Bucaramanga Cabecera';
-- Esperado: FlotaYa Bucaramanga Cabecera | 0 | Bucaramanga | Daniel Rojas | DST503 · Duster | DISPONIBLE


-- Op. 2 · Ajustes de precios
SELECT c.name AS categoria, r.season_type AS tipo, r.daily_rate AS tarifa_antes
FROM season_rates AS r
JOIN categories AS c ON c.id = r.category_id
WHERE c.name = 'Lujo' AND r.season_type = 'ALTA';

-- Se guarda la clave de esa tarifa para actualizar por PK (Safe Updates)
SET @tarifa_lujo_alta = (SELECT r.id
                         FROM season_rates AS r
                         JOIN categories AS c ON c.id = r.category_id
                         WHERE c.name = 'Lujo' AND r.season_type = 'ALTA');

UPDATE season_rates
SET daily_rate = daily_rate * 1.05
WHERE id = @tarifa_lujo_alta;

SELECT c.name AS categoria, r.season_type AS tipo, r.daily_rate AS tarifa_despues
FROM season_rates AS r
JOIN categories AS c ON c.id = r.category_id
WHERE c.name = 'Lujo' AND r.season_type = 'ALTA';
-- Esperado: 650000.00 → 682500.00

SELECT e.name AS extra, e.daily_price AS precio_lista
FROM extras AS e WHERE e.name = 'GPS';

UPDATE extras SET daily_price = 16000 WHERE name = 'GPS';

-- Precio de lista contra el precio pactado en los contratos que llevan GPS
SELECT e.name            AS extra,
       e.daily_price     AS precio_lista_hoy,
       ce.agreed_price   AS precio_pactado,
       ct.id             AS contrato
FROM contract_extras AS ce
JOIN extras AS e ON e.id = ce.extra_id
JOIN contracts AS ct ON ct.id = ce.contract_id
WHERE e.name = 'GPS'
ORDER BY ct.id;
-- Los contratos conservan 15000: el precio pactado no cambia (regla 17).


-- Op. 3 · Confirmaciones de diciembre
SELECT id, pickup_date, status FROM reservations
WHERE status = 'PENDIENTE' AND pickup_date >= '2026-12-01';

-- ⚠️ ESPERADO: ERROR 1175 (HY000): You are using safe update mode...
-- (el WHERE usa columnas sin índice). Ejecutar sola con Safe Updates activo:
-- UPDATE reservations SET status = 'CONFIRMADA'
-- WHERE status = 'PENDIENTE' AND pickup_date >= '2026-12-01';

-- Ahora por clave primaria:
UPDATE reservations SET status = 'CONFIRMADA' WHERE id = 503;
UPDATE reservations SET status = 'CONFIRMADA' WHERE id = 504;

SELECT id, pickup_date, status FROM reservations WHERE id IN (503, 504);

-- Op. 4 · Limpieza
SELECT COUNT(*) AS modelos_de_nissan FROM models WHERE brand_id = (SELECT id FROM brands WHERE name = 'Nissan');

SELECT COUNT(*) AS contratos_con_portabicicletas
FROM contract_extras WHERE extra_id = (SELECT id FROM extras WHERE name = 'Portabicicletas');

DELETE FROM brands WHERE name = 'Nissan';
DELETE FROM extras WHERE name = 'Portabicicletas';

SELECT COUNT(*) AS quedan_nissan FROM brands WHERE name = 'Nissan';
SELECT COUNT(*) AS quedan_portabicicletas FROM extras WHERE name = 'Portabicicletas';

-- Antes de borrar Económico: cuántos modelos y tarifas lo usan
SELECT c.name AS categoria,
       (SELECT COUNT(*) FROM models WHERE category_id = c.id)       AS modelos,
       (SELECT COUNT(*) FROM season_rates WHERE category_id = c.id) AS tarifas
FROM categories AS c WHERE c.name = 'Económico';

-- ⚠️ ESPERADO: ERROR 1451 (23000): Cannot delete or update a parent row:
-- a foreign key constraint fails. Ejecutar sola:
-- DELETE FROM categories WHERE name = 'Económico';

-- Op. 5 · Errores provocados (ejecutar cada una SOLA)

-- ⚠️ ESPERADO: ERROR 1062 (23000): Duplicate entry 'KWD101' for key 'vehicles.plate'
-- (caso 10: dos vehículos con la misma placa)
-- INSERT INTO vehicles (model_id, plate, model_year, color, mileage_km, branch_id)
-- VALUES (1, 'KWD101', 2025, 'Negro', 500, 1);

-- ⚠️ ESPERADO: ERROR 3819 (HY000): Check constraint 'damages_chk_1' is violated.
-- (un costo de daño negativo)
-- INSERT INTO damages (inspection_id, description, severity, repair_cost, charged_to_customer)
-- VALUES (2, 'Golpe con costo negativo', 'LEVE', -50000, TRUE);

-- ⚠️ ESPERADO: ERROR 1265 (01000): Data truncated for column 'method' at row 1
-- (FlotaYa no recibe cheques, caso 17)
-- INSERT INTO payments (contract_id, concept, amount, method, paid_at)
-- VALUES (9007, 'CIERRE', 100000, 'CHEQUE', '2026-11-23 10:00:00');
