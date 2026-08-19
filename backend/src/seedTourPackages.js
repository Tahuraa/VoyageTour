// Dev-only script: upserts 20 tour packages (by title), each itinerary day
// resolving its real activities against the Activity collection seeded by
// seedActivities.js. Logistics items (airport transfers, hotel check-in,
// free time, shopping) are NOT activities — they stay as day description
// text only, per the "activities only live in itinerary, transfers/
// breakfast/etc. live in included_services" rule. Idempotent and
// non-destructive — safe to re-run.
require('dotenv').config();
const mongoose = require('mongoose');
const Destination = require('./models/Destination');
const Activity = require('./models/Activity');
const TourPackage = require('./models/TourPackage');

const img = (title) =>
  `https://picsum.photos/seed/${encodeURIComponent(title.toLowerCase().replace(/[^a-z0-9]+/g, '-'))}/900/700`;

const DEFAULT_INCLUDED_SERVICES = [
  'Airport transfers',
  'Hotel accommodation',
  'Daily breakfast',
  'Intercity transportation',
  'Selected activities',
];

// day(number, title, description, activityRefs) — activityRefs: [name, location][]
const day = (day_number, title, description, activityRefs = []) => ({
  day_number,
  title,
  description,
  activityRefs,
});

const PACKAGES = [
  {
    title: 'Thailand Highlights',
    country: 'Thailand',
    price: 650,
    duration_days: 7,
    max_people: 10,
    category: 'cultural',
    description: 'A complete introduction to Thailand, from Bangkok’s temples and canals to the beach town of Pattaya.',
    itinerary: [
      day(1, 'Arrival in Bangkok', 'Airport pickup and hotel check-in in Bangkok.'),
      day(2, 'Bangkok', 'A full day of Bangkok’s landmark sights.', [
        ['Grand Palace & Temple Tour', 'Bangkok'],
        ['Wat Arun Visit', 'Bangkok'],
        ['Chao Phraya River Cruise', 'Bangkok'],
      ]),
      day(3, 'Bangkok', 'Markets and a hands-on Thai cooking class.', [
        ['Floating Market Tour', 'Bangkok'],
        ['Thai Cooking Class', 'Bangkok'],
      ]),
      day(4, 'Bangkok → Pattaya', 'Transfer to Pattaya, then a city tour.', [
        ['Pattaya City Tour', 'Pattaya'],
      ]),
      day(5, 'Pattaya', 'Island hopping and a visit to the Sanctuary of Truth.', [
        ['Coral Island Tour', 'Pattaya'],
        ['Sanctuary of Truth', 'Pattaya'],
      ]),
      day(6, 'Pattaya → Bangkok', 'Free morning, then transfer back to Bangkok for a city tour.', [
        ['Bangkok City Tour', 'Bangkok'],
      ]),
      day(7, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Thailand Beach Escape',
    country: 'Thailand',
    price: 720,
    duration_days: 6,
    max_people: 8,
    category: 'beach',
    description: 'Island hopping and beach time based in Phuket.',
    itinerary: [
      day(1, 'Arrival in Phuket', 'Airport pickup and hotel check-in in Phuket.'),
      day(2, 'Phuket', 'A boat tour of the Phi Phi Islands.', [['Phi Phi Island Tour', 'Phuket']]),
      day(3, 'Phuket', 'James Bond Island and Phuket’s old town.', [
        ['James Bond Island Tour', 'Phuket'],
        ['Phuket Old Town Tour', 'Phuket'],
      ]),
      day(4, 'Phuket', 'A full day at leisure on Phuket’s beaches.'),
      day(5, 'Phuket', 'An evening sunset cruise.', [['Phuket Sunset Cruise', 'Phuket']]),
      day(6, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Bangkok & Pattaya Explorer',
    country: 'Thailand',
    price: 480,
    duration_days: 5,
    max_people: 10,
    category: 'city',
    description: 'A short city break covering Bangkok’s temples and Pattaya’s islands.',
    itinerary: [
      day(1, 'Arrival in Bangkok', 'Airport pickup and hotel check-in in Bangkok.'),
      day(2, 'Bangkok', 'The Grand Palace and Wat Arun.', [
        ['Grand Palace & Temple Tour', 'Bangkok'],
        ['Wat Arun Visit', 'Bangkok'],
      ]),
      day(3, 'Bangkok → Pattaya', 'Transfer to Pattaya, then a boat trip to Coral Island.', [
        ['Coral Island Tour', 'Pattaya'],
      ]),
      day(4, 'Pattaya', 'The Sanctuary of Truth and a Pattaya city tour.', [
        ['Sanctuary of Truth', 'Pattaya'],
        ['Pattaya City Tour', 'Pattaya'],
      ]),
      day(5, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Malaysia Highlights',
    country: 'Malaysia',
    price: 580,
    duration_days: 6,
    max_people: 10,
    category: 'city',
    description: 'Kuala Lumpur’s landmarks, culture and a day trip to Genting Highlands.',
    itinerary: [
      day(1, 'Arrival in Kuala Lumpur', 'Airport pickup and hotel check-in.'),
      day(2, 'Kuala Lumpur', 'The Petronas Twin Towers, KL Tower and a city tour.', [
        ['Petronas Twin Towers Visit', 'Kuala Lumpur'],
        ['Kuala Lumpur City Tour', 'Kuala Lumpur'],
        ['KL Tower Visit', 'Kuala Lumpur'],
      ]),
      day(3, 'Kuala Lumpur', 'Batu Caves and a Jalan Alor food tour.', [
        ['Batu Caves Tour', 'Kuala Lumpur'],
        ['Jalan Alor Food Tour', 'Kuala Lumpur'],
      ]),
      day(4, 'Genting Highlands', 'A day trip up to Genting Highlands.', [
        ['Genting Highlands Day Trip', 'Genting Highlands'],
      ]),
      day(5, 'Kuala Lumpur', 'Free time for shopping.'),
      day(6, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Langkawi Escape',
    country: 'Malaysia',
    price: 550,
    duration_days: 5,
    max_people: 8,
    category: 'beach',
    description: 'Island hopping, mangroves and sunset cruises on Langkawi.',
    itinerary: [
      day(1, 'Arrival in Langkawi', 'Airport pickup and hotel check-in.'),
      day(2, 'Langkawi', 'Island hopping and the Sky Bridge.', [
        ['Langkawi Island Hopping', 'Langkawi'],
        ['Sky Bridge Visit', 'Langkawi'],
      ]),
      day(3, 'Langkawi', 'A mangrove tour.', [['Langkawi Mangrove Tour', 'Langkawi']]),
      day(4, 'Langkawi', 'An evening sunset cruise.', [['Langkawi Sunset Cruise', 'Langkawi']]),
      day(5, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Kuala Lumpur & Langkawi',
    country: 'Malaysia',
    price: 750,
    duration_days: 7,
    max_people: 10,
    category: 'family',
    description: 'City sightseeing in Kuala Lumpur followed by island time in Langkawi.',
    itinerary: [
      day(1, 'Arrival in Kuala Lumpur', 'Airport pickup and hotel check-in.'),
      day(2, 'Kuala Lumpur', 'The Petronas Twin Towers and a city tour.', [
        ['Petronas Twin Towers Visit', 'Kuala Lumpur'],
        ['Kuala Lumpur City Tour', 'Kuala Lumpur'],
      ]),
      day(3, 'Kuala Lumpur', 'Batu Caves and a Jalan Alor food tour.', [
        ['Batu Caves Tour', 'Kuala Lumpur'],
        ['Jalan Alor Food Tour', 'Kuala Lumpur'],
      ]),
      day(4, 'Kuala Lumpur → Langkawi', 'Transfer to Langkawi.'),
      day(5, 'Langkawi', 'Island hopping and the Sky Bridge.', [
        ['Langkawi Island Hopping', 'Langkawi'],
        ['Sky Bridge Visit', 'Langkawi'],
      ]),
      day(6, 'Langkawi', 'A mangrove tour and sunset cruise.', [
        ['Langkawi Mangrove Tour', 'Langkawi'],
        ['Langkawi Sunset Cruise', 'Langkawi'],
      ]),
      day(7, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Singapore Highlights',
    country: 'Singapore',
    price: 520,
    duration_days: 4,
    max_people: 8,
    category: 'city',
    description: 'A compact tour of Singapore’s skyline, gardens and Sentosa Island.',
    itinerary: [
      day(1, 'Arrival in Singapore', 'Airport pickup, then a Marina Bay city tour.', [
        ['Marina Bay City Tour', 'Singapore'],
      ]),
      day(2, 'Singapore', 'Gardens by the Bay, the Singapore Flyer and a river cruise.', [
        ['Gardens by the Bay', 'Singapore'],
        ['Singapore Flyer', 'Singapore'],
        ['Singapore River Cruise', 'Singapore'],
      ]),
      day(3, 'Sentosa', 'Sentosa Island and Universal Studios Singapore.', [
        ['Sentosa Island Tour', 'Singapore'],
        ['Universal Studios Singapore', 'Singapore'],
      ]),
      day(4, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Singapore Family Adventure',
    country: 'Singapore',
    price: 650,
    duration_days: 5,
    max_people: 8,
    category: 'family',
    description: 'A family-friendly week covering Singapore’s top attractions.',
    itinerary: [
      day(1, 'Singapore', 'A Marina Bay city tour.', [['Marina Bay City Tour', 'Singapore']]),
      day(2, 'Singapore', 'Gardens by the Bay and the Singapore Flyer.', [
        ['Gardens by the Bay', 'Singapore'],
        ['Singapore Flyer', 'Singapore'],
      ]),
      day(3, 'Singapore', 'A full day at Universal Studios Singapore.', [
        ['Universal Studios Singapore', 'Singapore'],
      ]),
      day(4, 'Singapore', 'Sentosa Island and the Night Safari.', [
        ['Sentosa Island Tour', 'Singapore'],
        ['Night Safari', 'Singapore'],
      ]),
      day(5, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Bali Escape',
    country: 'Indonesia',
    price: 620,
    duration_days: 6,
    max_people: 8,
    category: 'honeymoon',
    description: 'Temples, rice terraces and sunset cruises across Bali and Ubud.',
    itinerary: [
      day(1, 'Arrival in Bali', 'Airport pickup and hotel check-in.'),
      day(2, 'Ubud', 'The Tegallalang Rice Terrace and Ubud Palace.', [
        ['Tegallalang Rice Terrace', 'Ubud'],
        ['Ubud Palace Visit', 'Ubud'],
      ]),
      day(3, 'Bali', 'The Bali Swing and Tanah Lot Temple.', [
        ['Bali Swing Experience', 'Bali'],
        ['Tanah Lot Temple', 'Bali'],
      ]),
      day(4, 'Bali', 'A boat tour to Nusa Penida.', [['Nusa Penida Island Tour', 'Bali']]),
      day(5, 'Bali', 'Uluwatu Temple and a sunset dinner cruise.', [
        ['Uluwatu Temple Visit', 'Bali'],
        ['Bali Sunset Dinner Cruise', 'Bali'],
      ]),
      day(6, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Bali Adventure',
    country: 'Indonesia',
    price: 580,
    duration_days: 5,
    max_people: 8,
    category: 'adventure',
    description: 'An active week of trekking, island tours and Bali’s best viewpoints.',
    itinerary: [
      day(1, 'Arrival in Bali', 'Airport pickup and hotel check-in.'),
      day(2, 'Bali & Ubud', 'A sunrise trek up Mount Batur, then the Tegallalang Rice Terrace.', [
        ['Mount Batur Sunrise Trek', 'Bali'],
        ['Tegallalang Rice Terrace', 'Ubud'],
      ]),
      day(3, 'Bali', 'A boat tour to Nusa Penida.', [['Nusa Penida Island Tour', 'Bali']]),
      day(4, 'Bali', 'The Bali Swing and Uluwatu Temple.', [
        ['Bali Swing Experience', 'Bali'],
        ['Uluwatu Temple Visit', 'Bali'],
      ]),
      day(5, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Maldives Paradise',
    country: 'Maldives',
    price: 950,
    duration_days: 5,
    max_people: 6,
    category: 'honeymoon',
    description: 'Snorkeling, sandbanks and sunset cruises across the Maldives’ atolls.',
    itinerary: [
      day(1, 'Arrival in Malé', 'Airport pickup and resort check-in.'),
      day(2, 'Malé', 'A snorkeling trip and a secluded sandbank excursion.', [
        ['Snorkeling Trip', 'Malé'],
        ['Sandbank Excursion', 'Malé'],
      ]),
      day(3, 'Malé', 'A full day of island hopping.', [['Island Hopping', 'Malé']]),
      day(4, 'Malé', 'Dolphin watching, followed by a sunset cruise.', [
        ['Dolphin Watching Cruise', 'Malé'],
        ['Sunset Cruise', 'Malé'],
      ]),
      day(5, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Maldives Adventure Escape',
    country: 'Maldives',
    price: 800,
    duration_days: 4,
    max_people: 6,
    category: 'adventure',
    description: 'Scuba diving, snorkeling and island hopping across the Maldives.',
    itinerary: [
      day(1, 'Arrival in Malé', 'Resort check-in.'),
      day(2, 'Malé', 'A scuba diving experience and a snorkeling trip.', [
        ['Scuba Diving Experience', 'Malé'],
        ['Snorkeling Trip', 'Malé'],
      ]),
      day(3, 'Malé', 'Island hopping and a sandbank excursion.', [
        ['Island Hopping', 'Malé'],
        ['Sandbank Excursion', 'Malé'],
      ]),
      day(4, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Japan Highlights',
    country: 'Japan',
    price: 1150,
    duration_days: 7,
    max_people: 10,
    category: 'cultural',
    description: 'Tokyo, Mount Fuji, Kyoto’s temples and Osaka’s street food.',
    itinerary: [
      day(1, 'Arrival in Tokyo', 'Airport pickup and hotel check-in.'),
      day(2, 'Tokyo', 'A Tokyo city tour and a walk through Shibuya.', [
        ['Tokyo City Tour', 'Tokyo'],
        ['Shibuya Walking Tour', 'Tokyo'],
      ]),
      day(3, 'Tokyo', 'A day trip to Mount Fuji.', [['Mount Fuji Day Trip', 'Tokyo']]),
      day(4, 'Tokyo → Kyoto', 'Transfer to Kyoto.'),
      day(5, 'Kyoto', 'Kyoto’s temples and the Arashiyama Bamboo Forest.', [
        ['Kyoto Temple Tour', 'Kyoto'],
        ['Arashiyama Bamboo Forest', 'Kyoto'],
      ]),
      day(6, 'Kyoto → Osaka', 'Osaka Castle and a local food tour.', [
        ['Osaka Castle Visit', 'Osaka'],
        ['Osaka Food Tour', 'Osaka'],
      ]),
      day(7, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Tokyo Explorer',
    country: 'Japan',
    price: 780,
    duration_days: 5,
    max_people: 8,
    category: 'city',
    description: 'A focused week exploring Tokyo and Mount Fuji.',
    itinerary: [
      day(1, 'Arrival in Tokyo', 'Airport pickup.'),
      day(2, 'Tokyo', 'A Tokyo city tour and a walk through Shibuya.', [
        ['Tokyo City Tour', 'Tokyo'],
        ['Shibuya Walking Tour', 'Tokyo'],
      ]),
      day(3, 'Tokyo', 'A day trip to Mount Fuji.', [['Mount Fuji Day Trip', 'Tokyo']]),
      day(4, 'Tokyo', 'Free time for shopping.'),
      day(5, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Dubai Highlights',
    country: 'United Arab Emirates',
    price: 700,
    duration_days: 5,
    max_people: 8,
    category: 'luxury',
    description: 'Dubai’s skyline, malls and a desert safari.',
    itinerary: [
      day(1, 'Arrival in Dubai', 'Airport pickup and hotel check-in.'),
      day(2, 'Dubai', 'A city tour and the Burj Khalifa.', [
        ['Dubai City Tour', 'Dubai'],
        ['Burj Khalifa Visit', 'Dubai'],
      ]),
      day(3, 'Dubai', 'Dubai Mall and a marina cruise.', [
        ['Dubai Mall & Downtown Tour', 'Dubai'],
        ['Dubai Marina Cruise', 'Dubai'],
      ]),
      day(4, 'Dubai', 'A desert safari.', [['Desert Safari', 'Dubai']]),
      day(5, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Dubai & Abu Dhabi',
    country: 'United Arab Emirates',
    price: 850,
    duration_days: 6,
    max_people: 10,
    category: 'luxury',
    description: 'The best of Dubai paired with a visit to Abu Dhabi.',
    itinerary: [
      day(1, 'Arrival in Dubai', 'Airport pickup.'),
      day(2, 'Dubai', 'A city tour and the Burj Khalifa.', [
        ['Dubai City Tour', 'Dubai'],
        ['Burj Khalifa Visit', 'Dubai'],
      ]),
      day(3, 'Dubai', 'A desert safari.', [['Desert Safari', 'Dubai']]),
      day(4, 'Abu Dhabi', 'An Abu Dhabi city tour and the Sheikh Zayed Grand Mosque.', [
        ['Abu Dhabi City Tour', 'Abu Dhabi'],
        ['Sheikh Zayed Grand Mosque', 'Abu Dhabi'],
      ]),
      day(5, 'Abu Dhabi', 'A visit to Ferrari World.', [['Ferrari World Visit', 'Abu Dhabi']]),
      day(6, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Turkey Highlights',
    country: 'Turkey',
    price: 1050,
    duration_days: 8,
    max_people: 10,
    category: 'cultural',
    description: 'Istanbul’s history, Cappadocia’s balloons and the terraces of Pamukkale.',
    itinerary: [
      day(1, 'Arrival in Istanbul', 'Airport pickup.'),
      day(2, 'Istanbul', 'A city tour and the Hagia Sophia.', [
        ['Istanbul City Tour', 'Istanbul'],
        ['Hagia Sophia Visit', 'Istanbul'],
      ]),
      day(3, 'Istanbul', 'A Bosphorus cruise and the Grand Bazaar.', [
        ['Bosphorus Cruise', 'Istanbul'],
        ['Grand Bazaar Tour', 'Istanbul'],
      ]),
      day(4, 'Istanbul → Cappadocia', 'Transfer to Cappadocia.'),
      day(5, 'Cappadocia', 'A hot air balloon ride and a valley tour.', [
        ['Cappadocia Hot Air Balloon', 'Cappadocia'],
        ['Cappadocia Valley Tour', 'Cappadocia'],
      ]),
      day(6, 'Cappadocia → Pamukkale', 'Transfer to Pamukkale.'),
      day(7, 'Pamukkale', 'A tour of Pamukkale’s terraces.', [['Pamukkale Tour', 'Pamukkale']]),
      day(8, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Paris Escape',
    country: 'France',
    price: 850,
    duration_days: 5,
    max_people: 8,
    category: 'city',
    description: 'The essential sights of Paris, from the Eiffel Tower to Versailles.',
    itinerary: [
      day(1, 'Arrival in Paris', 'Airport pickup.'),
      day(2, 'Paris', 'The Eiffel Tower and a city tour.', [
        ['Eiffel Tower Visit', 'Paris'],
        ['Paris City Tour', 'Paris'],
      ]),
      day(3, 'Paris', 'The Louvre and a Seine river cruise.', [
        ['Louvre Museum Tour', 'Paris'],
        ['Seine River Cruise', 'Paris'],
      ]),
      day(4, 'Paris', 'Versailles Palace and a French food tour.', [
        ['Versailles Palace Tour', 'Paris'],
        ['French Food Tour', 'Paris'],
      ]),
      day(5, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Italy Highlights',
    country: 'Italy',
    price: 1100,
    duration_days: 8,
    max_people: 10,
    category: 'cultural',
    description: 'Rome, Florence and Venice — three of Italy’s most iconic cities.',
    itinerary: [
      day(1, 'Arrival in Rome', 'Airport pickup.'),
      day(2, 'Rome', 'The Colosseum and a city tour.', [
        ['Colosseum Tour', 'Rome'],
        ['Rome City Tour', 'Rome'],
      ]),
      day(3, 'Rome', 'The Vatican Museums.', [['Vatican Museums Tour', 'Rome']]),
      day(4, 'Rome → Florence', 'Transfer to Florence, then a walking tour.', [
        ['Florence Walking Tour', 'Florence'],
      ]),
      day(5, 'Florence → Venice', 'Transfer to Venice, then a walking tour.', [
        ['Venice Walking Tour', 'Venice'],
      ]),
      day(6, 'Venice', 'A classic gondola ride.', [['Venice Gondola Ride', 'Venice']]),
      day(7, 'Venice', 'Free time to explore.'),
      day(8, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
  {
    title: 'Swiss Alps Experience',
    country: 'Switzerland',
    price: 1300,
    duration_days: 7,
    max_people: 8,
    category: 'nature',
    description: 'Zurich, Lucerne and Interlaken, with a trip to the Jungfraujoch.',
    itinerary: [
      day(1, 'Arrival in Zurich', 'Airport pickup.'),
      day(2, 'Zurich', 'A visit to the Rhine Falls.', [['Rhine Falls Tour', 'Zurich']]),
      day(3, 'Zurich → Lucerne', 'Transfer to Lucerne, then a city tour.', [
        ['Lucerne City Tour', 'Lucerne'],
      ]),
      day(4, 'Lucerne', 'A tour of Mount Titlis.', [['Mount Titlis Tour', 'Lucerne']]),
      day(5, 'Lucerne → Interlaken', 'Transfer to Interlaken, then a city tour.', [
        ['Interlaken City Tour', 'Interlaken'],
      ]),
      day(6, 'Interlaken', 'A day trip to the Jungfraujoch.', [['Jungfraujoch Day Trip', 'Interlaken']]),
      day(7, 'Departure', 'Transfer to the airport for your departure flight.'),
    ],
  },
];

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected. Upserting tour packages...');

  let created = 0;
  let updated = 0;
  let missingActivities = 0;

  for (const pkg of PACKAGES) {
    const destination = await Destination.findOne({ name: pkg.country });
    if (!destination) {
      console.warn(`Skipping "${pkg.title}" — destination "${pkg.country}" not found.`);
      continue;
    }

    const itinerary = [];
    for (const d of pkg.itinerary) {
      const activities = [];
      for (const [i, [name, location]] of d.activityRefs.entries()) {
        const activity = await Activity.findOne({ name, location });
        if (!activity) {
          console.warn(`  Missing activity "${name}" (${location}) — ${pkg.title}, Day ${d.day_number}`);
          missingActivities += 1;
          continue;
        }
        activities.push({
          activity_id: activity._id,
          is_included: true,
          is_optional: false,
          source: 'package',
          sort_order: i,
        });
      }
      itinerary.push({
        day_number: d.day_number,
        title: d.title,
        description: d.description,
        activities,
      });
    }

    const res = await TourPackage.updateOne(
      { title: pkg.title },
      {
        $set: {
          destination_id: destination._id,
          description: pkg.description,
          price: pkg.price,
          duration_days: pkg.duration_days,
          max_people: pkg.max_people,
          category: pkg.category,
          included_services: DEFAULT_INCLUDED_SERVICES,
          itinerary,
          status: 'active',
        },
        $setOnInsert: { image_url: img(pkg.title) },
      },
      { upsert: true }
    );
    if (res.upsertedCount) created += 1;
    else updated += 1;
  }

  console.log(`Done. Created ${created}, updated ${updated}, missing activity refs ${missingActivities}.`);
  await mongoose.disconnect();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
