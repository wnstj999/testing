-- Portal System Database Schema
-- Version: 0.1 (2025-09-24)
-- Author: 홍길동
-- Note: Replace IDENTITY clauses with AUTO_INCREMENT (MySQL/MariaDB) or IDENTITY(1,1) (MSSQL) as needed.

-- =============================================================
-- 1. Master Data: Geography
-- =============================================================
CREATE TABLE countries (
    country_code        VARCHAR(3)  PRIMARY KEY,
    country_name        VARCHAR(100) NOT NULL,
    iso_alpha3          CHAR(3) UNIQUE,
    region              VARCHAR(100),
    currency_code       VARCHAR(3),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cities (
    city_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code        VARCHAR(3) NOT NULL,
    city_name           VARCHAR(120) NOT NULL,
    is_port_city        CHAR(1) DEFAULT 'N' CHECK (is_port_city IN ('Y','N')),
    latitude            DECIMAL(9,6),
    longitude           DECIMAL(9,6),
    population          BIGINT,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_city_country FOREIGN KEY (country_code)
        REFERENCES countries (country_code)
);

CREATE TABLE ports (
    port_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    city_id             BIGINT NOT NULL,
    port_name           VARCHAR(150) NOT NULL,
    un_locode           CHAR(5) UNIQUE,
    max_draft_meters    DECIMAL(5,2),
    container_capacity_teu INTEGER,
    CONSTRAINT fk_port_city FOREIGN KEY (city_id) REFERENCES cities (city_id)
);

-- =============================================================
-- 2. Logistics & Shipping
-- =============================================================
CREATE TABLE container_ships (
    ship_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    imo_number          CHAR(7) UNIQUE NOT NULL,
    ship_name           VARCHAR(120) NOT NULL,
    capacity_teu        INTEGER NOT NULL,
    operator_company    VARCHAR(150),
    built_year          SMALLINT,
    active_flag         CHAR(1) DEFAULT 'Y' CHECK (active_flag IN ('Y','N'))
);

CREATE TABLE shipping_routes (
    route_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    departure_port_id   BIGINT NOT NULL,
    arrival_port_id     BIGINT NOT NULL,
    estimated_days      SMALLINT NOT NULL,
    frequency_per_week  SMALLINT,
    CONSTRAINT fk_route_departure FOREIGN KEY (departure_port_id) REFERENCES ports (port_id),
    CONSTRAINT fk_route_arrival FOREIGN KEY (arrival_port_id) REFERENCES ports (port_id)
);

CREATE TABLE voyages (
    voyage_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ship_id             BIGINT NOT NULL,
    route_id            BIGINT NOT NULL,
    departure_date      DATE NOT NULL,
    arrival_date        DATE,
    status              VARCHAR(30) DEFAULT 'SCHEDULED',
    CONSTRAINT fk_voyage_ship FOREIGN KEY (ship_id) REFERENCES container_ships (ship_id),
    CONSTRAINT fk_voyage_route FOREIGN KEY (route_id) REFERENCES shipping_routes (route_id)
);

CREATE TABLE shipping_logs (
    log_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    voyage_id           BIGINT NOT NULL,
    container_id        VARCHAR(20) NOT NULL,
    event_type          VARCHAR(50) NOT NULL,
    event_timestamp     TIMESTAMP NOT NULL,
    location_city_id    BIGINT,
    description         TEXT,
    CONSTRAINT fk_log_voyage FOREIGN KEY (voyage_id) REFERENCES voyages (voyage_id),
    CONSTRAINT fk_log_city FOREIGN KEY (location_city_id) REFERENCES cities (city_id)
);

-- =============================================================
-- 3. Commerce: Shopping Mall & Catalog
-- =============================================================
CREATE TABLE malls (
    mall_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mall_name           VARCHAR(150) NOT NULL,
    domain              VARCHAR(120) UNIQUE NOT NULL,
    super_admin_id      BIGINT,
    active_flag         CHAR(1) DEFAULT 'Y' CHECK (active_flag IN ('Y','N')),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE mall_users (
    user_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mall_id             BIGINT NOT NULL,
    role_code           VARCHAR(30) NOT NULL CHECK (role_code IN ('SUPER_ADMIN','MALL_ADMIN','CUSTOMER','INSTITUTION_BUYER')),
    email               VARCHAR(150) UNIQUE NOT NULL,
    password_hash       VARCHAR(255) NOT NULL,
    full_name           VARCHAR(150),
    phone_number        VARCHAR(30),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_mall FOREIGN KEY (mall_id) REFERENCES malls (mall_id)
);

CREATE TABLE categories (
    category_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parent_category_id  BIGINT,
    category_name       VARCHAR(120) NOT NULL,
    category_level      SMALLINT,
    display_order       INTEGER,
    CONSTRAINT fk_category_parent FOREIGN KEY (parent_category_id) REFERENCES categories (category_id)
);

CREATE TABLE products (
    product_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mall_id             BIGINT NOT NULL,
    sku                 VARCHAR(60) UNIQUE NOT NULL,
    product_name        VARCHAR(200) NOT NULL,
    description         TEXT,
    default_price       DECIMAL(12,2) NOT NULL,
    currency_code       VARCHAR(3) NOT NULL,
    package_type_id     BIGINT,
    weight_kg           DECIMAL(10,3),
    volume_cbm          DECIMAL(10,4),
    active_flag         CHAR(1) DEFAULT 'Y' CHECK (active_flag IN ('Y','N')),
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_mall FOREIGN KEY (mall_id) REFERENCES malls (mall_id)
);

CREATE TABLE product_categories (
    product_id          BIGINT NOT NULL,
    category_id         BIGINT NOT NULL,
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_pc_product FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_pc_category FOREIGN KEY (category_id) REFERENCES categories (category_id)
);

CREATE TABLE package_types (
    package_type_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    package_name        VARCHAR(100) NOT NULL,
    units_per_package   INTEGER DEFAULT 1,
    description         TEXT
);

CREATE TABLE price_history (
    price_history_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id          BIGINT NOT NULL,
    start_date          DATE NOT NULL,
    end_date            DATE,
    price               DECIMAL(12,2) NOT NULL,
    currency_code       VARCHAR(3) NOT NULL,
    CONSTRAINT fk_price_product FOREIGN KEY (product_id) REFERENCES products (product_id)
);

-- =============================================================
-- 4. Warehouse & Inventory (WMS)
-- =============================================================
CREATE TABLE warehouses (
    warehouse_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    mall_id             BIGINT NOT NULL,
    warehouse_name      VARCHAR(150) NOT NULL,
    city_id             BIGINT,
    address_line1       VARCHAR(200),
    address_line2       VARCHAR(200),
    postal_code         VARCHAR(20),
    CONSTRAINT fk_warehouse_mall FOREIGN KEY (mall_id) REFERENCES malls (mall_id),
    CONSTRAINT fk_warehouse_city FOREIGN KEY (city_id) REFERENCES cities (city_id)
);

CREATE TABLE inventory (
    inventory_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id        BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    quantity_on_hand    INTEGER NOT NULL DEFAULT 0,
    quantity_reserved   INTEGER NOT NULL DEFAULT 0,
    quantity_in_transit INTEGER NOT NULL DEFAULT 0,
    last_counted_at     TIMESTAMP,
    CONSTRAINT uq_inventory UNIQUE (warehouse_id, product_id),
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id),
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES products (product_id)
);

CREATE TABLE stock_movements (
    movement_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inventory_id        BIGINT NOT NULL,
    movement_type       VARCHAR(30) NOT NULL CHECK (movement_type IN ('INBOUND','OUTBOUND','ADJUSTMENT')),
    quantity            INTEGER NOT NULL,
    reference_type      VARCHAR(50),
    reference_id        BIGINT,
    movement_timestamp  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    remarks             TEXT,
    CONSTRAINT fk_movement_inventory FOREIGN KEY (inventory_id) REFERENCES inventory (inventory_id)
);

-- =============================================================
-- 5. Orders & Carts
-- =============================================================
CREATE TABLE carts (
    cart_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id             BIGINT NOT NULL,
    status_code         VARCHAR(30) DEFAULT 'ACTIVE',
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cart_user FOREIGN KEY (user_id) REFERENCES mall_users (user_id)
);

CREATE TABLE cart_items (
    cart_item_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cart_id             BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    quantity            INTEGER NOT NULL,
    unit_price          DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_cart_item_cart FOREIGN KEY (cart_id) REFERENCES carts (cart_id),
    CONSTRAINT fk_cart_item_product FOREIGN KEY (product_id) REFERENCES products (product_id)
);

CREATE TABLE orders (
    order_id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cart_id             BIGINT,
    buyer_user_id       BIGINT NOT NULL,
    order_type          VARCHAR(30) CHECK (order_type IN ('PERSONAL','INSTITUTION')),
    order_status        VARCHAR(30) NOT NULL,
    order_date          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount        DECIMAL(14,2) NOT NULL,
    currency_code       VARCHAR(3) NOT NULL,
    CONSTRAINT fk_order_cart FOREIGN KEY (cart_id) REFERENCES carts (cart_id),
    CONSTRAINT fk_order_buyer FOREIGN KEY (buyer_user_id) REFERENCES mall_users (user_id)
);

CREATE TABLE order_items (
    order_item_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id            BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    quantity            INTEGER NOT NULL,
    unit_price          DECIMAL(12,2) NOT NULL,
    currency_code       VARCHAR(3) NOT NULL,
    CONSTRAINT fk_order_item_order FOREIGN KEY (order_id) REFERENCES orders (order_id),
    CONSTRAINT fk_order_item_product FOREIGN KEY (product_id) REFERENCES products (product_id)
);

-- =============================================================
-- 6. Institutional Procurement & Usage Tracking
-- =============================================================
CREATE TABLE institutions (
    institution_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    institution_type    VARCHAR(50) CHECK (institution_type IN ('ELEMENTARY','MIDDLE','HIGH','UNIVERSITY','OTHER')),
    institution_name    VARCHAR(200) NOT NULL,
    country_code        VARCHAR(3),
    city_id             BIGINT,
    address_line1       VARCHAR(200),
    address_line2       VARCHAR(200),
    CONSTRAINT fk_institution_country FOREIGN KEY (country_code) REFERENCES countries (country_code),
    CONSTRAINT fk_institution_city FOREIGN KEY (city_id) REFERENCES cities (city_id)
);

CREATE TABLE institution_orders (
    institution_order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    institution_id       BIGINT NOT NULL,
    order_id             BIGINT NOT NULL,
    requester_name       VARCHAR(150),
    grade_level          VARCHAR(30),
    class_name           VARCHAR(50),
    usage_period_start   DATE,
    usage_period_end     DATE,
    CONSTRAINT fk_io_institution FOREIGN KEY (institution_id) REFERENCES institutions (institution_id),
    CONSTRAINT fk_io_order FOREIGN KEY (order_id) REFERENCES orders (order_id)
);

CREATE TABLE product_usage_logs (
    usage_log_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    institution_order_id BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    usage_date          DATE NOT NULL,
    grade_level         VARCHAR(30),
    class_name          VARCHAR(50),
    quantity_used       INTEGER NOT NULL,
    remarks             TEXT,
    CONSTRAINT fk_usage_institution_order FOREIGN KEY (institution_order_id) REFERENCES institution_orders (institution_order_id),
    CONSTRAINT fk_usage_product FOREIGN KEY (product_id) REFERENCES products (product_id)
);

-- =============================================================
-- 7. Logging & Auditing
-- =============================================================
CREATE TABLE audit_logs (
    audit_log_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_name         VARCHAR(100) NOT NULL,
    entity_id           BIGINT,
    action_type         VARCHAR(30) NOT NULL,
    performed_by        BIGINT,
    performed_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    change_payload      TEXT,
    CONSTRAINT fk_audit_user FOREIGN KEY (performed_by) REFERENCES mall_users (user_id)
);

CREATE TABLE login_history (
    login_history_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id             BIGINT NOT NULL,
    login_timestamp     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address          VARCHAR(45),
    user_agent          VARCHAR(255),
    CONSTRAINT fk_login_user FOREIGN KEY (user_id) REFERENCES mall_users (user_id)
);

-- =============================================================
-- 8. Reference & Supporting Tables
-- =============================================================
CREATE TABLE currencies (
    currency_code       VARCHAR(3) PRIMARY KEY,
    currency_name       VARCHAR(80) NOT NULL,
    symbol              VARCHAR(10)
);

CREATE TABLE exchange_rates (
    exchange_rate_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    base_currency       VARCHAR(3) NOT NULL,
    target_currency     VARCHAR(3) NOT NULL,
    rate_date           DATE NOT NULL,
    conversion_rate     DECIMAL(18,6) NOT NULL,
    CONSTRAINT fk_er_base FOREIGN KEY (base_currency) REFERENCES currencies (currency_code),
    CONSTRAINT fk_er_target FOREIGN KEY (target_currency) REFERENCES currencies (currency_code)
);

-- =============================================================
-- Sample Seed Data
-- =============================================================
INSERT INTO countries (country_code, country_name, iso_alpha3, region, currency_code)
VALUES ('KOR','South Korea','KOR','Asia','KRW'),
       ('USA','United States','USA','North America','USD'),
       ('DEU','Germany','DEU','Europe','EUR');

INSERT INTO cities (country_code, city_name, is_port_city, latitude, longitude, population)
VALUES ('KOR','Busan', 'Y', 35.1796, 129.0756, 3400000),
       ('KOR','Seoul', 'N', 37.5665, 126.9780, 9700000),
       ('USA','Los Angeles', 'Y', 34.0522, -118.2437, 3890000);

INSERT INTO malls (mall_name, domain, super_admin_id)
VALUES ('Global Trade Mall','globalmall.example', NULL);

INSERT INTO package_types (package_name, units_per_package)
VALUES ('Single Unit', 1), ('Case of 12', 12);

INSERT INTO products (mall_id, sku, product_name, description, default_price, currency_code, package_type_id)
VALUES (1, 'SKU-0001', 'Standard Laptop', '15-inch laptop for education', 1200.00, 'USD', 1),
       (1, 'SKU-0002', 'STEM Robotics Kit', 'Robotics learning kit', 750.00, 'USD', 2);

INSERT INTO warehouses (mall_id, warehouse_name, city_id, address_line1)
VALUES (1, 'Busan Central Warehouse', 1, '123 Port Rd'),
       (1, 'Seoul Education Hub', 2, '456 Learning Ave');

INSERT INTO inventory (warehouse_id, product_id, quantity_on_hand, quantity_reserved)
VALUES (1, 1, 250, 30),
       (2, 2, 80, 10);

INSERT INTO institutions (institution_type, institution_name, country_code, city_id)
VALUES ('HIGH','Busan High School','KOR',1),
       ('UNIVERSITY','Seoul Tech University','KOR',2);

INSERT INTO institution_orders (institution_id, order_id, requester_name, grade_level, class_name, usage_period_start)
VALUES (1, 1, 'Mr. Kim', 'Grade 11', 'Class A', '2025-03-01');

INSERT INTO product_usage_logs (institution_order_id, product_id, usage_date, grade_level, class_name, quantity_used)
VALUES (1, 2, '2025-04-15', 'Grade 11', 'Class A', 5);

