'use strict';

const { Product } = require('../models');
const { Op } = require('sequelize');

// GET /api/products  — customers see only available products
const getProducts = async (req, res) => {
  try {
    const { category, search, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const where = { is_available: true };
    if (category) where.category = category;
    if (search) where.name = { [Op.iLike]: `%${search}%` };

    const { count, rows: products } = await Product.findAndCountAll({
      where,
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset,
    });

    return res.status(200).json({
      success: true,
      data: products,
      pagination: { total: count, page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(count / parseInt(limit)) },
    });
  } catch (error) {
    console.error('Get products error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// GET /api/products/:id
const getProductById = async (req, res) => {
  try {
    const product = await Product.findByPk(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found.' });
    return res.status(200).json({ success: true, data: product });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// POST /api/products (Admin only) — supports multipart (with image) and JSON
const createProduct = async (req, res) => {
  try {
    const { name, description, price, stock, category, is_available } = req.body;
    if (!name || !price) {
      return res.status(400).json({ success: false, message: 'Name and price are required.' });
    }
    const image_url = req.file ? `/uploads/${req.file.filename}` : (req.body.image_url || null);
    const product = await Product.create({
      name,
      description: description || null,
      price: parseFloat(price),
      image_url,
      stock: parseInt(stock) || 100,
      category: category || 'Main Course',
      is_available: is_available !== undefined ? is_available === true || is_available === 'true' : true,
    });
    return res.status(201).json({ success: true, data: product });
  } catch (error) {
    console.error('Create product error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// PUT /api/products/:id (Admin only)
const updateProduct = async (req, res) => {
  try {
    const product = await Product.findByPk(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found.' });
    const updates = { ...req.body };
    if (req.file) updates.image_url = `/uploads/${req.file.filename}`;
    if (updates.price) updates.price = parseFloat(updates.price);
    if (updates.stock) updates.stock = parseInt(updates.stock);
    if (updates.is_available !== undefined) {
      updates.is_available = updates.is_available === true || updates.is_available === 'true';
    }
    await product.update(updates);
    return res.status(200).json({ success: true, data: product });
  } catch (error) {
    console.error('Update product error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// DELETE /api/products/:id (Admin only) — hard delete
const deleteProduct = async (req, res) => {
  try {
    const product = await Product.findByPk(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found.' });
    await product.destroy();
    return res.status(200).json({ success: true, message: 'Product deleted.' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

module.exports = { getProducts, getProductById, createProduct, updateProduct, deleteProduct };
