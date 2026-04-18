import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/palette.dart';
import 'form_laporan_barang_screen.dart';
import 'laporan_barang_model.dart';
import 'laporan_barang_service.dart';

class LaporanBarangScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const LaporanBarangScreen({super.key, required this.user});

  @override
  State<LaporanBarangScreen> createState() => _LaporanBarangScreenState();
}

class _LaporanBarangScreenState extends State<LaporanBarangScreen> {
  late Future<List<LaporanBarangItem>> _future;

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
      _future = LaporanBarangService().getByUser(userId).then(
        (list) => list..sort((a, b) => b.id.compareTo(a.id)),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await _future;
  }

  Future<void> _goToForm({LaporanBarangItem? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormLaporanBarangScreen(
          user: widget.user,
          item: item,
        ),
      ),
    );

    if (result == true) {
      _refresh();
    }
  }

  Future<void> _deleteItem(LaporanBarangItem item) async {
    final userId = _parseUserId(widget.user['id']);
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text('Yakin ingin menghapus laporan ini?'),
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
      await LaporanBarangService().delete(id: item.id, userId: userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dihapus')),
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

  Color _jenisColor(String jenis) {
    return jenis == 'temuan' ? Palette.green : Colors.red;
  }

  Color _jenisBg(String jenis) {
    return jenis == 'temuan'
        ? Palette.greenLight
        : const Color(0xFFFFE5E5);
  }

  @override
  Widget build(BuildContext context) {
    final userId = _parseUserId(widget.user['id']);

    return Scaffold(
      backgroundColor: Palette.bgPage,
      appBar: AppBar(
        title: const Text('Laporan Barang'),
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
          : FutureBuilder<List<LaporanBarangItem>>(
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
                        Center(child: Text('Belum ada laporan barang')),
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
                            // ✅ Judul "Laporan Barang X" dan badge status dalam satu Row yang sejajar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Laporan Barang ${index + 1}',  // Menampilkan Laporan Barang 1, Laporan Barang 2, dll.
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
                                    color: _jenisBg(item.keterangan),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.keterangan == 'temuan'
                                        ? 'TEMUAN'
                                        : 'HILANG',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _jenisColor(item.keterangan),
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
                                    'Tanggal Laporan: ${_formatTanggal(item.tanggal)}',
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
                                    'Deskripsi: ${item.deskripsi.isEmpty ? 'Tidak ada deskripsi' : item.deskripsi}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Palette.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (item.fotoUrl != null && item.fotoUrl!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item.fotoUrl!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
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