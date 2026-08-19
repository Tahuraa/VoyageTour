import 'package:flutter/foundation.dart';
import '../models/tour_package_model.dart';
import '../services/api_client.dart';
import '../services/catalog_service.dart';

class SearchProvider extends ChangeNotifier {
  final _catalogService = CatalogService();

  /// Destinations selected as chips. Packages matching ANY of these are
  /// returned (an OR search) so a user can compare several destinations
  /// side by side in one results list — e.g. "Switzerland, Italy, Japan".
  List<String> destinations = [];
  DateTime? startDate;
  DateTime? endDate;
  int travelers = 2;
  String? category;
  double? minPrice;
  double? maxPrice;
  String sort = 'popularity';

  bool isLoading = false;
  String? error;
  List<TourPackageModel> results = [];
  bool hasSearched = false;

  void addDestination(String destination) {
    final trimmed = destination.trim();
    if (trimmed.isEmpty) return;
    final exists = destinations.any((d) => d.toLowerCase() == trimmed.toLowerCase());
    if (exists) return;
    destinations = [...destinations, trimmed];
    notifyListeners();
    search();
  }

  void removeDestination(String destination) {
    destinations = destinations.where((d) => d != destination).toList();
    notifyListeners();
    if (destinations.isEmpty) {
      results = [];
      hasSearched = false;
      notifyListeners();
    } else {
      search();
    }
  }

  void clearDestinations() {
    destinations = [];
    results = [];
    hasSearched = false;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate = start;
    endDate = end;
    notifyListeners();
  }

  void setTravelers(int value) {
    travelers = value;
    notifyListeners();
  }

  void setCategory(String? value) {
    category = value;
    notifyListeners();
  }

  void setPriceRange(double? min, double? max) {
    minPrice = min;
    maxPrice = max;
    notifyListeners();
  }

  void setSort(String value) {
    sort = value;
    notifyListeners();
  }

  /// Replaces the current destination selection with a single one and
  /// searches immediately — used by Home screen shortcuts (e.g. tapping a
  /// destination card or a "trending" chip).
  Future<void> searchFor(String destination) async {
    destinations = [destination.trim()];
    await search();
  }

  Future<void> search() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      results = await _catalogService.getPackages(
        PackageSearchParams(
          destinations: destinations,
          category: category,
          minPrice: minPrice,
          maxPrice: maxPrice,
          startDate: startDate,
          endDate: endDate,
          sort: sort,
        ),
      );
      hasSearched = true;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not reach the server. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
