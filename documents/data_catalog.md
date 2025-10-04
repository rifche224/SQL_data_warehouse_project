# Catalogue de Données du Data Warehouse

## Vue d’ensemble
Le Data Warehouse est organisé en trois couches principales pour gérer et transformer les données étape par étape :  

- **Bronze Layer :** Données brutes telles que reçues des systèmes sources.  
- **Silver Layer :** Données nettoyées et standardisées prêtes pour les usages analytiques intermédiaires.  
- **Gold Layer :** Données métier prêtes pour l’analyse, le reporting et la data science.  

---

## 1. Bronze Layer
- **Objectif :** Stocker les données brutes directement extraites des sources (CRM, ERP, fichiers CSV dans S3, etc.).  
- **Type d’objet :** Table  
- **Chargement :**  
  - Traitement par lot (Batch Processing)  
  - Chargement complet (Full Load)  
  - Truncate & Insert  

- **Transformations :** Aucune (les données sont stockées “as-is”).  
- **Modèle de données :** Aucun (les données sont conservées telles quelles).  

### Exemples de tables (Bronze) :
| Nom de Table                | Description                                                                 |
|------------------------------|-----------------------------------------------------------------------------|
| bronze.customers_raw         | Données clients brutes issues du CRM.                                       |
| bronze.products_raw          | Données produits brutes issues de l’ERP.                                    |
| bronze.sales_raw             | Transactions de ventes brutes provenant des systèmes sources.               |
| bronze.files_imported        | Données issues de fichiers CSV déposés dans le S3 bucket.                   |

---

## 2. Silver Layer
- **Objectif :** Stocker les données nettoyées, standardisées et enrichies afin de préparer la consommation analytique.  
- **Type d’objet :** Table  
- **Chargement :**  
  - Traitement par lot (Batch Processing)  
  - Chargement complet (Full Load)  
  - Truncate & Insert  

- **Transformations :**  
  - Nettoyage (Cleansing)  
  - Standardisation  
  - Normalisation  
  - Enrichissement  

- **Modèle de données :** Aucun (tables standardisées, mais non encore structurées selon un schéma métier).  

### Exemples de tables (Silver) :
| Nom de Table                | Description                                                                 |
|------------------------------|-----------------------------------------------------------------------------|
| silver.dim_customers_clean   | Données clients nettoyées et standardisées.                                |
| silver.dim_products_clean    | Données produits nettoyées et enrichies avec catégories.                   |
| silver.fact_sales_clean      | Transactions de ventes nettoyées avec clés normalisées.                     |
| silver.lookup_geography      | Table de correspondance géographique (ex. codes pays standardisés ISO).    |

---

## 3. Gold Layer
- **Objectif :** Fournir des données prêtes à l’emploi pour l’analyse métier, le reporting et la data science.  
- **Type d’objet :** Table  
- **Chargement :** Aucun (les données sont déjà transformées).  
- **Transformations :**  
  - Intégrations de données  
  - Agrégation  
  - Règles métier  

- **Modèle de données :**  
  - Schéma en étoile (Star Schema)  
  - Table plate (Flat Table)  
  - Tables agrégées  

### Tables de Dimensions

#### **gold.dim_customers**
- **Objectif :** Stocke les détails des clients enrichis avec des données démographiques et géographiques.  
- **Colonnes :**

| Nom de Colonne   | Type de Données | Description                                                                 |
|------------------|-----------------|-----------------------------------------------------------------------------|
| customer_key     | INT             | Clé de substitution identifiant de manière unique chaque client.             |
| customer_id      | INT             | Identifiant numérique unique attribué à chaque client.                       |
| customer_number  | NVARCHAR(50)    | Identifiant alphanumérique représentant le client.                           |
| first_name       | NVARCHAR(50)    | Prénom du client.                                                            |
| last_name        | NVARCHAR(50)    | Nom de famille du client.                                                    |
| country          | NVARCHAR(50)    | Pays de résidence du client (ex. : 'Australie').                             |
| marital_status   | NVARCHAR(50)    | Statut matrimonial du client (ex. : 'Marié', 'Célibataire').                 |
| gender           | NVARCHAR(50)    | Genre du client (ex. : 'Homme', 'Femme', 'n/a').                             |
| birthdate        | DATE            | Date de naissance du client (format AAAA-MM-JJ).                             |
| create_date      | DATE            | Date de création de l’enregistrement client.                                 |

---

#### **gold.dim_products**
- **Objectif :** Fournir des informations sur les produits et leurs attributs.  
- **Colonnes :**

| Nom de Colonne       | Type de Données | Description                                                                 |
|----------------------|-----------------|-----------------------------------------------------------------------------|
| product_key          | INT             | Clé de substitution identifiant de manière unique chaque produit.           |
| product_id           | INT             | Identifiant unique attribué au produit.                                     |
| product_number       | NVARCHAR(50)    | Code alphanumérique structuré représentant le produit.                      |
| product_name         | NVARCHAR(50)    | Nom descriptif du produit (type, couleur, taille, etc.).                    |
| category_id          | NVARCHAR(50)    | Identifiant unique de la catégorie du produit.                              |
| category             | NVARCHAR(50)    | Classification générale du produit (ex. : Vélos, Composants).               |
| subcategory          | NVARCHAR(50)    | Classification plus détaillée du produit.                                   |
| maintenance_required | NVARCHAR(50)    | Indique si le produit nécessite une maintenance (ex. : 'Oui', 'Non').       |
| cost                 | INT             | Coût ou prix de base du produit.                                            |
| product_line         | NVARCHAR(50)    | Ligne ou série de produits (ex. : Route, Montagne).                         |
| start_date           | DATE            | Date de disponibilité du produit.                                           |

---

### Tables de Faits

#### **gold.fact_sales**
- **Objectif :** Stocke les transactions de ventes pour analyses.  
- **Colonnes :**

| Nom de Colonne   | Type de Données | Description                                                                 |
|------------------|-----------------|-----------------------------------------------------------------------------|
| order_number     | NVARCHAR(50)    | Identifiant alphanumérique unique pour chaque commande.                      |
| product_key      | INT             | Clé de substitution vers la dimension produits.                              |
| customer_key     | INT             | Clé de substitution vers la dimension clients.                               |
| order_date       | DATE            | Date de passage de la commande.                                              |
| shipping_date    | DATE            | Date d’expédition de la commande.                                            |
| due_date         | DATE            | Date d’échéance du paiement.                                                 |
| sales_amount     | INT             | Montant total de la vente (en unités monétaires entières).                   |
| quantity         | INT             | Quantité de produits commandés.                                              |
| price            | INT             | Prix unitaire du produit (en unités monétaires entières).                    |

---