const mongoose = require('mongoose');
const Promotion = require('../models/Promotion');

const isValidId = (id) => mongoose.isValidObjectId(id);

// GET /api/promotions/active
const getActivePromotions = async (req, res) => {
  const now = new Date();
  const promotions = await Promotion.find({
    status: 'active',
    valid_from: { $lte: now },
    valid_to: { $gte: now },
  }).sort({ valid_to: 1 });

  res.json({ promotions });
};

// ---------- Admin ----------

const listPromotions = async (req, res) => {
  const promotions = await Promotion.find().sort({ created_at: -1 });
  res.json({ promotions });
};

const createPromotion = async (req, res) => {
  const {
    code, title, subtitle, badge_label, image_url,
    discount_type, discount_value, min_order_amount,
    valid_from, valid_to, usage_limit, status,
  } = req.body;
  if (!code || !discount_type || discount_value == null || !valid_from || !valid_to) {
    return res.status(400).json({
      message: 'code, discount_type, discount_value, valid_from and valid_to are required',
    });
  }
  const promotion = await Promotion.create({
    code, title, subtitle, badge_label, image_url,
    discount_type, discount_value, min_order_amount,
    valid_from, valid_to, usage_limit, status,
  });
  res.status(201).json({ promotion });
};

const updatePromotion = async (req, res) => {
  if (!isValidId(req.params.id)) return res.status(404).json({ message: 'Promotion not found' });
  const {
    code, title, subtitle, badge_label, image_url,
    discount_type, discount_value, min_order_amount,
    valid_from, valid_to, usage_limit, status,
  } = req.body;
  const promotion = await Promotion.findByIdAndUpdate(
    req.params.id,
    {
      code, title, subtitle, badge_label, image_url,
      discount_type, discount_value, min_order_amount,
      valid_from, valid_to, usage_limit, status,
    },
    { new: true, runValidators: true, omitUndefined: true }
  );
  if (!promotion) return res.status(404).json({ message: 'Promotion not found' });
  res.json({ promotion });
};

const deletePromotion = async (req, res) => {
  if (!isValidId(req.params.id)) return res.status(404).json({ message: 'Promotion not found' });
  const promotion = await Promotion.findByIdAndDelete(req.params.id);
  if (!promotion) return res.status(404).json({ message: 'Promotion not found' });
  res.json({ message: 'Promotion deleted' });
};

module.exports = {
  getActivePromotions,
  listPromotions, createPromotion, updatePromotion, deletePromotion,
};
