import 'package:flutter/material.dart';
import '../../utils/palette.dart';
import 'profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>
  profile; // profile dapat menyertakan token jika tersedia
  const ProfileScreen({super.key, required this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _profile;
  bool _isEditing = false;
  bool _loading = false;

  late TextEditingController _namaCtrl;
  late TextEditingController _nimCtrl;
  late TextEditingController _prodiCtrl;
  late TextEditingController _kelasCtrl;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _profile = Map<String, dynamic>.from(widget.profile);

    _namaCtrl = TextEditingController(text: _profile['nama'] ?? '');
    _nimCtrl = TextEditingController(text: _profile['nim'] ?? '');
    _prodiCtrl = TextEditingController(text: _profile['prodi'] ?? '');
    _kelasCtrl = TextEditingController(text: _profile['kelas'] ?? '');
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nimCtrl.dispose();
    _prodiCtrl.dispose();
    _kelasCtrl.dispose();
    super.dispose();
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _namaCtrl.text = _profile['nama'] ?? '';
      _nimCtrl.text = _profile['nim'] ?? '';
      _prodiCtrl.text = _profile['prodi'] ?? '';
      _kelasCtrl.text = _profile['kelas'] ?? '';
    });
  }

  Future<void> _saveEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final token = _profile['token']?.toString().trim();
      final profileId = _profile['id'];

      final requestData = {
        'nama': _namaCtrl.text.trim(),
        'nim': _nimCtrl.text.trim(),
        'prodi': _prodiCtrl.text.trim(),
        'kelas': _kelasCtrl.text.trim(),
      };
      if (_profile['role'] != null) {
        requestData['role'] = _profile['role'];
      }
      if (_profile['email'] != null) {
        requestData['email'] = _profile['email'];
      }

      final updatedProfile = await ProfileService().updateProfile(
        profileId: profileId,
        token: token,
        data: requestData,
      );

      setState(() {
        _profile = {
          'id': updatedProfile.id,
          'nama': updatedProfile.nama,
          'nim': updatedProfile.nim,
          'prodi': updatedProfile.prodi,
          'kelas': updatedProfile.kelas,
          'role': updatedProfile.role,
          'email': updatedProfile.email,
          'token': token,
        };
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Profil berhasil diperbarui'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _value(dynamic value, {String fallback = 'Belum tersedia'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _formatRole(String role) {
    return role.isNotEmpty
        ? role[0].toUpperCase() + role.substring(1).toLowerCase()
        : role;
  }

  @override
  Widget build(BuildContext context) {
    final nama = _value(_profile['nama'], fallback: 'Pengguna');
    final nim = _value(_profile['nim']);
    final role = _formatRole(_value(_profile['role']));
    final prodi = _value(_profile['prodi']);
    final kelas = _value(_profile['kelas']);
    final inisial = nama.isNotEmpty
        ? nama.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: Palette.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
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
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Info / Edit card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Palette.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Palette.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama
                      _isEditing
                          ? _EditField(
                              label: 'Nama',
                              controller: _namaCtrl,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Nama wajib diisi'
                                  : null,
                            )
                          : _InfoRow(label: 'Nama', value: nama),
                      const Divider(height: 22),

                      // NIM
                      _isEditing
                          ? _EditField(
                              label: 'NIM',
                              controller: _nimCtrl,
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'NIM wajib diisi'
                                  : null,
                            )
                          : _InfoRow(label: 'NIM', value: nim),
                      const Divider(height: 22),

                      // Prodi
                      _isEditing
                          ? _EditField(label: 'Prodi', controller: _prodiCtrl)
                          : _InfoRow(label: 'Prodi', value: prodi),
                      const Divider(height: 22),

                      // Kelas
                      _isEditing
                          ? _EditField(label: 'Kelas', controller: _kelasCtrl)
                          : _InfoRow(label: 'Kelas', value: kelas),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol aksi
                if (!_isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
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
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _cancelEdit,
                            icon: const Icon(Icons.close),
                            label: const Text('Batal'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _saveEdit,
                            icon: _loading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(_loading ? 'Menyimpan...' : 'Simpan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget info read-only
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Palette.textMuted),
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

// Widget input edit
class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Palette.textMuted),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontSize: 13, color: Palette.textDark),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Palette.blue),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
