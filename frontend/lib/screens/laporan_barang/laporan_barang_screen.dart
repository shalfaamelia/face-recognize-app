import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/palette.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/app_theme_helpers.dart';
import 'form_laporan_barang_screen.dart';
import 'laporan_barang_model.dart';
import 'laporan_barang_service.dart';

class LaporanBarangScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const LaporanBarangScreen({
    super.key,
    required this.user,
  });

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
      _future = LaporanBarangService()
          .getByUser(userId)
          .then((list) => list..sort((a, b) => b.id.compareTo(a.id)));
    } else {
      _future = Future.value([]);
    }
  }

  Future<void> _refresh() async {
    setState(() => _loadData());
    await _future;
  }

  Future<void> _goToForm({LaporanBarangItem? item}) async {
    if (item != null && !item.isMenunggu) {
      AppSnackbar.warning(
        context,
        'Laporan yang sudah diterima tidak dapat diedit',
      );
      return;
    }

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

    if (userId == null) {
      AppSnackbar.error(context, 'ID user tidak ditemukan');
      return;
    }

    if (!item.isMenunggu) {
      AppSnackbar.warning(
        context,
        'Laporan yang sudah diterima tidak dapat dihapus',
      );
      return;
    }

    final confirm = await showAppDeleteDialog(
      context: context,
      title: 'Hapus Laporan',
      content: 'Yakin ingin menghapus laporan barang ini?',
    );

    if (confirm != true) return;

    try {
      await LaporanBarangService().delete(
        id: item.id,
        userId: userId,
      );

      if (!mounted) return;

      AppSnackbar.success(context, 'Laporan berhasil dihapus');
      _refresh();
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.error(context, 'Gagal hapus: $e');
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

  String _formatStatus(String status) {
    final value = status.toLowerCase();

    if (value == 'menunggu') return 'Menunggu';
    if (value == 'diterima') return 'Diterima';

    return status.isEmpty ? '-' : status[0].toUpperCase() + status.substring(1);
  }

  Color _jenisColor(String jenis) {
    return jenis == 'temuan' ? Palette.green : Colors.red;
  }

  Color _jenisBg(String jenis) {
    return jenis == 'temuan' ? Palette.greenLight : const Color(0xFFFFE5E5);
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();

    if (value == 'diterima') {
      return Palette.green;
    }

    return Colors.orange;
  }

  Color _statusBg(String status) {
    final value = status.toLowerCase();

    if (value == 'diterima') {
      return Palette.greenLight;
    }

    return const Color(0xFFFFF3CD);
  }

  Widget _buildJenisBadge(LaporanBarangItem item) {
    final isTemuan = item.keterangan == 'temuan';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _jenisBg(item.keterangan),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isTemuan ? 'TEMUAN' : 'HILANG',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _jenisColor(item.keterangan),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LaporanBarangItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _statusBg(item.status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatStatus(item.status).toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _statusColor(item.status),
        ),
      ),
    );
  }

  Widget _infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$label: ${value.trim().isEmpty ? '-' : value}',
        style: const TextStyle(
          fontSize: 12,
          color: Palette.textMuted,
        ),
      ),
    );
  }

  Widget _buildActionButtons(LaporanBarangItem item) {
    final locked = !item.isMenunggu;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: locked ? null : () => _goToForm(item: item),
          style: OutlinedButton.styleFrom(
            foregroundColor: locked ? Colors.grey.shade500 : Palette.blue,
            side: BorderSide(
              color: locked ? Colors.grey.shade300 : Palette.blue,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(
            Icons.edit,
            size: 16,
            color: locked ? Colors.grey.shade500 : null,
          ),
          label: const Text('Edit'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: locked ? Colors.grey.shade300 : Colors.red,
            foregroundColor: locked ? Colors.grey.shade500 : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: locked ? null : () => _deleteItem(item),
          icon: Icon(
            Icons.delete,
            size: 16,
            color: locked ? Colors.grey.shade500 : null,
          ),
          label: const Text('Hapus'),
        ),
      ],
    );
  }

  Widget _buildFoto(LaporanBarangItem item) {
    if (item.fotoUrl == null || item.fotoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            item.fotoUrl!,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;

              return Container(
                height: 120,
                width: double.infinity,
                color: Palette.bgField,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) {
              return Container(
                height: 120,
                width: double.infinity,
                color: Palette.bgField,
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(LaporanBarangItem item, int index) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Laporan Barang ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Palette.textDark,
                ),
              ),
              Row(
                children: [
                  _buildStatusBadge(item),
                  const SizedBox(width: 6),
                  _buildJenisBadge(item),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tanggal Laporan: ${_formatTanggal(item.tanggal)}',
            style: const TextStyle(
              fontSize: 12,
              color: Palette.textDark,
            ),
          ),
          _infoText('Ruang', item.ruang),
          _infoText('No HP', item.noHp),
          _infoText(
            'Deskripsi',
            item.deskripsi.isEmpty ? 'Tidak ada deskripsi' : item.deskripsi,
          ),
          _buildFoto(item),
          const SizedBox(height: 12),
          _buildActionButtons(item),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _parseUserId(widget.user['id']);

    return Scaffold(
      backgroundColor: Palette.bgPage,
      appBar: AppBar(
        title: const Text(
          'Laporan Barang',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Palette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Palette.blue,
        onPressed: userId == null ? null : () => _goToForm(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: userId == null
          ? const Center(
              child: Text('ID user tidak ditemukan'),
            )
          : FutureBuilder<List<LaporanBarangItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Palette.blue,
                    ),
                  );
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
                    color: Palette.blue,
                    child: ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text('Belum ada laporan barang'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: Palette.blue,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildCard(item, index);
                    },
                  ),
                );
              },
            ),
    );
  }
}