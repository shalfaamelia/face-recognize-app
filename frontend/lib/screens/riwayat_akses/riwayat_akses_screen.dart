import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/palette.dart';

// ─── Model Log Akses ───────────────────────────────────────
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

    // Coba format ISO dulu
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    // Coba format: Sat, 11 Apr 2026 15:54:36 GMT
    try {
      return DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US')
          .parseUtc(raw)
          .toLocal();
    } catch (_) {}

    // Coba format lain kalau ada
    try {
      return DateFormat("EEE, dd MMM yyyy HH:mm:ss", 'en_US')
          .parse(raw)
          .toLocal();
    } catch (_) {}

    throw FormatException('Invalid date format', raw);
  }
}

// ─── Service API ────────────────────────────────────────────
class MonitoringService {
  Future<List<LogAkses>> fetchUserLogs(int userId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/monitoring/$userId'),
      headers: {'Content-Type': 'application/json'},
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

// ─── Halaman Riwayat Akses ─────────────────────────────────
class RiwayatAksesScreen extends StatefulWidget {
  final int userId;
  const RiwayatAksesScreen({super.key, required this.userId});

  @override
  State<RiwayatAksesScreen> createState() => _RiwayatAksesScreenState();
}

class _RiwayatAksesScreenState extends State<RiwayatAksesScreen> {
  late Future<List<LogAkses>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    _logsFuture = MonitoringService().fetchUserLogs(widget.userId);
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgPage,
      appBar: AppBar(
        title: const Text('Riwayat Akses'),
        backgroundColor: Palette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<LogAkses>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Terjadi kesalahan:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(
              child: Text('Belum ada riwayat akses'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadLogs();
              });
              await _logsFuture;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final log = logs[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Palette.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Palette.cardBorder),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Palette.blueLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.history_outlined,
                          color: Palette.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.nama,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Palette.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'NIM: ${log.nim}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Palette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${log.prodi} • ${log.kelas}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.greenLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDateTime(log.masuk),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Palette.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}