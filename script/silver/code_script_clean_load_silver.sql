--******************************************************************************************
--* Nom du fichier  : code_script_clean_load_silver.sql
--* Auteur          : Cherif
--* Objectif        : Chargement des données nettoyées dans la couche SILVER 
--* Description     :
--* Ce fichier charge les données nettoyées dans la table silver.crm_cust_info.
--*                   et les données nettoyées dans la table silver.crm_prd_info.
--*                   et les données nettoyées dans la table silver.crm_sales_details.
--*                   et les données nettoyées dans la table silver.erp_cust_az12.
--*                   et les données nettoyées dans la table silver.erp_loc_a101.
--*                   et les données nettoyées dans la table silver.erp_cat_g1v2.
--******************************************************************************************
PRINT '==================================================================';
PRINT 'NETTOYAGE ET CHARGEMENT DES DONNÉES CRM & ERP sur la couche SILVER';
PRINT '==================================================================';
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @start_batch_time DATETIME, @end_batch_time DATETIME;
    SET @start_batch_time = GETDATE();
    BEGIN TRY
    PRINT '>> Vidange des tables : silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;
    SET @start_time = GETDATE();
    PRINT '>> Chargement des données : silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info(
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_gndr,
        cst_material_status,
        cst_create_date
    ) SELECT cst_id,
        cst_key,
        TRIM(cst_firstname), 
        TRIM(cst_lastname), 
        CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' 
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' 
            ELSE 'n/a' -- Valeur par défaut
        END cst_gndr,
        CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single' 
            WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
            ELSE 'n/a' -- Valeur par défaut
        END AS cst_material_status, 
        cst_create_date -- Date de création de l'enregistrement
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flags_Last -- Numéro de ligne pour chaque enregistrement
        FROM bronze.crm_cust_info 
        WHERE cst_id IS NOT NULL 
    )T WHERE Flags_Last = 1; -- Filtrage des enregistrements pour ne garder que le dernier enregistrement
    SET @end_time = GETDATE();
    -- Chargement des données nettoyées dans la table silver.crm_prd_info
    TRUNCATE TABLE silver.crm_prd_info;
    SET @start_time = GETDATE();
    INSERT INTO silver.crm_prd_info(
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Extraction de la catégorie du produit
        SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,        -- Extraction de la clé du produit
        prd_nm,
        ISNULL(prd_cost, 0) AS prd_cost,                       -- Remplacement des valeurs nulles par 0
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,                                             -- Mapping des codes à descriptions des valeurs de la colonne prd_line
    -- Calcul de la date de fin du produit, en utilisant la fonction LEAD pour obtenir la date de début du produit suivant et en soustrayant 1 jour
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        DATEADD(day, -1, LEAD(CAST(prd_start_dt AS date)) OVER (PARTITION BY prd_key ORDER BY CAST(prd_start_dt AS DATE))) AS prd_end_dt 
    FROM bronze.crm_prd_info; 
    SET @end_time = GETDATE();
    -- Chargement des données nettoyées dans la table silver.crm_sales_details
    TRUNCATE TABLE silver.crm_sales_details;
    SET @start_time = GETDATE();
    INSERT INTO silver.crm_sales_details(
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_price,
        sls_quantity
    ) SELECT sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE 
        WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL -- Si la date est nulle ou n'a pas 8 caractères, on la met à NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) -- Sinon, on la conserve
        END AS sls_order_dt,
        CASE 
        WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL -- Si la date est nulle ou n'a pas 8 caractères, on la met à NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) -- Sinon, on la conserve
        END AS sls_ship_dt,
        CASE 
        WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL -- Si la date est nulle ou n'a pas 8 caractères, on la met à NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) -- Sinon, on la conserve
        END AS sls_due_dt,
        CASE 
        WHEN sls_sales = 0 OR sls_sales IS NULL  OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
        END AS sls_sales,
        CASE 
        WHEN sls_price IS NULL  OR sls_price <= 0 THEN sls_sales /NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price,
        sls_quantity
    FROM bronze.crm_sales_details; 
    SET @end_time = GETDATE();
    -- Chargement des données nettoyées dans la table silver.ERP_cust_az12
    TRUNCATE TABLE silver.erp_cust_az12;
    SET @start_time = GETDATE();
    INSERT INTO silver.erp_cust_az12(
        cid,
        bdate,
        gen
    )
    SELECT
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, len(cid))
        ELSE cid 
    END AS cid, 
    CASE 
    WHEN bdate > GETDATE() THEN NULL
    ELSE bdate
    END AS bdate,
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen
    FROM bronze.erp_cust_az12;
    SET @end_time = GETDATE();
    -- Chargement des données nettoyées dans la table silver.ERP_loc_a101
    TRUNCATE TABLE silver.erp_loc_a101;
    SET @start_time = GETDATE();
    INSERT INTO silver.erp_loc_a101(
        cid,
        cntry
    )SELECT
    REPLACE(cid, '-', '') AS cid,
    CASE
        WHEN REPLACE(REPLACE(REPLACE(cntry, CHAR(9), ''), CHAR(10), ''), CHAR(13), '') = 'DE' THEN 'Germany'
        WHEN REPLACE(REPLACE(REPLACE(cntry, CHAR(9), ''), CHAR(10), ''), CHAR(13), '') IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry
    FROM bronze.erp_loc_a101;
    SET @end_time =GETDATE();
    -- Chargement des données nettoyées dans la table silver.erp_px_cat_g1v2
    TRUNCATE TABLE silver.erp_cat_g1v2;
    SET @start_time = GETDATE();
    INSERT INTO silver.erp_cat_g1v2(
        id,
        cat,
        subcat,
        maintenance
    )SELECT *
    FROM bronze.erp_cat_g1v2;
    SET @end_time = GETDATE();
    PRINT '>> Durée de chargement sur la couche Silver :' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
    SET @end_batch_time = GETDATE();
    PRINT '=====================================================================';
    PRINT 'Le chargement complet des données nettoyées sur la couche silver est terminé';
    PRINT '>> Temps de chargement total est :' + CAST(DATEDIFF(second, @start_batch_time, @end_batch_time) AS NVARCHAR) + ' seconds';
    PRINT '=====================================================================';
    END TRY
    BEGIN CATCH
       PRINT '=====================================================================';
       PRINT 'Erreur de chargement des données sur la couche silver';
       PRINT 'Erreur ' + ERROR_MESSAGE();
       PRINT 'Erreur' + CAST (ERROR_NUMBER() AS NVARCHAR);
       PRINT 'Erreur' + CAST (ERROR_STATE() AS NVARCHAR);
       PRINT '=====================================================================';
    END CATCH
 END