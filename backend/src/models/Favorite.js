const mongoose = require('mongoose');

const favoriteSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, enum: ['package', 'hotel', 'destination'], required: true },
    reference_id: { type: mongoose.Schema.Types.ObjectId, required: true },
  },
  { timestamps: { createdAt: 'created_at', updatedAt: false } }
);

favoriteSchema.index({ user_id: 1, type: 1, reference_id: 1 }, { unique: true });

module.exports = mongoose.model('Favorite', favoriteSchema);
