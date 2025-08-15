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

# Начало скрипта
print_header "Миграция с MongoDB на PostgreSQL в CardFlow"

# Проверка существующих директорий
PROJECT_DIR=$(pwd)
print_message "Директория проекта: $PROJECT_DIR" "${BLUE}i"

if [ ! -d "$PROJECT_DIR/backend" ] || [ ! -d "$PROJECT_DIR/frontend" ]; then
    print_message "Директория проекта не содержит нужных файлов. Проверьте, что вы находитесь в корне проекта CardFlow." "${RED}✗"
    exit 1
fi

# Установка PostgreSQL
print_header "Установка PostgreSQL и необходимых пакетов"

print_message "Устанавливаем PostgreSQL..." "${YELLOW}!"
sudo apt update
check_result "APT обновлен" "Ошибка при обновлении пакетов" "exit"

sudo apt install -y postgresql postgresql-contrib
check_result "PostgreSQL установлен" "Ошибка при установке PostgreSQL" "exit"

# Проверка статуса PostgreSQL
print_message "Проверяем статус PostgreSQL..." "${YELLOW}!"
sudo systemctl status postgresql | grep "active (running)" > /dev/null
check_result "PostgreSQL запущен" "PostgreSQL не запущен, пытаемся запустить..." 

if [ $? -ne 0 ]; then
    sudo systemctl start postgresql
    check_result "PostgreSQL запущен" "Не удалось запустить PostgreSQL" "exit"
fi

# Создание базы данных и пользователя для CardFlow
print_header "Создание базы данных PostgreSQL для CardFlow"

print_message "Создаем пользователя и базу данных..." "${YELLOW}!"
DB_NAME="cardflow"
DB_USER="cardflow_user"
DB_PASSWORD="cardflow_password_$(date +%s | sha256sum | base64 | head -c 8)"

# Создание пользователя и базы данных
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
check_result "Пользователь PostgreSQL создан" "Ошибка при создании пользователя PostgreSQL"

sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
check_result "База данных PostgreSQL создана" "Ошибка при создании базы данных PostgreSQL"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
check_result "Права предоставлены" "Ошибка при предоставлении прав"

print_message "База данных PostgreSQL успешно настроена" "${GREEN}✓"
print_message "Имя базы данных: $DB_NAME" "${BLUE}i"
print_message "Пользователь: $DB_USER" "${BLUE}i"
print_message "Пароль: $DB_PASSWORD" "${BLUE}i"

# Установка необходимых пакетов Node.js для работы с PostgreSQL
print_header "Установка необходимых пакетов Node.js"

cd "$PROJECT_DIR/backend"
print_message "Устанавливаем sequelize, pg и pg-hstore..." "${YELLOW}!"
npm install --save sequelize pg pg-hstore
check_result "Пакеты для PostgreSQL установлены" "Ошибка при установке пакетов Node.js" "exit"

# Создание директорий для миграции
mkdir -p src/database/models
mkdir -p src/database/config
mkdir -p src/database/migrations

# Создание конфигурационного файла для Sequelize
print_header "Создание файлов конфигурации для Sequelize"

# Создание файла конфигурации
cat > src/database/config/config.js << EOF
require('dotenv').config({ path: '../../.env' });

module.exports = {
  development: {
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST || 'localhost',
    dialect: 'postgres',
    logging: console.log,
  },
  production: {
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST || 'localhost',
    dialect: 'postgres',
    logging: false,
  },
};
EOF

check_result "Файл конфигурации Sequelize создан" "Ошибка при создании файла конфигурации"

# Обновление .env файла
print_message "Обновляем .env файл..." "${YELLOW}!"
if [ -f .env ]; then
    # Создаем бэкап
    cp .env .env.mongodb.backup
    check_result "Создан бэкап .env файла" "Ошибка при создании бэкапа .env файла"
    
    # Получаем значение JWT_SECRET из существующего .env файла
    JWT_SECRET=$(grep "JWT_SECRET" .env | cut -d= -f2)
    JWT_EXPIRES_IN=$(grep "JWT_EXPIRES_IN" .env | cut -d= -f2)
fi

# Если JWT_SECRET не найден, генерируем новый
if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(openssl rand -base64 32)
fi

if [ -z "$JWT_EXPIRES_IN" ]; then
    JWT_EXPIRES_IN="7d"
fi

# Создаем новый .env файл
cat > .env << EOF
PORT=5000
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=localhost
JWT_SECRET=$JWT_SECRET
JWT_EXPIRES_IN=$JWT_EXPIRES_IN
EOF

check_result ".env файл обновлен" "Ошибка при обновлении .env файла"

# Создание моделей для PostgreSQL
print_header "Создание моделей Sequelize"

# Создание модели User
cat > src/database/models/user.js << EOF
'use strict';
const { Model } = require('sequelize');
const bcrypt = require('bcryptjs');

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
EOF

check_result "Модель User создана" "Ошибка при создании модели User"

# Создание модели Workspace
cat > src/database/models/workspace.js << EOF
'use strict';
const { Model } = require('sequelize');

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
EOF

check_result "Модель Workspace создана" "Ошибка при создании модели Workspace"

# Создание модели Card
cat > src/database/models/card.js << EOF
'use strict';
const { Model } = require('sequelize');

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
EOF

check_result "Модель Card создана" "Ошибка при создании модели Card"

# Создание файла для инициализации Sequelize
cat > src/database/models/index.js << EOF
'use strict';

const fs = require('fs');
const path = require('path');
const Sequelize = require('sequelize');
const process = require('process');
const basename = path.basename(__filename);
const env = process.env.NODE_ENV || 'development';
const config = require('../config/config.js')[env];
const db = {};

let sequelize;
if (config.use_env_variable) {
  sequelize = new Sequelize(process.env[config.use_env_variable], config);
} else {
  sequelize = new Sequelize(config.database, config.username, config.password, config);
}

fs
  .readdirSync(__dirname)
  .filter(file => {
    return (
      file.indexOf('.') !== 0 &&
      file !== basename &&
      file.slice(-3) === '.js'
    );
  })
  .forEach(file => {
    const model = require(path.join(__dirname, file))(sequelize, Sequelize.DataTypes);
    db[model.name] = model;
  });

Object.keys(db).forEach(modelName => {
  if (db[modelName].associate) {
    db[modelName].associate(db);
  }
});

db.sequelize = sequelize;
db.Sequelize = Sequelize;

module.exports = db;
EOF

check_result "Файл инициализации Sequelize создан" "Ошибка при создании файла инициализации"

# Обновление серверного файла
print_header "Обновление server.js"

# Создание бэкапа server.js
cp src/server.js src/server.js.mongodb.backup
check_result "Создан бэкап server.js" "Ошибка при создании бэкапа server.js"

# Создание нового server.js для PostgreSQL
cat > src/server.js << EOF
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');

// Импортируем модели Sequelize
const db = require('./database/models');

const authRoutes = require('./routes/auth');
const workspaceRoutes = require('./routes/workspaces');
const cardRoutes = require('./routes/cards');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/workspaces', workspaceRoutes);
app.use('/api/cards', cardRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'CardFlow API is running',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV || 'development',
    database: 'PostgreSQL'
  });
});

// Serve static assets in production
if (process.env.NODE_ENV === 'production') {
  // Set static folder
  app.use(express.static(path.join(__dirname, '../../frontend/build')));

  app.get('*', (req, res, next) => {
    // Make sure API routes work
    if (req.originalUrl.startsWith('/api')) {
      return next();
    }
    res.sendFile(path.resolve(__dirname, '../../frontend/build', 'index.html'));
  });
}

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    message: err.message || 'Internal Server Error',
  });
});

// Синхронизация с базой данных и запуск сервера
db.sequelize.sync({ alter: true })
  .then(() => {
    console.log('Database synchronized');
    app.listen(PORT, () => {
      console.log(\`Server running on port \${PORT}\`);
    });
  })
  .catch((err) => {
    console.error('Failed to synchronize database:', err);
    process.exit(1);
  });
EOF

check_result "server.js обновлен" "Ошибка при обновлении server.js"

# Обновление аутентификационного middleware
print_header "Обновление middleware и routes"

# Создание бэкапа auth middleware
cp src/middleware/auth.js src/middleware/auth.js.mongodb.backup
check_result "Создан бэкап auth middleware" "Ошибка при создании бэкапа auth middleware"

# Обновление auth middleware
cat > src/middleware/auth.js << EOF
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
EOF

check_result "Auth middleware обновлен" "Ошибка при обновлении auth middleware"

# Обновление routes/auth.js
cp src/routes/auth.js src/routes/auth.js.mongodb.backup
check_result "Создан бэкап auth routes" "Ошибка при создании бэкапа auth routes"

cat > src/routes/auth.js << EOF
const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const { User, Workspace } = require('../database/models');
const auth = require('../middleware/auth');

const router = express.Router();

// Helper function to generate JWT
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });
};

// @route   POST /api/auth/register
// @desc    Register user
// @access  Public
router.post(
  '/register',
  [
    body('email').isEmail().withMessage('Please enter a valid email'),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters long')
      .matches(/\d/)
      .withMessage('Password must contain a number')
      .matches(/[a-zA-Z]/)
      .withMessage('Password must contain a letter'),
    body('name').not().isEmpty().withMessage('Name is required'),
    body('confirmPassword').custom((value, { req }) => {
      if (value !== req.body.password) {
        throw new Error('Passwords do not match');
      }
      return true;
    }),
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, name } = req.body;

    try {
      // Check if user already exists
      let existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(400).json({ message: 'User already exists' });
      }

      // Create new user
      const user = await User.create({
        email,
        password,
        name,
      });

      // Create default workspace
      await Workspace.create({
        userId: user.id,
        name: 'Main',
        order: 0,
      });

      // Generate JWT
      const token = generateToken(user.id);

      res.status(201).json({
        token,
        user,
      });
    } catch (err) {
      console.error('Registration error:', err.message);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// @route   POST /api/auth/login
// @desc    Login user and get token
// @access  Public
router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Please enter a valid email'),
    body('password').exists().withMessage('Password is required'),
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;

    try {
      // Find user by email
      const user = await User.findOne({ where: { email } });
      if (!user) {
        return res.status(400).json({ message: 'Invalid credentials' });
      }

      // Compare password
      const isMatch = await user.comparePassword(password);
      if (!isMatch) {
        return res.status(400).json({ message: 'Invalid credentials' });
      }

      // Generate JWT
      const token = generateToken(user.id);

      res.json({
        token,
        user,
      });
    } catch (err) {
      console.error('Login error:', err.message);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// @route   GET /api/auth/profile
// @desc    Get user profile
// @access  Private
router.get('/profile', auth, async (req, res) => {
  try {
    res.json({ user: req.user });
  } catch (err) {
    console.error('Profile error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/auth/settings
// @desc    Update user settings
// @access  Private
router.put(
  '/settings',
  auth,
  [
    body('theme').isIn(['light', 'dark']).withMessage('Theme must be either light or dark'),
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { theme } = req.body;

    try {
      // Update user settings
      req.user.settings = { ...req.user.settings, theme };
      await req.user.save();

      res.json({ user: req.user });
    } catch (err) {
      console.error('Settings update error:', err.message);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

module.exports = router;
EOF

check_result "Auth routes обновлены" "Ошибка при обновлении auth routes"

# Обновление routes/workspaces.js
cp src/routes/workspaces.js src/routes/workspaces.js.mongodb.backup
check_result "Создан бэкап workspaces routes" "Ошибка при создании бэкапа workspaces routes"

cat > src/routes/workspaces.js << EOF
const express = require('express');
const { body, validationResult } = require('express-validator');
const auth = require('../middleware/auth');
const { Workspace, Card } = require('../database/models');

const router = express.Router();

// @route   GET /api/workspaces
// @desc    Get all user workspaces
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const workspaces = await Workspace.findAll({ 
      where: { userId: req.userId },
      order: [['order', 'ASC']]
    });
    res.json(workspaces);
  } catch (err) {
    console.error('Get workspaces error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/workspaces
// @desc    Create a workspace
// @access  Private
router.post(
  '/',
  [auth, body('name').not().isEmpty().withMessage('Name is required')],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { name, order } = req.body;

      // Create workspace
      const workspace = await Workspace.create({
        userId: req.userId,
        name,
        order: order || 0,
      });

      res.status(201).json(workspace);
    } catch (err) {
      console.error('Create workspace error:', err.message);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// @route   PUT /api/workspaces/:id
// @desc    Update a workspace
// @access  Private
router.put(
  '/:id',
  [auth, body('name').not().isEmpty().withMessage('Name is required')],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { name, order } = req.body;

      // Find workspace
      let workspace = await Workspace.findOne({ 
        where: { 
          id: req.params.id,
          userId: req.userId
        }
      });

      if (!workspace) {
        return res.status(404).json({ message: 'Workspace not found' });
      }

      // Update workspace
      workspace.name = name;
      if (order !== undefined) workspace.order = order;
      await workspace.save();

      res.json(workspace);
    } catch (err) {
      console.error('Update workspace error:', err.message);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// @route   DELETE /api/workspaces/:id
// @desc    Delete a workspace
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    // Find workspace
    const workspace = await Workspace.findOne({ 
      where: { 
        id: req.params.id,
        userId: req.userId
      }
    });

    if (!workspace) {
      return res.status(404).json({ message: 'Workspace not found' });
    }

    // Delete workspace (this will also delete all cards due to cascade)
    await workspace.destroy();

    res.json({ message: 'Workspace deleted' });
  } catch (err) {
    console.error('Delete workspace error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/workspaces/:id/cards
// @desc    Get all cards in a workspace
// @access  Private
router.get('/:id/cards', auth, async (req, res) => {
  try {
    // Find workspace
    const workspace = await Workspace.findOne({ 
      where: { 
        id: req.params.id,
        userId: req.userId
      }
    });

    if (!workspace) {
      return res.status(404).json({ message: 'Workspace not found' });
    }

    // Get cards
    const cards = await Card.findAll({ 
      where: { workspaceId: req.params.id }
    });

    res.json(cards);
  } catch (err) {
    console.error('Get cards error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
EOF

check_result "Workspaces routes обновлены" "Ошибка при обновлении workspaces routes"

# Обновление routes/cards.js
cp src/routes/cards.js src/routes/cards.js.mongodb.backup
check_result "Создан бэкап cards routes" "Ошибка при создании бэкапа cards routes"

cat > src/routes/cards.js << EOF
const express = require('express');
const { body, validationResult } = require('express-validator');
const auth = require('../middleware/auth');
const { Card, Workspace } = require('../database/models');

const router = express.Router();

// @route   GET /api/cards
// @desc    Get all user cards
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const cards = await Card.findAll({ 
      where: { userId: req.userId } 
    });
    res.json(cards);
  } catch (err) {
    console.error('Get cards error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/cards/:id
// @desc    Get a card by ID
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const card = await Card.findOne({ 
      where: { 
        id: req.params.id,
        userId: req.userId
      }
    });

    if (!card) {
      return res.status(404).json({ message: 'Card not found' });
    }

    res.json(card);
  } catch (err) {
    console.error('Get card error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/cards
// @desc    Create a card
// @access  Private
router.post(
  '/',
  [
    auth,
    body('title').not().isEmpty().withMessage('Title is required'),
    body('description').not().isEmpty().withMessage('Description is required'),
    body('workspaceId').not().isEmpty().withMessage('Workspace ID is required'),
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const {
        title,
        titleColor,
        description,
        descriptionColor,
        content,
        backgroundColor,
        position,
        workspaceId,
      } = req.body;

      // Verify workspace exists and belongs to the user
      const workspace = await Workspace.findOne({ 
        where: { 
          id: workspaceId,
          userId: req.userId
        }
      });

      if (!workspace) {
        return res.status(404).json({ message: 'Workspace not found' });
      }

      // Create card
      const card = await Card.create({
        title,
        titleColor: titleColor || '#FFFFFF',
        description,
        descriptionColor: descriptionColor || '#FFFFFF',
        content: content || '',
        backgroundColor: backgroundColor || '#3F51B5',
        position: position || { x: 0, y: 0 },
        workspaceId,
        userId: req.userId,
      });

      res.status(201).json(card);
    } catch (err) {
      console.error('Create card error:', err.message);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// @route   PUT /api/cards/:id
// @desc    Update a card
// @access  Private
router.put(
  '/:id',
  [
    auth,
    body('title').not().isEmpty().withMessage('Title is required'),
    body('description').not().isEmpty().withMessage('Description is required'),
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const {
        title,
        titleColor,
        description,
        descriptionColor,
        content,
        backgroundColor,
      } = req.body;

      // Find card
      const card = await Card.findOne({ 
        where: { 
          id: req.params.id,
          userId: req.userId
        }
      });

      if (!card) {
        return res.status(404).json({ message: 'Card not found' });
      }

      // Update card
      card.title = title;
      if (titleColor) card.titleColor = titleColor;
      card.description = description;
      if (descriptionColor) card.descriptionColor = descriptionColor;
      if (content !== undefined) card.content = content;
      if (backgroundColor) card.backgroundColor = backgroundColor;
      
      await card.save();

      res.json(card);
    } catch (err) {
      console.error('Update card error:', err.message);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// @route   PUT /api/cards/:id/position
// @desc    Update a card's position
// @access  Private
router.put('/:id/position', auth, async (req, res) => {
  try {
    const { position } = req.body;

    // Find card
    const card = await Card.findOne({ 
      where: { 
        id: req.params.id,
        userId: req.userId
      }
    });

    if (!card) {
      return res.status(404).json({ message: 'Card not found' });
    }

    // Update card position
    card.position = position;
    await card.save();

    res.json(card);
  } catch (err) {
    console.error('Update card position error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   DELETE /api/cards/:id
// @desc    Delete a card
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    // Find card
    const card = await Card.findOne({ 
      where: { 
        id: req.params.id,
        userId: req.userId
      }
    });

    if (!card) {
      return res.status(404).json({ message: 'Card not found' });
    }

    // Delete card
    await card.destroy();

    res.json({ message: 'Card deleted' });
  } catch (err) {
    console.error('Delete card error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
EOF

check_result "Cards routes обновлены" "Ошибка при обновлении cards routes"

# Создание скрипта запуска
print_header "Создание скрипта запуска"

cd "$PROJECT_DIR"
cat > start_cardflow_postgres.sh << EOF
#!/bin/bash

# Запуск бэкенда
cd "\$(dirname "\$0")/backend"
echo "Запуск бэкенда с PostgreSQL..."
node src/server.js &
BACKEND_PID=\$!

# Небольшая пауза, чтобы бэкенд успел запуститься
sleep 3

# Запуск фронтенда
cd "\$(dirname "\$0")/frontend"
echo "Запуск фронтенда..."
npm start

# Завершение процессов при выходе
trap "kill \$BACKEND_PID" EXIT
EOF

chmod +x start_cardflow_postgres.sh
check_result "Скрипт запуска создан" "Ошибка при создании скрипта запуска"

print_header "Миграция на PostgreSQL успешно завершена!"
print_message "Теперь вы можете запустить приложение с PostgreSQL вместо MongoDB:" "${GREEN}✓"
print_message "./start_cardflow_postgres.sh" "${BLUE}i"
print_message "Данные базы данных PostgreSQL:" "${BLUE}i"
print_message "Имя базы данных: $DB_NAME" "${BLUE}i"
print_message "Пользователь: $DB_USER" "${BLUE}i"
print_message "Пароль: $DB_PASSWORD" "${BLUE}i"
print_message "Все настройки сохранены в .env файле бэкенда" "${BLUE}i"
print_message "Бэкапы старых файлов сохранены с расширением .mongodb.backup" "${BLUE}i"
