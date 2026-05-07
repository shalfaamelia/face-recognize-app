import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/api_service.dart';
import '../../utils/palette.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _namaController = TextEditingController();
  final _nimController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  bool _namaFocused = false;
  bool _nimFocused = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _orbitController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _orbitController.dispose();
    _namaController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final nama = _namaController.text.trim();
    final nim = _nimController.text.trim();

    if (nama.isEmpty || nim.isEmpty) {
      setState(() {
        _errorMessage = 'Nama dan NIM wajib diisi.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.login(nama, nim);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(user: user),
        ),
      );
    } catch (e) {
      debugPrint('Login gagal: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgPage,
      body: Stack(
        children: [
          _AnimatedBackground(controller: _orbitController),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 64),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Palette.blue,
                          boxShadow: [
                            BoxShadow(
                              color: Palette.blue.withOpacity(0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Selamat Datang',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: Palette.textDark,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Masuk untuk melanjutkan ke portal akademik',
                        style: TextStyle(
                          color: Palette.textMuted,
                          fontSize: 13.5,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Palette.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Palette.cardBorder,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Palette.blue.withOpacity(0.06),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInputField(
                              controller: _namaController,
                              label: 'Nama Lengkap',
                              hint: 'Masukkan nama Anda',
                              icon: Icons.person_outline_rounded,
                              isFocused: _namaFocused,
                              onFocusChange: (v) {
                                setState(() => _namaFocused = v);
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              controller: _nimController,
                              label: 'NIM',
                              hint: 'Nomor Induk Mahasiswa',
                              icon: Icons.badge_outlined,
                              isFocused: _nimFocused,
                              onFocusChange: (v) {
                                setState(() => _nimFocused = v);
                              },
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 28),
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFCA5A5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: _loading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Palette.blue,
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: _loading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Palette.blue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Portal Akademik • 2026',
                        style: TextStyle(
                          color: Palette.textHint,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isFocused,
    required ValueChanged<bool> onFocusChange,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isFocused ? Palette.blue : Palette.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isFocused ? Palette.bgFieldFocus : Palette.bgField,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFocused ? Palette.borderFocus : Palette.borderIdle,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: Palette.textDark,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Palette.textHint,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  icon,
                  color: isFocused ? Palette.blue : Palette.textHint,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * math.pi;

        return Stack(
          children: [
            Positioned(
              top: -80 + math.sin(t) * 20,
              right: -80 + math.cos(t * 0.7) * 15,
              child: const _Orb(
                size: 300,
                color: Color(0xFFDBEAFE),
              ),
            ),
            Positioned(
              bottom: size.height * 0.1 + math.sin(t * 0.8) * 15,
              left: -60 + math.cos(t * 0.6) * 12,
              child: const _Orb(
                size: 200,
                color: Color(0xFFBFDBFE),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}