const mongoose = require('mongoose');
const Destination = require('../models/Destination');
const Activity = require('../models/Activity');
const TourPackage = require('../models/TourPackage');
const Booking = require('../models/Booking');
const CustomizedTour = require('../models/CustomizedTour');

const isValidId = (id) => mongoose.isValidObjectId(id);

// ---------- Destinations ----------

const listDestinations = async (req, res) => {
  const destinations = await Destination.find().sort({ name: 1 });
  res.json({ destinations });
};

const createDestination = async (req, res) => {
  const { name, country, country_code, description, image_url, is_featured, status } = req.body;
  if (!name || !country || !country_code) {
    return res.status(400).json({ message: 'name, country and country_code are required' });
  }
  const destination = await Destination.create({ name, country, country_code, description, image_url, is_featured, status });
  res.status(201).json({ destination });
};

const updateDestination = async (req, res) => {
  if (!isValidId(req.params.id)) return res.status(404).json({ message: 'Destination not found' });
  const { name, country, country_code, description, image_url, is_featured, status } = req.body;
  const destination = await Destination.findByIdAndUpdate(
    req.params.id,
    { name, country, country_code, description, image_url, is_featured, status },
    { new: true, runValidators: true, omitUndefined: true }
  );
  if (!destination) return res.status(404).json({ message: 'Destination not found' });
  res.json({ destination });
};

const deleteDestination = async (req, res) => {
  if (!isValidId(req.params.id)) return res.status(404).json({ message: 'Destination not found' });
  const [activityCount, packageCount] = await Promise.all([
    Activity.countDocuments({ destination_id: req.params.id }),
    TourPackage.countDocuments({ destination_id: req.params.id }),
  ]);
  if (activityCount > 0 || packageCount > 0) {
    return res.status(409).json({
      message: `Cannot delete: ${packageCount} package(s) and ${activityCount} activity/activities still reference this destination. Deactivate it instead.`,
    });
  }
  const destination = await Destination.findByIdAndDelete(req.params.id);
  if (!destination) return res.status(404).json({ message: 'Destination not found' });
  res.json({ message: 'Destination deleted' });
};

// ---------- Activities ----------

const listActivities = async (req, res) => {
  const match = {};
  if (req.query.destination_id) match.destination_id = req.query.destination_id;
  const activities = await Activity.find(match).sort({ name: 1 }).populate('destination_id', 'name country');
  res.json({ activities });
};

const createActivity = async (req, res) => {
  const { destination_id, name, location, description, duration_minutes, price, category, image_url } = req.body;
  if (!destination_id || !name || !location || !category) {
    return res.status(400).json({ message: 'destination_id, name, location and category are required' });
  }
  const activity = await Activity.create({
    destination_id, name, location, description, duration_minutes, price, category, image_url,
  });
  await activity.populate('destination_id', 'name country');
  res.status(201).json({ activity });
};

const updateActivity = async (req, res) => {
  if (!isValidId(req.params.id)) return res.status(404).json({ message: 'Activity not found' });
  const { destination_id, name, location, description, duration_minutes, price, category, image_url, status } = req.body;
  const activity = await Activity.findByIdAndUpdate(
    req.params.id,
    { destination_id, name, location, description, duration_minutes, price, category, image_url, status },
    { new: true, runValidators: true, omitUndefined: true }
  );
  if (!activity) return res.status(404).json({ message: 'Activity not found' });
  await activity.populate('destination_id', 'name country');
  res.json({ activity });
};

const deleteActivity = async (req, res) => {
  if (!isValidId(req.params.id)) return res.status(404).json({ message: 'Activity not found' });
  const [inPackages, inCustomizedTours] = await Promise.all([
    TourPackage.countDocuments({ 'itinerary.activities.activity_id': req.params.id }),
    CustomizedTour.countDocuments({ 'activities.activity_id': req.params.id }),
  ]);
  if (inPackages > 0 || inCustomizedTours > 0) {
    return res.status(409).json({
      message: 'Cannot delete: this activity is used in one or more tour package itineraries or customized trips. Deactivate it instead.',
    });
  }
  const activity = await Activity.findByIdAndDelete(req.params.id);
  if (!activity) return res.status(404).json({ message: 'Activity not found' });
  res.json({ message: 'Activity deleted' });
};

// ---------- Tour Packages (core fields — itinerary editing is not supported here) ----------

const PACKAGE_POPULATE = [
  { path: 'destination_id', select: 'name country' },
  { path: 'itinerary.activities.activity_id', select: 'name price category location duration_minutes' },
];

const listPackages = async (req, res) => {
  const packages = await TourPackage.find().sort({ title: 1 }).populate(PACKAGE_POPULATE);
  res.json({ packages });
};

const createPackage = async (req, res) => {
  const { destination_id, title, description, price, duration_days, max_people, image_url, category, included_services, itinerary } = req.body;
  if (!destination_id || !title || price == null || !duration_days || !max_people || !category) {
    return res.status(400).json({
      message: 'destination_id, title, price, duration_days, max_people and category are required',
    });
  }
  const pkg = await TourPackage.create({
    destination_id, title, description, price, duration_days, max_people, image_url, category,
    included_services: included_services || [],
    itinerary: itinerary || [],
  });
  await pkg.populate(PACKAGE_POPULATE);
  res.status(201).json({ package: pkg });
};

const updatePackage = async (req, res) => {
  if (!isValidId(req.params.id)) return res.status(404).json({ message: 'Package not found' });
  const { destination_id, title, description, price, duration_days, max_people, image_url, category, included_services, status, itinerary } = req.body;
  const pkg = await TourPackage.findByIdAndUpdate(
    req.params.id,
    { destination_id, title, description, price, duration_days, max_people, image_url, category, included_services, status, itinerary },
    { new: true, runValidators: true, omitUndefined: true }
  );
  if (!pkg) return res.status(404).json({ message: 'Package not found' });
  await pkg.populate(PACKAGE_POPULATE);
  res.json({ package: pkg });
};

const deletePackage = async (req, res) => {
  if (!isValidId(req.params.id)) return res.status(404).json({ message: 'Package not found' });
  const [inBookings, inCustomizedTours] = await Promise.all([
    Booking.countDocuments({ package_id: req.params.id }),
    CustomizedTour.countDocuments({ tour_package_id: req.params.id }),
  ]);
  if (inBookings > 0 || inCustomizedTours > 0) {
    return res.status(409).json({
      message: 'Cannot delete: this package has existing bookings or customized trips. Deactivate it instead.',
    });
  }
  const pkg = await TourPackage.findByIdAndDelete(req.params.id);
  if (!pkg) return res.status(404).json({ message: 'Package not found' });
  res.json({ message: 'Package deleted' });
};

module.exports = {
  listDestinations, createDestination, updateDestination, deleteDestination,
  listActivities, createActivity, updateActivity, deleteActivity,
  listPackages, createPackage, updatePackage, deletePackage,
};
