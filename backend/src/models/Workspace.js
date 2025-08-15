const mongoose = require('mongoose');

const workspaceSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    order: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// Create index for faster queries
workspaceSchema.index({ userId: 1, order: 1 });

const Workspace = mongoose.model('Workspace', workspaceSchema);

module.exports = Workspace;
