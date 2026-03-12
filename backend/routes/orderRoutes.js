'use strict';

const express = require('express');
const router = express.Router();
const { createOrder, getOrders, getOrderById } = require('../controllers/orderController');
const { authenticate } = require('../middleware/authMiddleware');

router.use(authenticate);

router.post('/create', createOrder);
router.get('/', getOrders);
router.get('/:id', getOrderById);

module.exports = router;
