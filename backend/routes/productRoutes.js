'use strict';

const express = require('express');
const router = express.Router();
const path = require('path');
const multer = require('multer');
const { getProducts, getProductById, createProduct, updateProduct, deleteProduct } = require('../controllers/productController');
const { authenticate, authorizeAdmin } = require('../middleware/authMiddleware');

const storage = multer.diskStorage({
  destination: path.join(__dirname, '../uploads'),
  filename: (req, file, cb) => {
    cb(null, `product_${Date.now()}${path.extname(file.originalname)}`);
  },
});
const upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 } });

router.get('/', getProducts);
router.get('/:id', getProductById);

// Admin routes — accept optional image file
router.post('/', authenticate, authorizeAdmin, upload.single('image'), createProduct);
router.put('/:id', authenticate, authorizeAdmin, upload.single('image'), updateProduct);
router.delete('/:id', authenticate, authorizeAdmin, deleteProduct);

module.exports = router;
