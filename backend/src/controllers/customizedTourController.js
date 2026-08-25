const mongoose = require('mongoose');
const CustomizedTour = require('../models/CustomizedTour');
const TourPackage = require('../models/TourPackage');
const Activity = require('../models/Activity');
const Booking = require('../models/Booking');
const applyPromotion = require('../utils/applyPromotion');
const {
  HOTEL_CATEGORY_PRICE_PER_NIGHT,
  TRANSPORTATION_TYPE_PRICE,
  DEFAULT_HOTEL_CATEGORY,
  DEFAULT_TRANSPORTATION_TYPE,
} = require('../config/customizationOptions');

// Nights of hotel stay a package's duration implies (a 5-day trip books 4
// nights). Shared by createCustomizedTour and selectHotel so the default
// hotel and a manually re-picked one price the same way.
const nightsFor = (durationDays) => Math.max((durationDays || 1) - 1, 1);

const recomputeTotals = (tour) => {
  tour.activities_price = tour.activities
    .filter((a) => a.source === 'added')
    .reduce((sum, a) => sum + a.price, 0);
  tour.hotel_price = tour.hotel?.price || 0;
  tour.transportation_price = tour.transportation?.price || 0;
  tour.total_price = tour.base_price + tour.activities_price + tour.hotel_price + tour.transportation_price;
};

const loadOwnedTour = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    res.status(404).json({ message: 'Customized tour not found' });
    return null;
  }
  const tour = await CustomizedTour.findById(req.params.id);
  if (!tour || String(tour.user_id) !== String(req.user._id)) {
    res.status(404).json({ message: 'Customized tour not found' });
    return null;
  }
  return tour;
};

const populated = (tour) =>
  tour.populate([
    { path: 'destination_id' },
    { path: 'tour_package_id', select: 'title image_url duration_days price' },
    { path: 'activities.activity_id' },
  ]);

// GET /api/customized-tours/options
const getOptions = async (req, res) => {
  res.json({
    hotelCategories: Object.entries(HOTEL_CATEGORY_PRICE_PER_NIGHT).map(([category, pricePerNight]) => ({
      category,
      price_per_night: pricePerNight,
    })),
    transportationTypes: Object.entries(TRANSPORTATION_TYPE_PRICE).map(([type, price]) => ({ type, price })),
  });
};

// POST /api/customized-tours
const createCustomizedTour = async (req, res) => {
  const { tour_package_id, travelers, travel_date } = req.body;
  if (!tour_package_id || !travelers || !travel_date) {
    return res.status(400).json({ message: 'tour_package_id, travelers and travel_date are required' });
  }

  const pkg = await TourPackage.findOne({ _id: tour_package_id, status: 'active' });
  if (!pkg) return res.status(404).json({ message: 'Tour package not found' });
  if (travelers < 1 || travelers > pkg.max_people) {
    return res.status(400).json({ message: `Travelers must be between 1 and ${pkg.max_people}` });
  }

  const activities = [];
  for (const day of pkg.itinerary) {
    for (const entry of day.activities) {
      const activity = await Activity.findById(entry.activity_id);
      if (!activity) continue;
      activities.push({
        day_number: day.day_number,
        activity_id: activity._id,
        price: activity.price,
        start_time: entry.start_time,
        notes: entry.notes,
        sort_order: entry.sort_order,
        source: 'package',
      });
    }
  }

  const nights = nightsFor(pkg.duration_days);
  const defaultHotelPrice = HOTEL_CATEGORY_PRICE_PER_NIGHT[DEFAULT_HOTEL_CATEGORY] * nights;
  const defaultTransportationPrice = TRANSPORTATION_TYPE_PRICE[DEFAULT_TRANSPORTATION_TYPE];
  const basePrice = pkg.price * travelers;

  const tour = await CustomizedTour.create({
    user_id: req.user._id,
    tour_package_id: pkg._id,
    destination_id: pkg.destination_id,
    travelers,
    travel_date,
    activities,
    hotel: { category: DEFAULT_HOTEL_CATEGORY, price: defaultHotelPrice },
    transportation: { type: DEFAULT_TRANSPORTATION_TYPE, price: defaultTransportationPrice },
    base_price: basePrice,
    hotel_price: defaultHotelPrice,
    transportation_price: defaultTransportationPrice,
    total_price: basePrice + defaultHotelPrice + defaultTransportationPrice,
  });

  await populated(tour);
  res.status(201).json({ customizedTour: tour });
};

// GET /api/customized-tours
const listMyCustomizedTours = async (req, res) => {
  const tours = await CustomizedTour.find({ user_id: req.user._id })
    .sort({ updated_at: -1 })
    .populate('destination_id')
    .populate('tour_package_id', 'title image_url duration_days')
    .populate('activities.activity_id');
  res.json({ customizedTours: tours });
};

// GET /api/customized-tours/:id
const getCustomizedTour = async (req, res) => {
  const tour = await loadOwnedTour(req, res);
  if (!tour) return;
  await populated(tour);
  res.json({ customizedTour: tour });
};

// PATCH /api/customized-tours/:id
const updateTripDetails = async (req, res) => {
  const tour = await loadOwnedTour(req, res);
  if (!tour) return;
  if (tour.status !== 'draft') {
    return res.status(409).json({ message: 'Only draft trips can be edited' });
  }

  const { travelers, travel_date } = req.body;
  if (travelers != null) {
    const pkg = await TourPackage.findById(tour.tour_package_id, 'price');
    tour.travelers = travelers;
    tour.base_price = (pkg?.price || 0) * travelers;
  }
  if (travel_date != null) tour.travel_date = travel_date;

  recomputeTotals(tour);
  await tour.save();
  await populated(tour);
  res.json({ customizedTour: tour });
};

// POST /api/customized-tours/:id/activities
const addActivity = async (req, res) => {
  const tour = await loadOwnedTour(req, res);
  if (!tour) return;
  if (tour.status !== 'draft') {
    return res.status(409).json({ message: 'Only draft trips can be edited' });
  }

  const { day_number, activity_id, start_time, notes } = req.body;
  if (!day_number || !activity_id) {
    return res.status(400).json({ message: 'day_number and activity_id are required' });
  }

  const activity = await Activity.findById(activity_id);
  if (!activity) return res.status(404).json({ message: 'Activity not found' });

  const sortOrder = tour.activities.filter((a) => a.day_number === day_number).length;
  tour.activities.push({
    day_number,
    activity_id: activity._id,
    price: activity.price,
    start_time,
    notes,
    sort_order: sortOrder,
    source: 'added',
  });

  recomputeTotals(tour);
  await tour.save();
  await populated(tour);
  res.status(201).json({ customizedTour: tour });
};

// DELETE /api/customized-tours/:id/activities/:entryId
const removeActivity = async (req, res) => {
  const tour = await loadOwnedTour(req, res);
  if (!tour) return;
  if (tour.status !== 'draft') {
    return res.status(409).json({ message: 'Only draft trips can be edited' });
  }

  const entry = tour.activities.id(req.params.entryId);
  if (!entry) return res.status(404).json({ message: 'Activity entry not found' });

  if (entry.source === 'package') {
    tour.removed_activity_ids.push(entry.activity_id);
  }
  tour.activities.pull({ _id: req.params.entryId });

  recomputeTotals(tour);
  await tour.save();
  await populated(tour);
  res.json({ customizedTour: tour });
};

// PUT /api/customized-tours/:id/hotel
const selectHotel = async (req, res) => {
  const tour = await loadOwnedTour(req, res);
  if (!tour) return;
  if (tour.status !== 'draft') {
    return res.status(409).json({ message: 'Only draft trips can be edited' });
  }

  const { category } = req.body;
  const pricePerNight = HOTEL_CATEGORY_PRICE_PER_NIGHT[category];
  if (!pricePerNight) {
    return res.status(400).json({ message: 'A valid hotel category is required' });
  }

  const pkg = await TourPackage.findById(tour.tour_package_id, 'duration_days');
  const nights = nightsFor(pkg?.duration_days);

  tour.hotel = { category, price: pricePerNight * nights };
  recomputeTotals(tour);
  await tour.save();
  await populated(tour);
  res.json({ customizedTour: tour });
};

// DELETE /api/customized-tours/:id/hotel
const clearHotel = async (req, res) => {
  const tour = await loadOwnedTour(req, res);
  if (!tour) return;
  if (tour.status !== 'draft') {
    return res.status(409).json({ message: 'Only draft trips can be edited' });
  }

  tour.hotel = undefined;
  recomputeTotals(tour);
  await tour.save();
  await populated(tour);
  res.json({ customizedTour: tour });
};

// PUT /api/customized-tours/:id/transportation
const selectTransportation = async (req, res) => {
  const tour = await loadOwnedTour(req, res);
  if (!tour) return;
  if (tour.status !== 'draft') {
    return res.status(409).json({ message: 'Only draft trips can be edited' });
  }

  const { type } = req.body;
  const price = TRANSPORTATION_TYPE_PRICE[type];
  if (!price) return res.status(400).json({ message: 'A valid transportation type is required' });

  tour.transportation = { type, price };
  recomputeTotals(tour);
  await tour.save();
  await populated(tour);
  res.json({ customizedTour: tour });
};

// DELETE /api/customized-tours/:id/transportation
const clearTransportation = async (req, res) => {
  const tour = await loadOwnedTour(req, res);
  if (!tour) return;
  if (tour.status !== 'draft') {
    return res.status(409).json({ message: 'Only draft trips can be edited' });
  }

  tour.transportation = undefined;
  recomputeTotals(tour);
  await tour.save();
  await populated(tour);
  res.json({ customizedTour: tour });
};

// POST /api/customized-tours/:id/confirm
const confirmCustomizedTour = async (req, res) => {
  const tour = await loadOwnedTour(req, res);
  if (!tour) return;
  if (tour.status !== 'draft') {
    return res.status(409).json({ message: 'This trip has already been confirmed' });
  }

  const pkg = await TourPackage.findById(tour.tour_package_id, 'duration_days');
  const travelEndDate = new Date(tour.travel_date);
  travelEndDate.setDate(travelEndDate.getDate() + (pkg?.duration_days || 1));

  const { lead_traveler_name, lead_traveler_email, lead_traveler_phone, promo_code } = req.body;

  const { total, promotion, discountAmount } = await applyPromotion(promo_code, tour.total_price);

  const booking = await Booking.create({
    user_id: tour.user_id,
    package_id: tour.tour_package_id,
    travel_start_date: tour.travel_date,
    travel_end_date: travelEndDate,
    travelers: tour.travelers,
    total_price: total,
    promo_code: promotion?.code || null,
    discount_amount: discountAmount,
    lead_traveler_name: lead_traveler_name || req.user.name,
    lead_traveler_email: lead_traveler_email || req.user.email,
    lead_traveler_phone: lead_traveler_phone || req.user.phone,
    status: 'pending',
  });

  tour.status = 'confirmed';
  await tour.save();
  await populated(tour);
  await booking.populate({ path: 'package_id', select: 'title image_url duration_days destination_id', populate: { path: 'destination_id' } });

  res.status(201).json({ booking, customizedTour: tour });
};

// PATCH /api/customized-tours/:id/cancel
// Only drafts can be cancelled here — a confirmed customized tour has a
// real Booking backing it, so cancel that booking instead.
const cancelCustomizedTour = async (req, res) => {
  const tour = await loadOwnedTour(req, res);
  if (!tour) return;
  if (tour.status !== 'draft') {
    return res.status(409).json({ message: 'Only draft trips can be cancelled here' });
  }

  tour.status = 'cancelled';
  await tour.save();
  await populated(tour);
  res.json({ customizedTour: tour });
};

module.exports = {
  getOptions,
  createCustomizedTour,
  listMyCustomizedTours,
  getCustomizedTour,
  updateTripDetails,
  addActivity,
  removeActivity,
  selectHotel,
  clearHotel,
  selectTransportation,
  clearTransportation,
  confirmCustomizedTour,
  cancelCustomizedTour,
};
