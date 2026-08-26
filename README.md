# VoyageTour

A full-stack tour booking and trip customization platform — a Flutter mobile app backed by a Node.js/Express/MongoDB API, with Stripe payments, an admin dashboard, and a promo-code offers system.
link to WireFrame https://app.visily.ai/projects/4e747567-a23b-4047-a641-1ddfaa83e903/boards/2690093
link to Schema Diagram https://drive.google.com/file/d/1jRMpd5ynsFXZHeIDA_wJYCcWOKoFeSxU/view?usp=sharing
link to  Video https://drive.google.com/drive/folders/1t4AlCH26PbHD7ObFQGTYFg7JYgdwlfNY?usp=sharings

## Tech Stack

**Frontend**
- Flutter (Dart), Material 3
- `provider` for state management
- `flutter_stripe` for in-app payments
- `shared_preferences` for local persistence (read/unread notifications, notification on/off preference)

**Backend**
- Node.js + Express
- MongoDB with Mongoose
- JWT authentication
- Stripe (test mode) for payments

## Features

- **Auth & account management** — registration, login, JWT sessions, change password, account deletion (cascades bookings/payments/customized tours/favorites/reviews)
- **Search & discovery** — multi-destination search with autocomplete, category/price/date filters, sorting, and a claimable promo-coupon strip
- **Tour package customization** — hotel category (3★/4★/5★), transportation type (private car / shared shuttle / tour bus), day-by-day activity selection, live price recalculation
- **Booking & payments** — Stripe checkout, server-authoritative pricing (subtotal, promo discount, and total are always computed backend-side)
- **My Trips** — Next / Ongoing / Past / Draft tabs, status badges, tiered cancellation & refund policy (100% >14 days, 30% 7–14 days, 0% <7 days), cancelled trips stay visible and re-bucket by date
- **Notifications** — derived from trip/booking state (no push infra needed), read/unread tracking, on/off toggle in Account Settings
- **Offers & promotions** — admin-managed promo codes; users claim an offer and it auto-applies its discount at checkout
- **Favorites & reviews**
- **Admin dashboard** — global stats and full CRUD for destinations, activities, tour packages, bookings, users, and promotions

## Project Structure

```
lib/                    Flutter app
  models/                data models (+ admin/ variants for admin-only fields)
  providers/             ChangeNotifier state (auth, search, favorites, promotions)
  screens/               UI screens, grouped by feature (auth, home, search, trips, admin, ...)
  services/              HTTP clients per resource, talk to the backend API
  widgets/                shared UI components

backend/
  src/
    models/              Mongoose schemas
    controllers/         route handlers
    routes/               Express routers
    middleware/           auth (JWT) and error handling
    config/               DB connection, Stripe client, customization pricing
    utils/                 promo/discount calculation, email, tokens
  server.js               app entrypoint
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.12.2)
- [Node.js](https://nodejs.org/) 18+
- A MongoDB database (e.g. a free [MongoDB Atlas](https://www.mongodb.com/atlas) cluster)
- A [Stripe](https://stripe.com/) account (test mode is fine) for payments

## Backend Setup

```bash
cd backend
npm install
cp .env.example .env   # then fill in the values below
```

| Variable | Description |
|---|---|
| `MONGO_URI` | MongoDB connection string |
| `PORT` | API port (the app expects `5050`) |
| `JWT_SECRET` | Any long random string used to sign auth tokens |
| `STRIPE_SECRET_KEY` | Your Stripe test secret key |

Seed the database, then start the server:

```bash
npm run seed:destinations
npm run seed:activities
npm run seed:packages
npm run seed:admin        # creates an admin user; prints its email/password once
npm run dev                # starts the API with nodemon on PORT
```

`npm run seed:admin` accepts optional `ADMIN_EMAIL` / `ADMIN_PHONE` / `ADMIN_PASSWORD` env vars if you want to set them explicitly instead of using the generated defaults.

## Frontend Setup

```bash
flutter pub get
```

The app talks to the backend at `127.0.0.1:5050` (see `lib/config/api_config.dart`):

- **Android emulator / physical device over USB**: run `adb reverse tcp:5050 tcp:5050` so the device can reach your machine's `localhost`.
- **Physical device over Wi-Fi**: change `_host` in `lib/config/api_config.dart` to your machine's LAN IP (device and machine must be on the same network).

Then run the app:

```bash
flutter run
```

## Notes

- All pricing (promo discounts, refund percentages) is calculated server-side — the client only displays what the API returns, so totals can't be manipulated from the app.
- Stripe is configured in test mode; use [Stripe's test card numbers](https://docs.stripe.com/testing) to complete a booking end-to-end.
