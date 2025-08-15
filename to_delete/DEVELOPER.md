# Инструкция для разработчиков CardFlow

## Первоначальная настройка

1. Установите зависимости для разработки:

```bash
# Установка зависимостей для запуска в режиме разработки
npm install -g concurrently
cp dev-package.json package.json
npm install
```

2. Установите зависимости проекта:

```bash
# Быстрая установка всех зависимостей
npm run install-all

# или установите зависимости по отдельности
cd backend && npm install
cd ../frontend && npm install
```

## Запуск в режиме разработки

Запустите оба сервера (frontend и backend) одновременно:

```bash
npm run dev
```

Или запустите их по отдельности:

```bash
# Запуск только backend
npm run backend

# Запуск только frontend
npm run frontend
```

## Структура проекта

### Backend

- `backend/src/server.js` - Основной файл сервера Express
- `backend/src/models/` - Mongoose модели данных
- `backend/src/routes/` - Express маршруты API
- `backend/src/middleware/` - Middleware для аутентификации и др.

### Frontend

- `frontend/src/App.tsx` - Основной компонент приложения
- `frontend/src/pages/` - Компоненты страниц
- `frontend/src/components/` - Переиспользуемые компоненты
- `frontend/src/store/` - Redux хранилище
- `frontend/src/services/` - API сервисы
- `frontend/src/models/` - TypeScript интерфейсы
- `frontend/src/styles/` - Глобальные стили
- `frontend/src/utils/` - Вспомогательные функции

## Сборка для продакшена

1. Сборка frontend:

```bash
cd frontend && npm run build
```

2. Запуск backend в режиме production:

```bash
cd backend
NODE_ENV=production npm start
```

## Запуск с использованием Docker

```bash
# Запуск в режиме разработки
docker-compose -f docker-compose.dev.yml up

# Запуск в режиме production
docker-compose up -d
```
