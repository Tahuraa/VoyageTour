const mongoose = require('mongoose');

const bookingTransportSchema = new mongoose.Schema({
  booking_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
  transport_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Transportation', required: true },
  pickup_location: { type: String, required: true },
  drop_location: { type: String, required: true },
  travel_date: { type: Date, required: true },
  price: { type: Number, required: true },
});

module.exports = mongoose.model('BookingTransport', bookingTransportSchema);
