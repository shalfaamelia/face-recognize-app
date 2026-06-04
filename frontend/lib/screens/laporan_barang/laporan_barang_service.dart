import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'laporan_barang_model.dart';

class LaporanBarangService {
  Future<List<LaporanBarangItem>> getByUser(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/laporan-barang/user/$userId'),
      headers: ApiService.headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => LaporanBarangItem.fromJson(e)).toList();
    } else {
      throw Exception(_getErrorMessage(
        response.body,
        'Gagal memuat data laporan barang',
      ));
    }
  }

  Future<void> create({
    required int userId,
    required String ruang,
    required String noHp,
    required String tanggal,
    required String keterangan,
    required String deskripsi,
    String? fotoPath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/laporan-barang'),
    );

    request.fields['user_id'] = userId.toString();
    request.fields['ruang'] = ruang;
    request.fields['no_hp'] = noHp;
    request.fields['tanggal'] = tanggal;
    request.fields['keterangan'] = keterangan;
    request.fields['deskripsi'] = deskripsi;

    request.headers.addAll(ApiService.headers);

    if (fotoPath != null && fotoPath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', fotoPath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception(_getErrorMessage(
        response.body,
        'Gagal menambahkan laporan barang',
      ));
    }
  }

  Future<void> update({
    required int id,
    required int userId,
    required String ruang,
    required String noHp,
    required String tanggal,
    required String keterangan,
    required String deskripsi,
    String? fotoPath,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiService.baseUrl}/laporan-barang/$id'),
    );

    request.fields['user_id'] = userId.toString();
    request.fields['ruang'] = ruang;
    request.fields['no_hp'] = noHp;
    request.fields['tanggal'] = tanggal;
    request.fields['keterangan'] = keterangan;
    request.fields['deskripsi'] = deskripsi;

    request.headers.addAll(ApiService.headers);

    if (fotoPath != null && fotoPath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', fotoPath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(
        response.body,
        'Gagal memperbarui laporan barang',
      ));
    }
  }

  Future<void> delete({
    required int id,
    required int userId,
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/laporan-barang/$id?user_id=$userId'),
      headers: ApiService.headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(
        response.body,
        'Gagal menghapus laporan barang',
      ));
    }
  }

  String _getErrorMessage(String responseBody, String fallback) {
    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return decoded['message'].toString();
      }

      return fallback;
    } catch (_) {
      return fallback;
    }
  }
}