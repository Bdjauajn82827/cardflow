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

# Проверка и установка PostgreSQL
setup_postgresql() {
    print_header "Проверка и установка PostgreSQL"
    
    # Проверка, установлен ли PostgreSQL
    if command -v psql &> /dev/null; then
        print_message "PostgreSQL уже установлен" "${GREEN}✓"
    else
        print_message "Установка PostgreSQL..." "${YELLOW}!"
        sudo apt update
        sudo apt install -y postgresql postgresql-contrib
        check_result "PostgreSQL установлен" "Ошибка при установке PostgreSQL" "exit"
    fi
    
    # Запуск PostgreSQL, если не запущен
    if ! systemctl is-active --quiet postgresql; then
        print_message "Запуск PostgreSQL..." "${YELLOW}!"
        sudo systemctl start postgresql
        check_result "PostgreSQL запущен" "Ошибка при запуске PostgreSQL" "exit"
    else
        print_message "PostgreSQL уже запущен" "${GREEN}✓"
    fi
}

# Создание базы данных PostgreSQL
setup_database() {
    print_header "Настройка базы данных PostgreSQL"
    
    DB_NAME="cardflow"
    DB_USER="cardflow_user"
    DB_PASSWORD="cardflow_password"
    
    # Проверка, существует ли пользователь
    USER_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" 2>/dev/null)
    
    if [ "$USER_EXISTS" = "1" ]; then
        print_message "Пользователь $DB_USER уже существует" "${GREEN}✓"
    else
        print_message "Создание пользователя $DB_USER..." "${YELLOW}!"
        sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
        check_result "Пользователь создан" "Ошибка при создании пользователя" "exit"
    fi
    
    # Проверка, существует ли база данных
    DB_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null)
    
    if [ "$DB_EXISTS" = "1" ]; then
        print_message "База данных $DB_NAME уже существует" "${GREEN}✓"
    else
        print_message "Создание базы данных $DB_NAME..." "${YELLOW}!"
        sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
        check_result "База данных создана" "Ошибка при создании базы данных" "exit"
        
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
        check_result "Права предоставлены" "Ошибка при предоставлении прав" "exit"
    fi
    
    print_message "База данных настроена успешно" "${GREEN}✓"
    print_message "Имя БД: $DB_NAME, Пользователь: $DB_USER, Пароль: $DB_PASSWORD" "${BLUE}i"
}

# Установка зависимостей проекта
install_dependencies() {
    print_header "Установка зависимостей проекта"
    
    # Переход в директорию backend
    cd "$(dirname "$0")/backend" || exit 1
    
    # Установка зависимостей для PostgreSQL
    print_message "Установка pg, pg-hstore и sequelize..." "${YELLOW}!"
    npm install --save pg pg-hstore sequelize
    check_result "Зависимости установлены" "Ошибка при установке зависимостей" "exit"
    
    # Установка остальных зависимостей
    print_message "Проверка наличия node_modules..." "${YELLOW}!"
    if [ ! -d "node_modules" ]; then
        print_message "Установка зависимостей backend..." "${YELLOW}!"
        npm install
        check_result "Зависимости backend установлены" "Ошибка при установке зависимостей backend" "exit"
    else
        print_message "Зависимости backend уже установлены" "${GREEN}✓"
    fi
    
    # Переход в директорию frontend
    cd "../frontend" || exit 1
    
    # Установка зависимостей frontend
    print_message "Проверка наличия node_modules..." "${YELLOW}!"
    if [ ! -d "node_modules" ]; then
        print_message "Установка зависимостей frontend..." "${YELLOW}!"
        npm install
        check_result "Зависимости frontend установлены" "Ошибка при установке зависимостей frontend" "exit"
    else
        print_message "Зависимости frontend уже установлены" "${GREEN}✓"
    fi
    
    # Возврат в корневую директорию
    cd ".." || exit 1
}

# Запуск приложения
start_application() {
    print_header "Запуск приложения CardFlow с PostgreSQL"
    
    # Запуск backend
    print_message "Запуск backend на порту 5000..." "${YELLOW}!"
    cd "$(dirname "$0")/backend" || exit 1
    node src/server.js &
    BACKEND_PID=$!
    check_result "Backend запущен (PID: $BACKEND_PID)" "Ошибка при запуске backend" "exit"
    
    # Небольшая пауза для запуска backend
    sleep 3
    
    # Запуск frontend
    print_message "Запуск frontend на порту 3000..." "${YELLOW}!"
    cd "../frontend" || exit 1
    npm start &
    FRONTEND_PID=$!
    check_result "Frontend запущен (PID: $FRONTEND_PID)" "Ошибка при запуске frontend" "exit"
    
    # Вывод информации о запущенных процессах
    print_header "Приложение CardFlow успешно запущено"
    print_message "Backend: http://localhost:5000" "${BLUE}i"
    print_message "Frontend: http://localhost:3000" "${BLUE}i"
    print_message "Backend PID: $BACKEND_PID" "${BLUE}i"
    print_message "Frontend PID: $FRONTEND_PID" "${BLUE}i"
    print_message "Нажмите Ctrl+C для завершения работы" "${BLUE}i"
    
    # Ожидание прерывания
    trap "kill $BACKEND_PID $FRONTEND_PID; exit" INT
    wait
}

# Основная функция
main() {
    print_header "CardFlow - Запуск с PostgreSQL"
    
    # Проверка наличия проекта
    if [ ! -d "$(dirname "$0")/backend" ] || [ ! -d "$(dirname "$0")/frontend" ]; then
        print_message "Ошибка: директории backend или frontend не найдены. Убедитесь, что скрипт запущен из корневой директории проекта." "${RED}✗"
        exit 1
    fi
    
    # Вызов функций
    setup_postgresql
    setup_database
    install_dependencies
    start_application
}

# Запуск основной функции
main
