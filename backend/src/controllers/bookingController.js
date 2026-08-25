const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const TourPackage = require('../models/TourPackage');
const Payment = require('../models/Payment');
const stripe = require('../config/stripe');
const applyPromotion = require('../utils/applyPromotion');

const populated = (booking) =>
  booking.populate({ path: 'package_id', select: 'title image_url duration_days destination_id', populate: { path: 'destination_id' } });

// Cancellation refund policy for an already-confirmed (paid) booking:
//   more than 2 weeks before travel   -> full refund
//   2 weeks or less, more than 7 days -> 30% refund
//   7 days or less                    -> no refund
const MS_PER_DAY = 24 * 60 * 60 * 1000;
const calculateRefundPercent = (travelStartDate) => {
  const daysUntilTrip = Math.ceil((new Date(travelStartDate).getTime() - Date.now()) / MS_PER_DAY);
  if (daysUntilTrip > 14) return 100;
  if (daysUntilTrip > 7) return 30;
  return 0;
};

// POST /api/bookings — the direct "Book" path (no customization): review
// the plain package, capture lead traveler details, and pay the package's
// flat price. For the itinerary-editing path, see CustomizedTour instead.
const createBooking = async (req, res) => {
  const {
    package_id,
    travelers,
    travel_date,
    lead_traveler_name,
    lead_traveler_email,
    lead_traveler_phone,
    promo_code,
  } = req.body;

  if (!package_id || !travelers || !travel_date) {
    return res.status(400).json({ message: 'package_id, travelers and travel_date are required' });
  }
  if (!lead_traveler_name || !lead_traveler_email || !lead_traveler_phone) {
    return res.status(400).json({ message: 'Lead traveler name, email and phone are required' });
  }

  const pkg = await TourPackage.findOne({ _id: package_id, status: 'active' });
  if (!pkg) return res.status(404).json({ message: 'Tour package not found' });
  if (travelers < 1 || travelers > pkg.max_people) {
    return res.status(400).json({ message: `Travelers must be between 1 and ${pkg.max_people}` });
  }

  const travelStartDate = new Date(travel_date);
  const travelEndDate = new Date(travelStartDate);
  travelEndDate.setDate(travelEndDate.getDate() + pkg.duration_days);

  const subtotal = pkg.price * travelers;
  const { total, promotion, discountAmount } = await applyPromotion(promo_code, subtotal);

  const booking = await Booking.create({
    user_id: req.user._id,
    package_id: pkg._id,
    travel_start_date: travelStartDate,
    travel_end_date: travelEndDate,
    travelers,
    total_price: total,
    promo_code: promotion?.code || null,
    discount_amount: discountAmount,
    lead_traveler_name,
    lead_traveler_email,
    lead_traveler_phone,
    status: 'pending',
  });

  await populated(booking);
  res.status(201).json({ booking });
};

// GET /api/bookings
const listMyBookings = async (req, res) => {
  const bookings = await Booking.find({ user_id: req.user._id })
    .sort({ created_at: -1 })
    .populate({ path: 'package_id', select: 'title image_url duration_days destination_id', populate: { path: 'destination_id' } });
  res.json({ bookings });
};

// GET /api/bookings/:id
const getBooking = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(404).json({ message: 'Booking not found' });
  }
  const booking = await Booking.findById(req.params.id);
  if (!booking || String(booking.user_id) !== String(req.user._id)) {
    return res.status(404).json({ message: 'Booking not found' });
  }
  await populated(booking);
  res.json({ booking });
};

// PATCH /api/bookings/:id/cancel
// draft/pending bookings just cancel outright (nothing was ever charged).
// A confirmed (paid) booking gets a refund per calculateRefundPercent,
// issued back through Stripe against the original PaymentIntent.
const cancelBooking = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(404).json({ message: 'Booking not found' });
  }
  const booking = await Booking.findOne({ _id: req.params.id, user_id: req.user._id });
  if (!booking) return res.status(404).json({ message: 'Booking not found' });
  if (!['pending', 'confirmed'].includes(booking.status)) {
    return res.status(409).json({ message: `Booking cannot be cancelled (status: ${booking.status})` });
  }

  if (booking.status === 'confirmed') {
    const refundPercent = calculateRefundPercent(booking.travel_start_date);
    booking.refund_percent = refundPercent;

    if (refundPercent > 0) {
      const payment = await Payment.findOne({ booking_id: booking._id, payment_status: 'paid' });
      if (payment) {
        const refundAmount = Math.round(booking.total_price * (refundPercent / 100) * 100);
        await stripe.refunds.create({ payment_intent: payment.transaction_id, amount: refundAmount });
        payment.payment_status = 'refunded';
        await payment.save();
      }
    }
  }

  booking.status = 'cancelled';
  await booking.save();
  await populated(booking);
  res.json({ booking });
};

module.exports = { createBooking, listMyBookings, getBooking, cancelBooking };
