import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/spacing.dart';
import '../core/utils/formatters.dart';

class ServiceCard extends StatefulWidget {
  final String? image;
  final String title;
  final String category;
  final double rating;
  final int reviewCount;
  final double price;
  final double? originalPrice;
  final bool verified;
  final VoidCallback? onSelect;

  const ServiceCard({
    super.key,
    this.image,
    required this.title,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.originalPrice,
    this.verified = true,
    this.onSelect,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _isPressed = false;
  bool _isSaved = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final categoryPrefix = widget.category.length >= 3
        ? widget.category.substring(0, 3).toUpperCase()
        : widget.category.toUpperCase();

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onSelect,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.card,
            boxShadow: AppShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Image Thumbnail & Verified Overlay
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: AppRadii.control,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.image != null && widget.image!.isNotEmpty
                        ? Image.network(
                            widget.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildCategoryFallback(categoryPrefix),
                          )
                        : _buildCategoryFallback(categoryPrefix),
                  ),

                  // Overlay Verified Badge
                  if (widget.verified)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.95),
                          borderRadius: AppRadii.pill,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          'Verified',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),

              // Right Details Column
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category, Title, Rating Row
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.toUpperCase(),
                            style: GoogleFonts.spaceMono(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.title,
                            style: GoogleFonts.sora(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13.0,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.rating.toStringAsFixed(1),
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.reviewCount})',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11.0,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Price & Heart Save Toggle Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                Formatters.currency(widget.price),
                                style: GoogleFonts.spaceMono(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brand,
                                ),
                              ),
                              if (widget.originalPrice != null) ...[
                                const SizedBox(width: AppSpacing.xs + 2),
                                Text(
                                  Formatters.currency(widget.originalPrice!),
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 11.0,
                                    color: AppColors.inkCaption,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: AppColors.inkCaption,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Interactive Bookmark / Save Toggle Button
                          GestureDetector(
                            onTap: () {
                              setState(() => _isSaved = !_isSaved);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                _isSaved
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16.0,
                                color: _isSaved
                                    ? const Color(0xFFD66853)
                                    : AppColors.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFallback(String prefix) {
    return Container(
      color: AppColors.surfaceRaised,
      alignment: Alignment.center,
      child: Text(
        prefix,
        style: GoogleFonts.spaceMono(
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}
