// Dev-only seed script: populates destinations, tour packages (with full
// itineraries), reviews (to derive ratings) and bookings (to derive
// popularity) so the Home/Search/Package-details screens have real data to
// render. Safe to re-run — it clears and rebuilds only the catalog + seed
// reviewer/booking data, never touches real user accounts.
require('dotenv').config();
const mongoose = require('mongoose');
const Destination = require('./models/Destination');
const TourPackage = require('./models/TourPackage');
const Promotion = require('./models/Promotion');
const Review = require('./models/Review');
const Booking = require('./models/Booking');
const User = require('./models/User');

const img = (seed) => `https://picsum.photos/seed/${seed}/900/700`;

const SEED_REVIEWERS = [
  { name: 'Alice Chen', email: 'seed.alice@voyagetour.seed', phone: '+10000000001' },
  { name: 'Ben Ortiz', email: 'seed.ben@voyagetour.seed', phone: '+10000000002' },
  { name: 'Chloe Dubois', email: 'seed.chloe@voyagetour.seed', phone: '+10000000003' },
  { name: 'Dev Patel', email: 'seed.dev@voyagetour.seed', phone: '+10000000004' },
  { name: 'Elena Rossi', email: 'seed.elena@voyagetour.seed', phone: '+10000000005' },
];

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected. Clearing previous seed data...');

  const seedEmails = SEED_REVIEWERS.map((r) => r.email);
  const seedUserIds = (await User.find({ email: { $in: seedEmails } }, '_id')).map((u) => u._id);
  await Booking.deleteMany({ user_id: { $in: seedUserIds } });
  await Review.deleteMany({ user_id: { $in: seedUserIds } });
  await User.deleteMany({ email: { $in: seedEmails } });
  await TourPackage.deleteMany({});
  await Destination.deleteMany({});
  await Promotion.deleteMany({});

  const reviewers = await User.create(
    SEED_REVIEWERS.map((r) => ({ ...r, password: 'seedpassword123' }))
  );

  const destinations = await Destination.create([
    {
      name: 'Paris',
      country: 'France',
      description: 'The City of Light, famed for the Eiffel Tower, art and cafe culture.',
      image_url: img('paris'),
      is_featured: true,
    },
    {
      name: 'London',
      country: 'United Kingdom',
      description: 'A historic capital blending royal heritage with modern energy.',
      image_url: img('london'),
      is_featured: true,
    },
    {
      name: 'Interlaken',
      country: 'Switzerland',
      description: 'Gateway to the Swiss Alps, nestled between two turquoise lakes.',
      image_url: img('interlaken'),
      is_featured: false,
    },
    {
      name: 'Rome',
      country: 'Italy',
      description: 'The Eternal City, home to the Colosseum and centuries of history.',
      image_url: img('rome'),
      is_featured: false,
    },
    {
      name: 'Male',
      country: 'Maldives',
      description: 'Turquoise lagoons and overwater villas across a coral archipelago.',
      image_url: img('maldives'),
      is_featured: false,
    },
    {
      name: 'Kyoto',
      country: 'Japan',
      description: 'Ancient temples, tea houses and Japan’s cherry blossom heartland.',
      image_url: img('kyoto'),
      is_featured: false,
    },
    {
      name: 'Bali',
      country: 'Indonesia',
      description: 'Rice terraces, temples and a spiritual retreat destination.',
      image_url: img('bali'),
      is_featured: false,
    },
    {
      name: 'Tokyo',
      country: 'Japan',
      description: 'A neon-lit metropolis mixing tradition with cutting-edge culture.',
      image_url: img('tokyo'),
      is_featured: false,
    },
    {
      name: 'Amalfi Coast',
      country: 'Italy',
      description: 'Clifftop villages, turquoise water and Italy’s most scenic coastline.',
      image_url: img('amalfi'),
      is_featured: false,
    },
  ]);

  const byName = Object.fromEntries(destinations.map((d) => [d.name, d]));

  const packages = await TourPackage.create([
    {
      destination_id: byName['Bali'].id,
      title: 'Bali Spiritual Retreat',
      description:
        'Reconnect with yourself among rice terraces and ancient temples on this restorative journey through Ubud and the Balinese highlands.',
      price: 1249,
      duration_days: 7,
      max_people: 12,
      image_url: img('bali-retreat'),
      category: 'nature',
      included_services: [
        'Boutique eco-resort accommodation',
        'Daily yoga and meditation sessions',
        'Traditional Balinese healing ceremony',
        'All breakfasts and two group dinners',
        'Private driver for temple visits',
      ],
      itinerary: [
        { day_number: 1, title: 'Arrival in Ubud', description: 'Settle into your eco-resort and enjoy a welcome ceremony.', highlights: ['Check-in', 'Welcome Ceremony'] },
        { day_number: 2, title: 'Rice Terraces & Yoga', description: 'Sunrise yoga overlooking the Tegalalang rice terraces.', highlights: ['Sunrise Yoga', 'Rice Terrace Walk'] },
        { day_number: 3, title: 'Temple Trail', description: 'Visit sacred water temples and receive a traditional blessing.', highlights: ['Temple Visit', 'Water Blessing'] },
        { day_number: 4, title: 'Healing Ceremony', description: 'A guided Balinese healing and sound bath session.', highlights: ['Sound Bath', 'Healer Session'] },
        { day_number: 5, title: 'Waterfall Hike', description: 'Trek to a hidden jungle waterfall.', highlights: ['Jungle Trek'] },
        { day_number: 6, title: 'Free Day & Spa', description: 'Leisure day with an optional traditional spa treatment.', highlights: ['Spa'] },
        { day_number: 7, title: 'Departure', description: 'Farewell breakfast and transfer to the airport.', highlights: ['Departure'] },
      ],
    },
    {
      destination_id: byName['Tokyo'].id,
      title: 'Modern Tokyo Highlights',
      description:
        'From Shibuya’s neon crossings to quiet Meiji shrine gardens, experience Tokyo’s full spectrum in five action-packed days.',
      price: 999,
      duration_days: 5,
      max_people: 15,
      image_url: img('tokyo-highlights'),
      category: 'city',
      included_services: [
        'Central Tokyo hotel accommodation',
        'Unlimited metro pass',
        'Guided Shibuya & Shinjuku walking tour',
        'Robot Restaurant show ticket',
        'Airport transfers',
      ],
      itinerary: [
        { day_number: 1, title: 'Arrival & Shinjuku by Night', description: 'Check in and explore Shinjuku’s neon streets.', highlights: ['Check-in', 'Night Walk'] },
        { day_number: 2, title: 'Shibuya & Harajuku', description: 'Cross the famous scramble and browse Harajuku fashion streets.', highlights: ['Shibuya Crossing'] },
        { day_number: 3, title: 'Asakusa & Sumida River', description: 'Visit Senso-ji temple and cruise the river at sunset.', highlights: ['Temple Visit', 'River Cruise'] },
        { day_number: 4, title: 'Akihabara & teamLab', description: 'Explore electronics town and an immersive digital art museum.', highlights: ['teamLab'] },
        { day_number: 5, title: 'Departure', description: 'Free morning, then transfer to the airport.', highlights: ['Departure'] },
      ],
    },
    {
      destination_id: byName['Interlaken'].id,
      title: 'Swiss Alps Grand Tour',
      description:
        'Explore the breathtaking beauty of the Swiss Alps. This guided tour covers scenic valleys, snow-capped peaks and lakeside villages.',
      price: 1499,
      duration_days: 5,
      max_people: 10,
      image_url: img('swiss-alps'),
      category: 'adventure',
      included_services: [
        'Mountain-view chalet accommodation',
        'Jungfraujoch cogwheel train tickets',
        'Guided glacier hike',
        'Daily breakfast and one fondue dinner',
        'All internal transfers',
      ],
      itinerary: [
        { day_number: 1, title: 'Arrival in Interlaken', description: 'Check in to your lakeside chalet.', highlights: ['Check-in'] },
        { day_number: 2, title: 'Jungfraujoch – Top of Europe', description: 'Cogwheel train to Europe’s highest railway station.', highlights: ['Jungfraujoch'] },
        { day_number: 3, title: 'Glacier Hike', description: 'Guided hike across an alpine glacier trail.', highlights: ['Glacier Hike'] },
        { day_number: 4, title: 'Lauterbrunnen Valley', description: 'Waterfalls and cable cars through the valley of 72 falls.', highlights: ['Waterfalls'] },
        { day_number: 5, title: 'Departure', description: 'Farewell breakfast and transfer onward.', highlights: ['Departure'] },
      ],
    },
    {
      destination_id: byName['Rome'].id,
      title: 'Historic Rome Walking Journey',
      description:
        'Walk through history on cobblestone streets. Discover the Colosseum, Vatican City and hidden piazzas on foot.',
      price: 450,
      duration_days: 3,
      max_people: 14,
      image_url: img('rome-walk'),
      category: 'cultural',
      included_services: [
        'Central Rome boutique hotel',
        'Skip-the-line Colosseum & Forum tour',
        'Vatican Museums & Sistine Chapel entry',
        'Daily breakfast',
        'Expert local guide throughout',
      ],
      itinerary: [
        { day_number: 1, title: 'Colosseum & Roman Forum', description: 'Skip-the-line tour of ancient Rome’s heart.', highlights: ['Colosseum'] },
        { day_number: 2, title: 'Vatican City', description: 'Vatican Museums, Sistine Chapel and St. Peter’s Basilica.', highlights: ['Vatican'] },
        { day_number: 3, title: 'Trastevere & Departure', description: 'Morning food walk through Trastevere before departure.', highlights: ['Food Walk', 'Departure'] },
      ],
    },
    {
      destination_id: byName['Rome'].id,
      title: 'Roman Food & Wine Tour',
      description:
        'A four-day culinary journey through Rome’s trattorias, markets and vineyards, guided by local chefs and sommeliers.',
      price: 720,
      duration_days: 4,
      max_people: 10,
      image_url: img('rome-food'),
      category: 'cultural',
      included_services: [
        'Boutique hotel near Campo de’ Fiori',
        'Testaccio Market food tour with tastings',
        'Hands-on pasta-making class',
        'Day trip to a Frascati vineyard with wine tasting',
        'Three guided dinners',
      ],
      itinerary: [
        { day_number: 1, title: 'Testaccio Market Tour', description: 'Taste your way through Rome’s historic food market.', highlights: ['Market Tour', 'Tastings'] },
        { day_number: 2, title: 'Pasta-Making Class', description: 'Hands-on class with a local Roman chef.', highlights: ['Cooking Class'] },
        { day_number: 3, title: 'Frascati Vineyard Day Trip', description: 'Wine tasting in the hills outside Rome.', highlights: ['Wine Tasting'] },
        { day_number: 4, title: 'Trastevere Farewell Dinner', description: 'Final evening with a chef-led dinner in Trastevere.', highlights: ['Farewell Dinner', 'Departure'] },
      ],
    },
    {
      destination_id: byName['Male'].id,
      title: 'Maldives Island Hopping',
      description:
        'Paradise awaits in the crystal-clear turquoise waters. Enjoy luxury resorts, snorkeling in coral reefs and overwater villas.',
      price: 2890,
      duration_days: 7,
      max_people: 8,
      image_url: img('maldives-hopping'),
      category: 'beach',
      included_services: [
        'Overwater villa accommodation',
        'Seaplane transfers between islands',
        'Guided snorkeling excursions',
        'All-inclusive dining',
        'Sunset dolphin cruise',
      ],
      itinerary: [
        { day_number: 1, title: 'Arrival & Overwater Villa', description: 'Seaplane transfer to your first resort island.', highlights: ['Check-in'] },
        { day_number: 2, title: 'Coral Reef Snorkeling', description: 'Guided snorkeling trip across a protected reef.', highlights: ['Snorkeling'] },
        { day_number: 3, title: 'Island Hop', description: 'Seaplane to a second island resort.', highlights: ['Island Transfer'] },
        { day_number: 4, title: 'Sunset Dolphin Cruise', description: 'Evening cruise to spot spinner dolphins.', highlights: ['Dolphin Cruise'] },
        { day_number: 5, title: 'Free Day', description: 'Leisure day at your villa.', highlights: [] },
        { day_number: 6, title: 'Sandbank Picnic', description: 'Private picnic on a secluded sandbank.', highlights: ['Sandbank Picnic'] },
        { day_number: 7, title: 'Departure', description: 'Seaplane transfer back to Male for departure.', highlights: ['Departure'] },
      ],
    },
    {
      destination_id: byName['Kyoto'].id,
      title: 'Kyoto Cherry Blossom Special',
      description:
        'Witness the magical Sakura season. Visit traditional temples, attend tea ceremonies and explore vibrant blossom-lined streets.',
      price: 880,
      duration_days: 4,
      max_people: 12,
      image_url: img('kyoto-sakura'),
      category: 'cultural',
      included_services: [
        'Traditional ryokan accommodation',
        'Tea ceremony experience',
        'Guided Arashiyama bamboo grove tour',
        'Kimono rental for one day',
        'Daily breakfast',
      ],
      itinerary: [
        { day_number: 1, title: 'Arrival & Gion District', description: 'Evening stroll through the historic geisha district.', highlights: ['Check-in'] },
        { day_number: 2, title: 'Fushimi Inari & Tea Ceremony', description: 'Thousand torii gates followed by a traditional tea ceremony.', highlights: ['Tea Ceremony'] },
        { day_number: 3, title: 'Arashiyama Bamboo Grove', description: 'Kimono-clad walk through the famous bamboo forest.', highlights: ['Kimono Day'] },
        { day_number: 4, title: 'Departure', description: 'Final blossom viewing before transfer to the airport.', highlights: ['Departure'] },
      ],
    },
    {
      destination_id: byName['Amalfi Coast'].id,
      title: 'Mediterranean Coastal Escape',
      description:
        'Experience the magic of the Amalfi Coast. From the vertical colorful villages of Positano to the turquoise waters of Capri, this curated journey blends luxury relaxation with authentic Italian culture.',
      price: 2450,
      duration_days: 7,
      max_people: 10,
      image_url: img('amalfi-escape'),
      category: 'luxury',
      included_services: [
        'Luxury 5-star hotel accommodations',
        'Private boat tour to Capri & Blue Grotto',
        'Authentic Italian breakfast & selective dinners',
        'Professional local English-speaking guide',
        'All internal transportation & airport transfers',
      ],
      itinerary: [
        {
          day_number: 1,
          title: 'Arrival in Naples & Transfer to Positano',
          description:
            'Welcome to Italy! Your private driver will meet you at Naples Airport and whisk you away to your luxury clifftop hotel in Positano.',
          highlights: ['Check-in', 'Sunset Welcome Dinner', 'Evening Leisure'],
        },
        {
          day_number: 2,
          title: 'The Vertical City Exploration',
          description:
            'Wander Positano’s cascading staircases, boutique shops and viewpoints over the bay.',
          highlights: ['Walking Tour', 'Free Shopping Time'],
        },
        {
          day_number: 3,
          title: 'Capri & Blue Grotto Boat Journey',
          description:
            'A full-day private boat tour to the island of Capri, including the famous Blue Grotto sea cave.',
          highlights: ['Private Boat', 'Blue Grotto'],
        },
        {
          day_number: 4,
          title: 'Path of the Gods Hike',
          description:
            'A guided hike along the legendary coastal trail with panoramic views of the Tyrrhenian Sea.',
          highlights: ['Guided Hike', 'Panoramic Views'],
        },
        {
          day_number: 5,
          title: 'Amalfi & Ravello Day Trip',
          description: 'Visit Amalfi’s cathedral and the clifftop gardens of Ravello.',
          highlights: ['Amalfi Cathedral', 'Ravello Gardens'],
        },
        {
          day_number: 6,
          title: 'Free Day & Optional Cooking Class',
          description: 'A leisure day with an optional hands-on Italian cooking class.',
          highlights: ['Cooking Class'],
        },
        {
          day_number: 7,
          title: 'Departure',
          description: 'Private transfer back to Naples Airport for your departure flight.',
          highlights: ['Departure'],
        },
      ],
    },
  ]);

  // Ratings: a handful of reviews per package, mostly high with light variation.
  const ratingPlan = {
    'Bali Spiritual Retreat': [5, 5, 5, 4, 5],
    'Modern Tokyo Highlights': [5, 4, 5, 5, 4],
    'Swiss Alps Grand Tour': [5, 5, 5, 5, 4],
    'Historic Rome Walking Journey': [5, 4, 5, 5, 4],
    'Roman Food & Wine Tour': [5, 5, 4, 5],
    'Maldives Island Hopping': [5, 5, 5, 4, 5],
    'Kyoto Cherry Blossom Special': [5, 4, 5, 4, 5],
    'Mediterranean Coastal Escape': [5, 5, 5, 5, 5, 4, 5, 5, 5, 4],
  };
  const bookingCountPlan = {
    'Bali Spiritual Retreat': 6,
    'Modern Tokyo Highlights': 5,
    'Swiss Alps Grand Tour': 4,
    'Historic Rome Walking Journey': 3,
    'Roman Food & Wine Tour': 2,
    'Maldives Island Hopping': 4,
    'Kyoto Cherry Blossom Special': 2,
    'Mediterranean Coastal Escape': 3,
  };

  for (const pkg of packages) {
    const ratings = ratingPlan[pkg.title] || [5, 4];
    await Review.create(
      ratings.map((rating, i) => ({
        user_id: reviewers[i % reviewers.length]._id,
        package_id: pkg._id,
        rating,
        comment: 'Wonderful trip, would book again!',
      }))
    );

    const bookingCount = bookingCountPlan[pkg.title] || 1;
    await Booking.create(
      Array.from({ length: bookingCount }, (_, i) => ({
        user_id: reviewers[i % reviewers.length]._id,
        package_id: pkg._id,
        travel_start_date: new Date(Date.now() + (i + 1) * 20 * 24 * 60 * 60 * 1000),
        travel_end_date: new Date(Date.now() + ((i + 1) * 20 + pkg.duration_days) * 24 * 60 * 60 * 1000),
        travelers: 2,
        total_price: pkg.price * 2,
        status: 'confirmed',
      }))
    );
  }

  await Promotion.create({
    code: 'SUMMER40',
    title: 'Up to 40% Off Beach Resorts',
    subtitle: 'Book your dream tropical getaway before the season ends',
    badge_label: 'Summer Deal',
    image_url: img('summer-deal'),
    discount_type: 'percentage',
    discount_value: 40,
    min_order_amount: 0,
    valid_from: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    valid_to: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    usage_limit: 1000,
    status: 'active',
  });

  console.log(`Seeded ${destinations.length} destinations, ${packages.length} packages, 1 promotion.`);
  await mongoose.disconnect();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
