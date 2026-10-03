-- Load raw CSV files into SQLite database
.mode csv
.import data/customers.csv customers
.import data/products.csv products
.import data/orders.csv orders

-- SQLite .import loads empty CSV cells as empty strings ('')
-- Convert empty strings to NULL to preserve correct aggregation behavior
UPDATE orders 
SET discount_pct = NULL 
WHERE discount_pct = '';

UPDATE orders 
SET rating = NULL 
WHERE rating = '';

-- Verification Queries
SELECT COUNT(*) AS customer_count FROM customers; -- Expected: 45
SELECT COUNT(*) AS product_count  FROM products;  -- Expected: 16
SELECT COUNT(*) AS order_count    FROM orders;    -- Expected: 180
