'use strict';

const { Product, Order, OrderItem } = require('../models');
const { Op, fn, col, literal } = require('sequelize');

// ── Holt's Linear Exponential Smoothing ───────────────────────────────────────
// Returns `periods` future predictions given a time-series array of values.
// alpha = level smoothing factor, beta = trend smoothing factor.
function holtForecast(series, alpha = 0.4, beta = 0.3, periods = 3) {
  if (series.length === 0) return Array(periods).fill(0);
  if (series.length === 1) return Array(periods).fill(Math.round(series[0]));

  let level = series[0];
  let trend = series[1] - series[0];

  for (let i = 1; i < series.length; i++) {
    const prevLevel = level;
    level = alpha * series[i] + (1 - alpha) * (level + trend);
    trend = beta * (level - prevLevel) + (1 - beta) * trend;
  }

  return Array.from({ length: periods }, (_, i) =>
    Math.max(0, Math.round(level + (i + 1) * trend))
  );
}

// ── ISO week key: "YYYY-Www" (e.g. "2025-W12") ────────────────────────────────
function isoWeekKey(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  // Thursday-based ISO week
  d.setDate(d.getDate() + 3 - ((d.getDay() + 6) % 7));
  const week1 = new Date(d.getFullYear(), 0, 4);
  const weekNum =
    1 +
    Math.round(
      ((d.getTime() - week1.getTime()) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7
    );
  return `${d.getFullYear()}-W${String(weekNum).padStart(2, '0')}`;
}

// Build a list of the last N ISO week keys up to (and including) the current week
function lastNWeekKeys(n) {
  const keys = [];
  const now = new Date();
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i * 7);
    keys.push(isoWeekKey(d));
  }
  return [...new Set(keys)]; // deduplicate (edge-of-week safety)
}

// Build the week key for `weekOffset` weeks from now (positive = future)
function futureWeekKey(offset) {
  const d = new Date();
  d.setDate(d.getDate() + offset * 7);
  return isoWeekKey(d);
}

// ── GET /api/admin/forecast ───────────────────────────────────────────────────
const getForecast = async (req, res) => {
  try {
    const HISTORY_WEEKS = 8;   // weeks of history to use for training
    const PREDICT_WEEKS = 3;   // weeks to forecast ahead

    // Date boundary: start of the oldest history week
    const historyStart = new Date();
    historyStart.setDate(historyStart.getDate() - HISTORY_WEEKS * 7);

    // Fetch all delivered order items in that window, with product info
    const items = await OrderItem.findAll({
      include: [
        {
          model: Order,
          as: 'order',
          where: {
            status: 'delivered',
            created_at: { [Op.gte]: historyStart },
          },
          attributes: ['created_at'],
        },
        {
          model: Product,
          as: 'product',
          attributes: ['id', 'name', 'category', 'image_url'],
        },
      ],
      attributes: ['product_id', 'quantity'],
    });

    // Group quantities by product → week
    const productWeekMap = {}; // { productId: { weekKey: totalQty } }
    const productMeta = {};    // { productId: { name, category, image_url } }

    for (const item of items) {
      const pid = item.product_id;
      const wk = isoWeekKey(item.order.created_at);

      if (!productWeekMap[pid]) productWeekMap[pid] = {};
      productWeekMap[pid][wk] = (productWeekMap[pid][wk] || 0) + item.quantity;

      if (!productMeta[pid] && item.product) {
        productMeta[pid] = {
          id: pid,
          name: item.product.name,
          category: item.product.category,
          image_url: item.product.image_url,
        };
      }
    }

    const historyKeys = lastNWeekKeys(HISTORY_WEEKS);

    const results = [];
    for (const [pid, weekData] of Object.entries(productWeekMap)) {
      const meta = productMeta[pid] || { id: parseInt(pid), name: `Product #${pid}`, category: null, image_url: null };

      // Build the history series (fill 0 for missing weeks)
      const historySeries = historyKeys.map((wk) => weekData[wk] || 0);

      // Only include products that have at least 1 delivered plate
      const totalDelivered = historySeries.reduce((s, v) => s + v, 0);
      if (totalDelivered === 0) continue;

      // Run Holt's exponential smoothing
      const predicted = holtForecast(historySeries, 0.4, 0.3, PREDICT_WEEKS);

      // Build trend direction based on last 2 actual data points
      const lastTwo = historySeries.slice(-2);
      const trendDir =
        lastTwo[1] > lastTwo[0] ? 'up' : lastTwo[1] < lastTwo[0] ? 'down' : 'stable';

      // Historical view: just the last 4 weeks for display
      const displayHistory = historyKeys.slice(-4).map((wk) => ({
        week: wk,
        quantity: weekData[wk] || 0,
      }));

      // Predicted weeks
      const predictedWeeks = Array.from({ length: PREDICT_WEEKS }, (_, i) => ({
        week: futureWeekKey(i + 1),
        quantity: predicted[i],
      }));

      results.push({
        ...meta,
        total_delivered: totalDelivered,
        trend: trendDir,
        history: displayHistory,
        forecast: predictedWeeks,
        next_week_plates: predicted[0],
      });
    }

    // Sort by next-week prediction descending (highest demand first)
    results.sort((a, b) => b.next_week_plates - a.next_week_plates);

    return res.status(200).json({
      success: true,
      data: {
        generated_at: new Date().toISOString(),
        history_weeks: HISTORY_WEEKS,
        forecast_weeks: PREDICT_WEEKS,
        products: results,
      },
    });
  } catch (error) {
    console.error('Forecast error:', error);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

module.exports = { getForecast };
