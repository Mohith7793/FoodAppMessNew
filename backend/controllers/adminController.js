'use strict';

const bcrypt = require('bcryptjs');
const { User, Product, Order, OrderItem, Cart } = require('../models');
const { Op } = require('sequelize');

// ── STAFF MANAGEMENT ─────────────────────────────────────────────────────────

// POST /api/admin/staff  — admin creates staff credentials
const createStaff = async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Name, email, and password are required.' });
    }
    if (password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters.' });
    }
    const existing = await User.findOne({ where: { email } });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Email already registered.' });
    }
    const hashedPassword = await bcrypt.hash(password, 12);
    const staff = await User.create({ name, email, password: hashedPassword, role: 'staff', is_active: true, email_verified: true });
    return res.status(201).json({
      success: true,
      message: 'Staff member created.',
      data: { id: staff.id, name: staff.name, email: staff.email, role: staff.role, is_active: staff.is_active, created_at: staff.created_at },
    });
  } catch (error) {
    console.error('Create staff error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// GET /api/admin/staff  — list all staff
const getStaff = async (req, res) => {
  try {
    const staff = await User.findAll({
      where: { role: 'staff' },
      attributes: { exclude: ['password'] },
      order: [['created_at', 'DESC']],
    });
    return res.status(200).json({ success: true, data: staff });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// PUT /api/admin/staff/:id/toggle  — toggle staff active/inactive
const toggleStaff = async (req, res) => {
  try {
    const staff = await User.findOne({ where: { id: req.params.id, role: 'staff' } });
    if (!staff) return res.status(404).json({ success: false, message: 'Staff member not found.' });
    await staff.update({ is_active: !staff.is_active });
    return res.status(200).json({
      success: true,
      message: `Staff member ${staff.is_active ? 'activated' : 'deactivated'}.`,
      data: { id: staff.id, name: staff.name, is_active: staff.is_active },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// PUT /api/admin/staff/:id  — update staff info / reset password
const updateStaff = async (req, res) => {
  try {
    const staff = await User.findOne({ where: { id: req.params.id, role: 'staff' } });
    if (!staff) return res.status(404).json({ success: false, message: 'Staff member not found.' });
    const updates = {};
    if (req.body.name) updates.name = req.body.name;
    if (req.body.password) updates.password = await bcrypt.hash(req.body.password, 12);
    await staff.update(updates);
    return res.status(200).json({ success: true, message: 'Staff updated.', data: { id: staff.id, name: staff.name, email: staff.email } });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// DELETE /api/admin/staff/:id  — remove staff member
const deleteStaff = async (req, res) => {
  try {
    const staff = await User.findOne({ where: { id: req.params.id, role: 'staff' } });
    if (!staff) return res.status(404).json({ success: false, message: 'Staff member not found.' });
    await staff.destroy();
    return res.status(200).json({ success: true, message: 'Staff member removed.' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// ── DASHBOARD ─────────────────────────────────────────────────────────────────

// GET /api/admin/dashboard
const getDashboard = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      totalOrders,
      totalRevenue,
      totalCustomers,
      pendingOrders,
      todayOrdersCount,
      todayRevenue,
      activeStaff,
      inactiveStaff,
      recentOrders,
    ] = await Promise.all([
      Order.count(),
      Order.sum('total_price'),
      User.count({ where: { role: 'customer' } }),
      Order.count({ where: { status: 'pending' } }),
      Order.count({ where: { created_at: { [Op.gte]: today } } }),
      Order.sum('total_price', { where: { created_at: { [Op.gte]: today } } }),
      User.count({ where: { role: 'staff', is_active: true } }),
      User.count({ where: { role: 'staff', is_active: false } }),
      Order.findAll({
        limit: 5,
        order: [['created_at', 'DESC']],
        include: [{ model: User, as: 'user', attributes: ['name', 'email'] }],
      }),
    ]);

    // Orders by status
    const orderStatuses = ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'];
    const statusCounts = await Promise.all(
      orderStatuses.map(async (status) => ({
        status,
        count: await Order.count({ where: { status } }),
      }))
    );

    return res.status(200).json({
      success: true,
      data: {
        totalOrders,
        totalRevenue: totalRevenue || 0,
        totalCustomers,
        pendingOrders,
        todayOrders: todayOrdersCount,
        todayRevenue: todayRevenue || 0,
        staff: { active: activeStaff, inactive: inactiveStaff },
        ordersByStatus: statusCounts,
        recentOrders,
      },
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// ── GLOBAL ORDERS ─────────────────────────────────────────────────────────────

// GET /api/admin/orders  — all orders with customer info
const getGlobalOrders = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const where = status ? { status } : {};

    const { count, rows: orders } = await Order.findAndCountAll({
      where,
      include: [
        { model: User, as: 'user', attributes: ['id', 'name', 'email'] },
        {
          model: OrderItem, as: 'items',
          include: [{ model: Product, as: 'product', attributes: ['id', 'name', 'image_url'] }],
        },
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset,
    });

    return res.status(200).json({
      success: true,
      data: orders,
      pagination: { total: count, page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(count / parseInt(limit)) },
    });
  } catch (error) {
    console.error('Global orders error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// PUT /api/admin/orders/:id/status  — update order status
const updateOrderStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status.' });
    }
    const order = await Order.findByPk(req.params.id);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found.' });
    await order.update({ status });
    return res.status(200).json({ success: true, message: 'Order status updated.', data: { id: order.id, status: order.status } });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// ── ADMIN PRODUCTS ─────────────────────────────────────────────────────────────

// GET /api/admin/products  — all products including unavailable
const getAdminProducts = async (req, res) => {
  try {
    const { search } = req.query;
    const where = {};
    if (search) where.name = { [Op.iLike]: `%${search}%` };
    const products = await Product.findAll({ where, order: [['created_at', 'DESC']] });
    return res.status(200).json({ success: true, data: products });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

module.exports = { createStaff, getStaff, toggleStaff, updateStaff, deleteStaff, getDashboard, getGlobalOrders, updateOrderStatus, getAdminProducts };
