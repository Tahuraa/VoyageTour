const express = require('express');
const asyncHandler = require('../middleware/asyncHandler');
const { protect } = require('../middleware/auth');
const { createBooking, listMyBookings, getBooking, cancelBooking } = require('../controllers/bookingController');

const router = express.Router();

router.use(asyncHandler(protect));
router.post('/', asyncHandler(createBooking));
router.get('/', asyncHandler(listMyBookings));
router.get('/:id', asyncHandler(getBooking));
router.patch('/:id/cancel', asyncHandler(cancelBooking));

module.exports = router;
