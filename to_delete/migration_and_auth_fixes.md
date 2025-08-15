# Документация по миграции с MongoDB на PostgreSQL и исправлению авторизации

## 1. Причины миграции с MongoDB на PostgreSQL

### 1.1 Проблемы совместимости
- Проблемы совместимости MongoDB с Debian Bookworm
- Ошибки в работе MongoDB на новых версиях Linux

### 1.2 Преимущества PostgreSQL
- Надежная ACID-совместимая СУБД
- Строгая типизация данных
- Развитые возможности для обеспечения целостности данных
- Поддержка сложных запросов и транзакций

## 2. Изменения в бэкенде

### 2.1 Замена ORM
- Переход с Mongoose (MongoDB) на Sequelize (PostgreSQL)
- Обновление моделей данных для работы с SQL-базой

### 2.2 Модель пользователя (User)

```javascript
const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  registrationDate: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  settings: {
    type: DataTypes.JSON,
    defaultValue: {
      theme: 'light'
    }
  }
});
```

### 2.3 Модель рабочего пространства (Workspace)

```javascript
const Workspace = sequelize.define('Workspace', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  order: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  }
});
```

### 2.4 Модель карточки (Card)

```javascript
const Card = sequelize.define('Card', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false
  },
  titleColor: {
    type: DataTypes.STRING,
    defaultValue: '#000000'
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  descriptionColor: {
    type: DataTypes.STRING,
    defaultValue: '#000000'
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  backgroundColor: {
    type: DataTypes.STRING,
    defaultValue: '#ffffff'
  },
  position: {
    type: DataTypes.JSON,
    defaultValue: {
      x: 0,
      y: 0
    }
  }
});
```

### 2.5 Связи между моделями

```javascript
User.hasMany(Workspace, { foreignKey: 'userId', as: 'workspaces' });
Workspace.belongsTo(User, { foreignKey: 'userId' });

User.hasMany(Card, { foreignKey: 'userId', as: 'cards' });
Card.belongsTo(User, { foreignKey: 'userId' });

Workspace.hasMany(Card, { foreignKey: 'workspaceId', as: 'cards' });
Card.belongsTo(Workspace, { foreignKey: 'workspaceId' });
```

### 2.6 Обновление API-запросов в контроллерах

Замена MongoDB-запросов на Sequelize:

**Пример MongoDB (до):**
```javascript
const user = await User.findOne({ email });
```

**Пример Sequelize (после):**
```javascript
const user = await User.findOne({ where: { email } });
```

## 3. Исправление системы авторизации

### 3.1 Проблема с сессиями
- При обновлении страницы сессия не сохранялась
- Флажок "Запомнить меня" не обеспечивал правильного сохранения сессии

### 3.2 Внесенные изменения

#### 3.2.1 Удаление чекбокса "Запомнить меня"
- Удалён чекбокс из формы авторизации
- Все сессии сохраняются в localStorage для постоянной авторизации

#### 3.2.2 Обновление функции авторизации в `api.ts`

```typescript
export const authService = {
  login: async (credentials: LoginCredentials): Promise<AuthResponse> => {
    const response = await api.post<AuthResponse>('/auth/login', credentials);
    // Всегда сохраняем токен в localStorage для постоянной аутентификации
    localStorage.setItem('token', response.data.token);
    return response.data;
  },
  
  logout: (): void => {
    localStorage.removeItem('token');
  },
  
  // Остальные методы...
};
```

#### 3.2.3 Обновление проверки токена в `App.tsx`

```typescript
useEffect(() => {
  // Проверка аутентификации пользователя
  const checkAuth = async () => {
    try {
      const token = localStorage.getItem('token');
      if (token) {
        // Проверка токена путем получения профиля пользователя
        const user = await authService.getProfile();
        dispatch(loginSuccess({ user }));
      }
    } catch (error) {
      // Токен недействителен, он будет удален перехватчиком
      console.error("Authentication error:", error);
    } finally {
      setIsLoading(false);
    }
  };
  
  checkAuth();
}, [dispatch]);
```

#### 3.2.4 Обновление модели LoginCredentials

```typescript
export interface LoginCredentials {
  email: string;
  password: string;
}
```

### 3.3 Процесс аутентификации после изменений

1. Пользователь вводит email и пароль на странице авторизации
2. После успешной аутентификации сервер возвращает JWT токен
3. Токен сохраняется в localStorage браузера
4. При каждой загрузке приложения проверяется наличие токена в localStorage
5. Если токен найден, выполняется запрос к API для проверки его действительности
6. При успешной проверке токена пользователь автоматически авторизуется
7. Токен удаляется только при явном выходе из системы или при его недействительности

## 4. Преимущества новой реализации

### 4.1 База данных
- Повышенная надежность и стабильность системы
- Возможность использования транзакций для операций с данными
- Строгая типизация данных для предотвращения ошибок
- Лучшая масштабируемость при росте объема данных

### 4.2 Аутентификация
- Более стабильное сохранение сессии пользователя
- Отсутствие необходимости повторно входить в систему при обновлении страницы
- Более понятный для пользователя процесс аутентификации
- Соответствие современным практикам разработки веб-приложений

## 5. Дополнительные улучшения

### 5.1 Обработка ошибок
- Добавлена улучшенная обработка ошибок аутентификации
- Автоматическая перенаправление на страницу авторизации при истечении токена

### 5.2 Безопасность
- Проверка токена на сервере при каждом защищенном запросе
- Корректная очистка данных аутентификации при выходе из системы
