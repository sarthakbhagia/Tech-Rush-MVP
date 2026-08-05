import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../models/job.dart';
import '../../models/application.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/job_status_stepper.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/trust_badge_row.dart';
import '../../widgets/provider_card.dart';
import '../../widgets/sticky_bottom_bar.dart';
import '../../widgets/rate_worker_bottom_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({
    super.key,
    this.jobId = 'job-1',
  });

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isApplying = false;

  Future<void> _handleExpressInterest(Job job) async {
    final user = ref.read(userProfileProvider);
    if (!user.isLoggedIn) {
      context.push('/auth/sign-in');
      return;
    }

    setState(() => _isApplying = true);

    final app = await ref.read(applicationServiceProvider).applyToJob(
          jobId: job.id,
          workerId: user.phone.isNotEmpty ? user.phone : 'worker_${user.name}',
          workerName: user.name.isNotEmpty ? user.name : 'Ramesh Kumar',
          workerPhone: user.phone.isNotEmpty ? user.phone : '+91 98765 43210',
        );

    if (mounted) {
      setState(() => _isApplying = false);
      if (app != null) {
        ref.invalidate(jobApplicationsProvider(job.id));
        ref.invalidate(workerApplicationsProvider);
        ref.invalidate(jobDetailProvider(job.id));

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
                  'Application Submitted!',
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your interest has been dispatched to ${job.employerName}.',
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
  }

  Future<void> _handleAcceptApplication(Application app, Job job) async {
    final success = await ref
        .read(applicationServiceProvider)
        .updateApplicationStatus(
          applicationId: app.id,
          jobId: job.id,
          workerName: app.workerName,
          workerId: app.workerId,
          status: 'assigned',
        );

    if (mounted && success) {
      ref.invalidate(jobApplicationsProvider(job.id));
      ref.invalidate(jobDetailProvider(job.id));
      ref.invalidate(jobsByCategoryProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            'Assigned ${app.workerName} to ${job.title}!',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncJob = ref.watch(jobDetailProvider(widget.jobId));
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.inkPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          l10n.jobDetailTitle,
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
      body: asyncJob.when(
        data: (job) {
          if (job == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: EmptyState(
                  icon: Icons.work_off_outlined,
                  title: 'Job Dispatch Not Found',
                  description: 'The requested job posting could not be found or has been un-published.',
                ),
              ),
            );
          }

          final isAssigned = job.status == 'assigned';
          final isCompleted = job.status == 'completed';
          final currentStep = isCompleted
              ? JobStepStatus.completed
              : (isAssigned
                  ? JobStepStatus.assigned
                  : JobStepStatus.posted);

          final asyncApps = ref.watch(jobApplicationsProvider(job.id));
          final applications = asyncApps.asData?.value ?? [];
          final hasApplied = applications.any(
              (a) => a.workerId == (user.phone.isNotEmpty ? user.phone : 'worker_${user.name}'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
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
                          Expanded(
                            child: Text(
                              '${job.category.toUpperCase()} DISPATCH',
                              style: GoogleFonts.spaceMono(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brand,
                                letterSpacing: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          StatusChip(
                            status: isCompleted
                                ? StatusChipType.completed
                                : (isAssigned
                                    ? StatusChipType.assigned
                                    : StatusChipType.open),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        job.title,
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.location,
                              style: GoogleFonts.spaceMono(
                                fontSize: 11,
                                color: AppColors.inkMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            job.date,
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

                // Stepper
                JobStatusStepper(currentStatus: currentStep),
                const SizedBox(height: AppSpacing.lg),

                // Description & Requirements
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
                        l10n.jobDetailTaskRequirements,
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildRequirementRow(job.description),
                      _buildRequirementRow(
                        'Working hours: 09:00 AM to 06:00 PM with 1-hour lunch break',
                      ),
                      _buildRequirementRow(
                        'Same-day guaranteed UPI payout upon job completion verification',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const TrustBadgeRow(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Employer Info
                Text(
                  l10n.jobDetailEmployerHeader,
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ProviderCard(
                  name: job.employerName,
                  primarySkill: 'Verified Employer',
                  skills: const ['Households', 'Dispatch Owner'],
                  wage: job.wage,
                  rating: job.rating,
                  reviewsCount: job.reviewCount,
                  jobsCompleted: 12,
                  phone: '+91 98765 00000',
                  isVerified: job.verified,
                  isAssigned: isAssigned,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Applicant List (For Employer or viewable applications)
                Text(
                  '${l10n.jobDetailApplicantBids} (${applications.length})',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                if (applications.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.card,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      l10n.jobDetailNoApps,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  )
                else
                  Column(
                    children: applications.map((app) {
                      final isSelected = app.status == 'assigned';
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brandSubtle : AppColors.surface,
                          borderRadius: AppRadii.card,
                          border: Border.all(
                            color: isSelected ? AppColors.brand : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceRaised,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded,
                                  size: 20, color: AppColors.brand),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app.workerName,
                                    style: GoogleFonts.sora(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${app.workerPhone} • ${app.status.toUpperCase()}',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 10,
                                      color: isSelected ? AppColors.brand : AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isAssigned && app.status != 'rejected')
                              ElevatedButton(
                                onPressed: () => _handleAcceptApplication(app, job),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brand,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadii.pill,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                                child: Text(
                                  l10n.jobDetailAcceptCta,
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else if (isSelected)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.brand,
                                      borderRadius: AppRadii.pill,
                                    ),
                                    child: Text(
                                      isCompleted ? 'COMPLETED' : 'ASSIGNED',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () async {
                                      if (!isCompleted) {
                                        // Mark job completed in database first
                                        await ref.read(jobServiceProvider).updateJobStatus(
                                              jobId: job.id,
                                              status: 'completed',
                                            );
                                        ref.invalidate(jobDetailProvider(job.id));
                                        ref.invalidate(jobsByCategoryProvider);
                                        ref.invalidate(filteredJobsProvider);
                                      }
                                      if (mounted) {
                                        openRateWorkerBottomSheet(
                                          context,
                                          ref,
                                          jobId: job.id,
                                          workerId: app.workerId,
                                          workerName: app.workerName,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceRaised,
                                        borderRadius: AppRadii.pill,
                                        border: Border.all(color: AppColors.warning),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              size: 12, color: AppColors.warning),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Rate Worker',
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          body: Center(
            child: Text(
              'Error loading job: $err',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger),
            ),
          ),
        ),
      ),
      bottomNavigationBar: asyncJob.maybeWhen(
        data: (job) {
          if (job == null) return null;
          final asyncApps = ref.watch(jobApplicationsProvider(job.id));
          final applications = asyncApps.asData?.value ?? [];
          final hasApplied = applications.any(
              (a) => a.workerId == (user.phone.isNotEmpty ? user.phone : 'worker_${user.name}'));
          final isAssigned = job.status == 'assigned';

          return StickyBottomBar(
            label: 'DAILY RATE',
            price: job.wage,
            ctaLabel: isAssigned
                ? 'Job Assigned (${job.workerName ?? "Worker"})'
                : (hasApplied
                    ? 'Interest Expressed ✓'
                    : (_isApplying
                        ? 'Registering Interest...'
                        : 'Express Interest & Apply')),
            isLoading: _isApplying,
            disabled: hasApplied || isAssigned,
            icon: (hasApplied || isAssigned)
                ? const Icon(Icons.check_circle_outline_rounded,
                    size: 16, color: Colors.white)
                : const Icon(Icons.work_outline_rounded,
                    size: 16, color: Colors.white),
            onCta: () => _handleExpressInterest(job),
          );
        },
        orElse: () => null,
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
