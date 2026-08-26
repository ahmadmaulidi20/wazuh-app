import 'package:intl/intl.dart';

const Duration _wibOffset = Duration(hours: 7);

DateTime _toWIB(DateTime dt) => dt.toUtc().add(_wibOffset);

String formatTimestamp(String? ts) {
  if (ts == null) return '';
  try {
    final dt = DateTime.parse(ts);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(_toWIB(dt));
  } catch (_) {
    return ts;
  }
}

String formatTime(String? ts) {
  if (ts == null) return '';
  try {
    final dt = DateTime.parse(ts);
    return DateFormat('HH:mm').format(_toWIB(dt));
  } catch (_) {
    return ts;
  }
}

String formatFullDate(DateTime dt) {
  return DateFormat('EEEE, d MMMM yyyy', 'id').format(_toWIB(dt));
}

String formatClock(DateTime dt) {
  return DateFormat('HH:mm:ss').format(_toWIB(dt));
}
