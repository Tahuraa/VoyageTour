const crypto = require('crypto');
const User = require('../models/User');
const generateToken = require('../utils/generateToken');
const sendEmail = require('../utils/sendEmail');

const publicUser = (user) => ({
  id: user._id,
  name: user.name,
  email: user.email,
  phone: user.phone,
  profile_image: user.profile_image,
  role: user.role,
  created_at: user.created_at,
});

// POST /api/auth/register
const register = async (req, res) => {
  const { name, email, phone, password } = req.body;
  if (!name || !email || !phone || !password) {
    return res.status(400).json({ message: 'name, email, phone and password are required' });
  }

  const exists = await User.findOne({ $or: [{ email }, { phone }] });
  if (exists) {
    return res.status(409).json({ message: 'An account with this email or phone already exists' });
  }

  const user = await User.create({ name, email, phone, password });
  return res.status(201).json({ user: publicUser(user), token: generateToken(user._id) });
};

// POST /api/auth/login
const login = async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'email and password are required' });
  }

  const user = await User.findOne({ email }).select('+password');
  if (!user || !(await user.matchPassword(password))) {
    return res.status(401).json({ message: 'Invalid email or password' });
  }

  return res.json({ user: publicUser(user), token: generateToken(user._id) });
};

// POST /api/auth/forgot-password
const forgotPassword = async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({ email });

  // Always respond the same way so we don't leak which emails are registered.
  if (!user) {
    return res.json({ message: 'If that email is registered, a reset code has been sent' });
  }

  const resetToken = user.createPasswordResetToken();
  await user.save({ validateBeforeSave: false });

  await sendEmail({
    to: user.email,
    subject: 'VoyageTour password reset',
    text: `Use this code to reset your password (valid for 15 minutes): ${resetToken}`,
  });

  return res.json({ message: 'If that email is registered, a reset code has been sent' });
};

// POST /api/auth/reset-password
const resetPassword = async (req, res) => {
  const { token, password } = req.body;
  if (!token || !password) {
    return res.status(400).json({ message: 'token and password are required' });
  }

  const hashedToken = crypto.createHash('sha256').update(token).digest('hex');
  const user = await User.findOne({
    passwordResetToken: hashedToken,
    passwordResetExpires: { $gt: Date.now() },
  }).select('+password +passwordResetToken +passwordResetExpires');

  if (!user) {
    return res.status(400).json({ message: 'Reset code is invalid or has expired' });
  }

  user.password = password;
  user.passwordResetToken = undefined;
  user.passwordResetExpires = undefined;
  await user.save();

  return res.json({ message: 'Password has been reset, please log in' });
};

module.exports = { register, login, forgotPassword, resetPassword, publicUser };
