// Preset pricing tiers for trip customization. The CustomizedTour schema
// stores hotel/transportation as free-standing snapshots (name/price/category
// or type), not references into the Hotel/Transportation collections — those
// catalogs are shaped for a different purpose (per-destination listings) and
// don't match this schema's fields. Pricing lives on the server so the
// client can't dictate its own total.

const HOTEL_CATEGORY_PRICE_PER_NIGHT = {
  '3_star': 60,
  '4_star': 100,
  '5_star': 160,
};

const TRANSPORTATION_TYPE_PRICE = {
  shared_shuttle: 40,
  tour_bus: 55,
  private_car: 90,
};

// Every new customized tour starts with these pre-selected, so the user
// always sees a complete price rather than an empty "Add" state.
const DEFAULT_HOTEL_CATEGORY = '3_star';
const DEFAULT_TRANSPORTATION_TYPE = 'private_car';

module.exports = {
  HOTEL_CATEGORY_PRICE_PER_NIGHT,
  TRANSPORTATION_TYPE_PRICE,
  DEFAULT_HOTEL_CATEGORY,
  DEFAULT_TRANSPORTATION_TYPE,
};
