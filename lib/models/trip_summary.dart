import 'booking_model.dart';
import 'customized_tour_model.dart';

enum TripKind { booking, customizedTour }

/// Which "My Trips" tab a trip belongs in.
enum TripBucket { next, ongoing, past, draft }

/// A unified view over the two kinds of trips a user can have — a direct
/// [BookingModel] or a [CustomizedTourModel] — so "My Trips" and "Travel
/// History" can list, sort and filter them together.
class TripSummary {
  final TripKind kind;
  final String id;
  final String title;
  final String destinationName;
  final String destinationCountry;
  final String? imageUrl;
  final DateTime travelDate;
  final DateTime? travelEndDate;
  final int travelers;
  final double totalPrice;
  final String status;
  final BookingModel? booking;
  final CustomizedTourModel? customizedTour;

  TripSummary._({
    required this.kind,
    required this.id,
    required this.title,
    required this.destinationName,
    required this.destinationCountry,
    this.imageUrl,
    required this.travelDate,
    this.travelEndDate,
    required this.travelers,
    required this.totalPrice,
    required this.status,
    this.booking,
    this.customizedTour,
  });

  factory TripSummary.fromBooking(BookingModel booking) => TripSummary._(
        kind: TripKind.booking,
        id: booking.id,
        title: booking.package.title,
        destinationName: booking.package.destination.name,
        destinationCountry: booking.package.destination.country,
        imageUrl: booking.package.imageUrl,
        travelDate: booking.travelStartDate,
        travelEndDate: booking.travelEndDate,
        travelers: booking.travelers,
        totalPrice: booking.totalPrice,
        status: booking.status,
        booking: booking,
      );

  factory TripSummary.fromCustomizedTour(CustomizedTourModel tour) => TripSummary._(
        kind: TripKind.customizedTour,
        id: tour.id,
        title: tour.tourPackage.title,
        destinationName: tour.destination.name,
        destinationCountry: tour.destination.country,
        imageUrl: tour.tourPackage.imageUrl,
        travelDate: tour.travelDate,
        travelers: tour.travelers,
        totalPrice: tour.totalPrice,
        status: tour.status,
        customizedTour: tour,
      );

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _startDay => DateTime(travelDate.year, travelDate.month, travelDate.day);

  DateTime get _endDay => travelEndDate != null
      ? DateTime(travelEndDate!.year, travelEndDate!.month, travelEndDate!.day)
      : _startDay;

  /// A booking that's still unpaid once its travel window has arrived (or
  /// passed) never actually happened — payment was due before then. Treat
  /// it as cancelled rather than letting it sit in "Ongoing" forever with
  /// nothing paid for.
  bool get _isExpiredPending =>
      kind == TripKind.booking && status == 'pending' && !_today.isBefore(_startDay);

  /// The status to show the user, which overrides the raw backend [status]
  /// only for an expired unpaid booking (see [_isExpiredPending]) — the
  /// backend itself still says "pending" until someone actually cancels it.
  String get effectiveStatus => _isExpiredPending ? 'cancelled' : status;

  /// Which "My Trips" tab this trip sorts into. Draft and expired-pending
  /// trips are decided outright — the latter always to Past, regardless of
  /// its dates, per [_isExpiredPending]. A real cancellation (or a
  /// completed trip) still sorts by date like an active trip, so cancelling
  /// something far in advance keeps it under Next/Ongoing (labeled
  /// Cancelled) until its date actually arrives, rather than jumping
  /// straight to Past.
  TripBucket get bucket {
    if (kind == TripKind.customizedTour && status == 'draft') return TripBucket.draft;
    if (_isExpiredPending) return TripBucket.past;
    if (status == 'completed') return TripBucket.past;

    if (_today.isBefore(_startDay)) return TripBucket.next;
    if (!_today.isAfter(_endDay)) return TripBucket.ongoing;
    return TripBucket.past;
  }
}
