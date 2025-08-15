const express = require('express');
const { body, validationResult } = require('express-validator');
const { Card, Workspace, sequelize } = require('../database/models');
const auth = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/cards/workspace/:workspaceId
// @desc    Get all cards for a workspace
// @access  Private
router.get('/workspace/:workspaceId', auth, async (req, res) => {
  try {
    // Check if workspace exists and belongs to user
    const workspace = await Workspace.findOne({
      where: {
        id: req.params.workspaceId,
        userId: req.userId,
      }
    });

    if (!workspace) {
      return res.status(404).json({ message: 'Workspace not found' });
    }

    // Get cards
    const cards = await Card.findAll({
      where: {
        workspaceId: req.params.workspaceId,
        userId: req.userId,
      },
      order: [
        [sequelize.json('position.y'), 'ASC'],
        [sequelize.json('position.x'), 'ASC']
      ]
    });

    res.json({ cards });
  } catch (err) {
    console.error('Get cards error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/cards/:id
// @desc    Get a specific card
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const card = await Card.findOne({
      where: {
        id: req.params.id,
        userId: req.userId,
      }
    });

    if (!card) {
      return res.status(404).json({ message: 'Card not found' });
    }

    res.json({ card });
  } catch (err) {
    console.error('Get card error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/cards
// @desc    Create a new card
// @access  Private
router.post(
  '/',
  auth,
  [
    body('workspaceId').not().isEmpty().withMessage('Workspace ID is required'),
    body('title').not().isEmpty().withMessage('Title is required'),
    body('description').not().isEmpty().withMessage('Description is required'),
    body('backgroundColor').optional().isHexColor().withMessage('Background color must be a valid hex color'),
    body('titleColor').optional().isHexColor().withMessage('Title color must be a valid hex color'),
    body('descriptionColor').optional().isHexColor().withMessage('Description color must be a valid hex color'),
    body('content').optional(),
    body('position').optional().isObject().withMessage('Position must be an object'),
    body('position.x').optional().isNumeric().withMessage('Position X must be a number'),
    body('position.y').optional().isNumeric().withMessage('Position Y must be a number'),
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      workspaceId,
      title,
      titleColor,
      description,
      descriptionColor,
      content,
      backgroundColor,
      position,
    } = req.body;

    try {
      // Check if workspace exists and belongs to user
      const workspace = await Workspace.findOne({
        where: {
          id: workspaceId,
          userId: req.userId,
        }
      });

      if (!workspace) {
        return res.status(404).json({ message: 'Workspace not found' });
      }

      // Create new card
      const card = await Card.create({
        workspaceId,
        userId: req.userId,
        title,
        titleColor: titleColor || '#FFFFFF',
        description,
        descriptionColor: descriptionColor || '#FFFFFF',
        content: content || '',
        backgroundColor: backgroundColor || '#3F51B5',
        position: position || { x: 0, y: 0 },
      });

      res.status(201).json({ card });
    } catch (err) {
      console.error('Create card error:', err.message);
      
      // Check if error is related to foreign key constraint
      if (err.name === 'SequelizeForeignKeyConstraintError') {
        return res.status(400).json({ message: 'Invalid workspace ID' });
      }
      
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// @route   PUT /api/cards/:id
// @desc    Update a card
// @access  Private
router.put(
  '/:id',
  auth,
  [
    body('title').optional().not().isEmpty().withMessage('Title cannot be empty'),
    body('description').optional().not().isEmpty().withMessage('Description cannot be empty'),
    body('backgroundColor').optional().isHexColor().withMessage('Background color must be a valid hex color'),
    body('titleColor').optional().isHexColor().withMessage('Title color must be a valid hex color'),
    body('descriptionColor').optional().isHexColor().withMessage('Description color must be a valid hex color'),
    body('content').optional(),
    body('position').optional().isObject().withMessage('Position must be an object'),
    body('position.x').optional().isNumeric().withMessage('Position X must be a number'),
    body('position.y').optional().isNumeric().withMessage('Position Y must be a number'),
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const updates = {};
    if (req.body.title !== undefined) updates.title = req.body.title;
    if (req.body.titleColor !== undefined) updates.titleColor = req.body.titleColor;
    if (req.body.description !== undefined) updates.description = req.body.description;
    if (req.body.descriptionColor !== undefined) updates.descriptionColor = req.body.descriptionColor;
    if (req.body.content !== undefined) updates.content = req.body.content;
    if (req.body.backgroundColor !== undefined) updates.backgroundColor = req.body.backgroundColor;
    if (req.body.position !== undefined) updates.position = req.body.position;

    try {
      // Find and update card
      const card = await Card.findOne({
        where: {
          id: req.params.id,
          userId: req.userId
        }
      });

      if (!card) {
        return res.status(404).json({ message: 'Card not found' });
      }
      
      // Update card properties
      if (req.body.title !== undefined) card.title = req.body.title;
      if (req.body.titleColor !== undefined) card.titleColor = req.body.titleColor;
      if (req.body.description !== undefined) card.description = req.body.description;
      if (req.body.descriptionColor !== undefined) card.descriptionColor = req.body.descriptionColor;
      if (req.body.content !== undefined) card.content = req.body.content;
      if (req.body.backgroundColor !== undefined) card.backgroundColor = req.body.backgroundColor;
      if (req.body.position !== undefined) card.position = req.body.position;
      
      await card.save();

      res.json({ card });
    } catch (err) {
      console.error('Update card error:', err.message);
      
      // Check if error is related to foreign key constraint
      if (err.name === 'SequelizeForeignKeyConstraintError') {
        return res.status(400).json({ message: 'Invalid card ID' });
      }
      
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// @route   PATCH /api/cards/:id/position
// @desc    Update card position
// @access  Private
router.patch(
  '/:id/position',
  auth,
  [
    body('position').isObject().withMessage('Position must be an object'),
    body('position.x').isNumeric().withMessage('Position X must be a number'),
    body('position.y').isNumeric().withMessage('Position Y must be a number'),
  ],
  async (req, res) => {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { position } = req.body;

    try {
      // Find and update card
      const card = await Card.findOne({
        where: {
          id: req.params.id,
          userId: req.userId
        }
      });

      if (!card) {
        return res.status(404).json({ message: 'Card not found' });
      }
      
      // Update position
      card.position = position;
      await card.save();

      res.json({ card });
    } catch (err) {
      console.error('Update card position error:', err.message);
      
      // Check if error is related to foreign key constraint
      if (err.name === 'SequelizeForeignKeyConstraintError') {
        return res.status(400).json({ message: 'Invalid card ID' });
      }
      
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// @route   DELETE /api/cards/:id
// @desc    Delete a card
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    // Find and delete card
    const card = await Card.findOne({
      where: {
        id: req.params.id,
        userId: req.userId,
      }
    });

    if (!card) {
      return res.status(404).json({ message: 'Card not found' });
    }
    
    await card.destroy();

    res.json({ message: 'Card deleted' });
  } catch (err) {
    console.error('Delete card error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
