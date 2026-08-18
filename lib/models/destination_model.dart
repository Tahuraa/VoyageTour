class DestinationModel {
  final String id;
  final String name;
  final String country;
  final String? description;
  final String? imageUrl;
  final double? ratingAvg;
  final int reviewCount;
  final int packageCount;

  DestinationModel({
    required this.id,
    required this.name,
    required this.country,
    this.description,
    this.imageUrl,
    this.ratingAvg,
    this.reviewCount = 0,
    this.packageCount = 0,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) => DestinationModel(
        id: json['_id'] as String,
        name: json['name'] as String,
        country: json['country'] as String,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
        reviewCount: json['review_count'] as int? ?? 0,
        packageCount: json['package_count'] as int? ?? 0,
      );
}
