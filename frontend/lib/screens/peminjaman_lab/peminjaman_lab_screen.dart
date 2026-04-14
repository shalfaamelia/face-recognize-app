import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/palette.dart';
import 'form_peminjaman_screen.dart';

class PeminjamanItem {
  final int id;
  final int userId;
  final String nama;
  final String nim;
  final String prodi;
  final String kelas;
  final String tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String keterangan;
  final String status;

  PeminjamanItem({
    required this.id,
    required this.userId,
    required this.nama,
    required this.nim,
    required this.prodi,
    required this.kelas,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.keterangan,
    required this.status,
  });

  factory PeminjamanItem.fromJson(Map<String, dynamic> json) {
    return PeminjamanItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      nama: (json['nama'] ?? '').toString(),
      nim: (json['nim'] ?? '').toString(),
      prodi: (json['prodi'] ?? '').toString(),
      kelas: (json['kelas'] ?? '').toString(),
      tanggal: (json['tanggal'] ?? '').toString(),
      jamMulai: (json['jam_mulai'] ?? '').toString(),
      jamSelesai: (json['jam_selesai'] ?? '').toString(),
      keterangan: (json['keterangan'] ?? '').toString(),
      status: (json['status'] ?? 'menunggu').toString(),
    );
  }
}

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

class PeminjamanLabScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const PeminjamanLabScreen({super.key, required this.user});

  @override
  State<PeminjamanLabScreen> createState() => _PeminjamanLabScreenState();
}

class _PeminjamanLabScreenState extends State<PeminjamanLabScreen> {
  late Future<List<PeminjamanItem>> _future;

  int? _parseUserId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final userId = _parseUserId(widget.user['id']);
    if (userId != null) {
      _future = PeminjamanService().getByUser(userId);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await _future;
  }

  Future<void> _goToForm({PeminjamanItem? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormPeminjamanScreen(
          user: widget.user,
          item: item,
        ),
      ),
    );

    if (result == true) {
      _refresh();
    }
  }

  Future<void> _deleteItem(PeminjamanItem item) async {
    final userId = _parseUserId(widget.user['id']);
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Peminjaman'),
        content: const Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PeminjamanService().delete(id: item.id, userId: userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil dihapus')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus: $e')),
      );
    }
  }

  String _formatTanggal(String tanggal) {
    try {
      final dt = DateTime.parse(tanggal);
      return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return tanggal;
    }
  }

  String _formatJam(String jam) {
    return jam.length >= 5 ? jam.substring(0, 5) : jam;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Palette.green;
      case 'ditolak':
        return Colors.red;
      case 'selesai':
        return Palette.blue;
      default:
        return Palette.orange;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Palette.greenLight;
      case 'ditolak':
        return const Color(0xFFFFE5E5);
      case 'selesai':
        return Palette.blueLight;
      default:
        return Palette.orangeLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _parseUserId(widget.user['id']);

    return Scaffold(
      backgroundColor: Palette.bgPage,
      appBar: AppBar(
        title: const Text('Peminjaman Lab'),
        backgroundColor: Palette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Palette.blue,
        onPressed: userId == null ? null : () => _goToForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: userId == null
          ? const Center(child: Text('ID user tidak ditemukan'))
          : FutureBuilder<List<PeminjamanItem>>(
              future: _future,
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

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('Belum ada data peminjaman')),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Palette.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Palette.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatTanggal(item.tanggal),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Palette.textDark,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusBg(item.status),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(item.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatJam(item.jamMulai)} - ${_formatJam(item.jamSelesai)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Palette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.keterangan.isEmpty ? '-' : item.keterangan,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Palette.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _goToForm(item: item),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _deleteItem(item),
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Hapus'),
                                ),
                              ],
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