#!/bin/bash


set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "============================================================"
echo -e "${BLUE} DÉMARRAGE DE L'INFRASTRUCTURE${NC}"
echo "============================================================"
echo ""

echo -e "${BLUE}  Étape 1/7 : Vérifications préalables${NC}"

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}  Docker n'est pas installé${NC}"
    exit 1
fi
echo -e "${GREEN}  Docker installé${NC}"

# Vérifier Docker Compose
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}  Docker Compose n'est pas installé${NC}"
    exit 1
fi
echo -e "${GREEN}  Docker Compose installé${NC}"

# Vérifier que Docker tourne
if ! docker info &> /dev/null; then
    echo -e "${RED}  Docker daemon n'est pas démarré${NC}"
    echo "Démarrer Docker Desktop et relancer ce script"
    exit 1
fi
echo -e "${GREEN}  Docker daemon actif${NC}"


echo ""
echo -e "${BLUE}  Étape 2/7 : Vérification de la structure${NC}"

# Créer les dossiers nécessaires
mkdir -p app prometheus rundeck/data

# Vérifier docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}  docker-compose.yml non trouvé${NC}"
    exit 1
fi
echo -e "${GREEN}  docker-compose.yml trouvé${NC}"

# Vérifier app/index.php
if [ ! -f "app/index.php" ]; then
    echo -e "${YELLOW}   app/index.php non trouvé, création...${NC}"
    cat > app/index.php << 'EOF'
<?php
$host = 'mysql';
$user = 'user';
$password = 'password';
$database = 'testdb';

echo "<h1>Application Web - Test de connexion</h1>";

try {
    $conn = new mysqli($host, $user, $password, $database);
    if ($conn->connect_error) {
        throw new Exception($conn->connect_error);
    }
    echo "<p style='color:green'>  Connexion MySQL réussie !</p>";
    
    $conn->query("CREATE TABLE IF NOT EXISTS visits (id INT AUTO_INCREMENT PRIMARY KEY, timestamp DATETIME)");
    $conn->query("INSERT INTO visits (timestamp) VALUES (NOW())");
    
    $result = $conn->query("SELECT COUNT(*) as count FROM visits");
    $row = $result->fetch_assoc();
    echo "<p>Nombre de visites : " . $row['count'] . "</p>";
    
    $conn->close();
} catch (Exception $e) {
    echo "<p style='color:red'>  Erreur : " . $e->getMessage() . "</p>";
}

phpinfo();
?>
EOF
fi
echo -e "${GREEN}  app/index.php créé${NC}"

# Vérifier prometheus/prometheus.yml
if [ ! -f "prometheus/prometheus.yml" ]; then
    echo -e "${YELLOW}   prometheus.yml non trouvé, création...${NC}"
    cat > prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'mysql'
    static_configs:
      - targets: ['mysql-exporter:9104']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
EOF
fi
echo -e "${GREEN}  prometheus.yml créé${NC}"


echo ""
echo -e "${BLUE}  Étape 3/7 : Nettoyage des anciens conteneurs${NC}"

# Arrêter les conteneurs s'ils existent
if docker compose ps -q 2>/dev/null | grep -q .; then
    echo "Arrêt des conteneurs existants..."
    docker compose down
    echo -e "${GREEN}  Conteneurs arrêtés${NC}"
else
    echo -e "${GREEN}  Aucun conteneur à arrêter${NC}"
fi


echo ""
echo -e "${BLUE}  Étape 4/7 : Vérification des ports${NC}"

PORTS=(8888 3001 9091 4441 3307 9105 9101)
PORTS_OK=true

for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${RED}  Port $port déjà utilisé${NC}"
        PORTS_OK=false
    else
        echo -e "${GREEN}  Port $port disponible${NC}"
    fi
done

if [ "$PORTS_OK" = false ]; then
    echo ""
    echo -e "${YELLOW}   Certains ports sont occupés${NC}"
    echo "Voulez-vous continuer quand même ? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Arrêt du script"
        exit 1
    fi
fi


echo ""
echo -e "${BLUE}  Étape 5/7 : Configuration des permissions Docker${NC}"

if [ -e /var/run/docker.sock ]; then
    echo "Configuration des permissions du socket Docker..."
    sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
    echo -e "${GREEN}  Permissions configurées${NC}"
else
    echo -e "${YELLOW}   Socket Docker non trouvé (normal sur macOS)${NC}"
fi

echo ""
echo -e "${BLUE}  Étape 6/7 : Démarrage des conteneurs${NC}"
echo ""

docker compose up -d

echo ""
echo -e "${GREEN}  Conteneurs démarrés${NC}"


echo ""
echo -e "${BLUE}  Étape 7/7 : Attente du démarrage complet${NC}"
echo ""

echo "⏳ Attente de MySQL (peut prendre 30-60 secondes)..."
timeout=120
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker exec mysql_db mysqladmin ping -h localhost -uuser -ppassword &>/dev/null; then
        echo -e "${GREEN}  MySQL opérationnel (${elapsed}s)${NC}"
        break
    fi
    printf "."
    sleep 5
    elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $timeout ]; then
    echo -e "${RED}  MySQL n'a pas démarré dans les temps${NC}"
    echo "Vérifier les logs : docker logs mysql_db"
    exit 1
fi

echo ""
echo " Attente de Rundeck (peut prendre 60-90 secondes)..."
sleep 30  # Rundeck prend du temps
echo -e "${GREEN}  Rundeck devrait être prêt${NC}"


echo ""
echo "============================================================"
echo -e "${GREEN}  INFRASTRUCTURE DÉMARRÉE AVEC SUCCÈS !${NC}"
echo "============================================================"
echo ""

# Vérifier le statut
echo -e "${BLUE}  Statut des conteneurs :${NC}"
docker compose ps

echo ""
echo "============================================================"
echo -e "${BLUE}  ACCÈS AUX SERVICES${NC}"
echo "============================================================"
echo ""
echo " Application Web      : http://localhost:8888"
echo "  Grafana             : http://localhost:3001  (admin/admin)"
echo " Prometheus          : http://localhost:9091"
echo " Rundeck             : http://localhost:4441  (admin/admin)"
echo " MySQL Exporter      : http://localhost:9105/metrics"
echo " Node Exporter       : http://localhost:9101/metrics"
echo ""
echo "============================================================"
echo -e "${BLUE} COMMANDES UTILES${NC}"
echo "============================================================"
echo ""
echo "# Voir les logs"
echo "docker compose logs -f [service]"
echo ""
echo "# Arrêter"
echo "docker compose down"
echo ""
echo "# Redémarrer un service"
echo "docker restart [nom_conteneur]"
echo ""
echo "# Vérifier MySQL"
echo "docker exec mysql_db mysql -uuser -ppassword -e 'SELECT 1;'"
echo ""
echo "============================================================"
echo -e "${YELLOW}   PROCHAINES ÉTAPES${NC}"
echo "============================================================"
echo ""
echo "1. Tester l'application : curl http://localhost:8888"
echo "2. Configurer Grafana (ajouter source Prometheus)"
echo "3. Créer le job Rundeck de redémarrage MySQL"
echo "4. Prendre des screenshots pour le rapport"
echo ""
echo "============================================================"
echo -e "${GREEN} Bon travail !${NC}"
echo "============================================================"
echo ""
