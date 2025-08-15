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
DB_PASSWORD=your_password
DB_HOST=your_host.supabase.co
DB_PORT=5432
DATABASE_URL=postgresql://postgres:your_password@your_host.supabase.co:5432/postgres
JWT_SECRET=your_jwt_secret_should_be_long_and_complex
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

Для деплоя приложения на Vercel с использованием базы данных Supabase следуйте инструкциям в файле [vercel_deployment_guide.md](/vercel_deployment_guide.md).

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
git clone https://github.com/yourusername/cardflow.git
cd cardflow
```

### 2. Установка зависимостей

#### Для бэкенда:
```bash
cd backend
npm install
```

#### Для фронтенда:
```bash
cd ../frontend
npm install
```

### 3. Настройка переменных окружения

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

### Вариант 1: Деплой на Heroku

#### 1. Настройка репозитория для Heroku

Создайте файл `package.json` в корневой директории:

```json
{
  "name": "cardflow",
  "version": "1.0.0",
  "description": "Система организации информации с помощью карточек",
  "engines": {
    "node": "14.x"
  },
  "scripts": {
    "start": "cd backend && npm start",
    "heroku-postbuild": "cd backend && npm install && cd ../frontend && npm install && npm run build"
  }
}
```

Создайте файл `Procfile` в корневой директории:

```
web: cd backend && npm start
```

#### 2. Настройка Express для раздачи статических файлов

В файле `backend/src/server.js` добавьте следующий код:

```javascript
// Serve static assets in production
if (process.env.NODE_ENV === 'production') {
  // Set static folder
  app.use(express.static(path.join(__dirname, '../../frontend/build')));

  app.get('*', (req, res) => {
    res.sendFile(path.resolve(__dirname, '../../frontend/build', 'index.html'));
  });
}
```

#### 3. Создание приложения на Heroku и деплой

```bash
heroku create your-app-name
git add .
git commit -m "Ready for deployment"
git push heroku master
```

#### 4. Настройка переменных окружения на Heroku

```bash
heroku config:set MONGODB_URI=your_mongodb_uri
heroku config:set JWT_SECRET=your_jwt_secret
heroku config:set JWT_EXPIRES_IN=7d
heroku config:set NODE_ENV=production
```

### Вариант 2: Деплой с использованием Docker

#### 1. Предварительные требования

- Docker и Docker Compose установлены на вашем сервере
- Git для клонирования репозитория

#### 2. Клонирование репозитория

```bash
git clone https://github.com/yourusername/cardflow.git
cd cardflow
```

#### 3. Настройка переменных окружения

Создайте файл `.env` в корневой директории:

```
JWT_SECRET=your_jwt_secret_should_be_long_and_complex
JWT_EXPIRES_IN=7d
```

#### 4. Запуск с помощью Docker Compose

```bash
docker-compose up -d
```

Приложение будет доступно по адресу [http://localhost](http://localhost).

#### 5. Проверка логов

```bash
# Логи MongoDB
docker logs cardflow-mongodb

# Логи бэкенда
docker logs cardflow-backend

# Логи фронтенда
docker logs cardflow-frontend
```

#### 6. Остановка контейнеров

```bash
docker-compose down
```

### Вариант 3: Деплой на VPS (Ubuntu)

#### 1. Настройка сервера

```bash
# Обновление пакетов
sudo apt update
sudo apt upgrade

# Установка Node.js
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y nodejs

# Установка MongoDB
sudo apt install -y mongodb
sudo systemctl start mongodb
sudo systemctl enable mongodb

# Установка Nginx
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Установка PM2 для управления процессами
sudo npm install -g pm2
```

#### 2. Клонирование репозитория

```bash
git clone https://github.com/yourusername/cardflow.git
cd cardflow
```

#### 3. Настройка и сборка приложения

```bash
# Установка зависимостей бэкенда
cd backend
npm install

# Создание .env файла
echo "PORT=5000
MONGODB_URI=mongodb://localhost:27017/cardflow
JWT_SECRET=your_jwt_secret_should_be_long_and_complex
JWT_EXPIRES_IN=7d
NODE_ENV=production" > .env

# Установка зависимостей и сборка фронтенда
cd ../frontend
npm install
npm run build
```

#### 4. Настройка Nginx

Создайте файл конфигурации:

```bash
sudo nano /etc/nginx/sites-available/cardflow
```

Добавьте следующую конфигурацию:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        root /path/to/cardflow/frontend/build;
        try_files $uri /index.html;
    }

    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Активируйте конфигурацию:

```bash
sudo ln -s /etc/nginx/sites-available/cardflow /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

#### 5. Запуск приложения с PM2

```bash
cd /path/to/cardflow/backend
pm2 start src/server.js --name "cardflow-backend"
pm2 save
pm2 startup
```

#### 6. Настройка SSL с Certbot (опционально)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

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
