import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../models/job.dart';
import '../../widgets/service_card.dart';
import '../../widgets/skeleton_service_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../providers/filter_provider.dart';
import '../../providers/job_provider.dart';

class JobListingScreen extends ConsumerStatefulWidget {
  final String initialCategory;
  const JobListingScreen({super.key, this.initialCategory = 'All'});

  @override
  ConsumerState<JobListingScreen> createState() => _JobListingScreenState();
}

class _JobListingScreenState extends ConsumerState<JobListingScreen> {
  String _searchQuery = '';
  late String _selectedCategory;
  String _selectedStatusTab = 'ALL';
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'All',
    'Painting',
    'Cleaning',
    'Plumbing',
    'Gardening',
    'Cooking',
    'Electrical',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedStatusTab = 'ALL';
      _searchController.clear();
    });
    ref.invalidate(jobsByCategoryProvider);
  }

  List<Job> _filterJobs(List<Job> rawJobs) {
    final filterState = ref.watch(jobFilterProvider);

    var list = rawJobs.where((job) {
      // 1. Status Tab filter
      if (_selectedStatusTab != 'ALL') {
        if (job.status.toUpperCase() != _selectedStatusTab) {
          return false;
        }
      }

      // 2. Category Chip / BottomSheet Category filter
      if (filterState.categories.isNotEmpty) {
        if (!filterState.categories.contains(job.category)) {
          return false;
        }
      } else if (_selectedCategory != 'All') {
        if (job.category.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }

      // 3. Price Range Filter
      if (job.wage < filterState.minPrice || job.wage > filterState.maxPrice) {
        return false;
      }

      // 4. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = job.title.toLowerCase().contains(q);
        final matchCat = job.category.toLowerCase().contains(q);
        final matchLoc = job.location.toLowerCase().contains(q);
        if (!matchTitle && !matchCat && !matchLoc) {
          return false;
        }
      }

      return true;
    }).toList();

    // 5. Sorting
    switch (filterState.sortBy) {
      case 'price_low':
        list.sort((a, b) => a.wage.compareTo(b.wage));
        break;
      case 'price_high':
        list.sort((a, b) => b.wage.compareTo(a.wage));
        break;
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'urgency':
        list.sort((a, b) => (b.urgent ? 1 : 0).compareTo(a.urgent ? 1 : 0));
        break;
      case 'most_recent':
      default:
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final asyncJobs = ref.watch(jobsByCategoryProvider(_selectedCategory));
    final filterState = ref.watch(jobFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.inkPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _selectedCategory == 'All'
              ? 'All Job Listings'
              : '$_selectedCategory Jobs',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.inkPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.border,
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border,
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            color: AppColors.inkPrimary,
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search title, category, location...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: AppColors.inkMuted,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.inkMuted,
                                    ),
                                  )
                                : null,
                            fillColor: AppColors.canvas,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    Material(
                      color: filterState.isActive ? AppColors.brandSubtle : AppColors.surfaceRaised,
                      borderRadius: AppRadii.control,
                      child: InkWell(
                        onTap: () => openFilterBottomSheet(context, ref),
                        borderRadius: AppRadii.control,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: filterState.isActive ? AppColors.brand : AppColors.border,
                            ),
                            borderRadius: AppRadii.control,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: filterState.isActive ? AppColors.brand : AppColors.inkPrimary,
                              ),
                              const SizedBox(width: 4),
                              if (filterState.isActive)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.brand,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${filterState.activeCount}',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: AppColors.inkMuted,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (filterState.isActive) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brandSubtle,
                      borderRadius: AppRadii.control,
                      border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${filterState.activeCount} filter${filterState.activeCount > 1 ? "s" : ""} applied',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        GestureDetector(
                          onTap: () {
                            ref.read(jobFilterProvider.notifier).reset();
                          },
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brand,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs + 2),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.brand
                                  : AppColors.inkMuted,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                          selectedColor: AppColors.brandSubtle,
                          backgroundColor: AppColors.canvas,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.pill,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.brand
                                  : AppColors.border,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                Row(
                  children: [
                    _buildStatusTab('ALL', 'ALL'),
                    const SizedBox(width: AppSpacing.xs + 2),
                    _buildStatusTab('OPEN', 'OPEN',
                        chipType: StatusChipType.open),
                    const SizedBox(width: AppSpacing.xs + 2),
                    _buildStatusTab('ASSIGNED', 'ASSIGNED',
                        chipType: StatusChipType.assigned),
                    const SizedBox(width: AppSpacing.xs + 2),
                    _buildStatusTab('COMPLETED', 'DONE',
                        chipType: StatusChipType.completed),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: asyncJobs.when(
              data: (rawJobs) {
                final filtered = _filterJobs(rawJobs);
                if (filtered.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No Job Dispatches Found',
                        description:
                            'No listings match your search term or category filters. Clear filters to see available daily jobs.',
                        actionLabel: 'Clear All Filters',
                        onAction: _clearFilters,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(jobsByCategoryProvider);
                  },
                  backgroundColor: AppColors.surface,
                  color: AppColors.brand,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final job = filtered[index];
                      return ServiceCard(
                        title: job.title,
                        category: job.category,
                        rating: job.rating,
                        reviewCount: job.reviewCount,
                        price: job.wage,
                        originalPrice: job.originalWage,
                        verified: job.verified,
                        onSelect: () {
                          context.push('/job/${job.id}');
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SkeletonList(count: 3),
              ),
              error: (err, stack) => Center(
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to Load Jobs',
                  description: 'Error: $err',
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(jobsByCategoryProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String tabKey, String label,
      {StatusChipType? chipType}) {
    final isSelected = _selectedStatusTab == tabKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedStatusTab = tabKey);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceRaised : AppColors.canvas,
            borderRadius: AppRadii.control,
            border: Border.all(
              color: isSelected ? AppColors.brand : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.brand : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
