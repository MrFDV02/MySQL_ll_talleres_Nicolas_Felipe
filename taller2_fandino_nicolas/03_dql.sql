-- =====================================================================
-- Taller 2 · FlotaYa · Fase 4 · DQL
-- Se ejecuta después de 02_dml.sql completo (incluidas las operaciones
-- del día). Fecha de corte fija: 2026-11-23. Nunca NOW() ni CURDATE().
-- =====================================================================

USE flotaya;

-- ---------------------------------------------------------------------
-- Q-01 · ¿Cómo está repartida la flota hoy?
-- ---------------------------------------------------------------------
SELECT v.status          AS estado,
       COUNT(*)          AS vehiculos
FROM vehicles AS v
GROUP BY v.status
ORDER BY vehiculos DESC, estado ASC;
-- Esperado: DISPONIBLE 12 · ALQUILADO 3 · MANTENIMIENTO 2 · FUERA_DE_SERVICIO 1

-- ---------------------------------------------------------------------
-- Q-02 · ¿Cuánto duran las temporadas altas?
-- ---------------------------------------------------------------------
SELECT s.name                                        AS temporada,
       s.start_date                                  AS desde,
       s.end_date                                    AS hasta,
       DATEDIFF(s.end_date, s.start_date) + 1        AS dias
FROM seasons AS s
WHERE s.season_type = 'ALTA'
ORDER BY s.start_date;

-- Q-03 · ¿Qué carros podemos ofrecer ya mismo?
SELECT v.plate      AS placa,
       b.name       AS marca,
       m.name       AS modelo,
       c.name       AS categoria,
       br.name      AS sede,
       ci.name      AS ciudad
FROM vehicles AS v
JOIN models AS m     ON m.id = v.model_id
JOIN brands AS b     ON b.id = m.brand_id
JOIN categories AS c ON c.id = m.category_id
JOIN branches AS br  ON br.id = v.branch_id
JOIN cities AS ci    ON ci.id = br.city_id
WHERE v.status = 'DISPONIBLE'
ORDER BY FIELD(c.name, 'Económico', 'Compacto', 'SUV', 'Camioneta 4x4', 'Van', 'Lujo'),
         v.plate;

-- Q-04 · ¿Qué contratos abiertos están atrasados o por vencer?
SELECT ct.id                                       AS contrato,
       CONCAT(cu.first_name, ' ', cu.last_name)    AS cliente,
       v.plate                                     AS placa,
       m.name                                      AS modelo,
       br.name                                     AS sede_recogida,
       ct.expected_end_date                        AS fin_esperado,
       DATEDIFF(ct.expected_end_date, '2026-11-23') AS dias_para_devolver,
       COUNT(cd.additional_driver_id)              AS conductores_adicionales
FROM contracts AS ct
JOIN reservations AS r ON r.id = ct.reservation_id
JOIN customers AS cu   ON cu.id = r.customer_id
JOIN vehicles AS v     ON v.id = ct.vehicle_id
JOIN models AS m       ON m.id = v.model_id
JOIN branches AS br    ON br.id = r.pickup_branch_id
LEFT JOIN contract_drivers AS cd ON cd.contract_id = ct.id
WHERE ct.status = 'ABIERTO'
GROUP BY ct.id, cliente, v.plate, m.name, br.name, ct.expected_end_date
ORDER BY dias_para_devolver ASC, ct.id;

-- Q-05 · ¿Qué sedes recaudan más?
SELECT br.name                        AS sede,
       COUNT(DISTINCT p.contract_id)  AS contratos,
       ROUND(SUM(p.amount), 2)        AS recaudado
FROM payments AS p
JOIN contracts AS ct     ON ct.id = p.contract_id
JOIN reservations AS r   ON r.id = ct.reservation_id
JOIN branches AS br      ON br.id = r.pickup_branch_id
GROUP BY br.id, br.name
HAVING SUM(p.amount) > 2000000
ORDER BY recaudado DESC, sede;

-- Q-06 · ¿Qué modelos tenemos en el catálogo sin un solo carro?
SELECT b.name AS marca,
       m.name AS modelo
FROM models AS m
JOIN brands AS b ON b.id = m.brand_id
LEFT JOIN vehicles AS v ON v.model_id = m.id
WHERE v.id IS NULL
ORDER BY marca, modelo;


-- Q-07 · ¿Qué clientes no podrían manejar hoy?
SELECT cu.id                                     AS id,
       CONCAT(cu.first_name, ' ', cu.last_name)  AS cliente
FROM customers AS cu
WHERE NOT EXISTS (
        SELECT 1
        FROM driver_licenses AS dl
        WHERE dl.customer_id = cu.id
          AND dl.issue_date  <= '2026-11-23'
          AND dl.expiry_date >= '2026-11-23'
      )
ORDER BY cu.id;

-- Q-08 · ¿Qué carros siguen libres para diciembre?
SELECT v.plate  AS placa,
       m.name   AS modelo,
       br.name  AS sede
FROM vehicles AS v
JOIN models AS m    ON m.id = v.model_id
JOIN branches AS br ON br.id = v.branch_id
WHERE v.status = 'DISPONIBLE'
  AND NOT EXISTS (
        SELECT 1
        FROM reservations AS r
        WHERE r.vehicle_id = v.id
          AND r.status IN ('PENDIENTE', 'CONFIRMADA', 'CONVERTIDA')
          AND r.pickup_date <= '2026-12-31'
          AND r.return_date >= '2026-12-01'
      )
ORDER BY v.plate;


-- Q-09 · ¿Qué vehículos nos están costando más en el taller?
WITH gastos AS (
    SELECT v.id            AS vehicle_id,
           v.plate         AS placa,
           SUM(mt.cost)    AS gasto
    FROM vehicles AS v
    JOIN maintenances AS mt ON mt.vehicle_id = v.id
    GROUP BY v.id, v.plate
)
SELECT placa            AS placa,
       ROUND(gasto, 2)  AS gasto
FROM gastos
WHERE gasto > (SELECT AVG(gasto) FROM gastos)
ORDER BY gasto DESC;

-- Segunda consulta: el promedio con el que se comparó
WITH gastos AS (
    SELECT v.id         AS vehicle_id,
           v.plate      AS placa,
           SUM(mt.cost) AS gasto
    FROM vehicles AS v
    JOIN maintenances AS mt ON mt.vehicle_id = v.id
    GROUP BY v.id, v.plate
)
SELECT ROUND(AVG(gasto), 2) AS promedio_por_vehiculo,
       COUNT(*)             AS vehiculos,
       COUNT(gasto)         AS con_gasto
FROM gastos;
-- Los mantenimientos en curso NO afectan el promedio: su costo es NULL y
-- SUM() lo ignora, así que ese vehículo queda con gasto NULL y AVG() lo
-- excluye. Cuenta como vehículo que entró al taller (6), pero no como
-- vehículo con gasto conocido (4). El promedio es 3.310.000 / 4 = 827.500.

-- Q-10 · ¿Cuál es el carro más rodado de cada categoría?
WITH ranking AS (
    SELECT c.name           AS categoria,
           v.plate          AS placa,
           v.mileage_km     AS kilometraje,
           ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY v.mileage_km DESC, v.plate) AS rn
    FROM vehicles AS v
    JOIN models AS m     ON m.id = v.model_id
    JOIN categories AS c ON c.id = m.category_id
)
SELECT categoria, placa, kilometraje
FROM ranking
WHERE rn = 1
ORDER BY FIELD(categoria, 'Económico', 'Compacto', 'SUV', 'Camioneta 4x4', 'Van', 'Lujo');
-- Lujo no aparece porque no tiene ningún modelo y, por tanto, ningún vehículo.

-- Q-11 · ¿Cuánto dejan los extras?
SELECT e.name AS extra,
       COUNT(ce.contract_id) AS contratos,
       ROUND(COALESCE(SUM(ce.quantity * ce.agreed_price *
             DATEDIFF(COALESCE(ct.actual_return_date, ct.expected_end_date), ct.start_date)), 0), 2) AS ingresos
FROM extras AS e
LEFT JOIN contract_extras AS ce ON ce.extra_id = e.id
LEFT JOIN contracts AS ct       ON ct.id = ce.contract_id
GROUP BY e.id, e.name
ORDER BY ingresos DESC, extra;

-- Q-12 · ¿Qué daños hemos encontrado?
SELECT ct.id                                     AS contrato,
       v.plate                                   AS placa,
       CONCAT(cu.first_name, ' ', cu.last_name)  AS cliente,
       i.stage                                   AS etapa,
       d.description                             AS dano,
       d.severity                                AS severidad,
       ROUND(d.repair_cost, 2)                   AS costo,
       IF(d.charged_to_customer, 'Sí', 'No')     AS se_cobra
FROM damages AS d
JOIN inspections AS i  ON i.id = d.inspection_id
JOIN contracts AS ct   ON ct.id = i.contract_id
JOIN reservations AS r ON r.id = ct.reservation_id
JOIN customers AS cu   ON cu.id = r.customer_id
JOIN vehicles AS v     ON v.id = ct.vehicle_id
ORDER BY ct.id, d.id;