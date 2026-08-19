const mongoose = require('mongoose');

const itineraryActivitySchema = new mongoose.Schema(
  {
    activity_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Activity',
      required: true,
    },

    start_time: {
      type: String,
    },

    notes: {
      type: String,
    },

    is_included: {
      type: Boolean,
      default: true,
    },

    is_optional: {
      type: Boolean,
      default: false,
    },

    sort_order: {
      type: Number,
      default: 0,
    },
  },
  {
    _id: true,
  }
);

const itineraryDaySchema = new mongoose.Schema(
  {
    day_number: {
      type: Number,
      required: true,
    },

    title: {
      type: String,
      required: true,
    },

    description: {
      type: String,
    },

    activities: {
      type: [itineraryActivitySchema],
      default: [],
    },
  },
  {
    _id: false,
  }
);

const tourPackageSchema = new mongoose.Schema(
  {
    destination_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Destination',
      required: true,
    },

    title: {
      type: String,
      required: true,
      trim: true,
    },

    description: {
      type: String,
    },

    price: {
      type: Number,
      required: true,
      min: 0,
    },

    duration_days: {
      type: Number,
      required: true,
      min: 1,
    },

    max_people: {
      type: Number,
      required: true,
      min: 1,
    },

    image_url: {
      type: String,
    },

    category: {
      type: String,
      enum: [
        'adventure',
        'beach',
        'cultural',
        'city',
        'nature',
        'luxury',
        'family',
        'honeymoon',
      ],
      required: true,
    },

    included_services: {
      type: [String],
      default: [],
    },

    itinerary: {
      type: [itineraryDaySchema],
      default: [],
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

module.exports = mongoose.model('TourPackage', tourPackageSchema);
