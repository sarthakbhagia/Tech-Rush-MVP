import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../models/job.dart';
import '../../widgets/service_card.dart';
import '../../widgets/skeleton_service_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/empty_state.dart';

class JobListingScreen extends StatefulWidget {
  const JobListingScreen({super.key});

  @override
  State<JobListingScreen> createState() => _JobListingScreenState();
}

class _JobListingScreenState extends State<JobListingScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatusTab = 'ALL';
  bool _isLoading = true;

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
    _simulateLoading();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _simulateLoading() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedStatusTab = 'ALL';
      _searchController.clear();
    });
    _simulateLoading();
  }

  void _openFilterBottomSheet() {
    showAppBottomSheet(
      context: context,
      title: 'Filter Dispatches by Category',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceRaised : AppColors.surface,
              borderRadius: AppRadii.control,
              border: Border.all(
                color: isSelected ? AppColors.brand : AppColors.border,
              ),
            ),
            child: ListTile(
              title: Text(
                cat,
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.brand : AppColors.inkPrimary,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.brand, size: 18)
                  : null,
              onTap: () {
                setState(() => _selectedCategory = cat);
                Navigator.of(context).pop();
                _simulateLoading();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Job> get _filteredJobs {
    return mockJobs.where((job) {
      if (_selectedStatusTab != 'ALL') {
        if (job.status.toUpperCase() != _selectedStatusTab) {
          return false;
        }
      }
      if (_selectedCategory != 'All') {
        if (job.category.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }
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
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredJobs;

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
          'Job Dispatch Ledger',
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
                      color: AppColors.surfaceRaised,
                      borderRadius: AppRadii.control,
                      child: InkWell(
                        onTap: _openFilterBottomSheet,
                        borderRadius: AppRadii.control,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: AppRadii.control,
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: AppColors.brand,
                              ),
                              SizedBox(width: 4),
                              Icon(
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
                              _simulateLoading();
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
            child: _isLoading
                ? const SingleChildScrollView(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: SkeletonList(count: 3),
                  )
                : filtered.isEmpty
                    ? Center(
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
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          _simulateLoading();
                          await Future.delayed(
                              const Duration(milliseconds: 650));
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
          _simulateLoading();
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
