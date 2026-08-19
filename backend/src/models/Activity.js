const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema(
  {
    destination_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Destination',
      required: true,
    },

    name: {
      type: String,
      required: true,
      trim: true,
    },

    location: {
      type: String,
      required: true,
      trim: true,
    },

    description: {
      type: String,
    },

    duration_minutes: {
      type: Number,
      min: 1,
    },

    price: {
      type: Number,
      required: true,
      default: 0,
      min: 0,
    },

    category: {
      type: String,
      enum: [
        'sightseeing',
        'adventure',
        'food',
        'shopping',
        'culture',
        'nature',
        'beach',
        'entertainment',
        'transport',
      ],
      required: true,
    },

    image_url: {
      type: String,
    },

    status: {
      type: String,
      enum: ['active', 'inactive'],
      default: 'active',
    },
  },
  {
    timestamps: {
      createdAt: 'created_at',
      updatedAt: 'updated_at',
    },
  }
);

module.exports = mongoose.model('Activity', activitySchema);
