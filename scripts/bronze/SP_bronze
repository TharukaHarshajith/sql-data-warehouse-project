/*
Purpose:
Loads raw CRM and ERP source data from CSV files into the Bronze layer tables.
This procedure performs a full refresh by truncating existing data and reloading
it using BULK INSERT operations, while logging execution times and handling errors.
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	BEGIN TRY 

		DECLARE @start_time DATE, @end_time DATE, @layer_start_time DATE
		
		SET @layer_start_time = GETDATE();

		PRINT '======================================================';
		PRINT 'Bronze Layer Loadign...';
		PRINT '======================================================';

		PRINT '------------------------------------------------------';
		PRINT 'CRM info extraction';
		PRINT '------------------------------------------------------';

		SET @start_time = GETDATE();

		-- Full refresh to ensure no residual or duplicate data
		PRINT '>>>TRUNCATINT bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		-- Load customer data from CRM source file
		PRINT '>>>INSERTING data into bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\For_Job\SQL\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH(
			FIRSTROW = 2, -- Skip header row
			FIELDTERMINATOR = ',',
			TABLOCK -- Improve bulk load performance
		);

		SET @end_time = GETDATE();
		PRINT '>>>Load duration	: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ 'seconds';
		PRINT '>>>---------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>>>TRUNCATE bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>>>INSER data into bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\For_Job\SQL\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>>>Load duration	: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ 'seconds';
		PRINT '>>>---------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>>>TRUNCATE bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>>>INSER data into bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\For_Job\SQL\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>>>Load duration	: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ 'seconds';
		PRINT '>>>---------------------------------------------------';

		PRINT '------------------------------------------------------';
		PRINT 'ERP info extraction';
		PRINT '------------------------------------------------------';
	
		SET @start_time = GETDATE();

		PRINT '>>>TRUNCATE bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>>>INSER data into bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'D:\For_Job\SQL\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>>>Load duration	: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ 'seconds';
		PRINT '>>>---------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>>>TRUNCATE bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>>>INSER data into bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'D:\For_Job\SQL\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>>>Load duration	: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ 'seconds';
		PRINT '>>>---------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>>>TRUNCATE bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>>>INSER data into bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'D:\For_Job\SQL\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE();

		PRINT '>>>Load duration	: '+ CAST(DATEDIFF(second,@start_time,@end_time) AS NVARCHAR)+ 'seconds';
		PRINT '>>>---------------------------------------------------';

		PRINT '======================================================';
		PRINT 'Loading bronze layer is completed';
		PRINT '>>>Total executuin time :' + CAST(DATEDIFF(second,@layer_start_time ,@end_time) AS NVARCHAR)+ 'seconds===';
		PRINT '======================================================';

	END TRY

	BEGIN CATCH

		PRINT '=================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';

		-- Capture detailed SQL Server error diagnostics
		PRINT 'ERROR Message	: ' + ERROR_MESSAGE();
		PRINT 'ERROR Number		: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR State		: ' + CAST(ERROR_STATE() AS NVARCHAR);

		PRINT '=================================================';
	
	END CATCH

END
