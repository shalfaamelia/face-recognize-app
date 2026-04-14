import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/palette.dart';
import 'peminjaman_lab_screen.dart';

class FormPeminjamanScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final PeminjamanItem? item;

  const FormPeminjamanScreen({
    super.key,
    required this.user,
    this.item,
  });

  @override
  State<FormPeminjamanScreen> createState() => _FormPeminjamanScreenState();
}

class _FormPeminjamanScreenState extends State<FormPeminjamanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  bool _isSaving = false;

  int? _parseUserId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  void initState() {
    super.initState();

    if (widget.item != null) {
      _keteranganController.text = widget.item!.keterangan;

      try {
        _selectedDate = DateTime.parse(widget.item!.tanggal);
      } catch (_) {}

      final mulai = widget.item!.jamMulai.split(':');
      final selesai = widget.item!.jamSelesai.split(':');

      if (mulai.length >= 2) {
        _jamMulai = TimeOfDay(
          hour: int.parse(mulai[0]),
          minute: int.parse(mulai[1]),
        );
      }

      if (selesai.length >= 2) {
        _jamSelesai = TimeOfDay(
          hour: int.parse(selesai[0]),
          minute: int.parse(selesai[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickMulai() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _jamMulai ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _jamMulai = picked;
      });
    }
  }

  Future<void> _pickSelesai() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _jamSelesai ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _jamSelesai = picked;
      });
    }
  }

  String _dateLabel() {
    if (_selectedDate == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate!);
  }

  String _timeLabel(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dateApi() {
    return DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  String _timeApi(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _jamMulai == null || _jamSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal dan jam wajib dipilih')),
      );
      return;
    }

    final userId = _parseUserId(widget.user['id']);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID user tidak ditemukan')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.item == null) {
        await PeminjamanService().create(
          userId: userId,
          tanggal: _dateApi(),
          jamMulai: _timeApi(_jamMulai!),
          jamSelesai: _timeApi(_jamSelesai!),
          keterangan: _keteranganController.text.trim(),
        );
      } else {
        await PeminjamanService().update(
          id: widget.item!.id,
          userId: userId,
          tanggal: _dateApi(),
          jamMulai: _timeApi(_jamMulai!),
          jamSelesai: _timeApi(_jamSelesai!),
          keterangan: _keteranganController.text.trim(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.item == null
                ? 'Peminjaman berhasil disimpan'
                : 'Peminjaman berhasil diperbarui',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simpan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _readonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Palette.textMuted),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF6F7FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
    IconData icon = Icons.calendar_today_outlined,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Palette.textMuted),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: IgnorePointer(
            child: TextFormField(
              controller: TextEditingController(text: value),
              decoration: InputDecoration(
                suffixIcon: Icon(icon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              validator: (_) {
                if (value.isEmpty) return '$label wajib diisi';
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = (widget.user['nama'] ?? '').toString();
    final nim = (widget.user['nim'] ?? widget.user['npm'] ?? '').toString();
    final prodi = (widget.user['prodi'] ?? '').toString();
    final kelas = (widget.user['kelas'] ?? '').toString();

    return Scaffold(
      backgroundColor: Palette.bgPage,
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Tambah Peminjaman Baru' : 'Edit Peminjaman',
        ),
        backgroundColor: Palette.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _readonlyField('Nama', nama),
              const SizedBox(height: 14),
              _readonlyField('NIM', nim),
              const SizedBox(height: 14),
              _readonlyField('Kelas', kelas),
              const SizedBox(height: 14),
              _readonlyField('Prodi', prodi),
              const SizedBox(height: 14),
              _pickerField(
                label: 'Tanggal',
                value: _dateLabel(),
                onTap: _pickDate,
              ),
              const SizedBox(height: 14),
              _pickerField(
                label: 'Jam Mulai',
                value: _timeLabel(_jamMulai),
                onTap: _pickMulai,
                icon: Icons.access_time,
              ),
              const SizedBox(height: 14),
              _pickerField(
                label: 'Jam Selesai',
                value: _timeLabel(_jamSelesai),
                onTap: _pickSelesai,
                icon: Icons.access_time,
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keterangan',
                    style: TextStyle(fontSize: 12, color: Palette.textMuted),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _keteranganController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSaving ? 'Menyimpan...' : 'Simpan Peminjaman',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}