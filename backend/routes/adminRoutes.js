'use strict';

const express = require('express');
const router = express.Router();
const path = require('path');
const multer = require('multer');
const {
  createStaff, getStaff, toggleStaff, updateStaff, deleteStaff,
  getDashboard, getGlobalOrders, updateOrderStatus,
  getOrdersByUser, getPlatesSummary,
  getAdminProducts,
} = require('../controllers/adminController');
const { authenticate, authorizeAdmin, authorizeAdminOrStaff } = require('../middleware/authMiddleware');

// Image upload storage
const storage = multer.diskStorage({
  destination: path.join(__dirname, '../uploads'),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `product_${Date.now()}${ext}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) return cb(new Error('Only images allowed'));
    cb(null, true);
  },
});

// All admin routes require authentication
router.use(authenticate);

// ── Staff (admin only) ────────────────────────────────────────────────────────
router.get('/staff', authorizeAdmin, getStaff);
router.post('/staff', authorizeAdmin, createStaff);
router.put('/staff/:id', authorizeAdmin, updateStaff);
router.put('/staff/:id/toggle', authorizeAdmin, toggleStaff);
router.delete('/staff/:id', authorizeAdmin, deleteStaff);

// ── Dashboard (admin + staff) ─────────────────────────────────────────────────
router.get('/dashboard', authorizeAdminOrStaff, getDashboard);

// ── Global Orders (admin + staff) ─────────────────────────────────────────────
router.get('/orders', authorizeAdminOrStaff, getGlobalOrders);
router.put('/orders/:id/status', authorizeAdminOrStaff, updateOrderStatus);
router.get('/orders/user/:userId', authorizeAdminOrStaff, getOrdersByUser);
router.get('/orders/plates', authorizeAdminOrStaff, getPlatesSummary);

// ── Admin Products (admin only, includes unavailable) ─────────────────────────
router.get('/products', authorizeAdmin, getAdminProducts);

// ── Product Image Upload (admin only) ────────────────────────────────────────
router.post('/products/:id/image', authorizeAdmin, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No image uploaded.' });
    const { Product } = require('../models');
    const product = await Product.findByPk(req.params.id);
    if (!product) return res.status(404).json({ success: false, message: 'Product not found.' });
    const imageUrl = `/uploads/${req.file.filename}`;
    await product.update({ image_url: imageUrl });
    return res.status(200).json({ success: true, data: { image_url: imageUrl } });
  } catch (error) {
    console.error('Image upload error:', error);
    return res.status(500).json({ success: false, message: 'Upload failed.' });
  }
});

module.exports = router;
