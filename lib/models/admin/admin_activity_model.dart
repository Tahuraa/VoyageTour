import 'admin_destination_model.dart';

class AdminActivityModel {
  final String id;
  final String name;
  final String location;
  final String? description;
  final int? durationMinutes;
  final double price;
  final String category;
  final String? imageUrl;
  final String status;
  final AdminDestinationSummary destination;

  AdminActivityModel({
    required this.id,
    required this.name,
    required this.location,
    this.description,
    this.durationMinutes,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.status,
    required this.destination,
  });

  factory AdminActivityModel.fromJson(Map<String, dynamic> json) => AdminActivityModel(
        id: json['_id'] as String,
        name: json['name'] as String,
        location: json['location'] as String,
        description: json['description'] as String?,
        durationMinutes: json['duration_minutes'] as int?,
        price: (json['price'] as num).toDouble(),
        category: json['category'] as String,
        imageUrl: json['image_url'] as String?,
        status: json['status'] as String? ?? 'active',
        destination: AdminDestinationSummary.fromJson(json['destination_id'] as Map<String, dynamic>),
      );
}
