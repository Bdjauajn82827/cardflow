const express = require('express');
const { body, validationResult } = require('express-validator');
const { Workspace, Card } = require('../database/models');
const auth = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/workspaces
// @desc    Get all workspaces for a user
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const workspaces = await Workspace.findAll({ 
      where: { userId: req.userId },
      order: [['order', 'ASC']]
    });
    res.json({ workspaces });
  } catch (err) {
    console.error('Get workspaces error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/workspaces/:id
// @desc    Get a specific workspace
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const workspace = await Workspace.findOne({
      where: {
        id: req.params.id,
        userId: req.userId,
      }
    });

    if (!workspace) {
      return res.status(404).json({ message: 'Workspace not found' });
    }

    res.json({ workspace });
  } catch (err) {
    console.error('Get workspace error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/workspaces
// @desc    Create a new workspace
// @access  Private
router.post(
  '/',
  auth,
  [
    body('name').not().isEmpty().withMessage('Name is required'),
    body('order').isNumeric().withMessage('Order must be a number'),
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, order } = req.body;

    try {
      // Check if maximum number of workspaces is reached (7)
      const workspaceCount = await Workspace.count({ where: { userId: req.userId } });
      if (workspaceCount >= 7) {
        return res.status(400).json({ message: 'Maximum number of workspaces reached (7)' });
      }

      // Create new workspace
      const workspace = await Workspace.create({
        userId: req.userId,
        name,
        order,
      });

      res.status(201).json({ workspace });
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
  auth,
  [
    body('name').optional().not().isEmpty().withMessage('Name cannot be empty'),
    body('order').optional().isNumeric().withMessage('Order must be a number'),
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const updates = {};
    if (req.body.name !== undefined) updates.name = req.body.name;
    if (req.body.order !== undefined) updates.order = req.body.order;

    try {
      // Find and update workspace
      const workspace = await Workspace.findOne({
        where: { 
          id: req.params.id,
          userId: req.userId
        }
      });

      if (!workspace) {
        return res.status(404).json({ message: 'Workspace not found' });
      }
      
      // Update workspace properties
      if (req.body.name !== undefined) workspace.name = req.body.name;
      if (req.body.order !== undefined) workspace.order = req.body.order;
      
      await workspace.save();

      res.json({ workspace });
    } catch (err) {
      console.error('Update workspace error:', err.message);
      
      // Check if error is due to invalid ID format
      if (err instanceof mongoose.Error.CastError) {
        return res.status(400).json({ message: 'Invalid workspace ID' });
      }
      
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// @route   DELETE /api/workspaces/:id
// @desc    Delete a workspace
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    // Check if this is the main workspace (order 0)
    const workspace = await Workspace.findOne({
      where: {
        id: req.params.id,
        userId: req.userId,
      }
    });

    if (!workspace) {
      return res.status(404).json({ message: 'Workspace not found' });
    }

    if (workspace.order === 0) {
      return res.status(400).json({ message: 'Cannot delete main workspace' });
    }

    // Sequelize will automatically delete all cards due to CASCADE
    await workspace.destroy();

    res.json({ message: 'Workspace deleted' });
  } catch (err) {
    console.error('Delete workspace error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
