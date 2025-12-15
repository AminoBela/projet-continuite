-- Création de la base de données pour l'application si elle n'existe pas (déjà fait par MYSQL_DATABASE mais sécurité)
CREATE DATABASE IF NOT EXISTS testdb;

-- Création de la base de données pour Rundeck
CREATE DATABASE IF NOT EXISTS rundeck CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Droits pour l'utilisateur 'user' sur la base Rundeck
GRANT ALL PRIVILEGES ON rundeck.* TO 'user'@'%';

-- Droits pour l'exporteur MySQL (Metrologie)
-- Il a besoin de droits spécifiques pour lire les performances
CREATE USER 'exporter'@'%' IDENTIFIED BY 'exporterpassword';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';

FLUSH PRIVILEGES;
