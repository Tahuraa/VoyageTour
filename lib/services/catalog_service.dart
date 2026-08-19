import '../models/destination_model.dart';
import '../models/promotion_model.dart';
import '../models/tour_package_model.dart';
import 'api_client.dart';

class PackageSearchParams {
  final List<String> destinations;
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sort;

  const PackageSearchParams({
    this.destinations = const [],
    this.category,
    this.minPrice,
    this.maxPrice,
    this.startDate,
    this.endDate,
    this.sort = 'popularity',
  });

  Map<String, String> toQuery() => {
        if (destinations.isNotEmpty) 'destinations': destinations.join(','),
        if (category != null) 'category': category!,
        if (minPrice != null) 'minPrice': minPrice!.toStringAsFixed(0),
        if (maxPrice != null) 'maxPrice': maxPrice!.toStringAsFixed(0),
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        'sort': sort,
      };
}

class CatalogService {
  final _client = ApiClient();

  Future<List<DestinationModel>> getDestinations({bool featuredOnly = false}) async {
    final path = featuredOnly ? '/destinations?featured=true' : '/destinations';
    final res = await _client.get(path);
    return (res['destinations'] as List<dynamic>)
        .map((e) => DestinationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TourPackageModel>> getPackages(PackageSearchParams params) async {
    final query = Uri(queryParameters: params.toQuery()).query;
    final res = await _client.get('/packages?$query');
    return (res['packages'] as List<dynamic>)
        .map((e) => TourPackageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TourPackageModel> getPackageById(String id) async {
    final res = await _client.get('/packages/$id');
    return TourPackageModel.fromJson(res['package'] as Map<String, dynamic>);
  }

  Future<List<PromotionModel>> getActivePromotions() async {
    final res = await _client.get('/promotions/active');
    return (res['promotions'] as List<dynamic>)
        .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
