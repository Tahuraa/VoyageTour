

## Project Title

**VoyageTour — A Full-Stack Tour Booking and Trip Customization Platform**

VoyageTour is a cross-platform travel booking application consisting of a Flutter mobile frontend and a Node.js/Express/MongoDB backend. It allows customers to search, customize, book, and manage guided tour packages, while giving administrators full control over the catalog, bookings, and promotional campaigns through a dedicated admin panel.

## Project Features

By the end of this course, the following features were designed, implemented, and verified end-to-end (backend API + live device UI):

**1. Authentication & Account Management**
- User registration and login secured with JWT-based authentication.
- Change-password flow with current-password verification.
- Account deletion with password confirmation, cascading the delete across the user's bookings, payments, customized tours, favorites, and reviews.
- Role-based access separating regular users from admin accounts.

**2. Destination & Package Search**
- Multi-destination search with autocomplete suggestions.
- Filtering by trip category, budget range, travel dates, and number of travelers.
- Sorting by recommendation, rating, and price (ascending/descending).
- Agoda-style claimable promo-code coupon strip displayed directly beneath the search bar.

**3. Tour Package Customization**
- Hotel category selection (3-star / 4-star / 5-star) instead of a fixed named hotel, with per-night pricing.
- Transportation type selection (private car / shared shuttle / tour bus), each with its own pricing tier and a sensible default.
- Day-by-day itinerary customization by adding or removing activities per day.
- Live price recalculation as customization choices change.

**4. Booking & Payment**
- Direct package booking and customized-tour confirmation flows.
- Stripe (test-mode) payment integration via `flutter_stripe`.
- Server-authoritative pricing: subtotal, promo discount, and final total are always computed on the backend, never trusted from client input.

**5. My Trips Management**
- Trips organized into **Next / Ongoing / Past / Draft** tabs.
- Status badges (Payment Pending, Confirmed, Cancelled) shown only where relevant — suppressed on Past and Draft trips.
- "Effective status" logic: a booking still pending once its travel date has passed is automatically treated as cancelled for display, without altering the underlying stored status.
- Tiered cancellation and refund policy, enforced server-side:
  - More than 14 days before travel → 100% refund
  - 7–14 days before travel → 30% refund
  - Less than 7 days before travel → no refund
- Cancelled trips remain visible (never deleted), correctly re-bucketed by date into Next/Ongoing/Past.

**6. Notifications**
- In-app notifications derived directly from existing trip/booking data (no push-notification backend required) — covering payment-pending reminders, trips starting soon, cancellations, confirmations, and draft reminders.
- Read/unread tracking persisted locally, with a live unread-count badge on the home screen bell icon.
- A user-level on/off toggle for notifications in Account Settings.

**7. Offers & Promotions**
- Admin-managed promo codes (percentage or fixed discount, minimum order amount, validity window, usage limit, active/inactive status).
- "Claim then auto-apply" user flow: a user claims an offer from the Home or Search screen, and its discount is automatically computed and deducted at checkout in the Review Trip screen — no manual code entry required.
- Full admin CRUD screen ("Manage Offers & Promotions") for creating, editing, and deleting promotions, mirroring the same list/form pattern used for managing activities, destinations, and packages.

**8. Admin Dashboard**
- Global statistics: total users, total bookings, total revenue, total packages, and a bookings-by-status breakdown.
- Full CRUD management for Destinations, Activities, Tour Packages, Bookings, Users, and Promotions.

**9. UI/UX**
- A centralized, custom Material 3 theme (refined color scheme, rounded cards, consistent button/input/chip styling) applied consistently across the entire app.
- Favorites/wishlist and review functionality for tour packages.

## Online Resources used

**a) Reference:**
- Flutter official documentation ([flutter.dev](https://flutter.dev)) — widgets, state management, navigation
- Node.js / Express.js official documentation
- MongoDB & Mongoose documentation — schema design and querying
- Stripe API documentation and `flutter_stripe` package documentation — payment integration
- Provider package documentation — app-wide state management (`ChangeNotifier`)
- YouTube videos: Flutter + Node.js REST API integration tutorials, Stripe payments in Flutter tutorials

**b)** Stack Overflow (debugging Flutter `setState`/Future pitfalls, Mongoose query patterns) and GitHub reference repositories for Flutter/Express project structure conventions.

## Future Enhancements

Following enhancements can be added to the current system to further improve it:

a) Real push notifications (e.g., Firebase Cloud Messaging) as an alternative/complement to the current in-app derived notifications.
b) Social login (Google/Apple) — currently present in the UI as placeholders but not functionally wired up.
c) Multi-language and multi-currency support for international users.
d) AI-based personalized trip recommendations based on booking history.
e) Real-time chat support between customers and travel agents.
f) One-time-use / per-user redemption enforcement for promo codes (the schema already reserves a `usage_limit` field for this).
g) Automated test coverage (unit, widget, and integration tests) and a CI/CD pipeline.
h) Admin analytics dashboard with revenue trends and booking forecasts over time.
i) A loyalty/rewards points program layered on top of the existing promotions engine.
