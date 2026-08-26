import 'package:intl/intl.dart';

String formatTimestamp(String? ts) {
  if (ts == null) return '';
  try {
    final dt = DateTime.parse(ts);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  } catch (_) {
    return ts;
  }
}

String formatTime(String? ts) {
  if (ts == null) return '';
  try {
    final dt = DateTime.parse(ts);
    return DateFormat('HH:mm:ss').format(dt);
  } catch (_) {
    return ts;
  }
}

String formatFullDate(DateTime dt) {
  return DateFormat('EEEE, d MMMM yyyy', 'id').format(dt);
}

String formatClock(DateTime dt) {
  return DateFormat('HH:mm:ss').format(dt);
}
