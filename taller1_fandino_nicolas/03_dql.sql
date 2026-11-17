-- ======================================================================================
-- 03_dql.sql
-- 12 preguntas de negocio. Fecha de corte: 2026-11-10 (fija). no se usa la del sistema.
-- ======================================================================================
USE bibliored;

-- Q-01 · ¿A qué socios no podemos llamar o no podemos atender?
-- Sin teléfono (NULL) o no activos. IFNULL muestra vacío cuando no tiene teléfono.
-- Resultado esperado: ids 4, 5 (menores sin teléfono), 6 (suspendido), 10 (inactivo)
SELECT m.id,
       CONCAT(m.first_name, ' ', m.last_name) AS socio,
       m.status AS estado,
       IFNULL(m.phone, '') AS telefono
FROM members m
WHERE m.phone IS NULL OR m.status <> 'ACTIVO'
ORDER BY m.id;

-- Q-02 · ¿Qué préstamos están vencidos al corte?
-- Vencido = ACTIVO y due_on < corte (el mismo día del vencimiento NO está vencido).
-- Multa estimada = días de mora × multa por día de la membresía del socio.
-- Resultado esperado: 1010 (25 días, 12.500), 1011 (15 días, 4.500), 1018 (12 días, 3.600)
SELECT l.id AS prestamo,
       CONCAT(m.first_name, ' ', m.last_name) AS socio,
       ms.name AS membresia,
       t.name AS titulo,
       c.barcode AS ejemplar,
       b.name AS sede,
       l.due_on AS vence,
       DATEDIFF('2026-11-10', l.due_on) AS dias_mora,
       DATEDIFF('2026-11-10', l.due_on) * ms.daily_fine AS multa_estimada
FROM loans l
JOIN members m      ON m.id = l.member_id
JOIN memberships ms ON ms.id = m.membership_id
JOIN copies c       ON c.id = l.copy_id
JOIN titles t       ON t.id = c.title_id
JOIN branches b     ON b.id = c.branch_id
WHERE l.status = 'ACTIVO'
  AND l.due_on < '2026-11-10'
ORDER BY dias_mora DESC, l.id;

-- Q-03 · ¿Qué títulos tienen coautores?
-- Se cuentan las filas de la tabla puente por título y se filtra con HAVING (> 1).
-- Resultado esperado: títulos 1, 4 y 6, con 2 autores cada uno
SELECT t.name AS titulo,
       COUNT(ta.id) AS autores
FROM titles t
JOIN title_authors ta ON ta.title_id = t.id
GROUP BY t.id, t.name
HAVING COUNT(ta.id) > 1
ORDER BY t.id;

-- Q-04 · ¿Qué sedes tienen más movimiento?
-- La sede del préstamo es la del ejemplar. Solo sedes con 5 o más préstamos.
-- COUNT(CASE ...) cuenta los activos sin duplicar; COUNT(DISTINCT) los socios distintos.
-- Resultado esperado: Sede Central Chía (9, 5, 6) y Sede Cajicá (5, 4, 4)
SELECT b.name AS sede,
       COUNT(l.id) AS prestamos_totales,
       COUNT(CASE WHEN l.status = 'ACTIVO' THEN 1 END) AS prestamos_activos,
       COUNT(DISTINCT l.member_id) AS socios_distintos
FROM branches b
JOIN copies c ON c.branch_id = b.id
JOIN loans l  ON l.copy_id = c.id
GROUP BY b.id, b.name
HAVING COUNT(l.id) >= 5
ORDER BY prestamos_totales DESC, b.name;

-- Q-05 · ¿Qué socios se afiliaron y nunca han pedido un libro?
-- LEFT JOIN + IS NULL: socios sin ninguna fila en loans.
-- Resultado esperado: ids 12 (Ricardo) y 13 (Isabel)
SELECT m.id,
       CONCAT(m.first_name, ' ', m.last_name) AS socio,
       m.joined_on AS afiliado_desde
FROM members m
LEFT JOIN loans l ON l.member_id = m.id
WHERE l.id IS NULL
ORDER BY m.id;

-- Q-06 · ¿Qué tenemos en el catálogo que no se está usando?
-- Dos listados unidos: categorías sin títulos y autores sin títulos.
-- Resultado esperado: categoria / Cómic y autor / Ignacio Salazar Pinto
SELECT 'categoria' AS tipo, c.name AS nombre
FROM categories c
LEFT JOIN titles t ON t.category_id = c.id
WHERE t.id IS NULL
UNION ALL
SELECT 'autor' AS tipo, a.full_name AS nombre
FROM authors a
LEFT JOIN title_authors ta ON ta.author_id = a.id
WHERE ta.id IS NULL;

-- Q-07 · ¿Qué socios tienen al menos una multa pendiente?
-- EXISTS evita repetir al socio aunque tenga varias multas.
-- Resultado esperado: ids 3 (Marcela), 6 (Óscar), 11 (Lorena)
SELECT m.id,
       CONCAT(m.first_name, ' ', m.last_name) AS socio,
       m.status AS estado
FROM members m
WHERE EXISTS (SELECT 1
              FROM fines f
              JOIN loans l ON l.id = f.loan_id
              WHERE l.member_id = m.id
                AND f.status = 'PENDIENTE')
ORDER BY m.id;

-- Q-08 · ¿Qué reservas pendientes siguen en espera?
-- PENDIENTE y sin ningún ejemplar DISPONIBLE del título en la sede de recogida.
-- Resultado esperado: reservas 3 (La ciudad sin relojes, Chía) y 4 (El mapa de los ríos, Cota).
-- La reserva 1 sí se puede entregar (ejemplar 7 disponible en Chía); la 2 ya está VENCIDA.
SELECT r.id AS reserva,
       CONCAT(m.first_name, ' ', m.last_name) AS socio,
       t.name AS titulo,
       b.name AS sede,
       r.expires_on AS expira
FROM reservations r
JOIN members m  ON m.id = r.member_id
JOIN titles t   ON t.id = r.title_id
JOIN branches b ON b.id = r.branch_id
WHERE r.status = 'PENDIENTE'
  AND NOT EXISTS (SELECT 1
                  FROM copies c
                  WHERE c.title_id = r.title_id
                    AND c.branch_id = r.branch_id
                    AND c.status = 'DISPONIBLE')
ORDER BY r.id;

-- Q-09 · ¿Qué títulos son más caros de reponer que el promedio?
-- Subconsulta escalar con el promedio de todo el catálogo (55.500).
-- Resultado esperado: 5 títulos (90.000, 85.000, 68.000, 60.000, 58.000)
SELECT t.name AS titulo,
       t.replacement_cost AS costo_reposicion
FROM titles t
WHERE t.replacement_cost > (SELECT AVG(replacement_cost) FROM titles)
ORDER BY t.replacement_cost DESC, t.name;

-- Q-10 · ¿Quiénes son los socios más asiduos?
-- Todos los que igualan el máximo de préstamos (maneja empates).
-- Resultado esperado: ids 1 (Camila) y 9 (Daniela), con 3 préstamos cada uno
SELECT m.id,
       CONCAT(m.first_name, ' ', m.last_name) AS socio,
       COUNT(l.id) AS prestamos
FROM members m
JOIN loans l ON l.member_id = m.id
GROUP BY m.id, m.first_name, m.last_name
HAVING COUNT(l.id) = (SELECT MAX(conteo)
                      FROM (SELECT COUNT(*) AS conteo
                            FROM loans
                            GROUP BY member_id) AS por_socio)
ORDER BY m.id;

-- Q-11 · ¿Cuál es el ejemplar más antiguo de cada sede?
-- Se compara la fecha de adquisición con el mínimo de su propia sede.
-- Tabio no aparece porque no tiene ejemplares.
-- Resultado esperado: BR-0007 (Chía), BR-0014 (Cajicá), BR-0016 (Zipaquirá, 2011), BR-0025 (Cota)
SELECT b.name AS sede,
       c.barcode AS ejemplar,
       t.name AS titulo,
       c.acquired_on AS adquirido
FROM copies c
JOIN branches b ON b.id = c.branch_id
JOIN titles t   ON t.id = c.title_id
WHERE c.acquired_on = (SELECT MIN(c2.acquired_on)
                       FROM copies c2
                       WHERE c2.branch_id = c.branch_id)
ORDER BY b.id, c.id;

-- Q-12 · ¿Cuánto debe cada socio en multas?
-- Las cuotas se suman primero por multa (subconsulta p) para no duplicar totales
-- cuando una multa tiene varias cuotas. Se excluyen las ANULADAS.
-- Solo socios con saldo > 0 (la multa pagada en dos cuotas, de Daniela, no aparece).
-- Resultado esperado: Lorena (68.000 / 20.000 / 48.000), Óscar (3.000 / 0 / 3.000), Marcela (600 / 0 / 600)
SELECT m.id,
       CONCAT(m.first_name, ' ', m.last_name) AS socio,
       ROUND(SUM(f.amount), 2) AS total_multas,
       ROUND(SUM(IFNULL(p.pagado, 0)), 2) AS pagado,
       ROUND(SUM(f.amount - IFNULL(p.pagado, 0)), 2) AS saldo
FROM fines f
JOIN loans l   ON l.id = f.loan_id
JOIN members m ON m.id = l.member_id
LEFT JOIN (SELECT fine_id, SUM(amount) AS pagado
           FROM fine_payments
           GROUP BY fine_id) p ON p.fine_id = f.id
WHERE f.status <> 'ANULADA'
GROUP BY m.id, m.first_name, m.last_name
HAVING saldo > 0
ORDER BY saldo DESC, m.id;