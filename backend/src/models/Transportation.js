const mongoose = require('mongoose');

const transportationSchema = new mongoose.Schema(
  {
    destination_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Destination', required: true },
    type: { type: String, enum: ['bus', 'car', 'van', 'train', 'other'], required: true },
    name: { type: String, required: true, trim: true },
    price: { type: Number, required: true, min: 0 },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  },
  { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } }
);

transportationSchema.index({ destination_id: 1, status: 1, type: 1 });

module.exports = mongoose.model('Transportation', transportationSchema);
