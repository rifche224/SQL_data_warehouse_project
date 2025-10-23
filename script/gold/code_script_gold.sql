--******************************************************************************************
--* Nom du fichier  : code_script_gold.sql
--* Auteur          : Cherif
--* Objectif        : Chargement des données nettoyées dans l'entrepot de données GOLD 
--* Description     :
--* Ce fichier charge les données nettoyées dans lE DATA WAREHOUSE
--*                   Charger les données dans la table dimension clients(customers).
--*                   Charger les données dans la table dimension produits(products).
--*                   Charger les données dans la table de fait des ventes (sales).
--******************************************************************************************

------------Creation de la dimension customers------------
CREATE VIEW gold.dim_customers AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customers_key,
    c_i.cst_id AS customer_id,
    c_i.cst_key AS customer_number,
    c_i.cst_firstname AS first_name,
    c_i.cst_lastname AS last_name,
    c_l.cntry AS country,
    c_i.cst_material_status AS marital_status,
    CASE 
        WHEN c_i.cst_gndr != 'n/a' THEN c_i.cst_gndr ---JE GARDE LA VALEUR PROVENANT DE LA SOURCE CRM
        ELSE COALESCE(c_a.gen, 'n/a')
    END AS gender,
     c_a.bdate AS birthdate,
    c_i.cst_create_date AS create_date 
FROM silver.crm_cust_info c_i
LEFT JOIN silver.erp_cust_az12 c_a
ON c_i.cst_key = c_a.cid
LEFT JOIN silver.erp_loc_a101 c_l
ON c_i.cst_key = c_l.cid;
---------------CREATION DE LA DIMENSION PRODUITS---------
CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_row_key,
    pn.prd_id AS product_id,
    pn.prd_key AS product_key,
    pn.prd_nm AS product_name,
    pn.cat_id AS product_category_id,
    pc.cat AS product_category,
    pc.subcat AS product_subcategory,
    pc.maintenance,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS product_start_date,
    pn.prd_end_dt AS product_end_date
FROM silver.crm_prd_info pn 
LEFT JOIN silver.erp_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; --filter les produits courants

-----------Creation de la table de fait sales---------
CREATE VIEW gold.fact_sales AS
SELECT 
      sls_ord_num AS sales_order_number,
      pr.product_key AS product_key,
      cu.customers_key AS customers_key,
      sls_order_dt AS order_date,
      sls_ship_dt AS shipping_date,
      sls_due_dt AS due_tue_date,
      sls_sales AS sales_amount,
      sls_quantity AS quantity,
      sls_price AS price
  FROM silver.crm_sales_details sd 
  LEFT JOIN gold.dim_products pr
  ON sd.sls_prd_key = pr.product_key
  LEFT JOIN gold.dim_customers cu
  ON sd.sls_cust_id = cu.customer_id;