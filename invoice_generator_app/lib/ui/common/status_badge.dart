import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status; // 'paid', 'unpaid', 'partially_paid', 'overdue', 'draft'

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'paid':
        bg = AppColors.successLight;
        text = AppColors.success;
        label = 'PAID';
        icon = Icons.check_circle_rounded;
        break;
      case 'partially_paid':
        bg = AppColors.infoLight;
        text = AppColors.info;
        label = 'PARTIAL';
        icon = Icons.timelapse_rounded;
        break;
      case 'overdue':
        bg = AppColors.dangerLight;
        text = AppColors.danger;
        label = 'OVERDUE';
        icon = Icons.warning_amber_rounded;
        break;
      case 'draft':
        bg = AppColors.surfaceVariant;
        text = AppColors.textSecondary;
        label = 'DRAFT';
        icon = Icons.edit_note_rounded;
        break;
      case 'unpaid':
      default:
        bg = AppColors.warningLight;
        text = AppColors.warning;
        label = 'UNPAID';
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: text,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
