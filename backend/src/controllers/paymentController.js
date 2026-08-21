const stripe = require('../config/stripe');
const Booking = require('../models/Booking');
const Payment = require('../models/Payment');

// GET /api/payments/config
const getConfig = async (req, res) => {
  res.json({ publishableKey: process.env.STRIPE_PUBLISHABLE_KEY || '' });
};

// POST /api/payments/create-intent
// body: { booking_id }
const createPaymentIntent = async (req, res) => {
  const { booking_id } = req.body;
  if (!booking_id) return res.status(400).json({ message: 'booking_id is required' });

  const booking = await Booking.findOne({ _id: booking_id, user_id: req.user._id });
  if (!booking) return res.status(404).json({ message: 'Booking not found' });
  if (booking.status !== 'pending') {
    return res.status(409).json({ message: `Booking is already ${booking.status}` });
  }

  const intent = await stripe.paymentIntents.create({
    amount: Math.round(booking.total_price * 100),
    currency: 'usd',
    automatic_payment_methods: { enabled: true },
    metadata: { booking_id: String(booking._id), user_id: String(req.user._id) },
  });

  res.json({ clientSecret: intent.client_secret, paymentIntentId: intent.id });
};

// POST /api/payments/confirm
// body: { payment_intent_id }
const confirmPayment = async (req, res) => {
  const { payment_intent_id } = req.body;
  if (!payment_intent_id) return res.status(400).json({ message: 'payment_intent_id is required' });

  const intent = await stripe.paymentIntents.retrieve(payment_intent_id);
  if (!intent || intent.metadata?.user_id !== String(req.user._id)) {
    return res.status(404).json({ message: 'Payment not found' });
  }
  if (intent.status !== 'succeeded') {
    return res.status(409).json({ message: `Payment has not succeeded (status: ${intent.status})` });
  }

  const booking = await Booking.findOne({ _id: intent.metadata.booking_id, user_id: req.user._id });
  if (!booking) return res.status(404).json({ message: 'Booking not found' });

  const payment = await Payment.findOneAndUpdate(
    { booking_id: booking._id },
    {
      booking_id: booking._id,
      amount: intent.amount / 100,
      payment_method: 'card',
      transaction_id: intent.id,
      payment_status: 'paid',
      paid_at: new Date(),
    },
    { upsert: true, new: true }
  );

  if (booking.status === 'pending') {
    booking.status = 'confirmed';
    await booking.save();
  }
  await booking.populate({ path: 'package_id', select: 'title image_url duration_days destination_id', populate: { path: 'destination_id' } });

  res.json({ booking, payment });
};

module.exports = { getConfig, createPaymentIntent, confirmPayment };
