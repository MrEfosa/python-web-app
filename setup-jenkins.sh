#!/bin/bash

# Exit immediately if any command returns a non-zero status
set -e

echo "========================================="
echo "Updating System Packages..."
echo "========================================="
apt update -y && apt upgrade -y

echo "========================================="
echo "Installing Docker Engine..."
echo "========================================="
apt install -y docker.io

echo "========================================="
echo "Starting & Enabling Docker..."
echo "========================================="
systemctl enable --now docker

echo "========================================="
echo "Installing Docker Compose Plugin..."
echo "========================================="
apt install -y docker-compose-v2

echo "========================================="
echo "Setting Up Jenkins Directories..."
echo "========================================="
# Best Practice: Define an explicit, standard host directory for data persistence
mkdir -p /var/jenkins_home
mkdir -p /root/jenkins
cd /root/jenkins

echo "========================================="
echo "Detecting Host Docker Group ID..."
echo "========================================="
# Detect the host's docker GID dynamically and save it to a variable
DOCKER_GID=$(getent group docker | cut -d: -f3)
echo "Detected Docker GID: $DOCKER_GID"

echo "========================================="
echo "Creating docker-compose.yml..."
echo "========================================="
cat > docker-compose.yml <<EOF
services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - /var/jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    # Secure: Runs as non-root user (1000), but adds them to the host docker group
    user: "1000:$DOCKER_GID"
EOF

echo "========================================="
echo "Launching Jenkins Container..."
echo "========================================="
docker compose up -d

# Giving Jenkins a brief moment to unpack its file structures before modification
sleep 5

echo "========================================="
echo "Provisioning Docker CLI inside Jenkins..."
echo "========================================="
docker exec -u 0 -it jenkins bash -c "apt update && apt install -y docker.io"

echo "========================================="
echo "Deployment Initialization Complete!"
echo "========================================="
echo "Access your Jenkins UI at: http://$(curl -s ifconfig.me):8080"
echo "To fetch your initial unlock password, run: docker logs jenkins"
echo "========================================="