import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/service_card.dart';
import '../../widgets/skeleton_service_card.dart';
import '../../widgets/logo.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../providers/filter_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/address_bottom_sheet.dart';

enum DashboardRole { employer, worker }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardRole _role = DashboardRole.employer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _toggleRole() {
    setState(() {
      _role = _role == DashboardRole.employer
          ? DashboardRole.worker
          : DashboardRole.employer;
    });
    _simulateLoading();
  }

  @override
  Widget build(BuildContext context) {
    final isEmployer = _role == DashboardRole.employer;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            _simulateLoading();
            await Future.delayed(const Duration(milliseconds: 600));
          },
          backgroundColor: AppColors.surface,
          color: AppColors.brand,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // 1. HERO SECTION (Bold Vibrant Orange Accent Hero Block)
                // -------------------------------------------------------------
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + AppSpacing.md,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.xl,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEA580C), // Vibrant rich orange
                        Color(0xFFD97706), // Warm brand amber
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x29EA580C),
                        blurRadius: 16.0,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Kaamsetu Logo + Location + Notification & Mode Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left Logo (36x36 Bust/Face Crop)
                          const Logo(variant: LogoVariant.header),

                          // Center Location / Greeting Text
                          Expanded(
                            child: GestureDetector(
                              onTap: () => openAddressBottomSheet(context, ref),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            ref.watch(userProfileProvider).shortAddress,
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      isEmployer
                                          ? ref.watch(userProfileProvider).name
                                          : 'Ramesh Kumar (Pro)',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Right Actions: Mode Switcher & Notification Bell
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _toggleRole,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: AppRadii.pill,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    isEmployer ? 'EMPLOYER' : 'WORKER',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => context.push('/notifications'),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (ref.watch(unreadNotificationCountProvider) > 0)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: AppColors.brand,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${ref.watch(unreadNotificationCountProvider)}',
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Hero Headline (Option 2 for Employer, Option 3 for Worker)
                      Text(
                        isEmployer
                            ? 'What daily service do you need done today?'
                            : 'Active Job Ledger & Direct Hires',
                        style: GoogleFonts.sora(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEmployer
                            ? 'Connect with 1,200+ local daily-wage specialists'
                            : 'Set your rate and view nearby daily postings',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Floating White Search Bar
                      GestureDetector(
                        onTap: () => context.push('/search'),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadii.pill,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F000000),
                                blurRadius: 12.0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: AppColors.brand,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isEmployer
                                      ? 'Search "House Painting", "Plumbing"...'
                                      : 'Search jobs near Indiranagar...',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => openFilterBottomSheet(context, ref),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: ref.watch(jobFilterProvider).isActive
                                            ? AppColors.brandSubtle
                                            : AppColors.surfaceRaised,
                                        shape: BoxShape.circle,
                                        border: ref.watch(jobFilterProvider).isActive
                                            ? Border.all(color: AppColors.brand)
                                            : null,
                                      ),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        size: 16,
                                        color: ref.watch(jobFilterProvider).isActive
                                            ? AppColors.brand
                                            : AppColors.inkPrimary,
                                      ),
                                    ),
                                    if (ref.watch(jobFilterProvider).isActive)
                                      Positioned(
                                        top: -2,
                                        right: 4,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: const BoxDecoration(
                                            color: AppColors.brand,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Hero Value Proposition Promo Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md + 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: AppRadii.card,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                size: 24,
                                color: AppColors.brand,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEmployer
                                        ? '100% Aadhaar Verified Daily Pros'
                                        : 'Guaranteed Same-Day UPI Payout',
                                    style: GoogleFonts.sora(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEmployer
                                        ? 'Book verified daily workers with instant response'
                                        : 'Direct connection with verified local households',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // -------------------------------------------------------------
                // 2. CATEGORY GRID (Option 2 Label Employer / Option 3 Worker)
                // -------------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEmployer
                                ? 'POST A NEW JOB BY CATEGORY'
                                : 'AVAILABLE WORK CATEGORIES',
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            '6 Categories',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 3-Column Marketplace Category Grid
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.only(top: 10),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.95,
                        children: [
                          CategoryTile(
                            icon: Icons.format_paint_rounded,
                            label: 'Painting',
                            badgeText: 'HIGH DEMAND',
                            badgeColor: AppColors.brand,
                            badgeBg: const Color(0xFFFFF7ED),
                            onTap: () => context.push('/listings?category=Painting'),
                          ),
                          CategoryTile(
                            icon: Icons.cleaning_services_rounded,
                            label: 'Cleaning',
                            badgeText: 'POPULAR',
                            badgeColor: const Color(0xFF2563EB),
                            badgeBg: const Color(0xFFEFF6FF),
                            onTap: () => context.push('/listings?category=Cleaning'),
                          ),
                          CategoryTile(
                            icon: Icons.plumbing_rounded,
                            label: 'Plumbing',
                            badgeText: 'URGENT',
                            badgeColor: AppColors.danger,
                            badgeBg: const Color(0xFFFEF2F2),
                            onTap: () => context.push('/listings?category=Plumbing'),
                          ),
                          CategoryTile(
                            icon: Icons.soup_kitchen_rounded,
                            label: 'Cooking',
                            onTap: () => context.push('/listings?category=Cooking'),
                          ),
                          CategoryTile(
                            icon: Icons.grass_rounded,
                            label: 'Gardening',
                            onTap: () => context.push('/listings?category=Gardening'),
                          ),
                          CategoryTile(
                            icon: Icons.electric_bolt_rounded,
                            label: 'Electrical',
                            onTap: () => context.push('/listings?category=Electrical'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl + 8),

                      // -------------------------------------------------------
                      // 3. SECONDARY OPERATIONAL DATA (Below the Fold)
                      // -------------------------------------------------------
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadii.card,
                          boxShadow: AppShadows.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isEmployer
                                      ? 'Active Dispatch Operations'
                                      : 'Daily Availability Status',
                                  style: GoogleFonts.sora(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                StatusChip(
                                  status: StatusChipType.open,
                                  labelOverride: isEmployer
                                      ? '2 POSTINGS'
                                      : 'AVAILABLE',
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              isEmployer
                                  ? '2 open postings receiving applicant bids. Next dispatch scheduled for 09:00 AM tomorrow.'
                                  : 'Your profile is active in local dispatch pool. Employers nearby can view your skill certifications and call directly.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.inkMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Text(
                        isEmployer
                            ? 'DISPATCH & METRICS OVERVIEW'
                            : 'MY WORK PARAMETERS',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.35,
                        children: isEmployer
                            ? const [
                                _StatTile(
                                  icon: Icons.work_outline_rounded,
                                  iconBg: Color(0xFFFFF7ED),
                                  iconColor: AppColors.brand,
                                  title: 'Active Postings',
                                  value: '2',
                                  subtext: '1 Painting, 1 Plumbing',
                                ),
                                _StatTile(
                                  icon: Icons.people_outline_rounded,
                                  iconBg: Color(0xFFEFF6FF),
                                  iconColor: Color(0xFF2563EB),
                                  title: 'Applications',
                                  value: '7',
                                  subtext: '4 Verified Workers',
                                ),
                                _StatTile(
                                  icon: Icons.task_alt_rounded,
                                  iconBg: Color(0xFFECFDF5),
                                  iconColor: AppColors.success,
                                  title: 'Total Dispatches',
                                  value: '14',
                                  subtext: 'Completed Jobs',
                                ),
                                _StatTile(
                                  icon: Icons.currency_rupee_rounded,
                                  iconBg: Color(0xFFFEF3C7),
                                  iconColor: AppColors.brand,
                                  title: 'Avg Daily Payout',
                                  value: '₹750',
                                  subtext: 'Per Worker',
                                  highlightValue: true,
                                ),
                              ]
                            : const [
                                _StatTile(
                                  icon: Icons.currency_rupee_rounded,
                                  iconBg: Color(0xFFFEF3C7),
                                  iconColor: AppColors.brand,
                                  title: 'Daily Wage Rate',
                                  value: '₹650/day',
                                  subtext: 'Set by Ramesh',
                                  highlightValue: true,
                                ),
                                _StatTile(
                                  icon: Icons.star_rounded,
                                  iconBg: Color(0xFFFFFBEB),
                                  iconColor: AppColors.warning,
                                  title: 'Rating Score',
                                  value: '4.8 ★',
                                  subtext: '24 Reviews',
                                ),
                                _StatTile(
                                  icon: Icons.task_alt_rounded,
                                  iconBg: Color(0xFFECFDF5),
                                  iconColor: AppColors.success,
                                  title: 'Jobs Completed',
                                  value: '32',
                                  subtext: '100% On-Time',
                                ),
                                _StatTile(
                                  icon: Icons.send_rounded,
                                  iconBg: Color(0xFFEFF6FF),
                                  iconColor: Color(0xFF2563EB),
                                  title: 'Applications Sent',
                                  value: '3',
                                  subtext: 'Pending Review',
                                ),
                              ],
                      ),
                      const SizedBox(height: AppSpacing.xxl + 8),

                      // 4. Recent Postings Feed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEmployer
                                ? 'RECENT DISPATCH LEDGER'
                                : 'RECOMMENDED JOBS NEARBY',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/listings'),
                            child: Text(
                              'View All ->',
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      if (_isLoading)
                        const SkeletonList(count: 3)
                      else ...[
                        ServiceCard(
                          title: 'Full House Painting (Interior Walls)',
                          category: 'Painting',
                          rating: 4.8,
                          reviewCount: 24,
                          price: 1500,
                          originalPrice: 1800,
                          verified: true,
                          onSelect: () => context.push('/job/job-1'),
                        ),
                        ServiceCard(
                          title: 'Deep Kitchen & Chimney Cleaning',
                          category: 'Cleaning',
                          rating: 4.9,
                          reviewCount: 42,
                          price: 900,
                          originalPrice: 1200,
                          verified: true,
                          onSelect: () => context.push('/job/job-2'),
                        ),
                        ServiceCard(
                          title: 'Emergency Bathroom Leak Repair',
                          category: 'Plumbing',
                          rating: 4.7,
                          reviewCount: 18,
                          price: 750,
                          originalPrice: 850,
                          verified: true,
                          onSelect: () => context.push('/job/job-3'),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final String subtext;
  final bool highlightValue;

  const _StatTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtext,
    this.highlightValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.right,
                  style: GoogleFonts.spaceMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.spaceMono(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: highlightValue ? AppColors.brand : AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtext,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.inkMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
