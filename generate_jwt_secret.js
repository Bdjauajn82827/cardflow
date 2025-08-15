#!/usr/bin/env node

// Скрипт для генерации случайного JWT-секрета
const crypto = require('crypto');
const jwtSecret = crypto.randomBytes(64).toString('hex');

console.log('Случайный JWT-секрет для использования в переменных окружения:');
console.log(jwtSecret);
