import '../models/trip_summary.dart';
import 'booking_service.dart';
import 'customized_tour_service.dart';

/// Loads and merges a user's bookings and customized tours into the unified
/// [TripSummary] list used by both "My Trips" and the notifications feed,
/// so the two stay in sync on which trips are shown.
class TripsService {
  static Future<List<TripSummary>> loadMine(String token) async {
    final bookingsFuture = BookingService(token: token).listMine();
    final toursFuture = CustomizedTourService(token: token).listMine();
    final bookings = await bookingsFuture;
    final tours = await toursFuture;
    return [
      ...bookings.map((b) => TripSummary.fromBooking(b)),
      // Confirming a customized tour creates a real Booking for it and
      // moves the tour itself past 'draft' — from that point the Booking
      // is the single source of truth, so only still-editable drafts (and
      // drafts cancelled before ever being booked) get their own entry.
      ...tours.where((t) => t.status == 'draft' || t.status == 'cancelled').map((t) => TripSummary.fromCustomizedTour(t)),
    ];
  }
}
