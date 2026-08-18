const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema(
  {
    booking_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true, unique: true },
    amount: { type: Number, required: true },
    payment_method: { type: String, enum: ['card', 'bkash', 'nagad', 'others'], required: true },
    transaction_id: { type: String, required: true, unique: true },
    payment_status: { type: String, enum: ['paid', 'failed', 'refunded'], default: 'paid' },
    paid_at: { type: Date },
  },
  { timestamps: { createdAt: 'created_at', updatedAt: false } }
);

module.exports = mongoose.model('Payment', paymentSchema);
