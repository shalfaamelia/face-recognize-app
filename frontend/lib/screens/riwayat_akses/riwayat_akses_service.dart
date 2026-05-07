import 'dart:convert';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'riwayat_akses_model.dart';

class MonitoringService {
  Future<List<LogAkses>> fetchUserLogs(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/monitoring_user?user_id=$userId'),
      headers: ApiService.headers,
    );

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.map((e) => LogAkses.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception('Gagal memuat log akses: ${response.body}');
    }
  }
}