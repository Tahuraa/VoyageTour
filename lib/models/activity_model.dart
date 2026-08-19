class ActivityModel {
  final String id;
  final String name;
  final String location;
  final String category;
  final double price;
  final int? durationMinutes;
  final String? imageUrl;

  ActivityModel({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    required this.price,
    this.durationMinutes,
    this.imageUrl,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
        id: json['_id'] as String,
        name: json['name'] as String,
        location: json['location'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        durationMinutes: json['duration_minutes'] as int?,
        imageUrl: json['image_url'] as String?,
      );
}
