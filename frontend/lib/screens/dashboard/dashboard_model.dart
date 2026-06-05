import 'package:flutter/material.dart';

class AktivitasItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String judul;
  final String waktu;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;

  const AktivitasItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.judul,
    required this.waktu,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
  });
}

class DashboardData {
  final int peminjamanAktif;
  final int totalAkses;
  final int laporanBarang;
  final List<AktivitasItem> aktivitas;

  const DashboardData({
    required this.peminjamanAktif,
    required this.totalAkses,
    required this.laporanBarang,
    required this.aktivitas,
  });

  factory DashboardData.empty() {
    return const DashboardData(
      peminjamanAktif: 0,
      totalAkses: 0,
      laporanBarang: 0,
      aktivitas: [],
    );
  }
}
