const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    package_id: { type: mongoose.Schema.Types.ObjectId, ref: 'TourPackage', default: null },
    travel_start_date: { type: Date, required: true },
    travel_end_date: { type: Date, required: true },
    travelers: { type: Number, required: true, min: 1 },
    total_price: { type: Number, required: true, min: 0 },
    // Set only when a valid promo code was applied at booking time — the
    // code and how much it knocked off the subtotal, for display purposes.
    promo_code: { type: String, default: null },
    discount_amount: { type: Number, min: 0, default: 0 },
    lead_traveler_name: { type: String, required: true, trim: true },
    lead_traveler_email: { type: String, required: true, trim: true, lowercase: true },
    lead_traveler_phone: { type: String, required: true, trim: true },
    status: {
      type: String,
      enum: ['pending', 'confirmed', 'cancelled', 'completed'],
      default: 'pending',
    },
    // Set when a confirmed (already-paid) booking is cancelled — the
    // refund percentage applied based on how close to the travel date the
    // cancellation happened. Null for bookings cancelled before payment
    // (nothing to refund) or never cancelled.
    refund_percent: { type: Number, min: 0, max: 100, default: null },
  },
  { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } }
);

bookingSchema.path('travel_end_date').validate(function (value) {
  return !this.travel_start_date || value >= this.travel_start_date;
}, 'travel_end_date must be on or after travel_start_date');

bookingSchema.index({ user_id: 1, created_at: -1 });
bookingSchema.index({ package_id: 1, status: 1 });

module.exports = mongoose.model('Booking', bookingSchema);
