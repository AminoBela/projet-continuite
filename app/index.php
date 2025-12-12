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
    echo "<p style='color:green'> Connexion MySQL réussie !</p>";
    
    // Créer une table et insérer des données
    $conn->query("CREATE TABLE IF NOT EXISTS visits (id INT AUTO_INCREMENT PRIMARY KEY, timestamp DATETIME)");
    $conn->query("INSERT INTO visits (timestamp) VALUES (NOW())");
    
    $result = $conn->query("SELECT COUNT(*) as count FROM visits");
    $row = $result->fetch_assoc();
    echo "<p>Nombre de visites : " . $row['count'] . "</p>";
    
    $conn->close();
} catch (Exception $e) {
    echo "<p style='color:red'> Erreur : " . $e->getMessage() . "</p>";
}

phpinfo();
?>
