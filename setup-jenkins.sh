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
echo "Setting Up Jenkins Directory..."
echo "========================================="
mkdir -p /root/jenkins
cd /root/jenkins

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
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    user: root

volumes:
  jenkins_home:
EOF

echo "========================================="
echo "Launching Jenkins Container..."
echo "========================================="
docker compose up -d
docker exec -u 0 -it jenkins bash -c "apt update && apt install -y docker.io"
echo "========================================="
echo "Deployment Initialization Complete!"
echo "========================================="
echo "Access your Jenkins UI at: http://$(curl -s ifconfig.me):8080"
echo "To fetch your initial unlock password, run: docker logs jenkins"
echo "========================================="