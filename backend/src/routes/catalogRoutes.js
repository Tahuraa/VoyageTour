const express = require('express');
const asyncHandler = require('../middleware/asyncHandler');
const { getDestinations, getDestinationById } = require('../controllers/destinationController');
const { getPackages, getPackageById } = require('../controllers/packageController');
const { getActivePromotions } = require('../controllers/promotionController');
const { getActivities } = require('../controllers/activityController');

const router = express.Router();

router.get('/destinations', asyncHandler(getDestinations));
router.get('/destinations/:id', asyncHandler(getDestinationById));
router.get('/packages', asyncHandler(getPackages));
router.get('/packages/:id', asyncHandler(getPackageById));
router.get('/promotions/active', asyncHandler(getActivePromotions));
router.get('/activities', asyncHandler(getActivities));

module.exports = router;
