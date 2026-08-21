import 'tour_package_model.dart';

class FavoriteModel {
  final String id;
  final TourPackageModel package;

  FavoriteModel({required this.id, required this.package});

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
        id: json['favorite_id'] as String,
        package: TourPackageModel.fromJson(json['package'] as Map<String, dynamic>),
      );
}
