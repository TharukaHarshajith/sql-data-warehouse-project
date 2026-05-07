/*
Purpose:
Loads cleaned and standardized data from the Bronze layer into the Silver layer.
This procedure performs data cleansing, normalization, deduplication, validation,
and enrichment before storing warehouse-ready data for downstream analytics.
*/

-- Creating stored procedure for silver layer
--EXEC silver.load_silver

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

	BEGIN TRY

		DECLARE @start_time DATETIME,
				@end_time DATETIME,
				@layer_start_time DATETIME

		SET @layer_start_time = GETDATE();

		PRINT '======================================================';
		PRINT 'Silver Layer Loading...';
		PRINT '======================================================';

		--=================================================================
		PRINT '------------------------------------------------------';
		PRINT 'Loading CRM Customer Information';
		PRINT '------------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>>>Truncating table	: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;

		PRINT '>>>Inserting data into	: silver.crm_cust_info';

		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_material_status,
			cst_gendr,
			cst_create_date
		)

		SELECT
			cst_id,
			cst_key,

			-- Remove leading and trailing spaces from names
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,

			-- Standardize marital status values
			CASE 
				WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
				ELSE 'n/a'
			END AS cst_material_status,

			-- Standardize gender values
			CASE 
				WHEN UPPER(TRIM(cst_gendr)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(cst_gendr)) = 'M' THEN 'Male'
				ELSE 'n/a'
			END AS cst_gendr,

			cst_create_date

		FROM(
			-- Keep only the most recent customer record
			SELECT
				*,
				ROW_NUMBER() OVER(
					PARTITION BY cst_id 
					ORDER BY cst_create_date DESC
				) AS flag
			FROM bronze.crm_cust_info
		)t
		WHERE flag = 1 AND cst_id IS NOT NULL;

		SET @end_time = GETDATE();

		PRINT '>>>Load duration		: ' +
			  CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)
			  + ' seconds';

		PRINT '>>>---------------------------------------------------';

		--=================================================================
		PRINT '------------------------------------------------------';
		PRINT 'Loading CRM Product Information';
		PRINT '------------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>>>Truncating table	: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;

		PRINT '>>>Inserting data into	: silver.crm_prd_info';

		INSERT INTO silver.crm_prd_info(
			prd_id,
			cat_id,
			sls_prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_date,
			prd_end_date
		)

		SELECT
			prd_id,

			-- Extract category identifier from product key
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,

			-- Extract sales product key portion
			SUBSTRING(prd_key,7,LEN(prd_key)) AS sls_prd_key,

			prd_nm,

			-- Replace missing product cost with zero
			ISNULL(prd_cost,0) AS prd_cost,

			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END AS prd_line,

			prd_start_date,

			-- Generate historical product end date
			DATEADD(
				DAY,
				-1,
				LEAD(prd_start_date) OVER (
					PARTITION BY prd_key
					ORDER BY prd_start_date
				)
			) AS prd_end_date

		FROM bronze.crm_prd_info;

		SET @end_time = GETDATE();

		PRINT '>>>Load duration		: ' +
			  CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)
			  + ' seconds';

		PRINT '>>>---------------------------------------------------';

		--=================================================================
		PRINT '------------------------------------------------------';
		PRINT 'Loading CRM Sales Details';
		PRINT '------------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>>>Truncating table	: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;

		PRINT '>>>Inserting data into	: silver.crm_sales_details';

		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)

		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,

			-- Validate and convert order date
			CASE 
				WHEN LEN(TRIM(sls_order_dt)) != 8 THEN NULL
				ELSE CAST(TRIM(sls_order_dt) AS DATE)
			END AS sls_order_dt,

			sls_ship_dt,
			sls_due_dt,

			-- Recalculate invalid or inconsistent sales amounts
			CASE 
				WHEN sls_sales <= 0 
					 OR sls_sales IS NULL 
					 OR sls_sales != sls_quantity * ABS(sls_price)
				THEN sls_price * ABS(sls_quantity)

				ELSE sls_sales
			END AS sls_sales,

			sls_quantity,

			-- Standardize invalid or negative pricing values
			CASE 
				WHEN sls_price = 0 
					 OR sls_price IS NULL
				THEN (sls_sales / sls_quantity)

				WHEN sls_price < 0
				THEN ABS(sls_price)

				ELSE sls_price
			END AS sls_price

		FROM bronze.crm_sales_details;

		SET @end_time = GETDATE();

		PRINT '>>>Load duration		: ' +
			  CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)
			  + ' seconds';

		PRINT '>>>---------------------------------------------------';

		--=================================================================
		PRINT '------------------------------------------------------';
		PRINT 'Loading ERP Customer Information';
		PRINT '------------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>>>Truncating table	: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;

		PRINT '>>>Inserting data into	: silver.erp_cust_az12';

		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)

		SELECT 
			-- Remove source-system prefix from customer IDs
			CASE 
				WHEN cid LIKE 'NAS%' 
				THEN SUBSTRING(cid,4,LEN(cid))
				ELSE cid
			END AS cid,

			-- Ignore future birthdates
			CASE 
				WHEN bdate > GETDATE() 
				THEN NULL
				ELSE bdate
			END AS bdate,

			CASE 
				WHEN UPPER(TRIM(gen)) IN ('F','FEMALE')
				THEN 'Female'

				WHEN UPPER(TRIM(gen)) IN ('M','MALE')
				THEN 'Male'

				ELSE 'n/a'
			END AS gen

		FROM bronze.erp_cust_az12;

		SET @end_time = GETDATE();

		PRINT '>>>Load duration		: ' +
			  CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)
			  + ' seconds';

		PRINT '>>>---------------------------------------------------';

		--=================================================================
		PRINT '------------------------------------------------------';
		PRINT 'Loading ERP Location Information';
		PRINT '------------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>>>Truncating table	: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;

		PRINT '>>>Inserting data into	: silver.erp_loc_a101';

		INSERT INTO silver.erp_loc_a101(
			cid,
			cntry
		)

		SELECT
			-- Remove formatting characters from customer IDs
			REPLACE(cid, '-','') AS cid,

			-- Standardize country names
			CASE 
				WHEN UPPER(TRIM(cntry)) ='DE'
				THEN 'Germany'

				WHEN UPPER(TRIM(cntry)) IN ('USA', 'US')
				THEN 'United States'

				WHEN TRIM(cntry)='' 
					 OR cntry IS NULL
				THEN 'n/a'

				ELSE cntry
			END AS cntry

		FROM bronze.erp_loc_a101;

		SET @end_time = GETDATE();

		PRINT '>>>Load duration		: ' +
			  CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)
			  + ' seconds';

		PRINT '>>>---------------------------------------------------';

		--=================================================================
		PRINT '------------------------------------------------------';
		PRINT 'Loading ERP Product Category Information';
		PRINT '------------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>>>Truncating table	: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;

		PRINT '>>>Inserting data into	: silver.erp_px_cat_g1v2';

		INSERT INTO silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
		)

		SELECT
			id,
			cat,
			subcat,
			maintenance

		FROM bronze.erp_px_cat_g1v2;

		SET @end_time = GETDATE();

		PRINT '>>>Load duration		: ' +
			  CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR)
			  + ' seconds';

		PRINT '>>>---------------------------------------------------';

		--=================================================================

		PRINT '======================================================';
		PRINT 'Loading silver layer is completed';
		PRINT '>>>Total execution time : ' +
			  CAST(DATEDIFF(SECOND,@layer_start_time,@end_time) AS NVARCHAR)
			  + ' seconds';
		PRINT '======================================================';

	END TRY

	BEGIN CATCH

		PRINT '=================================================';
		PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';

		-- Display SQL Server error diagnostics
		PRINT 'ERROR Message	: ' + ERROR_MESSAGE();
		PRINT 'ERROR Number	: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR State	: ' + CAST(ERROR_STATE() AS NVARCHAR);

		PRINT '=================================================';

	END CATCH

END

