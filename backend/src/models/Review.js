const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    package_id: { type: mongoose.Schema.Types.ObjectId, ref: 'TourPackage', default: null },
    hotel_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Hotel', default: null },
    rating: { type: Number, min: 1, max: 5, required: true },
    comment: { type: String },
  },
  { timestamps: { createdAt: 'created_at', updatedAt: false } }
);

module.exports = mongoose.model('Review', reviewSchema);
