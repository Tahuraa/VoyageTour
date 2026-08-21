import '../models/favorite_model.dart';
import 'api_client.dart';

class FavoriteService {
  final String token;
  FavoriteService({required this.token});

  ApiClient get _client => ApiClient(token: token);

  Future<List<FavoriteModel>> list() async {
    final res = await _client.get('/favorites?type=package');
    return (res['favorites'] as List<dynamic>)
        .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> listIds() async {
    final res = await _client.get('/favorites/ids?type=package');
    return (res['ids'] as List<dynamic>).cast<String>().toSet();
  }

  Future<bool> toggle(String packageId) async {
    final res = await _client.post('/favorites/toggle', {'type': 'package', 'reference_id': packageId});
    return res['favorited'] as bool;
  }
}
