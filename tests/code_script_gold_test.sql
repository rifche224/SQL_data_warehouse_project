/******************************************************************************************
* Nom du fichier  : code_script_gold_test.sql
* Auteur          : Cherif
* Objectif        : Tests et vérifications de qualité des données 
*                   avant chargement dans le data warehouse
*
* Description     :
* Ce fichier contient tous les tests de qualité de données effectués sur les données
* néttoyées avant le chargement dans le data warehouse.
******************************************************************************************/
---- Traitement et verification de la couche gold------
---Récuperation de toutes les infos des clients------
--------------Vérifications des doublons-------------
SELECT cst_id, COUNT(*) FROM (
SELECT 
    c_i.cst_id,
    c_i.cst_key,
    c_i.cst_firstname,
    c_i.cst_lastname,
    c_i.cst_material_status,
    c_i.cst_gndr,
    c_i.cst_create_date,
    c_a.bdate,
    c_a.gen,
    c_l.cntry
FROM silver.crm_cust_info c_i
LEFT JOIN silver.erp_cust_az12 c_a
ON c_i.cst_key = c_a.cid
LEFT JOIN silver.erp_loc_a101 c_l
ON c_i.cst_key = c_l.cid)t GROUP BY cst_id
HAVING COUNT(*) > 1;
----------------Resultats 0 doublons----------------------

-----------Deux colonnes sex apres integration----------
SELECT DISTINCT
    c_i.cst_gndr,
    c_a.gen,
CASE 
    WHEN c_i.cst_gndr != 'n/a' THEN c_i.cst_gndr ---jE GARDE LA VALEUR PROVENANT DE LA SOURCE CRM
    ELSE COALESCE(c_a.gen, 'n/a')
END AS new_gen
FROM silver.crm_cust_info c_i
LEFT JOIN silver.erp_cust_az12 c_a
ON c_i.cst_key = c_a.cid
LEFT JOIN silver.erp_loc_a101 c_l
ON c_i.cst_key = c_l.cid
ORDER BY 1,2;


--------------------Verirification de notre dimension-----------
SELECT DISTINCT gender FROM gold.dim_customers;
-----------------------Verification des produits----------------
----------JE SELECTIONNE LES PRODUITS COURANTS------------------
---verifier les doublons---
SELECT prd_key, COUNT(*) 
FROM(
    SELECT
    pn.prd_id,
    pn.cat_id,
    pn.prd_key,
    pn.prd_nm,
    pn.prd_cost,
    pn.prd_line,
    pn.prd_start_dt,
    pn.prd_end_dt,
    pc.subcat,
    pc.maintenance
FROM silver.crm_prd_info pn 
LEFT JOIN silver.erp_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL
)t GROUP BY prd_key
HAVING count(*)> 1;
-----Resultas 0 --------

----------------VERIFICATION---------------------------
----------Customers-----
SELECT * 
from gold.fact_sales f
LEFT join gold.dim_customers dc 
ON dc.customers_key = f.customers_key
where dc.customers_key is null;
---------Products------------
SELECT * 
from gold.fact_sales f
LEFT join gold.dim_products dp 
ON dp.product_key = f.product_key
where dp.product_key is null;
-----------Resultat ok tout match ------