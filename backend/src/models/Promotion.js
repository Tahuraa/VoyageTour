const mongoose = require('mongoose');

const promotionSchema = new mongoose.Schema(
  {
    code: { type: String, required: true, unique: true, uppercase: true, trim: true },
    title: { type: String },
    subtitle: { type: String },
    badge_label: { type: String },
    image_url: { type: String },
    discount_type: { type: String, enum: ['percentage', 'fixed'], required: true },
    discount_value: { type: Number, required: true },
    min_order_amount: { type: Number, default: 0 },
    valid_from: { type: Date, required: true },
    valid_to: { type: Date, required: true },
    usage_limit: { type: Number },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  },
  { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } }
);

module.exports = mongoose.model('Promotion', promotionSchema);
