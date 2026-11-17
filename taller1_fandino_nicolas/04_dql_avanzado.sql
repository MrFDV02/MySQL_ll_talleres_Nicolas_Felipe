-- =====================================================================
-- 04_dql_avanzado.sql
-- =====================================================================
USE bibliored;

DELIMITER $$

-- ---------------------------------------------------------------------
-- sp_resumen_socio: préstamos activos y saldo pendiente de un socio
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_resumen_socio $$
CREATE PROCEDURE sp_resumen_socio(
    IN  p_member_id BIGINT,
    OUT p_prestamos_activos INT,
    OUT p_saldo_pendiente DECIMAL(12,2)
)
BEGIN
    DECLARE v_found INT DEFAULT 0;

    SELECT COUNT(*) INTO v_found FROM members WHERE id = p_member_id;
    IF v_found = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio no existe';
    END IF;

    SELECT COUNT(*) INTO p_prestamos_activos
    FROM loans
    WHERE member_id = p_member_id AND status = 'ACTIVO';

    -- saldo = valor de cada multa PENDIENTE menos lo abonado
    SELECT IFNULL(SUM(f.amount - IFNULL(p.pagado, 0)), 0) INTO p_saldo_pendiente
    FROM fines f
    JOIN loans l ON l.id = f.loan_id
    LEFT JOIN (SELECT fine_id, SUM(amount) AS pagado
               FROM fine_payments
               GROUP BY fine_id) p ON p.fine_id = f.id
    WHERE l.member_id = p_member_id AND f.status = 'PENDIENTE';
END $$

-- ---------------------------------------------------------------------
-- sp_prestar_ejemplar: valida en orden y registra el préstamo
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_prestar_ejemplar $$
CREATE PROCEDURE sp_prestar_ejemplar(
    IN  p_copy_id BIGINT,
    IN  p_member_id BIGINT,
    IN  p_employee_id BIGINT,
    IN  p_loaned_on DATE,
    OUT p_loan_id BIGINT
)
BEGIN
    DECLARE v_found INT DEFAULT 0;
    DECLARE v_member_status VARCHAR(20);
    DECLARE v_membership_id BIGINT;
    DECLARE v_copy_status VARCHAR(20);
    DECLARE v_pending INT DEFAULT 0;
    DECLARE v_active INT DEFAULT 0;
    DECLARE v_max_loans INT;
    DECLARE v_loan_days INT;
    DECLARE v_msg VARCHAR(200);

    -- 1. El socio existe
    SELECT COUNT(*) INTO v_found FROM members WHERE id = p_member_id;
    IF v_found = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio no existe';
    END IF;

    -- 2. El socio está ACTIVO
    SELECT status, membership_id INTO v_member_status, v_membership_id
    FROM members WHERE id = p_member_id;
    IF v_member_status <> 'ACTIVO' THEN
        SET v_msg = CONCAT('El socio no está activo: ', v_member_status);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    -- 3. El ejemplar existe
    SELECT COUNT(*) INTO v_found FROM copies WHERE id = p_copy_id;
    IF v_found = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El ejemplar no existe';
    END IF;

    -- 4. El ejemplar está DISPONIBLE
    SELECT status INTO v_copy_status FROM copies WHERE id = p_copy_id;
    IF v_copy_status <> 'DISPONIBLE' THEN
        SET v_msg = CONCAT('El ejemplar no está disponible: ', v_copy_status);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    -- 5. El socio no tiene multas PENDIENTE
    SELECT COUNT(*) INTO v_pending
    FROM fines f
    JOIN loans l ON l.id = f.loan_id
    WHERE l.member_id = p_member_id AND f.status = 'PENDIENTE';
    IF v_pending > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio tiene multas pendientes';
    END IF;

    -- 6. El socio no ha llegado al tope de su membresía
    SELECT max_loans, loan_days INTO v_max_loans, v_loan_days
    FROM memberships WHERE id = v_membership_id;
    SELECT COUNT(*) INTO v_active
    FROM loans WHERE member_id = p_member_id AND status = 'ACTIVO';
    IF v_active >= v_max_loans THEN
        SET v_msg = CONCAT('El socio alcanzó su tope de ', v_max_loans, ' préstamos');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    -- Todo bien: PRIMERO el ejemplar, DESPUÉS el préstamo (el empleado lo valida la FK)
    UPDATE copies SET status = 'PRESTADO' WHERE id = p_copy_id;
    INSERT INTO loans (copy_id, member_id, employee_id, loaned_on, due_on)
    VALUES (p_copy_id, p_member_id, p_employee_id, p_loaned_on,
            DATE_ADD(p_loaned_on, INTERVAL v_loan_days DAY));
    SET p_loan_id = LAST_INSERT_ID();
END $$

-- ---------------------------------------------------------------------
-- sp_devolver_ejemplar: devuelve y genera multa por mora si aplica
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_devolver_ejemplar $$
CREATE PROCEDURE sp_devolver_ejemplar(
    IN  p_loan_id BIGINT,
    IN  p_returned_on DATE,
    OUT p_fine_amount DECIMAL(12,2)
)
BEGIN
    DECLARE v_found INT DEFAULT 0;
    DECLARE v_status VARCHAR(20);
    DECLARE v_loaned_on DATE;
    DECLARE v_due_on DATE;
    DECLARE v_copy_id BIGINT;
    DECLARE v_daily_fine DECIMAL(10,2);
    DECLARE v_late_days INT DEFAULT 0;

    SELECT COUNT(*) INTO v_found FROM loans WHERE id = p_loan_id;
    IF v_found = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El préstamo no existe';
    END IF;

    SELECT l.status, l.loaned_on, l.due_on, l.copy_id, ms.daily_fine
      INTO v_status, v_loaned_on, v_due_on, v_copy_id, v_daily_fine
    FROM loans l
    JOIN members m      ON m.id = l.member_id
    JOIN memberships ms ON ms.id = m.membership_id
    WHERE l.id = p_loan_id;

    IF v_status <> 'ACTIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El préstamo no está activo';
    END IF;

    IF p_returned_on < v_loaned_on THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de devolución es anterior al préstamo';
    END IF;

    -- Mora calculada con la fecha de devolución recibida (nunca con la fecha del sistema)
    SET v_late_days = GREATEST(DATEDIFF(p_returned_on, v_due_on), 0);
    SET p_fine_amount = v_late_days * v_daily_fine;

    IF v_late_days > 0 AND p_fine_amount > 0 THEN
        INSERT INTO fines (loan_id, reason, late_days, amount, issued_on)
        VALUES (p_loan_id, 'MORA', v_late_days, p_fine_amount, p_returned_on);
    END IF;

    UPDATE loans SET status = 'DEVUELTO', returned_on = p_returned_on WHERE id = p_loan_id;
    UPDATE copies SET status = 'DISPONIBLE' WHERE id = v_copy_id;
END $$

-- ---------------------------------------------------------------------
-- sp_renovar_prestamo: valida en orden y registra la renovación
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_renovar_prestamo $$
CREATE PROCEDURE sp_renovar_prestamo(
    IN  p_loan_id BIGINT,
    IN  p_renewed_on DATE,
    OUT p_new_due_on DATE
)
BEGIN
    DECLARE v_found INT DEFAULT 0;
    DECLARE v_status VARCHAR(20);
    DECLARE v_due_on DATE;
    DECLARE v_title_id BIGINT;
    DECLARE v_max_renewals INT;
    DECLARE v_loan_days INT;
    DECLARE v_renewals_used INT DEFAULT 0;
    DECLARE v_reservations INT DEFAULT 0;
    DECLARE v_msg VARCHAR(200);

    -- 1. El préstamo existe
    SELECT COUNT(*) INTO v_found FROM loans WHERE id = p_loan_id;
    IF v_found = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El préstamo no existe';
    END IF;

    SELECT l.status, l.due_on, c.title_id, ms.max_renewals, ms.loan_days
      INTO v_status, v_due_on, v_title_id, v_max_renewals, v_loan_days
    FROM loans l
    JOIN copies c       ON c.id = l.copy_id
    JOIN members m      ON m.id = l.member_id
    JOIN memberships ms ON ms.id = m.membership_id
    WHERE l.id = p_loan_id;

    -- 2. Está ACTIVO
    IF v_status <> 'ACTIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El préstamo no está activo';
    END IF;

    -- 3. No está vencido (regla 13: vencido = fecha de referencia posterior al vencimiento)
    IF p_renewed_on > v_due_on THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El préstamo está vencido: primero debe devolverse';
    END IF;

    -- 4. No agotó las renovaciones de la membresía
    SELECT COUNT(*) INTO v_renewals_used FROM loan_renewals WHERE loan_id = p_loan_id;
    IF v_renewals_used >= v_max_renewals THEN
        SET v_msg = CONCAT('El préstamo ya usó sus ', v_max_renewals, ' renovaciones');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    -- 5. Nadie tiene una reserva PENDIENTE de ese título (en cualquier sede)
    SELECT COUNT(*) INTO v_reservations
    FROM reservations WHERE title_id = v_title_id AND status = 'PENDIENTE';
    IF v_reservations > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hay reservas pendientes para este título';
    END IF;

    -- Todo bien: nuevo vencimiento = vencimiento actual + días de la membresía
    SET p_new_due_on = DATE_ADD(v_due_on, INTERVAL v_loan_days DAY);
    INSERT INTO loan_renewals (loan_id, renewed_on, previous_due_on, new_due_on)
    VALUES (p_loan_id, p_renewed_on, v_due_on, p_new_due_on);
    UPDATE loans SET due_on = p_new_due_on WHERE id = p_loan_id;
END $$

-- ---------------------------------------------------------------------
-- sp_reporte_sedes: una fila por sede, recorriendo las sedes con un cursor
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_reporte_sedes $$
CREATE PROCEDURE sp_reporte_sedes(IN p_cutoff DATE)
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_branch_id BIGINT;
    DECLARE v_branch_name VARCHAR(100);
    DECLARE v_copies INT;
    DECLARE v_loaned INT;
    DECLARE v_overdue INT;
    DECLARE cur_branches CURSOR FOR SELECT id, name FROM branches ORDER BY id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    DROP TEMPORARY TABLE IF EXISTS tmp_reporte_sedes;
    CREATE TEMPORARY TABLE tmp_reporte_sedes (
        sede VARCHAR(100),
        ejemplares INT,
        prestados INT,
        vencidos INT,
        ocupacion_pct DECIMAL(5,2)
    );

    OPEN cur_branches;
    read_loop: LOOP
        FETCH cur_branches INTO v_branch_id, v_branch_name;
        IF v_done = 1 THEN
            LEAVE read_loop;
        END IF;

        -- ejemplares en circulación (sin perdidos ni dados de baja)
        SELECT COUNT(*) INTO v_copies
        FROM copies
        WHERE branch_id = v_branch_id AND status NOT IN ('PERDIDO', 'DADO_DE_BAJA');

        -- préstamos activos de los ejemplares de la sede
        SELECT COUNT(*) INTO v_loaned
        FROM loans l JOIN copies c ON c.id = l.copy_id
        WHERE c.branch_id = v_branch_id AND l.status = 'ACTIVO';

        -- vencidos a la fecha de corte
        SELECT COUNT(*) INTO v_overdue
        FROM loans l JOIN copies c ON c.id = l.copy_id
        WHERE c.branch_id = v_branch_id AND l.status = 'ACTIVO' AND l.due_on < p_cutoff;

        -- sin ejemplares: ocupación vacía (NULL), sin dividir por cero
        IF v_copies = 0 THEN
            INSERT INTO tmp_reporte_sedes VALUES (v_branch_name, v_copies, v_loaned, v_overdue, NULL);
        ELSE
            INSERT INTO tmp_reporte_sedes
            VALUES (v_branch_name, v_copies, v_loaned, v_overdue, ROUND(v_loaned * 100 / v_copies, 2));
        END IF;
    END LOOP;
    CLOSE cur_branches;

    SELECT sede, ejemplares, prestados, vencidos, ocupacion_pct
    FROM tmp_reporte_sedes
    ORDER BY ocupacion_pct DESC, sede;

    DROP TEMPORARY TABLE tmp_reporte_sedes;
END $$

-- ---------------------------------------------------------------------
-- sp_pagar_multa: registra una cuota; el medio de pago lo rechaza la base
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_pagar_multa $$
CREATE PROCEDURE sp_pagar_multa(
    IN  p_fine_id BIGINT,
    IN  p_amount DECIMAL(12,2),
    IN  p_payment_method VARCHAR(20),
    IN  p_paid_on DATE,
    OUT p_balance DECIMAL(12,2)
)
BEGIN
    DECLARE v_found INT DEFAULT 0;
    DECLARE v_status VARCHAR(20);
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_paid DECIMAL(12,2);
    DECLARE v_saldo DECIMAL(12,2);

    -- 1265 = "Data truncated": error de MySQL al guardar un valor que no está en el ENUM
    DECLARE EXIT HANDLER FOR 1265
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Medio de pago no válido: use EFECTIVO, TARJETA o TRANSFERENCIA';

    SELECT COUNT(*) INTO v_found FROM fines WHERE id = p_fine_id;
    IF v_found = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no existe';
    END IF;

    SELECT status, amount INTO v_status, v_total FROM fines WHERE id = p_fine_id;
    IF v_status <> 'PENDIENTE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La multa no está pendiente';
    END IF;

    SELECT IFNULL(SUM(amount), 0) INTO v_paid FROM fine_payments WHERE fine_id = p_fine_id;
    SET v_saldo = v_total - v_paid;
    IF p_amount <= 0 OR p_amount > v_saldo THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El abono debe ser mayor que 0 y no superar el saldo';
    END IF;

    INSERT INTO fine_payments (fine_id, amount, paid_on, payment_method)
    VALUES (p_fine_id, p_amount, p_paid_on, p_payment_method);

    SET p_balance = v_saldo - p_amount;
    IF p_balance = 0 THEN
        UPDATE fines SET status = 'PAGADA' WHERE id = p_fine_id;
    END IF;
END $$

DELIMITER ;

-- =====================================================================
-- PRUEBAS · sp_resumen_socio
-- =====================================================================
-- Prueba 1: Óscar (6), SUSPENDIDO de D4: 1 préstamo activo (1010) y saldo 3.000 (multa 3 sin abonos)
CALL sp_resumen_socio(6, @activos, @saldo);
SELECT @activos AS prestamos_activos, @saldo AS saldo_pendiente;

-- Prueba 2: Felipe (8): 2 préstamos activos y ninguna multa => saldo 0.00
CALL sp_resumen_socio(8, @activos, @saldo);
SELECT @activos AS prestamos_activos, @saldo AS saldo_pendiente;

-- Prueba 3: socio que no existe
-- ESPERADO: ERROR 1644 (45000): El socio no existe
-- CALL sp_resumen_socio(999, @activos, @saldo);

-- =====================================================================
-- PRUEBAS · sp_prestar_ejemplar (fecha 2026-11-10)
-- =====================================================================
-- Prueba 1: Isabel (13) no tiene préstamos ni multas; ejemplar 6 está DISPONIBLE.
-- Vencimiento esperado: 2026-11-24 (Estudiante = 14 días)
CALL sp_prestar_ejemplar(6, 13, 6, '2026-11-10', @prestamo);
SELECT @prestamo AS prestamo_creado;
SELECT l.id, l.copy_id, l.loaned_on, l.due_on, l.status, c.status AS estado_ejemplar
FROM loans l JOIN copies c ON c.id = l.copy_id WHERE l.id = @prestamo;

-- Prueba 2: Óscar (6) está SUSPENDIDO (y además debe una multa): gana la validación 2
-- ESPERADO: ERROR 1644 (45000): El socio no está activo: SUSPENDIDO
-- CALL sp_prestar_ejemplar(4, 6, 2, '2026-11-10', @prestamo);

-- Prueba 3: Ricardo (12), activo, pide el ejemplar 2 que está PRESTADO
-- ESPERADO: ERROR 1644 (45000): El ejemplar no está disponible: PRESTADO
-- CALL sp_prestar_ejemplar(2, 12, 2, '2026-11-10', @prestamo);

-- Prueba 4: Marcela (3), activa, con una multa pendiente, pide el ejemplar 13 (DISPONIBLE)
-- ESPERADO: ERROR 1644 (45000): El socio tiene multas pendientes
-- CALL sp_prestar_ejemplar(13, 3, 3, '2026-11-10', @prestamo);

-- Prueba 5: Felipe (8, D7, Básica con 2 activos) pide el ejemplar 13 (DISPONIBLE)
-- ESPERADO: ERROR 1644 (45000): El socio alcanzó su tope de 2 préstamos
-- CALL sp_prestar_ejemplar(13, 8, 2, '2026-11-10', @prestamo);

-- Prueba 6: Ricardo (12), activo, pide un ejemplar que no existe
-- ESPERADO: ERROR 1644 (45000): El ejemplar no existe
-- CALL sp_prestar_ejemplar(9999, 12, 2, '2026-11-10', @prestamo);

-- =====================================================================
-- PRUEBAS · sp_devolver_ejemplar
-- =====================================================================
-- Prueba 1: el préstamo más atrasado de Q-02 es el 1010 (25 días × 500 = 12.500)
CALL sp_devolver_ejemplar(1010, '2026-11-10', @multa);
SELECT @multa AS multa_generada;
SELECT id, loan_id, reason, late_days, amount, status FROM fines ORDER BY id DESC LIMIT 1;

-- Prueba 2: el préstamo 1012 (vence 2026-11-13) aún no vence: multa 0.00 y ninguna multa nueva
CALL sp_devolver_ejemplar(1012, '2026-11-10', @multa);
SELECT @multa AS multa_generada;
SELECT COUNT(*) AS multas_del_prestamo_1012 FROM fines WHERE loan_id = 1012;

-- Prueba 3: devolver un préstamo ya DEVUELTO (1001)
-- ESPERADO: ERROR 1644 (45000): El préstamo no está activo
-- CALL sp_devolver_ejemplar(1001, '2026-11-10', @multa);

-- Prueba 4: préstamo activo (1018, prestado el 2026-10-15) con devolución anterior
-- ESPERADO: ERROR 1644 (45000): La fecha de devolución es anterior al préstamo
-- CALL sp_devolver_ejemplar(1018, '2026-10-01', @multa);

-- =====================================================================
-- PRUEBAS · sp_renovar_prestamo (fecha 2026-11-10)
-- =====================================================================
-- Prueba 1: préstamo 1017 (Daniela, Docente): activo, al día (vence 2026-12-01),
-- 1 de 2 renovaciones usadas y su título no tiene reservas. Nuevo vencimiento = 2026-12-22
CALL sp_renovar_prestamo(1017, '2026-11-10', @nuevo_vence);
SELECT @nuevo_vence AS nuevo_vencimiento;
SELECT * FROM loan_renewals WHERE loan_id = 1017 ORDER BY id;

-- Prueba 2: préstamo 1016 (D8): ya usó sus 2 renovaciones y no está vencido
-- ESPERADO: ERROR 1644 (45000): El préstamo ya usó sus 2 renovaciones
-- CALL sp_renovar_prestamo(1016, '2026-11-10', @nuevo_vence);

-- Prueba 3: préstamo 1011 (activo y vencido desde 2026-10-26)
-- ESPERADO: ERROR 1644 (45000): El préstamo está vencido: primero debe devolverse
-- CALL sp_renovar_prestamo(1011, '2026-11-10', @nuevo_vence);

-- Prueba 4: préstamo 1015 (D9): título 7 con reserva PENDIENTE de Ricardo
-- ESPERADO: ERROR 1644 (45000): Hay reservas pendientes para este título
-- CALL sp_renovar_prestamo(1015, '2026-11-10', @nuevo_vence);

-- =====================================================================
-- PRUEBAS · sp_reporte_sedes
-- =====================================================================
-- Prueba 1: reporte al corte. 5 filas, una por sede; los vencidos (1011 en Cajicá y 1018 en Chía)
-- son los que siguen activos de Q-02 (el 1010 ya se devolvió en la prueba de sp_devolver_ejemplar).
CALL sp_reporte_sedes('2026-11-10');
-- Prueba 2: la Sede Tabio sale con 0 | 0 | 0 y ocupacion_pct vacía (NULL), sin error de división por cero
--          (aparece en la última fila del reporte anterior).

-- =====================================================================
-- PRUEBAS · sp_pagar_multa
-- =====================================================================
-- Prueba 1: Marcela (3) paga completa su única multa (id 6, 600) en EFECTIVO => saldo 0.00, multa PAGADA
CALL sp_pagar_multa(6, 600.00, 'EFECTIVO', '2026-11-10', @saldo);
SELECT @saldo AS saldo_restante;
SELECT id, status FROM fines WHERE id = 6;

-- Prueba 2: Marcela repite el préstamo de la prueba 4 de sp_prestar_ejemplar: ahora sí se presta
CALL sp_prestar_ejemplar(13, 3, 3, '2026-11-10', @prestamo);
SELECT @prestamo AS prestamo_creado;

-- Prueba 3: abono parcial con TARJETA a la multa 4 (Lorena, ya tenía 20.000): 68.000 - 20.000 - 10.000 = 38.000
CALL sp_pagar_multa(4, 10000.00, 'TARJETA', '2026-11-10', @saldo);
SELECT @saldo AS saldo_restante;

-- Prueba 4: abonar a una multa PAGADA (la 1)
-- ESPERADO: ERROR 1644 (45000): La multa no está pendiente
-- CALL sp_pagar_multa(1, 100.00, 'EFECTIVO', '2026-11-10', @saldo);

-- Prueba 5: abonar más que el saldo de una multa pendiente (la 3 debe 3.000)
-- ESPERADO: ERROR 1644 (45000): El abono debe ser mayor que 0 y no superar el saldo
-- CALL sp_pagar_multa(3, 20000.00, 'EFECTIVO', '2026-11-10', @saldo);

-- Prueba 6: pagar con 'CHEQUE' (lo rechaza el ENUM con el error 1265 y el handler lo convierte)
-- ESPERADO: ERROR 1644 (45000): Medio de pago no válido: use EFECTIVO, TARJETA o TRANSFERENCIA
-- CALL sp_pagar_multa(3, 1000.00, 'CHEQUE', '2026-11-10', @saldo);

-- =====================================================================
-- Rutinas de la base: deben aparecer los 6 procedimientos
-- =====================================================================
SELECT routine_name AS rutina, routine_type AS tipo
FROM information_schema.routines
WHERE routine_schema = 'bibliored'
ORDER BY routine_name;