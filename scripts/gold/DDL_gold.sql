/*
Purpose:
Creates Gold layer dimensional views for analytical reporting and business intelligence.
The views organize cleaned Silver layer data into dimension and fact structures
following a star schema design for downstream analytics and dashboarding.
*/

-- =========================================================
-- VIEW: gold.dim_customers
-- PURPOSE: Customer Dimension
-- =========================================================

IF OBJECT_ID ('gold.dim_customers','V') IS NOT NULL
	DROP VIEW gold.dim_customers;

GO

CREATE VIEW gold.dim_customers AS

SELECT
	-- Generate surrogate customer key
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,

	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,

	la.cntry AS country,

	ci.cst_material_status AS material_status,

	-- Prioritize CRM gender value over ERP value
	CASE 
		WHEN ci.cst_gendr != 'n/a' THEN ci.cst_gendr
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,

	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date	

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid;

GO


-- =========================================================
-- VIEW: gold.dim_products
-- PURPOSE: Product Dimension
-- =========================================================

IF OBJECT_ID ('gold.dim_products','V') IS NOT NULL
	DROP VIEW gold.dim_products;

GO

CREATE VIEW gold.dim_products AS

SELECT
	-- Generate surrogate product key
	ROW_NUMBER() OVER(
		ORDER BY pin.prd_start_date, pin.prd_id
	) AS product_key,

	pin.prd_id AS product_id,
	pin.sls_prd_key AS product_number,
	pin.prd_nm AS product_name,
	pin.cat_id AS category_id,

	pc.cat AS category,
	pc.subcat AS subcategory,	
	pc.maintenance,

	pin.prd_cost AS cost,
	pin.prd_line AS product_line,
	pin.prd_start_date AS start_date

FROM silver.crm_prd_info pin

LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pin.cat_id = pc.id

-- Exclude historical product versions
WHERE pin.prd_end_date IS NULL;

GO


-- =========================================================
-- VIEW: gold.fact_sales
-- PURPOSE: Sales Fact Table
-- =========================================================

IF OBJECT_ID ('gold.fact_sales','V') IS NOT NULL
	DROP VIEW gold.fact_sales;

GO

CREATE VIEW gold.fact_sales AS

SELECT
    sd.sls_ord_num AS order_number,

	-- Link to product dimension
    pr.product_key,

	-- Link to customer dimension
    cu.customer_key,

    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,

    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price

FROM silver.crm_sales_details sd

LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id;
