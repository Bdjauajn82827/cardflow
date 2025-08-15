// Точка входа для Vercel Serverless Functions
const express = require('express');
const app = require('../backend/src/index');

// Для обработки serverless функций в Vercel
module.exports = (req, res) => {
  // Указываем, что это обработчик express
  return app(req, res);
};
