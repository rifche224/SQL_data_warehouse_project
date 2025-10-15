/******************************************************************************************
* Nom du fichier  : code_script_bronze.sql
* Auteur          : Cherif
* Objectif        : Créer les tables de la couche BRONZE à partir des sources CRM et ERP et charger les données dans les tables.
*
* Description     :
* Ce fichier définit les tables de la couche BRONZE, conformes à un modèle 
* en étoile (star schema), pour permettre d'alimenter notre data warehouse.
******************************************************************************************/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @start_batch_time DATETIME, @end_batch_time DATETIME;
    SET @start_batch_time = GETDATE()
    BEGIN TRY
    PRINT '==================================================';
    PRINT 'Chargement des données brutes sur la couche bronze';
    PRINT '==================================================';

    PRINT '>> Création des TABLES de la SOURCE CRM';
    DROP TABLE IF EXISTS bronze.crm_cust_info;
    CREATE TABLE bronze.crm_cust_info(
        cst_id INT,
        cst_key NVARCHAR(50),
        cst_firstname NVARCHAR(50),
        cst_lastname NVARCHAR(50),
        cst_material_status NVARCHAR(50),
        cst_gndr NVARCHAR(50),
        cst_create_date date
    );

    DROP TABLE IF EXISTS bronze.crm_prd_info;
    CREATE TABLE  bronze.crm_prd_info(
        prd_id INT,
        prd_key NVARCHAR(50),
        prd_nm NVARCHAR(50),
        prd_cost INT,
        prd_line NVARCHAR(50),
        prd_start_dt DATE,
        prd_end_dt DATE
    );

    DROP TABLE IF EXISTS bronze.crm_sales_details;
    CREATE TABLE bronze.crm_sales_details(
        sls_ord_num NVARCHAR(25),
        sls_prd_key NVARCHAR(25),
        sls_cust_id INT,
        sls_order_dt INT,
        sls_ship_dt INT,
        sls_due_dt INT,
        sls_sales INT,
        sls_quantity INT,
        sls_price INT
    );

    PRINT '>> Création des TABLES DE LA SOURCE ERP';
    DROP TABLE IF EXISTS bronze.erp_cust_az12;
    CREATE TABLE bronze.erp_cust_az12(
        cid NVARCHAR(50),
        bdate DATE,
        gen NVARCHAR(20)
    );

    DROP TABLE IF EXISTS bronze.erp_loc_a101;
    CREATE TABLE bronze.erp_loc_a101(
        cid NVARCHAR(50),
        cntry NVARCHAR(20)
    );

    DROP TABLE IF EXISTS bronze.erp_cat_g1v2;
    CREATE TABLE  bronze.erp_cat_g1v2(
        id NVARCHAR(50),
        cat NVARCHAR(50),
        subcat NVARCHAR(50),
        maintenance NVARCHAR(50)
    );

    SET @start_time = GETDATE();
    PRINT '>> Ingestion des données depuis les SOURCES CRM & ERP';
    PRINT '>> 1. CRM - Customer Info';
    TRUNCATE TABLE bronze.crm_cust_info;
    BULK INSERT bronze.crm_cust_info
    FROM '/datasets/data_source_CRM/cust_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        TABLOCK
    );
    SET @end_time = GETDATE();
    PRINT '>> Durée de chargement :' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
    
    SET @start_time = GETDATE();
    PRINT '>> 2. CRM - Products';
    TRUNCATE TABLE bronze.crm_prd_info;
    BULK INSERT bronze.crm_prd_info
    FROM '/datasets/data_source_CRM/prd_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        TABLOCK
    );
    SET @end_time = GETDATE();
    PRINT '>> Durée de chargement :' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

    SET @start_time = GETDATE();
    PRINT '>> CRM - Sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;
    BULK INSERT bronze.crm_sales_details
    FROM '/datasets/data_source_CRM/sales_details.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        TABLOCK
    );
    SET @end_time = GETDATE();
    PRINT '>> Durée de chargement :' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

    SET @start_time = GETDATE();
    PRINT '>> 4. ERP - Cat_g1v2';
    TRUNCATE TABLE bronze.erp_cat_g1v2;
    BULK INSERT bronze.erp_cat_g1v2
    FROM '/datasets/data_source_ERP/PX_CAT_G1V2.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        TABLOCK
    );
    SET @end_time = GETDATE();
    PRINT '>> Durée de chargement :' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

    SET @start_time = GETDATE();
    PRINT '>> 5. ERP - Cust_az12'
    TRUNCATE TABLE bronze.erp_cust_az12;
    BULK INSERT bronze.erp_cust_az12
    FROM '/datasets/data_source_ERP/CUST_AZ12.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        TABLOCK
    );
    SET @end_time = GETDATE();
    PRINT '>> Durée de chargement :' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

    SET @start_time = GETDATE()
    PRINT '>> 6. ERP - LOC_A101';
    TRUNCATE TABLE bronze.erp_loc_a101;
    BULK INSERT bronze.erp_loc_a101
    FROM '/datasets/data_source_ERP/LOC_A101.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        TABLOCK
    );
    SET @end_time = GETDATE();
    PRINT '>> Durée de chargement :' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
    
    SET @end_batch_time = GETDATE();
    PRINT '=====================================================================';
    PRINT 'Le chargement complet des données brutes est terminé';
    PRINT '>> Temps de chargement total est :' + CAST(DATEDIFF(second, @start_batch_time, @end_batch_time) AS NVARCHAR) + ' seconds';
    PRINT '=====================================================================';
    END TRY
    BEGIN CATCH
       PRINT '=====================================================================';
       PRINT 'Erreur de chargement des données sur la couche bronze';
       PRINT 'Erreur ' + ERROR_MESSAGE();
       PRINT 'Erreur' + CAST (ERROR_NUMBER() AS NVARCHAR);
       PRINT 'Erreur' + CAST (ERROR_STATE() AS NVARCHAR);
       PRINT '=====================================================================';
    END CATCH
END