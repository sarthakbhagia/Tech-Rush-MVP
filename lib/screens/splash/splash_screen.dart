import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../widgets/logo.dart';

enum GuestRole { employer, worker }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  GuestRole _role = GuestRole.employer;

  void _toggleRole(GuestRole role) {
    setState(() => _role = role);
  }

  void _navigateToAuth() {
    context.push('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final isEmployer = _role == GuestRole.employer;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------------
              // 1. HERO SECTION (Identical to Post-Auth Dashboard)
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
                    // Header Row: KaamSetu Logo + App Tagline + Sign In Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Logo
                        const Logo(variant: LogoVariant.header),

                        // Center App Tagline
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KaamSetu OPS',
                                  style: GoogleFonts.sora(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Daily Workforce Dispatch',
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

                        // Right Sign In CTA Button
                        GestureDetector(
                          onTap: _navigateToAuth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppRadii.pill,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.login_rounded,
                                  size: 13,
                                  color: AppColors.brand,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sign In',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Embedded Mode Segmented Control / Pill Toggle
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: AppRadii.pill,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleRole(GuestRole.employer),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7.0),
                                decoration: BoxDecoration(
                                  color: isEmployer
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: AppRadii.pill,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'I NEED WORKERS',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isEmployer
                                        ? AppColors.brand
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleRole(GuestRole.worker),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7.0),
                                decoration: BoxDecoration(
                                  color: !isEmployer
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: AppRadii.pill,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "I'M LOOKING FOR WORK",
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: !isEmployer
                                        ? AppColors.brand
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Hero Guest Headline & Subtext
                    Text(
                      isEmployer
                          ? 'What daily service do you need done today?'
                          : 'Browse Open Daily Dispatches Nearby',
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

                    // Floating White Search Bar (Gated -> Auth)
                    GestureDetector(
                      onTap: _navigateToAuth,
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
                                    : 'Search jobs near your location...',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceRaised,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: AppColors.inkPrimary,
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
              // 2. CATEGORY DISCOVERY GRID (Identical to Post-Auth Dashboard)
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
                        GestureDetector(
                          onTap: _navigateToAuth,
                          child: Text(
                            'Sign In to Browse ->',
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

                    // 3-Column Marketplace Category Grid (Gated -> Auth)
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.95,
                      children: [
                        _CategoryTile(
                          icon: Icons.format_paint_rounded,
                          label: 'Painting',
                          badgeText: 'HIGH DEMAND',
                          badgeColor: AppColors.brand,
                          badgeBg: const Color(0xFFFFF7ED),
                          onTap: _navigateToAuth,
                        ),
                        _CategoryTile(
                          icon: Icons.cleaning_services_rounded,
                          label: 'Cleaning',
                          badgeText: 'POPULAR',
                          badgeColor: const Color(0xFF2563EB),
                          badgeBg: const Color(0xFFEFF6FF),
                          onTap: _navigateToAuth,
                        ),
                        _CategoryTile(
                          icon: Icons.plumbing_rounded,
                          label: 'Plumbing',
                          badgeText: 'URGENT',
                          badgeColor: AppColors.danger,
                          badgeBg: const Color(0xFFFEF2F2),
                          onTap: _navigateToAuth,
                        ),
                        _CategoryTile(
                          icon: Icons.soup_kitchen_rounded,
                          label: 'Cooking',
                          onTap: _navigateToAuth,
                        ),
                        _CategoryTile(
                          icon: Icons.grass_rounded,
                          label: 'Gardening',
                          onTap: _navigateToAuth,
                        ),
                        _CategoryTile(
                          icon: Icons.electric_bolt_rounded,
                          label: 'Electrical',
                          onTap: _navigateToAuth,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ---------------------------------------------------------
                    // 3. TRUST METRICS BAR & SECURITY FOOTER
                    // ---------------------------------------------------------
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md + 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadii.card,
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '1,200+',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Verified Pros',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '₹650/day',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Avg Daily Rate',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: AppColors.border,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '60 Sec',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brand,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Job Dispatch',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Security & Compliance Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'RLS ENFORCED • AADHAAR VERIFIED WORKFORCE',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeBg;
  final VoidCallback onTap;

  const _CategoryTile({
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.card,
              boxShadow: AppShadows.card,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
          if (badgeText != null)
            Positioned(
              top: -5,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
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
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
