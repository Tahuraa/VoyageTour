import 'package:flutter/foundation.dart';
import '../services/favorite_service.dart';

/// Tracks which tour package ids the current user has favorited, so heart
/// icons across Home / Search / Package Details stay in sync without each
/// screen re-fetching the full favorites list.
class FavoritesProvider extends ChangeNotifier {
  Set<String> _ids = {};

  bool isFavorite(String packageId) => _ids.contains(packageId);

  Future<void> load(String token) async {
    try {
      _ids = await FavoriteService(token: token).listIds();
      notifyListeners();
    } catch (_) {
      // Leave whatever state we had; screens fall back to "not favorited".
    }
  }

  void clear() {
    _ids = {};
    notifyListeners();
  }

  Future<void> toggle(String token, String packageId) async {
    final wasFavorite = _ids.contains(packageId);
    wasFavorite ? _ids.remove(packageId) : _ids.add(packageId);
    notifyListeners();

    try {
      final favorited = await FavoriteService(token: token).toggle(packageId);
      if (favorited == _ids.contains(packageId)) return;
      favorited ? _ids.add(packageId) : _ids.remove(packageId);
      notifyListeners();
    } catch (_) {
      wasFavorite ? _ids.add(packageId) : _ids.remove(packageId);
      notifyListeners();
    }
  }
}
