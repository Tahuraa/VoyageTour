import 'admin_destination_model.dart';

class AdminItineraryActivity {
  final String activityId;
  final String activityName;
  final double activityPrice;
  final String? startTime;
  final String? notes;
  final bool isIncluded;
  final bool isOptional;

  AdminItineraryActivity({
    required this.activityId,
    required this.activityName,
    required this.activityPrice,
    this.startTime,
    this.notes,
    this.isIncluded = true,
    this.isOptional = false,
  });

  factory AdminItineraryActivity.fromJson(Map<String, dynamic> json) {
    final raw = json['activity_id'];
    String id;
    String name;
    double price;
    if (raw is Map<String, dynamic>) {
      id = raw['_id'] as String;
      name = raw['name'] as String? ?? 'Activity';
      price = (raw['price'] as num?)?.toDouble() ?? 0;
    } else {
      id = raw as String;
      name = 'Activity';
      price = 0;
    }
    return AdminItineraryActivity(
      activityId: id,
      activityName: name,
      activityPrice: price,
      startTime: json['start_time'] as String?,
      notes: json['notes'] as String?,
      isIncluded: json['is_included'] as bool? ?? true,
      isOptional: json['is_optional'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'activity_id': activityId,
        if (startTime != null && startTime!.isNotEmpty) 'start_time': startTime,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'is_included': isIncluded,
        'is_optional': isOptional,
      };
}

class AdminItineraryDay {
  final int dayNumber;
  final String title;
  final String? description;
  final List<AdminItineraryActivity> activities;

  AdminItineraryDay({
    required this.dayNumber,
    required this.title,
    this.description,
    this.activities = const [],
  });

  factory AdminItineraryDay.fromJson(Map<String, dynamic> json) => AdminItineraryDay(
        dayNumber: json['day_number'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
        activities: (json['activities'] as List<dynamic>? ?? [])
            .map((e) => AdminItineraryActivity.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'title': title,
        if (description != null && description!.isNotEmpty) 'description': description,
        'activities': activities.map((a) => a.toJson()).toList(),
      };
}

class AdminPackageModel {
  final String id;
  final String title;
  final String? description;
  final double price;
  final int durationDays;
  final int maxPeople;
  final String category;
  final String? imageUrl;
  final List<String> includedServices;
  final String status;
  final AdminDestinationSummary destination;
  final List<AdminItineraryDay> itinerary;

  AdminPackageModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.durationDays,
    required this.maxPeople,
    required this.category,
    this.imageUrl,
    this.includedServices = const [],
    required this.status,
    required this.destination,
    this.itinerary = const [],
  });

  factory AdminPackageModel.fromJson(Map<String, dynamic> json) => AdminPackageModel(
        id: json['_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        durationDays: json['duration_days'] as int,
        maxPeople: json['max_people'] as int,
        category: json['category'] as String,
        imageUrl: json['image_url'] as String?,
        includedServices: (json['included_services'] as List<dynamic>? ?? []).cast<String>(),
        status: json['status'] as String? ?? 'active',
        destination: AdminDestinationSummary.fromJson(json['destination_id'] as Map<String, dynamic>),
        itinerary: (json['itinerary'] as List<dynamic>? ?? [])
            .map((e) => AdminItineraryDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
