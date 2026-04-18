import 'package:flutter/material.dart';
import '../../utils/palette.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const ProfileScreen({super.key, required this.user});

  String _value(dynamic value, {String fallback = 'Belum tersedia'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _formatRole(String role) {
    return role.isNotEmpty ? role[0].toUpperCase() + role.substring(1).toLowerCase() : role;
  }

  @override
  Widget build(BuildContext context) {
    final nama = _value(user['nama'], fallback: 'Pengguna');
    final nim = _value(user['nim']);
    final role = _formatRole(_value(user['role'])); // Terapkan format di sini
    final prodi = _value(user['prodi']);
    final kelas = _value(user['kelas']);
    final inisial = nama.isNotEmpty
        ? nama.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: Palette.bgPage,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Palette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Palette.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Palette.cardBorder),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Palette.blueLight,
                    child: Text(
                      inisial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Palette.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    nama,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Palette.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nim,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Palette.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Palette.cardBorder),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Nama', value: nama),
                  const Divider(height: 22),
                  _InfoRow(label: 'NIM', value: nim),
                  const Divider(height: 22),
                  _InfoRow(label: 'Role', value: role), 
                  const Divider(height: 22),
                  _InfoRow(label: 'Prodi', value: prodi),
                  const Divider(height: 22),
                  _InfoRow(label: 'Kelas', value: kelas),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur edit profil belum dihubungkan ke backend'),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profil'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Palette.blue,
                  side: const BorderSide(color: Palette.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Palette.textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Palette.textDark,
            ),
          ),
        ),
      ],
    );
  }
}