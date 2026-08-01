import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SeverityBadge extends StatelessWidget {
  final int level;
  const SeverityBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SeverityColors.getColor(level).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'L$level',
        style: TextStyle(
          color: SeverityColors.getColor(level),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
