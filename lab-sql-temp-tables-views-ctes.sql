USE sakila;

-- Step 1: Create a view summarizing rental information per customer
CREATE VIEW customer_rental_summary AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.email,
    COUNT(r.rental_id)                      AS rental_count
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email;
    
SELECT * FROM customer_rental_summary
ORDER BY rental_count DESC
LIMIT 10;

-- Step 2: Create a temporary table with total payments per customer
CREATE TEMPORARY TABLE customer_payment_summary AS
SELECT
    crs.customer_id,
    crs.first_name,
    crs.email,
    crs.rental_count,
    COALESCE(SUM(p.amount), 0) AS total_paid
FROM customer_rental_summary crs
LEFT JOIN payment p ON crs.customer_id = p.customer_id
GROUP BY
    crs.customer_id,
    crs.full_name,
    crs.email,
    crs.rental_count;
    
SELECT *
FROM customer_payment_summary
ORDER BY total_paid DESC
LIMIT 10;    

-- Step 1: Create the view (if not already created)
CREATE OR REPLACE VIEW customer_rental_summary AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.email,
    COUNT(r.rental_id)                      AS rental_count
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email;

-- Step 2: Create the temporary table
CREATE TEMPORARY TABLE customer_payment_summary AS
SELECT
    crs.customer_id,
    crs.full_name,
    crs.email,
    crs.rental_count,
    COALESCE(SUM(p.amount), 0) AS total_paid
FROM customer_rental_summary crs
LEFT JOIN payment p ON crs.customer_id = p.customer_id
GROUP BY
    crs.customer_id,
    crs.full_name,
    crs.email,
    crs.rental_count;

-- Step 3: CTE + Final Customer Summary Report
WITH customer_summary_cte AS (
    SELECT
        crs.full_name,
        crs.email,
        crs.rental_count,
        cps.total_paid
    FROM customer_rental_summary crs
    JOIN customer_payment_summary cps ON crs.customer_id = cps.customer_id
)
SELECT
    full_name,
    email,
    rental_count,
    total_paid,
    CASE
        WHEN rental_count = 0 THEN 0
        ELSE ROUND(total_paid / rental_count, 2)
    END AS average_payment_per_rental
FROM customer_summary_cte
ORDER BY total_paid DESC;