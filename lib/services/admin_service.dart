import '../models/admin/admin_activity_model.dart';
import '../models/admin/admin_destination_model.dart';
import '../models/admin/admin_package_model.dart';
import '../models/admin/admin_promotion_model.dart';
import '../models/admin/admin_stats_model.dart';
import '../models/admin/admin_user_model.dart';
import '../models/booking_model.dart';
import 'api_client.dart';

class AdminService {
  final String token;
  AdminService({required this.token});

  ApiClient get _client => ApiClient(token: token);

  Future<AdminStatsModel> getStats() async {
    final res = await _client.get('/admin/stats');
    return AdminStatsModel.fromJson(res);
  }

  Future<List<AdminUserModel>> listUsers() async {
    final res = await _client.get('/admin/users');
    return (res['users'] as List<dynamic>).map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---------- Bookings ----------

  Future<List<BookingModel>> listBookings({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final res = await _client.get('/admin/bookings$query');
    return (res['bookings'] as List<dynamic>).map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel> updateBookingStatus(String id, String status) async {
    final res = await _client.patch('/admin/bookings/$id/status', {'status': status});
    return BookingModel.fromJson(res['booking'] as Map<String, dynamic>);
  }

  // ---------- Destinations ----------

  Future<List<AdminDestinationModel>> listDestinations() async {
    final res = await _client.get('/admin/destinations');
    return (res['destinations'] as List<dynamic>)
        .map((e) => AdminDestinationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminDestinationModel> createDestination(Map<String, dynamic> body) async {
    final res = await _client.post('/admin/destinations', body);
    return AdminDestinationModel.fromJson(res['destination'] as Map<String, dynamic>);
  }

  Future<AdminDestinationModel> updateDestination(String id, Map<String, dynamic> body) async {
    final res = await _client.put('/admin/destinations/$id', body);
    return AdminDestinationModel.fromJson(res['destination'] as Map<String, dynamic>);
  }

  Future<void> deleteDestination(String id) => _client.delete('/admin/destinations/$id');

  // ---------- Activities ----------

  Future<List<AdminActivityModel>> listActivities({String? destinationId}) async {
    final query = destinationId != null ? '?destination_id=$destinationId' : '';
    final res = await _client.get('/admin/activities$query');
    return (res['activities'] as List<dynamic>)
        .map((e) => AdminActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminActivityModel> createActivity(Map<String, dynamic> body) async {
    final res = await _client.post('/admin/activities', body);
    return AdminActivityModel.fromJson(res['activity'] as Map<String, dynamic>);
  }

  Future<AdminActivityModel> updateActivity(String id, Map<String, dynamic> body) async {
    final res = await _client.put('/admin/activities/$id', body);
    return AdminActivityModel.fromJson(res['activity'] as Map<String, dynamic>);
  }

  Future<void> deleteActivity(String id) => _client.delete('/admin/activities/$id');

  // ---------- Packages ----------

  Future<List<AdminPackageModel>> listPackages() async {
    final res = await _client.get('/admin/packages');
    return (res['packages'] as List<dynamic>).map((e) => AdminPackageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminPackageModel> createPackage(Map<String, dynamic> body) async {
    final res = await _client.post('/admin/packages', body);
    return AdminPackageModel.fromJson(res['package'] as Map<String, dynamic>);
  }

  Future<AdminPackageModel> updatePackage(String id, Map<String, dynamic> body) async {
    final res = await _client.put('/admin/packages/$id', body);
    return AdminPackageModel.fromJson(res['package'] as Map<String, dynamic>);
  }

  Future<void> deletePackage(String id) => _client.delete('/admin/packages/$id');

  // ---------- Promotions ----------

  Future<List<AdminPromotionModel>> listPromotions() async {
    final res = await _client.get('/admin/promotions');
    return (res['promotions'] as List<dynamic>)
        .map((e) => AdminPromotionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminPromotionModel> createPromotion(Map<String, dynamic> body) async {
    final res = await _client.post('/admin/promotions', body);
    return AdminPromotionModel.fromJson(res['promotion'] as Map<String, dynamic>);
  }

  Future<AdminPromotionModel> updatePromotion(String id, Map<String, dynamic> body) async {
    final res = await _client.put('/admin/promotions/$id', body);
    return AdminPromotionModel.fromJson(res['promotion'] as Map<String, dynamic>);
  }

  Future<void> deletePromotion(String id) => _client.delete('/admin/promotions/$id');
}
