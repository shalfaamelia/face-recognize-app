import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../utils/palette.dart';
import 'laporan_barang_model.dart';
import 'laporan_barang_service.dart';

class FormLaporanBarangScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final LaporanBarangItem? item;

  const FormLaporanBarangScreen({super.key, required this.user, this.item});

  @override
  State<FormLaporanBarangScreen> createState() =>
      _FormLaporanBarangScreenState();
}

class _FormLaporanBarangScreenState extends State<FormLaporanBarangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedKeterangan;
  XFile? _selectedImage;
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
      _deskripsiController.text = widget.item!.deskripsi;
      _selectedKeterangan = widget.item!.keterangan;

      try {
        _selectedDate = DateTime.parse(widget.item!.tanggal);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  String _dateLabel() {
    if (_selectedDate == null) return '';
    return DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate!);
  }

  String _dateApi() {
    return DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tanggal wajib dipilih')));
      return;
    }

    final userId = _parseUserId(widget.user['id']);
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID user tidak ditemukan')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.item == null) {
        await LaporanBarangService().create(
          userId: userId,
          tanggal: _dateApi(),
          keterangan: _selectedKeterangan!,
          deskripsi: _deskripsiController.text.trim(),
          fotoPath: _selectedImage?.path,
        );
      } else {
        await LaporanBarangService().update(
          id: widget.item!.id,
          userId: userId,
          tanggal: _dateApi(),
          keterangan: _selectedKeterangan!,
          deskripsi: _deskripsiController.text.trim(),
          fotoPath: _selectedImage?.path,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.item == null
                ? 'Laporan barang berhasil disimpan'
                : 'Laporan barang berhasil diperbarui',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = (widget.user['nama'] ?? '-').toString();
    final nim = (widget.user['nim'] ?? widget.user['npm'] ?? '-').toString();
    final kelas = (widget.user['kelas'] ?? 'Belum tersedia').toString();
    final prodi = (widget.user['prodi'] ?? 'Belum tersedia').toString();

    return Scaffold(
      backgroundColor: Palette.bgPage,
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Tambah Pengajuan Baru' : 'Edit Pengajuan',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waktu',
                    style: TextStyle(fontSize: 12, color: Palette.textMuted),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: TextEditingController(text: _dateLabel()),
                        decoration: InputDecoration(
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        validator: (_) {
                          if (_selectedDate == null)
                            return 'Tanggal wajib dipilih';
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedKeterangan,
                items: const [
                  DropdownMenuItem(
                    value: 'temuan',
                    child: Text('Temuan Barang'),
                  ),
                  DropdownMenuItem(
                    value: 'hilang',
                    child: Text('Hilang Barang'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedKeterangan = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Keterangan wajib dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Foto (opsional)',
                      style: TextStyle(fontSize: 12, color: Palette.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.blue,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.upload),
                          label: const Text('Pilih Foto'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImage!.path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (widget.item?.fotoUrl != null &&
                        widget.item!.fotoUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.item!.fotoUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 120,
                              height: 120,
                              color: Palette.bgField,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
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
                ),
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
                  child: Text(_isSaving ? 'Menyimpan...' : 'Simpan Pengajuan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
