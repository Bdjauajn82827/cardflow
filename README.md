# CardFlow - Система организации информации с помощью карточек

CardFlow - это веб-приложение для организации и хранения информации в формате карточек с возможностью гибкой настройки и организации данных по рабочим пространствам.

## Особенности

- Авторизация и аутентификация пользователей
- Создание, редактирование, перемещение и удаление карточек
- Организация карточек по рабочим пространствам (до 7 вкладок)
- Персонализация внешнего вида карточек
- Поддержка темной и светлой тем интерфейса
- Полностью адаптивный дизайн

## Технологический стек

### Фронтенд
- React.js + TypeScript
- Redux для управления состоянием
- Styled-components для стилизации
- Formik + Yup для работы с формами
- TinyMCE для редактирования форматированного текста
- React Beautiful DnD для перетаскивания карточек

### Бэкенд
- Node.js + Express
- PostgreSQL (Sequelize ORM) для хранения данных
- JWT для аутентификации
- Express-validator для валидации данных

## Требования

- Node.js (v14+)
- PostgreSQL (через Supabase)
- NPM или Yarn

## Настройка и запуск

### 1. Клонирование репозитория

```bash
git clone https://github.com/Bdjauajn82827/cardflow.git
cd cardflow
```

### 2. Установка зависимостей

```bash
npm run install-all
```

### 3. Настройка базы данных и переменных окружения

#### 3.1. Инициализация базы данных в Supabase

1. Создайте проект в [Supabase](https://supabase.com/)
2. В разделе SQL Editor выполните скрипт из файла `database_schema.sql`

#### 3.2. Настройка переменных окружения

**Бэкенд (.env файл в папке backend):**
```
PORT=5000
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your_supabase_password
DB_HOST=your_host.supabase.co
DB_PORT=5432
DATABASE_URL=postgresql://postgres:your_supabase_password@your_host.supabase.co:5432/postgres
JWT_SECRET=your_generated_jwt_secret
JWT_EXPIRES_IN=7d
```

**Фронтенд (.env файл в папке frontend):**
```
REACT_APP_API_URL=http://localhost:5000/api
```

### 4. Локальный запуск для разработки (опционально)

```bash
# Запуск в режиме разработки
npm run dev
```

Приложение будет доступно по адресу [http://localhost:3000](http://localhost:3000).

## Структура проекта

```
cardflow/
├── backend/
│   ├── api/            # Точка входа для Vercel Serverless Functions
│   ├── src/
│   │   ├── database/   # Модели и конфигурация Sequelize
│   │   ├── middleware/ # Middleware для аутентификации
│   │   ├── routes/     # Express маршруты
│   │   ├── server.js   # Конфигурация Express-сервера
│   │   └── index.js    # Точка входа сервера
│   ├── .env            # Переменные окружения для бэкенда
│   └── package.json    # Зависимости бэкенда
├── frontend/
│   ├── public/         # Статические файлы
│   ├── src/
│   │   ├── components/ # React компоненты
│   │   ├── models/     # TypeScript интерфейсы
│   │   ├── pages/      # Страницы приложения
│   │   ├── services/   # API сервисы
│   │   ├── store/      # Redux хранилище
│   │   ├── styles/     # Глобальные стили
│   │   ├── App.tsx     # Корневой компонент
│   │   └── index.tsx   # Входная точка React
│   ├── .env            # Переменные окружения для фронтенда
│   └── package.json    # Зависимости фронтенда
├── database_schema.sql # SQL-скрипт для инициализации БД Supabase
├── vercel.json         # Конфигурация для Vercel
├── vercel_setup_instructions.md # Инструкции по настройке Vercel
├── package.json        # Корневые скрипты и зависимости
└── README.md           # Документация проекта
```

## Деплой на Vercel

Проект настроен для деплоя на платформу Vercel с использованием базы данных Supabase. Для деплоя следуйте инструкциям в файле [vercel_setup_instructions.md](/vercel_setup_instructions.md).

Основные шаги:

1. Форкните или клонируйте репозиторий на GitHub
2. Подключите ваш репозиторий в Vercel
3. Настройте переменные окружения в Vercel
4. Запустите деплой
5. Подключите ваш домен (если необходимо)

Переменные окружения Vercel:
- DATABASE_URL: строка подключения к Supabase
- JWT_SECRET: секретный ключ JWT
- NODE_ENV: production

## Лицензия

MIT

## Лицензия

MIT
