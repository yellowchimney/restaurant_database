DROP DATABASE IF EXISTS restaurant_db;
CREATE DATABASE restaurant_db;
USE restaurant_db;

DROP TABLE IF EXISTS dim_customers;
CREATE TABLE dim_customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(15),
    loyalty_points INT
);

INSERT INTO dim_customers (customer_id, first_name, last_name, email, phone, loyalty_points)
VALUES
(1, 'Emily', 'Johnson', 'emily.johnson@example.com', '555-123-4567', 100),
(2, 'Michael', 'Smith', 'michael.smith@example.com', '555-234-5678', 150),
(3, 'Sophia', 'Williams', 'sophia.williams@example.com', '555-345-6789', 200),
(4, 'Jacob', 'Brown', 'jacob.brown@example.com', '555-456-7890', 180),
(5, 'Olivia', 'Jones', 'olivia.jones@example.com', '555-567-8901', 220),
(6, 'Ethan', 'Garcia', 'ethan.garcia@example.com', '555-678-9012', 190),
(7, 'Emma', 'Miller', 'emma.miller@example.com', '555-789-0123', 210),
(8, 'Alexander', 'Davis', 'alexander.davis@example.com', '555-890-1234', 170),
(9, 'Ava', 'Rodriguez', 'ava.rodriguez@example.com', '555-901-2345', 240),
(10, 'Daniel', 'Martinez', 'daniel.martinez@example.com', '555-012-3456', 130);

-- Remove existing function if needed
DROP FUNCTION IF EXISTS mutate_name;

-- Create new mutation function
DELIMITER //
CREATE FUNCTION mutate_name(original VARCHAR(50), variation INT) RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE mutated VARCHAR(50);
    DECLARE pos INT;
    DECLARE original_char CHAR(1);
    DECLARE replacement_char CHAR(1);
    
    SET mutated = original;
    SET pos = 1 + variation % CHAR_LENGTH(original);
    SET original_char = SUBSTRING(original, pos, 1);
    
    -- Use controlled vowel substitutions
    SET replacement_char = CASE original_char
        WHEN 'a' THEN 'e'
        WHEN 'e' THEN 'i'
        WHEN 'i' THEN 'y'
        WHEN 'o' THEN 'u'
        WHEN 'u' THEN 'o'
        WHEN 'y' THEN 'i'
        WHEN 's' THEN 'z'
        WHEN 'm' THEN 'n'
        ELSE CHAR(ASCII(original_char) + (variation % 2))
    END;
    
    -- Ensure valid characters
    IF replacement_char NOT BETWEEN 'A' AND 'z' THEN
        SET replacement_char = original_char;
    END IF;
    
    RETURN CONCAT(
        SUBSTRING(mutated, 1, pos - 1),
        replacement_char,
        SUBSTRING(mutated, pos + 1)
    );
END//
DELIMITER ;

-- Generate variations with safe mutations
INSERT INTO dim_customers (customer_id, first_name, last_name, email, phone, loyalty_points)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 49
)
SELECT 
    10 + (base.customer_id - 1) * 49 + numbers.n,
    LOWER(mutate_name(base.first_name, numbers.n)),
    LOWER(mutate_name(base.last_name, numbers.n)),
    CONCAT(
        LOWER(mutate_name(base.first_name, numbers.n)), 
        '.', 
        LOWER(mutate_name(base.last_name, numbers.n)),
        numbers.n,
        '@example.com'
    ),
    CONCAT('555-', LPAD(FLOOR(RAND() * 1000), 3, '0'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0')),
    base.loyalty_points + FLOOR(RAND() * 100)
FROM dim_customers base
CROSS JOIN numbers
WHERE base.customer_id BETWEEN 1 AND 10;

DROP TABLE IF EXISTS dim_employees;
CREATE TABLE dim_employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    position VARCHAR(50),
    hire_date DATE,
    salary DECIMAL(10,2),
    department VARCHAR(50),
    manager VARCHAR(50)
);

INSERT INTO dim_employees
VALUES
(1, 'John', 'Smith', 'Head Chef', '2020-03-15', 68000.00, 'Kitchen', 'Sarah Johnson'),
(2, 'Maria', 'Garcia', 'Sous Chef', '2021-06-01', 52000.00, 'Kitchen', 'John Smith'),
(3, 'Sarah', 'Johnson', 'Restaurant Manager', '2019-01-10', 75000.00, 'Management', NULL),
(4, 'James', 'Brown', 'Server', '2022-02-01', 35000.00, 'Service', 'Sarah Johnson'),
(5, 'Emily', 'Davis', 'Bartender', '2022-05-15', 38000.00, 'Service', 'Sarah Johnson'),
(6, 'Michael', 'Wilson', 'Dishwasher', '2023-01-10', 28000.00, 'Kitchen', 'John Smith'),
(7, 'Linda', 'Martinez', 'Pastry Chef', '2021-09-01', 48000.00, 'Kitchen', 'John Smith'),
(8, 'David', 'Anderson', 'Host', '2023-03-01', 32000.00, 'Service', 'Sarah Johnson'),
(9, 'Karen', 'Taylor', 'Sommelier', '2020-11-01', 42000.00, 'Service', 'Sarah Johnson'),
(10, 'Robert', 'Thomas', 'Line Cook', '2023-06-01', 34000.00, 'Kitchen', 'John Smith');

DROP TABLE IF EXISTS dim_menu;
CREATE TABLE dim_menu (
    menu_id INT PRIMARY KEY,
    item_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(5,2),
    cost DECIMAL(5,2),
    is_vegan BOOLEAN
);

INSERT INTO dim_menu (menu_id, item_name, category, price, cost, is_vegan)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 30
)
SELECT
    n,
    CONCAT('Item ', n),
    CASE 
        WHEN n % 4 = 0 THEN 'Appetizer'
        WHEN n % 4 = 1 THEN 'Main Course'
        WHEN n % 4 = 2 THEN 'Dessert'
        ELSE 'Beverage'
    END,
    ROUND(5 + (RAND() * 45), 2),
    ROUND(5 + (RAND() * 45) * 0.5, 2),
    FLOOR(RAND() * 2)
FROM numbers;

DROP TABLE IF EXISTS dim_time;
CREATE TABLE dim_time (
    time_id INT PRIMARY KEY,
    date DATE,
    day_of_week VARCHAR(10),
    month VARCHAR(10),
    quarter INT,
    year INT
);

INSERT INTO dim_time (time_id, date, day_of_week, month, quarter, year)
WITH RECURSIVE dates AS (
    SELECT 
        1 AS n,
        '2024-01-01' AS dt
    UNION ALL
    SELECT 
        n + 1,
        dt + INTERVAL 1 DAY
    FROM dates
    WHERE n < 365
)
SELECT
    n,
    dt,
    DAYNAME(dt),
    MONTHNAME(dt),
    QUARTER(dt),
    YEAR(dt)
FROM dates;

DROP TABLE IF EXISTS dim_tables;
CREATE TABLE dim_tables (
    table_id INT PRIMARY KEY,
    table_number INT,
    capacity INT,
    location VARCHAR(50)
);

INSERT INTO dim_tables
SELECT
    n,
    n,
    FLOOR(2 + RAND() * 7),
    CASE 
        WHEN n % 3 = 0 THEN 'Patio'
        WHEN n % 3 = 1 THEN 'Main Dining'
        ELSE 'Private Room'
    END
FROM (
    SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
) numbers;

DROP TABLE IF EXISTS dim_reservations;
CREATE TABLE dim_reservations (
    reservation_id INT PRIMARY KEY,
    customer_id INT,
    reservation_time DATETIME,
    party_size INT,
    table_id INT,
    special_requests TEXT,
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (table_id) REFERENCES dim_tables(table_id)
);

-- Insert 1000 reservations with guaranteed valid customer IDs
INSERT INTO dim_reservations (reservation_id, customer_id, reservation_time, party_size, table_id, special_requests)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 1000
)
SELECT
    n,
    1 + (FLOOR(RAND() * 500)),
    TIMESTAMPADD(SECOND, FLOOR(RAND() * 31536000), '2024-01-01 00:00:00'),
    FLOOR(2 + RAND() * 7),  -- Party size 2-8
    FLOOR(1 + RAND() * 15), -- Table IDs 1-15
    CASE WHEN RAND() < 0.3 THEN CONCAT('Special request ', n) ELSE NULL END
    FROM numbers;

DROP TABLE IF EXISTS dim_payments;
CREATE TABLE dim_payments (
    payment_id INT PRIMARY KEY,
    payment_method VARCHAR(50),
    payment_status VARCHAR(20)
);

INSERT INTO dim_payments (payment_id, payment_method, payment_status)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 1000
)
SELECT
    n,
    CASE 
        WHEN n % 4 = 0 THEN 'Credit Card'
        WHEN n % 4 = 1 THEN 'Cash'
        WHEN n % 4 = 2 THEN 'Online'
        ELSE 'Gift Card'
    END,
    CASE 
        WHEN n % 100 = 0 THEN 'Refunded' 
        ELSE 'Completed'
    END
FROM numbers;

DROP TABLE IF EXISTS fact_sales;
CREATE TABLE fact_sales (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    employee_id INT NOT NULL,
    menu_item_id INT NOT NULL,
    time_id INT NOT NULL,
    table_id INT NOT NULL,
    reservation_id INT NULL, 
    payment_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    total_price DECIMAL(10,2) NOT NULL CHECK (total_price > 0),
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (employee_id) REFERENCES dim_employees(employee_id),
    FOREIGN KEY (menu_item_id) REFERENCES dim_menu(menu_id),
    FOREIGN KEY (time_id) REFERENCES dim_time(time_id),
    FOREIGN KEY (table_id) REFERENCES dim_tables(table_id),
    FOREIGN KEY (reservation_id) REFERENCES dim_reservations(reservation_id),
    FOREIGN KEY (payment_id) REFERENCES dim_payments(payment_id)
);

INSERT INTO fact_sales (customer_id, employee_id, menu_item_id, time_id, table_id, reservation_id, payment_id, quantity, total_price)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 1000
)
SELECT
    1 + FLOOR(RAND() * 500),  
    1 + FLOOR(RAND() * 10),   
    1 + FLOOR(RAND() * 30),   
    1 + FLOOR(RAND() * 365),  
    1 + FLOOR(RAND() * 15),   
    CASE WHEN RAND() < 0.7 THEN 1 + FLOOR(RAND() * 1000) ELSE NULL END, 
    1 + FLOOR(RAND() * 1000), 
    1 + FLOOR(RAND() * 5),    
    ROUND((5 + RAND() * 50) * (1 + FLOOR(RAND() * 5)), 2)  
FROM numbers;
