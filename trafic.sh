#!/bin/bash
echo "Simulation de trafic régulier... (CTRL+C pour arrêter)"

while true; do
    # Effectue une requête silencieuse
    curl -s "http://localhost:8888" > /dev/null
    
    echo -n "."
    
    # Attend un temps aléatoire entre 0.1 et 1 seconde pour varier la courbe
    sleep 0.$(( ( RANDOM % 9 ) + 1 ))
done
