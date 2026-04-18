import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/palette.dart';
import 'form_peminjaman_screen.dart';
import 'peminjaman_lab_service.dart';
import 'peminjaman_lab_model.dart';

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
      // ✅ Sort data terbaru di atas berdasarkan id descending
      _future = PeminjamanService().getByUser(userId).then(
        (list) => list..sort((a, b) => b.id.compareTo(a.id)), // Menyortir berdasarkan id
      );
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
      case 'menunggu':
        return Colors.blue;
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
      case 'menunggu':
        return const Color(0xFFE0F7FA); // Menambahkan warna biru muda untuk "Menunggu"
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
                            // ✅ Judul "Peminjaman X" dan badge status dalam satu Row yang sejajar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Peminjaman ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Palette.textDark,
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
                                    item.status.toUpperCase(),
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tanggal Peminjaman: ${_formatTanggal(item.tanggal)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Palette.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Waktu Peminjaman: ${_formatJam(item.jamMulai)} - ${_formatJam(item.jamSelesai)} WIB',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Palette.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Keterangan: ${item.keterangan.isEmpty ? 'Tidak ada keterangan' : item.keterangan}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Palette.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: item.status.toLowerCase() == 'disetujui' || item.status.toLowerCase() == 'ditolak'
                                      ? null
                                      : () => _goToForm(item: item),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: item.status.toLowerCase() == 'disetujui' || item.status.toLowerCase() == 'ditolak'
                                      ? null
                                      : () => _deleteItem(item),
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