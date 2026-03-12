'use strict';

const { Order, OrderItem, Cart, CartItem, Product } = require('../models');
const { sequelize } = require('../models');

// POST /api/orders/create
const createOrder = async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const { notes } = req.body;

    // Get cart with items
    const cart = await Cart.findOne({
      where: { user_id: req.user.id },
      include: [
        {
          model: CartItem,
          as: 'items',
          include: [{ model: Product, as: 'product' }],
        },
      ],
      transaction: t,
    });

    if (!cart || !cart.items || cart.items.length === 0) {
      await t.rollback();
      return res.status(400).json({ success: false, message: 'Cart is empty.' });
    }

    // Calculate total
    let total = 0;
    const orderItemsData = [];
    for (const item of cart.items) {
      if (!item.product.is_available) {
        await t.rollback();
        return res.status(400).json({
          success: false,
          message: `Product "${item.product.name}" is no longer available.`,
        });
      }
      const subtotal = parseFloat(item.product.price) * item.quantity;
      total += subtotal;
      orderItemsData.push({
        product_id: item.product_id,
        quantity: item.quantity,
        price: parseFloat(item.product.price),
      });
    }

    // Create order
    const order = await Order.create(
      { user_id: req.user.id, total_price: total.toFixed(2), status: 'pending', notes },
      { transaction: t }
    );

    // Create order items
    const orderItems = orderItemsData.map((item) => ({ ...item, order_id: order.id }));
    await OrderItem.bulkCreate(orderItems, { transaction: t });

    // Clear cart
    await CartItem.destroy({ where: { cart_id: cart.id }, transaction: t });

    await t.commit();

    // Fetch full order details
    const fullOrder = await Order.findByPk(order.id, {
      include: [{ model: OrderItem, as: 'items', include: [{ model: Product, as: 'product' }] }],
    });

    return res.status(201).json({ success: true, message: 'Order placed successfully.', data: fullOrder });
  } catch (error) {
    await t.rollback();
    console.error('Create order error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// GET /api/orders
const getOrders = async (req, res) => {
  try {
    const orders = await Order.findAll({
      where: { user_id: req.user.id },
      include: [
        {
          model: OrderItem,
          as: 'items',
          include: [{ model: Product, as: 'product' }],
        },
      ],
      order: [['created_at', 'DESC']],
    });

    return res.status(200).json({ success: true, data: orders });
  } catch (error) {
    console.error('Get orders error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// GET /api/orders/:id
const getOrderById = async (req, res) => {
  try {
    const order = await Order.findOne({
      where: { id: req.params.id, user_id: req.user.id },
      include: [{ model: OrderItem, as: 'items', include: [{ model: Product, as: 'product' }] }],
    });

    if (!order) return res.status(404).json({ success: false, message: 'Order not found.' });

    return res.status(200).json({ success: true, data: order });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

module.exports = { createOrder, getOrders, getOrderById };
