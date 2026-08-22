const mongoose = require('mongoose');
const User = require('../models/User');
const Booking = require('../models/Booking');
const Payment = require('../models/Payment');
const TourPackage = require('../models/TourPackage');
const Destination = require('../models/Destination');

const BOOKING_STATUSES = ['pending', 'confirmed', 'cancelled', 'completed'];

const bookingPopulate = { path: 'package_id', select: 'title image_url duration_days destination_id', populate: { path: 'destination_id' } };

// GET /api/admin/stats
const getStats = async (req, res) => {
  const [totalUsers, totalPackages, totalDestinations, bookingCounts, revenue, recentBookings] = await Promise.all([
    User.countDocuments(),
    TourPackage.countDocuments(),
    Destination.countDocuments(),
    Booking.aggregate([{ $group: { _id: '$status', count: { $sum: 1 } } }]),
    Payment.aggregate([
      { $match: { payment_status: 'paid' } },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ]),
    Booking.find().sort({ created_at: -1 }).limit(5).populate('user_id', 'name email').populate(bookingPopulate),
  ]);

  const bookingsByStatus = Object.fromEntries(BOOKING_STATUSES.map((s) => [s, 0]));
  for (const row of bookingCounts) bookingsByStatus[row._id] = row.count;

  res.json({
    totalUsers,
    totalPackages,
    totalDestinations,
    totalBookings: bookingCounts.reduce((sum, r) => sum + r.count, 0),
    bookingsByStatus,
    totalRevenue: revenue[0]?.total || 0,
    recentBookings,
  });
};

// GET /api/admin/users
const listUsers = async (req, res) => {
  const users = await User.find().sort({ created_at: -1 });
  res.json({ users });
};

// GET /api/admin/bookings?status=
const listBookings = async (req, res) => {
  const match = {};
  if (req.query.status && BOOKING_STATUSES.includes(req.query.status)) match.status = req.query.status;

  const bookings = await Booking.find(match)
    .sort({ created_at: -1 })
    .populate('user_id', 'name email phone')
    .populate(bookingPopulate);
  res.json({ bookings });
};

// PATCH /api/admin/bookings/:id/status
// body: { status }
const updateBookingStatus = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(404).json({ message: 'Booking not found' });
  }
  const { status } = req.body;
  if (!BOOKING_STATUSES.includes(status)) {
    return res.status(400).json({ message: `status must be one of ${BOOKING_STATUSES.join(', ')}` });
  }

  const booking = await Booking.findById(req.params.id);
  if (!booking) return res.status(404).json({ message: 'Booking not found' });

  booking.status = status;
  await booking.save();
  await booking.populate('user_id', 'name email phone');
  await booking.populate(bookingPopulate);
  res.json({ booking });
};

module.exports = { getStats, listUsers, listBookings, updateBookingStatus };
