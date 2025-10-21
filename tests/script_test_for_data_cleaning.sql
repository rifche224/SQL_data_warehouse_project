/******************************************************************************************
* Nom du fichier  : script_test_for_data_cleaning.sql
* Auteur          : Cherif
* Objectif        : Tests et vérifications de qualité des données pour le nettoyage
*                   avant chargement dans la couche SILVER
*
* Description     :
* Ce fichier contient tous les tests de qualité de données effectués sur les sources
* CRM et ERP pour identifier et corriger les anomalies avant le chargement en SILVER.
*
* Sections :
* 1. Tests sur CRM - Customer Info
* 2. Tests sur CRM - Product Info  
* 3. Tests sur CRM - Sales Details
* 4. Tests sur ERP - Customer AZ12
* 5. Tests sur ERP - Location A101
* 6. Tests sur ERP - Category G1V2
******************************************************************************************/

-- ============================================================================
-- SECTION 1 : TESTS ET NETTOYAGE - CRM CUSTOMER INFO
-- ============================================================================

PRINT '==================================================';
PRINT 'TESTS DE QUALITÉ - CRM CUSTOMER INFO';
PRINT '==================================================';

-- 1.1 Vérification des clés primaires dupliquées et valeurs NULLES
PRINT '>> 1.1 - Recherche de clés primaires dupliquées et valeurs NULLES';
SELECT cst_id, count(*) AS OCCURENTS_NUMBER
FROM bronze.crm_cust_info 
GROUP BY cst_id 
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- 1.2 Focus sur les clés primaires dupliquées uniquement
PRINT '>> 1.2 - Focus sur les clés primaires dupliquées';
SELECT cst_id, count(*) AS OCCUENTS_NUMBER 
FROM bronze.crm_cust_info 
GROUP BY cst_id 
HAVING COUNT(*) > 1;

-- 1.3 Dédoublonnage - Garder la version la plus récente par client
PRINT '>> 1.3 - Dédoublonnage - Version la plus récente par client';
SELECT *
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flags_Last
    FROM bronze.crm_cust_info 
) T 
WHERE Flags_Last = 1;

-- 1.4 Vérification des espaces indésirables dans les noms
PRINT '>> 1.4 - Vérification des espaces indésirables';
SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- 1.5 Résolution complète avec nettoyage des espaces
PRINT '>> 1.5 - Résolution complète avec nettoyage';
SELECT cst_id,
      cst_key,
      TRIM(cst_firstname) AS cst_firstname,
      TRIM(cst_lastname) AS cst_lastname,
      cst_material_status,
      cst_gndr,
      cst_create_date
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flags_Last
    FROM bronze.crm_cust_info
) T 
WHERE Flags_Last = 1;

-- 1.6 Standardisation des données - Genre et statut marital
PRINT '>> 1.6 - Standardisation des données';
SELECT DISTINCT cst_gndr FROM bronze.crm_cust_info;
SELECT DISTINCT cst_material_status FROM bronze.crm_cust_info;

-- 1.7 Transformation finale avec standardisation
PRINT '>> 1.7 - Transformation finale avec standardisation';
SELECT cst_id,
      cst_key,
      TRIM(cst_firstname) AS cst_firstname,
      TRIM(cst_lastname) AS cst_lastname,
      CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
           WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
           ELSE 'n/a'
      END AS cst_material_status,
      CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
           WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
           ELSE 'n/a'
      END AS cst_gndr,
      cst_create_date
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flags_Last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) T 
WHERE Flags_Last = 1;

-- ============================================================================
-- SECTION 2 : TESTS ET NETTOYAGE - CRM PRODUCT INFO
-- ============================================================================

PRINT '==================================================';
PRINT 'TESTS DE QUALITÉ - CRM PRODUCT INFO';
PRINT '==================================================';

-- 2.1 Vérification des clés primaires dupliquées
PRINT '>> 2.1 - Recherche de clés primaires dupliquées';
SELECT prd_id, count(*) AS OCCURENTS_NUMBER
FROM bronze.crm_prd_info 
GROUP BY prd_id 
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- 2.2 Nettoyage et transformation des produits
PRINT '>> 2.2 - Nettoyage et transformation des produits';
SELECT prd_id,
      prd_key,
      REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
      SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key_clean,
      prd_nm,
      ISNULL(prd_cost, 0) AS prd_cost,
      CASE UPPER(TRIM(prd_line))
           WHEN 'M' THEN 'Mountain'
           WHEN 'R' THEN 'Road'
           WHEN 'S' THEN 'Other Sales'
           WHEN 'T' THEN 'Touring'
           ELSE 'n/a'
      END AS prd_line,
      CAST(prd_start_dt AS DATE) AS prd_start_dt,
      DATEADD(day, -1, LEAD(CAST(prd_start_dt AS date)) OVER (PARTITION BY prd_key ORDER BY CAST(prd_start_dt AS DATE))) AS prd_end_dt
FROM bronze.crm_prd_info;

-- 2.3 Vérification des coûts négatifs ou NULL
PRINT '>> 2.3 - Vérification des coûts';
SELECT prd_cost FROM bronze.crm_prd_info WHERE prd_cost < 0 OR prd_cost IS NULL;

-- 2.4 Vérification des lignes de produits
PRINT '>> 2.4 - Vérification des lignes de produits';
SELECT DISTINCT prd_line FROM bronze.crm_prd_info;

-- ============================================================================
-- SECTION 3 : TESTS ET NETTOYAGE - CRM SALES DETAILS
-- ============================================================================

PRINT '==================================================';
PRINT 'TESTS DE QUALITÉ - CRM SALES DETAILS';
PRINT '==================================================';

-- 3.1 Vérification des dates invalides
PRINT '>> 3.1 - Vérification des dates invalides';
SELECT *
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
   OR LEN(sls_due_dt) != 8
   OR sls_due_dt > 20500101 
   OR sls_due_dt < 19000101;

-- 3.2 Correction des dates nulles
PRINT '>> 3.2 - Correction des dates nulles';
SELECT NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
   OR LEN(sls_due_dt) != 8 
   OR sls_due_dt > 20500101 
   OR sls_due_dt < 19000101;

-- 3.3 Vérification de la cohérence des commandes
PRINT '>> 3.3 - Vérification de la cohérence des commandes';
SELECT * 
FROM bronze.crm_sales_details 
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- 3.4 Vérification de la cohérence des calculs
PRINT '>> 3.4 - Vérification de la cohérence des calculs';
SELECT sls_quantity, sls_price, sls_sales 
FROM bronze.crm_sales_details 
WHERE sls_sales != sls_quantity * sls_price 
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL 
   OR sls_sales < 0 
   OR sls_price < 0 
   OR sls_quantity < 0;

-- 3.5 Transformation finale des ventes avec corrections
PRINT '>> 3.5 - Transformation finale des ventes';
SELECT sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE 
       WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
       ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt,
    CASE 
       WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
       ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
    END AS sls_ship_dt,
    CASE 
       WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
       ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
    END AS sls_due_dt,
    CASE 
       WHEN sls_sales = 0 OR sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
       THEN sls_quantity * ABS(sls_price)
       ELSE sls_sales
    END AS sls_sales,
    CASE 
       WHEN sls_price IS NULL OR sls_price <= 0 
       THEN sls_sales / NULLIF(sls_quantity, 0)
       ELSE sls_price
    END AS sls_price,
    sls_quantity
FROM bronze.crm_sales_details;

-- ============================================================================
-- SECTION 4 : TESTS ET NETTOYAGE - ERP CUSTOMER AZ12
-- ============================================================================

PRINT '==================================================';
PRINT 'TESTS DE QUALITÉ - ERP CUSTOMER AZ12';
PRINT '==================================================';

-- 4.1 Nettoyage des identifiants clients
PRINT '>> 4.1 - Nettoyage des identifiants clients';
SELECT cid,
CASE 
    WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
    ELSE cid 
END AS cid_clean, 
bdate,
gen
FROM bronze.erp_cust_az12;

-- 4.2 Vérification de la cohérence avec les données CRM
PRINT '>> 4.2 - Vérification de la cohérence avec CRM';
SELECT cid,
CASE 
    WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
    ELSE cid 
END AS cid_clean, 
bdate,
gen
FROM bronze.erp_cust_az12
WHERE CASE 
    WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
    ELSE cid 
END NOT IN (SELECT DISTINCT cst_key FROM bronze.crm_cust_info);

-- 4.3 Vérification des dates de naissance
PRINT '>> 4.3 - Vérification des dates de naissance';
SELECT cid,
CASE 
    WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
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

-- ============================================================================
-- SECTION 5 : TESTS ET NETTOYAGE - ERP LOCATION A101
-- ============================================================================

PRINT '==================================================';
PRINT 'TESTS DE QUALITÉ - ERP LOCATION A101';
PRINT '==================================================';

-- 5.1 Nettoyage des identifiants et standardisation des pays
PRINT '>> 5.1 - Nettoyage et standardisation des pays';
SELECT
  REPLACE(cid, '-', '') AS cid,
  CASE
    WHEN REPLACE(REPLACE(REPLACE(cntry, CHAR(9), ''), CHAR(10), ''), CHAR(13), '') = 'DE' THEN 'Germany'
    WHEN REPLACE(REPLACE(REPLACE(cntry, CHAR(9), ''), CHAR(10), ''), CHAR(13), '') IN ('US', 'USA') THEN 'United States'
    WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
    ELSE TRIM(cntry)
  END AS cntry
FROM bronze.erp_loc_a101;

-- ============================================================================
-- SECTION 6 : TESTS ET NETTOYAGE - ERP CATEGORY G1V2
-- ============================================================================

PRINT '==================================================';
PRINT 'TESTS DE QUALITÉ - ERP CATEGORY G1V2';
PRINT '==================================================';

-- 6.1 Vérification des espaces dans les catégories
PRINT '>> 6.1 - Vérification des espaces dans les catégories';
SELECT * 
FROM bronze.erp_cat_g1v2 
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

-- 6.2 Vérification des valeurs de maintenance
PRINT '>> 6.2 - Vérification des valeurs de maintenance';
SELECT DISTINCT maintenance FROM bronze.erp_cat_g1v2;

-- 6.3 Chargement simple (pas de transformation nécessaire)
PRINT '>> 6.3 - Chargement simple des catégories';
SELECT * FROM bronze.erp_cat_g1v2;

-- ============================================================================
-- RÉSUMÉ DES TESTS
-- ============================================================================

PRINT '==================================================';
PRINT 'RÉSUMÉ DES TESTS DE QUALITÉ TERMINÉS';
PRINT '==================================================';
PRINT 'Tous les tests de qualité de données ont été effectués.';
PRINT 'Les transformations identifiées peuvent être appliquées pour le chargement en SILVER.';
