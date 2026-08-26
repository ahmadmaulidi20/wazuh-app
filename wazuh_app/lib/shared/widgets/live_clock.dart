import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/utils/date_format.dart';

class LiveClock extends StatefulWidget {
  const LiveClock({super.key});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  late DateTime _now;

  static DateTime _wibNow() => DateTime.now().toUtc().add(const Duration(hours: 7));

  @override
  void initState() {
    super.initState();
    _now = _wibNow();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = _wibNow());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatFullDate(_now),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          formatClock(_now),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
