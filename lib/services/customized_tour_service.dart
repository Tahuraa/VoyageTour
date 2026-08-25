import '../models/activity_model.dart';
import '../models/booking_model.dart';
import '../models/customized_tour_model.dart';
import 'api_client.dart';

class CustomizedTourService {
  final String token;
  CustomizedTourService({required this.token});

  ApiClient get _client => ApiClient(token: token);

  // Sent as UTC midnight so the calendar date the user picked survives the
  // round trip regardless of server timezone — a local (non-UTC) DateTime
  // serializes without a zone marker, which the backend would otherwise
  // parse as server-local time and shift by a day.
  static String _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day).toIso8601String();

  static Future<CustomizationOptions> getOptions() async {
    final res = await ApiClient().get('/customized-tours/options');
    return CustomizationOptions.fromJson(res);
  }

  static Future<List<ActivityModel>> getActivitiesForDestination(String destinationId) async {
    final res = await ApiClient().get('/activities?destination_id=$destinationId');
    return (res['activities'] as List<dynamic>)
        .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CustomizedTourModel> create({
    required String tourPackageId,
    required int travelers,
    required DateTime travelDate,
  }) async {
    final res = await _client.post('/customized-tours', {
      'tour_package_id': tourPackageId,
      'travelers': travelers,
      'travel_date': _dateOnly(travelDate),
    });
    return CustomizedTourModel.fromJson(res['customizedTour'] as Map<String, dynamic>);
  }

  Future<CustomizedTourModel> getById(String id) async {
    final res = await _client.get('/customized-tours/$id');
    return CustomizedTourModel.fromJson(res['customizedTour'] as Map<String, dynamic>);
  }

  Future<CustomizedTourModel> updateTripDetails(String id, {int? travelers, DateTime? travelDate}) async {
    final travelDateStr = travelDate != null ? _dateOnly(travelDate) : null;
    final res = await _client.patch('/customized-tours/$id', {
      'travelers': ?travelers,
      'travel_date': ?travelDateStr,
    });
    return CustomizedTourModel.fromJson(res['customizedTour'] as Map<String, dynamic>);
  }

  Future<CustomizedTourModel> addActivity(
    String id, {
    required int dayNumber,
    required String activityId,
  }) async {
    final res = await _client.post('/customized-tours/$id/activities', {
      'day_number': dayNumber,
      'activity_id': activityId,
    });
    return CustomizedTourModel.fromJson(res['customizedTour'] as Map<String, dynamic>);
  }

  Future<CustomizedTourModel> removeActivity(String id, String entryId) async {
    final res = await _client.delete('/customized-tours/$id/activities/$entryId');
    return CustomizedTourModel.fromJson(res['customizedTour'] as Map<String, dynamic>);
  }

  Future<CustomizedTourModel> selectHotel(String id, {required String category}) async {
    final res = await _client.put('/customized-tours/$id/hotel', {'category': category});
    return CustomizedTourModel.fromJson(res['customizedTour'] as Map<String, dynamic>);
  }

  Future<CustomizedTourModel> clearHotel(String id) async {
    final res = await _client.delete('/customized-tours/$id/hotel');
    return CustomizedTourModel.fromJson(res['customizedTour'] as Map<String, dynamic>);
  }

  Future<CustomizedTourModel> selectTransportation(String id, {required String type}) async {
    final res = await _client.put('/customized-tours/$id/transportation', {'type': type});
    return CustomizedTourModel.fromJson(res['customizedTour'] as Map<String, dynamic>);
  }

  Future<CustomizedTourModel> clearTransportation(String id) async {
    final res = await _client.delete('/customized-tours/$id/transportation');
    return CustomizedTourModel.fromJson(res['customizedTour'] as Map<String, dynamic>);
  }

  Future<BookingModel> confirm(
    String id, {
    String? leadTravelerName,
    String? leadTravelerEmail,
    String? leadTravelerPhone,
    String? promoCode,
  }) async {
    final res = await _client.post('/customized-tours/$id/confirm', {
      'lead_traveler_name': ?leadTravelerName,
      'lead_traveler_email': ?leadTravelerEmail,
      'lead_traveler_phone': ?leadTravelerPhone,
      'promo_code': ?promoCode,
    });
    return BookingModel.fromJson(res['booking'] as Map<String, dynamic>);
  }

  Future<List<CustomizedTourModel>> listMine() async {
    final res = await _client.get('/customized-tours');
    return (res['customizedTours'] as List<dynamic>)
        .map((e) => CustomizedTourModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CustomizedTourModel> cancel(String id) async {
    final res = await _client.patch('/customized-tours/$id/cancel', {});
    return CustomizedTourModel.fromJson(res['customizedTour'] as Map<String, dynamic>);
  }
}
