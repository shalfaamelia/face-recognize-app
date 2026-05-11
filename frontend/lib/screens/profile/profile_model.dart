class Profile {
  final int id;
  String nama;
  String nim;
  String prodi;
  String kelas;
  String role;
  String? email;

  Profile({
    required this.id,
    required this.nama,
    required this.nim,
    required this.prodi,
    required this.kelas,
    required this.role,
    this.email,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nama: (json['nama'] ?? '').toString(),
      nim: (json['nim'] ?? '').toString(),
      prodi: (json['prodi'] ?? '').toString(),
      kelas: (json['kelas'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'nim': nim,
      'prodi': prodi,
      'kelas': kelas,
      'role': role,
      'email': email,
    };
  }
}