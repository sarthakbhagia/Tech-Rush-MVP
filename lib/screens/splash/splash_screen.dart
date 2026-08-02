import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../widgets/logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top-Left Logo Header Lockup & Sign In Action
              Container(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Logo(variant: LogoVariant.header),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/auth'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.control,
                        ),
                      ),
                      icon: const Icon(
                        Icons.login_rounded,
                        size: 14,
                        color: AppColors.inkMuted,
                      ),
                      label: Text(
                        'Sign In',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Product Headline
              Text(
                'Daily Workforce & Dispatch Operations',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkPrimary,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                'Connecting daily-wage workers with households and local businesses for immediate daily jobs.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Trust Metrics Bar
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.card,
                  border: Border.all(color: AppColors.border),
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verified Workers',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 24, width: 1, color: AppColors.border),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '₹650/day',
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
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
                    Container(height: 24, width: 1, color: AppColors.border),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '60 Seconds',
                            style: GoogleFonts.spaceMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkPrimary,
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

              // Overline Section Label
              Text(
                'SELECT NAVIGATION PORTAL',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),

              // PORTAL CARD 1: Household & Employer
              _PortalCard(
                icon: Icons.business_center_rounded,
                iconColor: AppColors.inkMuted,
                title: 'Need Daily Workers?',
                subtitle: 'FOR HOUSEHOLDS & LOCAL BUSINESSES',
                description:
                    'Post daily requirements for cleaning, painting, plumbing, or cooking. Receive applications from verified local workers.',
                featureLabel: 'Instant Job Posting',
                ctaLabel: 'Employer Portal',
                ctaColor: AppColors.brand,
                ctaTextColor: Colors.white,
                onTap: () => context.go('/dashboard'),
              ),
              const SizedBox(height: AppSpacing.md),

              // PORTAL CARD 2: Skilled Worker
              _PortalCard(
                icon: Icons.construction_rounded,
                iconColor: AppColors.success,
                title: 'Looking for Daily Work?',
                subtitle: 'FOR SKILLED DAILY-WAGE WORKERS',
                subtitleColor: AppColors.success,
                description:
                    'Browse open daily listings nearby, express interest, manage your daily availability, and set your expected daily wage rate.',
                featureLabel: 'Direct Employer Contact',
                ctaLabel: 'Worker Feed',
                ctaColor: AppColors.surfaceRaised,
                ctaBorderColor: AppColors.border,
                ctaTextColor: AppColors.inkPrimary,
                onTap: () => context.go('/dashboard'),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Footer Security Badge
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
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final String description;
  final String featureLabel;
  final String ctaLabel;
  final Color ctaColor;
  final Color? ctaBorderColor;
  final Color ctaTextColor;
  final VoidCallback onTap;

  const _PortalCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    required this.description,
    required this.featureLabel,
    required this.ctaLabel,
    required this.ctaColor,
    this.ctaBorderColor,
    required this.ctaTextColor,
    required this.onTap,
  });

  @override
  State<_PortalCard> createState() => _PortalCardState();
}

class _PortalCardState extends State<_PortalCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.card,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius: AppRadii.control,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: widget.iconColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: widget.subtitleColor ?? AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.featureLabel,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.ctaColor,
                        borderRadius: AppRadii.control,
                        border: widget.ctaBorderColor != null
                            ? Border.all(color: widget.ctaBorderColor!)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.ctaLabel,
                            style: GoogleFonts.spaceMono(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.ctaTextColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: widget.ctaTextColor,
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
      ),
    );
  }
}
