import 'package:flutter/material.dart';

import '../../utils/palette.dart';
import '../profile/profile_screen.dart';
import '../riwayat_akses/riwayat_akses_screen.dart';
import '../peminjaman_lab/peminjaman_lab_screen.dart';
import '../laporan_barang/laporan_barang_screen.dart';
import 'dashboard_model.dart';
import 'dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgPage,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _HomeTab(user: widget.user),
          ProfileScreen(profile: widget.user),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selected: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final Map<String, dynamic> user;

  const _HomeTab({
    required this.user,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final DashboardService _dashboardService = DashboardService();

  DashboardData _dashboardData = DashboardData.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    try {
      final data = await _dashboardService.getDashboardData(widget.user);

      if (!mounted) return;

      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error dashboard: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nama = (widget.user['nama'] ?? 'Pengguna').toString();

    final String inisial = nama.isNotEmpty
        ? nama.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'U';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                nama: nama,
                inisial: inisial,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      aktif: _dashboardData.peminjamanAktif,
                      akses: _dashboardData.totalAkses,
                      laporan: _dashboardData.laporanBarang,
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Menu Utama'),
                    const SizedBox(height: 10),
                    _MenuGrid(
                      user: widget.user,
                      peminjamanAktif: _dashboardData.peminjamanAktif,
                      laporanBarang: _dashboardData.laporanBarang,
                      totalAkses: _dashboardData.totalAkses,
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Aktivitas Terbaru'),
                    const SizedBox(height: 10),
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _dashboardData.aktivitas.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('Belum ada aktivitas terbaru'),
                                ),
                              )
                            : _AktivitasCard(
                                items: _dashboardData.aktivitas,
                              ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String nama;
  final String inisial;

  const _Header({
    required this.nama,
    required this.inisial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.blue,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang 👋',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nama,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              inisial,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final int aktif;
  final int akses;
  final int laporan;

  const _StatRow({
    required this.aktif,
    required this.akses,
    required this.laporan,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: aktif.toString(),
            label: 'Peminjaman\nAktif',
            color: Palette.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: akses.toString(),
            label: 'Akses\nTotal',
            color: Palette.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: laporan.toString(),
            label: 'Barang\nDilaporkan',
            color: Palette.orange,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final Map<String, dynamic> user;
  final int peminjamanAktif;
  final int laporanBarang;
  final int totalAkses;

  const _MenuGrid({
    required this.user,
    required this.peminjamanAktif,
    required this.laporanBarang,
    required this.totalAkses,
  });

  int? _parseUserId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final int? userId = _parseUserId(user['id']);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: [
        _MenuCard(
          icon: Icons.science_outlined,
          iconColor: Palette.blue,
          iconBg: Palette.blueLight,
          title: 'Peminjaman Lab',
          subtitle: '$peminjamanAktif peminjaman',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PeminjamanLabScreen(user: user),
              ),
            );
          },
        ),
        _MenuCard(
          icon: Icons.inventory_2_outlined,
          iconColor: Palette.orange,
          iconBg: Palette.orangeLight,
          title: 'Laporan Barang',
          subtitle: '$laporanBarang laporan',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LaporanBarangScreen(user: user),
              ),
            );
          },
        ),
        _MenuCard(
          icon: Icons.history_outlined,
          iconColor: Palette.green,
          iconBg: Palette.greenLight,
          title: 'Riwayat Akses',
          subtitle: '$totalAkses akses',
          onTap: () {
            if (userId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ID pengguna tidak ditemukan. Silakan login ulang.',
                  ),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RiwayatAksesScreen(userId: userId),
              ),
            );
          },
        ),
        _MenuCard(
          icon: Icons.person_outline,
          iconColor: Palette.purple,
          iconBg: Palette.purpleLight,
          title: 'Profil Saya',
          subtitle: 'Lihat & edit profil',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(profile: user),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MenuCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(
          milliseconds: 120,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Palette.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Palette.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Palette.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AktivitasCard extends StatelessWidget {
  final List<AktivitasItem> items;

  const _AktivitasCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Palette.cardBorder,
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;

          return Column(
            children: [
              _AktivitasRow(item: entry.value),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Color(0xFFF0F0F0),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AktivitasRow extends StatelessWidget {
  final AktivitasItem item;

  const _AktivitasRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              color: item.iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.judul,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Palette.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.waktu,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: item.badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: item.badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selected,
    required this.onTap,
  });

  static const _items = [
    {
      'icon': Icons.home_outlined,
      'label': 'Beranda',
    },
    {
      'icon': Icons.person_outline,
      'label': 'Profil',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Palette.bgCard,
        border: Border(
          top: BorderSide(
            color: Palette.cardBorder,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final isSelected = index == selected;

          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _items[index]['icon'] as IconData,
                  size: 22,
                  color: isSelected ? Palette.blue : Palette.textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  _items[index]['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Palette.blue : Palette.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}