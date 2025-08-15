// Расширенное логирование для отладки проблем регистрации
const winston = require('winston');

// Создаем логгер
const logger = winston.createLogger({
  level: 'debug',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

/**
 * Расширенное логирование ошибок регистрации
 * @param {Error} error - Объект ошибки
 * @param {Object} userData - Данные пользователя (без пароля)
 */
exports.logRegistrationError = (error, userData = {}) => {
  // Удаляем чувствительные данные
  const safeUserData = { ...userData };
  delete safeUserData.password;
  delete safeUserData.confirmPassword;
  
  logger.error('Registration Error:', { 
    message: error.message,
    stack: error.stack,
    code: error.code,
    name: error.name,
    userData: safeUserData
  });
};

/**
 * Логирование успешной регистрации
 * @param {Object} user - Созданный пользователь (без пароля)
 */
exports.logSuccessfulRegistration = (user) => {
  const safeUser = { ...user.toJSON() };
  logger.info('User registered successfully:', { 
    userId: safeUser.id,
    email: safeUser.email 
  });
};

/**
 * Логирование запроса к базе данных
 * @param {string} action - Действие
 * @param {Object} details - Детали запроса
 */
exports.logDatabaseAction = (action, details = {}) => {
  logger.debug(`Database Action: ${action}`, details);
};
