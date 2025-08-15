#!/bin/bash

echo "Установка зависимостей PostgreSQL..."
cd "$(dirname "$0")/backend"
npm install --save pg pg-hstore sequelize

echo "Готово! Теперь можно запустить приложение:"
echo "./start_postgres.sh"
