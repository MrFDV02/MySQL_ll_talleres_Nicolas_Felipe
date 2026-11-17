-- =====================================================================
-- 01_ddl.sql
-- =====================================================================
DROP DATABASE IF EXISTS bibliored;
CREATE DATABASE bibliored;
USE bibliored;

-- ---------------------------------------------------------------------
-- Tablas sin dependencias
-- ---------------------------------------------------------------------

-- Regla 1: sedes con nombre único
CREATE TABLE branches (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    municipality VARCHAR(60) NOT NULL,
    address VARCHAR(120) NOT NULL,
    opened_on DATE NOT NULL
);

-- Regla 4: categorías con nombre único
CREATE TABLE categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE
);

-- Regla 4: editoriales con nombre único y ciudad
CREATE TABLE publishers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    city VARCHAR(60) NOT NULL
);

-- Regla 5: autores
CREATE TABLE authors (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    nationality VARCHAR(60) NOT NULL,
    birth_year SMALLINT NOT NULL
);

-- Regla 7: membresías (topes y tarifas con CHECK)
CREATE TABLE memberships (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(40) NOT NULL UNIQUE,
    max_loans INT NOT NULL,
    loan_days INT NOT NULL,
    max_renewals INT NOT NULL,
    daily_fine DECIMAL(10,2) NOT NULL,
    annual_fee DECIMAL(12,2) NOT NULL,
    CHECK (max_loans > 0),
    CHECK (loan_days > 0),
    CHECK (max_renewals >= 0),
    CHECK (daily_fine >= 0),
    CHECK (annual_fee >= 0)
);

-- ---------------------------------------------------------------------
-- Tablas que dependen de las anteriores
-- ---------------------------------------------------------------------

-- Regla 2: empleado en una sola sede, correo único, rol por defecto BIBLIOTECARIO
CREATE TABLE employees (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    hire_date DATE NOT NULL,
    role ENUM('COORDINADOR', 'BIBLIOTECARIO', 'AUXILIAR') NOT NULL DEFAULT 'BIBLIOTECARIO',
    branch_id BIGINT NOT NULL,
    FOREIGN KEY (branch_id) REFERENCES branches(id)
);

-- Regla 3: título con ISBN único, una categoría, una editorial, costo por defecto 50.000
CREATE TABLE titles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    publication_year SMALLINT NOT NULL,
    replacement_cost DECIMAL(12,2) NOT NULL DEFAULT 50000.00,
    category_id BIGINT NOT NULL,
    publisher_id BIGINT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (publisher_id) REFERENCES publishers(id)
);

-- Regla 5: tabla puente título-autor con orden de autoría
CREATE TABLE title_authors (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title_id BIGINT NOT NULL,
    author_id BIGINT NOT NULL,
    author_order INT NOT NULL,
    FOREIGN KEY (title_id) REFERENCES titles(id),
    FOREIGN KEY (author_id) REFERENCES authors(id),
    UNIQUE (title_id, author_id),
    UNIQUE (title_id, author_order),
    CHECK (author_order >= 1)
);

-- Regla 6: ejemplar físico con código de barras único y estado
CREATE TABLE copies (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    barcode VARCHAR(30) NOT NULL UNIQUE,
    acquired_on DATE NOT NULL,
    status ENUM('DISPONIBLE', 'PRESTADO', 'EN_REPARACION', 'PERDIDO', 'DADO_DE_BAJA') NOT NULL DEFAULT 'DISPONIBLE',
    title_id BIGINT NOT NULL,
    branch_id BIGINT NOT NULL,
    FOREIGN KEY (title_id) REFERENCES titles(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id)
);

-- Regla 8: socio (correo y teléfono pueden ser NULL; documento y correo únicos)
CREATE TABLE members (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    document_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    birth_date DATE NOT NULL,
    joined_on DATE NOT NULL,
    status ENUM('ACTIVO', 'SUSPENDIDO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    membership_id BIGINT NOT NULL,
    branch_id BIGINT NOT NULL,
    FOREIGN KEY (membership_id) REFERENCES memberships(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id)
);

-- Reglas 9 y 10: préstamo (devolución vacía mientras no vuelva; numeración desde 1001)
CREATE TABLE loans (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    loaned_on DATE NOT NULL,
    due_on DATE NOT NULL,
    returned_on DATE,
    status ENUM('ACTIVO', 'DEVUELTO', 'PERDIDO') NOT NULL DEFAULT 'ACTIVO',
    copy_id BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    employee_id BIGINT NOT NULL,
    FOREIGN KEY (copy_id) REFERENCES copies(id),
    FOREIGN KEY (member_id) REFERENCES members(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id),
    CHECK (due_on > loaned_on),
    CHECK (returned_on IS NULL OR returned_on >= loaned_on)
) AUTO_INCREMENT = 1001;

-- Regla 14: historial de renovaciones
CREATE TABLE loan_renewals (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    renewed_on DATE NOT NULL,
    previous_due_on DATE NOT NULL,
    new_due_on DATE NOT NULL,
    loan_id BIGINT NOT NULL,
    FOREIGN KEY (loan_id) REFERENCES loans(id),
    CHECK (new_due_on > previous_due_on)
);

-- Regla 16: reserva sobre un título, con sede de recogida propia
CREATE TABLE reservations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    reserved_on DATE NOT NULL,
    expires_on DATE NOT NULL,
    status ENUM('PENDIENTE', 'ATENDIDA', 'CANCELADA', 'VENCIDA') NOT NULL DEFAULT 'PENDIENTE',
    member_id BIGINT NOT NULL,
    title_id BIGINT NOT NULL,
    branch_id BIGINT NOT NULL,
    FOREIGN KEY (member_id) REFERENCES members(id),
    FOREIGN KEY (title_id) REFERENCES titles(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    CHECK (expires_on >= reserved_on)
);

-- Reglas 17 y 18: multa que nace de un préstamo; el valor se guarda y no cambia
CREATE TABLE fines (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    reason ENUM('MORA', 'DAÑO', 'PERDIDA') NOT NULL,
    status ENUM('PENDIENTE', 'PAGADA', 'ANULADA') NOT NULL DEFAULT 'PENDIENTE',
    late_days INT NOT NULL DEFAULT 0,
    amount DECIMAL(12,2) NOT NULL,
    issued_on DATE NOT NULL,
    loan_id BIGINT NOT NULL,
    FOREIGN KEY (loan_id) REFERENCES loans(id),
    CHECK (late_days >= 0),
    CHECK (amount > 0)
);

-- Regla 20: cuotas de una multa
CREATE TABLE fine_payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(12,2) NOT NULL,
    paid_on DATE NOT NULL,
    payment_method ENUM('EFECTIVO', 'TARJETA', 'TRANSFERENCIA') NOT NULL,
    fine_id BIGINT NOT NULL,
    FOREIGN KEY (fine_id) REFERENCES fines(id),
    CHECK (amount > 0)
);

-- ---------------------------------------------------------------------
-- Verificación
-- ---------------------------------------------------------------------
SHOW TABLES;
DESCRIBE loans;

-- =====================================================================
-- REGLAS QUE NO SE PUEDEN PROTEGER SOLO CON LA ESTRUCTURA
-- (PK, FK, UNIQUE, CHECK, NOT NULL). Para cada una: por qué no cabe y dónde se resuelve.
--  Un CHECK solo ve las columnas de la fila que se guarda; no puede
-- consultar otras filas, otras tablas ni "la fecha de hoy".
-- =====================================================================
-- Regla 10 (vencimiento = fecha del préstamo + días de la membresía)
--   Por qué no cabe: los días están en memberships, otra tabla; el CHECK no la ve.
--   Se resuelve en: fase 5 (sp_prestar_ejemplar calcula el vencimiento y
--   sp_renovar_prestamo el nuevo vencimiento).
-- Regla 11 (prestar solo a socio ACTIVO, sin multas y bajo el tope)
--   Por qué no cabe: hay que contar filas de fines y loans; un CHECK no hace subconsultas.
--   Se resuelve en: fase 5 (sp_prestar_ejemplar).
-- Regla 12 (ejemplar PRESTADO <=> préstamo ACTIVO)
--   Por qué no cabe: compara el estado de dos tablas (copies y loans); ningún CHECK ni
--   FK compara el valor de una columna con el de otra tabla.
--   Se resuelve en: fase 5 (los procedimientos cambian ejemplar y préstamo) y fase 6
--   (la transacción hace que ambos cambios ocurran juntos o ninguno).
-- Regla 15 (renovar solo si está activo, sin vencer, sin agotar renovaciones y sin reservas)
--   Por qué no cabe: depende de conteos en otras tablas y de una fecha de referencia.
--   Se resuelve en: fase 5 (sp_renovar_prestamo).
-- Regla 16, 2.ª parte (una reserva PENDIENTE ya expirada debe quedar VENCIDA)
--   Por qué no cabe: un CHECK no puede depender de "hoy"; es una acción que alguien
--   ejecuta con una fecha de corte, no una condición de una fila.
--   Se resuelve en: el enunciado la deja para la fase 5; aquí se hace con el UPDATE
--   de mantenimiento de la fase 3 (02_dml.sql, U2) y con el reto R3.
-- Regla 18 (multa por mora = días de retraso × multa por día de la membresía)
--   Por qué no cabe: es un cálculo con datos de memberships y de la fecha de devolución.
--   Se resuelve en: fase 5 (sp_devolver_ejemplar).
-- Regla 19 (libro perdido => préstamo y ejemplar PERDIDO + multa PERDIDA por el costo de reposición)
--   Por qué no cabe: es un efecto en cadena sobre varias tablas (loans, copies, fines).
--   Se resuelve en: los datos de la fase 3 (así lo indica el enunciado para este taller).
-- Regla 20, tope de la cuota y paso a PAGADA
--   Por qué no cabe: el saldo es una suma sobre otra tabla (fine_payments) y el paso a
--   PAGADA es un cambio en fines que depende de esa suma; un CHECK solo ve una fila.
--   Se resuelve en: fase 5 (sp_pagar_multa).