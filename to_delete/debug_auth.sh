#!/bin/bash

# Цвета для вывода в терминал
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Без цвета

# Функция для вывода сообщений с отступом
print_message() {
    echo -e "${2}  $1${NC}"
}

# Функция для вывода заголовка
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Создаем директорию для логов
LOG_DIR="$(pwd)/logs"
mkdir -p "$LOG_DIR"
DATA_DIR="$(pwd)/data/db"
mkdir -p "$DATA_DIR"

print_header "Диагностика проблемы регистрации в CardFlow"
print_message "Диагностика будет записана в папку $LOG_DIR" "${YELLOW}!"

# Проверка MongoDB
print_header "Проверка MongoDB"
if command -v mongod &> /dev/null; then
    print_message "MongoDB найден в системе" "${GREEN}✓"
    MONGO_VERSION=$(mongod --version | head -n 1)
    print_message "Версия MongoDB: $MONGO_VERSION" "${BLUE}i"
else
    print_message "MongoDB не найден. Возможно, нужно установить MongoDB." "${RED}✗"
    exit 1
fi

# Проверка, запущен ли уже MongoDB
MONGO_RUNNING=$(pgrep mongod || echo "")
if [ -n "$MONGO_RUNNING" ]; then
    print_message "MongoDB уже запущен, PID: $MONGO_RUNNING" "${GREEN}✓"
else
    print_message "Запускаем MongoDB..." "${YELLOW}!"
    mongod --dbpath "$DATA_DIR" --fork --logpath "$LOG_DIR/mongodb.log"
    sleep 3
    MONGO_RUNNING=$(pgrep mongod || echo "")
    if [ -n "$MONGO_RUNNING" ]; then
        print_message "MongoDB запущен, PID: $MONGO_RUNNING" "${GREEN}✓"
    else
        print_message "Не удалось запустить MongoDB. Проверьте логи: $LOG_DIR/mongodb.log" "${RED}✗"
        exit 1
    fi
fi

# Проверка подключения к MongoDB
print_message "Проверка подключения к MongoDB..." "${YELLOW}!"
echo "db.runCommand({ping:1})" | mongosh --quiet > "$LOG_DIR/mongo_connection.log" 2>&1
if grep -q "1" "$LOG_DIR/mongo_connection.log"; then
    print_message "Подключение к MongoDB успешно" "${GREEN}✓"
else
    print_message "Проблема с подключением к MongoDB. Проверьте логи: $LOG_DIR/mongo_connection.log" "${RED}✗"
    exit 1
fi

# Проверяем окружение backend
print_header "Проверка окружения backend"
cd "$(pwd)/backend"

# Проверка .env файла
if [ -f .env ]; then
    print_message ".env файл найден" "${GREEN}✓"
    # Копируем .env файл для анализа, удаляя чувствительные данные
    grep -v "JWT_SECRET" .env > "$LOG_DIR/env_redacted.log"
    print_message "Содержимое .env файла (без секретов) сохранено в $LOG_DIR/env_redacted.log" "${BLUE}i"
else
    print_message ".env файл не найден. Создаем его..." "${YELLOW}!"
    # Генерация случайного JWT_SECRET
    JWT_SECRET=$(openssl rand -base64 32)
    echo "PORT=5000
MONGODB_URI=mongodb://localhost:27017/cardflow
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=7d" > .env
    print_message "Создан новый .env файл" "${GREEN}✓"
fi

# Проверка соединения с MongoDB из backend
print_message "Проверка соединения с MongoDB из Node.js..." "${YELLOW}!"
node -e "
const mongoose = require('mongoose');
require('dotenv').config();
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/cardflow';
console.log('Connecting to MongoDB at:', MONGODB_URI);
mongoose
  .connect(MONGODB_URI)
  .then(() => {
    console.log('Connected to MongoDB successfully');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Failed to connect to MongoDB', err);
    process.exit(1);
  });
" > "$LOG_DIR/mongoose_connection.log" 2>&1

if grep -q "Connected to MongoDB successfully" "$LOG_DIR/mongoose_connection.log"; then
    print_message "Node.js успешно подключился к MongoDB" "${GREEN}✓"
else
    print_message "Проблема с подключением Node.js к MongoDB. Проверьте логи: $LOG_DIR/mongoose_connection.log" "${RED}✗"
    cat "$LOG_DIR/mongoose_connection.log"
    exit 1
fi

# Запускаем тест регистрации
print_header "Тестирование API регистрации"
print_message "Запускаем backend на порту 5000..." "${YELLOW}!"

# Проверяем, не занят ли порт 5000
PORT_USAGE=$(lsof -i :5000 -t || echo "")
if [ -n "$PORT_USAGE" ]; then
    print_message "Порт 5000 уже занят процессом $PORT_USAGE. Освобождаем..." "${YELLOW}!"
    kill -9 $PORT_USAGE
    sleep 1
fi

# Запускаем backend
node src/server.js > "$LOG_DIR/backend.log" 2>&1 &
BACKEND_PID=$!
print_message "Backend запущен с PID: $BACKEND_PID. Логи: $LOG_DIR/backend.log" "${GREEN}✓"
sleep 5

# Отправляем тестовый запрос регистрации
print_message "Отправляем тестовый запрос регистрации..." "${YELLOW}!"
TEST_EMAIL="test$(date +%s)@example.com"
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test User\",\"email\":\"$TEST_EMAIL\",\"password\":\"password123\",\"confirmPassword\":\"password123\"}" \
  http://localhost:5000/api/auth/register -v > "$LOG_DIR/registration_test.log" 2>&1

# Анализируем результат
if grep -q "\"token\":" "$LOG_DIR/registration_test.log"; then
    print_message "Регистрация прошла успешно!" "${GREEN}✓"
    print_message "Детали ответа сохранены в $LOG_DIR/registration_test.log" "${BLUE}i"
else
    print_message "Проблема с регистрацией. Проверьте логи: $LOG_DIR/registration_test.log" "${RED}✗"
    print_message "Содержимое логов регистрации:" "${YELLOW}!"
    cat "$LOG_DIR/registration_test.log"
fi

# Отправляем тестовый запрос на авторизацию
print_message "Отправляем тестовый запрос авторизации..." "${YELLOW}!"
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"password123\"}" \
  http://localhost:5000/api/auth/login -v > "$LOG_DIR/login_test.log" 2>&1

# Анализируем результат
if grep -q "\"token\":" "$LOG_DIR/login_test.log"; then
    print_message "Авторизация прошла успешно!" "${GREEN}✓"
    print_message "Детали ответа сохранены в $LOG_DIR/login_test.log" "${BLUE}i"
else
    print_message "Проблема с авторизацией. Проверьте логи: $LOG_DIR/login_test.log" "${RED}✗"
    print_message "Содержимое логов авторизации:" "${YELLOW}!"
    cat "$LOG_DIR/login_test.log"
fi

# Проверяем проблемы во фронтенде
print_header "Проверка фронтенд настроек"
cd "../frontend"

# Проверка .env файла для фронтенда
if [ -f .env ]; then
    print_message ".env файл фронтенда найден" "${GREEN}✓"
    cat .env > "$LOG_DIR/frontend_env.log"
    print_message "Содержимое .env файла фронтенда сохранено в $LOG_DIR/frontend_env.log" "${BLUE}i"
else
    print_message ".env файл фронтенда не найден. Создаем его..." "${YELLOW}!"
    echo "REACT_APP_API_URL=http://localhost:5000/api" > .env
    print_message "Создан новый .env файл фронтенда" "${GREEN}✓"
fi

# Анализируем API URL в коде
grep -r "API_URL" --include="*.ts" --include="*.tsx" src/ > "$LOG_DIR/api_url_usage.log"
print_message "Использование API_URL во фронтенде сохранено в $LOG_DIR/api_url_usage.log" "${BLUE}i"

# Завершаем процессы
print_header "Завершение диагностики"
print_message "Останавливаем backend..." "${YELLOW}!"
kill $BACKEND_PID
print_message "Backend остановлен" "${GREEN}✓"

print_message "Диагностика завершена. Все результаты сохранены в папке $LOG_DIR" "${GREEN}✓"
print_message "Для анализа проблем с регистрацией проверьте следующие файлы:" "${BLUE}i"
print_message "- Логи MongoDB: $LOG_DIR/mongodb.log" "${BLUE}i"
print_message "- Логи соединения с базой: $LOG_DIR/mongoose_connection.log" "${BLUE}i"
print_message "- Логи тестовой регистрации: $LOG_DIR/registration_test.log" "${BLUE}i"
print_message "- Логи тестовой авторизации: $LOG_DIR/login_test.log" "${BLUE}i"
print_message "- Настройки API во фронтенде: $LOG_DIR/api_url_usage.log" "${BLUE}i"

# Предлагаем действия по исправлению
print_header "Возможные решения проблемы"
print_message "1. Проверьте CORS настройки в backend/src/server.js" "${YELLOW}!"
print_message "2. Проверьте, что URL в frontend/.env правильно указывает на backend API" "${YELLOW}!"
print_message "3. Проверьте сетевые настройки, если frontend и backend запущены на разных хостах" "${YELLOW}!"
print_message "4. Проверьте наличие ошибок в консоли браузера при попытке регистрации" "${YELLOW}!"
print_message "5. Убедитесь, что MongoDB запущен и доступен" "${YELLOW}!"
