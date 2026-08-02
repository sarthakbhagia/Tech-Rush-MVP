import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/spacing.dart';
import '../providers/filter_provider.dart';
import 'app_bottom_sheet.dart';
import 'sticky_bottom_bar.dart';

void openFilterBottomSheet(BuildContext context, WidgetRef ref) {
  showAppBottomSheet(
    context: context,
    title: 'Filter Dispatches',
    child: _FilterBottomSheetContent(ref: ref),
  );
}

class _FilterBottomSheetContent extends StatefulWidget {
  final WidgetRef ref;
  const _FilterBottomSheetContent({required this.ref});

  @override
  State<_FilterBottomSheetContent> createState() =>
      __FilterBottomSheetContentState();
}

class __FilterBottomSheetContentState
    extends State<_FilterBottomSheetContent> {
  late Set<String> _tempCategories;
  late RangeValues _tempPriceRange;
  late String _tempSortBy;

  static const List<String> _allCategories = [
    'Painting',
    'Cleaning',
    'Plumbing',
    'Cooking',
    'Gardening',
    'Electrical',
  ];

  static const Map<String, String> _sortOptions = {
    'most_recent': 'Most Recent',
    'price_low': 'Price: Low to High',
    'price_high': 'Price: High to Low',
    'rating': 'Top Rated',
    'urgency': 'Urgent First',
  };

  @override
  void initState() {
    super.initState();
    final currentFilter = widget.ref.read(jobFilterProvider);
    _tempCategories = Set<String>.from(currentFilter.categories);
    _tempPriceRange = RangeValues(currentFilter.minPrice, currentFilter.maxPrice);
    _tempSortBy = currentFilter.sortBy;
  }

  void _resetTempFilters() {
    setState(() {
      _tempCategories.clear();
      _tempPriceRange = const RangeValues(500.0, 3000.0);
      _tempSortBy = 'most_recent';
    });
  }

  void _applyFilters() {
    final notifier = widget.ref.read(jobFilterProvider.notifier);
    notifier.setCategories(_tempCategories);
    notifier.setPriceRange(_tempPriceRange.start, _tempPriceRange.end);
    notifier.setSortBy(_tempSortBy);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reset Text Button Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter Criteria',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.inkMuted,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: _resetTempFilters,
              child: Text(
                'Reset All',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // 1. Category Section (Multi-Select Chips)
        Text(
          'Categories (Multi-Select)',
          style: GoogleFonts.sora(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.inkPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allCategories.map((cat) {
            final isSelected = _tempCategories.contains(cat);
            return FilterChip(
              label: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.brand : AppColors.inkPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _tempCategories.add(cat);
                  } else {
                    _tempCategories.remove(cat);
                  }
                });
              },
              selectedColor: AppColors.brandSubtle,
              backgroundColor: AppColors.canvas,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.pill,
                side: BorderSide(
                  color: isSelected ? AppColors.brand : AppColors.border,
                ),
              ),
              checkmarkColor: AppColors.brand,
              showCheckmark: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. Price Range Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Wage Range',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.inkPrimary,
              ),
            ),
            Text(
              '₹${_tempPriceRange.start.round()} - ₹${_tempPriceRange.end.round()}',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.brand,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RangeSlider(
          values: _tempPriceRange,
          min: 500.0,
          max: 3000.0,
          divisions: 25,
          activeColor: AppColors.brand,
          inactiveColor: AppColors.border,
          labels: RangeLabels(
            '₹${_tempPriceRange.start.round()}',
            '₹${_tempPriceRange.end.round()}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _tempPriceRange = values;
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // 3. Sort By Section
        Text(
          'Sort By',
          style: GoogleFonts.sora(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.inkPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sortOptions.entries.map((entry) {
            final isSelected = _tempSortBy == entry.key;
            return ChoiceChip(
              label: Text(
                entry.value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.brand : AppColors.inkPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _tempSortBy = entry.key;
                  });
                }
              },
              selectedColor: AppColors.brandSubtle,
              backgroundColor: AppColors.canvas,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.pill,
                side: BorderSide(
                  color: isSelected ? AppColors.brand : AppColors.border,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),

        // 4. Apply Filters Sticky Bottom Bar CTA
        StickyBottomBar(
          label: 'TOTAL FILTERS',
          price: '${_tempCategories.length + (_tempPriceRange != const RangeValues(500, 3000) ? 1 : 0) + (_tempSortBy != "most_recent" ? 1 : 0)} Active',
          ctaLabel: 'Apply Filters',
          onCta: _applyFilters,
        ),
      ],
    );
  }
}
