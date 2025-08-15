#!/bin/bash
cd "$(dirname "$0")"
echo "Остановка MongoDB в Docker..."
sudo docker-compose -f docker-compose.mongodb.yml down
