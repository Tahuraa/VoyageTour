// Creates (or promotes) a VoyageTour admin account.
// Usage: npm run seed:admin
// Optional overrides: ADMIN_EMAIL, ADMIN_PHONE, ADMIN_PASSWORD env vars.
require('dotenv').config();
const crypto = require('crypto');
const mongoose = require('mongoose');
const User = require('./models/User');

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@voyagetour.com';
const ADMIN_PHONE = process.env.ADMIN_PHONE || '9999999999';
const explicitPassword = process.env.ADMIN_PASSWORD;
const generatedPassword = crypto.randomBytes(9).toString('base64').replace(/[^a-zA-Z0-9]/g, '').slice(0, 12);

const run = async () => {
  await mongoose.connect(process.env.MONGO_URI);

  let user = await User.findOne({ email: ADMIN_EMAIL });
  let passwordToReport = null;

  if (user) {
    user.role = 'admin';
    if (explicitPassword) {
      user.password = explicitPassword;
      passwordToReport = explicitPassword;
    }
    await user.save();
    console.log(`Existing user ${ADMIN_EMAIL} ensured as admin.`);
  } else {
    passwordToReport = explicitPassword || generatedPassword;
    user = await User.create({
      name: 'VoyageTour Admin',
      email: ADMIN_EMAIL,
      phone: ADMIN_PHONE,
      password: passwordToReport,
      role: 'admin',
    });
    console.log('Created new admin user.');
  }

  console.log('\n--- Admin login ---');
  console.log('Email:   ', ADMIN_EMAIL);
  console.log('Password:', passwordToReport || '(unchanged — use the existing password)');
  console.log('-------------------\n');

  process.exit(0);
};

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
