# 📊 Projet de Surveillance d'Infrastructure

Infrastructure dockerisée avec application n-tiers, métrologie et automatisation.

## 🏗️ Architecture

- **Web** : Apache + PHP
- **BDD** : MySQL 8.0
- **Métrologie** : Prometheus + Exporters
- **Visualisation** : Grafana
- **Automatisation** : Rundeck

## 🚀 Installation rapide
```bash
# Prérequis
sudo apt install docker.io docker-compose -y
sudo usermod -aG docker $USER

# Déploiement
mkdir -p ~/projet-surveillance/{app,prometheus,grafana,rundeck}
cd ~/projet-surveillance
docker compose up -d

# Configuration MySQL pour Rundeck
docker exec -it mysql_db mysql -uroot -prootpassword -e "
CREATE DATABASE rundeck;
GRANT ALL PRIVILEGES ON rundeck.* TO 'user'@'%';
FLUSH PRIVILEGES;"

# Permissions Docker
sudo chmod 666 /var/run/docker.sock
```

## 🌐 Accès

| Service | URL | Login |
|---------|-----|-------|
| Application | http://localhost:8080 | - |
| Grafana | http://localhost:3000 | admin/admin |
| Prometheus | http://localhost:9090 | - |
| Rundeck | http://localhost:4440 | admin/admin |

## 📈 Configuration Grafana

1. Data sources → Add Prometheus
2. URL : `http://prometheus:9090`
3. Métriques utiles :
   - `mysql_up` : Statut MySQL
   - `mysql_global_status_threads_connected` : Connexions
   - `rate(mysql_global_status_questions[1m])` : Requêtes/s

## 🔧 Job Rundeck (Redémarrage MySQL)

**Script** :
```bash
#!/bin/bash
echo "🔄 Redémarrage MySQL..."
docker restart mysql_db
sleep 15
docker exec mysql_db mysqladmin ping -h localhost -uuser -ppassword
echo "✅ Terminé"
```

**Planification** : `0 0 2 * * ? *` (2h du matin)

## 🧪 Tests
```bash
# Vérifier les conteneurs
docker compose ps

# Tester l'application
curl http://localhost:8080

# Tester les métriques
curl http://localhost:9104/metrics
```

## 🛠️ Commandes utiles
```bash
docker compose logs -f [service]    # Logs
docker compose restart [service]    # Redémarrer
docker compose down                 # Arrêter
docker stats                        # Ressources
```

## 📦 Structure
```
projet-surveillance/
├── app/index.php
├── prometheus/prometheus.yml
├── rundeck/Dockerfile
└── docker-compose.yml
```
