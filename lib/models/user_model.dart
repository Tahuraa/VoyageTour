import '../config/api_config.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        profileImage: json['profile_image'] as String?,
        role: json['role'] as String? ?? 'user',
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      );

  String? get profileImageUrl {
    if (profileImage == null || profileImage!.isEmpty) return null;
    if (profileImage!.startsWith('http')) return profileImage;
    return '${ApiConfig.mediaBaseUrl}$profileImage';
  }
}
