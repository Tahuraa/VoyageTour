const mongoose = require('mongoose');
const TourPackage = require('../models/TourPackage');
const Review = require('../models/Review');
require('../models/Activity'); // registers the 'Activity' schema for itinerary.activities.activity_id populate

const SORT_MAP = {
  price_asc: { price: 1 },
  price_desc: { price: -1 },
  rating: { rating_avg: -1, review_count: -1 },
  popularity: { popularity: -1, rating_avg: -1 },
};

const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// GET /api/packages
// Query params: q, destinations (comma-separated, matched with OR), category,
// minPrice, maxPrice, startDate, endDate, sort, page, limit
const getPackages = async (req, res) => {
  const { q, destinations, category, minPrice, maxPrice, startDate, endDate, sort } = req.query;
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 50);

  const destinationTerms = destinations
    ? String(destinations).split(',').map((d) => d.trim()).filter(Boolean)
    : [];

  const match = { status: 'active' };
  if (category) match.category = category;
  if (minPrice || maxPrice) {
    match.price = {};
    if (minPrice) match.price.$gte = Number(minPrice);
    if (maxPrice) match.price.$lte = Number(maxPrice);
  }
  if (startDate && endDate) {
    const tripDays = Math.round(
      (new Date(endDate).getTime() - new Date(startDate).getTime()) / (1000 * 60 * 60 * 24)
    );
    if (tripDays > 0) match.duration_days = { $lte: tripDays };
  }

  const pipeline = [
    { $match: match },
    { $lookup: { from: 'destinations', localField: 'destination_id', foreignField: '_id', as: 'destination' } },
    { $unwind: '$destination' },
  ];

  if (destinationTerms.length) {
    const pattern = destinationTerms.map(escapeRegExp).join('|');
    pipeline.push({
      $match: {
        $or: [
          { title: { $regex: pattern, $options: 'i' } },
          { 'destination.name': { $regex: pattern, $options: 'i' } },
          { 'destination.country': { $regex: pattern, $options: 'i' } },
        ],
      },
    });
  } else if (q) {
    pipeline.push({
      $match: {
        $or: [
          { title: { $regex: q, $options: 'i' } },
          { 'destination.name': { $regex: q, $options: 'i' } },
          { 'destination.country': { $regex: q, $options: 'i' } },
        ],
      },
    });
  }

  pipeline.push(
    { $lookup: { from: 'reviews', localField: '_id', foreignField: 'package_id', as: 'reviews' } },
    { $lookup: { from: 'bookings', localField: '_id', foreignField: 'package_id', as: 'bookings' } },
    {
      $addFields: {
        rating_avg: {
          $cond: [
            { $gt: [{ $size: '$reviews' }, 0] },
            { $round: [{ $avg: '$reviews.rating' }, 1] },
            null,
          ],
        },
        review_count: { $size: '$reviews' },
        popularity: { $size: '$bookings' },
      },
    },
    { $project: { reviews: 0, bookings: 0, itinerary: 0, included_services: 0 } },
    { $sort: SORT_MAP[sort] || SORT_MAP.popularity },
    { $skip: (page - 1) * limit },
    { $limit: limit }
  );

  const packages = await TourPackage.aggregate(pipeline);
  res.json({ packages, page, limit });
};

// GET /api/packages/:id
const getPackageById = async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(404).json({ message: 'Package not found' });
  }

  const pkg = await TourPackage.findOne({ _id: req.params.id, status: 'active' })
    .populate('destination_id')
    .populate('itinerary.activities.activity_id')
    .lean();
  if (!pkg) return res.status(404).json({ message: 'Package not found' });

  const reviews = await Review.find({ package_id: pkg._id }, 'rating').lean();
  const rating_avg = reviews.length
    ? Math.round((reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length) * 10) / 10
    : null;

  const { destination_id, ...rest } = pkg;
  res.json({
    package: { ...rest, destination: destination_id, rating_avg, review_count: reviews.length },
  });
};

module.exports = { getPackages, getPackageById };
