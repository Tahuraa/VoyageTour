const mongoose = require('mongoose');

const bookingCouponSchema = new mongoose.Schema({
  booking_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
  promotion_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Promotion', required: true },
  discount_amount: { type: Number, required: true },
});

module.exports = mongoose.model('BookingCoupon', bookingCouponSchema);
