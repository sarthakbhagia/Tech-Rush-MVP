import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/spacing.dart';

/// Reusable helper function to display KaamSetu styled modal bottom sheets.
/// Features rounded top corners, a centered drag handle, drag-to-dismiss physics,
/// header title with close button, and safe-area padding.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: AppColors.surface,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24.0),
      ),
    ),
    builder: (BuildContext modalContext) {
      final bottomInset = MediaQuery.of(modalContext).padding.bottom;
      final keyboardHeight = MediaQuery.of(modalContext).viewInsets.bottom;

      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24.0),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1.0,
            ),
          ),
          boxShadow: AppShadows.floating,
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.sm + 2,
          bottom: bottomInset + keyboardHeight + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Centered Drag Handle Pill
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 40.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadii.pill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header Title Row & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.sora(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Material(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(8.0),
                  child: InkWell(
                    onTap: () => Navigator.of(modalContext).pop(),
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16.0,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Header Divider
            Container(
              height: 1.0,
              color: AppColors.border.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.md),

            // Sheet Body Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
          ],
        ),
      );
    },
  );
}
