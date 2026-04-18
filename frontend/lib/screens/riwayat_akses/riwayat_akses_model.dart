import 'package:intl/intl.dart';

class LogAkses {
  final int id;
  final String kode;
  final String nama;
  final String nim;
  final String prodi;
  final String kelas;
  final DateTime masuk;

  LogAkses({
    required this.id,
    required this.kode,
    required this.nama,
    required this.nim,
    required this.prodi,
    required this.kelas,
    required this.masuk,
  });

  factory LogAkses.fromJson(Map<String, dynamic> json) {
    return LogAkses(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      kode: (json['kode'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      nim: (json['nim'] ?? '').toString(),
      prodi: (json['prodi'] ?? '').toString(),
      kelas: (json['kelas'] ?? '').toString(),
      masuk: _parseTanggal(json['masuk']),
    );
  }

  static DateTime _parseTanggal(dynamic value) {
    final raw = value.toString().trim();

    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    try {
      return DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
          .parseUtc(raw)
          .toLocal();
    } catch (_) {}

    try {
      return DateFormat("EEE, dd MMM yyyy HH:mm:ss", 'en_US')
          .parse(raw)
          .toLocal();
    } catch (_) {}

    throw FormatException('Invalid date format', raw);
  }
}
