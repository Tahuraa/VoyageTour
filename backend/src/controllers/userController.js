const User = require('../models/User');
const Booking = require('../models/Booking');
const CustomizedTour = require('../models/CustomizedTour');
const Favorite = require('../models/Favorite');
const Review = require('../models/Review');
const Payment = require('../models/Payment');
const { publicUser } = require('./authController');

// GET /api/users/me
const getMe = async (req, res) => {
  return res.json({ user: publicUser(req.user) });
};

// PUT /api/users/me
const updateMe = async (req, res) => {
  const { name, phone } = req.body;

  if (phone && phone !== req.user.phone) {
    const taken = await User.findOne({ phone, _id: { $ne: req.user._id } });
    if (taken) return res.status(409).json({ message: 'Phone number already in use' });
  }

  if (name) req.user.name = name;
  if (phone) req.user.phone = phone;
  await req.user.save();

  return res.json({ user: publicUser(req.user) });
};

// POST /api/users/me/photo
const updateMyPhoto = async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'No photo uploaded' });

  req.user.profile_image = `/uploads/${req.file.filename}`;
  await req.user.save();

  return res.json({ user: publicUser(req.user) });
};

// PUT /api/users/me/password
const changeMyPassword = async (req, res) => {
  const { current_password, new_password } = req.body;
  if (!current_password || !new_password) {
    return res.status(400).json({ message: 'current_password and new_password are required' });
  }
  if (new_password.length < 6) {
    return res.status(400).json({ message: 'New password must be at least 6 characters' });
  }

  const user = await User.findById(req.user._id).select('+password');
  if (!(await user.matchPassword(current_password))) {
    return res.status(401).json({ message: 'Current password is incorrect' });
  }

  user.password = new_password;
  await user.save();

  return res.json({ message: 'Password updated' });
};

// DELETE /api/users/me
// Cascades to everything owned by the account — bookings, customized
// tours, favorites and reviews (and the payments tied to those bookings) —
// matching what the app's confirmation dialog tells the user will happen.
const deleteMe = async (req, res) => {
  const { password } = req.body;
  if (!password) return res.status(400).json({ message: 'password is required' });

  const user = await User.findById(req.user._id).select('+password');
  if (!(await user.matchPassword(password))) {
    return res.status(401).json({ message: 'Password is incorrect' });
  }

  const bookings = await Booking.find({ user_id: user._id }, '_id');
  await Payment.deleteMany({ booking_id: { $in: bookings.map((b) => b._id) } });
  await Booking.deleteMany({ user_id: user._id });
  await CustomizedTour.deleteMany({ user_id: user._id });
  await Favorite.deleteMany({ user_id: user._id });
  await Review.deleteMany({ user_id: user._id });
  await user.deleteOne();

  return res.json({ message: 'Account deleted' });
};

module.exports = { getMe, updateMe, updateMyPhoto, changeMyPassword, deleteMe };
