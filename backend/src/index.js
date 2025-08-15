// index.js для деплоя на Vercel
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

// Обработчик 404
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    message: err.message || 'Internal Server Error',
  });
});

// Для локальной разработки
if (process.env.NODE_ENV !== 'production') {
  const PORT = process.env.PORT || 5000;
  
  // Синхронизация с базой данных и запуск сервера
  db.sequelize.sync({ alter: true })
    .then(() => {
      console.log('Database synchronized');
      app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
      });
    })
    .catch((err) => {
      console.error('Failed to synchronize database:', err);
      process.exit(1);
    });
} else {
  // В продакшене не запускаем сервер, а просто экспортируем app для Vercel
  // Но синхронизацию с базой данных всё равно делаем для корректной работы
  db.sequelize.sync({ alter: false })
    .then(() => {
      console.log('Database synchronized in serverless mode');
    })
    .catch((err) => {
      console.error('Failed to synchronize database in serverless mode:', err);
    });
}

// Экспортируем приложение для Vercel serverless function
module.exports = app;
