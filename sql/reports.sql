-- SQL Report Queries for Raw Data Inspection

-- REPORT (A): Order totals
SELECT 
    COUNT(*) AS total_orders,
    ROUND(SUM(o.quantity * p.price * (1.0 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_revenue,
    ROUND(AVG(o.quantity * p.price * (1.0 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS avg_order_value
FROM orders o
JOIN products p ON o.product_id = p.product_id;
/*
EXPECTED OUTPUT:
total_orders|total_revenue|avg_order_value
180|99860.2|554.78
*/

-- REPORT (B): COUNT(*) vs COUNT(column)
SELECT 
    COUNT(*) AS total_rows,
    COUNT(rating) AS rated_orders,
    COUNT(*) - COUNT(rating) AS unrated_orders
FROM orders;
/*
EXPECTED OUTPUT:
total_rows|rated_orders|unrated_orders
180|165|15
*/

-- REPORT (C): LEFT JOIN with zero-match row + Validation
-- Query 1: LEFT JOIN
SELECT 
    c.customer_id, 
    c.name, 
    c.city
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.city
HAVING COUNT(o.order_id) = 0;
/*EXPECTED OUTPUT Query 1:
customer_id|name|city
C045|Vihaan|Mumbai
*/
-- Query 2: NOT IN Subquery Validation
SELECT 
    c.customer_id, 
    c.name, 
    c.city
FROM customers c
WHERE c.customer_id NOT IN (SELECT DISTINCT customer_id FROM orders);
/*
EXPECTED OUTPUT Query 2:
customer_id|name|city
C045|Vihaan|Mumbai
*/

-- REPORT (D): GROUP BY + HAVING on City Return Rates
SELECT 
    c.city,
    COUNT(o.order_id) AS total_orders,
    SUM(o.returned) AS returned_orders,
    ROUND(CAST(SUM(o.returned) AS FLOAT) / COUNT(o.order_id) * 100.0, 1) AS return_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.city
HAVING return_rate_pct > 20.0
ORDER BY return_rate_pct DESC;
/*
EXPECTED OUTPUT:
city|total_orders|returned_orders|return_rate_pct
Jaipur|19|8|42.1
Lucknow|49|15|30.6
Bangalore|33|8|24.2
*/

-- REPORT (E): Ranking with ORDER BY + LIMIT/OFFSET
-- Query 1: Top 5
SELECT 
    c.customer_id,
    c.name,
    ROUND(SUM(o.quantity * p.price * (1.0 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_spend
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spend DESC, c.customer_id ASC
LIMIT 5;
/*
EXPECTED OUTPUT Top 5:
customer_id|name|total_spend
C043|Reyansh|12920.0
C026|Isha|8371.6
C008|Meera|4564.6
C011|Arjun|4111.0
C042|Sanya|3785.0
*/
-- Query 2: Ranks 3-5
SELECT 
    c.customer_id,
    c.name,
    ROUND(SUM(o.quantity * p.price * (1.0 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS total_spend
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spend DESC, c.customer_id ASC
LIMIT 3 OFFSET 2;
/*
EXPECTED OUTPUT Rank 3-5 (LIMIT 3 OFFSET 2):
customer_id|name|total_spend
C008|Meera|4564.6
C011|Arjun|4111.0
C042|Sanya|3785.0
*/

-- REPORT (F): Three-table JOIN with Category Performance
SELECT 
    p.category,
    COUNT(o.order_id) AS order_count,
    ROUND(SUM(o.quantity * p.price * (1.0 - COALESCE(o.discount_pct, 0) / 100.0)), 2) AS category_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY p.category
ORDER BY category_revenue DESC;
/*
EXPECTED OUTPUT:
category|order_count|category_revenue
Haircare|54|44956.1
Skincare|60|27346.0
Babycare|30|16805.0
PersonalCare|36|10753.1
*/

-- REPORT (G): LIKE pattern match
SELECT customer_id, name
FROM customers
WHERE name LIKE 'A%';
/*
EXPECTED OUTPUT:
customer_id|name
C001|Aarav
C003|Aditi
C004|Ananya
C011|Arjun
C021|Aryan
C030|Anika
C031|Aditya
C036|Aisha
C041|Ayaan
C044|Aria
*/

-- REPORT (H): DISTINCT Acquisition Sources
SELECT DISTINCT acquisition_source
FROM customers
ORDER BY acquisition_source;
/*
EXPECTED OUTPUT:
acquisition_source
Ad
Organic
Referral
Social
*/

-- REPORT (I): ALTER TABLE + UPDATE with CASE

SET SQL_SAFE_UPDATES = 0;
/* Since we're not using WHERE clause so SQL security doesn't allow updation, so we are disabling safe update mode */

ALTER TABLE customers ADD loyalty_tier VARCHAR(10);

UPDATE customers 
SET loyalty_tier = CASE 
    WHEN city_tier = 1 THEN 'Gold' 
    ELSE 'Silver' 
END;

SELECT loyalty_tier, COUNT(*) 
FROM customers 
GROUP BY loyalty_tier;

SET SQL_SAFE_UPDATES = 1;
/*
turning back safe update mode on
EXPECTED OUTPUT:
loyalty_tier|COUNT(*)
Gold|28
Silver|17
*/
