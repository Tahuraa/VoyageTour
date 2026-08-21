const express = require('express');
const asyncHandler = require('../middleware/asyncHandler');
const { protect } = require('../middleware/auth');
const { listFavorites, listFavoriteIds, toggleFavorite } = require('../controllers/favoriteController');

const router = express.Router();

router.use(asyncHandler(protect));
router.get('/', asyncHandler(listFavorites));
router.get('/ids', asyncHandler(listFavoriteIds));
router.post('/toggle', asyncHandler(toggleFavorite));

module.exports = router;
