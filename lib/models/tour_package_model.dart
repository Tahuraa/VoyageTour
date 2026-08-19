import 'activity_model.dart';
import 'destination_model.dart';

class ItineraryActivityEntry {
  final ActivityModel activity;
  final String? startTime;
  final String? notes;
  final bool isIncluded;
  final bool isOptional;

  ItineraryActivityEntry({
    required this.activity,
    this.startTime,
    this.notes,
    this.isIncluded = true,
    this.isOptional = false,
  });

  factory ItineraryActivityEntry.fromJson(Map<String, dynamic> json) => ItineraryActivityEntry(
        activity: ActivityModel.fromJson(json['activity_id'] as Map<String, dynamic>),
        startTime: json['start_time'] as String?,
        notes: json['notes'] as String?,
        isIncluded: json['is_included'] as bool? ?? true,
        isOptional: json['is_optional'] as bool? ?? false,
      );
}

class ItineraryDay {
  final int dayNumber;
  final String title;
  final String? description;
  final List<ItineraryActivityEntry> activities;

  ItineraryDay({
    required this.dayNumber,
    required this.title,
    this.description,
    this.activities = const [],
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        dayNumber: json['day_number'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
        activities: (json['activities'] as List<dynamic>? ?? [])
            .map((e) => ItineraryActivityEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TourPackageModel {
  final String id;
  final String title;
  final String? description;
  final double price;
  final int durationDays;
  final int maxPeople;
  final String? imageUrl;
  final String category;
  final DestinationModel destination;
  final double? ratingAvg;
  final int reviewCount;
  final int popularity;
  final List<String> includedServices;
  final List<ItineraryDay> itinerary;

  TourPackageModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.durationDays,
    required this.maxPeople,
    this.imageUrl,
    required this.category,
    required this.destination,
    this.ratingAvg,
    this.reviewCount = 0,
    this.popularity = 0,
    this.includedServices = const [],
    this.itinerary = const [],
  });

  factory TourPackageModel.fromJson(Map<String, dynamic> json) => TourPackageModel(
        id: json['_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        durationDays: json['duration_days'] as int,
        maxPeople: json['max_people'] as int,
        imageUrl: json['image_url'] as String?,
        category: json['category'] as String? ?? 'city',
        destination: DestinationModel.fromJson(json['destination'] as Map<String, dynamic>),
        ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
        reviewCount: json['review_count'] as int? ?? 0,
        popularity: json['popularity'] as int? ?? 0,
        includedServices: (json['included_services'] as List<dynamic>? ?? []).cast<String>(),
        itinerary: (json['itinerary'] as List<dynamic>? ?? [])
            .map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
