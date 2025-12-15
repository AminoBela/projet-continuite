FROM rundeck/rundeck:5.0.0

USER root

RUN apt-get update && \
    apt-get install -y docker.io && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Retour à l'utilisateur rundeck
USER rundeck
