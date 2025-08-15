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

## Локальная установка и запуск

### 1. Клонирование репозитория

```bash
git clone https://github.com/Bdjauajn82827/cardflow.git
cd cardflow
```

### 2. Установка зависимостей

```bash
npm run install-all
```

### 3. Настройка переменных окружения

#### Бэкенд (.env файл в папке backend):
```
PORT=5000
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=IFEzoP0ppdwJ7d39
DB_HOST=db.eskiyhqhittzpwoxfmvq.supabase.co
DB_PORT=5432
DATABASE_URL=postgresql://postgres:IFEzoP0ppdwJ7d39@db.eskiyhqhittzpwoxfmvq.supabase.co:5432/postgres
JWT_SECRET=059713690b6fa1eba46f5c97d4307a6f9c0077c34329dd8bacd931513b67496a1d2ac56c72ff0e88b7cb77cc3928c9eee2c90dd5e5889bd7cdaf14dbca57bcde
JWT_EXPIRES_IN=7d
```

#### Фронтенд (.env файл в папке frontend):
```
REACT_APP_API_URL=http://localhost:5000/api
```

### 4. Запуск приложения

```bash
# Запуск в режиме разработки
npm run dev

# Или запуск отдельных компонентов
npm run frontend
npm run backend
```

Приложение будет доступно по адресу [http://localhost:3000](http://localhost:3000).

## Деплой на Vercel

Для деплоя приложения на Vercel с использованием базы данных Supabase следуйте инструкциям в файле [vercel_setup_instructions.md](/vercel_setup_instructions.md).

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
│   │   ├── utils/      # Вспомогательные функции
│   │   ├── App.tsx     # Корневой компонент
│   │   └── index.tsx   # Входная точка React
│   ├── .env            # Переменные окружения для фронтенда
│   └── package.json    # Зависимости фронтенда
├── vercel.json         # Конфигурация для Vercel
├── database_setup.md   # Инструкции по настройке базы данных
├── vercel_env_setup.md # Инструкции по настройке переменных окружения
├── package.json        # Корневые скрипты и зависимости
└── README.md           # Документация проекта
```

## Лицензия

MIT

## Требования

- Node.js (v14+)
- MongoDB (локально или в облаке)
- NPM или Yarn

## Локальная установка и запуск

### 1. Клонирование репозитория

```bash
git clone https://github.com/Bdjauajn82827/cardflow.git
cd cardflow
```

### 2. Установка зависимостей

```bash
# Для бэкенда:
cd backend
npm install

# Для фронтенда:
cd ../frontend
npm install
```

### 3. Настройка базы данных и переменных окружения

#### 3.1. Запуск SQL-скрипта для инициализации базы данных

Перед первым запуском необходимо создать структуру базы данных:

1. Зайдите в панель управления Supabase
2. Перейдите в раздел SQL Editor
3. Создайте новый запрос и вставьте содержимое файла `database_schema.sql`
4. Выполните скрипт

#### 3.2. Настройка переменных окружения

#### Бэкенд (.env файл в папке backend):
```
PORT=5000
MONGODB_URI=mongodb://localhost:27017/cardflow
JWT_SECRET=your_jwt_secret_should_be_long_and_complex
JWT_EXPIRES_IN=7d
```

#### Фронтенд (.env файл в папке frontend):
```
REACT_APP_API_URL=http://localhost:5000/api
```

### 4. Запуск MongoDB (если используете локально)

```bash
mongod
```

### 5. Запуск приложения

#### Запуск бэкенда в режиме разработки:
```bash
cd backend
npm run dev
```

#### Запуск фронтенда в режиме разработки:
```bash
cd frontend
npm start
```

Приложение будет доступно по адресу [http://localhost:3000](http://localhost:3000).

### 6. Запуск с использованием Docker (альтернативный способ)

Если у вас установлены Docker и Docker Compose, вы можете запустить все компоненты приложения одной командой:

```bash
# Для режима разработки
docker-compose -f docker-compose.dev.yml up

# Или для production режима
docker-compose up
```

Приложение будет доступно по адресу [http://localhost:3000](http://localhost:3000) в режиме разработки или [http://localhost](http://localhost) в production режиме.

## Деплой на продакшн

### Деплой на Vercel

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

## Структура проекта

```
cardflow/
├── backend/
│   ├── src/
│   │   ├── middleware/  # Middleware для аутентификации
│   │   ├── models/      # Mongoose модели
│   │   ├── routes/      # Express маршруты
│   │   └── server.js    # Входная точка сервера
│   ├── .env             # Переменные окружения для бэкенда
│   └── package.json     # Зависимости бэкенда
├── frontend/
│   ├── public/          # Статические файлы
│   ├── src/
│   │   ├── components/  # React компоненты
│   │   ├── models/      # TypeScript интерфейсы
│   │   ├── pages/       # Страницы приложения
│   │   ├── services/    # API сервисы
│   │   ├── store/       # Redux хранилище
│   │   ├── styles/      # Глобальные стили
│   │   ├── utils/       # Вспомогательные функции
│   │   ├── App.tsx      # Корневой компонент
│   │   └── index.tsx    # Входная точка React
│   ├── .env             # Переменные окружения для фронтенда
│   └── package.json     # Зависимости фронтенда
├── README.md            # Документация проекта
```

## Лицензия

MIT
