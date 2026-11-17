-- =====================================================================
-- Taller 2 · FlotaYa · Fase 5 · DQL avanzado
-- Funciones, procedimientos, roles y cuentas. Se ejecuta después de
-- 03_dql.sql. El script se puede repetir dos veces seguidas.
-- =====================================================================

USE flotaya;

-- =====================================================================
-- 5.1 FUNCIONES
-- =====================================================================

-- ---------------------------------------------------------------------
-- fn_prueba_1418 · MySQL exige declarar características en funciones
-- ---------------------------------------------------------------------
-- ESPERADO: ERROR 1418 (HY000): This function has none of DETERMINISTIC,
-- NO SQL, or READS SQL DATA in its declaration and binary logging is enabled
--
-- DROP FUNCTION IF EXISTS fn_prueba_1418;
-- DELIMITER $$
-- CREATE FUNCTION fn_prueba_1418()
-- RETURNS INT
-- BEGIN
--    RETURN 1;
-- END $$
-- DELIMITER ;
--
-- MySQL pide declarar si la función es determinista y si lee datos porque,
-- con el binary log activo, necesita garantizar que la función dé el mismo
-- resultado en la réplica. Sin esa promesa, rechaza crearla (1418).

-- ---------------------------------------------------------------------
-- fn_edad_conductor · años cumplidos a una fecha de referencia
-- DETERMINISTIC + NO SQL: solo calcula con sus dos parámetros, no lee
-- tablas ni el reloj del servidor y siempre da el mismo resultado.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_edad_conductor;

DELIMITER $$

CREATE FUNCTION fn_edad_conductor(p_birth_date DATE, p_reference_date DATE)
RETURNS INT
DETERMINISTIC
NO SQL
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, p_birth_date, p_reference_date);
END $$

DELIMITER ;

SELECT fn_edad_conductor('2004-07-15', '2026-07-14') AS un_dia_antes,   -- 21
       fn_edad_conductor('2004-07-15', '2026-07-15') AS el_cumple,      -- 22
       fn_edad_conductor('2004-07-15', '2026-11-23') AS al_corte;       -- 22

-- ---------------------------------------------------------------------
-- fn_valor_alquiler · regla 8, noche por noche
-- READS SQL DATA + NOT DETERMINISTIC: consulta seasons y season_rates y su
-- resultado cambia si cambian las tarifas (por ejemplo, el alza de Lujo).
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_valor_alquiler;

DELIMITER $$

CREATE FUNCTION fn_valor_alquiler(p_category_id BIGINT, p_pickup_date DATE, p_return_date DATE)
RETURNS DECIMAL(12,2)
READS SQL DATA
NOT DETERMINISTIC
BEGIN
    DECLARE v_day    DATE;
    DECLARE v_rate   DECIMAL(12,2);
    DECLARE v_total  DECIMAL(12,2) DEFAULT 0;
    DECLARE v_msg    VARCHAR(255);

    IF p_return_date <= p_pickup_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La fecha final debe ser posterior a la inicial';
    END IF;

    SET v_day = p_pickup_date;

    WHILE v_day < p_return_date DO
        SET v_rate = NULL;

        SELECT r.daily_rate INTO v_rate
        FROM seasons AS s
        JOIN season_rates AS r ON r.season_type = s.season_type
        WHERE r.category_id = p_category_id
          AND v_day BETWEEN s.start_date AND s.end_date;

        IF v_rate IS NULL THEN
            SET v_msg = CONCAT('No hay temporada o tarifa para el día ',
                               DATE_FORMAT(v_day, '%Y-%m-%d'));
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;

        SET v_total = v_total + v_rate;
        SET v_day = DATE_ADD(v_day, INTERVAL 1 DAY);
    END WHILE;

    RETURN v_total;
END $$

DELIMITER ;

-- Casos de prueba (todos deben coincidir con el enunciado)
SELECT fn_valor_alquiler(1, '2026-11-27', '2026-12-02') AS economico_diciembre,   -- 620000
       fn_valor_alquiler(5, '2026-12-18', '2026-12-23') AS van_fin_de_ano,        -- 2300000
       fn_valor_alquiler(3, '2026-10-08', '2026-10-12') AS suv_receso_octubre,    -- 1080000
       fn_valor_alquiler(6, '2026-12-14', '2026-12-16') AS lujo_con_alza;         -- 1202500

-- ESPERADO: ERROR 1644 (45000): La fecha final debe ser posterior a la inicial
-- SELECT fn_valor_alquiler(1, '2026-12-05', '2026-12-05');

-- ESPERADO: ERROR 1644 (45000): No hay temporada o tarifa para el día 2027-01-16
-- SELECT fn_valor_alquiler(1, '2027-01-14', '2027-01-18');

-- ---------------------------------------------------------------------
-- fn_licencia_vigente · regla 11
-- READS SQL DATA + NOT DETERMINISTIC: lee driver_licenses y depende de la
-- fecha y de los datos del cliente.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_licencia_vigente;

DELIMITER $$

CREATE FUNCTION fn_licencia_vigente(p_customer_id BIGINT, p_reference_date DATE)
RETURNS BOOLEAN
READS SQL DATA
NOT DETERMINISTIC
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count
    FROM driver_licenses AS dl
    WHERE dl.customer_id = p_customer_id
      AND dl.issue_date  <= p_reference_date
      AND dl.expiry_date >= p_reference_date;

    RETURN v_count > 0;
END $$

DELIMITER ;

SELECT fn_licencia_vigente(7,  '2026-11-23') AS jorge_al_corte,        -- 1
       fn_licencia_vigente(8,  '2026-11-23') AS paola_al_corte,        -- 1
       fn_licencia_vigente(8,  '2026-12-15') AS paola_15_dic,          -- 0
       fn_licencia_vigente(9,  '2026-12-15') AS esteban_15_dic,        -- 0
       fn_licencia_vigente(12, '2026-12-15') AS laura_15_dic;          -- 0

-- ---------------------------------------------------------------------
-- Uso de las funciones en consultas
-- ---------------------------------------------------------------------

-- Clientes menores de 25 años al corte
SELECT CONCAT(cu.first_name, ' ', cu.last_name)                        AS cliente,
       cu.birth_date                                                   AS nacimiento,
       fn_edad_conductor(cu.birth_date, '2026-11-23')                   AS edad,
       IF(fn_edad_conductor(cu.birth_date, '2026-11-23') >= 23, 'Sí', 'No') AS puede_suv,
       IF(fn_edad_conductor(cu.birth_date, '2026-11-23') >= 25, 'Sí', 'No') AS puede_4x4_o_van
FROM customers AS cu
WHERE fn_edad_conductor(cu.birth_date, '2026-11-23') < 25
ORDER BY edad ASC, cliente;

-- Clientes que no podrían manejar el 2026-12-15
SELECT cu.id                                                            AS id,
       CONCAT(cu.first_name, ' ', cu.last_name)                         AS cliente,
       IF(fn_licencia_vigente(cu.id, '2026-11-23'), 'Sí', 'No')          AS vigente_al_corte,
       IF(fn_licencia_vigente(cu.id, '2026-12-15'), 'Sí', 'No')          AS vigente_15_dic
FROM customers AS cu
WHERE NOT fn_licencia_vigente(cu.id, '2026-12-15')
ORDER BY cu.id;

-- =====================================================================
-- 5.2 PROCEDIMIENTOS
-- =====================================================================

-- ---------------------------------------------------------------------
-- sp_crear_reserva · valida las reglas 14 y 15 en el orden pedido
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_crear_reserva;

DELIMITER $$

CREATE PROCEDURE sp_crear_reserva(
    IN  p_customer_id      BIGINT,
    IN  p_vehicle_id       BIGINT,
    IN  p_pickup_branch_id BIGINT,
    IN  p_return_branch_id BIGINT,
    IN  p_pickup_date      DATE,
    IN  p_return_date      DATE,
    OUT p_reservation_number BIGINT
)
BEGIN
    DECLARE v_count        INT;
    DECLARE v_customer_status VARCHAR(20);
    DECLARE v_vehicle_status  VARCHAR(20);
    DECLARE v_category_id  BIGINT;
    DECLARE v_min_age      INT;
    DECLARE v_age          INT;
    DECLARE v_birth_date   DATE;
    DECLARE v_quoted       DECIMAL(12,2);
    DECLARE v_msg          VARCHAR(255);

    -- 1. El cliente existe
    SELECT COUNT(*) INTO v_count FROM customers WHERE id = p_customer_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente no existe';
    END IF;

    -- 2. El cliente no está bloqueado
    SELECT status INTO v_customer_status FROM customers WHERE id = p_customer_id;
    IF v_customer_status = 'BLOQUEADO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente está bloqueado';
    END IF;

    -- 3. La devolución es posterior a la recogida
    IF p_return_date <= p_pickup_date THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La devolución debe ser posterior a la recogida';
    END IF;

    -- 4. El vehículo existe
    SELECT COUNT(*) INTO v_count FROM vehicles WHERE id = p_vehicle_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El vehículo no existe';
    END IF;

    -- 5. El vehículo no está fuera de servicio
    SELECT status INTO v_vehicle_status FROM vehicles WHERE id = p_vehicle_id;
    IF v_vehicle_status = 'FUERA_DE_SERVICIO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El vehículo está fuera de servicio';
    END IF;

    -- 6. Ninguna reserva viva del vehículo comparte un día (regla 14)
    SELECT COUNT(*) INTO v_count
    FROM reservations AS r
    WHERE r.vehicle_id = p_vehicle_id
      AND r.status IN ('PENDIENTE', 'CONFIRMADA', 'CONVERTIDA')
      AND r.pickup_date <= p_return_date
      AND r.return_date >= p_pickup_date;

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El vehículo ya está reservado en esas fechas';
    END IF;

    -- 7. Edad mínima de la categoría el día de la recogida
    SELECT m.category_id, c.min_age
      INTO v_category_id, v_min_age
    FROM vehicles AS v
    JOIN models AS m     ON m.id = v.model_id
    JOIN categories AS c ON c.id = m.category_id
    WHERE v.id = p_vehicle_id;

    SELECT birth_date INTO v_birth_date FROM customers WHERE id = p_customer_id;
    SET v_age = fn_edad_conductor(v_birth_date, p_pickup_date);

    IF v_age < v_min_age THEN
        SET v_msg = CONCAT('El cliente tiene ', v_age,
                           ' años y la categoría exige ', v_min_age);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    -- 8. Licencia vigente hasta el día de la devolución
    IF NOT fn_licencia_vigente(p_customer_id, p_return_date) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El cliente no tiene licencia vigente durante todo el alquiler';
    END IF;

    -- Hace: registra la reserva PENDIENTE con el valor calculado
    SET v_quoted = fn_valor_alquiler(v_category_id, p_pickup_date, p_return_date);

    INSERT INTO reservations (customer_id, vehicle_id, pickup_branch_id, return_branch_id,
                              pickup_date, return_date, quoted_value, created_at, status)
    VALUES (p_customer_id, p_vehicle_id, p_pickup_branch_id, p_return_branch_id,
            p_pickup_date, p_return_date, v_quoted, '2026-11-23 08:00:00', 'PENDIENTE');

    SET p_reservation_number = LAST_INSERT_ID();
END $$

DELIMITER ;

-- Prueba 1 · Jorge Arango, Hilux HLX701, El Poblado -> El Poblado, 12-19 a 12-22
CALL sp_crear_reserva(7, 14, 3, 3, '2026-12-19', '2026-12-22', @num_reserva);
SELECT @num_reserva AS reserva_creada;

SELECT id, customer_id, vehicle_id, pickup_date, return_date, quoted_value, status
FROM reservations WHERE id = @num_reserva;
-- Esperado: reserva PENDIENTE cotizada en 1290000.00 (3 noches ALTA de 4x4)

-- ESPERADO: ERROR 1644 (45000): El vehículo ya está reservado en esas fechas
-- (prueba 2: cruce con la reserva 501 de Juliana Patiño)
-- CALL sp_crear_reserva(2, 1, 1, 1, '2026-11-30', '2026-12-04', @num_x);

-- ESPERADO: ERROR 1644 (45000): El cliente tiene 22 años y la categoría exige 23
-- (prueba 3: Juliana Patiño en una SUV)
-- CALL sp_crear_reserva(3, 13, 4, 4, '2026-12-12', '2026-12-14', @num_x);

-- ESPERADO: ERROR 1644 (45000): El cliente no tiene licencia vigente durante todo el alquiler
-- (prueba 4: la licencia de Paola Quintero vence el 2026-12-10)
-- CALL sp_crear_reserva(8, 2, 2, 2, '2026-12-08', '2026-12-12', @num_x);

-- ESPERADO: ERROR 1644 (45000): El cliente está bloqueado
-- (prueba 5: Martha Cifuentes)
-- CALL sp_crear_reserva(10, 2, 2, 2, '2026-12-01', '2026-12-03', @num_x);

-- ESPERADO: ERROR 1644 (45000): El vehículo está fuera de servicio
-- (prueba 6: KWD103)
-- CALL sp_crear_reserva(1, 3, 6, 6, '2026-12-01', '2026-12-03', @num_x);

-- ---------------------------------------------------------------------
-- sp_cerrar_contrato · regla 23 completa, sin COMMIT propio
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_cerrar_contrato;

DELIMITER $$

CREATE PROCEDURE sp_cerrar_contrato(
    IN  p_contract_id BIGINT,
    IN  p_close_date  DATE,
    OUT p_balance     DECIMAL(12,2)
)
BEGIN
    DECLARE v_count           INT;
    DECLARE v_status          VARCHAR(20);
    DECLARE v_start_date      DATE;
    DECLARE v_vehicle_id      BIGINT;
    DECLARE v_category_id     BIGINT;
    DECLARE v_real_return     DATE;
    DECLARE v_return_branch   BIGINT;
    DECLARE v_return_mileage  INT;
    DECLARE v_nights          INT;
    DECLARE v_rental          DECIMAL(12,2);
    DECLARE v_extras          DECIMAL(12,2);
    DECLARE v_damages         DECIMAL(12,2);
    DECLARE v_paid            DECIMAL(12,2);
    DECLARE v_deposit         DECIMAL(12,2);
    DECLARE v_applied         DECIMAL(12,2);

    -- 1. El contrato existe
    SELECT COUNT(*) INTO v_count FROM contracts WHERE id = p_contract_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El contrato no existe';
    END IF;

    -- 2. Está ABIERTO
    SELECT status INTO v_status FROM contracts WHERE id = p_contract_id;
    IF v_status <> 'ABIERTO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El contrato no está abierto';
    END IF;

    -- 3. Tiene la devolución registrada
    SELECT COUNT(*) INTO v_count FROM vehicle_returns WHERE contract_id = p_contract_id;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El contrato no tiene devolución registrada';
    END IF;

    -- 4. Tiene la inspección de devolución
    SELECT COUNT(*) INTO v_count
    FROM inspections
    WHERE contract_id = p_contract_id AND stage = 'DEVOLUCION';
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Falta la inspección de devolución';
    END IF;

    -- 5. La fecha de cierre es posterior al inicio
    SELECT start_date INTO v_start_date FROM contracts WHERE id = p_contract_id;
    IF p_close_date <= v_start_date THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de cierre debe ser posterior al inicio';
    END IF;

    -- Datos de devolución y del vehículo
    SELECT vehicle_id INTO v_vehicle_id FROM contracts WHERE id = p_contract_id;
    SELECT m.category_id
      INTO v_category_id
    FROM vehicles AS v
    JOIN models AS m ON m.id = v.model_id
    WHERE v.id = v_vehicle_id;

    SELECT DATE(occurred_at), branch_id, mileage_km
      INTO v_real_return, v_return_branch, v_return_mileage
    FROM vehicle_returns
    WHERE contract_id = p_contract_id;

    SET v_nights = DATEDIFF(v_real_return, v_start_date);

    -- Regla 23: alquiler recalculado con la fecha real, extras y daños
    SET v_rental = fn_valor_alquiler(v_category_id, v_start_date, v_real_return);

    SELECT COALESCE(SUM(quantity * agreed_price), 0) INTO v_extras
    FROM contract_extras WHERE contract_id = p_contract_id;

    SET v_extras = v_extras * v_nights;

    SELECT COALESCE(SUM(d.repair_cost), 0) INTO v_damages
    FROM damages AS d
    JOIN inspections AS i ON i.id = d.inspection_id
    WHERE i.contract_id = p_contract_id
      AND i.stage = 'DEVOLUCION'
      AND d.charged_to_customer = TRUE;

    SELECT COALESCE(SUM(amount), 0) INTO v_paid
    FROM payments WHERE contract_id = p_contract_id;

    SELECT amount INTO v_deposit FROM deposits WHERE contract_id = p_contract_id;

    -- El depósito se aplica a los daños o se libera
    IF v_damages > 0 THEN
        SET v_applied = LEAST(v_deposit, v_damages);

        UPDATE deposits
        SET applied_to_damages = v_applied,
            released_at        = p_close_date,
            status             = 'APLICADO'
        WHERE contract_id = p_contract_id;

        IF v_applied > 0 THEN
            INSERT INTO payments (contract_id, concept, amount, method, paid_at)
            VALUES (p_contract_id, 'DAÑOS', v_applied, 'DEPOSITO', p_close_date);
        END IF;
    ELSE
        SET v_applied = 0;

        UPDATE deposits
        SET applied_to_damages = 0,
            released_at        = p_close_date,
            status             = 'LIBERADO'
        WHERE contract_id = p_contract_id;
    END IF;

    -- Contrato cerrado y vehículo disponible en la sede de devolución
    UPDATE contracts
    SET rental_value       = v_rental,
        actual_return_date = v_real_return,
        status             = 'CERRADO'
    WHERE id = p_contract_id;

    UPDATE vehicles
    SET status     = 'DISPONIBLE',
        mileage_km = v_return_mileage,
        branch_id  = v_return_branch
    WHERE id = v_vehicle_id;

    SET p_balance = v_rental + v_extras + v_damages - v_paid - v_applied;
END $$

DELIMITER ;

-- ESPERADO: ERROR 1644 (45000): El contrato no está abierto
-- (prueba 1: el contrato 9001 ya está cerrado)
-- CALL sp_cerrar_contrato(9001, '2026-10-06', @saldo_x);

-- ESPERADO: ERROR 1644 (45000): El contrato no tiene devolución registrada
-- (prueba 2: Carlos Mejía todavía tiene el carro)
-- CALL sp_cerrar_contrato(9007, '2026-11-23', @saldo_x);

-- Prueba 3 · Devolución y cierre del Onix de Ricardo Lozano (contrato 9006)
INSERT INTO vehicle_returns (contract_id, occurred_at, mileage_km, fuel_pct, branch_id, employee_id)
VALUES (9006, '2026-11-21 10:00:00', 30910, 100, 1, 3);

INSERT INTO inspections (contract_id, stage, occurred_at, exterior_ok, interior_ok, notes, employee_id)
VALUES (9006, 'DEVOLUCION', '2026-11-21 10:10:00', TRUE, TRUE, NULL, 3);

CALL sp_cerrar_contrato(9006, '2026-11-21', @saldo_ricardo);
COMMIT;

SELECT @saldo_ricardo AS saldo_ricardo;   -- Esperado: 60000.00

SELECT ct.id, ct.status, ct.rental_value, ct.actual_return_date,
       v.plate, v.status AS estado_vehiculo, v.mileage_km, b.name AS sede,
       d.status AS estado_deposito
FROM contracts AS ct
JOIN vehicles AS v  ON v.id = ct.vehicle_id
JOIN branches AS b  ON b.id = v.branch_id
JOIN deposits AS d  ON d.contract_id = ct.id
WHERE ct.id = 9006;
-- Esperado: CERRADO · 600000.00 · 2026-11-21 · ONX301 DISPONIBLE en Calle 26
-- con 30910 km y depósito LIBERADO

-- =====================================================================
-- 5.3 USUARIOS, ROLES Y PRIVILEGIOS (regla 24)
-- Se puede repetir: borrar la base no borra cuentas ni roles, así que el
-- script las elimina antes de crearlas.
-- =====================================================================

DROP USER IF EXISTS 'asesor_flotaya'@'localhost';
DROP USER IF EXISTS 'taller_flotaya'@'localhost';
DROP USER IF EXISTS 'auditor_flotaya'@'localhost';

DROP ROLE IF EXISTS rol_asesor_flotaya;
DROP ROLE IF EXISTS rol_taller_flotaya;
DROP ROLE IF EXISTS rol_auditor_flotaya;

CREATE ROLE rol_asesor_flotaya;
CREATE ROLE rol_taller_flotaya;
CREATE ROLE rol_auditor_flotaya;

-- ---- Asesor de mostrador: reservas, clientes, vehículos y cotización ----
GRANT SELECT ON flotaya.reservations TO rol_asesor_flotaya;
GRANT UPDATE (status) ON flotaya.reservations TO rol_asesor_flotaya;
GRANT SELECT ON flotaya.customers TO rol_asesor_flotaya;
GRANT SELECT ON flotaya.vehicles TO rol_asesor_flotaya;
GRANT EXECUTE ON PROCEDURE flotaya.sp_crear_reserva TO rol_asesor_flotaya;
GRANT EXECUTE ON FUNCTION flotaya.fn_valor_alquiler TO rol_asesor_flotaya;

-- ---- Taller: mantenimientos completos y del vehículo solo lo mínimo ----
GRANT SELECT, INSERT, UPDATE ON flotaya.maintenances TO rol_taller_flotaya;
GRANT SELECT (id, plate, status, mileage_km, branch_id) ON flotaya.vehicles TO rol_taller_flotaya;
GRANT UPDATE (status) ON flotaya.vehicles TO rol_taller_flotaya;

-- ---- Auditor externo: lectura amplia, pagos sin datos sensibles ----
GRANT SELECT ON flotaya.contracts TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.reservations TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.vehicles TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.maintenances TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.vehicle_returns TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.inspections TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.damages TO rol_auditor_flotaya;
GRANT SELECT ON flotaya.deposits TO rol_auditor_flotaya;
GRANT SELECT (id, contract_id, concept, amount, paid_at) ON flotaya.payments TO rol_auditor_flotaya;

-- ---- Cuentas con su rol activo al conectarse ----
CREATE USER 'asesor_flotaya'@'localhost'  IDENTIFIED BY 'Practica_2026*';
CREATE USER 'taller_flotaya'@'localhost'  IDENTIFIED BY 'Practica_2026*';
CREATE USER 'auditor_flotaya'@'localhost' IDENTIFIED BY 'Practica_2026*';

GRANT rol_asesor_flotaya  TO 'asesor_flotaya'@'localhost';
GRANT rol_taller_flotaya  TO 'taller_flotaya'@'localhost';
GRANT rol_auditor_flotaya TO 'auditor_flotaya'@'localhost';

SET DEFAULT ROLE ALL TO 'asesor_flotaya'@'localhost';
SET DEFAULT ROLE ALL TO 'taller_flotaya'@'localhost';
SET DEFAULT ROLE ALL TO 'auditor_flotaya'@'localhost';

-- Revisión de privilegios del rol del taller
SHOW GRANTS FOR rol_taller_flotaya;

-- =====================================================================
-- PRUEBAS DE ACCESO (una conexión de Workbench por cuenta: 127.0.0.1,
-- usuario y clave Practica_2026*). Se dejan aquí como guía comentada.
-- =====================================================================
--
-- -- Como asesor_flotaya -------------------------------------------------
-- SELECT CURRENT_USER() AS usuario, CURRENT_ROLE() AS rol_activo;
-- SHOW TABLES;
--
-- -- Permitido: crear con el procedimiento y confirmar
-- CALL sp_crear_reserva(14, 13, 4, 4, '2026-12-12', '2026-12-15', @nueva);
-- SELECT @nueva AS reserva;
-- UPDATE reservations SET status = 'CONFIRMADA' WHERE id = @nueva;
--
-- -- Cotizar
-- SELECT fn_valor_alquiler(3, '2026-12-12', '2026-12-15') AS cotizacion;
--
-- -- ESPERADO: ERROR 1142 · SELECT sobre pagos no permitido
-- SELECT * FROM payments;
-- -- ESPERADO: ERROR 1142 · borrar reservas no permitido
-- DELETE FROM reservations WHERE id = @nueva;
-- -- ESPERADO: ERROR 1142 · licencias no visibles
-- SELECT COUNT(*) FROM driver_licenses;
--
-- -- Sin el rol activo, la cuenta ve menos todavía:
-- SET ROLE NONE;
-- SHOW TABLES;
-- SET ROLE ALL;
--
-- -- Como taller_flotaya --------------------------------------------------
-- SELECT CURRENT_USER() AS usuario, CURRENT_ROLE() AS rol_activo;
--
-- -- Permitido: cerrar el cambio de embrague de la HLX702
-- UPDATE maintenances
-- SET end_date = '2026-11-23', cost = 1850000
-- WHERE id = 1;
-- UPDATE vehicles SET status = 'DISPONIBLE' WHERE id = 15;
--
-- -- Permitido: registrar un mantenimiento preventivo de la SPT602
-- INSERT INTO maintenances (vehicle_id, maintenance_type, description, workshop, start_date, end_date, cost)
-- VALUES (13, 'PREVENTIVO', 'Alineación y balanceo', 'Taller FlotaYa Bogotá', '2026-11-23', '2026-11-23', 120000);
--
-- -- ESPERADO: ERROR 1142 · no puede ver todos los datos del vehículo
-- SELECT * FROM vehicles;
-- -- ESPERADO: ERROR 1143 · no puede cambiar el kilometraje
-- UPDATE vehicles SET mileage_km = 90000 WHERE id = 15;
-- -- ESPERADO: ERROR 1142 · no ve contratos
-- SELECT COUNT(*) FROM contracts;
--
-- -- Como auditor_flotaya ------------------------------------------------
-- SELECT CURRENT_USER() AS usuario, CURRENT_ROLE() AS rol_activo;
--
-- -- Permitido: pagos del contrato de Emma Walker sin el medio de pago
-- SELECT id, contract_id, concept, amount, paid_at
-- FROM payments WHERE contract_id = 9003;
--
-- -- Permitido: contar contratos por estado
-- SELECT status, COUNT(*) FROM contracts GROUP BY status;
--
-- -- ESPERADO: ERROR 1143 · no ve los últimos 4 dígitos de la tarjeta
-- SELECT card_last4 FROM payments;
-- -- ESPERADO: ERROR 1142 · no ve todos los datos de los pagos
-- SELECT * FROM payments;
-- -- ESPERADO: ERROR 1142 · no modifica datos
-- UPDATE contracts SET status = 'ABIERTO' WHERE id = 9001;
-- -- ESPERADO: ERROR 1142 · no ve clientes
-- SELECT COUNT(*) FROM customers;
--
-- =====================================================================
-- RESPUESTAS
-- =====================================================================
-- 1. El asesor creó una reserva que valida licencias sin poder leerlas
--   porque el procedimiento es SQL SECURITY DEFINER: se ejecuta con los
--   privilegios de quien lo creó (root), no con los del asesor. El asesor
--   solo tiene EXECUTE. El riesgo es la escalada de privilegios: si el
--   procedimiento devolviera datos de las licencias o aceptara SQL libre,
--   el asesor vería a través de él lo que la matriz le prohíbe. Por eso el
--   procedimiento solo valida y no muestra nada de licencias.
--
-- 2. El 1142 niega el privilegio sobre la TABLA: `SELECT *` pide todas las
--   columnas y MySQL lo resuelve como un permiso de tabla, así que la cuenta
--   que solo tiene privilegios por columna no puede usarlo. El 1143 niega
--   una COLUMNA concreta: el auditor puede leer id, contract_id, concept,
--   amount y paid_at de payments, pero al pedir card_last4 tropieza con la
--   columna prohibida. Por eso el mismo tipo de consulta da códigos distintos.
--
-- 3. Si la cuenta tiene el rol asignado pero no activo (sin DEFAULT ROLE o
--   tras SET ROLE NONE), la sesión arranca solo con USAGE: puede conectarse,
--   pero cualquier consulta falla con 1142/1143 como si no tuviera permisos.
--   Los roles se activan por sesión; por eso el script usa SET DEFAULT ROLE.