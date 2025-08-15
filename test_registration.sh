#!/bin/bash

# Создаем директорию для логов
LOG_DIR="/home/nixx/cards/logs"
mkdir -p "$LOG_DIR"

# Запускаем MongoDB в отдельном терминале
gnome-terminal -- bash -c "mongod --dbpath /home/nixx/cards/data/db" &

# Даем MongoDB время для запуска
sleep 3

# Запускаем backend с логированием
cd /home/nixx/cards/backend
LOG_FILE="$LOG_DIR/backend_$(date +%Y%m%d_%H%M%S).log"
echo "Запускаем backend с логированием в $LOG_FILE"
NODE_ENV=development node src/server.js > "$LOG_FILE" 2>&1 &
BACKEND_PID=$!

# Даем backend время для запуска
sleep 2

# Добавляем curl запрос для проверки регистрации
echo "Тестируем регистрацию пользователя..."
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123","confirmPassword":"password123"}' \
  http://localhost:5000/api/auth/register > "$LOG_DIR/registration_test.log" 2>&1

echo "Логи регистрации сохранены в $LOG_DIR/registration_test.log"

# Ожидаем ввода пользователя перед завершением
echo "Нажмите Enter для завершения работы серверов"
read

# Завершаем процессы
kill $BACKEND_PID
killall mongod

echo "Серверы остановлены"
