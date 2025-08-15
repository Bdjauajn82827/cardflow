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
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash - >> "$LOG_FILE" 2>&1
    sudo apt install -y nodejs >> "$LOG_FILE" 2>&1
    check_result "Node.js обновлен до последней версии" "Ошибка при обновлении Node.js. Подробности в $LOG_FILE" "exit"
fi

# Проверка и установка MongoDB
if ! command_exists mongod; then
    print_message "MongoDB не установлен. Устанавливаю..." "${YELLOW}!"
    sudo apt update >> "$LOG_FILE" 2>&1
    sudo apt install -y mongodb >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        print_message "Стандартная установка MongoDB не удалась. Пробую альтернативный способ..." "${YELLOW}!"
        # Альтернативный способ установки MongoDB
        wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add - >> "$LOG_FILE" 2>&1
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list >> "$LOG_FILE" 2>&1
        sudo apt update >> "$LOG_FILE" 2>&1
        sudo apt install -y mongodb-org >> "$LOG_FILE" 2>&1
        sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
        check_result "MongoDB установлен альтернативным способом" "Не удалось установить MongoDB. Подробности в $LOG_FILE" "exit"
    else
        check_result "MongoDB установлен" "Ошибка при установке MongoDB. Подробности в $LOG_FILE"
    fi
else
    print_message "MongoDB уже установлен" "${GREEN}✓"
fi

# Запуск MongoDB
print_message "Запускаю MongoDB..." "${YELLOW}!"
sudo systemctl start mongodb >> "$LOG_FILE" 2>&1
sleep 3

# Проверка статуса MongoDB
MONGO_STATUS=$(sudo systemctl is-active mongodb)
if [ "$MONGO_STATUS" = "active" ]; then
    print_message "MongoDB успешно запущен" "${GREEN}✓"
    sudo systemctl enable mongodb >> "$LOG_FILE" 2>&1
else
    print_message "MongoDB не запущен, проверяю альтернативный сервис..." "${YELLOW}!"
    
    # Проверка альтернативного имени сервиса
    sudo systemctl start mongod >> "$LOG_FILE" 2>&1
    sleep 3
    MONGO_STATUS=$(sudo systemctl is-active mongod)
    
    if [ "$MONGO_STATUS" = "active" ]; then
        print_message "MongoDB (mongod) успешно запущен" "${GREEN}✓"
        sudo systemctl enable mongod >> "$LOG_FILE" 2>&1
    else
        print_message "Не удалось запустить MongoDB. Пытаюсь запустить его вручную..." "${YELLOW}!"
        
        # Попытка запустить MongoDB вручную
        sudo mkdir -p /data/db >> "$LOG_FILE" 2>&1
        sudo chmod 777 /data/db >> "$LOG_FILE" 2>&1
        mongod --fork --logpath /var/log/mongodb.log >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            print_message "MongoDB запущен вручную" "${GREEN}✓"
        else
            print_message "Не удалось запустить MongoDB. Возможно, потребуется ручная установка." "${RED}✗"
            print_message "Продолжаю установку других компонентов..." "${YELLOW}!"
        fi
    fi
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
echo "3) Запустить с помощью Docker (если установлен)"
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
        print_message "Проверяю наличие Docker..." "${YELLOW}!"
        
        if ! command_exists docker || ! command_exists docker-compose; then
            print_message "Docker и/или Docker Compose не установлены. Устанавливаю..." "${YELLOW}!"
            
            # Установка Docker
            curl -fsSL https://get.docker.com -o get-docker.sh >> "$LOG_FILE" 2>&1
            sudo sh get-docker.sh >> "$LOG_FILE" 2>&1
            sudo usermod -aG docker $USER >> "$LOG_FILE" 2>&1
            
            # Установка Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
            sudo chmod +x /usr/local/bin/docker-compose >> "$LOG_FILE" 2>&1
            
            print_message "Docker и Docker Compose установлены. Требуется перелогиниться для применения прав группы docker." "${GREEN}✓"
            print_message "Пожалуйста, перезапустите скрипт после перелогинивания." "${YELLOW}!"
            exit 0
        else
            print_message "Docker и Docker Compose установлены" "${GREEN}✓"
        fi
        
        # Запуск с помощью Docker Compose
        print_message "Запускаю Docker контейнеры..." "${YELLOW}!"
        
        if [ -f docker-compose.dev.yml ]; then
            sudo docker-compose -f docker-compose.dev.yml up
        elif [ -f docker-compose.yml ]; then
            sudo docker-compose up
        else
            print_message "Файлы docker-compose не найдены. Не удалось запустить с помощью Docker." "${RED}✗"
            exit 1
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

# Команды для проверки здоровья приложения
print_message "Для проверки статуса всех компонентов, выполните:" "${BLUE}i"
echo -e "${YELLOW}./health-check.sh${NC}"

# Команды для остановки приложения
print_header "Остановка приложения"
print_message "Чтобы остановить все компоненты:" "${BLUE}i"
echo -e "${YELLOW}- Нажмите Ctrl+C в терминале с запущенными процессами${NC}"
echo -e "${YELLOW}- Или выполните 'docker-compose down', если вы использовали Docker${NC}"

print_message "Установка и настройка завершены. Спасибо за использование CardFlow!" "${GREEN}✓"
