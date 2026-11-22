import 'package:intl/intl.dart';

/// Helper pemformat tanggal catatan berbahasa Indonesia menggunakan package intl.
class DateFormatter {
  DateFormatter._();

  static const List<String> _shortMonthsId = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Mengubah DateTime menjadi format ringkas seperti "9 Nov 2026".
  static String formatShortDate(DateTime date) {
    final local = date.toLocal();
    final day = DateFormat('d').format(local);
    final month = _shortMonthsId[local.month - 1];
    final year = DateFormat('yyyy').format(local);
    return '$day $month $year';
  }

  /// Mengubah DateTime menjadi format tanggal dan jam seperti "9 Nov 2026, 10:15".
  static String formatDateTime(DateTime date) {
    final local = date.toLocal();
    final time = DateFormat('HH:mm').format(local);
    return '${formatShortDate(local)}, $time';
  }
}
