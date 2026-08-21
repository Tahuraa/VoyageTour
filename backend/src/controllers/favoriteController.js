const mongoose = require('mongoose');
const Favorite = require('../models/Favorite');
const TourPackage = require('../models/TourPackage');
require('../models/Activity'); // registers the 'Activity' schema for itinerary.activities.activity_id populate

const VALID_TYPES = ['package', 'hotel', 'destination'];

// GET /api/favorites?type=package
const listFavorites = async (req, res) => {
  const type = VALID_TYPES.includes(req.query.type) ? req.query.type : 'package';
  const favorites = await Favorite.find({ user_id: req.user._id, type }).sort({ created_at: -1 }).lean();

  if (type !== 'package') {
    return res.json({ favorites: favorites.map((f) => ({ favorite_id: f._id, reference_id: f.reference_id })) });
  }

  const packageIds = favorites.map((f) => f.reference_id);
  const packages = await TourPackage.find({ _id: { $in: packageIds } })
    .populate('destination_id')
    .populate('itinerary.activities.activity_id')
    .lean();
  const byId = new Map(packages.map((p) => [String(p._id), p]));

  const results = favorites
    .map((f) => {
      const pkg = byId.get(String(f.reference_id));
      if (!pkg) return null;
      const { destination_id, ...rest } = pkg;
      return { favorite_id: f._id, package: { ...rest, destination: destination_id } };
    })
    .filter(Boolean);

  res.json({ favorites: results });
};

// GET /api/favorites/ids?type=package
const listFavoriteIds = async (req, res) => {
  const type = VALID_TYPES.includes(req.query.type) ? req.query.type : 'package';
  const favorites = await Favorite.find({ user_id: req.user._id, type }, 'reference_id').lean();
  res.json({ ids: favorites.map((f) => String(f.reference_id)) });
};

// POST /api/favorites/toggle
// body: { type, reference_id }
const toggleFavorite = async (req, res) => {
  const { type, reference_id } = req.body;
  if (!VALID_TYPES.includes(type) || !mongoose.isValidObjectId(reference_id)) {
    return res.status(400).json({ message: 'A valid type and reference_id are required' });
  }

  const existing = await Favorite.findOne({ user_id: req.user._id, type, reference_id });
  if (existing) {
    await existing.deleteOne();
    return res.json({ favorited: false });
  }

  await Favorite.create({ user_id: req.user._id, type, reference_id });
  res.json({ favorited: true });
};

module.exports = { listFavorites, listFavoriteIds, toggleFavorite };
