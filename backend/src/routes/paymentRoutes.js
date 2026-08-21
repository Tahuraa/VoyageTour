const express = require('express');
const asyncHandler = require('../middleware/asyncHandler');
const { protect } = require('../middleware/auth');
const { getConfig, createPaymentIntent, confirmPayment } = require('../controllers/paymentController');

const router = express.Router();

router.get('/config', asyncHandler(getConfig));

router.use(asyncHandler(protect));
router.post('/create-intent', asyncHandler(createPaymentIntent));
router.post('/confirm', asyncHandler(confirmPayment));

module.exports = router;
