import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'peminjaman_lab_model.dart';

class PeminjamanService {
  Future<List<PeminjamanItem>> getByUser(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/peminjaman/user/$userId'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => PeminjamanItem.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat data peminjaman');
    }
  }

  Future<void> create({
    required int userId,
    required String tanggal,
    required String jamMulai,
    required String jamSelesai,
    required String keterangan,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/peminjaman'), 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'tanggal': tanggal,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'keterangan': keterangan,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  Future<void> update({
    required int id,
    required int userId,
    required String tanggal,
    required String jamMulai,
    required String jamSelesai,
    required String keterangan,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/peminjaman/$id'), 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'tanggal': tanggal,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'keterangan': keterangan,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  Future<void> delete({
    required int id,
    required int userId,
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/peminjaman/$id?user_id=$userId'), 
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }
  }
}