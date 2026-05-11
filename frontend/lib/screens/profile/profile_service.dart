import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'profile_model.dart';

class ProfileService {
  final String baseUrl = '${ApiService.baseUrl}/users'; // sesuai backend

  Future<Profile> updateProfile({
    required int profileId,
    String? token,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$baseUrl/$profileId');

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final message = body['message'] ?? 'Gagal update profile';
      throw Exception(message);
    }

    final responseBody = jsonDecode(response.body);
    if (responseBody is Map<String, dynamic> &&
        responseBody.containsKey('id')) {
      return Profile.fromJson(responseBody);
    }

    return Profile(
      id: profileId,
      nama: data['nama']?.toString() ?? '',
      nim: data['nim']?.toString() ?? '',
      prodi: data['prodi']?.toString() ?? '',
      kelas: data['kelas']?.toString() ?? '',
      role: data['role']?.toString() ?? 'mahasiswa',
      email: data['email']?.toString(),
    );
  }
}
