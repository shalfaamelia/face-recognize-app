import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../utils/palette.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/app_theme_helpers.dart';
import 'laporan_barang_model.dart';
import 'laporan_barang_service.dart';

class FormLaporanBarangScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final LaporanBarangItem? item;

  const FormLaporanBarangScreen({
    super.key,
    required this.user,
    this.item,
  });

  @override
  State<FormLaporanBarangScreen> createState() =>
      _FormLaporanBarangScreenState();
}

class _FormLaporanBarangScreenState extends State<FormLaporanBarangScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ruangController = TextEditingController();
  final _noHpController = TextEditingController();
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
      _ruangController.text = widget.item!.ruang;
      _noHpController.text = widget.item!.noHp;
      _deskripsiController.text = widget.item!.deskripsi;
      _selectedKeterangan = widget.item!.keterangan;

      try {
        _selectedDate = DateTime.parse(widget.item!.tanggal);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _ruangController.dispose();
    _noHpController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _selectedDate,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _selectedImage = image);
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
      AppSnackbar.warning(context, 'Tanggal wajib dipilih');
      return;
    }

    final userId = _parseUserId(widget.user['id']);

    if (userId == null) {
      AppSnackbar.error(context, 'ID user tidak ditemukan');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.item == null) {
        await LaporanBarangService().create(
          userId: userId,
          ruang: _ruangController.text.trim(),
          noHp: _noHpController.text.trim(),
          tanggal: _dateApi(),
          keterangan: _selectedKeterangan!,
          deskripsi: _deskripsiController.text.trim(),
          fotoPath: _selectedImage?.path,
        );
      } else {
        await LaporanBarangService().update(
          id: widget.item!.id,
          userId: userId,
          ruang: _ruangController.text.trim(),
          noHp: _noHpController.text.trim(),
          tanggal: _dateApi(),
          keterangan: _selectedKeterangan!,
          deskripsi: _deskripsiController.text.trim(),
          fotoPath: _selectedImage?.path,
        );
      }

      if (!mounted) return;

      AppSnackbar.success(
        context,
        widget.item == null
            ? 'Laporan barang berhasil disimpan'
            : 'Laporan barang berhasil diperbarui',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal simpan: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _readonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Palette.textMuted,
          ),
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

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String validatorMessage,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMessage;
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Palette.blue,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
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
          widget.item == null
              ? 'Tambah Laporan Barang Baru'
              : 'Edit Laporan Barang',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
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

              _inputField(
                controller: _ruangController,
                label: 'Ruang',
                validatorMessage: 'Ruang wajib diisi',
              ),
              const SizedBox(height: 14),

              _inputField(
                controller: _noHpController,
                label: 'No HP',
                validatorMessage: 'No HP wajib diisi',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: TextEditingController(
                          text: _dateLabel(),
                        ),
                        decoration: InputDecoration(
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            color: Palette.blue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Palette.blue,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        validator: (_) {
                          return _selectedDate == null
                              ? 'Tanggal wajib dipilih'
                              : null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _selectedKeterangan,
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Palette.blue,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _selectedKeterangan = value);
                },
                validator: (value) {
                  return value == null || value.isEmpty
                      ? 'Keterangan wajib dipilih'
                      : null;
                },
              ),
              const SizedBox(height: 14),

              _inputField(
                controller: _deskripsiController,
                label: 'Deskripsi',
                validatorMessage: 'Deskripsi wajib diisi',
                maxLines: 4,
              ),
              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Foto (opsional)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.upload),
                      label: const Text('Pilih Foto'),
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
                          loadingBuilder: (_, child, progress) {
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
                          errorBuilder: (_, __, ___) {
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSaving ? 'Menyimpan...' : 'Simpan Pengajuan',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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