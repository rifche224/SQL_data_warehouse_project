/******************************************************************************************
* Nom du fichier  : code_script_silver.sql
* Auteur          : Cherif
* Objectif        : Créer les tables de la couche SILVER à partir des sources CRM et ERP et charger les données dans les tables.
*
* Description     :
* Ce fichier définit les tables de la couche SILVER, conformes à un modèle 
* en étoile (star schema), pour permettre d'alimenter notre data warehouse.
******************************************************************************************/
PRINT '===============================================================';
PRINT 'Création des TABLES de la SOURCE CRM & ERP sur la couche SILVER';
PRINT '===============================================================';
    DROP TABLE IF EXISTS silver.crm_cust_info;
    CREATE TABLE silver.crm_cust_info(
        cst_id INT,
        cst_key NVARCHAR(50),
        cst_firstname NVARCHAR(50),
        cst_lastname NVARCHAR(50),
        cst_material_status NVARCHAR(50),
        cst_gndr NVARCHAR(50),
        cst_create_date date,
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    DROP TABLE IF EXISTS silver.crm_prd_info;
    CREATE TABLE  silver.crm_prd_info(
        prd_id INT,
        cat_id NVARCHAR(50),
        prd_key NVARCHAR(50),
        prd_nm NVARCHAR(50),
        prd_cost INT,
        prd_line NVARCHAR(50),
        prd_start_dt DATE,
        prd_end_dt DATE,
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    DROP TABLE IF EXISTS silver.crm_sales_details;
    CREATE TABLE silver.crm_sales_details(
        sls_ord_num NVARCHAR(25),
        sls_prd_key NVARCHAR(25),
        sls_cust_id INT,
        sls_order_dt DATE,
        sls_ship_dt DATE,
        sls_due_dt DATE,
        sls_sales INT,
        sls_quantity INT,
        sls_price INT,
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    PRINT '>> Création des TABLES DE LA SOURCE ERP sur la couche SILVER';
    DROP TABLE IF EXISTS silver.erp_cust_az12;
    CREATE TABLE silver.erp_cust_az12(
        cid NVARCHAR(50),
        bdate DATE,
        gen NVARCHAR(20)
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    DROP TABLE IF EXISTS silver.erp_loc_a101;
    CREATE TABLE silver.erp_loc_a101(
        cid NVARCHAR(50),
        cntry NVARCHAR(20),
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    DROP TABLE IF EXISTS silver.erp_cat_g1v2;
    CREATE TABLE  silver.erp_cat_g1v2(
        id NVARCHAR(50),
        cat NVARCHAR(50),
        subcat NVARCHAR(50),
        maintenance NVARCHAR(50),
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );