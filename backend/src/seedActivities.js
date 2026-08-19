// Dev-only script: upserts activities (by name + location) against the
// country-level destinations already in the DB. Idempotent and
// non-destructive — safe to re-run.
require('dotenv').config();
const mongoose = require('mongoose');
const Destination = require('./models/Destination');
const Activity = require('./models/Activity');

const img = (name) =>
  `https://picsum.photos/seed/${encodeURIComponent(name.toLowerCase().replace(/[^a-z0-9]+/g, '-'))}/900/700`;

// [name, location, category, price, duration_minutes]
const ACTIVITIES_BY_COUNTRY = {
  Thailand: [
    ['Grand Palace & Temple Tour', 'Bangkok', 'sightseeing', 25, 180],
    ['Wat Arun Visit', 'Bangkok', 'culture', 10, 90],
    ['Chao Phraya River Cruise', 'Bangkok', 'sightseeing', 30, 120],
    ['Bangkok City Tour', 'Bangkok', 'sightseeing', 35, 240],
    ['Floating Market Tour', 'Bangkok', 'culture', 30, 240],
    ['Thai Cooking Class', 'Bangkok', 'food', 40, 180],
    ['Safari World Bangkok', 'Bangkok', 'entertainment', 45, 300],
    ['Coral Island Tour', 'Pattaya', 'adventure', 40, 300],
    ['Sanctuary of Truth', 'Pattaya', 'culture', 20, 120],
    ['Pattaya City Tour', 'Pattaya', 'sightseeing', 30, 240],
    ['Phi Phi Island Tour', 'Phuket', 'nature', 70, 480],
    ['James Bond Island Tour', 'Phuket', 'adventure', 65, 420],
    ['Phuket Old Town Tour', 'Phuket', 'culture', 25, 180],
    ['Phuket Sunset Cruise', 'Phuket', 'entertainment', 50, 180],
    ['Krabi Four Islands Tour', 'Krabi', 'adventure', 60, 420],
    ['Railay Beach Visit', 'Krabi', 'beach', 30, 240],
    ['Chiang Mai Temple Tour', 'Chiang Mai', 'culture', 30, 240],
    ['Elephant Sanctuary Visit', 'Chiang Mai', 'nature', 60, 300],
  ],
  Malaysia: [
    ['Petronas Twin Towers Visit', 'Kuala Lumpur', 'sightseeing', 25, 120],
    ['Kuala Lumpur City Tour', 'Kuala Lumpur', 'sightseeing', 30, 240],
    ['Batu Caves Tour', 'Kuala Lumpur', 'culture', 20, 180],
    ['KL Tower Visit', 'Kuala Lumpur', 'sightseeing', 20, 120],
    ['Jalan Alor Food Tour', 'Kuala Lumpur', 'food', 30, 180],
    ['Genting Highlands Day Trip', 'Genting Highlands', 'entertainment', 50, 480],
    ['Langkawi Island Hopping', 'Langkawi', 'adventure', 40, 300],
    ['Langkawi Mangrove Tour', 'Langkawi', 'nature', 45, 300],
    ['Langkawi Sunset Cruise', 'Langkawi', 'entertainment', 60, 180],
    ['Sky Bridge Visit', 'Langkawi', 'nature', 25, 180],
    ['Penang Heritage Tour', 'Penang', 'culture', 30, 240],
    ['George Town Food Tour', 'Penang', 'food', 35, 180],
  ],
  Singapore: [
    ['Gardens by the Bay', 'Singapore', 'nature', 25, 180],
    ['Marina Bay City Tour', 'Singapore', 'sightseeing', 30, 180],
    ['Singapore Flyer', 'Singapore', 'sightseeing', 30, 90],
    ['Sentosa Island Tour', 'Singapore', 'entertainment', 40, 360],
    ['Universal Studios Singapore', 'Singapore', 'entertainment', 75, 480],
    ['Singapore River Cruise', 'Singapore', 'sightseeing', 25, 90],
    ['Night Safari', 'Singapore', 'nature', 45, 240],
    ['Singapore Food Tour', 'Singapore', 'food', 35, 180],
  ],
  Indonesia: [
    ['Uluwatu Temple Visit', 'Bali', 'culture', 20, 180],
    ['Bali Swing Experience', 'Bali', 'adventure', 30, 120],
    ['Nusa Penida Island Tour', 'Bali', 'nature', 70, 480],
    ['Tegallalang Rice Terrace', 'Ubud', 'nature', 15, 120],
    ['Ubud Palace Visit', 'Ubud', 'culture', 10, 90],
    ['Bali Cooking Class', 'Ubud', 'food', 40, 180],
    ['Mount Batur Sunrise Trek', 'Bali', 'adventure', 55, 360],
    ['Bali Sunset Dinner Cruise', 'Bali', 'entertainment', 50, 180],
    ['Kuta Beach Visit', 'Bali', 'beach', 0, 120],
    ['Tanah Lot Temple', 'Bali', 'culture', 15, 150],
  ],
  Maldives: [
    ['Snorkeling Trip', 'Malé', 'adventure', 40, 180],
    ['Dolphin Watching Cruise', 'Malé', 'nature', 50, 180],
    ['Sunset Cruise', 'Malé', 'entertainment', 45, 120],
    ['Island Hopping', 'Malé', 'adventure', 50, 300],
    ['Scuba Diving Experience', 'Malé', 'adventure', 80, 180],
    ['Sandbank Excursion', 'Malé', 'beach', 60, 240],
    ['Maafushi Island Tour', 'Maafushi', 'sightseeing', 40, 300],
  ],
  'Sri Lanka': [
    ['Colombo City Tour', 'Colombo', 'sightseeing', 30, 240],
    ['Temple of the Tooth Visit', 'Kandy', 'culture', 15, 120],
    ['Kandy Cultural Dance Show', 'Kandy', 'culture', 20, 120],
    ['Ella Train Ride', 'Ella', 'nature', 25, 300],
    ['Nine Arches Bridge Visit', 'Ella', 'nature', 10, 120],
    ['Tea Plantation Tour', 'Nuwara Eliya', 'culture', 20, 180],
    ['Galle Fort Tour', 'Galle', 'culture', 20, 180],
    ['Yala Safari', 'Yala', 'nature', 60, 360],
  ],
  India: [
    ['Taj Mahal Visit', 'Agra', 'culture', 25, 180],
    ['Jaipur City Palace', 'Jaipur', 'culture', 15, 120],
    ['Amber Fort Tour', 'Jaipur', 'culture', 20, 180],
    ['Delhi City Tour', 'Delhi', 'sightseeing', 30, 300],
    ['Goa Beach Tour', 'Goa', 'beach', 20, 240],
    ['Goa Sunset Cruise', 'Goa', 'entertainment', 35, 180],
    ['Kerala Backwater Cruise', 'Kerala', 'nature', 50, 300],
    ['Kashmir Gulmarg Tour', 'Kashmir', 'nature', 40, 360],
    ['Manali Adventure Tour', 'Manali', 'adventure', 45, 300],
  ],
  Japan: [
    ['Tokyo City Tour', 'Tokyo', 'sightseeing', 50, 360],
    ['Mount Fuji Day Trip', 'Tokyo', 'nature', 80, 600],
    ['Shibuya Walking Tour', 'Tokyo', 'sightseeing', 20, 150],
    ['Kyoto Temple Tour', 'Kyoto', 'culture', 40, 300],
    ['Arashiyama Bamboo Forest', 'Kyoto', 'nature', 20, 180],
    ['Osaka Castle Visit', 'Osaka', 'culture', 15, 120],
    ['Osaka Food Tour', 'Osaka', 'food', 40, 180],
  ],
  'South Korea': [
    ['Seoul City Tour', 'Seoul', 'sightseeing', 40, 300],
    ['Gyeongbokgung Palace', 'Seoul', 'culture', 15, 120],
    ['N Seoul Tower', 'Seoul', 'sightseeing', 20, 120],
    ['Korean Cooking Class', 'Seoul', 'food', 45, 180],
    ['Busan Coastal Tour', 'Busan', 'nature', 40, 300],
    ['Jeju Island Tour', 'Jeju Island', 'nature', 60, 360],
    ['Jeju Waterfall Tour', 'Jeju Island', 'nature', 30, 240],
  ],
  Turkey: [
    ['Istanbul City Tour', 'Istanbul', 'sightseeing', 40, 300],
    ['Hagia Sophia Visit', 'Istanbul', 'culture', 20, 120],
    ['Bosphorus Cruise', 'Istanbul', 'sightseeing', 30, 180],
    ['Grand Bazaar Tour', 'Istanbul', 'shopping', 20, 180],
    ['Cappadocia Hot Air Balloon', 'Cappadocia', 'adventure', 200, 180],
    ['Cappadocia Valley Tour', 'Cappadocia', 'nature', 50, 300],
    ['Pamukkale Tour', 'Pamukkale', 'nature', 50, 360],
    ['Antalya Old Town Tour', 'Antalya', 'culture', 25, 180],
    ['Antalya Boat Trip', 'Antalya', 'beach', 45, 300],
  ],
  'United Arab Emirates': [
    ['Burj Khalifa Visit', 'Dubai', 'sightseeing', 50, 120],
    ['Dubai City Tour', 'Dubai', 'sightseeing', 40, 300],
    ['Desert Safari', 'Dubai', 'adventure', 60, 360],
    ['Dubai Marina Cruise', 'Dubai', 'entertainment', 45, 120],
    ['Dubai Mall & Downtown Tour', 'Dubai', 'shopping', 25, 180],
    ['Abu Dhabi City Tour', 'Abu Dhabi', 'sightseeing', 50, 360],
    ['Sheikh Zayed Grand Mosque', 'Abu Dhabi', 'culture', 20, 150],
    ['Ferrari World Visit', 'Abu Dhabi', 'entertainment', 80, 360],
  ],
  France: [
    ['Eiffel Tower Visit', 'Paris', 'sightseeing', 35, 150],
    ['Louvre Museum Tour', 'Paris', 'culture', 30, 180],
    ['Paris City Tour', 'Paris', 'sightseeing', 45, 300],
    ['Seine River Cruise', 'Paris', 'entertainment', 25, 120],
    ['Versailles Palace Tour', 'Paris', 'culture', 40, 300],
    ['French Food Tour', 'Paris', 'food', 50, 180],
    ['Nice Old Town Tour', 'Nice', 'culture', 25, 180],
    ['French Riviera Tour', 'Nice', 'beach', 50, 360],
  ],
  Italy: [
    ['Colosseum Tour', 'Rome', 'culture', 35, 180],
    ['Vatican Museums Tour', 'Rome', 'culture', 40, 180],
    ['Rome City Tour', 'Rome', 'sightseeing', 45, 300],
    ['Venice Gondola Ride', 'Venice', 'entertainment', 50, 90],
    ['Venice Walking Tour', 'Venice', 'sightseeing', 25, 180],
    ['Milan Duomo Visit', 'Milan', 'culture', 25, 120],
    ['Florence Walking Tour', 'Florence', 'culture', 30, 180],
    ['Amalfi Coast Tour', 'Amalfi Coast', 'nature', 60, 480],
  ],
  Switzerland: [
    ['Jungfraujoch Day Trip', 'Interlaken', 'nature', 120, 480],
    ['Interlaken City Tour', 'Interlaken', 'sightseeing', 25, 180],
    ['Mount Titlis Tour', 'Lucerne', 'nature', 100, 360],
    ['Lucerne City Tour', 'Lucerne', 'sightseeing', 30, 180],
    ['Rhine Falls Tour', 'Zurich', 'nature', 50, 300],
    ['Swiss Alps Scenic Train', 'Zurich', 'nature', 90, 360],
  ],
  Greece: [
    ['Santorini Sunset Tour', 'Santorini', 'sightseeing', 45, 180],
    ['Santorini Caldera Cruise', 'Santorini', 'entertainment', 70, 300],
    ['Santorini Island Tour', 'Santorini', 'sightseeing', 40, 300],
    ['Acropolis Tour', 'Athens', 'culture', 30, 180],
    ['Athens City Tour', 'Athens', 'sightseeing', 40, 300],
    ['Mykonos Island Tour', 'Mykonos', 'beach', 50, 300],
  ],
  Australia: [
    ['Sydney Opera House Tour', 'Sydney', 'culture', 30, 120],
    ['Sydney Harbour Cruise', 'Sydney', 'sightseeing', 45, 150],
    ['Sydney City Tour', 'Sydney', 'sightseeing', 40, 300],
    ['Bondi Beach Visit', 'Sydney', 'beach', 0, 180],
    ['Great Ocean Road Tour', 'Melbourne', 'nature', 70, 600],
    ['Gold Coast Theme Park', 'Gold Coast', 'entertainment', 80, 480],
  ],
  Egypt: [
    ['Pyramids of Giza Tour', 'Cairo', 'culture', 35, 240],
    ['Egyptian Museum Tour', 'Cairo', 'culture', 25, 180],
    ['Cairo City Tour', 'Cairo', 'sightseeing', 35, 300],
    ['Nile River Cruise', 'Cairo', 'entertainment', 50, 180],
    ['Red Sea Snorkeling', 'Sharm El Sheikh', 'adventure', 50, 300],
    ['Desert Safari', 'Sharm El Sheikh', 'adventure', 45, 300],
  ],
};

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected. Upserting activities...');

  let created = 0;
  let updated = 0;
  let skipped = 0;

  for (const [countryName, activities] of Object.entries(ACTIVITIES_BY_COUNTRY)) {
    const destination = await Destination.findOne({ name: countryName });
    if (!destination) {
      console.warn(`Skipping ${activities.length} activities — destination "${countryName}" not found.`);
      skipped += activities.length;
      continue;
    }

    for (const [name, location, category, price, duration_minutes] of activities) {
      const res = await Activity.updateOne(
        { name, location },
        {
          $set: {
            destination_id: destination._id,
            category,
            price,
            duration_minutes,
            status: 'active',
          },
          $setOnInsert: { image_url: img(`${name}-${location}`) },
        },
        { upsert: true }
      );
      if (res.upsertedCount) created += 1;
      else updated += 1;
    }
  }

  console.log(`Done. Created ${created}, updated ${updated}, skipped ${skipped}.`);
  await mongoose.disconnect();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
