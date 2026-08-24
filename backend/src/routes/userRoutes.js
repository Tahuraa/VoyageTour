const express = require('express');
const asyncHandler = require('../middleware/asyncHandler');
const { protect } = require('../middleware/auth');
const upload = require('../middleware/upload');
const { getMe, updateMe, updateMyPhoto, changeMyPassword, deleteMe } = require('../controllers/userController');

const router = express.Router();

router.use(asyncHandler(protect));
router.get('/me', asyncHandler(getMe));
router.put('/me', asyncHandler(updateMe));
router.post('/me/photo', upload.single('photo'), asyncHandler(updateMyPhoto));
router.put('/me/password', asyncHandler(changeMyPassword));
router.delete('/me', asyncHandler(deleteMe));

module.exports = router;
