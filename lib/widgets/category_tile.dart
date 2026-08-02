import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeBg;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.icon,
    required this.label,
    this.badgeText,
    this.badgeColor,
    this.badgeBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Base Card Container (Uniform size and inner layout for all tiles)
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.card,
              boxShadow: AppShadows.card,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceRaised,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 22,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 2. Uniform Badge Positioning (Anchored Top-Center for consistent alignment across all cards)
          if (badgeText != null)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg ?? AppColors.brandSubtle,
                    borderRadius: AppRadii.pill,
                    border: Border.all(
                      color: badgeColor ?? AppColors.brand,
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    badgeText!,
                    style: GoogleFonts.spaceMono(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: badgeColor ?? AppColors.brand,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
