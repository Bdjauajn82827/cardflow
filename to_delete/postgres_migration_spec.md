# Техническая спецификация: Миграция с MongoDB на PostgreSQL

## 1. Обоснование миграции

### 1.1. Проблемы с MongoDB
- Несовместимость с Debian Bookworm из-за зависимости от libssl1.1
- Сложности с обновлением и поддержкой
- Отсутствие строгой схемы данных, что затрудняет обеспечение целостности данных

### 1.2. Преимущества PostgreSQL
- Полноценная реляционная СУБД с транзакциями
- Надежность и широкое распространение в индустрии
- Строгая типизация и валидация данных
- Лучшая поддержка в долгосрочной перспективе
- Хорошая интеграция с Node.js через ORM Sequelize

## 2. Архитектура решения

### 2.1. Технологический стек
- **Backend**: Node.js + Express.js
- **ORM**: Sequelize для работы с PostgreSQL
- **База данных**: PostgreSQL 14+
- **Аутентификация**: JWT (без изменений)
- **API**: RESTful (без изменений)

### 2.2. Модель данных

#### 2.2.1. Таблица Users
```sql
CREATE TABLE "Users" (
  "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "email" VARCHAR(255) NOT NULL UNIQUE,
  "password" VARCHAR(255) NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "registrationDate" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "settings" JSONB DEFAULT '{"theme": "light"}'::jsonb,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);
```

#### 2.2.2. Таблица Workspaces
```sql
CREATE TABLE "Workspaces" (
  "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "userId" UUID NOT NULL REFERENCES "Users"("id") ON DELETE CASCADE,
  "name" VARCHAR(255) NOT NULL,
  "order" INTEGER DEFAULT 0,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);
```

#### 2.2.3. Таблица Cards
```sql
CREATE TABLE "Cards" (
  "id" UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  "workspaceId" UUID NOT NULL REFERENCES "Workspaces"("id") ON DELETE CASCADE,
  "userId" UUID NOT NULL REFERENCES "Users"("id"),
  "title" VARCHAR(255) NOT NULL,
  "titleColor" VARCHAR(50) DEFAULT '#FFFFFF',
  "description" TEXT NOT NULL,
  "descriptionColor" VARCHAR(50) DEFAULT '#FFFFFF',
  "content" TEXT DEFAULT '',
  "backgroundColor" VARCHAR(50) DEFAULT '#3F51B5',
  "position" JSONB DEFAULT '{"x": 0, "y": 0}'::jsonb,
  "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);
```

### 2.3. Структура моделей Sequelize

#### 2.3.1. Модель User
```javascript
// src/database/models/user.js
module.exports = (sequelize, DataTypes) => {
  class User extends Model {
    static associate(models) {
      User.hasMany(models.Workspace, { foreignKey: 'userId' });
    }

    async comparePassword(candidatePassword) {
      return bcrypt.compare(candidatePassword, this.password);
    }

    toJSON() {
      const values = Object.assign({}, this.get());
      delete values.password;
      return values;
    }
  }
  
  User.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: {
        isEmail: true,
      },
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: {
        len: [8, 100],
      },
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    registrationDate: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
    settings: {
      type: DataTypes.JSONB,
      defaultValue: {
        theme: 'light',
      },
    },
  }, {
    sequelize,
    modelName: 'User',
    hooks: {
      beforeCreate: async (user) => {
        if (user.password) {
          const salt = await bcrypt.genSalt(10);
          user.password = await bcrypt.hash(user.password, salt);
        }
      },
      beforeUpdate: async (user) => {
        if (user.changed('password')) {
          const salt = await bcrypt.genSalt(10);
          user.password = await bcrypt.hash(user.password, salt);
        }
      },
    },
  });
  
  return User;
};
```

#### 2.3.2. Модель Workspace
```javascript
// src/database/models/workspace.js
module.exports = (sequelize, DataTypes) => {
  class Workspace extends Model {
    static associate(models) {
      Workspace.belongsTo(models.User, { foreignKey: 'userId' });
      Workspace.hasMany(models.Card, { foreignKey: 'workspaceId' });
    }
  }
  
  Workspace.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    userId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'Users',
        key: 'id',
      },
      onDelete: 'CASCADE',
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    order: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
  }, {
    sequelize,
    modelName: 'Workspace',
  });
  
  return Workspace;
};
```

#### 2.3.3. Модель Card
```javascript
// src/database/models/card.js
module.exports = (sequelize, DataTypes) => {
  class Card extends Model {
    static associate(models) {
      Card.belongsTo(models.Workspace, { foreignKey: 'workspaceId' });
      Card.belongsTo(models.User, { foreignKey: 'userId' });
    }
  }
  
  Card.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    workspaceId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'Workspaces',
        key: 'id',
      },
      onDelete: 'CASCADE',
    },
    userId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'Users',
        key: 'id',
      },
    },
    title: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    titleColor: {
      type: DataTypes.STRING,
      defaultValue: '#FFFFFF',
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    descriptionColor: {
      type: DataTypes.STRING,
      defaultValue: '#FFFFFF',
    },
    content: {
      type: DataTypes.TEXT,
      defaultValue: '',
    },
    backgroundColor: {
      type: DataTypes.STRING,
      defaultValue: '#3F51B5',
    },
    position: {
      type: DataTypes.JSONB,
      defaultValue: { x: 0, y: 0 },
    },
  }, {
    sequelize,
    modelName: 'Card',
  });
  
  return Card;
};
```

## 3. Процесс миграции

### 3.1. Предварительные шаги
1. Создание резервной копии MongoDB:
   ```bash
   mongodump --db cardflow --out ./mongo_backup
   ```
   
2. Установка PostgreSQL на сервере:
   ```bash
   sudo apt update
   sudo apt install -y postgresql postgresql-contrib
   ```

3. Создание базы данных и пользователя:
   ```bash
   sudo -u postgres psql -c "CREATE USER cardflow_user WITH PASSWORD 'secure_password';"
   sudo -u postgres psql -c "CREATE DATABASE cardflow OWNER cardflow_user;"
   sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE cardflow TO cardflow_user;"
   ```

4. Установка необходимых пакетов Node.js:
   ```bash
   npm install --save sequelize pg pg-hstore
   ```

### 3.2. Изменения в проекте

1. Создание структуры директорий:
   ```
   backend/
   ├── src/
   │   ├── database/
   │   │   ├── config/
   │   │   │   └── config.js
   │   │   ├── migrations/
   │   │   ├── models/
   │   │   │   ├── index.js
   │   │   │   ├── user.js
   │   │   │   ├── workspace.js
   │   │   │   └── card.js
   ```

2. Настройка переменных окружения (.env):
   ```
   PORT=5000
   DB_NAME=cardflow
   DB_USER=cardflow_user
   DB_PASSWORD=secure_password
   DB_HOST=localhost
   JWT_SECRET=your_jwt_secret
   JWT_EXPIRES_IN=7d
   ```

3. Обновление серверного файла и маршрутов для работы с Sequelize

### 3.3. Трансформация API

#### 3.3.1. Обновление аутентификации
```javascript
// src/middleware/auth.js
const jwt = require('jsonwebtoken');
const { User } = require('../database/models');

module.exports = async (req, res, next) => {
  // Get token from header
  const token = req.header('Authorization')?.replace('Bearer ', '');

  // Check if no token
  if (!token) {
    return res.status(401).json({ message: 'No token, authorization denied' });
  }

  try {
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Find user by id
    const user = await User.findByPk(decoded.userId);
    if (!user) {
      return res.status(401).json({ message: 'Invalid token' });
    }

    // Set user in request
    req.user = user;
    req.userId = user.id;
    next();
  } catch (err) {
    res.status(401).json({ message: 'Token is not valid' });
  }
};
```

#### 3.3.2. Обновление маршрутов аутентификации
Вместо поиска по `_id` используется `findByPk` и другие методы Sequelize.

#### 3.3.3. Обновление маршрутов рабочих пространств и карточек
Аналогичные изменения для всех маршрутов, использующих MongoDB.

### 3.4. Процесс миграции данных

1. Создание скрипта миграции данных из MongoDB в PostgreSQL:
   ```javascript
   // scripts/migrate-data.js
   require('dotenv').config();
   const { MongoClient } = require('mongodb');
   const { sequelize, User, Workspace, Card } = require('../src/database/models');

   async function migrateData() {
     try {
       // Подключение к MongoDB
       const mongoClient = new MongoClient(process.env.MONGO_URI);
       await mongoClient.connect();
       const db = mongoClient.db('cardflow');
       
       // Получение данных из MongoDB
       const mongoUsers = await db.collection('users').find({}).toArray();
       const mongoWorkspaces = await db.collection('workspaces').find({}).toArray();
       const mongoCards = await db.collection('cards').find({}).toArray();
       
       // Синхронизация с PostgreSQL
       await sequelize.sync({ force: true });
       
       // Миграция пользователей
       for (const mongoUser of mongoUsers) {
         await User.create({
           id: mongoUser._id.toString(),
           email: mongoUser.email,
           password: mongoUser.password,
           name: mongoUser.name,
           registrationDate: mongoUser.registrationDate,
           settings: mongoUser.settings || { theme: 'light' },
         });
       }
       
       // Миграция рабочих пространств
       for (const mongoWorkspace of mongoWorkspaces) {
         await Workspace.create({
           id: mongoWorkspace._id.toString(),
           userId: mongoWorkspace.userId.toString(),
           name: mongoWorkspace.name,
           order: mongoWorkspace.order || 0,
         });
       }
       
       // Миграция карточек
       for (const mongoCard of mongoCards) {
         await Card.create({
           id: mongoCard._id.toString(),
           workspaceId: mongoCard.workspaceId.toString(),
           userId: mongoCard.userId.toString(),
           title: mongoCard.title,
           titleColor: mongoCard.titleColor || '#FFFFFF',
           description: mongoCard.description,
           descriptionColor: mongoCard.descriptionColor || '#FFFFFF',
           content: mongoCard.content || '',
           backgroundColor: mongoCard.backgroundColor || '#3F51B5',
           position: mongoCard.position || { x: 0, y: 0 },
         });
       }
       
       console.log('Миграция данных успешно завершена');
       await mongoClient.close();
       await sequelize.close();
     } catch (error) {
       console.error('Ошибка миграции данных:', error);
     }
   }
   
   migrateData();
   ```

2. Запуск скрипта миграции:
   ```bash
   node scripts/migrate-data.js
   ```

## 4. Тестирование и верификация

### 4.1. Проверка моделей
```bash
# Проверка создания пользователя
npx sequelize-cli db:seed:all --seed-test-user.js

# Проверка связей между моделями
node scripts/test-relations.js
```

### 4.2. Проверка API
1. Тестирование с помощью Postman или аналогичного инструмента всех эндпоинтов
2. Проверка сценариев аутентификации
3. Проверка CRUD операций для рабочих пространств и карточек

### 4.3. Проверка работы frontend с новым API
1. Запуск приложения с новым бэкендом
2. Проверка всех основных функций:
   - Регистрация и вход
   - Создание рабочих пространств
   - Создание и редактирование карточек
   - Перетаскивание карточек
   - Настройки пользователя

## 5. Развертывание

### 5.1. Запуск в режиме разработки
```bash
# Запуск бэкенда
cd backend
npm run dev

# Запуск фронтенда (в отдельном терминале)
cd frontend
npm start
```

### 5.2. Запуск в продакшн-режиме
```bash
# Сборка фронтенда
cd frontend
npm run build

# Запуск бэкенда
cd backend
NODE_ENV=production npm start
```

### 5.3. Сценарий запуска
Создание скрипта `start_cardflow_postgres.sh` для удобного запуска:
```bash
#!/bin/bash

# Запуск бэкенда
cd "$(dirname "$0")/backend"
echo "Запуск бэкенда с PostgreSQL..."
node src/server.js &
BACKEND_PID=$!

# Небольшая пауза, чтобы бэкенд успел запуститься
sleep 3

# Запуск фронтенда
cd "$(dirname "$0")/frontend"
echo "Запуск фронтенда..."
npm start

# Завершение процессов при выходе
trap "kill $BACKEND_PID" EXIT
```

## 6. Дальнейшие улучшения

### 6.1. Оптимизация производительности
- Создание индексов для часто запрашиваемых полей
- Кэширование запросов к БД
- Оптимизация запросов с помощью Sequelize

### 6.2. Расширение функциональности
- Добавление новых полей в модели при необходимости
- Реализация новых типов связей между моделями
- Добавление сложных запросов с использованием возможностей SQL

### 6.3. Улучшение безопасности
- Внедрение ролевой модели доступа
- Добавление аудита действий пользователей
- Ограничение доступа к API на уровне базы данных

### 6.4. Масштабирование
- Настройка пулов соединений
- Оптимизация использования ресурсов
- Настройка репликации PostgreSQL при необходимости

## 7. Оценка рисков

### 7.1. Потенциальные проблемы
- Различия в форматах данных между MongoDB и PostgreSQL
- Возможная несовместимость с существующим кодом
- Потеря производительности при сложных запросах

### 7.2. Стратегии смягчения рисков
- Подробное тестирование после миграции
- Сохранение резервных копий данных MongoDB
- Возможность временного переключения обратно на MongoDB при критических проблемах
- Постепенное внедрение новой БД с A/B тестированием

## 8. Заключение

Миграция с MongoDB на PostgreSQL обеспечит проекту CardFlow более надежную, структурированную и масштабируемую базу данных. Строгая типизация данных, встроенная поддержка JSON и возможность использования транзакций обеспечат целостность данных и надежность работы приложения в долгосрочной перспективе. Предложенный план миграции минимизирует риски и обеспечивает плавный переход без потери данных и функциональности.
