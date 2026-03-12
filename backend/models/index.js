'use strict';

const { Sequelize } = require('sequelize');
require('dotenv').config();

const sequelize = new Sequelize(
  process.env.DB_NAME || 'food_mess_db',
  process.env.DB_USER || 'postgres',
  process.env.DB_PASSWORD || 'password',
  {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    dialect: 'postgres',
    logging: false,
  }
);

const db = {};
db.Sequelize = Sequelize;
db.sequelize = sequelize;

db.User = require('./User')(sequelize, Sequelize.DataTypes);
db.Product = require('./Product')(sequelize, Sequelize.DataTypes);
db.Cart = require('./Cart')(sequelize, Sequelize.DataTypes);
db.CartItem = require('./CartItem')(sequelize, Sequelize.DataTypes);
db.Order = require('./Order')(sequelize, Sequelize.DataTypes);
db.OrderItem = require('./OrderItem')(sequelize, Sequelize.DataTypes);

// Associations
db.User.hasOne(db.Cart, { foreignKey: 'user_id', as: 'cart' });
db.Cart.belongsTo(db.User, { foreignKey: 'user_id', as: 'user' });

db.Cart.hasMany(db.CartItem, { foreignKey: 'cart_id', as: 'items' });
db.CartItem.belongsTo(db.Cart, { foreignKey: 'cart_id', as: 'cart' });

db.Product.hasMany(db.CartItem, { foreignKey: 'product_id', as: 'cartItems' });
db.CartItem.belongsTo(db.Product, { foreignKey: 'product_id', as: 'product' });

db.User.hasMany(db.Order, { foreignKey: 'user_id', as: 'orders' });
db.Order.belongsTo(db.User, { foreignKey: 'user_id', as: 'user' });

db.Order.hasMany(db.OrderItem, { foreignKey: 'order_id', as: 'items' });
db.OrderItem.belongsTo(db.Order, { foreignKey: 'order_id', as: 'order' });

db.Product.hasMany(db.OrderItem, { foreignKey: 'product_id', as: 'orderItems' });
db.OrderItem.belongsTo(db.Product, { foreignKey: 'product_id', as: 'product' });

module.exports = db;
