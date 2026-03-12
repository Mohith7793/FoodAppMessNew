'use strict';

const { Cart, CartItem, Product } = require('../models');

// GET /api/cart
const getCart = async (req, res) => {
  try {
    let cart = await Cart.findOne({
      where: { user_id: req.user.id },
      include: [
        {
          model: CartItem,
          as: 'items',
          include: [{ model: Product, as: 'product' }],
        },
      ],
    });

    if (!cart) {
      cart = await Cart.create({ user_id: req.user.id });
      cart.items = [];
    }

    const total = (cart.items || []).reduce((sum, item) => {
      return sum + parseFloat(item.product.price) * item.quantity;
    }, 0);

    return res.status(200).json({
      success: true,
      data: { cart, total: total.toFixed(2) },
    });
  } catch (error) {
    console.error('Get cart error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// POST /api/cart/add
const addToCart = async (req, res) => {
  try {
    const { product_id, quantity = 1 } = req.body;

    if (!product_id) {
      return res.status(400).json({ success: false, message: 'Product ID is required.' });
    }

    const product = await Product.findByPk(product_id);
    if (!product || !product.is_available) {
      return res.status(404).json({ success: false, message: 'Product not found or unavailable.' });
    }

    let cart = await Cart.findOne({ where: { user_id: req.user.id } });
    if (!cart) cart = await Cart.create({ user_id: req.user.id });

    let cartItem = await CartItem.findOne({ where: { cart_id: cart.id, product_id } });
    if (cartItem) {
      cartItem.quantity += parseInt(quantity);
      await cartItem.save();
    } else {
      cartItem = await CartItem.create({ cart_id: cart.id, product_id, quantity: parseInt(quantity) });
    }

    return res.status(200).json({ success: true, message: 'Item added to cart.', data: cartItem });
  } catch (error) {
    console.error('Add to cart error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// PUT /api/cart/update
const updateCartItem = async (req, res) => {
  try {
    const { product_id, quantity } = req.body;

    const cart = await Cart.findOne({ where: { user_id: req.user.id } });
    if (!cart) return res.status(404).json({ success: false, message: 'Cart not found.' });

    const cartItem = await CartItem.findOne({ where: { cart_id: cart.id, product_id } });
    if (!cartItem) return res.status(404).json({ success: false, message: 'Item not in cart.' });

    if (parseInt(quantity) <= 0) {
      await cartItem.destroy();
      return res.status(200).json({ success: true, message: 'Item removed from cart.' });
    }

    cartItem.quantity = parseInt(quantity);
    await cartItem.save();
    return res.status(200).json({ success: true, message: 'Cart updated.', data: cartItem });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// DELETE /api/cart/remove
const removeFromCart = async (req, res) => {
  try {
    const { product_id } = req.body;

    const cart = await Cart.findOne({ where: { user_id: req.user.id } });
    if (!cart) return res.status(404).json({ success: false, message: 'Cart not found.' });

    const deleted = await CartItem.destroy({ where: { cart_id: cart.id, product_id } });
    if (!deleted) return res.status(404).json({ success: false, message: 'Item not found in cart.' });

    return res.status(200).json({ success: true, message: 'Item removed from cart.' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

// DELETE /api/cart/clear
const clearCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ where: { user_id: req.user.id } });
    if (cart) await CartItem.destroy({ where: { cart_id: cart.id } });
    return res.status(200).json({ success: true, message: 'Cart cleared.' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

module.exports = { getCart, addToCart, updateCartItem, removeFromCart, clearCart };
