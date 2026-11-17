-- =====================================================================
-- 05_tcl.sql
-- =====================================================================

USE bibliored;

-- =====================================================================
-- T1 · El ejemplar sin ficha
-- =====================================================================

-- Estado del ejemplar ANTES de la llamada (debe ser DISPONIBLE)
SELECT id, barcode, status AS estado_antes_de_la_llamada FROM copies WHERE id = 4;

-- ---- Paso 1: SIN transacción ----
-- ⚠️ ESPERADO: ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
--   (loans.employee_id -> employees.id). El empleado 999 no existe.
-- CALL sp_prestar_ejemplar(4, 12, 999, '2026-11-10', @prestamo);

-- Estado del ejemplar DESPUÉS del error (si ejecutaste la llamada: queda PRESTADO)
SELECT id, barcode, status AS estado_despues_del_error FROM copies WHERE id = 4;

-- Ejemplares PRESTADO que no tienen un préstamo ACTIVO (violación de la regla 12)
-- Si ejecutaste la llamada fallida, aparece el ejemplar 4. Si no, devuelve 0 filas.
SELECT c.id, c.barcode, c.status
FROM copies c
WHERE c.status = 'PRESTADO'
  AND NOT EXISTS (SELECT 1 FROM loans l WHERE l.copy_id = c.id AND l.status = 'ACTIVO');

-- Corrección: UPDATE con su SELECT previo (filtra por la clave primaria por Safe Updates)
SELECT id, barcode, status FROM copies WHERE id = 4 AND status = 'PRESTADO';
UPDATE copies SET status = 'DISPONIBLE' WHERE id = 4 AND status = 'PRESTADO';
SELECT id, barcode, status AS estado_tras_la_correccion FROM copies WHERE id = 4;

-- ---- Paso 2: CON transacción ----
START TRANSACTION;
-- ⚠️ ESPERADO: ERROR 1452 (23000): igual que en el paso 1
-- CALL sp_prestar_ejemplar(4, 12, 999, '2026-11-10', @prestamo);
-- Dentro de la transacción (si ejecutaste la llamada: PRESTADO; el UPDATE del ejemplar aún no se confirmó)
SELECT id, barcode, status AS estado_dentro_de_la_transaccion FROM copies WHERE id = 4;
ROLLBACK;
-- Después del ROLLBACK: DISPONIBLE otra vez
SELECT id, barcode, status AS estado_despues_del_rollback FROM copies WHERE id = 4;

-- Pregunta: ¿por qué en el paso 1 no se deshizo solo el cambio del ejemplar si el procedimiento falló?
-- Respuesta: porque no había transacción abierta y MySQL trabaja en autocommit. El UPDATE del ejemplar
-- fue una sentencia que terminó bien y quedó confirmada sola, en ese mismo instante. El error llegó
-- después, en el INSERT del préstamo, y solo deshace esa sentencia fallida (no las anteriores).
-- Un procedimiento no es atómico por sí mismo: sin START TRANSACTION no existe un "todo o nada".

-- =====================================================================
-- T2 · sp_prestar_ejemplar_tx: todo o nada
-- =====================================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_prestar_ejemplar_tx $$
CREATE PROCEDURE sp_prestar_ejemplar_tx(
    IN  p_copy_id BIGINT,
    IN  p_member_id BIGINT,
    IN  p_employee_id BIGINT,
    IN  p_loaned_on DATE,
    OUT p_loan_id BIGINT
)
BEGIN
    -- Cualquier error (de negocio o de MySQL): deshace todo y relanza EL MISMO error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    CALL sp_prestar_ejemplar(p_copy_id, p_member_id, p_employee_id, p_loaned_on, p_loan_id);
    COMMIT;
END $$

DELIMITER ;

-- Evidencia ANTES de las tres llamadas
SELECT COUNT(*) AS prestamos_antes, MAX(id) AS ultimo_prestamo_antes FROM loans;

-- Caso 1: el empleado no existe => falla con el error de la base; el ejemplar sigue DISPONIBLE
-- ⚠️ ESPERADO: ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
-- CALL sp_prestar_ejemplar_tx(4, 12, 999, '2026-11-10', @prestamo);
SELECT id, barcode, status AS estado_tras_el_caso_1 FROM copies WHERE id = 4;   -- DISPONIBLE

-- Caso 2: el ejemplar 2 está PRESTADO
-- ⚠️ ESPERADO: ERROR 1644 (45000): El ejemplar no está disponible: PRESTADO
-- CALL sp_prestar_ejemplar_tx(2, 12, 2, '2026-11-10', @prestamo);

-- Caso 3: préstamo correcto con un empleado que sí existe (2)
CALL sp_prestar_ejemplar_tx(4, 12, 2, '2026-11-10', @prestamo);
SELECT @prestamo AS prestamo_del_caso_3;
SELECT id, barcode, status AS estado_tras_el_caso_3 FROM copies WHERE id = 4;   -- PRESTADO

-- Evidencia DESPUÉS de las tres llamadas
SELECT COUNT(*) AS prestamos_despues, MAX(id) AS ultimo_prestamo_despues FROM loans;

-- Comprobación final (regla 12): la cantidad de PRESTADO debe ser igual a la de ACTIVO
SELECT (SELECT COUNT(*) FROM copies WHERE status = 'PRESTADO') AS ejemplares_prestados,
       (SELECT COUNT(*) FROM loans WHERE status = 'ACTIVO')     AS prestamos_activos;

-- Pregunta: ¿por qué el número del préstamo del caso 3 no es el siguiente al último préstamo que existía?
-- Respuesta: porque el contador AUTO_INCREMENT de InnoDB NO se devuelve con un ROLLBACK ni con un INSERT fallido. 

-- Cada intento de INSERT en loans (incluidos los que fallaron por la FK del empleado en T1 y en el caso 1) reservó un número que quedó "gastado".
-- Por eso el préstamo del caso 3 sale con un número mayor que MAX(id)+1: hay huecos en la numeración, pero los ids siguen siendo únicos.