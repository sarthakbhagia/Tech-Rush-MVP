import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/spacing.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final Color? actionColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
              letterSpacing: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionText != null && onActionTap != null) ...[
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText!,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: actionColor ?? AppColors.brand,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
