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
    fi
}

# Остановка процессов frontend и backend
stop_application() {
    print_header "Остановка приложения CardFlow"
    
    # Остановка frontend процессов (React)
    print_message "Поиск и остановка процессов frontend (React)..." "${YELLOW}!"
    frontend_pids=$(pgrep -f "react-scripts start" || true)
    
    if [ -n "$frontend_pids" ]; then
        for pid in $frontend_pids; do
            print_message "Останавливаем frontend процесс (PID: $pid)..." "${YELLOW}!"
            kill -15 "$pid" 2>/dev/null
            check_result "Frontend процесс $pid остановлен" "Не удалось остановить frontend процесс $pid"
        done
    else
        print_message "Активные frontend процессы не найдены" "${GREEN}✓"
    fi
    
    # Остановка node-процессов backend
    print_message "Поиск и остановка процессов backend (Node.js)..." "${YELLOW}!"
    backend_pids=$(pgrep -f "node src/server.js" || true)
    
    if [ -n "$backend_pids" ]; then
        for pid in $backend_pids; do
            print_message "Останавливаем backend процесс (PID: $pid)..." "${YELLOW}!"
            kill -15 "$pid" 2>/dev/null
            check_result "Backend процесс $pid остановлен" "Не удалось остановить backend процесс $pid"
        done
    else
        print_message "Активные backend процессы не найдены" "${GREEN}✓"
    fi
    
    # Дополнительная проверка на другие node-процессы, связанные с путями проекта
    print_message "Поиск и остановка других node-процессов, связанных с проектом..." "${YELLOW}!"
    project_path=$(dirname "$(realpath "$0")")
    other_pids=$(ps aux | grep node | grep "$project_path" | grep -v grep | awk '{print $2}' || true)
    
    if [ -n "$other_pids" ]; then
        for pid in $other_pids; do
            if [[ ! "$frontend_pids $backend_pids" =~ $pid ]]; then
                print_message "Останавливаем дополнительный процесс (PID: $pid)..." "${YELLOW}!"
                kill -15 "$pid" 2>/dev/null
                check_result "Процесс $pid остановлен" "Не удалось остановить процесс $pid"
            fi
        done
    else
        print_message "Другие активные процессы не найдены" "${GREEN}✓"
    fi
    
    # Освобождение портов 3000 и 5000, если они заняты
    free_ports
}

# Освобождение занятых портов
free_ports() {
    print_header "Освобождение портов приложения"
    
    # Проверка и освобождение порта 3000 (frontend)
    pid_on_3000=$(lsof -t -i:3000 2>/dev/null || true)
    if [ -n "$pid_on_3000" ]; then
        print_message "Порт 3000 занят процессом $pid_on_3000, освобождаем..." "${YELLOW}!"
        kill -15 "$pid_on_3000" 2>/dev/null
        check_result "Порт 3000 освобожден" "Не удалось освободить порт 3000"
    else
        print_message "Порт 3000 (frontend) свободен" "${GREEN}✓"
    fi
    
    # Проверка и освобождение порта 5000 (backend)
    pid_on_5000=$(lsof -t -i:5000 2>/dev/null || true)
    if [ -n "$pid_on_5000" ]; then
        print_message "Порт 5000 занят процессом $pid_on_5000, освобождаем..." "${YELLOW}!"
        kill -15 "$pid_on_5000" 2>/dev/null
        check_result "Порт 5000 освобожден" "Не удалось освободить порт 5000"
    else
        print_message "Порт 5000 (backend) свободен" "${GREEN}✓"
    fi
}

# Очистка временных файлов
cleanup_temp_files() {
    print_header "Очистка временных файлов"
    
    # Переход в директорию backend
    cd "$(dirname "$0")/backend" 2>/dev/null || {
        print_message "Директория backend не найдена. Пропускаем..." "${YELLOW}!"
        return
    }
    
    # Удаление временных файлов в backend
    if [ -d "tmp" ]; then
        print_message "Очистка временных файлов backend..." "${YELLOW}!"
        rm -rf tmp/* 2>/dev/null
        check_result "Временные файлы backend очищены" "Ошибка при очистке временных файлов backend"
    else
        print_message "Директория tmp в backend не найдена" "${GREEN}✓"
    fi
    
    # Переход в директорию frontend
    cd "../frontend" 2>/dev/null || {
        print_message "Директория frontend не найдена. Пропускаем..." "${YELLOW}!"
        return
    }
    
    # Удаление временных файлов в frontend
    if [ -d "node_modules/.cache" ]; then
        print_message "Очистка кэша frontend (для устранения возможных конфликтов)..." "${YELLOW}!"
        rm -rf node_modules/.cache/* 2>/dev/null
        check_result "Кэш frontend очищен" "Ошибка при очистке кэша frontend"
    else
        print_message "Директория кэша в frontend не найдена" "${GREEN}✓"
    fi
    
    # Возврат в корневую директорию
    cd ".." || return
}

# Остановка PostgreSQL (по желанию)
stop_postgresql() {
    print_header "Управление сервисом PostgreSQL"
    
    # Спрашиваем пользователя, нужно ли останавливать PostgreSQL
    read -p "Остановить PostgreSQL? (y/n): " stop_pg
    
    if [[ "$stop_pg" =~ ^[Yy]$ ]]; then
        print_message "Останавливаем PostgreSQL..." "${YELLOW}!"
        sudo systemctl stop postgresql
        check_result "PostgreSQL остановлен" "Ошибка при остановке PostgreSQL"
    else
        print_message "PostgreSQL оставлен запущенным" "${GREEN}✓"
    fi
}

# Проверка результатов остановки
verify_shutdown() {
    print_header "Проверка результатов"
    
    # Проверяем процессы на портах 3000 и 5000
    if lsof -i:3000 &>/dev/null; then
        print_message "ВНИМАНИЕ: Порт 3000 всё ещё занят!" "${RED}✗"
    else
        print_message "Порт 3000 (frontend) успешно освобожден" "${GREEN}✓"
    fi
    
    if lsof -i:5000 &>/dev/null; then
        print_message "ВНИМАНИЕ: Порт 5000 всё ещё занят!" "${RED}✗"
    else
        print_message "Порт 5000 (backend) успешно освобожден" "${GREEN}✓"
    fi
    
    # Проверка на наличие процессов node в директории проекта
    project_path=$(dirname "$(realpath "$0")")
    if ps aux | grep node | grep "$project_path" | grep -v grep &>/dev/null; then
        print_message "ВНИМАНИЕ: Некоторые процессы node, связанные с проектом, всё ещё запущены!" "${RED}✗"
        print_message "Возможно, потребуется остановить их вручную" "${YELLOW}!"
    else
        print_message "Все процессы node, связанные с проектом, остановлены" "${GREEN}✓"
    fi
}

# Показать инструкции для запуска
show_restart_instructions() {
    print_header "Инструкции по запуску"
    
    print_message "Для запуска приложения выполните:" "${BLUE}i"
    print_message "  bash $(dirname "$(realpath "$0")")/start_postgres.sh" "${YELLOW}!"
    
    print_message "\nПриложение успешно остановлено!" "${GREEN}✓"
}

# Основная функция
main() {
    print_header "CardFlow - Остановка приложения"
    
    # Проверка наличия необходимых утилит
    if ! command -v lsof &>/dev/null; then
        print_message "Установка утилиты lsof для определения процессов на портах..." "${YELLOW}!"
        sudo apt-get update && sudo apt-get install -y lsof
        check_result "lsof установлен" "Ошибка при установке lsof, продолжаем без него..."
    fi
    
    # Вызов функций
    stop_application
    cleanup_temp_files
    # stop_postgresql # Раскомментируйте, если нужно останавливать PostgreSQL
    verify_shutdown
    show_restart_instructions
}

# Запуск основной функции
main
