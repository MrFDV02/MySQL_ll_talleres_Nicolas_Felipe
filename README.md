# Talleres MySQL II - Nicolás Fandino

Repositorio con los dos talleres del módulo **MySQL II**. Cada taller parte de un caso de
negocio distinto, sin modelo ni `CREATE TABLE` de regalo: hay que leer el enunciado, diseñar
el diagrama entidad-relación, normalizarlo, llevarlo a MySQL, llenarlo con datos coherentes,
consultarlo, protegerlo con código y cerrar operaciones con transacciones.

| Taller | Caso | Base de datos | Tablas | Tema central de la fase avanzada |
| --- | --- | --- | --- | --- |
| Taller 1 | BiblioRed | `bibliored` | 15 | Procedimientos almacenados |
| Taller 2 | FlotaYa | `flotaya` | 25 | Funciones, roles y permisos, transacciones |

Todo está escrito y probado sobre **MySQL 8.0.46**. Los scripts `01` a `05` de cada carpeta se
ejecutan en orden sobre un servidor sin la base y corren completos.

## Estructura del repositorio

```
Taller/
├── README.md
├── taller1_fandino_nicolas/
│   ├── 00_diagrama.md          Diagrama ER (Mermaid), cardinalidades y normalización
│   ├── 01_ddl.sql              Base, tablas y restricciones
│   ├── 02_dml.sql              Datos semilla, mantenimiento y errores provocados
│   ├── 03_dql.sql              Las 12 preguntas de negocio (Q-01 a Q-12)
│   ├── 04_dql_avanzado.sql     Procedimientos almacenados y sus pruebas
│   └── 05_tcl.sql              Operaciones "todo o nada"
└── taller2_fandino_nicolas/
    ├── 00_diagrama.md          Diagrama ER (Mermaid), cardinalidades y normalización
    ├── 01_ddl.sql              Base, tablas y restricciones
    ├── 02_dml.sql              Datos semilla, mantenimiento y errores provocados
    ├── 03_dql.sql              Las 12 preguntas de negocio (Q-01 a Q-12)
    ├── 04_dql_avanzado.sql     Funciones, procedimientos, roles y cuentas
    ├── 05_tcl.sql              Las dos operaciones "todo o nada" y la auditoría final
    └── evidencias/             Capturas de las tres cuentas de base de datos
```

Las carpetas siguen la convención `tallerN_apellido_nombre/` que piden los dos enunciados, y
los archivos van numerados en el mismo orden de las fases. La fecha de corte de cada taller
quedó fija en los datos y en las consultas (nunca `NOW()` ni `CURDATE()`).

---

## Taller 1 - BiblioRed

BiblioRed es una red física de bibliotecas públicas con cinco sedes en la Sabana de Bogotá. El
caso tiene tres particularidades que definen casi todo el diseño: los libros existen como
**ejemplares** concretos ubicados en una sede, los socios tienen **membresías** que fijan los
topes de préstamo, y las demoras generan **multas** que se pagan por cuotas.

Fecha de corte: `2026-11-10`.

### Modelo

15 tablas, dentro del rango pedido (13 a 17):

| Grupo | Tablas |
| --- | --- |
| Red y personal | `branches`, `employees` |
| Catálogo | `categories`, `publishers`, `authors`, `titles`, `title_authors`, `copies` |
| Socios | `memberships`, `members` |
| Circulación | `loans`, `loan_renewals`, `reservations` |
| Dinero | `fines`, `fine_payments` |

Las decisiones de normalización están justificadas en `00_diagrama.md`. Las dos que más
cambian el modelo son la tabla puente `title_authors` (un título puede tener varios autores,
con orden de autoría único) y la separación entre `titles` y `copies` (un título tiene muchos
ejemplares físicos, cada uno en una sede y con su propio código de barras).

### Procedimientos

Como el enunciado solo permitía procedimientos de MySQL II, toda la lógica vive ahí:

| Procedimiento | Qué resuelve |
| --- | --- |
| `sp_prestar_ejemplar` | Valida estado del ejemplar, membresía, tope de préstamos y deja el préstamo registrado |
| `sp_devolver_ejemplar` | Cierra el préstamo y calcula la multa por mora según los días de la membresía |
| `sp_renovar_prestamo` | Controla las renovaciones permitidas y mueve la fecha de vencimiento |
| `sp_pagar_multa` | Registra abonos y actualiza el saldo de la multa |
| `sp_resumen_socio` | Devuelve en un solo resultado la situación completa de un socio |
| `sp_reporte_sedes` | Reporte por sede al corte que se le pase como parámetro |

### Consultas

`03_dql.sql` responde las doce preguntas del negocio con `-- Q-01` ... `-- Q-12`:
socios a los que no se puede llamar, préstamos vencidos, títulos con coautores, sedes con más
movimiento, socios afiliados que nunca pidieron un libro, catálogo sin uso, socios con multa
pendiente, reservas en espera, títulos más caros que el promedio, socios más asiduos, el
ejemplar más antiguo de cada sede y cuánto debe cada socio.

### TCL

`05_tcl.sql` demuestra con datos por qué un procedimiento **no es atómico por sí mismo**:

1. Se llama `sp_prestar_ejemplar` con un empleado inexistente. Sin transacción abierta, el
   `UPDATE` del ejemplar ya se confirmó solo (autocommit) y el error llega después, en el
   `INSERT` del préstamo. Resultado: un ejemplar marcado `PRESTADO` sin préstamo que lo
   respalde, violando la regla 12. La consulta de comprobación muestra la inconsistencia.
2. Se corrige el dato y se repite la llamada dentro de `START TRANSACTION` + `ROLLBACK`: el
   ejemplar vuelve a `DISPONIBLE`.
3. Se crea `sp_prestar_ejemplar_tx`, que envuelve el procedimiento original con
   `EXIT HANDLER FOR SQLEXCEPTION` (`ROLLBACK` + `RESIGNAL`) y `COMMIT`. Ahí el error de la FK
   ya no deja basura: el ejemplar queda disponible y el error se propaga tal cual.

También queda documentado por qué el `AUTO_INCREMENT` de InnoDB no se devuelve con un
`ROLLBACK`: los intentos fallidos gastan números y dejan huecos, aunque los ids sigan siendo
únicos.

---

## Taller 2 - FlotaYa

FlotaYa es una empresa de alquiler de carros con sedes en Bogotá, Medellín, Rionegro,
Cartagena y Cali, y una sede en Bucaramanga que todavía no abre. El alquiler es un flujo
completo: **reserva** de una placa concreta, **cotización**, **contrato**, **entrega** con
inspección y depósito retenido, **devolución** con inspección, **daños**, **cierre** con
recálculo del alquiler y liberación del depósito. El precio depende del calendario: cada
categoría tiene tarifa diaria por tipo de temporada (BAJA, MEDIA, ALTA).

Fecha de corte: `2026-11-23`.

### Modelo

25 tablas, dentro del rango pedido (20 a 28):

| Grupo | Tablas |
| --- | --- |
| Geografía y red | `departments`, `cities`, `branches`, `employees` |
| Flota | `categories`, `brands`, `models`, `vehicles`, `maintenances` |
| Precios | `seasons`, `season_rates`, `extras` |
| Clientes | `customers`, `driver_licenses`, `additional_drivers` |
| Alquiler | `reservations`, `contracts`, `contract_drivers`, `contract_extras` |
| Operación | `deliveries`, `vehicle_returns`, `inspections`, `damages` |
| Dinero | `deposits`, `payments` |

La tabla `season_rates` es la que evita repetir precios: relaciona categoría con tipo de
temporada y guarda una sola tarifa diaria, porque el enunciado dice que la misma categoría
cuesta lo mismo en todas las temporadas del mismo tipo. `contract_extras` y
`contract_drivers` son puentes con datos propios (cantidad, precio pactado, autorización).

### Funciones y procedimientos

Tres funciones:

| Función | Qué calcula |
| --- | --- |
| `fn_edad_conductor` | Edad exacta a una fecha de referencia (no usa `NOW()`) |
| `fn_licencia_vigente` | Si la licencia del cliente cubre todo el rango del alquiler |
| `fn_valor_alquiler` | Cotiza día por día aplicando la temporada que corresponde a cada fecha |

Dos procedimientos:

| Procedimiento | Qué hace |
| --- | --- |
| `sp_crear_reserva` | Valida edad mínima por categoría, licencia vigente, bloqueo del cliente, estado del vehículo y cruces de fechas; si todo pasa, cotiza y crea la reserva |
| `sp_cerrar_contrato` | Recalcula el alquiler con la fecha real, cobra extras y daños, aplica o libera el depósito y deja el carro disponible en la sede de devolución |

Las validaciones de negocio usan `SIGNAL SQLSTATE '45000'` con mensajes en español, para que el
error diga qué regla se rompió y no solo que algo falló.

### Roles, cuentas y evidencias

El taller pedía tres perfiles con privilegio mínimo. Se crearon tres roles, cada uno con su
cuenta de base de datos en `localhost` y la clave de práctica, y con `SET DEFAULT ROLE ALL`
para que el rol quede activo al conectarse (sin eso la cuenta entra pero sin permisos):

| Cuenta | Rol | Puede | No puede |
| --- | --- | --- | --- |
| `asesor_flotaya` | `rol_asesor_flotaya` | Reservas, contratos, clientes, consultar vehículos y tarifas | Ver `payments`, `driver_licenses`, borrar reservas |
| `taller_flotaya` | `rol_taller_flotaya` | Mantenimientos y columnas puntuales de `vehicles` (`plate`, `status`, `mileage_km`, `branch_id`) | `SELECT *` de vehículos, cambiar el kilometraje, ver contratos |
| `auditor_flotaya` | `rol_auditor_flotaya` | Leer pagos sin datos de tarjeta, contar contratos | Ver `card_last4`, `SELECT *` de pagos, modificar contratos |

Las tres capturas están en `taller2_fandino_nicolas/evidencias/`. Cada una muestra la cuenta
conectada con su rol activo, una operación permitida y el error de la operación prohibida, en
la misma sesión.

**Cuenta asesor:** identifica la cuenta, consulta la reserva 516 cotizada en 810.000 y recibe
el error 1142 al intentar leer `payments`.

![Prueba de acceso con la cuenta de asesor](taller2_fandino_nicolas/evidencias/Cuenta%20ASESOR.png)

**Cuenta taller:** consulta las columnas permitidas del vehículo 15 (HLX702, en mantenimiento,
88.100 km) y recibe el error 1143 al intentar cambiar `mileage_km`.

![Prueba de acceso con la cuenta de taller](taller2_fandino_nicolas/evidencias/Cuenta%20TALLER.png)

**Cuenta auditor:** lee los tres pagos del contrato 9003 sin los datos de tarjeta y recibe el
error 1143 al pedir `card_last4`.

![Prueba de acceso con la cuenta de auditor](taller2_fandino_nicolas/evidencias/Cuenta%20AUDITOR.png)

### TCL

`05_tcl.sql` tiene las dos operaciones "todo o nada" y la auditoría final:

1. **Cierre del contrato de Paola Quintero, con `SAVEPOINT`.** Se registra devolución,
   inspección y un daño con un costo mal tecleado (3.800.000). Se vuelve al `SAVEPOINT` para
   deshacer solo ese error, se registra el daño correcto (380.000), se cierra el contrato y se
   cobra el saldo. Resultado: alquiler 1.840.000, depósito aplicado a daños, tres pagos y un
   solo daño en la inspección.
2. **Un cierre que debe deshacerse completo (Carlos Mejía).** Se abre la transacción, se
   intenta cerrar un contrato que no tiene devolución registrada y el `ROLLBACK` deja todo
   como estaba: contrato `ABIERTO`, vehículo `ALQUILADO`, depósito `RETENIDO`, cero
   devoluciones y cero inspecciones nuevas.
3. **Auditoría de consistencia (regla 23).** Una consulta final comprueba cuatro invariantes y
   el total de pagos. Debe dar `0, 0, 0, 1, 14`: ningún vehículo alquilado sin contrato
   abierto, ningún contrato cerrado sin devolución, ningún depósito retenido en un contrato
   cerrado, un contrato abierto y catorce pagos.

---

## Pruebas realizadas

- Los cinco scripts de cada taller se ejecutaron en orden sobre MySQL 8.0.46 sin detenerse.
- En el Taller 2 se corrieron dos veces seguidas para comprobar que el script es reproducible:
  mismo resultado las dos veces.
- Las respuestas del Taller 2 coinciden con lo esperado: cotizaciones de 620.000, 2.300.000,
  1.080.000 y 1.202.500; reserva 515 en 1.290.000; saldo de Ricardo en 60.000; saldo de Paola
  en 750.000; auditoría final en `0, 0, 0, 1, 14`.
- Se provocaron trece errores a propósito y todos devolvieron el código previsto: 1062 (placa
  duplicada), 3819 (costo negativo contra un `CHECK`), 1265 (valor fuera del `ENUM`), 1451
  (borrar una categoría con vehículos) y 1644 con el mensaje en español de cada regla de
  negocio.
- En el Taller 2 se probaron las tres cuentas por separado: cada una demuestra lo permitido y
  recibe el error correcto en lo prohibido.

## Notas y correcciones

- MySQL no acepta `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = CONCAT(...)` (devuelve 1064).
  En `fn_valor_alquiler` y `sp_crear_reserva` el mensaje se arma antes en una variable
  `v_msg` y luego se lanza con `SIGNAL`.
- Los códigos de privilegio no son intercambiables: **1142** niega el permiso sobre la
  **tabla** (por eso `SELECT *` falla cuando la cuenta solo tiene permisos por columna) y
  **1143** niega una **columna** concreta. Esa diferencia es justamente la que se explica en
  las pruebas de acceso.
- Las cuentas se crean `@'localhost'`, como pide el enunciado. Si se conectan desde otra
  máquina o desde un cliente fuera del servidor, MySQL las ve con otro host y responde 1045
  (no entraron), que no es lo mismo que 1142 o 1143 (entraron, pero sin permiso).

## Autor

Nicolás Fandino - Talleres de MySQL II.
