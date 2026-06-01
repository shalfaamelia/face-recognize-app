import 'package:flutter/material.dart';

enum SnackType { success, error, warning, info }

class AppSnackbar {
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    SnackType type = SnackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Ambil overlay dari root navigator agar tidak hilang saat halaman di-pop
    final overlayState = Navigator.of(context, rootNavigator: true)
        .overlay;
    if (overlayState == null) return;

    // Hapus notifikasi sebelumnya jika masih tampil
    _current?.remove();
    _current = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SnackbarWidget(
        message: message,
        type: type,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    _current = entry;
    overlayState.insert(entry);

    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
        if (_current == entry) _current = null;
      }
    });
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: SnackType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: SnackType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message, type: SnackType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message, type: SnackType.info);
}

class _SnackbarWidget extends StatelessWidget {
  final String message;
  final SnackType type;
  final VoidCallback onDismiss;

  const _SnackbarWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  _SnackConfig get _config {
    switch (type) {
      case SnackType.success:
        return _SnackConfig(
          icon: Icons.check_circle_rounded,
          bgColor: const Color(0xFF1A7A4A),
          iconColor: const Color(0xFF4ADE80),
          label: 'Berhasil',
          labelColor: const Color(0xFF4ADE80),
        );
      case SnackType.error:
        return _SnackConfig(
          icon: Icons.cancel_rounded,
          bgColor: const Color(0xFF7A1A1A),
          iconColor: const Color(0xFFF87171),
          label: 'Gagal',
          labelColor: const Color(0xFFF87171),
        );
      case SnackType.warning:
        return _SnackConfig(
          icon: Icons.warning_amber_rounded,
          bgColor: const Color(0xFF7A5A1A),
          iconColor: const Color(0xFFFBBF24),
          label: 'Peringatan',
          labelColor: const Color(0xFFFBBF24),
        );
      case SnackType.info:
        return _SnackConfig(
          icon: Icons.info_rounded,
          bgColor: const Color(0xFF1A3F7A),
          iconColor: const Color(0xFF60A5FA),
          label: 'Informasi',
          labelColor: const Color(0xFF60A5FA),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: onDismiss,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: cfg.bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cfg.iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(cfg.icon, color: cfg.iconColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cfg.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cfg.labelColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackConfig {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String label;
  final Color labelColor;

  const _SnackConfig({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.label,
    required this.labelColor,
  });
}