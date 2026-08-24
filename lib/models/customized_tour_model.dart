import 'activity_model.dart';
import 'destination_model.dart';

class HotelCategoryOption {
  final String category;
  final double pricePerNight;
  HotelCategoryOption({required this.category, required this.pricePerNight});

  factory HotelCategoryOption.fromJson(Map<String, dynamic> json) => HotelCategoryOption(
        category: json['category'] as String,
        pricePerNight: (json['price_per_night'] as num).toDouble(),
      );

  String get label => switch (category) {
        '3_star' => '3-Star',
        '4_star' => '4-Star',
        '5_star' => '5-Star',
        _ => category,
      };
}

class TransportationTypeOption {
  final String type;
  final double price;
  TransportationTypeOption({required this.type, required this.price});

  factory TransportationTypeOption.fromJson(Map<String, dynamic> json) => TransportationTypeOption(
        type: json['type'] as String,
        price: (json['price'] as num).toDouble(),
      );

  String get label => switch (type) {
        'private_car' => 'Private Car',
        'shared_shuttle' => 'Shared Shuttle',
        'tour_bus' => 'Tour Bus',
        _ => type,
      };
}

class CustomizationOptions {
  final List<HotelCategoryOption> hotelCategories;
  final List<TransportationTypeOption> transportationTypes;
  CustomizationOptions({required this.hotelCategories, required this.transportationTypes});

  factory CustomizationOptions.fromJson(Map<String, dynamic> json) => CustomizationOptions(
        hotelCategories: (json['hotelCategories'] as List<dynamic>)
            .map((e) => HotelCategoryOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        transportationTypes: (json['transportationTypes'] as List<dynamic>)
            .map((e) => TransportationTypeOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SelectedHotel {
  final double price;
  final String category;
  SelectedHotel({required this.price, required this.category});

  factory SelectedHotel.fromJson(Map<String, dynamic> json) => SelectedHotel(
        price: (json['price'] as num).toDouble(),
        category: json['category'] as String,
      );
}

class SelectedTransportation {
  final String type;
  final double price;
  SelectedTransportation({required this.type, required this.price});

  factory SelectedTransportation.fromJson(Map<String, dynamic> json) => SelectedTransportation(
        type: json['type'] as String,
        price: (json['price'] as num).toDouble(),
      );
}

class CustomizedActivityEntry {
  final String id;
  final int dayNumber;
  final ActivityModel activity;
  final String? startTime;
  final String? notes;
  final String source;
  final double price;

  CustomizedActivityEntry({
    required this.id,
    required this.dayNumber,
    required this.activity,
    this.startTime,
    this.notes,
    required this.source,
    required this.price,
  });

  factory CustomizedActivityEntry.fromJson(Map<String, dynamic> json) => CustomizedActivityEntry(
        id: json['_id'] as String,
        dayNumber: json['day_number'] as int,
        activity: ActivityModel.fromJson(json['activity_id'] as Map<String, dynamic>),
        startTime: json['start_time'] as String?,
        notes: json['notes'] as String?,
        source: json['source'] as String? ?? 'package',
        price: (json['price'] as num).toDouble(),
      );
}

class CustomizedTourPackageSummary {
  final String id;
  final String title;
  final String? imageUrl;
  final int durationDays;

  CustomizedTourPackageSummary({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.durationDays,
  });

  factory CustomizedTourPackageSummary.fromJson(Map<String, dynamic> json) => CustomizedTourPackageSummary(
        id: json['_id'] as String,
        title: json['title'] as String,
        imageUrl: json['image_url'] as String?,
        durationDays: json['duration_days'] as int,
      );
}

class CustomizedTourModel {
  final String id;
  final CustomizedTourPackageSummary tourPackage;
  final DestinationModel destination;
  final int travelers;
  final DateTime travelDate;
  final List<CustomizedActivityEntry> activities;
  final SelectedHotel? hotel;
  final SelectedTransportation? transportation;
  final double basePrice;
  final double activitiesPrice;
  final double hotelPrice;
  final double transportationPrice;
  final double totalPrice;
  final String status;

  CustomizedTourModel({
    required this.id,
    required this.tourPackage,
    required this.destination,
    required this.travelers,
    required this.travelDate,
    required this.activities,
    this.hotel,
    this.transportation,
    required this.basePrice,
    required this.activitiesPrice,
    required this.hotelPrice,
    required this.transportationPrice,
    required this.totalPrice,
    required this.status,
  });

  factory CustomizedTourModel.fromJson(Map<String, dynamic> json) => CustomizedTourModel(
        id: json['_id'] as String,
        tourPackage: CustomizedTourPackageSummary.fromJson(json['tour_package_id'] as Map<String, dynamic>),
        destination: DestinationModel.fromJson(json['destination_id'] as Map<String, dynamic>),
        travelers: json['travelers'] as int,
        travelDate: DateTime.parse(json['travel_date'] as String),
        activities: (json['activities'] as List<dynamic>)
            .map((e) => CustomizedActivityEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        // Mongoose materializes these nested objects as {price: 0} by default
        // (price has a schema default) even when nothing was ever selected —
        // treat them as "selected" only once their defining field is present.
        hotel: (json['hotel'] as Map<String, dynamic>?)?['category'] != null
            ? SelectedHotel.fromJson(json['hotel'] as Map<String, dynamic>)
            : null,
        transportation: (json['transportation'] as Map<String, dynamic>?)?['type'] != null
            ? SelectedTransportation.fromJson(json['transportation'] as Map<String, dynamic>)
            : null,
        basePrice: (json['base_price'] as num).toDouble(),
        activitiesPrice: (json['activities_price'] as num).toDouble(),
        hotelPrice: (json['hotel_price'] as num).toDouble(),
        transportationPrice: (json['transportation_price'] as num).toDouble(),
        totalPrice: (json['total_price'] as num).toDouble(),
        status: json['status'] as String,
      );

  Map<int, List<CustomizedActivityEntry>> get activitiesByDay {
    final map = <int, List<CustomizedActivityEntry>>{};
    for (final entry in activities) {
      map.putIfAbsent(entry.dayNumber, () => []).add(entry);
    }
    return map;
  }
}
