/*
=====================================================================================
Data Warehouse Initialization Script with Layered Architecture (Bronze, Silver, Gold)
=====================================================================================
*/


USE master;

CREATE DATABASE DataWarehouse;

USE DataWarehouse;

GO
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
