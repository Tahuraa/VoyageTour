const mongoose = require('mongoose');

const hotelSchema = new mongoose.Schema(
  {
    destination_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Destination', required: true },
    name: { type: String, required: true, trim: true },
    address: { type: String, trim: true },
    star_rating: { type: Number, min: 1, max: 5 },
    price_per_night: { type: Number, required: true, min: 0 },
    image_url: { type: String },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  },
  { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } }
);

hotelSchema.index({ destination_id: 1, status: 1 });
hotelSchema.index({ destination_id: 1, price_per_night: 1 });

module.exports = mongoose.model('Hotel', hotelSchema);
