import 'package:flutter/material.dart';

import '../../utils/palette.dart';
import '../peminjaman_lab/peminjaman_lab_service.dart';
import '../laporan_barang/laporan_barang_service.dart';
import '../riwayat_akses/riwayat_akses_service.dart';
import 'dashboard_model.dart';

class DashboardService {
  int? parseUserId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String kapitalisasi(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String formatWaktu(dynamic waktu) {
    if (waktu is DateTime) {
      return waktu.toString().replaceAll(RegExp(r'\.\d{3}$'), '');
    }

    return waktu.toString().replaceAll(RegExp(r'\.\d{3}$'), '');
  }

  Future<DashboardData> getDashboardData(Map<String, dynamic> user) async {
    final userId = parseUserId(user['id']);

    if (userId == null) {
      return DashboardData.empty();
    }

    final peminjaman = await PeminjamanService().getByUser(userId);
    final laporan = await LaporanBarangService().getByUser(userId);
    final akses = await MonitoringService().fetchUserLogs(userId);

    final aktivitas = <AktivitasItem>[
      ...peminjaman.take(2).map(
            (e) => AktivitasItem(
              icon: Icons.science_outlined,
              iconColor: Palette.blue,
              iconBg: Palette.blueLight,
              judul: e.keterangan,
              waktu: 'Peminjaman · ${e.tanggal}',
              badge: kapitalisasi(e.status),
              badgeColor: Palette.blue,
              badgeBg: Palette.blueLight,
            ),
          ),
      ...laporan.take(2).map(
            (e) => AktivitasItem(
              icon: Icons.inventory_2_outlined,
              iconColor: Palette.orange,
              iconBg: Palette.orangeLight,
              judul: 'Barang ${e.keterangan}',
              waktu: 'Laporan Barang · ${e.tanggal}',
              badge: kapitalisasi(e.status),
              badgeColor: Palette.orange,
              badgeBg: Palette.orangeLight,
            ),
          ),
      ...akses.take(2).map(
            (e) => AktivitasItem(
              icon: Icons.history_outlined,
              iconColor: Palette.green,
              iconBg: Palette.greenLight,
              judul: 'Akses Lab',
              waktu: 'Masuk · ${formatWaktu(e.masuk)}',
              badge: 'Riwayat Masuk',
              badgeColor: Palette.green,
              badgeBg: Palette.greenLight,
            ),
          ),
    ];

    return DashboardData(
      peminjamanAktif: peminjaman.length,
      totalAkses: akses.length,
      laporanBarang: laporan.length,
      aktivitas: aktivitas,
    );
  }
}