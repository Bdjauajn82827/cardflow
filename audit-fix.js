#!/usr/bin/env node

/**
 * Скрипт для автоматического исправления уязвимостей в зависимостях проекта
 */
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Цвета для консоли
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
};

console.log(`${colors.bright}${colors.cyan}=== Начинаем исправление уязвимостей в зависимостях ===${colors.reset}\n`);

// Исправляем уязвимости в корневом проекте
try {
  console.log(`${colors.yellow}Исправление уязвимостей в корневом пакете...${colors.reset}`);
  execSync('npm audit fix', { stdio: 'inherit' });
  console.log(`${colors.green}✓ Завершено${colors.reset}\n`);
} catch (error) {
  console.error(`${colors.red}Ошибка при исправлении уязвимостей в корневом пакете: ${error.message}${colors.reset}\n`);
}

// Исправляем уязвимости во фронтенде
try {
  console.log(`${colors.yellow}Исправление уязвимостей во фронтенде...${colors.reset}`);
  process.chdir('./frontend');
  execSync('npm audit fix', { stdio: 'inherit' });
  console.log(`${colors.green}✓ Завершено${colors.reset}\n`);
  process.chdir('..');
} catch (error) {
  console.error(`${colors.red}Ошибка при исправлении уязвимостей во фронтенде: ${error.message}${colors.reset}\n`);
  process.chdir('..');
}

// Исправляем уязвимости в бэкенде
try {
  console.log(`${colors.yellow}Исправление уязвимостей в бэкенде...${colors.reset}`);
  process.chdir('./backend');
  execSync('npm audit fix', { stdio: 'inherit' });
  console.log(`${colors.green}✓ Завершено${colors.reset}\n`);
  process.chdir('..');
} catch (error) {
  console.error(`${colors.red}Ошибка при исправлении уязвимостей в бэкенде: ${error.message}${colors.reset}\n`);
  process.chdir('..');
}

console.log(`${colors.bright}${colors.green}=== Исправление уязвимостей завершено ===${colors.reset}`);
