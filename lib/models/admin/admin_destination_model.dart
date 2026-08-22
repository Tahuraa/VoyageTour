class AdminDestinationSummary {
  final String id;
  final String name;
  final String country;

  AdminDestinationSummary({required this.id, required this.name, required this.country});

  factory AdminDestinationSummary.fromJson(Map<String, dynamic> json) => AdminDestinationSummary(
        id: json['_id'] as String,
        name: json['name'] as String,
        country: json['country'] as String,
      );
}

class AdminDestinationModel {
  final String id;
  final String name;
  final String country;
  final String countryCode;
  final String? description;
  final String? imageUrl;
  final bool isFeatured;
  final String status;

  AdminDestinationModel({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    this.description,
    this.imageUrl,
    required this.isFeatured,
    required this.status,
  });

  factory AdminDestinationModel.fromJson(Map<String, dynamic> json) => AdminDestinationModel(
        id: json['_id'] as String,
        name: json['name'] as String,
        country: json['country'] as String,
        countryCode: json['country_code'] as String,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        isFeatured: json['is_featured'] as bool? ?? false,
        status: json['status'] as String? ?? 'active',
      );
}
