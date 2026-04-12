import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000";

  static Future<Map<String, dynamic>> login(String nama, String nim) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nama": nama, "nim": nim}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['user'];
    } else {
      final message = jsonDecode(response.body)['message'];
      throw Exception(message);
    }
  }
}