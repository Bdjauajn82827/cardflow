#!/bin/bash
cd "$(dirname "$0")"
echo "Запуск MongoDB в Docker..."
sudo docker-compose -f docker-compose.mongodb.yml up -d
