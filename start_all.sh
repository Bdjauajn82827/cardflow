#!/bin/bash
cd "$(dirname "$0")"
echo "Запуск всех сервисов..."
if ! command -v concurrently &> /dev/null; then
    echo "Установка concurrently..."
    npm install -g concurrently
fi
concurrently "npm run backend --prefix ./backend" "npm run start --prefix ./frontend"
