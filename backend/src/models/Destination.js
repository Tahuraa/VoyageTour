const mongoose = require('mongoose');

const destinationSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    country: { type: String, required: true },
    country_code: { type: String, required: true, uppercase: true, trim: true, minlength: 2, maxlength: 2 },
    description: { type: String },
    image_url: { type: String },
    is_featured: { type: Boolean, default: false },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  },
  { timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } }
);

module.exports = mongoose.model('Destination', destinationSchema);
