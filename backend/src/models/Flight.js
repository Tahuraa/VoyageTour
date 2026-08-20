const mongoose = require('mongoose');

const flightSchema = new mongoose.Schema(
  {
    destination_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Destination', required: true },
    airline: { type: String, required: true, trim: true },
    departure_location: { type: String, required: true, trim: true },
    arrival_location: { type: String, required: true, trim: true },
    departure_time: { type: Date, required: true },
    arrival_time: { type: Date, required: true },
    price: { type: Number, required: true, min: 0 },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  },
  { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } }
);

flightSchema.path('arrival_time').validate(function (value) {
  return !this.departure_time || value > this.departure_time;
}, 'arrival_time must be after departure_time');

flightSchema.index({ destination_id: 1, status: 1, departure_time: 1 });

module.exports = mongoose.model('Flight', flightSchema);
