/******************************************************************************************
* Nom du fichier  : init_database.sql
* Auteur          : Cherif
* Objectif        : Initialiser la base de données DataWarehouse et créer les schémas
*                   bronze, silver et gold pour structurer le data warehouse retail.
*
* Description     :
* Ce fichier exécute les actions suivantes :
* 1. Création de la base de données `DataWarehouse` si elle n'existe pas déjà.
* 2. Création des schémas `bronze`, `silver` et `gold` pour structurer le traitement en couches.
* Architecture des couches :
*   - BRONZE : Données brutes ingérées depuis S3 (CRM/ERP)
*   - SILVER : Données nettoyées et normalisées
*   - GOLD   : Marts d'analyse prêts pour le reporting
******************************************************************************************/

-- Définit le contexte sur la base système 
USE master; 

-- Crée la base de données principale du projet (échoue si elle existe déjà)
CREATE DATABASE DataWarehouse; 

-- Bascule le contexte sur la base nouvellement créée
USE DataWarehouse; 

-- Crée le schéma de la couche BRONZE (données brutes)
CREATE SCHEMA bronze; 

-- GO : sépare les lots d'instructions 
GO

-- Crée le schéma de la couche SILVER (données nettoyées/normalisées)
CREATE SCHEMA silver; 

GO
 -- Crée le schéma de la couche GOLD (marts d'analyse)
CREATE SCHEMA gold;

GO