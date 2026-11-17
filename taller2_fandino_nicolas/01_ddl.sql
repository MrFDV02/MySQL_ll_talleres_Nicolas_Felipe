-- =====================================================================
-- 01_ddl.sql
-- =====================================================================
DROP DATABASE IF EXISTS flotaya;
CREATE DATABASE flotaya;
USE flotaya;

-- 1. Geografía y personal

CREATE TABLE departments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE cities (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    department_id BIGINT NOT NULL,
    name VARCHAR(80) NOT NULL,
    UNIQUE (department_id, name),
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

CREATE TABLE branches (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    city_id BIGINT NOT NULL,
    name VARCHAR(120) NOT NULL UNIQUE,
    address VARCHAR(160) NOT NULL,
    phone VARCHAR(20) NULL,
    is_airport BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (city_id) REFERENCES cities(id)
);

CREATE TABLE employees (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    branch_id BIGINT NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    hire_date DATE NOT NULL,
    role ENUM('ADMINISTRADOR', 'ASESOR', 'INSPECTOR', 'MECANICO') NOT NULL,
    FOREIGN KEY (branch_id) REFERENCES branches(id)
);


-- 2. Flota y precios


CREATE TABLE categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(40) NOT NULL UNIQUE,
    min_age INT NOT NULL,
    deposit_amount DECIMAL(12,2) NOT NULL,
    CHECK (min_age >= 18),
    CHECK (deposit_amount >= 0)
);

CREATE TABLE brands (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE models (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    brand_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    name VARCHAR(80) NOT NULL,
    transmission ENUM('MECANICA', 'AUTOMATICA') NOT NULL,
    fuel ENUM('GASOLINA', 'DIESEL', 'HIBRIDO', 'ELECTRICO') NOT NULL,
    seats INT NOT NULL,
    UNIQUE (brand_id, name),
    CHECK (seats > 0),
    FOREIGN KEY (brand_id) REFERENCES brands(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE vehicles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    model_id BIGINT NOT NULL,
    plate VARCHAR(6) NOT NULL UNIQUE,
    model_year SMALLINT NOT NULL,
    color VARCHAR(30) NOT NULL,
    mileage_km INT NOT NULL DEFAULT 0,
    status ENUM('DISPONIBLE', 'ALQUILADO', 'MANTENIMIENTO', 'FUERA_DE_SERVICIO') NOT NULL DEFAULT 'DISPONIBLE',
    branch_id BIGINT NOT NULL,
    CHECK (mileage_km >= 0),
    CHECK (model_year BETWEEN 1990 AND 2100),
    FOREIGN KEY (model_id) REFERENCES models(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id)
);

CREATE TABLE seasons (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE,
    season_type ENUM('BAJA', 'MEDIA', 'ALTA') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CHECK (end_date >= start_date)
);

CREATE TABLE season_rates (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT NOT NULL,
    season_type ENUM('BAJA', 'MEDIA', 'ALTA') NOT NULL,
    daily_rate DECIMAL(12,2) NOT NULL,
    UNIQUE (category_id, season_type),
    CHECK (daily_rate > 0),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE maintenances (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id BIGINT NOT NULL,
    maintenance_type ENUM('PREVENTIVO', 'CORRECTIVO', 'LATONERIA') NOT NULL,
    description VARCHAR(200) NOT NULL,
    workshop VARCHAR(120) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    cost DECIMAL(12,2) NULL,
    CHECK (end_date IS NULL OR end_date >= start_date),
    CHECK (cost IS NULL OR cost >= 0),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
);

CREATE TABLE extras (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(60) NOT NULL UNIQUE,
    daily_price DECIMAL(12,2) NOT NULL,
    CHECK (daily_price > 0)
);


-- 3. Clientes y conductores


CREATE TABLE customers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    document_type ENUM('CC', 'CE', 'PASAPORTE') NOT NULL DEFAULT 'CC',
    document_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(20) NULL,
    birth_date DATE NOT NULL,
    city_id BIGINT NOT NULL,
    registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('ACTIVO', 'BLOQUEADO') NOT NULL DEFAULT 'ACTIVO',
    FOREIGN KEY (city_id) REFERENCES cities(id)
);

CREATE TABLE driver_licenses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    license_number VARCHAR(30) NOT NULL UNIQUE,
    category ENUM('B1', 'B2', 'C1', 'C2') NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    country VARCHAR(60) NOT NULL DEFAULT 'Colombia',
    CHECK (expiry_date > issue_date),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE additional_drivers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    document_number VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    birth_date DATE NOT NULL,
    license_number VARCHAR(30) NOT NULL UNIQUE,
    license_expiry_date DATE NOT NULL
);


-- 4. Reservas y contratos


CREATE TABLE reservations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    vehicle_id BIGINT NOT NULL,
    pickup_branch_id BIGINT NOT NULL,
    return_branch_id BIGINT NOT NULL,
    pickup_date DATE NOT NULL,
    return_date DATE NOT NULL,
    quoted_value DECIMAL(12,2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('PENDIENTE', 'CONFIRMADA', 'CONVERTIDA', 'CANCELADA') NOT NULL DEFAULT 'PENDIENTE',
    CHECK (return_date > pickup_date),
    CHECK (quoted_value >= 0),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (pickup_branch_id) REFERENCES branches(id),
    FOREIGN KEY (return_branch_id) REFERENCES branches(id)
) AUTO_INCREMENT = 501;

CREATE TABLE contracts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    reservation_id BIGINT NOT NULL UNIQUE,
    vehicle_id BIGINT NOT NULL,
    employee_id BIGINT NOT NULL,
    start_date DATE NOT NULL,
    expected_end_date DATE NOT NULL,
    actual_return_date DATE NULL,
    rental_value DECIMAL(12,2) NOT NULL,
    status ENUM('ABIERTO', 'CERRADO') NOT NULL DEFAULT 'ABIERTO',
    CHECK (expected_end_date > start_date),
    CHECK (actual_return_date IS NULL OR actual_return_date >= start_date),
    CHECK (rental_value >= 0),
    FOREIGN KEY (reservation_id) REFERENCES reservations(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
) AUTO_INCREMENT = 9001;

CREATE TABLE contract_drivers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    contract_id BIGINT NOT NULL,
    additional_driver_id BIGINT NOT NULL,
    UNIQUE (contract_id, additional_driver_id),
    FOREIGN KEY (contract_id) REFERENCES contracts(id),
    FOREIGN KEY (additional_driver_id) REFERENCES additional_drivers(id)
);

CREATE TABLE contract_extras (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    contract_id BIGINT NOT NULL,
    extra_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    agreed_price DECIMAL(12,2) NOT NULL,
    UNIQUE (contract_id, extra_id),
    CHECK (quantity >= 1),
    CHECK (agreed_price > 0),
    FOREIGN KEY (contract_id) REFERENCES contracts(id),
    FOREIGN KEY (extra_id) REFERENCES extras(id)
);


-- 5. Entrega, devolución, inspección y daños


CREATE TABLE deliveries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    contract_id BIGINT NOT NULL UNIQUE,
    occurred_at DATETIME NOT NULL,
    mileage_km INT NOT NULL,
    fuel_pct TINYINT NOT NULL,
    branch_id BIGINT NOT NULL,
    employee_id BIGINT NOT NULL,
    CHECK (mileage_km >= 0),
    CHECK (fuel_pct BETWEEN 0 AND 100),
    FOREIGN KEY (contract_id) REFERENCES contracts(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

CREATE TABLE vehicle_returns (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    contract_id BIGINT NOT NULL UNIQUE,
    occurred_at DATETIME NOT NULL,
    mileage_km INT NOT NULL,
    fuel_pct TINYINT NOT NULL,
    branch_id BIGINT NOT NULL,
    employee_id BIGINT NOT NULL,
    CHECK (mileage_km >= 0),
    CHECK (fuel_pct BETWEEN 0 AND 100),
    FOREIGN KEY (contract_id) REFERENCES contracts(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

CREATE TABLE inspections (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    contract_id BIGINT NOT NULL,
    stage ENUM('ENTREGA', 'DEVOLUCION') NOT NULL,
    occurred_at DATETIME NOT NULL,
    exterior_ok BOOLEAN NOT NULL,
    interior_ok BOOLEAN NOT NULL,
    notes VARCHAR(300) NULL,
    employee_id BIGINT NOT NULL,
    UNIQUE (contract_id, stage),
    FOREIGN KEY (contract_id) REFERENCES contracts(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

CREATE TABLE damages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    inspection_id BIGINT NOT NULL,
    description VARCHAR(200) NOT NULL,
    severity ENUM('LEVE', 'MODERADO', 'GRAVE') NOT NULL,
    repair_cost DECIMAL(12,2) NOT NULL,
    charged_to_customer BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (repair_cost >= 0),
    FOREIGN KEY (inspection_id) REFERENCES inspections(id)
);


-- 6. Dinero


CREATE TABLE deposits (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    contract_id BIGINT NOT NULL UNIQUE,
    amount DECIMAL(12,2) NOT NULL,
    retained_at DATETIME NOT NULL,
    released_at DATETIME NULL,
    applied_to_damages DECIMAL(12,2) NOT NULL DEFAULT 0,
    status ENUM('RETENIDO', 'LIBERADO', 'APLICADO') NOT NULL DEFAULT 'RETENIDO',
    CHECK (amount > 0),
    CHECK (applied_to_damages >= 0),
    CHECK (applied_to_damages <= amount),
    FOREIGN KEY (contract_id) REFERENCES contracts(id)
);

CREATE TABLE payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    contract_id BIGINT NOT NULL,
    concept ENUM('ALQUILER', 'EXTRAS', 'DAÑOS', 'CIERRE') NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    method ENUM('TARJETA', 'EFECTIVO', 'TRANSFERENCIA', 'DEPOSITO') NOT NULL,
    paid_at DATETIME NOT NULL,
    card_last4 CHAR(4) NULL,
    authorization_code VARCHAR(30) NULL,
    CHECK (amount > 0),
    CHECK (card_last4 IS NULL OR CHAR_LENGTH(card_last4) = 4),
    FOREIGN KEY (contract_id) REFERENCES contracts(id)
);

SHOW TABLES;

DESCRIBE contracts;
DESCRIBE reservations;
