/*
Purpose:
Performs data quality validation checks on Gold layer dimension and fact views
to ensure analytical consistency, referential integrity, uniqueness,
and valid business-ready reporting data.
*/

-- =========================================================
-- VIEW: gold.dim_customers
-- TESTING AREA: Customer Dimension Quality Checks
-- =========================================================

-- Test: Check for duplicate or NULL customer keys
SELECT
	customer_key,
	COUNT(*)
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1
OR customer_key IS NULL;

-- Test: Check for duplicate business customer IDs
SELECT
	customer_id,
	COUNT(*)
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
OR customer_id IS NULL;

-- Test: Check for unwanted spaces in customer names
SELECT
	first_name,
	last_name
FROM gold.dim_customers
WHERE first_name != TRIM(first_name)
OR last_name != TRIM(last_name);

-- Test: Validate standardized gender values
SELECT DISTINCT
	gender
FROM gold.dim_customers;

-- Test: Validate standardized marital status values
SELECT DISTINCT
	material_status
FROM gold.dim_customers;

-- Test: Check for future birthdates
SELECT
	customer_id,
	birthdate
FROM gold.dim_customers
WHERE birthdate > GETDATE();

SELECT * FROM gold.dim_customers;


-- =========================================================
-- VIEW: gold.dim_products
-- TESTING AREA: Product Dimension Quality Checks
-- =========================================================

-- Test: Check for duplicate or NULL product keys
SELECT
	product_key,
	COUNT(*)
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1
OR product_key IS NULL;

-- Test: Check for duplicate business product IDs
SELECT
	product_id,
	COUNT(*)
FROM gold.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1
OR product_id IS NULL;

-- Test: Check for unwanted spaces in product names
SELECT
	product_name
FROM gold.dim_products
WHERE product_name != TRIM(product_name);

-- Test: Validate standardized product line values
SELECT DISTINCT
	product_line
FROM gold.dim_products;

-- Test: Check for NULL or negative product costs
SELECT
	product_id,
	cost
FROM gold.dim_products
WHERE cost IS NULL
OR cost < 0;

-- Test: Ensure historical products are excluded
SELECT
	*
FROM gold.dim_products dp
INNER JOIN silver.crm_prd_info sp
ON dp.product_id = sp.prd_id
WHERE sp.prd_end_date IS NOT NULL;

SELECT * FROM gold.dim_products;


-- =========================================================
-- VIEW: gold.fact_sales
-- TESTING AREA: Sales Fact Quality Checks
-- =========================================================

-- Test: Check for NULL dimension references
SELECT
	order_number,
	product_key,
	customer_key
FROM gold.fact_sales
WHERE product_key IS NULL
OR customer_key IS NULL;

-- Test: Validate sales amount calculations
SELECT
	order_number,
	sales_amount,
	quantity,
	price
FROM gold.fact_sales
WHERE sales_amount != quantity * price
OR sales_amount IS NULL
OR quantity IS NULL
OR price IS NULL;

-- Test: Check for negative values
SELECT
	order_number,
	sales_amount,
	quantity,
	price
FROM gold.fact_sales
WHERE sales_amount < 0
OR quantity < 0
OR price < 0;

-- Test: Validate chronological order of dates
SELECT
	order_number,
	order_date,
	shipping_date,
	due_date
FROM gold.fact_sales
WHERE shipping_date < order_date
OR due_date < shipping_date;

-- Test: Check for NULL order dates
SELECT
	order_number
FROM gold.fact_sales
WHERE order_date IS NULL;

-- Test: Detect duplicate sales records
SELECT
	order_number,
	product_key,
	customer_key,
	COUNT(*)
FROM gold.fact_sales
GROUP BY
	order_number,
	product_key,
	customer_key
HAVING COUNT(*) > 1;

SELECT * FROM gold.fact_sales;


-- =========================================================
-- CROSS-VIEW REFERENTIAL INTEGRITY CHECKS
-- =========================================================

-- Test: Validate all product keys exist in product dimension
SELECT
	fs.product_key
FROM gold.fact_sales fs
LEFT JOIN gold.dim_products dp
ON fs.product_key = dp.product_key
WHERE dp.product_key IS NULL;

-- Test: Validate all customer keys exist in customer dimension
SELECT
	fs.customer_key
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc
ON fs.customer_key = dc.customer_key
WHERE dc.customer_key IS NULL;


-- =========================================================
-- GOLD LAYER DATA VOLUME VALIDATION
-- =========================================================

-- Test: Validate row counts across Gold layer views
SELECT 'dim_customers' AS table_name, COUNT(*) AS total_records
FROM gold.dim_customers

UNION ALL

SELECT 'dim_products', COUNT(*)
FROM gold.dim_products

UNION ALL

SELECT 'fact_sales', COUNT(*)
FROM gold.fact_sales;
