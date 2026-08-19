// Dev-only script: upserts the country-level destination catalog by
// country_code. Idempotent and non-destructive — safe to re-run, and does
// not touch existing city-level destinations or anything else in the DB.
require('dotenv').config();
const mongoose = require('mongoose');
const Destination = require('./models/Destination');

const img = (code) => `https://picsum.photos/seed/${code.toLowerCase()}/900/700`;

const COUNTRIES = [
  ['Thailand', 'TH', true],
  ['Malaysia', 'MY', true],
  ['Singapore', 'SG', true],
  ['Indonesia', 'ID', true],
  ['Maldives', 'MV', true],
  ['Sri Lanka', 'LK', true],
  ['India', 'IN', true],
  ['Vietnam', 'VN', true],
  ['Cambodia', 'KH', false],
  ['Nepal', 'NP', false],
  ['Bhutan', 'BT', false],
  ['Japan', 'JP', true],
  ['South Korea', 'KR', true],
  ['China', 'CN', false],
  ['United Arab Emirates', 'AE', true],
  ['Saudi Arabia', 'SA', true],
  ['Turkey', 'TR', true],
  ['Qatar', 'QA', false],
  ['Azerbaijan', 'AZ', false],
  ['France', 'FR', true],
  ['Italy', 'IT', true],
  ['Switzerland', 'CH', true],
  ['Spain', 'ES', true],
  ['Greece', 'GR', true],
  ['United Kingdom', 'GB', true],
  ['Germany', 'DE', false],
  ['Netherlands', 'NL', false],
  ['Austria', 'AT', false],
  ['Portugal', 'PT', false],
  ['Czech Republic', 'CZ', false],
  ['Australia', 'AU', true],
  ['New Zealand', 'NZ', true],
  ['Egypt', 'EG', true],
  ['South Africa', 'ZA', true],
  ['United States', 'US', true],
  ['Canada', 'CA', true],
  ['Mauritius', 'MU', false],
  ['Seychelles', 'SC', false],
  ['Tanzania', 'TZ', false],
  ['Morocco', 'MA', true],
];

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected. Upserting destinations...');

  let created = 0;
  let updated = 0;

  for (const [name, code, isFeatured] of COUNTRIES) {
    const res = await Destination.updateOne(
      { country_code: code },
      {
        $set: {
          name,
          country: name,
          country_code: code,
          is_featured: isFeatured,
          status: 'active',
        },
        $setOnInsert: { image_url: img(code) },
      },
      { upsert: true }
    );
    if (res.upsertedCount) created += 1;
    else updated += 1;
  }

  console.log(`Done. Created ${created}, updated ${updated}, total ${COUNTRIES.length}.`);
  await mongoose.disconnect();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
