-- =====================================================================
-- 05_tcl.sql
-- =====================================================================

USE flotaya;


-- 6.1 · Cierre del contrato de Paola Quintero (con SAVEPOINT)

START TRANSACTION;

-- Estado inicial
SELECT ct.id             AS contrato,
       ct.status         AS estado,
       ct.rental_value   AS alquiler,
       v.plate           AS placa,
       v.status          AS estado_vehiculo,
       d.status          AS estado_deposito,
       (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE contract_id = 9005) AS pagado
FROM contracts AS ct
JOIN vehicles AS v ON v.id = ct.vehicle_id
JOIN deposits AS d ON d.contract_id = ct.id
WHERE ct.id = 9005;

-- 1. Devolución: 09:30, 12.480 km, tanque lleno, la recibe Carolina Zapata
INSERT INTO vehicle_returns (contract_id, occurred_at, mileage_km, fuel_pct, branch_id, employee_id)
VALUES (9005, '2026-11-23 09:30:00', 12480, 100, 2, 9);

-- Inspección de devolución: 09:40, exterior con novedad
INSERT INTO inspections (contract_id, stage, occurred_at, exterior_ok, interior_ok, notes, employee_id)
VALUES (9005, 'DEVOLUCION', '2026-11-23 09:40:00', FALSE, TRUE,
        'Rin delantero izquierdo rayado', 9);

-- 2. Guardar el número de la inspección ANTES de seguir
SET @v_inspeccion_paola = LAST_INSERT_ID();
SELECT @v_inspeccion_paola AS inspeccion_devolucion;

-- 3. Punto de guardado
SAVEPOINT antes_dano;

-- 4. Daño registrado por error en 3.800.000
INSERT INTO damages (inspection_id, description, severity, repair_cost, charged_to_customer)
VALUES (@v_inspeccion_paola, 'Rin delantero izquierdo rayado', 'LEVE', 3800000, TRUE);

SELECT id, description, severity, repair_cost
FROM damages WHERE inspection_id = @v_inspeccion_paola;

-- 5. Deshacer SOLO ese error y registrar el daño correcto (380.000)
ROLLBACK TO SAVEPOINT antes_dano;

INSERT INTO damages (inspection_id, description, severity, repair_cost, charged_to_customer)
VALUES (@v_inspeccion_paola, 'Rin delantero izquierdo rayado', 'LEVE', 380000, TRUE);

SELECT id, description, severity, repair_cost
FROM damages WHERE inspection_id = @v_inspeccion_paola;

-- 6. Cerrar el contrato
CALL sp_cerrar_contrato(9005, '2026-11-23', @saldo_paola);
SELECT @saldo_paola AS saldo_del_cierre;   -- Esperado: 750000.00

-- 7. Cobrar el saldo con tarjeta y confirmar
INSERT INTO payments (contract_id, concept, amount, method, paid_at, card_last4, authorization_code)
VALUES (9005, 'CIERRE', @saldo_paola, 'TARJETA', '2026-11-23 10:00:00', '3307', 'AUT-580114');

-- Estado final
SELECT ct.id           AS contrato,
       ct.status       AS estado,
       ct.rental_value AS alquiler,
       v.plate         AS placa,
       v.status        AS estado_vehiculo,
       v.mileage_km    AS kilometraje,
       b.name          AS sede,
       d.status        AS estado_deposito,
       d.applied_to_damages AS aplicado_a_danos,
       (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE contract_id = 9005) AS pagado,
       (SELECT COUNT(*) FROM damages WHERE inspection_id = @v_inspeccion_paola) AS danos_en_la_inspeccion,
       (SELECT GROUP_CONCAT(concept ORDER BY id) FROM payments WHERE contract_id = 9005) AS conceptos
FROM contracts AS ct
JOIN vehicles AS v ON v.id = ct.vehicle_id
JOIN branches AS b ON b.id = v.branch_id
JOIN deposits AS d ON d.contract_id = ct.id
WHERE ct.id = 9005;

COMMIT;

-- Pregunta: ¿qué habría pasado si el segundo daño se registraba con el
-- último id generado (LAST_INSERT_ID()) en lugar de la variable del paso 2?
-- Respuesta: LAST_INSERT_ID() ya apuntaría al id del daño equivocado, así
-- que el daño "bueno" habría quedado colgado del daño (inspection_id
-- inexistente) y la inspección de Paola se habría quedado con el daño de
-- 3.800.000, o el INSERT habría fallado por la FK. La variable guardada
-- antes del savepoint es la que sobrevive al ROLLBACK.


-- 6.2 · Un cierre que debe deshacerse completo (Carlos Mejía)


START TRANSACTION;

-- Estado inicial
SELECT ct.id AS contrato, ct.status AS estado, ct.rental_value AS alquiler,
       v.plate AS placa, v.status AS estado_vehiculo, d.status AS estado_deposito
FROM contracts AS ct
JOIN vehicles AS v ON v.id = ct.vehicle_id
JOIN deposits AS d ON d.contract_id = ct.id
WHERE ct.id = 9007;

-- Devolución en el Aeropuerto JMC: 18:00, 26.950 km, tanque a la mitad
INSERT INTO vehicle_returns (contract_id, occurred_at, mileage_km, fuel_pct, branch_id, employee_id)
VALUES (9007, '2026-11-23 18:00:00', 26950, 50, 4, 10);

INSERT INTO inspections (contract_id, stage, occurred_at, exterior_ok, interior_ok, notes, employee_id)
VALUES (9007, 'DEVOLUCION', '2026-11-23 18:10:00', TRUE, TRUE, NULL, 10);

CALL sp_cerrar_contrato(9007, '2026-11-23', @saldo_carlos);
SELECT @saldo_carlos AS saldo_carlos;   -- Esperado: 970000.00

-- Dentro de la transacción: contrato CERRADO y vehículo DISPONIBLE
SELECT ct.id AS contrato, ct.status AS estado,
       v.plate AS placa, v.status AS estado_vehiculo, d.status AS estado_deposito
FROM contracts AS ct
JOIN vehicles AS v ON v.id = ct.vehicle_id
JOIN deposits AS d ON d.contract_id = ct.id
WHERE ct.id = 9007;

-- ⚠️ ESPERADO: ERROR 1265 (01000): Data truncated for column 'method' at row 1
-- El asesor intenta cobrar el saldo con CHEQUE (FlotaYa no recibe cheques).
-- Ejecutar sola, con la transacción abierta:
-- INSERT INTO payments (contract_id, concept, amount, method, paid_at)
-- VALUES (9007, 'CIERRE', @saldo_carlos, 'CHEQUE', '2026-11-23 18:20:00');

-- El error no deshace la transacción: el asesor decide deshacerla completa
ROLLBACK;

-- Después del ROLLBACK: ABIERTO, ALQUILADO, RETENIDO, sin devolución
SELECT ct.id AS contrato, ct.status AS estado,
       v.plate AS placa, v.status AS estado_vehiculo, d.status AS estado_deposito,
       (SELECT COUNT(*) FROM vehicle_returns WHERE contract_id = 9007) AS devoluciones,
       (SELECT COUNT(*) FROM inspections WHERE contract_id = 9007 AND stage = 'DEVOLUCION') AS inspecciones_devolucion
FROM contracts AS ct
JOIN vehicles AS v ON v.id = ct.vehicle_id
JOIN deposits AS d ON d.contract_id = ct.id
WHERE ct.id = 9007;


-- 6.3 · Auditoría de consistencia (regla 23)


SELECT
    (SELECT COUNT(*)
       FROM vehicles AS v
      WHERE v.status = 'ALQUILADO'
        AND NOT EXISTS (SELECT 1 FROM contracts AS ct
                         WHERE ct.vehicle_id = v.id AND ct.status = 'ABIERTO')
    ) AS alquilados_sin_contrato,

    (SELECT COUNT(*)
       FROM contracts AS ct
      WHERE ct.status = 'CERRADO'
        AND NOT EXISTS (SELECT 1 FROM vehicle_returns AS vr
                         WHERE vr.contract_id = ct.id)
    ) AS cerrados_sin_devolucion,

    (SELECT COUNT(*)
       FROM deposits AS d
       JOIN contracts AS ct ON ct.id = d.contract_id
      WHERE d.status = 'RETENIDO' AND ct.status = 'CERRADO'
    ) AS depositos_retenidos_de_cerrados,

    (SELECT COUNT(*) FROM contracts WHERE status = 'ABIERTO') AS contratos_abiertos,

    (SELECT COUNT(*) FROM payments) AS pagos;
-- Esperado: 0 · 0 · 0 · 1 (el contrato de Carlos Mejía, que volvió atrás) · 14