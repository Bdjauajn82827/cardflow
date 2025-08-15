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

# Функция для запуска MongoDB без использования Docker
setup_local_mongodb() {
    print_message "Настраиваю локальную базу данных MongoDB..." "${YELLOW}!"
    
    # Создаем директорию для MongoDB данных
    mkdir -p "$PROJECT_DIR/data/db"
    print_message "Директория для данных MongoDB создана: $PROJECT_DIR/data/db" "${GREEN}✓"
    
    # Создание скрипта для запуска MongoDB локально
    cat > "$PROJECT_DIR/start_mongodb.sh" << 'EOF'
#!/bin/bash
DB_PATH="$(dirname "$0")/data/db"
mkdir -p "$DB_PATH"
echo "Запуск MongoDB с хранением данных в $DB_PATH"
echo "Нажмите Ctrl+C для остановки"
mongod --dbpath "$DB_PATH"
EOF
    
    chmod +x "$PROJECT_DIR/start_mongodb.sh"
    print_message "Скрипт для запуска MongoDB создан: $PROJECT_DIR/start_mongodb.sh" "${GREEN}✓"
    
    # Создание скрипта для запуска mongosh
    cat > "$PROJECT_DIR/start_mongosh.sh" << 'EOF'
#!/bin/bash
echo "Подключение к MongoDB..."
mongosh
EOF
    
    chmod +x "$PROJECT_DIR/start_mongosh.sh"
    print_message "Скрипт для запуска MongoDB shell создан: $PROJECT_DIR/start_mongosh.sh" "${GREEN}✓"
    
    print_message "Локальная настройка MongoDB завершена" "${GREEN}✓"
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

# Создание скриптов для запуска сервисов
print_message "Создаю скрипты для запуска сервисов..." "${YELLOW}!"

# Скрипт для запуска бэкенда
cat > "$PROJECT_DIR/start_backend.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/backend"
echo "Запуск бэкенда..."
npm run dev
EOF
chmod +x "$PROJECT_DIR/start_backend.sh"

# Скрипт для запуска фронтенда
cat > "$PROJECT_DIR/start_frontend.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")/frontend"
echo "Запуск фронтенда..."
npm start
EOF
chmod +x "$PROJECT_DIR/start_frontend.sh"

# Скрипт для запуска обоих сервисов
cat > "$PROJECT_DIR/start_all.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "Запуск всех сервисов..."
if ! command -v concurrently &> /dev/null; then
    echo "Установка concurrently..."
    npm install -g concurrently
fi
concurrently "npm run backend --prefix ./backend" "npm run start --prefix ./frontend"
EOF
chmod +x "$PROJECT_DIR/start_all.sh"

# Создадим настройку MongoDB с локальным хранением
setup_local_mongodb

# Меню выбора способа запуска
print_header "Запуск CardFlow"
echo -e "${YELLOW}Выберите способ запуска:${NC}"
echo "1) Запустить бэкенд и фронтенд отдельно (в разных терминалах)"
echo "2) Запустить с помощью concurrently (в одном терминале)"
echo "3) Запустить с помощью MongoDB в Docker (если доступен)"
echo "4) Выйти без запуска"

read -p "Введите номер (1-4): " launch_option

case $launch_option in
    1)
        print_message "Для работы приложения вам потребуется запустить MongoDB, бэкенд и фронтенд." "${YELLOW}!"
        print_message "1. Запустите MongoDB: ./start_mongodb.sh" "${BLUE}i"
        print_message "2. Запустите бэкенд: ./start_backend.sh" "${BLUE}i"
        print_message "3. Запустите фронтенд: ./start_frontend.sh" "${BLUE}i"
        
        # Запуск MongoDB в новом терминале, если он установлен
        if command_exists mongod; then
            if command_exists gnome-terminal; then
                gnome-terminal -- bash -c "cd '$PROJECT_DIR' && ./start_mongodb.sh; exec bash"
                sleep 2
                gnome-terminal -- bash -c "cd '$PROJECT_DIR' && ./start_backend.sh; exec bash"
                sleep 1
                "$PROJECT_DIR/start_frontend.sh"
            elif command_exists xterm; then
                xterm -e "cd '$PROJECT_DIR' && ./start_mongodb.sh; exec bash" &
                sleep 2
                xterm -e "cd '$PROJECT_DIR' && ./start_backend.sh; exec bash" &
                sleep 1
                "$PROJECT_DIR/start_frontend.sh"
            else
                print_message "Не удалось открыть новые терминалы. Запустите скрипты вручную:" "${YELLOW}!"
                print_message "./start_mongodb.sh" "${BLUE}i"
                print_message "./start_backend.sh" "${BLUE}i"
                print_message "./start_frontend.sh" "${BLUE}i"
            fi
        else
            print_message "MongoDB не найден в системе. Пожалуйста, запустите MongoDB вручную, а затем выполните:" "${YELLOW}!"
            print_message "./start_backend.sh" "${BLUE}i"
            print_message "./start_frontend.sh" "${BLUE}i"
        fi
        ;;
        
    2)
        print_message "Запускаю с помощью concurrently..." "${YELLOW}!"
        
        # Запуск MongoDB, если он установлен
        if command_exists mongod; then
            print_message "Запускаю MongoDB в отдельном терминале..." "${YELLOW}!"
            if command_exists gnome-terminal; then
                gnome-terminal -- bash -c "cd '$PROJECT_DIR' && ./start_mongodb.sh; exec bash"
            elif command_exists xterm; then
                xterm -e "cd '$PROJECT_DIR' && ./start_mongodb.sh; exec bash" &
            else
                print_message "Не удалось открыть новый терминал для MongoDB. Запустите его вручную:" "${YELLOW}!"
                print_message "./start_mongodb.sh" "${BLUE}i"
            fi
            sleep 2
        else
            print_message "MongoDB не найден в системе. Пожалуйста, запустите MongoDB вручную перед запуском приложения." "${YELLOW}!"
            sleep 2
        fi
        
        # Запуск с помощью concurrently
        "$PROJECT_DIR/start_all.sh"
        ;;
        
    3)
        print_message "Проверяю наличие Docker..." "${YELLOW}!"
        
        if ! command_exists docker; then
            print_message "Docker не установлен. Хотите установить Docker? (y/n)" "${YELLOW}!"
            read -p "Введите ответ: " install_docker
            
            if [ "$install_docker" = "y" ] || [ "$install_docker" = "Y" ]; then
                print_message "Устанавливаю Docker..." "${YELLOW}!"
                
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
                
                print_message "Для применения прав группы docker вам потребуется перелогиниться." "${YELLOW}!"
                print_message "Пожалуйста, перезапустите скрипт после перелогинивания." "${YELLOW}!"
                exit 0
            else
                print_message "Установка Docker отменена. Пожалуйста, установите MongoDB вручную или выберите другой вариант запуска." "${YELLOW}!"
                exit 0
            fi
        else
            print_message "Docker установлен. Запускаю MongoDB в Docker..." "${GREEN}✓"
            
            # Создание Docker Compose файла для MongoDB
            cat > "$PROJECT_DIR/docker-compose.mongodb.yml" << 'EOF'
version: "3.8"
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
  mongodb_data:
EOF
            
            # Создание скрипта для запуска MongoDB в Docker
            cat > "$PROJECT_DIR/docker_start_mongodb.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "Запуск MongoDB в Docker..."
sudo docker-compose -f docker-compose.mongodb.yml up -d
EOF
            chmod +x "$PROJECT_DIR/docker_start_mongodb.sh"
            
            # Создание скрипта для остановки MongoDB в Docker
            cat > "$PROJECT_DIR/docker_stop_mongodb.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "Остановка MongoDB в Docker..."
sudo docker-compose -f docker-compose.mongodb.yml down
EOF
            chmod +x "$PROJECT_DIR/docker_stop_mongodb.sh"
            
            # Запуск MongoDB в Docker
            print_message "Запускаю MongoDB в Docker..." "${YELLOW}!"
            sudo docker-compose -f "$PROJECT_DIR/docker-compose.mongodb.yml" up -d >> "$LOG_FILE" 2>&1
            
            if [ $? -eq 0 ]; then
                print_message "MongoDB успешно запущен в Docker" "${GREEN}✓"
                
                # Запуск бэкенда и фронтенда
                print_message "Теперь запускаю бэкенд и фронтенд..." "${YELLOW}!"
                
                if command_exists gnome-terminal; then
                    gnome-terminal -- bash -c "cd '$PROJECT_DIR' && ./start_backend.sh; exec bash"
                    sleep 1
                    "$PROJECT_DIR/start_frontend.sh"
                elif command_exists xterm; then
                    xterm -e "cd '$PROJECT_DIR' && ./start_backend.sh; exec bash" &
                    sleep 1
                    "$PROJECT_DIR/start_frontend.sh"
                else
                    print_message "Не удалось открыть новые терминалы. Запустите скрипты вручную:" "${YELLOW}!"
                    print_message "./start_backend.sh" "${BLUE}i"
                    print_message "./start_frontend.sh" "${BLUE}i"
                fi
            else
                print_message "Не удалось запустить MongoDB в Docker. Подробности в $LOG_FILE" "${RED}✗"
                print_message "Пожалуйста, проверьте настройки Docker или выберите другой вариант запуска." "${YELLOW}!"
                exit 1
            fi
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
echo -e "${YELLOW}- Если MongoDB запущен в Docker, выполните './docker_stop_mongodb.sh'${NC}"

print_message "Установка и настройка завершены. Спасибо за использование CardFlow!" "${GREEN}✓"
