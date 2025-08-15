# Настройка базы данных для продакшена

Для хостинга базы данных PostgreSQL мы используем Supabase (https://supabase.com/), который предлагает бесплатный уровень с лимитом до 500MB хранилища и 2 миллиона запросов в месяц.

## Информация о базе данных

База данных уже создана в Supabase со следующими параметрами подключения:

- **Host**: db.eskiyhqhittzpwoxfmvq.supabase.co
- **Database name**: postgres
- **Port**: 5432
- **User**: postgres
- **Password**: IFEzoP0ppdwJ7d39
- **Connection URL**: postgresql://postgres:IFEzoP0ppdwJ7d39@db.eskiyhqhittzpwoxfmvq.supabase.co:5432/postgres

Эти данные уже добавлены в файл `.env` в директории backend и будут использоваться для настройки переменных окружения в Vercel.

## Миграция схемы базы данных:

Для создания необходимых таблиц в вашей базе данных Supabase, выполните следующий SQL-скрипт через SQL Editor в интерфейсе Supabase:

```sql
-- Создание таблицы пользователей
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  registration_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  settings JSONB DEFAULT '{}'::jsonb
);

-- Создание таблицы рабочих пространств
CREATE TABLE IF NOT EXISTS workspaces (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  "order" INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Создание таблицы карточек
CREATE TABLE IF NOT EXISTS cards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  title_color VARCHAR(20) DEFAULT '#FFFFFF',
  description TEXT,
  description_color VARCHAR(20) DEFAULT '#FFFFFF',
  content TEXT,
  background_color VARCHAR(20) DEFAULT '#3F51B5',
  position JSONB DEFAULT '{"x": 0, "y": 0}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Индексы для улучшения производительности
CREATE INDEX IF NOT EXISTS idx_workspaces_user_id ON workspaces(user_id);
CREATE INDEX IF NOT EXISTS idx_cards_workspace_id ON cards(workspace_id);
CREATE INDEX IF NOT EXISTS idx_cards_user_id ON cards(user_id);
```

Этот SQL-скрипт создаст необходимые таблицы и индексы для вашего приложения CardFlow.
