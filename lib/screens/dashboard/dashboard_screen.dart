import 'dart:math' as math;
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
import '../../providers/job_provider.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job_category.dart';
import '../../widgets/address_bottom_sheet.dart';
import '../../widgets/post_job_bottom_sheet.dart';
import '../../widgets/empty_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/dashboard_stats_service.dart';
import '../../models/user_profile.dart';
import '../../models/job.dart';

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
    // Initialize role from provider immediately to prevent layout flashes
    final initialRole = ref.read(userProfileProvider).role;
    _role = (initialRole == 'worker') ? DashboardRole.worker : DashboardRole.employer;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    await ref.read(userProfileProvider.notifier).refreshProfile();
    if (mounted) {
      final profileRole = ref.read(userProfileProvider).role;
      setState(() {
        _isLoading = false;
        // Maintain active role state from provider rather than defaulting to employer
        _role = (profileRole == 'worker')
            ? DashboardRole.worker
            : DashboardRole.employer;
      });
    }
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
    final nextRole = _role == DashboardRole.employer
        ? DashboardRole.worker
        : DashboardRole.employer;

    setState(() {
      _role = nextRole;
    });

    ref.read(userProfileProvider.notifier).updateRole(
          nextRole == DashboardRole.employer ? 'employer' : 'worker',
        );

    _simulateLoading();
  }

  void _showCustomCategoriesBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse Other Categories',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Consumer(
                builder: (context, ref, child) {
                  final customCatsAsync = ref.watch(customCategoriesProvider);
                  return customCatsAsync.when(
                    data: (customCats) {
                      if (customCats.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Center(
                            child: Text(
                              'No other active categories at the moment.',
                              style: GoogleFonts.inter(
                                  color: AppColors.inkMuted, fontSize: 13),
                            ),
                          ),
                        );
                      }
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: customCats.map((cat) {
                          return ActionChip(
                            backgroundColor: AppColors.surfaceRaised,
                            side: const BorderSide(color: AppColors.border),
                            label: Text(
                              cat,
                              style: GoogleFonts.spaceMono(
                                fontSize: 11,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.push('/listings?category=$cat');
                            },
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(color: AppColors.brand),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.brand,
          ),
        ),
      );
    }

    final isEmployer = _role == DashboardRole.employer;
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final userProfile = ref.watch(userProfileProvider);

    final displayAddress = isEmployer
        ? (userProfile.shortAddress.isNotEmpty ? userProfile.shortAddress : 'Select Location')
        : (userProfile.workerAddress != null && userProfile.workerAddress!.isNotEmpty
            ? userProfile.workerAddress!
            : 'Koramangala, BLR');

    final displayName = isEmployer
        ? (userProfile.name.isNotEmpty ? userProfile.name : 'Guest Employer')
        : (userProfile.workerName != null && userProfile.workerName!.isNotEmpty
            ? userProfile.workerName!
            : 'Raju Sharma');

    // Resolve the current authenticated user ID for stats queries
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ??
        (userProfile.id?.isNotEmpty == true ? userProfile.id! : null) ??
        'e0000000-0000-0000-0000-000000000001';

    final dashboardJobsAsync = isEmployer
        ? ref.watch(jobsByEmployerProvider(currentUserId))
        : ref.watch(jobsByCategoryProvider('All'));

    // Dynamic color tokens for Employer vs Worker mode
    final primaryColor = isEmployer ? const Color(0xFF943D39) : const Color(0xFF1E5E54);
    final activeColor = isEmployer ? const Color(0xFFA64A45) : const Color(0xFF2D8073);
    final subtleColor = isEmployer ? const Color(0xFFF7EBEB) : const Color(0xFFEDF7F5);

    // Watch stats for the dynamic stat grid
    final statsParams = DashboardStatsParams(userId: currentUserId, role: isEmployer ? 'employer' : 'worker');
    final statsAsync = ref.watch(dashboardStatsProvider(statsParams));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            // Invalidate notification count so they re-fetch from Supabase
            ref.invalidate(notificationsProvider);
            ref.invalidate(dashboardStatsProvider(statsParams));
            await _loadProfile();
          },
          backgroundColor: AppColors.surface,
          color: primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // 1. HERO SECTION (Dynamic Gradient based on Active Role)
                // -------------------------------------------------------------
                Container(
                  padding: EdgeInsets.only(
                    top: math.max(MediaQuery.viewPaddingOf(context).top, 44.0) + AppSpacing.md,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.xl,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        activeColor,
                        primaryColor,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.16),
                        blurRadius: 16.0,
                        offset: const Offset(0, 6),
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
                                        Expanded(
                                          child: Text(
                                            displayAddress,
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
                                      displayName,
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

                          // Right Actions: Language Switcher, Mode Switcher & Notification Bell
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
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
                                    currentLocale.languageCode == 'en' ? 'हिं' : 'EN',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isEmployer
                                            ? Icons.business_center_rounded
                                            : Icons.construction_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isEmployer ? l10n.roleEmployer : l10n.roleWorker,
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
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
                                    if ((ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0) > 0)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0}',
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

                      // Hero Headline
                      Text(
                        isEmployer
                            ? l10n.dashboardEmployerHeadline
                            : (currentLocale.languageCode == 'hi' ? 'आज ही अपना अगला काम खोजें' : 'Find your next job today'),
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
                            ? l10n.dashboardEmployerSubhead
                            : (currentLocale.languageCode == 'hi' ? 'अपनी उपलब्धता को सक्रिय पर सेट करें और आसपास के लोगों द्वारा किराए पर लिए जाएं' : 'Set your status to active and get hired by nearby households'),
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
                              Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isEmployer
                                      ? l10n.dashboardEmployerSearchPlaceholder
                                      : l10n.dashboardWorkerSearchPlaceholder,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.inkMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                            ? subtleColor
                                            : AppColors.surfaceRaised,
                                        shape: BoxShape.circle,
                                        border: ref.watch(jobFilterProvider).isActive
                                            ? Border.all(color: primaryColor)
                                            : null,
                                      ),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        size: 16,
                                        color: ref.watch(jobFilterProvider).isActive
                                            ? primaryColor
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
                                          decoration: BoxDecoration(
                                            color: primaryColor,
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
                              child: Icon(
                                Icons.verified_user_rounded,
                                size: 24,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEmployer
                                        ? l10n.dashboardEmployerBannerTitle
                                        : l10n.dashboardWorkerBannerTitle,
                                    style: GoogleFonts.sora(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEmployer
                                        ? l10n.dashboardEmployerBannerSubhead
                                        : l10n.dashboardWorkerBannerSubhead,
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
                // CONTENT BELOW THE HERO (Diverges per Mode)
                // -------------------------------------------------------------
                if (isEmployer) ...[
                  // ── EMPLOYER VIEW CONTENT ──

                  // 1. Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentLocale.languageCode == 'hi' ? 'पोस्टिंग सारांश' : 'POSTING SUMMARY',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildStatsRow(statsAsync, primaryColor, subtleColor, isEmployer),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 2. Category grid for posting jobs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                l10n.postNewJobByCategory,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.inkPrimary,
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            GestureDetector(
                              onTap: () => openPostJobBottomSheet(context, ref),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: subtleColor,
                                  borderRadius: AppRadii.pill,
                                  border: Border.all(color: primaryColor),
                                ),
                                child: Text(
                                  l10n.postJobCta,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildCategoryGrid(context, primaryColor, isEmployer),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl + 8),

                  // 3. My Jobs Feed
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currentLocale.languageCode == 'hi' ? 'मेरे कार्य' : 'MY JOB POSTINGS',
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
                            const SizedBox(width: AppSpacing.xs),
                            GestureDetector(
                              onTap: () => context.push('/listings'),
                              child: Text(
                                l10n.linkViewAll,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildJobsFeed(dashboardJobsAsync, primaryColor, isEmployer, currentLocale),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ] else ...[
                  // ── WORKER VIEW CONTENT ──

                  // 1. Daily availability card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildAvailabilityCard(userProfile, l10n, currentLocale),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. WOW-Factor Gamified Streak & Earnings Widget
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _buildWorkerEarningsStreakWidget(primaryColor, subtleColor, currentLocale),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentLocale.languageCode == 'hi' ? 'कार्य सारांश' : 'WORK LEDGER',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildStatsRow(statsAsync, primaryColor, subtleColor, isEmployer),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 4. Categories for Workers to filter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                l10n.availableWorkCategories,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.inkPrimary,
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              l10n.categoriesCount,
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildCategoryGrid(context, primaryColor, isEmployer),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl + 8),

                  // 5. Jobs near me feed
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                l10n.headerRecommendedJobsNearby,
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
                            const SizedBox(width: AppSpacing.xs),
                            GestureDetector(
                              onTap: () => context.push('/listings'),
                              child: Text(
                                l10n.linkViewAll,
                                style: GoogleFonts.spaceMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildJobsFeed(dashboardJobsAsync, primaryColor, isEmployer, currentLocale),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DASHBOARD HELPER WIDGETS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(
    AsyncValue<DashboardStats> statsAsync,
    Color primaryColor,
    Color subtleColor,
    bool isEmployer,
  ) {
    return statsAsync.when(
      data: (stats) {
        return Row(
          children: [
            _buildStatCard(
              isEmployer ? 'Jobs Posted' : 'Jobs Available',
              '${stats.activePostings}',
              isEmployer ? Icons.work_history_rounded : Icons.local_play_rounded,
              primaryColor,
              subtleColor,
            ),
            const SizedBox(width: AppSpacing.md),
            _buildStatCard(
              isEmployer ? 'Applications' : 'Active Jobs',
              isEmployer ? '${stats.totalApplications}' : '${stats.jobsCompleted}',
              isEmployer ? Icons.people_alt_rounded : Icons.assignment_turned_in_rounded,
              primaryColor,
              subtleColor,
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(
            child: Container(
              height: 54,
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadii.card,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 54,
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadii.card,
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => Row(
        children: [
          _buildStatCard(
            isEmployer ? 'Jobs Posted' : 'Jobs Available',
            '--',
            isEmployer ? Icons.work_history_rounded : Icons.local_play_rounded,
            primaryColor,
            subtleColor,
          ),
          const SizedBox(width: AppSpacing.md),
          _buildStatCard(
            isEmployer ? 'Applications' : 'Active Jobs',
            '--',
            isEmployer ? Icons.people_alt_rounded : Icons.assignment_turned_in_rounded,
            primaryColor,
            subtleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color primaryColor,
    Color subtleColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.card,
          boxShadow: AppShadows.card,
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: subtleColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: primaryColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.spaceMono(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    Color primaryColor,
    bool isEmployer,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(top: 10),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.95,
      children: [
        ...AppCategories.all.map((cat) {
          return CategoryTile(
            icon: cat.icon,
            label: cat.getLocalizedName(l10n),
            iconColor: primaryColor,
            onTap: () => isEmployer
                ? openPostJobBottomSheet(context, ref, initialCategory: cat.id)
                : context.push('/listings?category=${cat.id}'),
          );
        }),
        CategoryTile(
          icon: Icons.grid_view_rounded,
          label: currentLocale.languageCode == 'hi' ? 'अन्य श्रेणियां' : 'Other / More',
          iconColor: primaryColor,
          onTap: () => isEmployer
              ? openPostJobBottomSheet(context, ref, initialCategory: 'Other')
              : _showCustomCategoriesBottomSheet(context, ref),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard(
    UserProfile userProfile,
    AppLocalizations l10n,
    Locale currentLocale,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.headerDailyAvailStatus,
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(
                status: userProfile.isAvailable
                    ? StatusChipType.open
                    : StatusChipType.closed,
                labelOverride: userProfile.isAvailable
                    ? l10n.statusAvailable
                    : (currentLocale.languageCode == 'hi'
                        ? 'अनुपलब्ध'
                        : 'NOT AVAILABLE'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            userProfile.isAvailable
                ? l10n.subtextDailyAvailStatus
                : (currentLocale.languageCode == 'hi'
                    ? 'आपकी प्रोफ़ाइल वर्तमान में सक्रिय प्रेषण पूल से रुकी हुई है। पास के नियोक्ताओं से कॉल प्राप्त करने के लिए उपलब्धता चालू करें।'
                    : 'Your profile is currently paused from active dispatch pool. Turn on availability to receive calls from nearby employers.'),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.inkMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerEarningsStreakWidget(Color primaryColor, Color subtleColor, Locale currentLocale) {
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const int currentStreak = 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.card,
        border: Border.all(color: primaryColor.withValues(alpha: 0.15), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Colors.orange.shade700, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    currentLocale.languageCode == 'hi' ? '5-दिन की सक्रिय लकीर!' : '5-DAY ACTIVE STREAK!',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: subtleColor,
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  currentLocale.languageCode == 'hi' ? 'स्तर 3 कार्यकर्ता' : 'Level 3 Worker',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Day Tracker Circles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = days[index];
              final isActive = index < currentStreak;
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isActive ? primaryColor : AppColors.surfaceRaised,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? Colors.transparent : AppColors.border,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day,
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : AppColors.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isActive)
                    Icon(Icons.check_circle_rounded, size: 10, color: primaryColor)
                  else
                    const SizedBox(height: 10),
                ],
              );
            }),
          ),
          const Divider(color: AppColors.border, height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLocale.languageCode == 'hi' ? 'साप्ताहिक कमाई' : 'WEEKLY EARNINGS',
                    style: GoogleFonts.spaceMono(
                      fontSize: 9.5,
                      color: AppColors.inkMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹3,400',
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currentLocale.languageCode == 'hi' ? 'UPI स्थिति: सक्रिय' : 'UPI Status: Active',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentLocale.languageCode == 'hi' ? 'आज +₹800' : '+₹800 today',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobsFeed(
    AsyncValue<List<Job>> dashboardJobsAsync,
    Color primaryColor,
    bool isEmployer,
    Locale currentLocale,
  ) {
    return dashboardJobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return EmptyState(
            icon: Icons.work_outline_rounded,
            title: isEmployer
                ? (currentLocale.languageCode == 'hi' ? 'कोई पोस्टेड काम नहीं' : 'No Posted Jobs Yet')
                : 'No Active Job Postings',
            description: isEmployer
                ? (currentLocale.languageCode == 'hi'
                    ? 'आपने अभी तक कोई काम पोस्ट नहीं किया है।'
                    : 'You haven\'t posted any jobs yet. Publish a new job dispatch to find workers.')
                : 'Be the first to publish a new job posting on KaamSetu.',
          );
        }
        return Column(
          children: jobs.take(4).map((job) {
            return ServiceCard(
              image: job.imageUrl,
              title: job.title,
              category: job.category,
              thumbsUpCount: null,
              thumbsUpPercentage: null,
              price: job.wage,
              originalPrice: job.originalWage,
              verified: job.verified,
              accentColor: primaryColor,
              onSelect: () => context.push('/job/${job.id}'),
            );
          }).toList(),
        );
      },
      loading: () => const SkeletonList(count: 3),
      error: (err, stack) => const EmptyState(
        icon: Icons.work_outline_rounded,
        title: 'No Active Job Postings',
        description: 'Be the first to publish a new job posting on KaamSetu.',
      ),
    );
  }
}