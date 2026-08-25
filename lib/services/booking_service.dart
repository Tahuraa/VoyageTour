import '../models/booking_model.dart';
import 'api_client.dart';

class BookingService {
  final String token;
  BookingService({required this.token});

  ApiClient get _client => ApiClient(token: token);

  Future<BookingModel> create({
    required String packageId,
    required int travelers,
    required DateTime travelDate,
    required String leadTravelerName,
    required String leadTravelerEmail,
    required String leadTravelerPhone,
    String? promoCode,
  }) async {
    final res = await _client.post('/bookings', {
      'package_id': packageId,
      'travelers': travelers,
      // Sent as UTC midnight so the calendar date the user picked survives
      // the round trip regardless of server timezone — a local (non-UTC)
      // DateTime serializes without a zone marker, which the backend would
      // otherwise parse as server-local time and shift by a day.
      'travel_date': DateTime.utc(travelDate.year, travelDate.month, travelDate.day).toIso8601String(),
      'lead_traveler_name': leadTravelerName,
      'lead_traveler_email': leadTravelerEmail,
      'lead_traveler_phone': leadTravelerPhone,
      'promo_code': ?promoCode,
    });
    return BookingModel.fromJson(res['booking'] as Map<String, dynamic>);
  }

  Future<BookingModel> getById(String id) async {
    final res = await _client.get('/bookings/$id');
    return BookingModel.fromJson(res['booking'] as Map<String, dynamic>);
  }

  Future<List<BookingModel>> listMine() async {
    final res = await _client.get('/bookings');
    return (res['bookings'] as List<dynamic>)
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> cancel(String id) async {
    final res = await _client.patch('/bookings/$id/cancel', {});
    return BookingModel.fromJson(res['booking'] as Map<String, dynamic>);
  }
}
