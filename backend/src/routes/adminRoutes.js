const express = require('express');
const asyncHandler = require('../middleware/asyncHandler');
const { protect, adminOnly } = require('../middleware/auth');
const { getStats, listUsers, listBookings, updateBookingStatus } = require('../controllers/adminController');
const {
  listDestinations, createDestination, updateDestination, deleteDestination,
  listActivities, createActivity, updateActivity, deleteActivity,
  listPackages, createPackage, updatePackage, deletePackage,
} = require('../controllers/adminCatalogController');
const {
  listPromotions, createPromotion, updatePromotion, deletePromotion,
} = require('../controllers/promotionController');

const router = express.Router();

router.use(asyncHandler(protect), adminOnly);

router.get('/stats', asyncHandler(getStats));

router.get('/users', asyncHandler(listUsers));

router.get('/bookings', asyncHandler(listBookings));
router.patch('/bookings/:id/status', asyncHandler(updateBookingStatus));

router.get('/destinations', asyncHandler(listDestinations));
router.post('/destinations', asyncHandler(createDestination));
router.put('/destinations/:id', asyncHandler(updateDestination));
router.delete('/destinations/:id', asyncHandler(deleteDestination));

router.get('/activities', asyncHandler(listActivities));
router.post('/activities', asyncHandler(createActivity));
router.put('/activities/:id', asyncHandler(updateActivity));
router.delete('/activities/:id', asyncHandler(deleteActivity));

router.get('/packages', asyncHandler(listPackages));
router.post('/packages', asyncHandler(createPackage));
router.put('/packages/:id', asyncHandler(updatePackage));
router.delete('/packages/:id', asyncHandler(deletePackage));

router.get('/promotions', asyncHandler(listPromotions));
router.post('/promotions', asyncHandler(createPromotion));
router.put('/promotions/:id', asyncHandler(updatePromotion));
router.delete('/promotions/:id', asyncHandler(deletePromotion));

module.exports = router;
