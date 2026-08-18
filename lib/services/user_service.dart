import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_client.dart';

class UserService {
  final String token;
  UserService({required this.token});

  Future<Map<String, dynamic>> uploadPhoto(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/users/me/photo'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('photo', file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final decoded = res.body.isNotEmpty
        ? jsonDecode(res.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    throw ApiException(decoded['message'] as String? ?? 'Photo upload failed');
  }
}
