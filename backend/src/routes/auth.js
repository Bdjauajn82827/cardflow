const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const { User, Workspace } = require('../database/models');
const auth = require('../middleware/auth');
const { logRegistrationError, logSuccessfulRegistration, logDatabaseAction } = require('../utils/logger');

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
      logDatabaseAction('Finding existing user', { email });
      // Check if user already exists
      let existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(400).json({ message: 'User already exists' });
      }

      logDatabaseAction('Creating new user', { email, name });
      // Create new user
      const user = await User.create({
        email,
        password,
        name,
      });

      logDatabaseAction('Creating default workspace', { userId: user.id });
      // Create default workspace
      await Workspace.create({
        userId: user.id,
        name: 'Main',
        order: 0,
      });

      // Generate JWT
      const token = generateToken(user.id);

      // Логируем успешную регистрацию
      logSuccessfulRegistration(user);

      res.status(201).json({
        token,
        user,
      });
    } catch (err) {
      // Расширенное логирование ошибки
      logRegistrationError(err, { email, name });
      
      // Возвращаем более информативное сообщение об ошибке
      res.status(500).json({ 
        message: 'Server error during registration', 
        error: process.env.NODE_ENV === 'production' ? 'See server logs' : err.message,
        details: process.env.NODE_ENV !== 'production' ? {
          name: err.name,
          code: err.code
        } : undefined
      });
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
