class LaporanBarangItem {
  final int id;
  final int userId;
  final String nama;
  final String nim;
  final String kelas;
  final String prodi;
  final String tanggal;
  final String keterangan;
  final String deskripsi;
  final String status;
  final String? foto;
  final String? fotoUrl;

  LaporanBarangItem({
    required this.id,
    required this.userId,
    required this.nama,
    required this.nim,
    required this.kelas,
    required this.prodi,
    required this.tanggal,
    required this.keterangan,
    required this.deskripsi,
    required this.status,
    this.foto,
    this.fotoUrl,
  });

  factory LaporanBarangItem.fromJson(Map<String, dynamic> json) {
    return LaporanBarangItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      nama: (json['nama'] ?? '').toString(),
      nim: (json['nim'] ?? '').toString(),
      kelas: (json['kelas'] ?? '').toString(),
      prodi: (json['prodi'] ?? '').toString(),
      tanggal: (json['tanggal'] ?? '').toString(),
      keterangan: (json['keterangan'] ?? '').toString(),
      deskripsi: (json['deskripsi'] ?? '').toString(),
      status: (json['status'] ?? 'baru').toString(),
      foto: json['foto']?.toString(),
      fotoUrl: json['foto_url']?.toString(),
    );
  }
}