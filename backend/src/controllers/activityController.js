const Activity = require('../models/Activity');

// GET /api/activities?destination_id=...
const getActivities = async (req, res) => {
  const { destination_id } = req.query;
  const filter = { status: 'active' };
  if (destination_id) filter.destination_id = destination_id;

  const activities = await Activity.find(filter).sort({ name: 1 });
  res.json({ activities });
};

module.exports = { getActivities };
