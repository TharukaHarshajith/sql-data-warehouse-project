# Data Catalog

This data catalog describes the data entities used by the SQL Data Warehouse ETL pipeline. It covers Bronze, Silver, and Gold layers, including table and view definitions, key columns, and business purpose.

## Layer Overview

- **Bronze**: Raw source staging tables. Data is loaded directly from source CSV files into SQL Server tables with minimal transformation.
- **Silver**: Cleansed and standardized warehouse tables. Bronze data is transformed, normalized, and enriched for analytical consumption.
- **Gold**: Analytical views. Silver tables are organized into dimensions and facts to support reporting and BI queries.

---

## Bronze Layer Catalog

### bronze.crm_cust_info
- Description: Raw CRM customer master records.
- Source: `datasets/source_crm/cust_info.csv`
- Columns:
  - `cst_id` INT: Customer identifier.
  - `cst_key` NVARCHAR(50): External customer key.
  - `cst_firstname` NVARCHAR(50): First name from source.
  - `cst_lastname` NVARCHAR(50): Last name from source.
  - `cst_material_status` NVARCHAR(50): Marital status code from CRM.
  - `cst_gendr` NVARCHAR(50): Gender code from CRM.
  - `cst_create_date` DATE: Record creation date in source.

### bronze.crm_prd_info
- Description: Raw CRM product metadata.
- Source: `datasets/source_crm/prd_info.csv`
- Columns:
  - `prd_id` INT: Product identifier.
  - `prd_key` NVARCHAR(50): Source product key containing category and product code.
  - `prd_nm` NVARCHAR(50): Product name.
  - `prd_cost` INT: Product cost amount.
  - `prd_line` NVARCHAR(50): Product line code.
  - `prd_start_date` DATE: Product start date.
  - `prd_end_date` DATE: Product end date or version expiration date.

### bronze.crm_sales_details
- Description: Raw CRM sales transactions.
- Source: `datasets/source_crm/sales_details.csv`
- Columns:
  - `sls_ord_num` NVARCHAR(50): Sales order number.
  - `sls_prd_key` NVARCHAR(50): Product key linked to CRM product.
  - `sls_cust_id` INT: Customer identifier.
  - `sls_order_dt` NVARCHAR(50): Order date stored as raw text.
  - `sls_ship_dt` DATE: Shipping date.
  - `sls_due_dt` DATE: Due date.
  - `sls_sales` INT: Sales amount.
  - `sls_quantity` INT: Quantity sold.
  - `sls_price` INT: Unit price.

### bronze.erp_cust_az12
- Description: ERP customer demographic facts.
- Source: `datasets/source_erp/CUST_AZ12.csv`
- Columns:
  - `cid` NVARCHAR(50): ERP customer ID.
  - `bdate` DATE: Customer birthdate.
  - `gen` NVARCHAR(50): Gender value from ERP.

### bronze.erp_loc_a101
- Description: ERP customer geographic data.
- Source: `datasets/source_erp/LOC_A101.csv`
- Columns:
  - `cid` NVARCHAR(50): ERP customer ID.
  - `cntry` NVARCHAR(50): Country code or name.

### bronze.erp_px_cat_g1v2
- Description: ERP product category reference data.
- Source: `datasets/source_erp/PX_CAT_G1V2.csv`
- Columns:
  - `id` NVARCHAR(50): Product category identifier.
  - `cat` NVARCHAR(50): Category name.
  - `subcat` NVARCHAR(50): Subcategory name.
  - `maintenance` NVARCHAR(50): Maintenance or support classification.

---

## Silver Layer Catalog

### silver.crm_cust_info
- Description: Clean and deduplicated CRM customer master table.
- Load logic: `silver.load_silver` transforms and standardizes values from `bronze.crm_cust_info`.
- Columns:
  - `cst_id` INT: Primary customer identifier.
  - `cst_key` NVARCHAR(50): Customer reference key.
  - `cst_firstname` NVARCHAR(50): Trimmed first name.
  - `cst_lastname` NVARCHAR(50): Trimmed last name.
  - `cst_material_status` NVARCHAR(50): Standardized status (`Single`, `Married`, `n/a`).
  - `cst_gendr` NVARCHAR(50): Normalized gender (`Female`, `Male`, `n/a`).
  - `cst_create_date` DATE: Original creation date preserved.
  - `dwh_create_date` DATETIME2: Timestamp when record entered Silver.

### silver.crm_prd_info
- Description: Enriched product master table ready for dimension building.
- Load logic: `silver.load_silver` derives category ID and sales product key.
- Columns:
  - `prd_id` INT: Product identifier.
  - `cat_id` NVARCHAR(50): Derived category ID from `prd_key`.
  - `sls_prd_key` NVARCHAR(50): Derived sales product key.
  - `prd_nm` NVARCHAR(50): Product name.
  - `prd_cost` INT: Product cost, defaulting missing values to `0`.
  - `prd_line` NVARCHAR(50): Normalized product line (`Mountain`, `Road`, `Other Sales`, `Touring`, `n/a`).
  - `prd_start_date` DATE: Product start date.
  - `prd_end_date` DATE: Historical end date derived by `LEAD()`.
  - `dwh_create_date` DATETIME2: Load timestamp.

### silver.crm_sales_details
- Description: Standardized sales transactions with cleaned measures.
- Load logic: `silver.load_silver` converts order date text to `DATE`, recalculates inconsistent sales values, and normalizes prices.
- Columns:
  - `sls_ord_num` NVARCHAR(50): Sales order number.
  - `sls_prd_key` NVARCHAR(50): Sales product key.
  - `sls_cust_id` INT: Customer identifier.
  - `sls_order_dt` DATE: Parsed order date.
  - `sls_ship_dt` DATE: Shipping date.
  - `sls_due_dt` DATE: Due date.
  - `sls_sales` INT: Standardized sales amount.
  - `sls_quantity` INT: Quantity.
  - `sls_price` INT: Standardized price value.
  - `dwh_create_date` DATETIME2: Load timestamp.

### silver.erp_cust_az12
- Description: Cleansed ERP customer demographic data.
- Load logic: `silver.load_silver` removes `NAS` prefixes, nulls future birthdates, and standardizes gender.
- Columns:
  - `cid` NVARCHAR(50): Clean ERP customer ID.
  - `bdate` DATE: Validated birthdate.
  - `gen` NVARCHAR(50): Gender normalized to `Female`, `Male`, or `n/a`.
  - `dwh_create_date` DATETIME2: Load timestamp.

### silver.erp_loc_a101
- Description: Normalized ERP customer location table.
- Load logic: `silver.load_silver` strips formatting characters and standardizes country names.
- Columns:
  - `cid` NVARCHAR(50): Clean ERP customer ID.
  - `cntry` NVARCHAR(50): Normalized country value.
  - `dwh_create_date` DATETIME2: Load timestamp.

### silver.erp_px_cat_g1v2
- Description: ERP product category reference loaded into Silver.
- Load logic: `silver.load_silver` passes data through from Bronze.
- Columns:
  - `id` NVARCHAR(50): Category identifier.
  - `cat` NVARCHAR(50): Category name.
  - `subcat` NVARCHAR(50): Subcategory.
  - `maintenance` NVARCHAR(50): Maintenance classification.
  - `dwh_create_date` DATETIME2: Load timestamp.

---

## Gold Layer Catalog

### gold.dim_customers (view)
- Description: Customer dimension view for reporting.
- Sources:
  - `silver.crm_cust_info`
  - `silver.erp_cust_az12`
  - `silver.erp_loc_a101`
- Key columns:
  - `customer_key` INT: Surrogate key generated by `ROW_NUMBER()`.
  - `customer_id` INT: Original CRM customer identifier.
  - `customer_number` NVARCHAR(50): CRM customer key.
  - `first_name`, `last_name` NVARCHAR(50): Customer name.
  - `country` NVARCHAR(50): Customer country.
  - `material_status` NVARCHAR(50): Marital status.
  - `gender` NVARCHAR(50): Business-friendly gender attribute.
  - `birthdate` DATE: Derived from ERP demographic record.
  - `create_date` DATE: Original CRM creation date.
- Notes: CRM gender is preferred when available; ERP gender is used as fallback.

### gold.dim_products (view)
- Description: Product dimension view for reporting.
- Sources:
  - `silver.crm_prd_info`
  - `silver.erp_px_cat_g1v2`
- Key columns:
  - `product_key` INT: Surrogate key generated by `ROW_NUMBER()`.
  - `product_id` INT: Original CRM product identifier.
  - `product_number` NVARCHAR(50): Sales product key.
  - `product_name` NVARCHAR(50): Product name.
  - `category_id` NVARCHAR(50): Derived category identifier.
  - `category`, `subcategory`, `maintenance` NVARCHAR(50): ERP category metadata.
  - `cost` INT: Product cost.
  - `product_line` NVARCHAR(50): Normalized product line.
  - `start_date` DATE: Product start date.
- Notes: Only current product versions are included (`prd_end_date IS NULL`).

### gold.fact_sales (view)
- Description: Sales fact view capturing transaction measures and dimension links.
- Sources:
  - `silver.crm_sales_details`
  - `gold.dim_products`
  - `gold.dim_customers`
- Key columns:
  - `order_number` NVARCHAR(50): Business order identifier.
  - `product_key` INT: Reference to `gold.dim_products`.
  - `customer_key` INT: Reference to `gold.dim_customers`.
  - `order_date` DATE: Sales order date.
  - `shipping_date` DATE: Shipping date.
  - `due_date` DATE: Due date.
  - `sales_amount` INT: Transaction sales value.
  - `quantity` INT: Units sold.
  - `price` INT: Unit price.
- Notes: Fact view links transactions to dimensions via product and customer surrogate keys.

---

## ETL Process Reference

### Bronze ➜ Silver
- Raw data is loaded into Bronze tables with minimal source-side changes.
- Silver ETL cleans names, standardizes codes, deduplicates records, normalizes product and customer references, and validates date/price logic.

### Silver ➜ Gold
- Gold views transform Silver tables into analytical dimensions and facts.
- Business logic is applied at query time via join rules and surrogate key generation.

## Usage Tips

- Use `bronze.load_bronze` to refresh raw staging data.
- Use `silver.load_silver` to transform and populate warehouse-ready records.
- Use the Gold views for BI queries, dashboards, and reporting.
- Validate Silver stage quality using `tests/quality_checks_silver.sql` before relying on Gold outputs.

## Glossary

- `Surrogate key`: A generated key used for report-friendly join keys in the Gold layer.
- `Raw staging`: Directly loaded data from source systems without business transformations.
- `Standardization`: Converting values to a consistent format for analytics.
- `Enrichment`: Adding derived or lookup data to improve downstream consumption.
