import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL untuk login (tanpa /api)
  static const String loginBaseUrl =
      "https://unfitting-bouncing-doorbell.ngrok-free.dev";

  // Base URL untuk semua endpoint /api
  static const String baseUrl =
      "https://unfitting-bouncing-doorbell.ngrok-free.dev/api";

  static Map<String, String> get headers {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  // -------------------------
  // LOGIN
  // -------------------------
  static Future<Map<String, dynamic>> login(String nama, String nim) async {
    final url = Uri.parse('$loginBaseUrl/login');
    debugPrint('Login URL: $url');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "nama": nama,
        "nim": nim,
      }),
    );

    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    late Map<String, dynamic> result;
    try {
      result = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Server tidak mengembalikan JSON. Cek URL ngrok atau endpoint Flask.',
      );
    }

    if (response.statusCode == 200) {
      final user = result['user'];
      if (user == null || user is! Map<String, dynamic>) {
        throw Exception('Response login tidak memiliki data user.');
      }
      return user;
    }

    throw Exception(result['message'] ?? 'Login gagal');
  }
}