const Stripe = require('stripe');

if (!process.env.STRIPE_SECRET_KEY) {
  console.warn('STRIPE_SECRET_KEY is not set — payment endpoints will fail until it is configured in .env');
}

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || 'sk_test_not_configured');

module.exports = stripe;
