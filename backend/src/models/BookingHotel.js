const mongoose = require('mongoose');

const bookingHotelSchema = new mongoose.Schema({
  booking_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
  hotel_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Hotel', required: true },
  check_in_date: { type: Date, required: true },
  check_out_date: { type: Date, required: true },
  guests: { type: Number, required: true },
  price: { type: Number, required: true },
});

module.exports = mongoose.model('BookingHotel', bookingHotelSchema);
