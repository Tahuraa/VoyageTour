const Destination = require('../models/Destination');
const TourPackage = require('../models/TourPackage');
const Review = require('../models/Review');

const round1 = (n) => Math.round(n * 10) / 10;

const withRatings = async (destinations) =>
  Promise.all(
    destinations.map(async (d) => {
      const packages = await TourPackage.find({ destination_id: d._id }, '_id').lean();
      const packageIds = packages.map((p) => p._id);
      const reviews = packageIds.length
        ? await Review.find({ package_id: { $in: packageIds } }, 'rating').lean()
        : [];
      const rating_avg = reviews.length
        ? round1(reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length)
        : null;
      return { ...d, rating_avg, review_count: reviews.length, package_count: packageIds.length };
    })
  );

// GET /api/destinations
const getDestinations = async (req, res) => {
  const filter = { status: 'active' };
  if (req.query.featured === 'true') filter.is_featured = true;

  const destinations = await Destination.find(filter).sort({ name: 1 }).lean();
  res.json({ destinations: await withRatings(destinations) });
};

// GET /api/destinations/:id
const getDestinationById = async (req, res) => {
  const destination = await Destination.findOne({ _id: req.params.id, status: 'active' }).lean();
  if (!destination) return res.status(404).json({ message: 'Destination not found' });

  const [withRating] = await withRatings([destination]);
  res.json({ destination: withRating });
};

module.exports = { getDestinations, getDestinationById };
