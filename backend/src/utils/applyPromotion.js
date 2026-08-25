const Promotion = require('../models/Promotion');

// Looks up an active, currently-valid promotion by code and prices it
// against a subtotal. A stale/expired/unknown code, or one that doesn't
// meet its minimum order amount, just doesn't discount — checkout never
// blocks on a bad promo code, it silently falls back to full price.
// Pricing always happens here (server-side) rather than trusting whatever
// discount the client claims, since the client only "claims" a code —
// the actual math is authoritative on the backend.
const applyPromotion = async (code, subtotal) => {
  if (!code) return { total: subtotal, promotion: null, discountAmount: 0 };

  const now = new Date();
  const promotion = await Promotion.findOne({
    code: String(code).toUpperCase(),
    status: 'active',
    valid_from: { $lte: now },
    valid_to: { $gte: now },
  });

  if (!promotion || subtotal < promotion.min_order_amount) {
    return { total: subtotal, promotion: null, discountAmount: 0 };
  }

  const rawDiscount =
    promotion.discount_type === 'percentage' ? subtotal * (promotion.discount_value / 100) : promotion.discount_value;
  const discountAmount = Math.min(rawDiscount, subtotal);
  const total = subtotal - discountAmount;

  return { total, promotion, discountAmount };
};

module.exports = applyPromotion;
