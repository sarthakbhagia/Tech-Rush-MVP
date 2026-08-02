import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/spacing.dart';

class RatingRowData {
  final int stars;
  final int pct;

  const RatingRowData({
    required this.stars,
    required this.pct,
  });
}

class RatingBreakdown extends StatelessWidget {
  final double average;
  final int total;
  final List<RatingRowData>? rows;

  const RatingBreakdown({
    super.key,
    required this.average,
    required this.total,
    this.rows,
  });

  static const List<RatingRowData> defaultRows = [
    RatingRowData(stars: 5, pct: 82),
    RatingRowData(stars: 4, pct: 12),
    RatingRowData(stars: 3, pct: 4),
    RatingRowData(stars: 2, pct: 1),
    RatingRowData(stars: 1, pct: 1),
  ];

  @override
  Widget build(BuildContext context) {
    final activeRows = rows ?? defaultRows;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header average score & star icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkPrimary,
                      fontFamily: 'monospace',
                    ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.star_rounded,
                size: 16.0,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '($total verified reviews)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12.0,
                      color: AppColors.inkMuted,
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Rating distribution bars (5★ to 1★)
          Column(
            children: activeRows.map((r) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${r.stars}★',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 11.0,
                              color: AppColors.inkMuted,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Container(
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius: AppRadii.pill,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: r.pct / 100.0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.brand,
                              borderRadius: AppRadii.pill,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${r.pct}%',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10.0,
                              color: AppColors.inkMuted,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
