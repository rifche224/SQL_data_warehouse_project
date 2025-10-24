# SQL Data Warehouse Project

## 📋 Vue d'Ensemble

Projet de **Data Warehouse** développé from scratch avec **SQL Server** et **Azure Data Studio**, implémentant une architecture **Medallion** (Bronze/Silver/Gold) pour l'intégration, la transformation et l'analyse de données provenant de sources hétérogènes (CRM et ERP).

### Objectifs du Projet

- ✅ Centraliser les données issues du **CRM** et de l'**ERP** dans un entrepôt de données unique
- ✅ Implémenter une architecture en **3 couches** (Bronze, Silver, Gold) pour garantir la qualité et la traçabilité
- ✅ Fournir des données **business-ready** pour le reporting et l'analyse
- ✅ Assurer la **gouvernance** et la **qualité des données** à chaque étape

---

## 🏗️ Architecture

### Architecture Medallion (Bronze → Silver → Gold)

```
┌─────────────────────────────────────────────────────────┐
│                  SOURCES DE DONNÉES                     │
│            CRM (Customers) | ERP (Products, Sales)      │
└────────────┬────────────────────────────────────────────┘
             │
             │ Extraction
             ▼
┌────────────────────────────────────────────────────────┐
│              BRONZE LAYER (Raw Data)                   │
│  • Données brutes "as-is"                              │
│  • Aucune transformation                               │
│  • Tables : customers_raw, products_raw, sales_raw     │
│  • Chargement : Full Load (Truncate & Insert)          │
└────────────┬───────────────────────────────────────────┘
             │
             │ Nettoyage & Standardisation
             ▼
┌────────────────────────────────────────────────────────┐
│            SILVER LAYER (Clean Data)                   │
│  • Données nettoyées et standardisées                  │
│  • Déduplication, validation, enrichissement           │
│  • Tables : dim_*_clean, fact_*_clean                  │
│  • Normalisation des formats                           │
└────────────┬───────────────────────────────────────────┘
             │
             │ Agrégation & Modélisation Métier
             ▼
┌────────────────────────────────────────────────────────┐
│              GOLD LAYER (Business-Ready)               │
│  • Modèle en étoile (Star Schema)                      │
│  • Dimensions : dim_customers, dim_products            │
│  • Faits : fact_sales                                  │
│  • Prêt pour reporting et analyse                      │
└────────────────────────────────────────────────────────┘
```

---

## 📊 Catalogue de Données

### 1. Bronze Layer (Raw Data)

**Objectif :** Stocker les données brutes directement extraites des sources sans aucune transformation.

**Caractéristiques :**
- Type : Tables SQL Server
- Chargement : Batch Processing (Truncate & Insert)
- Transformations : Aucune
- Rétention : Données sources conservées telles quelles

#### Tables Bronze

| Nom de Table           | Source | Description                                               |
|------------------------|--------|-----------------------------------------------------------|
| `bronze.crm_cust_info` | CRM    | Données clients brutes issues du système CRM              |
| `bronze.crm_prd_info`  | CRM    | Données prdoduits brutes issues du système CRM            |
| `bronze.crm_saledetails`| CRM   | Données details des ventes issues du système CRM          |
| `bronze.erp_cat_g1v2`  | ERP    | Données categorie de produits brutes issues du système ERP|
| `bronze.erp_cust_az12` | ERP    | Données clients brutes complementaires issues de l'ERP    |
| `bronze.erp_loc_a101`  | ERP    | Données brutes de localisation des clients issues de l'ERP|

---

### 2. Silver Layer (Clean Data)

**Objectif :** Stocker les données nettoyées, standardisées et enrichies pour préparer la consommation analytique.

**Transformations appliquées :**
- ✅ **Nettoyage** : Suppression des doublons, gestion des valeurs nulles
- ✅ **Standardisation** : Formats uniformes (dates, noms, codes pays)
- ✅ **Normalisation** : Types de données cohérents
- ✅ **Enrichissement** : Ajout de données de référence (géographie, catégories)

#### Tables Silver

| Nom de Table            | Source | Description                                               |
|-------------------------|--------|-----------------------------------------------------------|
| `silver.crm_cust_info`  | CRM    | Données clients nettoyées issues de la couche bronze.crm  |
| `silver.crm_prd_info`   | CRM    | Données prdoduits nettoyées issues de la couche bronze.crm|
| `silver.crm_saledetails`| CRM    | Données details des ventes nettoyées issues de sales_details|
| `silver.erp_cat_g1v2`   | ERP    | Données categorie de produits nettoyées bronze.ERP        |
| `silver.erp_cust_az12`  | ERP    | Données clients complementaires nettoyées issues de l'ERP |
| `silver.erp_loc_a101`   | ERP    | Données nettoyées de localisation des clients bronze l'ERP|

---

### 3. Gold Layer (Business-Ready)

**Objectif :** Fournir des données prêtes à l'emploi pour l'analyse métier, le reporting et la data science.

**Modèle de données :** **Star Schema (Schéma en Étoile)**
- Dimensions : Tables décrivant les entités métier (clients, produits)
- Faits : Tables contenant les mesures et transactions (ventes)

**Transformations appliquées :**
- ✅ **Intégration** : Jointures cross-sources (CRM + ERP)
- ✅ **Agrégation** : Calculs de KPIs et métriques métier
- ✅ **Règles métier** : Application de logiques métier spécifiques

---

#### 📌 Table de Dimension : `gold.dim_customers`

**Description :** Contient les informations détaillées sur les clients enrichies avec des données démographiques et géographiques.

**Colonnes :**

| Colonne            | Type          | Description                                                    |
|--------------------|---------------|----------------------------------------------------------------|
| `customer_key`     | INT           | Clé de substitution (surrogate key) identifiant unique         |
| `customer_id`      | INT           | Identifiant numérique du client (clé naturelle)                |
| `customer_number`  | NVARCHAR(50)  | Identifiant alphanumérique du client                           |
| `first_name`       | NVARCHAR(50)  | Prénom du client                                               |
| `last_name`        | NVARCHAR(50)  | Nom de famille du client                                       |
| `country`          | NVARCHAR(50)  | Pays de résidence (ex: 'France', 'Australie')                  |
| `marital_status`   | NVARCHAR(50)  | Statut matrimonial (ex: 'Marié', 'Célibataire')                |
| `gender`           | NVARCHAR(50)  | Genre du client (ex: 'Homme', 'Femme', 'Non renseigné')        |
| `birthdate`        | DATE          | Date de naissance (format YYYY-MM-DD)                          |
| `create_date`      | DATE          | Date de création de l'enregistrement                           |

**Clé primaire :** `customer_key`

---

#### 📌 Table de Dimension : `gold.dim_products`

**Description :** Contient les informations sur les produits et leurs attributs (catégories, coûts, caractéristiques).

**Colonnes :**

| Colonne                 | Type          | Description                                                    |
|-------------------------|---------------|----------------------------------------------------------------|
| `product_key`           | INT           | Clé de substitution (surrogate key) identifiant unique         |
| `product_id`            | INT           | Identifiant unique du produit (clé naturelle)                  |
| `product_number`        | NVARCHAR(50)  | Code alphanumérique du produit                                 |
| `product_name`          | NVARCHAR(50)  | Nom descriptif du produit (type, couleur, taille)              |
| `category_id`           | NVARCHAR(50)  | Identifiant de la catégorie                                    |
| `category`              | NVARCHAR(50)  | Classification générale (ex: 'Vélos', 'Composants')            |
| `subcategory`           | NVARCHAR(50)  | Sous-catégorie détaillée                                       |
| `maintenance`           | NVARCHAR(50)  | Indique si maintenance nécessaire ('Oui', 'Non')               |
| `cost`                  | INT           | Coût ou prix de base du produit                                |
| `product_line`          | NVARCHAR(50)  | Ligne de produits (ex: 'Route', 'Montagne')                    |
| `start_date`            | DATE          | Date de mise en disponibilité du produit                       |

**Clé primaire :** `product_key`

---

#### 📌 Table de Faits : `gold.fact_sales`

**Description :** Contient les transactions de ventes avec références aux dimensions (clients, produits) pour analyses et reporting.

**Colonnes :**

| Colonne          | Type          | Description                                                    |
|------------------|---------------|----------------------------------------------------------------|
| `order_number`   | NVARCHAR(50)  | Identifiant unique de la commande                              |
| `product_key`    | INT           | Clé étrangère vers `dim_products`                              |
| `customer_key`   | INT           | Clé étrangère vers `dim_customers`                             |
| `order_date`     | DATE          | Date de passage de la commande                                 |
| `shipping_date`  | DATE          | Date d'expédition de la commande                               |
| `due_date`       | DATE          | Date d'échéance du paiement                                    |
| `sales_amount`   | INT           | Montant total de la vente (en unités monétaires)               |
| `quantity`       | INT           | Quantité de produits commandés                                 |
| `price`          | INT           | Prix unitaire du produit (en unités monétaires)                |

**Clés étrangères :**
- `product_key` → `gold.dim_products(product_key)`
- `customer_key` → `gold.dim_customers(customer_key)`

**Grain de la table :** Une ligne = une ligne de commande (order_number + product_key)

---

## 🛠️ Stack Technique

| Composant            | Technologie                |
|----------------------|----------------------------|
| **Database**         | SQL Server                 |
| **IDE**              | Azure Data Studio          |
| **Langage**          | T-SQL (Transact-SQL)       |
| **Architecture**     | Medallion (Bronze/Silver/Gold) |
| **Modèle de données**| Star Schema                |
| **Sources**          | CRM, ERP                   |

---

## 📁 Structure du Projet

```
sql-data-warehouse-project/
├── README.md                         # Ce fichier
├── scripts/
│   ├── 01_init_database.sql          # Création des schémas (bronze, silver, gold)
│   ├── 02_bronze_layer/
│   │   ├── code_script_bronze.sql    # Tables bronze (raw) & Chargement données brutes        
│   ├── 03_silver_layer/
│   │   ├── code_script_silver.sql    # Tables silver (clean)
│   │   └── code_script_clean_load_silver.sql # Transformations et nettoyage
│   ├── 04_gold_layer/
│   │   ├── code_script_gold.sql     # Création dim_customers, dim_products, fact_sales
│   └── 05_tests/
│       └── script_test_for_cleaning.sql  # Tests de qualité des données (bronze, silver)
│       └── code_script_gold_tests.sql    # Tests de qualité des données (gold)
├── data/
│   ├── crm/
│   │   └── customers.csv             # Données sources CRM
│   └── erp/
│       ├── products.csv              # Données sources ERP
│       └── sales.csv                 # Données sources ERP
└── docs/
    ├── data_catalog.md               # Catalogue de données détaillé
    └── architecture_diagram.png      # Diagramme d'architecture
    └── dwh_model.png                 # Diagramme d'architecture du data warehouse
    └── ETL_Retail.png                # Diagramme de modelisation détaillé d'ETL
    └── schema_Analyse.png            # Diagramme des flux de données des trois couches
```

---


---

## 🎯 Bonnes Pratiques Implémentées

✅ **Architecture Medallion** : Séparation claire Bronze/Silver/Gold  
✅ **Star Schema** : Modèle dimensionnel optimisé pour l'analyse  
✅ **Surrogate Keys** : Clés de substitution pour indépendance des clés naturelles  
✅ **Nommage cohérent** : Conventions de nommage claires (schéma.type_nom)  
✅ **Documentation** : Catalogue de données complet  
✅ **Tests de qualité** : Validation à chaque étape  
✅ **Traçabilité** : Conservation des données brutes (Bronze)  

---

## 📝 Évolutions Futures

- [ ] Automatisation des pipelines avec **SSIS** ou **Azure Data Factory**
- [ ] Implémentation de **Slowly Changing Dimensions (SCD Type 2)** pour historisation
- [ ] Ajout de tables agrégées (pre-aggregated) pour performance
- [ ] Intégration avec **Power BI** pour dashboards interactifs
- [ ] Mise en place de **CDC (Change Data Capture)** pour chargements incrémentaux
- [ ] Ajout de tests automatisés avec **tSQLt Framework**
- [ ] Documentation auto-générée avec **SQL Server Data Tools (SSDT)**

---

## 👤 Auteur

**Cherif Amanatoulha SY**  
Data Engineer  
📧 cherif.sy@hotmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/votre-profil)  
🐙 [GitHub](https://github.com/votre-username)

---

## 📄 Licence

Ce projet est développé à des fins de démonstration de compétences en Data Engineering.
---

## 🙏 Remerciements

- **SQL Server Documentation** : https://docs.microsoft.com/sql
- **Kimball Dimensional Modeling** : Star Schema best practices
- **Databricks Medallion Architecture** : Architecture reference

---

**Dernière mise à jour :** 24 Octobre 2025