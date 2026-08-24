const mongoose = require('mongoose');

const customizedActivitySchema = new mongoose.Schema(
  {
    day_number: {
      type: Number,
      required: true,
    },

    activity_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Activity',
      required: true,
    },

    price: {
      type: Number,
      required: true,
      min: 0,
    },

    start_time: {
      type: String,
    },

    notes: {
      type: String,
    },

    sort_order: {
      type: Number,
      default: 0,
    },

    source: {
      type: String,
      enum: ['package', 'added'],
      default: 'package',
    },
  },
  {
    _id: true,
  }
);

const customizedTourSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    tour_package_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'TourPackage',
      required: true,
    },

    destination_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Destination',
      required: true,
    },

    travelers: {
      type: Number,
      required: true,
      min: 1,
    },

    travel_date: {
      type: Date,
      required: true,
    },

    activities: {
      type: [customizedActivitySchema],
      default: [],
    },

    removed_activity_ids: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Activity',
      },
    ],

    hotel: {
      price: {
        type: Number,
        default: 0,
        min: 0,
      },

      category: {
        type: String,
        enum: [
          '3_star',
          '4_star',
          '5_star',
        ],
      },
    },

    transportation: {
      type: {
        type: String,
        enum: [
          'private_car',
          'shared_shuttle',
          'tour_bus',
        ],
      },

      price: {
        type: Number,
        default: 0,
        min: 0,
      },
    },

    base_price: {
      type: Number,
      required: true,
      min: 0,
    },

    activities_price: {
      type: Number,
      default: 0,
      min: 0,
    },

    hotel_price: {
      type: Number,
      default: 0,
      min: 0,
    },

    transportation_price: {
      type: Number,
      default: 0,
      min: 0,
    },

    total_price: {
      type: Number,
      required: true,
      min: 0,
    },

    status: {
      type: String,
      enum: [
        'draft',
        'confirmed',
        'cancelled',
        'completed',
      ],
      default: 'draft',
    },
  },
  {
    timestamps: {
      createdAt: 'created_at',
      updatedAt: 'updated_at',
    },
  }
);

module.exports = mongoose.model(
  'CustomizedTour',
  customizedTourSchema
);
