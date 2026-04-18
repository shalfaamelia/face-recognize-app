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