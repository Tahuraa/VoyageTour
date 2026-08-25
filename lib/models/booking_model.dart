import 'destination_model.dart';

class BookingPackageSummary {
  final String id;
  final String title;
  final String? imageUrl;
  final int durationDays;
  final DestinationModel destination;

  BookingPackageSummary({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.durationDays,
    required this.destination,
  });

  factory BookingPackageSummary.fromJson(Map<String, dynamic> json) =>
      BookingPackageSummary(
        id: json['_id'] as String,
        title: json['title'] as String,
        imageUrl: json['image_url'] as String?,
        durationDays: json['duration_days'] as int,
        destination: DestinationModel.fromJson(
          json['destination_id'] as Map<String, dynamic>,
        ),
      );
}

class BookingModel {
  final String id;
  final BookingPackageSummary package;
  final DateTime travelStartDate;
  final DateTime travelEndDate;
  final int travelers;
  final double totalPrice;
  final String status;
  final String leadTravelerName;
  final String leadTravelerEmail;
  final String leadTravelerPhone;
  // Only present when fetched via the admin API, which populates the
  // booking owner; absent (null) on a user's own booking endpoints.
  final String? bookedByName;
  final String? bookedByEmail;
  final DateTime? createdAt;
  // Set only once a confirmed (paid) booking has been cancelled — the
  // refund percentage that was applied. Null otherwise.
  final int? refundPercent;
  // Set only when a valid promo code was applied at booking time.
  final String? promoCode;
  final double discountAmount;

  BookingModel({
    required this.id,
    required this.package,
    required this.travelStartDate,
    required this.travelEndDate,
    required this.travelers,
    required this.totalPrice,
    required this.status,
    required this.leadTravelerName,
    required this.leadTravelerEmail,
    required this.leadTravelerPhone,
    this.bookedByName,
    this.bookedByEmail,
    this.createdAt,
    this.refundPercent,
    this.promoCode,
    this.discountAmount = 0,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final user = json['user_id'];
    return BookingModel(
      id: json['_id'] as String,
      package: BookingPackageSummary.fromJson(
        json['package_id'] as Map<String, dynamic>,
      ),
      travelStartDate: DateTime.parse(json['travel_start_date'] as String),
      travelEndDate: DateTime.parse(json['travel_end_date'] as String),
      travelers: json['travelers'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
      leadTravelerName: json['lead_traveler_name'] as String,
      leadTravelerEmail: json['lead_traveler_email'] as String,
      leadTravelerPhone: json['lead_traveler_phone'] as String,
      bookedByName: user is Map ? user['name'] as String? : null,
      bookedByEmail: user is Map ? user['email'] as String? : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      refundPercent: json['refund_percent'] as int?,
      promoCode: json['promo_code'] as String?,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
