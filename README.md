# Projet Continuité de Service - TechCommerce Solutions

Projet réalisé dans le cadre du module "Continuité de Service" (BUT Informatique). Ce dépôt contient l'infrastructure conteneurisée simulant un environnement de production critique, sa surveillance et son automatisation.

**Auteurs (Groupe 2) :**
* Belalia
* Eyer
* Candido Della Hora
* Salvo

## 🏗 Architecture

Le projet déploie une application n-tiers surveillée et automatisée via Docker Compose :

* **Application Web** : Serveur Apache + PHP 8.2 (Simule l'activité "Hébergement sécurisé").
* **Base de Données** : MySQL 8.0 (Stockage des visites/données).
* **Métrologie (Monitoring)** :
    * **Prometheus** : Collecte des métriques (Scraping toutes les 15s).
    * **Exporters** : `mysqld-exporter` (métriques BDD) et `node-exporter` (métriques serveur).
    * **Grafana** : Visualisation des données (Dashboard ID 14057).
* **Automatisation** :
    * **Rundeck** : Ordonnanceur de tâches pour la reprise d'activité (Job de redémarrage automatique).

## 🚀 Installation et Démarrage

### Prérequis
* Docker & Docker Compose installés.
* Ports 8888, 3307, 9091, 3001, 4441 libres.

### Démarrage rapide
Un script d'automatisation est fourni pour vérifier l'environnement et lancer la stack :

```bash
chmod +x start.sh
./start.sh
```

Ou manuellement:

```bash
docker compose up -d --build
```

## 📊 Accès aux Services

Application web : http://localhost:8888
Grafana : http://localhost:3001
Rundeck : http://localhost:4441
Prometheus : http://localhost:9091

## 🧪 Simulation de Trafic

Pour générer des données dans Grafana, utilisez les scripts fournis :
1. Trafic régulier : ./traffic.sh (Simule des visites utilisateurs).
1. Stress Test : for i in {1..100}; do curl -s "http://localhost:8888" > /dev/null & done

## ⚙️ Configuration Spécifique

1. Rundeck : Le conteneur Rundeck possède le client Docker installé et le socket Docker monté (/var/run/docker.sock) pour pouvoir piloter les conteneurs voisins (Redémarrage MySQL).
2. MySQL : Initialisation automatique via mysql/init.sql pour créer l'utilisateur dédié à l'exporter Prometheus.
