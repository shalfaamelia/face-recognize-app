import 'package:flutter/material.dart';
import 'palette.dart';

/// Helper untuk menampilkan DatePicker dengan tema biru sesuai app
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initialDate ?? now,
    firstDate: firstDate ?? DateTime(now.year - 1),
    lastDate: lastDate ?? DateTime(now.year + 3),
    locale: const Locale('id', 'ID'),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Palette.blue,
            onPrimary: Colors.white,
            onSurface: Palette.textDark,
            surface: Colors.white,
            secondary: Palette.blue,
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Palette.blue,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

/// Helper untuk menampilkan TimePicker dengan tema biru sesuai app
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  TimeOfDay? initialTime,
}) {
  return showTimePicker(
    context: context,
    initialTime: initialTime ?? TimeOfDay.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Palette.blue,
            onPrimary: Colors.white,
            onSurface: Palette.textDark,
            surface: Colors.white,
            secondary: Palette.blue,
            tertiary: Palette.blue,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            dayPeriodShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            hourMinuteColor: MaterialStateColor.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? Palette.blue
                  : const Color(0xFFF0F4FF),
            ),
            hourMinuteTextColor: MaterialStateColor.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? Colors.white
                  : Palette.textDark,
            ),
            dialHandColor: Palette.blue,
            dialBackgroundColor: const Color(0xFFF0F4FF),
            dialTextColor: MaterialStateColor.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? Colors.white
                  : Palette.textDark,
            ),
            entryModeIconColor: Palette.blue,
            helpTextStyle: const TextStyle(
              color: Palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Palette.blue,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

/// Dialog konfirmasi hapus dengan styling sesuai app
Future<bool?> showAppDeleteDialog({
  required BuildContext context,
  required String title,
  required String content,
  String cancelLabel = 'Batal',
  String confirmLabel = 'Hapus',
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon hapus
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5E5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Palette.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Palette.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.textMuted,
                      side: const BorderSide(color: Color(0xFFDDE1EA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
