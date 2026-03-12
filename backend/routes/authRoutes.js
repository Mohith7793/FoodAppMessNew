'use strict';

const express = require('express');
const router = express.Router();
const { register, registerAdmin, login, getMe } = require('../controllers/authController');
const { authenticate } = require('../middleware/authMiddleware');

router.post('/register', register);
router.post('/register-admin', registerAdmin);
router.post('/login', login);
router.get('/me', authenticate, getMe);

module.exports = router;
