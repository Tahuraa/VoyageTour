const mongoose = require('mongoose');

const bookingActivitySchema = new mongoose.Schema({
  booking_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
  activity_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Activity', required: true },
  day_number: { type: Number, required: true },
  activity_date: { type: Date, required: true },
  quantity: { type: Number, required: true },
  price: { type: Number, required: true },
});

module.exports = mongoose.model('BookingActivity', bookingActivitySchema);
