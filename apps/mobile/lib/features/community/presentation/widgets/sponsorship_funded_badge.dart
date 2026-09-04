import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SponsorshipFundedBadge extends StatelessWidget {
  const SponsorshipFundedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 16, color: AppColors.surface),
          const SizedBox(width: 4),
          Text(
            'Goal Funded',
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
