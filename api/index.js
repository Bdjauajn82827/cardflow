// Точка входа для Vercel Serverless Functions
const app = require('../backend/src/index');

// Экспортируем обработчик для Vercel
module.exports = app;
