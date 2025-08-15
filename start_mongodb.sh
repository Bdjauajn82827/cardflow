#!/bin/bash
DB_PATH="$(dirname "$0")/data/db"
mkdir -p "$DB_PATH"
echo "Запуск MongoDB с хранением данных в $DB_PATH"
echo "Нажмите Ctrl+C для остановки"
mongod --dbpath "$DB_PATH"
