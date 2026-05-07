/*
Purpose:
Performs data quality validation checks on Silver layer tables to identify
duplicates, formatting issues, invalid dates, integrity violations,
and standardization problems before downstream analytics usage.
*/

-- =========================================================
-- TABLE: silver.crm_cust_info
-- TESTING AREA: Customer Information Quality Checks
-- =========================================================

-- Test: Check for NULLs or duplicate primary keys
SELECT
	cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Test: Check for unwanted spaces in first names
SELECT
	cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- Test: Check for unwanted spaces in last names
SELECT
	cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Test: Validate standardized gender values
SELECT DISTINCT
	cst_gendr
FROM silver.crm_cust_info;

-- Test: Validate standardized marital status values
SELECT DISTINCT
	cst_material_status
FROM silver.crm_cust_info;

SELECT * FROM silver.crm_cust_info;


-- =========================================================
-- TABLE: silver.crm_prd_info
-- TESTING AREA: Product Information Quality Checks
-- =========================================================

-- Test: Check for NULLs or duplicate primary keys
SELECT
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Test: Check for unwanted spaces in product names
SELECT 
	prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Test: Check for NULL or negative product costs
SELECT 
	prd_cost
FROM silver.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0;

-- Test: Validate standardized product line values
SELECT DISTINCT
	prd_line
FROM silver.crm_prd_info;

-- Test: Check for invalid product date ranges
SELECT 
	*
FROM silver.crm_prd_info
WHERE prd_end_date < prd_start_date;

SELECT * FROM silver.crm_prd_info;


-- =========================================================
-- TABLE: silver.crm_sales_details
-- TESTING AREA: Sales Details Quality Checks
-- =========================================================

SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details;

-- Test: Check for unwanted spaces in order numbers
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Test: Validate customer reference integrity
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (
	SELECT cst_id 
	FROM silver.crm_cust_info
);

-- Test: Check for invalid ship date formatting
SELECT
	*
FROM(
	SELECT
		sls_ord_num,
		sls_order_dt, 
		sls_ship_dt,
		sls_due_dt
	FROM silver.crm_sales_details
)t 
WHERE LEN(sls_ship_dt) != 8;

-- Test: Preview transformed order date logic
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,

	CASE 
		WHEN LEN(TRIM(sls_order_dt)) != 8 THEN NULL
		ELSE CAST(TRIM(sls_order_dt) AS DATE)
	END AS sls_order_dt_test,

	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details;

-- Test: Check for invalid chronological order of sales dates
SELECT
	*
FROM(
	SELECT
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,

		CASE 
			WHEN LEN(TRIM(sls_order_dt)) != 8 THEN NULL
			ELSE CAST(TRIM(sls_order_dt) AS DATE)
		END AS sls_order_dt,

		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
	FROM bronze.crm_sales_details
)t 
WHERE sls_ship_dt < sls_order_dt
OR sls_due_dt < sls_ship_dt;

-- Test: Validate sales, quantity, and price consistency
SELECT
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL 
OR sls_quantity IS NULL 
OR sls_price IS NULL
OR sls_sales < 0 
OR sls_quantity < 0 
OR sls_price < 0;

SELECT * FROM silver.crm_sales_details;


-- =========================================================
-- TABLE: silver.erp_cust_az12
-- TESTING AREA: ERP Customer Quality Checks
-- =========================================================

-- Test: Validate customer ID prefix cleanup
SELECT 
	cid,
	bdate,
	gen
FROM silver.erp_cust_az12
WHERE cid LIKE 'NAS%';

-- Test: Check for duplicate customer IDs
SELECT 
	cid,
	COUNT(*)
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1;

-- Test: Check for unwanted spaces in customer IDs
SELECT 
	cid
FROM silver.erp_cust_az12
WHERE cid != TRIM(cid);

-- Test: Check for unwanted spaces in gender values
SELECT 
	gen
FROM silver.erp_cust_az12
WHERE gen != TRIM(gen);

-- Test: Validate future birthdates
SELECT 
	cid,
	bdate,
	gen
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();

-- Test: Validate standardized gender values
SELECT DISTINCT
	gen
FROM silver.erp_cust_az12;

SELECT * FROM silver.erp_cust_az12;


-- =========================================================
-- TABLE: silver.erp_loc_a101
-- TESTING AREA: ERP Location Quality Checks
-- =========================================================

-- Test: Preview customer ID cleanup logic
SELECT
	cid,
	REPLACE(cid, '-','') AS cid_test,
	cntry
FROM bronze.erp_loc_a101;

-- Test: Validate standardized country values
SELECT DISTINCT
	cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

SELECT * FROM silver.erp_loc_a101;


-- =========================================================
-- TABLE: silver.erp_px_cat_g1v2
-- TESTING AREA: ERP Product Category Quality Checks
-- =========================================================

-- Test: Detect unmatched category IDs
SELECT
	id,
	cad,
	subcat,
	maintenance
FROM bronze.erp_px_cat_g1v2
WHERE TRIM(id) NOT IN (
	SELECT cat_id 
	FROM silver.crm_prd_info
);

-- Test: Check for unwanted spaces in category data
SELECT
	cad
FROM bronze.erp_px_cat_g1v2
WHERE cad != TRIM(cad)
OR subcat != TRIM(subcat)
OR maintenance != TRIM(maintenance);

-- Test: Validate maintenance category consistency
SELECT DISTINCT
	maintenance
FROM bronze.erp_px_cat_g1v2;

SELECT * FROM silver.erp_px_cat_g1v2;
