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

# Функция для проверки успешности выполнения команды
check_result() {
    if [ $? -eq 0 ]; then
        print_message "$1" "${GREEN}✓"
    else
        print_message "$2" "${RED}✗"
        if [ "$3" = "exit" ]; then
            exit 1
        fi
    fi
}

# Функция для проверки наличия команды
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Функция проверки и убийства процесса на порту
kill_process_on_port() {
    PORT=$1
    PROCESS_PID=$(lsof -ti:$PORT)
    if [ ! -z "$PROCESS_PID" ]; then
        print_message "Порт $PORT занят. Пытаюсь освободить..." "${YELLOW}!"
        kill -9 $PROCESS_PID
        sleep 1
        check_result "Порт $PORT успешно освобожден" "Не удалось освободить порт $PORT"
    fi
}

# Начало скрипта
echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}         Установка и запуск CardFlow                 ${NC}"
echo -e "${BLUE}=====================================================${NC}"

# Создание лог-файла
LOG_FILE="cardflow_setup_$(date +%Y%m%d_%H%M%S).log"
print_message "Все действия будут записаны в лог-файл: $LOG_FILE" "${YELLOW}!"

# Определение дистрибутива
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_CODENAME
    print_message "Обнаружена операционная система: $OS_NAME $OS_VERSION" "${BLUE}i"
else
    OS_NAME="unknown"
    OS_VERSION="unknown"
    print_message "Не удалось определить операционную систему, будут использованы настройки по умолчанию" "${YELLOW}!"
fi

# Установка базовых зависимостей
print_header "Проверка и установка необходимых зависимостей"

# Проверка и установка Node.js и npm
if ! command_exists node; then
    print_message "Node.js не установлен. Устанавливаю..." "${YELLOW}!"
    sudo apt update >> "$LOG_FILE" 2>&1
    sudo apt install -y nodejs npm >> "$LOG_FILE" 2>&1
    check_result "Node.js установлен" "Ошибка при установке Node.js. Подробности в $LOG_FILE" "exit"
else
    NODE_VERSION=$(node -v)
    print_message "Node.js уже установлен (${NODE_VERSION})" "${GREEN}✓"
fi

# Проверка версии Node.js
NODE_MAJOR_VERSION=$(node -v | cut -d. -f1 | tr -d 'v')
if [ "$NODE_MAJOR_VERSION" -lt 14 ]; then
    print_message "Версия Node.js слишком старая. Минимальная версия - 14. Обновляю..." "${YELLOW}!"
    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash - >> "$LOG_FILE" 2>&1
    sudo apt install -y nodejs >> "$LOG_FILE" 2>&1
    check_result "Node.js обновлен до последней версии" "Ошибка при обновлении Node.js. Подробности в $LOG_FILE" "exit"
fi

# Установка Docker - это будет наш основной метод запуска MongoDB
print_message "Проверяю наличие Docker..." "${YELLOW}!"

if ! command_exists docker; then
    print_message "Docker не установлен. Устанавливаю..." "${YELLOW}!"
    
    # Установка Docker для Debian/Ubuntu
    sudo apt-get update >> "$LOG_FILE" 2>&1
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release >> "$LOG_FILE" 2>&1
    
    # Добавление GPG ключа Docker
    curl -fsSL https://download.docker.com/linux/$OS_NAME/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >> "$LOG_FILE" 2>&1
    
    # Добавление репозитория Docker
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS_NAME $OS_VERSION stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Установка Docker
    sudo apt-get update >> "$LOG_FILE" 2>&1
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io >> "$LOG_FILE" 2>&1
    
    # Создание группы docker, если её нет
    sudo groupadd -f docker >> "$LOG_FILE" 2>&1
    sudo usermod -aG docker $USER >> "$LOG_FILE" 2>&1
    
    check_result "Docker установлен" "Ошибка при установке Docker. Подробности в $LOG_FILE" "exit"
    
    print_message "Для применения прав группы docker вам может потребоваться перелогиниться." "${YELLOW}!"
    print_message "Для временного решения, команды Docker будут выполняться через sudo." "${YELLOW}!"
else
    print_message "Docker уже установлен" "${GREEN}✓"
fi

# Установка Docker Compose
if ! command_exists docker-compose; then
    print_message "Docker Compose не установлен. Устанавливаю..." "${YELLOW}!"
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
    sudo chmod +x /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
    check_result "Docker Compose установлен" "Ошибка при установке Docker Compose. Подробности в $LOG_FILE" "exit"
else
    print_message "Docker Compose уже установлен" "${GREEN}✓"
fi

# Проверка и установка Git
if ! command_exists git; then
    print_message "Git не установлен. Устанавливаю..." "${YELLOW}!"
    sudo apt update >> "$LOG_FILE" 2>&1
    sudo apt install -y git >> "$LOG_FILE" 2>&1
    check_result "Git установлен" "Ошибка при установке Git. Подробности в $LOG_FILE"
else
    print_message "Git уже установлен" "${GREEN}✓"
fi

# Подготовка директории проекта
print_header "Настройка проекта CardFlow"

# Определение директории проекта
PROJECT_DIR=$(pwd)
print_message "Директория проекта: $PROJECT_DIR" "${BLUE}i"

# Проверка существования директории проекта
if [ ! -d "$PROJECT_DIR/frontend" ] || [ ! -d "$PROJECT_DIR/backend" ]; then
    print_message "Директория проекта не содержит нужных файлов. Проверьте, что вы находитесь в корне проекта CardFlow." "${RED}✗"
    exit 1
fi

# Создание файлов Docker для MongoDB
print_message "Создаю docker-compose.yml для MongoDB..." "${YELLOW}!"

# Создание docker-compose.mongodb.yml для MongoDB
echo 'version: "3.8"
services:
  mongodb:
    image: mongo:latest
    container_name: cardflow-mongodb
    restart: unless-stopped
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    environment:
      - MONGO_INITDB_DATABASE=cardflow

volumes:
  mongodb_data:' > docker-compose.mongodb.yml

check_result "docker-compose.mongodb.yml создан" "Не удалось создать docker-compose.mongodb.yml"

# Запуск MongoDB в Docker
print_message "Запускаю MongoDB в Docker..." "${YELLOW}!"
if command_exists docker && (id -nG "$USER" | grep -qw "docker" || [ $(id -u) -eq 0 ]); then
    docker-compose -f docker-compose.mongodb.yml up -d >> "$LOG_FILE" 2>&1
else
    sudo docker-compose -f docker-compose.mongodb.yml up -d >> "$LOG_FILE" 2>&1
fi

check_result "MongoDB запущен в Docker" "Ошибка при запуске MongoDB. Подробности в $LOG_FILE"

# Проверка доступности MongoDB
print_message "Проверяю доступность MongoDB..." "${YELLOW}!"
sleep 5  # Даем время MongoDB для запуска

if command_exists docker && (id -nG "$USER" | grep -qw "docker" || [ $(id -u) -eq 0 ]); then
    MONGO_STATUS=$(docker ps | grep cardflow-mongodb | wc -l)
else
    MONGO_STATUS=$(sudo docker ps | grep cardflow-mongodb | wc -l)
fi

if [ "$MONGO_STATUS" -gt 0 ]; then
    print_message "MongoDB успешно запущен в Docker" "${GREEN}✓"
else
    print_message "Не удалось запустить MongoDB в Docker. Подробности в $LOG_FILE" "${RED}✗"
    exit 1
fi

# Установка зависимостей бэкенда
print_message "Устанавливаю зависимости бэкенда..." "${YELLOW}!"
cd "$PROJECT_DIR/backend"
npm install >> "../$LOG_FILE" 2>&1
check_result "Зависимости бэкенда установлены" "Ошибка при установке зависимостей бэкенда. Подробности в $LOG_FILE"

# Создание .env файла для бэкенда, если его нет
if [ ! -f .env ]; then
    print_message "Создаю .env файл для бэкенда..." "${YELLOW}!"
    # Генерация случайного JWT_SECRET
    JWT_SECRET=$(openssl rand -base64 32)
    
    echo "PORT=5000
MONGODB_URI=mongodb://localhost:27017/cardflow
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=7d" > .env
    
    check_result ".env файл создан для бэкенда" "Не удалось создать .env файл для бэкенда"
else
    print_message ".env файл для бэкенда уже существует" "${GREEN}✓"
fi

# Установка зависимостей фронтенда
print_message "Устанавливаю зависимости фронтенда..." "${YELLOW}!"
cd "$PROJECT_DIR/frontend"
npm install >> "../$LOG_FILE" 2>&1
check_result "Зависимости фронтенда установлены" "Ошибка при установке зависимостей фронтенда. Подробности в $LOG_FILE"

# Создание .env файла для фронтенда, если его нет
if [ ! -f .env ]; then
    print_message "Создаю .env файл для фронтенда..." "${YELLOW}!"
    echo "REACT_APP_API_URL=http://localhost:5000/api" > .env
    check_result ".env файл создан для фронтенда" "Не удалось создать .env файл для фронтенда"
else
    print_message ".env файл для фронтенда уже существует" "${GREEN}✓"
fi

# Исправление уязвимостей npm (если есть)
print_message "Проверяю и исправляю уязвимости npm..." "${YELLOW}!"
cd "$PROJECT_DIR/frontend"
npm audit fix >> "../$LOG_FILE" 2>&1
cd "$PROJECT_DIR/backend"
npm audit fix >> "../$LOG_FILE" 2>&1
print_message "Проверка уязвимостей завершена" "${GREEN}✓"

# Подготовка к запуску
print_header "Подготовка к запуску приложения"

# Проверка и освобождение портов
print_message "Проверяю доступность портов..." "${YELLOW}!"
kill_process_on_port 5000  # Backend порт
kill_process_on_port 3000  # Frontend порт

# Создание package.json для dev-режима, если его нет
cd "$PROJECT_DIR"
if [ ! -f dev-package.json ]; then
    print_message "Создаю dev-package.json для запуска в режиме разработки..." "${YELLOW}!"
    
    echo '{
  "name": "cardflow-dev",
  "version": "1.0.0",
  "description": "Development script for CardFlow",
  "scripts": {
    "frontend": "cd frontend && npm start",
    "backend": "cd backend && npm run dev",
    "dev": "concurrently \"npm run backend\" \"npm run frontend\"",
    "install-all": "npm install && (cd backend && npm install) && (cd frontend && npm install)"
  },
  "devDependencies": {
    "concurrently": "^8.2.0"
  }
}' > dev-package.json
    
    check_result "dev-package.json создан" "Не удалось создать dev-package.json"
    
    # Установка concurrently для запуска
    print_message "Устанавливаю concurrently..." "${YELLOW}!"
    npm install -g concurrently >> "$LOG_FILE" 2>&1
    check_result "concurrently установлен" "Не удалось установить concurrently. Подробности в $LOG_FILE"
fi

# Меню выбора способа запуска
print_header "Запуск CardFlow"
echo -e "${YELLOW}Выберите способ запуска:${NC}"
echo "1) Запустить бэкенд и фронтенд отдельно (в разных терминалах)"
echo "2) Запустить с помощью concurrently (в одном терминале)"
echo "3) Запустить с помощью Docker (полная контейнеризация)"
echo "4) Выйти без запуска"

read -p "Введите номер (1-4): " launch_option

case $launch_option in
    1)
        print_message "Запускаю бэкенд и фронтенд в отдельных терминалах..." "${YELLOW}!"
        
        # Запуск бэкенда в новом терминале
        if command_exists gnome-terminal; then
            gnome-terminal -- bash -c "cd '$PROJECT_DIR/backend' && npm run dev; exec bash"
        elif command_exists xterm; then
            xterm -e "cd '$PROJECT_DIR/backend' && npm run dev; exec bash" &
        else
            print_message "Не удалось открыть новый терминал. Запускаю бэкенд в фоновом режиме..." "${YELLOW}!"
            cd "$PROJECT_DIR/backend" && npm run dev >> "../backend.log" 2>&1 &
            BACKEND_PID=$!
            print_message "Бэкенд запущен с PID: $BACKEND_PID. Логи записываются в backend.log" "${GREEN}✓"
        fi
        
        # Небольшая пауза, чтобы бэкенд успел запуститься
        sleep 3
        
        # Запуск фронтенда в текущем терминале
        print_message "Запускаю фронтенд..." "${YELLOW}!"
        cd "$PROJECT_DIR/frontend" && npm start
        ;;
        
    2)
        print_message "Запускаю с помощью concurrently..." "${YELLOW}!"
        
        # Копирование dev-package.json в package.json, если это необходимо
        if [ ! -f package.json ] || ! grep -q "concurrently" package.json; then
            cp dev-package.json package.json
            npm install >> "$LOG_FILE" 2>&1
        fi
        
        # Запуск с помощью concurrently
        npm run dev
        ;;
        
    3)
        print_message "Создаю полную Docker-конфигурацию..." "${YELLOW}!"
        
        # Создание docker-compose.yml для полной контейнеризации
        echo 'version: "3.8"

services:
  mongodb:
    image: mongo:latest
    container_name: cardflow-mongodb
    restart: unless-stopped
    volumes:
      - mongodb_data:/data/db
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_DATABASE=cardflow

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: cardflow-backend
    restart: unless-stopped
    depends_on:
      - mongodb
    environment:
      - PORT=5000
      - MONGODB_URI=mongodb://mongodb:27017/cardflow
      - JWT_SECRET=your_jwt_secret_here
      - JWT_EXPIRES_IN=7d
    ports:
      - "5000:5000"
    volumes:
      - ./backend:/app
      - /app/node_modules

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: cardflow-frontend
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      - REACT_APP_API_URL=http://localhost:5000/api
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules

volumes:
  mongodb_data:' > docker-compose.yml
        
        check_result "docker-compose.yml создан" "Не удалось создать docker-compose.yml"
        
        # Создание Dockerfile для backend
        if [ ! -f backend/Dockerfile ]; then
            print_message "Создаю Dockerfile для бэкенда..." "${YELLOW}!"
            echo 'FROM node:18

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 5000

CMD ["npm", "run", "dev"]' > backend/Dockerfile
            check_result "Dockerfile для бэкенда создан" "Не удалось создать Dockerfile для бэкенда"
        fi
        
        # Создание Dockerfile для frontend
        if [ ! -f frontend/Dockerfile ]; then
            print_message "Создаю Dockerfile для фронтенда..." "${YELLOW}!"
            echo 'FROM node:18

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]' > frontend/Dockerfile
            check_result "Dockerfile для фронтенда создан" "Не удалось создать Dockerfile для фронтенда"
        fi
        
        # Остановка отдельного контейнера MongoDB, если он запущен
        print_message "Останавливаю отдельный контейнер MongoDB..." "${YELLOW}!"
        if command_exists docker && (id -nG "$USER" | grep -qw "docker" || [ $(id -u) -eq 0 ]); then
            docker-compose -f docker-compose.mongodb.yml down >> "$LOG_FILE" 2>&1
        else
            sudo docker-compose -f docker-compose.mongodb.yml down >> "$LOG_FILE" 2>&1
        fi
        
        # Запуск с помощью Docker Compose
        print_message "Запускаю Docker контейнеры..." "${YELLOW}!"
        
        if command_exists docker && (id -nG "$USER" | grep -qw "docker" || [ $(id -u) -eq 0 ]); then
            docker-compose up
        else
            sudo docker-compose up
        fi
        ;;
        
    4)
        print_message "Выход без запуска" "${BLUE}i"
        exit 0
        ;;
        
    *)
        print_message "Неверный выбор. Выход." "${RED}✗"
        exit 1
        ;;
esac

# Инструкции по доступу к приложению
print_header "Доступ к приложению"
print_message "После успешного запуска CardFlow будет доступен по адресу:" "${BLUE}i"
echo -e "${GREEN}http://localhost:3000${NC}"
print_message "Если вы видите ошибки, проверьте логи и убедитесь, что все компоненты запущены." "${YELLOW}!"

# Команды для остановки приложения
print_header "Остановка приложения"
print_message "Чтобы остановить все компоненты:" "${BLUE}i"
echo -e "${YELLOW}- Нажмите Ctrl+C в терминале с запущенными процессами${NC}"
echo -e "${YELLOW}- Или выполните 'docker-compose down', если вы использовали Docker${NC}"

print_message "MongoDB запущен в Docker и будет доступен для последующих запусков" "${GREEN}✓"
print_message "Чтобы остановить MongoDB, выполните 'docker-compose -f docker-compose.mongodb.yml down'" "${BLUE}i"

print_message "Установка и настройка завершены. Спасибо за использование CardFlow!" "${GREEN}✓"
