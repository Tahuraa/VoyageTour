import '../booking_model.dart';

class AdminStatsModel {
  final int totalUsers;
  final int totalPackages;
  final int totalDestinations;
  final int totalBookings;
  final Map<String, int> bookingsByStatus;
  final double totalRevenue;
  final List<BookingModel> recentBookings;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalPackages,
    required this.totalDestinations,
    required this.totalBookings,
    required this.bookingsByStatus,
    required this.totalRevenue,
    required this.recentBookings,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) => AdminStatsModel(
        totalUsers: json['totalUsers'] as int,
        totalPackages: json['totalPackages'] as int,
        totalDestinations: json['totalDestinations'] as int,
        totalBookings: json['totalBookings'] as int,
        bookingsByStatus: (json['bookingsByStatus'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        recentBookings: (json['recentBookings'] as List<dynamic>)
            .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
