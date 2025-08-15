# Обновленная информация о деплое

## URL приложения

- Временный URL: https://cardflow-2zhe3hjff-niks-projects-11ad09aa.vercel.app
- Постоянный домен: https://cards.bashbang.ru (ожидает настройки DNS)

## Выполненные шаги

1. Коммит изменений в репозиторий
2. Настройка переменных окружения:
   - NODE_ENV: production
   - DATABASE_URL: postgresql://postgres:IFEzoP0ppdwJ7d39@db.eskiyhqhittzpwoxfmvq.supabase.co:5432/postgres
   - DB_NAME: postgres
   - DB_USER: postgres
   - DB_PASSWORD: IFEzoP0ppdwJ7d39
   - DB_HOST: db.eskiyhqhittzpwoxfmvq.supabase.co
   - DB_PORT: 5432
   - JWT_SECRET: [безопасный случайный ключ]
   - JWT_EXPIRES_IN: 7d
3. Добавление и настройка типов для react-beautiful-dnd
4. Деплой приложения на Vercel
5. Добавление домена cards.bashbang.ru

## Для настройки домена

Необходимо добавить следующую DNS-запись на стороне регистратора домена:

```
A cards.bashbang.ru 76.76.21.21
```

## Дата деплоя

15 августа 2025 г.
