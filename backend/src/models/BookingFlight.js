const mongoose = require('mongoose');

const bookingFlightSchema = new mongoose.Schema({
  booking_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
  flight_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Flight', required: true },
  travel_date: { type: Date, required: true },
  seat_class: { type: String, required: true },
  price: { type: Number, required: true },
});

module.exports = mongoose.model('BookingFlight', bookingFlightSchema);
