-- =====================================================================
-- 02_dml.sql
-- Datos semilla, UPDATE/DELETE con SELECT previo, errores provocados.
-- Fecha de corte: 2026-11-10 (fija; es decir no se usa la del sistema
-- Los INSERT no escriben el id: se asigna solo, en el orden de inserción.
-- =====================================================================
USE bibliored;

-- ---------------------------------------------------------------------
-- Sedes (ids 1..5)
-- ---------------------------------------------------------------------
INSERT INTO branches (name, municipality, address, opened_on) VALUES
('Sede Central Chía', 'Chía',      'Carrera 7 # 12-30',   '2012-03-15'),
('Sede Cajicá',       'Cajicá',    'Calle 3 # 5-20',      '2015-06-10'),
('Sede Zipaquirá',    'Zipaquirá', 'Carrera 9 # 4-15',    '2017-02-20'),
('Sede Cota',         'Cota',      'Avenida Principal 22','2020-08-05'),
('Sede Tabio',        'Tabio',     'Calle 5 # 3-10',      '2026-10-01');

-- ---------------------------------------------------------------------
-- Membresías (ids 1..5: Básica, Estudiante, Docente, Infantil, Institucional)
-- ---------------------------------------------------------------------
INSERT INTO memberships (name, max_loans, loan_days, max_renewals, daily_fine, annual_fee) VALUES
('Básica',        2, 14, 1,  500.00,      0.00),
('Estudiante',    3, 14, 2,  300.00,      0.00),
('Docente',       5, 21, 2,  300.00,  30000.00),
('Infantil',      2,  7, 1,  200.00,      0.00),
('Institucional',10, 30, 3, 1000.00, 250000.00);

-- ---------------------------------------------------------------------
-- Categorías (ids 1..8; Cómic = 8 queda sin títulos)
-- ---------------------------------------------------------------------
INSERT INTO categories (name) VALUES
('Novela'), ('Cuento'), ('Poesía'), ('Historia'), ('Ciencia'), ('Infantil'), ('Referencia'), ('Cómic');

-- ---------------------------------------------------------------------
-- Empleados (ids 1..6). El 5 se inserta SIN rol para comprobar el DEFAULT.
-- ---------------------------------------------------------------------
INSERT INTO employees (full_name, email, hire_date, role, branch_id) VALUES
('Patricia Lemus',      'patricia.lemus@bibliored.test', '2012-03-15', 'COORDINADOR',   1),
('Andrés Rojas',        'andres.rojas@bibliored.test',   '2014-01-20', 'BIBLIOTECARIO', 1),
('Luisa Mora',          'luisa.mora@bibliored.test',     '2015-06-10', 'BIBLIOTECARIO', 2),
('Camilo Ortiz',        'camilo.ortiz@bibliored.test',   '2017-02-20', 'BIBLIOTECARIO', 3);

INSERT INTO employees (full_name, email, hire_date, branch_id) VALUES
('Marta Beltrán',       'marta.beltran@bibliored.test',  '2020-08-05', 4);

INSERT INTO employees (full_name, email, hire_date, role, branch_id) VALUES
('Diego Pardo',         'diego.pardo@bibliored.test',    '2026-10-01', 'AUXILIAR',      5);

-- ---------------------------------------------------------------------
-- Editoriales (ids 1..7). La 6 queda sin títulos (D1); la 7 se borra en el DELETE.
-- ---------------------------------------------------------------------
INSERT INTO publishers (name, city) VALUES
('Editorial Sabana',    'Bogotá'),
('Ediciones Andinas',   'Medellín'),
('Páramo Libros',       'Bogotá'),
('Editorial Cóndor',    'Cali'),
('Luna Nueva',          'Bogotá'),
('Casa del Sur',        'Bucaramanga'),
('Imprenta Cordillera', 'Tunja');

-- ---------------------------------------------------------------------
-- Autores (ids 1..10). El 10 queda sin títulos (D1).
-- ---------------------------------------------------------------------
INSERT INTO authors (full_name, nationality, birth_year) VALUES
('Laura Gómez Ortega',     'Colombiana', 1975),
('Mateo Herrera Ruiz',     'Colombiana', 1968),
('Elena Vargas Prieto',    'Colombiana', 1982),
('Carlos Duarte León',     'Colombiana', 1959),
('Sofía Marín Cano',       'Chilena',    1971),
('Julián Peña Torres',     'Argentina',  1964),
('Ana Lucía Roldán',       'Colombiana', 1990),
('Tomás Quiroga Bell',     'Peruana',    1955),
('Valentina Ríos Mejía',   'Colombiana', 1986),
('Ignacio Salazar Pinto',  'Española',   1949);

-- ---------------------------------------------------------------------
-- Títulos (ids 1..14). DEFAULT = costo $50.000 (D13) en los títulos 3, 5 y 9.
-- El título 14 no tiene ejemplares (D1).
-- ---------------------------------------------------------------------
INSERT INTO titles (isbn, name, publication_year, replacement_cost, category_id, publisher_id) VALUES
('978-958-0001-01-1', 'Cuentos de la Sabana',              2019, 45000.00, 2, 1),
('978-958-0001-02-8', 'Átomos para curiosos',              2020, 68000.00, 5, 3),
('978-958-0001-03-5', 'La casa del páramo',                2016, DEFAULT,  1, 2),
('978-958-0001-04-2', 'Historia breve de la Sabana',       2014, 55000.00, 4, 1),
('978-958-0001-05-9', 'Versos de la niebla',               2018, DEFAULT,  3, 3),
('978-958-0001-06-6', 'El mapa de los ríos',               2021, 52000.00, 1, 4),
('978-958-0001-07-3', 'Diccionario práctico del español',  2010, 90000.00, 7, 2),
('978-958-0001-08-0', 'Cuentos para dormir el sol',        2022, 38000.00, 6, 5),
('978-958-0001-09-7', 'El universo en una gota',           2023, DEFAULT,  5, 5),
('978-958-0001-10-3', 'Crónicas del Muisca',               2012, 60000.00, 4, 2),
('978-958-0001-11-0', 'Poemas para un jardín',             2020, 40000.00, 3, 3),
('978-958-0001-12-7', 'La ciudad sin relojes',             2024, 58000.00, 1, 4),
('978-958-0001-13-4', 'Atlas ilustrado de Colombia',       2017, 85000.00, 7, 1),
('978-958-0001-14-1', 'El cartero de las estrellas',       2025, 36000.00, 6, 1);

-- ---------------------------------------------------------------------
-- Autores por título (título, autor, orden). Títulos 1, 4 y 6 con dos autores (D2).
-- ---------------------------------------------------------------------
INSERT INTO title_authors (title_id, author_id, author_order) VALUES
(1, 1, 1), (1, 2, 2),
(2, 3, 1),
(3, 4, 1),
(4, 2, 1), (4, 6, 2),
(5, 5, 1),
(6, 7, 1), (6, 9, 2),
(7, 8, 1),
(8, 1, 1),
(9, 3, 1),
(10, 6, 1),
(11, 5, 1),
(12, 4, 1),
(13, 9, 1),
(14, 7, 1);

-- ---------------------------------------------------------------------
-- Ejemplares (ids 1..25): (código, adquirido, estado, título, sede)
-- Chía 1-9 · Cajicá 10-15 · Zipaquirá 16-20 · Cota 21-25 · Tabio ninguno.
-- Ejemplar 16 (Zipaquirá, 2011) es el más antiguo de la red.
-- Ejemplar 21 (Cota, Átomos para curiosos) está PERDIDO.
-- ---------------------------------------------------------------------
INSERT INTO copies (barcode, acquired_on, status, title_id, branch_id) VALUES
('BR-0001', '2019-05-10', 'DISPONIBLE',    1, 1),
('BR-0002', '2019-05-10', 'PRESTADO',      1, 1),
('BR-0003', '2020-09-01', 'PRESTADO',      2, 1),
('BR-0004', '2016-04-12', 'DISPONIBLE',    3, 1),
('BR-0005', '2014-07-20', 'PRESTADO',      4, 1),
('BR-0006', '2018-03-03', 'DISPONIBLE',    5, 1),
('BR-0007', '2012-05-05', 'DISPONIBLE',    7, 1),
('BR-0008', '2023-06-15', 'PRESTADO',      9, 1),
('BR-0009', '2024-02-20', 'PRESTADO',     12, 1),
('BR-0010', '2019-06-01', 'PRESTADO',      1, 2),
('BR-0011', '2016-05-01', 'PRESTADO',      3, 2),
('BR-0012', '2021-04-18', 'PRESTADO',      6, 2),
('BR-0013', '2022-08-09', 'DISPONIBLE',    8, 2),
('BR-0014', '2013-02-11', 'PRESTADO',     10, 2),
('BR-0015', '2020-11-30', 'EN_REPARACION',11, 2),
('BR-0016', '2011-03-14', 'DISPONIBLE',    4, 3),
('BR-0017', '2012-09-09', 'PRESTADO',      7, 3),
('BR-0018', '2022-08-09', 'EN_REPARACION', 8, 3),
('BR-0019', '2013-10-10', 'DISPONIBLE',   10, 3),
('BR-0020', '2017-12-01', 'PRESTADO',     13, 3),
('BR-0021', '2020-09-01', 'PERDIDO',       2, 4),
('BR-0022', '2021-01-15', 'DISPONIBLE',    2, 4),
('BR-0023', '2021-04-18', 'PRESTADO',      6, 4),
('BR-0024', '2023-06-15', 'DADO_DE_BAJA',  9, 4),
('BR-0025', '2018-02-02', 'DISPONIBLE',   13, 4);

-- ---------------------------------------------------------------------
-- Socios (ids 1..14). Ricardo (12) sin teléfono; 13 es el único de Tabio.
-- Nadie con membresía 5 (Institucional).
-- ---------------------------------------------------------------------
INSERT INTO members (document_number, first_name, last_name, email, phone, birth_date, joined_on, status, membership_id, branch_id) VALUES
('1001001001', 'Camila',    'Torres Beltrán', 'camila.torres@correo.test',   '3001110001', '2004-05-20', '2024-02-10', 'ACTIVO',     2, 1),
('1001001002', 'Juan David','Pérez Salas',    'juan.perez@correo.test',      '3001110002', '1985-09-14', '2023-05-02', 'ACTIVO',     1, 1),
('1001001003', 'Marcela',   'Ruiz Gómez',     'marcela.ruiz@correo.test',    '3001110003', '1979-01-30', '2022-08-15', 'ACTIVO',     3, 2),
('1001001004', 'Sebastián', 'Acosta Vega',    NULL,                          NULL,         '2016-03-12', '2025-03-01', 'ACTIVO',     4, 2),
('1001001005', 'Valeria',   'Castro Pinto',   NULL,                          NULL,         '2015-11-02', '2025-04-12', 'ACTIVO',     4, 1),
('1001001006', 'Óscar',     'Mendoza Leal',   'oscar.mendoza@correo.test',   '3001110006', '1990-07-07', '2023-11-20', 'SUSPENDIDO', 1, 2),
('1001001007', 'Natalia',   'Rincón Soto',    'natalia.rincon@correo.test',  '3001110007', '2003-12-01', '2024-09-05', 'ACTIVO',     2, 3),
('1001001008', 'Felipe',    'Cárdenas Mora',  'felipe.cardenas@correo.test', '3001110008', '1995-04-22', '2024-01-18', 'ACTIVO',     1, 3),
('1001001009', 'Daniela',   'Ospina Reyes',   'daniela.ospina@correo.test',  '3001110009', '1982-10-09', '2021-07-01', 'ACTIVO',     3, 1),
('1001001010', 'Héctor',    'Salgado Vega',   'hector.salgado@correo.test',  '3001110010', '1970-02-02', '2020-10-10', 'INACTIVO',   1, 4),
('1001001011', 'Lorena',    'Bautista Díaz',  'lorena.bautista@correo.test', '3001110011', '2002-06-18', '2023-03-03', 'ACTIVO',     2, 4),
('1001001012', 'Ricardo',   'Neira Cruz',     'ricardo.neira@correo.test',   NULL,         '1988-08-08', '2026-10-20', 'ACTIVO',     1, 3),
('1001001013', 'Isabel',    'Guerrero Lara',  'isabel.guerrero@correo.test', '3001110013', '2005-09-09', '2026-10-05', 'ACTIVO',     2, 5),
('1001001014', 'Pablo',     'Giraldo Ríos',   'pablo.giraldo@correo.test',   '3001110014', '2001-03-15', '2025-02-14', 'ACTIVO',     2, 1);

-- ---------------------------------------------------------------------
-- Préstamos (ids 1001..1022): (ejemplar, socio, empleado, fecha, vence, devuelto, estado)
-- vence = fecha + días de la membresía del socio.
-- 1001-1009 devueltos · 1010-1021 activos · 1022 perdido.
-- ---------------------------------------------------------------------
INSERT INTO loans (copy_id, member_id, employee_id, loaned_on, due_on, returned_on, status) VALUES
(7,  1,  1, '2026-09-02', '2026-09-16', '2026-09-15', 'DEVUELTO'),  -- 1001 a tiempo
(4,  2,  2, '2026-09-03', '2026-09-17', '2026-09-25', 'DEVUELTO'),  -- 1002 tarde 8 días
(13, 4,  3, '2026-09-08', '2026-09-15', '2026-09-14', 'DEVUELTO'),  -- 1003 a tiempo
(16, 7,  4, '2026-09-10', '2026-09-24', '2026-09-20', 'DEVUELTO'),  -- 1004 a tiempo
(1,  9,  1, '2026-09-12', '2026-10-03', '2026-10-10', 'DEVUELTO'),  -- 1005 tarde 7 días
(19, 6,  4, '2026-09-15', '2026-09-29', '2026-10-05', 'DEVUELTO'),  -- 1006 tarde 6 días
(25, 3,  5, '2026-09-20', '2026-10-11', '2026-10-13', 'DEVUELTO'),  -- 1007 tarde 2 días
(22, 14, 5, '2026-09-22', '2026-10-06', '2026-10-11', 'DEVUELTO'),  -- 1008 tarde 5 días
(6,  10, 2, '2026-09-18', '2026-10-02', '2026-10-01', 'DEVUELTO'),  -- 1009 a tiempo
(11, 6,  3, '2026-10-02', '2026-10-16', NULL,         'ACTIVO'),    -- 1010 vencido (Cajicá)
(14, 3,  3, '2026-10-05', '2026-10-26', NULL,         'ACTIVO'),    -- 1011 vencido (Cajicá)
(12, 4,  3, '2026-11-06', '2026-11-13', NULL,         'ACTIVO'),    -- 1012 al día
(10, 1,  3, '2026-10-27', '2026-11-10', NULL,         'ACTIVO'),    -- 1013 vence el día del corte
(2,  8,  2, '2026-10-27', '2026-11-10', NULL,         'ACTIVO'),    -- 1014 vence el día del corte (D7: Felipe, 1.º)
(17, 8,  4, '2026-11-02', '2026-11-16', NULL,         'ACTIVO'),    -- 1015 (D7: Felipe, 2.º; título 7 con reserva, D9)
(3,  1,  1, '2026-10-06', '2026-11-17', NULL,         'ACTIVO'),    -- 1016 con 2 renovaciones (agotó)
(8,  9,  2, '2026-10-20', '2026-12-01', NULL,         'ACTIVO'),    -- 1017 con 1 renovación
(5,  7,  1, '2026-10-15', '2026-10-29', NULL,         'ACTIVO'),    -- 1018 vencido (Chía)
(9,  9,  2, '2026-11-03', '2026-11-24', NULL,         'ACTIVO'),    -- 1019
(20, 2,  4, '2026-11-05', '2026-11-19', NULL,         'ACTIVO'),    -- 1020
(23, 5,  5, '2026-11-04', '2026-11-11', NULL,         'ACTIVO'),    -- 1021
(21, 11, 5, '2026-09-05', '2026-09-19', NULL,         'PERDIDO');   -- 1022 Átomos para curiosos perdido

-- ---------------------------------------------------------------------
-- Renovaciones (3): préstamo 1016 (dos) y 1017 (una)
-- ---------------------------------------------------------------------
INSERT INTO loan_renewals (loan_id, renewed_on, previous_due_on, new_due_on) VALUES
(1016, '2026-10-18', '2026-10-20', '2026-11-03'),
(1016, '2026-11-02', '2026-11-03', '2026-11-17'),
(1017, '2026-11-03', '2026-11-10', '2026-12-01');

-- ---------------------------------------------------------------------
-- Reservas (ids 1..7), cuatro estados.
-- 1: PENDIENTE entregable (hay ejemplar 7 DISPONIBLE del título 7 en Chía)
-- 2: PENDIENTE ya expirada (pasará a VENCIDA en el UPDATE)
-- 3 y 4: PENDIENTE en espera · 5: ATENDIDA · 6 y 7: CANCELADA (la 6 se borra)
-- ---------------------------------------------------------------------
INSERT INTO reservations (member_id, title_id, branch_id, reserved_on, expires_on, status) VALUES
(12, 7,  1, '2026-11-04', '2026-11-14', 'PENDIENTE'),
(5,  3,  2, '2026-10-01', '2026-10-08', 'PENDIENTE'),
(2,  12, 1, '2026-11-02', '2026-11-20', 'PENDIENTE'),
(3,  6,  4, '2026-11-05', '2026-11-19', 'PENDIENTE'),
(1,  5,  1, '2026-09-20', '2026-09-30', 'ATENDIDA'),
(14, 9,  5, '2026-10-12', '2026-10-22', 'CANCELADA'),
(9,  10, 3, '2026-10-15', '2026-10-25', 'CANCELADA');

-- ---------------------------------------------------------------------
-- Multas (ids 1..6): valor = días × multa por día de la membresía (regla 18)
-- 1 PAGADA (1 cuota) · 2 PAGADA (2 cuotas) · 3 PENDIENTE sin abonos (Óscar, suspendido)
-- 4 PENDIENTE con abono parcial (PERDIDA, Lorena) · 5 ANULADA · 6 PENDIENTE sin abonos (Marcela)
-- ---------------------------------------------------------------------
INSERT INTO fines (loan_id, reason, status, late_days, amount, issued_on) VALUES
(1002, 'MORA',    'PAGADA',    8,  4000.00, '2026-09-25'),
(1005, 'MORA',    'PAGADA',    7,  2100.00, '2026-10-10'),
(1006, 'MORA',    'PENDIENTE', 6,  3000.00, '2026-10-05'),
(1022, 'PERDIDA', 'PENDIENTE', 0, 68000.00, '2026-10-01'),
(1008, 'MORA',    'ANULADA',   5,  1500.00, '2026-10-11'),
(1007, 'MORA',    'PENDIENTE', 2,   600.00, '2026-10-13');

-- ---------------------------------------------------------------------
-- Cuotas de multas (4)
-- ---------------------------------------------------------------------
INSERT INTO fine_payments (fine_id, amount, paid_on, payment_method) VALUES
(1,  4000.00, '2026-09-26', 'EFECTIVO'),
(2,  1000.00, '2026-10-11', 'EFECTIVO'),
(2,  1100.00, '2026-10-15', 'TARJETA'),
(4, 20000.00, '2026-10-20', 'TRANSFERENCIA');

-- =====================================================================
-- UPDATE con SELECT previo y SELECT de comprobación
-- =====================================================================

-- U1. Un ejemplar EN_REPARACION vuelve al estante (ejemplar 15)
SELECT id, barcode, status FROM copies WHERE id = 15;
UPDATE copies SET status = 'DISPONIBLE' WHERE id = 15;
SELECT id, barcode, status FROM copies WHERE id = 15;

-- U2. Reservas PENDIENTE que expiraron antes del corte pasan a VENCIDA
-- (id > 0 permite pasar Safe Updates: el WHERE usa la clave primaria)
SELECT id, member_id, title_id, expires_on, status FROM reservations
WHERE id > 0 AND status = 'PENDIENTE' AND expires_on < '2026-11-10';
UPDATE reservations SET status = 'VENCIDA'
WHERE id > 0 AND status = 'PENDIENTE' AND expires_on < '2026-11-10';
SELECT id, member_id, title_id, expires_on, status FROM reservations ORDER BY id;

-- U3. La cuota anual de la membresía Docente sube 10 % (30.000 -> 33.000)
SELECT id, name, annual_fee FROM memberships WHERE name = 'Docente';
UPDATE memberships SET annual_fee = ROUND(annual_fee * 1.10, 2) WHERE name = 'Docente';
SELECT id, name, annual_fee FROM memberships WHERE name = 'Docente';

-- U4. Un socio registra su celular (Ricardo, id 12)
SELECT id, first_name, phone FROM members WHERE id = 12;
UPDATE members SET phone = '3105550112' WHERE id = 12;
SELECT id, first_name, phone FROM members WHERE id = 12;

-- =====================================================================
-- DELETE con SELECT previo
-- =====================================================================

-- D-a. Borrar una reserva CANCELADA (id 6)
SELECT id, member_id, title_id, status FROM reservations WHERE id = 6;
DELETE FROM reservations WHERE id = 6;
SELECT id FROM reservations WHERE id = 6;   -- debe quedar vacío

-- D-b. Borrar la editorial sin títulos (id 7). Primero comprobar que no tiene títulos:
SELECT COUNT(*) AS titulos_de_la_editorial FROM titles WHERE publisher_id = 7;   -- debe dar 0
SELECT id, name FROM publishers WHERE id = 7;
DELETE FROM publishers WHERE id = 7;
SELECT id, name FROM publishers ORDER BY id;   -- quedan 6; Casa del Sur (6) sigue sin títulos

-- =====================================================================
-- TRES ERRORES PROVOCADOS
-- =====================================================================

-- E1 (caso 9): código de barras repetido
-- ESPERADO: ERROR 1062 (23000): Duplicate entry 'BR-0001' for key 'copies.barcode'
-- Lo produce el UNIQUE de copies.barcode.
-- INSERT INTO copies (barcode, acquired_on, title_id, branch_id) VALUES ('BR-0001', '2026-11-01', 1, 1);

-- E2 (caso 12): cuota de $0
-- ESPERADO: ERROR 3819 (HY000): Check constraint 'fine_payments_chk_1' is violated.
-- Lo produce el CHECK (amount > 0) de fine_payments.
-- INSERT INTO fine_payments (fine_id, amount, paid_on, payment_method) VALUES (3, 0, '2026-11-10', 'EFECTIVO');

-- E3 (caso 15): borrar una editorial que tiene títulos
-- ESPERADO: ERROR 1451 (23000): Cannot delete or update a parent row: a foreign key constraint fails
-- Lo produce la FK titles.publisher_id -> publishers.id (sin CASCADE: regla 22).
-- DELETE FROM publishers WHERE id = 1;

-- =====================================================================
-- VERIFICACIÓN FINAL
-- =====================================================================
-- Conteo de filas por tabla (esperado entre paréntesis)
SELECT 'branches' AS tabla, COUNT(*) AS filas FROM branches            -- 5
UNION ALL SELECT 'memberships',   COUNT(*) FROM memberships            -- 5
UNION ALL SELECT 'categories',    COUNT(*) FROM categories             -- 8
UNION ALL SELECT 'employees',     COUNT(*) FROM employees              -- 6
UNION ALL SELECT 'publishers',    COUNT(*) FROM publishers             -- 6
UNION ALL SELECT 'authors',       COUNT(*) FROM authors                -- 10
UNION ALL SELECT 'titles',        COUNT(*) FROM titles                 -- 14
UNION ALL SELECT 'title_authors', COUNT(*) FROM title_authors          -- 17
UNION ALL SELECT 'copies',        COUNT(*) FROM copies                 -- 25
UNION ALL SELECT 'members',       COUNT(*) FROM members                -- 14
UNION ALL SELECT 'loans',         COUNT(*) FROM loans                  -- 22
UNION ALL SELECT 'loan_renewals', COUNT(*) FROM loan_renewals          -- 3
UNION ALL SELECT 'reservations',  COUNT(*) FROM reservations           -- 6
UNION ALL SELECT 'fines',         COUNT(*) FROM fines                  -- 6
UNION ALL SELECT 'fine_payments', COUNT(*) FROM fine_payments;         -- 4

-- Caso D14: cada ejemplar PRESTADO tiene un préstamo ACTIVO y viceversa (ambas columnas deben dar 0)
SELECT
    (SELECT COUNT(*) FROM copies c
      WHERE c.status = 'PRESTADO'
        AND NOT EXISTS (SELECT 1 FROM loans l WHERE l.copy_id = c.id AND l.status = 'ACTIVO')) AS prestados_sin_prestamo,
    (SELECT COUNT(*) FROM loans l JOIN copies c ON c.id = l.copy_id
      WHERE l.status = 'ACTIVO' AND c.status <> 'PRESTADO') AS activos_sin_ejemplar_prestado;