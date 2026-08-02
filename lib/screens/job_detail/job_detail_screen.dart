import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../widgets/job_status_stepper.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/trust_badge_row.dart';
import '../../widgets/provider_card.dart';
import '../../widgets/sticky_bottom_bar.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;

  const JobDetailScreen({
    super.key,
    this.jobId = 'job-1',
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isApplying = false;
  bool _hasApplied = false;

  Future<void> _handleExpressInterest() async {
    setState(() => _isApplying = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isApplying = false;
        _hasApplied = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.card,
            side: const BorderSide(color: AppColors.brand),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interest Registered!',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your application has been dispatched to Sharma Household.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Job Dispatch Detail',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.inkPrimary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: StatusChip(
              status: StatusChipType.open,
              labelOverride: 'OPEN FOR BIDS',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.border,
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Main Job Title Header Card
            Container(
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
                      Text(
                        'PAINTING DISPATCH',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brand,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                          Text(
                            ' (24)',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    'Full House Painting (Interior Walls)',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Location & Date Badges
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Indiranagar, Stage 2',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Today 14:00',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 2: Lifecycle Stepper
            const JobStatusStepper(
              currentStatus: JobStepStatus.interested,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 3: Task & Site Requirements Card
            Container(
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
                  Text(
                    'TASK & SITE REQUIREMENTS',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildRequirementRow(
                    '3 BHK apartment interior wall painting & primer coat',
                  ),
                  _buildRequirementRow(
                    'All painting equipment, ladders, & drop cloths provided on site',
                  ),
                  _buildRequirementRow(
                    'Working hours: 09:00 AM to 06:00 PM with 1-hour lunch break',
                  ),
                  _buildRequirementRow(
                    'Payment disbursed immediately via UPI upon job completion verification',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const TrustBadgeRow(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 4: Employer Profile Block
            Text(
              'EMPLOYER & DISPATCH OWNER',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const ProviderCard(
              name: 'Sharma Household',
              primarySkill: 'Verified Employer',
              skills: ['Households', 'Interior Renovations'],
              wage: 1500,
              rating: 4.9,
              reviewsCount: 16,
              jobsCompleted: 28,
              phone: '+91 98765 00000',
              isVerified: true,
              isAssigned: false,
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
      bottomNavigationBar: StickyBottomBar(
        label: 'DAILY RATE',
        price: 1500,
        ctaLabel: _hasApplied
            ? 'Interest Expressed ✓'
            : (_isApplying
                ? 'Registering Interest...'
                : 'Express Interest & Apply'),
        isLoading: _isApplying,
        disabled: _hasApplied,
        icon: _hasApplied
            ? const Icon(Icons.check_circle_outline_rounded,
                size: 16, color: Colors.white)
            : const Icon(Icons.work_outline_rounded,
                size: 16, color: Colors.white),
        onCta: _handleExpressInterest,
      ),
    );
  }

  Widget _buildRequirementRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: AppColors.brand,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.inkPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
