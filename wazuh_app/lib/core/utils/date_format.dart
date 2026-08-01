import 'package:intl/intl.dart';

String formatTimestamp(String? ts) {
  if (ts == null) return '';
  try {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(ts).toLocal());
  } catch (_) {
    return ts;
  }
}

String formatTime(String? ts) {
  if (ts == null) return '';
  try {
    return DateFormat('HH:mm').format(DateTime.parse(ts).toLocal());
  } catch (_) {
    return ts;
  }
}

String formatFullDate(DateTime dt) {
  return DateFormat('EEEE, d MMMM yyyy', 'id').format(dt.toLocal());
}

String formatClock(DateTime dt) {
  return DateFormat('HH:mm:ss').format(dt.toLocal());
}
