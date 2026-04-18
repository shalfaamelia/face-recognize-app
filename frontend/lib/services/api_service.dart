import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.110:5000";

  static Future<Map<String, dynamic>> login(String nama, String nim) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nama": nama, "nim": nim}),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['user'];
      } else {
        final message = jsonDecode(response.body)['message'];
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('Exception di ApiService.login: $e');
      rethrow;
    }
  }
}
