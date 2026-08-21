const express = require('express');
const asyncHandler = require('../middleware/asyncHandler');
const { protect } = require('../middleware/auth');
const {
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
} = require('../controllers/customizedTourController');

const router = express.Router();

router.get('/options', asyncHandler(getOptions));

router.use(asyncHandler(protect));
router.post('/', asyncHandler(createCustomizedTour));
router.get('/', asyncHandler(listMyCustomizedTours));
router.get('/:id', asyncHandler(getCustomizedTour));
router.patch('/:id', asyncHandler(updateTripDetails));
router.post('/:id/activities', asyncHandler(addActivity));
router.delete('/:id/activities/:entryId', asyncHandler(removeActivity));
router.put('/:id/hotel', asyncHandler(selectHotel));
router.delete('/:id/hotel', asyncHandler(clearHotel));
router.put('/:id/transportation', asyncHandler(selectTransportation));
router.delete('/:id/transportation', asyncHandler(clearTransportation));
router.post('/:id/confirm', asyncHandler(confirmCustomizedTour));
router.patch('/:id/cancel', asyncHandler(cancelCustomizedTour));

module.exports = router;
