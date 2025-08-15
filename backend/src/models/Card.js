'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class Card extends Model {
    static associate(models) {
      Card.belongsTo(models.Workspace, { foreignKey: 'workspaceId' });
      Card.belongsTo(models.User, { foreignKey: 'userId' });
    }
  }
  
  Card.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    workspaceId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'Workspaces',
        key: 'id',
      },
      onDelete: 'CASCADE',
    },
    userId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'Users',
        key: 'id',
      },
    },
    title: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    titleColor: {
      type: DataTypes.STRING,
      defaultValue: '#FFFFFF',
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    descriptionColor: {
      type: DataTypes.STRING,
      defaultValue: '#FFFFFF',
    },
    content: {
      type: DataTypes.TEXT,
      defaultValue: '',
    },
    backgroundColor: {
      type: DataTypes.STRING,
      defaultValue: '#3F51B5',
    },
    position: {
      type: DataTypes.JSONB,
      defaultValue: { x: 0, y: 0 },
    },
  }, {
    sequelize,
    modelName: 'Card',
  });
  
  return Card;
};
