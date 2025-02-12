USE restaurant_db;

-- Creating views
-- Updatable

DROP VIEW IF EXISTS vw_reservations_per_day;
CREATE VIEW vw_reservations_per_day AS
SELECT 
	r.reservation_id,
    c.customer_id, 
    c.first_name, 
    c.last_name,
    r.party_size,
    t.date
FROM
	dim_reservations r
JOIN
	dim_customers c ON c.customer_id = r.customer_id
JOIN
	dim_time t ON t.date = DATE(r.reservation_time);

-- Non updatable

DROP VIEW IF EXISTS vw_highest_payers;
CREATE VIEW vw_highest_payers AS
SELECT 
    c.customer_id, 
    c.first_name, 
    c.last_name,
    s.payment_id, 
    COUNT(s.menu_item_id) AS total_items,     
    SUM(s.total_price * s.quantity) AS total_amount,   
    GROUP_CONCAT(DISTINCT s.menu_item_id) AS items_ordered  
FROM 
    fact_sales s
JOIN 
    dim_customers c ON s.customer_id = c.customer_id  
GROUP BY 
    c.customer_id, c.first_name, c.last_name, s.payment_id
ORDER BY 
    total_amount DESC;  
    
-- Example of query to the views

SELECT * FROM vw_highest_payers LIMIT 10;
SELECT * FROM vw_reservations_per_day 
WHERE date = '2024-12-28';

-- Subquery to reservarions table

SELECT reservation_id, customer_id, party_size, reservation_time
FROM dim_reservations
WHERE party_size = (
    SELECT MAX(party_size)
    FROM dim_reservations
);

-- Group by and Having query

SELECT customer_id, COUNT(reservation_id) AS total_reservations
FROM dim_reservations
GROUP BY customer_id
HAVING COUNT(reservation_id) > 5;

-- Function for revenue by day

DROP FUNCTION IF EXISTS GetTotalRevenueByDate;
DELIMITER //
CREATE FUNCTION GetTotalRevenueByDate(sale_date DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT SUM(total_price) INTO total
    FROM fact_sales
    WHERE time_id = sale_date;
    RETURN total;
END//
DELIMITER ;

-- Example of function call

SELECT GetTotalRevenueByDate('2024-10-15') AS total_revenue;

-- Create Stored Procedure

DROP PROCEDURE IF EXISTS UpdateSaleTotalPrice;
DELIMITER //
CREATE PROCEDURE UpdateSaleTotalPrice(
    IN sale_id INT,
    IN new_price DECIMAL(10,2)
)
BEGIN
    UPDATE fact_sales
    SET total_price = new_price
    WHERE sale_id = sale_id;
END//
DELIMITER ;

-- Example of calling procedure

CALL UpdateSaleTotalPrice(1, 75.00);