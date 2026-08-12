import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../models/job.dart';
import 'package:kaamsetu/models/user_profile.dart';
import '../../models/application.dart';
import '../../models/job_category.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/job_status_stepper.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/trust_badge_row.dart';
import '../../widgets/provider_card.dart';
import '../../widgets/sticky_bottom_bar.dart';
import '../../widgets/thumbs_rating_bottom_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/review_provider.dart';
import '../../providers/job_dispute_provider.dart';
import '../../widgets/report_issue_bottom_sheet.dart';
import '../../models/job_dispute.dart';
import '../../services/notification_service.dart';
import '../../providers/worker_match_provider.dart';
import '../../providers/payout_provider.dart';
import '../../models/payout.dart';
import '../../providers/completion_proof_provider.dart';
import '../../models/completion_proof.dart';
import 'completion_proof_bottom_sheet.dart';


/// Provider that fetches photo_url + name for any user profile by ID.
final profileDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  try {
    if (userId.isEmpty) return {};
    final client = SupabaseService().client;
    final res = await client
        .from('profiles')
        .select('full_name, photo_url')
        .eq('id', userId)
        .maybeSingle();
    if (res == null) return {};
    return {
      'name': res['full_name']?.toString() ?? '',
      'photo_url': res['photo_url']?.toString(),
    };
  } catch (_) {
    return {};
  }
});

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
  Timer? _payoutTimer;

  @override
  void initState() {
    super.initState();
    _payoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        ref.invalidate(jobPayoutProvider(widget.jobId));
      }
    });
  }

  @override
  void dispose() {
    _payoutTimer?.cancel();
    super.dispose();
  }


  Future<void> _handleExpressInterest(Job job) async {
    final user = ref.read(userProfileProvider);

    // Check both the provider state AND the live Supabase session to avoid
    // the race condition where _checkInitialSession hasn't completed yet.
    final liveSession = SupabaseService().client.auth.currentSession;
    final liveUser = SupabaseService().client.auth.currentUser;
    final isAuthenticated =
        user.isLoggedIn || liveSession != null || liveUser != null;

    if (!isAuthenticated) {
      context.push('/auth/sign-in');
      return;
    }

    if (user.isLoggedIn && user.role == 'employer') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            'Security violation: Employers are not allowed to apply to jobs.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _isApplying = true);

    // Resolve the real UUID — prefer live Supabase session over provider state
    final resolvedId = liveUser?.id ??
        (user.id?.isNotEmpty == true ? user.id! : null) ??
        (user.phone.isNotEmpty ? user.phone : 'worker_${user.name}');

    try {
      final app = await ref.read(applicationServiceProvider).applyToJob(
            jobId: job.id,
            workerId: resolvedId,
            workerName: user.name.isNotEmpty
                ? user.name
                : (liveUser?.email?.split('@').first ?? 'Worker'),
            workerPhone: user.phone.isNotEmpty ? user.phone : '',
          );

      if (mounted) {
        setState(() => _isApplying = false);
        if (app != null) {
          ref.invalidate(jobApplicationsProvider(job.id));
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
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              'Failed to apply: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.inter(color: Colors.white),
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
      ref.invalidate(filteredJobsProvider);
      // Explicitly evict match cache — the UI guard + provider guard also
      // prevent rendering, but this ensures stale data is never held in memory.
      ref.invalidate(workerMatchesProvider(job));

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

  Future<void> _handleRejectApplication(Application app, Job job) async {
    final success = await ref
        .read(applicationServiceProvider)
        .updateApplicationStatus(
          applicationId: app.id,
          jobId: job.id,
          workerName: app.workerName,
          workerId: app.workerId,
          status: 'rejected',
        );

    if (mounted && success) {
      ref.invalidate(jobApplicationsProvider(job.id));
      ref.invalidate(jobDetailProvider(job.id));
      ref.invalidate(jobsByCategoryProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.brand,
          content: Text(
            'Rejected ${app.workerName}\'s application.',
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

          // ── Status helpers ──────────────────────────────────────────────
          final isAssigned = job.status == 'assigned';
          final isOnTheWay = job.status == 'on_the_way';
          final isArrived = job.status == 'arrived';
          final isWorking = job.status == 'working';
          final isProofSubmitted = job.status == 'proof_submitted';
          final isCompleted = job.status == 'completed';
          final isInProgress = isOnTheWay || isArrived || isWorking || isProofSubmitted;

          final currentStep = isCompleted
              ? JobStepStatus.completed
              : (isAssigned || isInProgress
                  ? JobStepStatus.assigned
                  : JobStepStatus.posted);

          final asyncApps = ref.watch(jobApplicationsProvider(job.id));
          final applications = asyncApps.asData?.value ?? [];
          final liveUid = SupabaseService().client.auth.currentUser?.id;
          final employerProfileAsync = job.employerId != null && job.employerId!.isNotEmpty
              ? ref.watch(profileDetailsProvider(job.employerId!))
              : null;
          final employerPhotoUrl = employerProfileAsync?.valueOrNull?['photo_url'] as String?;
          final resolvedReporterId = (user.isLoggedIn && user.id != null && user.id!.isNotEmpty)
              ? user.id!
              : (liveUid ?? activeUserId);
          final isJobOwner = job.employerId != null && resolvedReporterId == job.employerId;
          final isAssignedWorker = applications.any((a) => a.status == 'assigned' && a.workerId == resolvedReporterId);
          final viewerIsParticipant = isJobOwner || isAssignedWorker;

          // ── Payout & Proof ─────────────────────────────────────────────
          final payoutAsync = isCompleted
              ? ref.watch(jobPayoutProvider(job.id))
              : const AsyncValue<Payout?>.data(null);
          final payout = payoutAsync.asData?.value;

          final proofAsync = (isAssigned || isInProgress || isCompleted)
              ? ref.watch(completionProofForJobProvider(job.id))
              : const AsyncValue<CompletionProof?>.data(null);
          final proof = proofAsync.asData?.value;

          return SingleChildScrollView(


            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Image / Category Fallback Hero Image
                Container(
                  width: double.infinity,
                  height: 180,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.card,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: job.imageUrl != null && job.imageUrl!.isNotEmpty
                      ? Image.network(
                          job.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDetailCategoryFallback(job.category),
                        )
                      : _buildDetailCategoryFallback(job.category),
                ),
                // Mutual Rating Banner removed - rating now only triggered via bottom sheet modal

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

                // ── Worker: Job Timeline Card (if assigned worker) ──────────
                if (isAssignedWorker && !isCompleted)
                  _buildWorkerTimeline(context, ref, job, resolvedReporterId),

                // ── Employer: Worker Progress Card (if job is in progress) ─
                if (isJobOwner && (isInProgress || isProofSubmitted)) ...[  
                  _buildEmployerProgressView(job),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Employer: Completion Verification Card ────────────────
                if (isJobOwner && isProofSubmitted) ...[  
                  _buildEmployerProofVerification(
                    context, ref, job,
                    resolvedReporterId,
                    applications,
                    proof,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Payment Stepper (after completion) ────────────────────
                if (isCompleted && viewerIsParticipant) ...[
                  _buildPaymentStepper(payout, job.wage),
                ],

                // ── Best Matches: only visible when job is genuinely open ─
                // Hidden once ANY worker has been assigned or the job is no
                // longer accepting workers. This is the UI guard; the
                // workerMatchesProvider also returns [] for non-open jobs.
                if (isJobOwner && !isAssigned && !isInProgress && !isCompleted) ...[
                  RecommendedWorkersSection(job: job),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (isCompleted && viewerIsParticipant) ...[
                  _buildFeedbackAndDisputeSection(context, ref, job, resolvedReporterId, user, liveUid, applications),
                  const SizedBox(height: AppSpacing.lg),
                ],

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
                  photoUrl: employerPhotoUrl,
                  primarySkill: 'Verified Employer',
                  skills: const ['Households', 'Dispatch Owner'],
                  wage: job.wage,
                  rating: job.rating,
                  reviewsCount: job.reviewCount,
                  jobsCompleted: 12,
                  phone: '+91 98765 00000',
                  isVerified: job.verified,
                  isAssigned: isAssigned,
                  rateeId: job.employerId,
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
                      final liveUid = SupabaseService().client.auth.currentUser?.id;

                      return _ApplicantRow(
                        app: app,
                        job: job,
                        user: user,
                        isSelected: isSelected,
                        isAssigned: isAssigned,
                        onAccept: () => _handleAcceptApplication(app, job),
                        onReject: () => _handleRejectApplication(app, job),
                        onRateWorker: () async {
                          if (!isCompleted) {
                            await ref
                                .read(jobServiceProvider)
                                .updateJobStatus(
                                    jobId: job.id,
                                    status: 'completed');
                            ref.invalidate(jobDetailProvider(job.id));
                            ref.invalidate(jobsByCategoryProvider);
                            ref.invalidate(filteredJobsProvider);
                          }
                          if (mounted) {
                            openThumbsRatingBottomSheet(
                              context,
                              ref,
                              jobId: job.id,
                              evaluatorId: (user.isLoggedIn && user.id != null && user.id!.isNotEmpty)
                                  ? user.id!
                                  : (liveUid ?? activeUserId),
                              targetId: app.workerId,
                              targetName: app.workerName,
                              raterRole: 'employer',
                              employerId: job.employerId ?? '',
                              workerId: app.workerId,
                            );
                          }
                        },
                        onRateEmployer: () {
                          openThumbsRatingBottomSheet(
                            context,
                            ref,
                            jobId: job.id,
                            evaluatorId: (user.isLoggedIn && user.id != null && user.id!.isNotEmpty)
                                  ? user.id!
                                  : (liveUid ?? activeUserId),
                            targetId: job.employerId ?? '',
                            targetName: job.employerName,
                            raterRole: 'worker',
                            employerId: job.employerId ?? '',
                            workerId: app.workerId,
                          );
                        },
                        onReportIssue: () {
                          final reporterId = (user.isLoggedIn && user.id != null && user.id!.isNotEmpty)
                              ? user.id!
                              : (liveUid ?? activeUserId);
                          final owner = job.employerId != null && reporterId == job.employerId;
                          final reporterRole = owner ? 'employer' : 'worker';
                          final otherPartyId = owner ? app.workerId : job.employerId;
                          if (reporterId.isEmpty) return;
                          openReportIssueBottomSheet(
                            context,
                            ref,
                            jobId: job.id,
                            reporterId: reporterId,
                            reporterRole: reporterRole,
                            jobTitle: job.title,
                            otherPartyId: otherPartyId,
                          );
                        },
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
          final bottomWorkerId = user.id?.isNotEmpty == true
              ? user.id!
              : (user.phone.isNotEmpty ? user.phone : 'worker_${user.name}');
          final hasApplied = applications.any((a) => a.workerId == bottomWorkerId);
          final isAssigned = job.status == 'assigned';
          final isOnTheWay = job.status == 'on_the_way';
          final isArrived = job.status == 'arrived';
          final isWorking = job.status == 'working';
          final isProofSubmitted = job.status == 'proof_submitted';
          final isCompleted = job.status == 'completed';
          final isInProgress = isOnTheWay || isArrived || isWorking || isProofSubmitted;

          final liveUid = SupabaseService().client.auth.currentUser?.id;
          final loggedInEmployer = user.isLoggedIn && user.role == 'employer';
          final isOwner = (liveUid != null && liveUid == job.employerId) ||
                          (user.id != null && user.id == job.employerId);
          final resolvedReporterId = (user.isLoggedIn && user.id != null && user.id!.isNotEmpty)
              ? user.id!
              : (liveUid ?? activeUserId);
          final isAssignedWorker = applications.any(
              (a) => a.status == 'assigned' && a.workerId == resolvedReporterId);

          // ── Employer bottom bar ───────────────────────────────────────
          if (loggedInEmployer) {
            if (isOwner) {
              if (isProofSubmitted) {
                // Employer sees a CTA to scroll up and review proof
                return StickyBottomBar(
                  label: 'PROOF SUBMITTED',
                  price: job.wage,
                  ctaLabel: 'Review & Verify Completion ↑',
                  isLoading: false,
                  disabled: false,
                  icon: const Icon(Icons.verified_outlined, size: 16, color: Colors.white),
                  onCta: () {},
                );
              } else if (isInProgress) {
                return StickyBottomBar(
                  label: 'WORKER IN PROGRESS',
                  price: job.wage,
                  ctaLabel: 'Awaiting Completion Proof...',
                  isLoading: false,
                  disabled: true,
                  icon: const Icon(Icons.access_time_rounded, size: 16, color: Colors.white),
                  onCta: () {},
                );
              } else if (isAssigned) {
                return StickyBottomBar(
                  label: 'STATUS: ASSIGNED',
                  price: job.wage,
                  ctaLabel: 'Awaiting Worker Check-in...',
                  isLoading: false,
                  disabled: true,
                  icon: const Icon(Icons.directions_walk_rounded, size: 16, color: Colors.white),
                  onCta: () {},
                );
              } else if (isCompleted) {
                return StickyBottomBar(
                  label: 'STATUS: COMPLETED',
                  price: job.wage,
                  ctaLabel: 'Job Completed ✓',
                  isLoading: false,
                  disabled: true,
                  icon: const Icon(Icons.done_all_rounded, size: 16, color: Colors.white),
                  onCta: () {},
                );
              } else {
                return StickyBottomBar(
                  label: 'STATUS: OPEN',
                  price: job.wage,
                  ctaLabel: 'Awaiting Applicants...',
                  isLoading: false,
                  disabled: true,
                  icon: const Icon(Icons.people_outline_rounded, size: 16, color: Colors.white),
                  onCta: () {},
                );
              }
            } else {
              return StickyBottomBar(
                label: 'DAILY RATE',
                price: job.wage,
                ctaLabel: 'Employer Mode',
                isLoading: false,
                disabled: true,
                icon: const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.white),
                onCta: () {},
              );
            }
          }

          if (isCompleted) {
            return StickyBottomBar(
              label: 'STATUS: COMPLETED',
              price: job.wage,
              ctaLabel: 'Job Completed ✓',
              isLoading: false,
              disabled: true,
              icon: const Icon(Icons.done_all_rounded, size: 16, color: Colors.white),
              onCta: () {},
            );
          }

          // ── Worker assigned: sequential check-in bottom bar ──────────
          final isThisWorker = isAssignedWorker;

          if (isThisWorker && isProofSubmitted) {
            return StickyBottomBar(
              label: 'PROOF SUBMITTED',
              price: job.wage,
              ctaLabel: 'Awaiting Employer Verification...',
              isLoading: false,
              disabled: true,
              icon: const Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.white),
              onCta: () {},
            );
          }

          if (isThisWorker && isWorking) {
            return StickyBottomBar(
              label: 'STATUS: WORKING',
              price: job.wage,
              ctaLabel: 'Submit Completion',
              isLoading: false,
              disabled: false,
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 16, color: Colors.white),
              onCta: () {
                openCompletionProofBottomSheet(
                  context, ref,
                  jobId: job.id,
                  workerId: resolvedReporterId,
                  jobTitle: job.title,
                  onSubmitted: () {
                    ref.invalidate(jobDetailProvider(job.id));
                    ref.invalidate(completionProofForJobProvider(job.id));
                  },
                );
              },
            );
          }

          if (isThisWorker && isArrived) {
            return StickyBottomBar(
              label: 'STATUS: ARRIVED',
              price: job.wage,
              ctaLabel: 'Start Job',
              isLoading: false,
              disabled: false,
              icon: const Icon(Icons.play_circle_outline_rounded, size: 16, color: Colors.white),
              onCta: () async {
                await ref.read(jobServiceProvider).updateWorkerProgress(
                  jobId: job.id, newStatus: 'working');
                ref.invalidate(jobDetailProvider(job.id));
              },
            );
          }

          if (isThisWorker && isOnTheWay) {
            return StickyBottomBar(
              label: "STATUS: ON THE WAY",
              price: job.wage,
              ctaLabel: "I've Arrived",
              isLoading: false,
              disabled: false,
              icon: const Icon(Icons.location_on_rounded, size: 16, color: Colors.white),
              onCta: () async {
                await ref.read(jobServiceProvider).updateWorkerProgress(
                  jobId: job.id, newStatus: 'arrived');
                ref.invalidate(jobDetailProvider(job.id));
              },
            );
          }

          if (isThisWorker && isAssigned) {
            return StickyBottomBar(
              label: 'STATUS: ASSIGNED',
              price: job.wage,
              ctaLabel: "I'm On My Way",
              isLoading: false,
              disabled: false,
              icon: const Icon(Icons.directions_walk_rounded, size: 16, color: Colors.white),
              onCta: () async {
                await ref.read(jobServiceProvider).updateWorkerProgress(
                  jobId: job.id, newStatus: 'on_the_way');
                ref.invalidate(jobDetailProvider(job.id));
              },
            );
          }

          return StickyBottomBar(
            label: 'DAILY RATE',
            price: job.wage,
            ctaLabel: (isAssigned || isInProgress)
                ? 'Job Assigned (${job.workerName ?? "Worker"})'
                : (hasApplied
                    ? 'Interest Expressed ✓'
                    : (_isApplying
                        ? 'Registering Interest...'
                        : 'Express Interest & Apply')),
            isLoading: _isApplying,
            disabled: hasApplied || isAssigned || isInProgress,
            icon: (hasApplied || isAssigned || isInProgress)
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

  // ── Worker Timeline Card ─────────────────────────────────────────────────

  Widget _buildWorkerTimeline(
    BuildContext context,
    WidgetRef ref,
    Job job,
    String workerId,
  ) {
    final status = job.status;
    final steps = [
      ('assigned', Icons.assignment_outlined, 'Assigned'),
      ('on_the_way', Icons.directions_walk_rounded, 'On the Way'),
      ('arrived', Icons.location_on_rounded, 'Arrived'),
      ('working', Icons.construction_rounded, 'Working'),
      ('proof_submitted', Icons.assignment_turned_in_outlined, 'Proof Submitted'),
    ];
    final statusOrder = ['assigned', 'on_the_way', 'arrived', 'working', 'proof_submitted', 'completed'];
    final currentIndex = statusOrder.indexOf(status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandSubtle, Color(0xFFF9F4F4)],
        ),
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.brand.withOpacity(0.2)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_history_rounded, color: AppColors.brand, size: 18),
              const SizedBox(width: 8),
              Text(
                "TODAY'S JOB",
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  status.toUpperCase().replaceAll('_', ' '),
                  style: GoogleFonts.spaceMono(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            job.title,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Timeline steps
          ...steps.asMap().entries.map((entry) {
            final stepIndex = statusOrder.indexOf(entry.value.$1);
            final isDone = stepIndex < currentIndex;
            final isActive = entry.value.$1 == status;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppColors.success
                                : (isActive ? AppColors.brand : AppColors.border),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDone
                                ? Icons.check_rounded
                                : (isActive ? entry.value.$2 : entry.value.$2),
                            color: isDone || isActive
                                ? Colors.white
                                : AppColors.inkMuted,
                            size: 13,
                          ),
                        ),
                        if (entry.key < steps.length - 1)
                          Container(
                            width: 2,
                            height: 16,
                            color: isDone ? AppColors.success : AppColors.border,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    entry.value.$3,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isDone
                          ? AppColors.success
                          : (isActive ? AppColors.inkPrimary : AppColors.inkMuted),
                    ),
                  ),
                  if (isDone) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                  ],
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Text('← Current', style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.brand)),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Employer: Worker Progress View ───────────────────────────────────────

  Widget _buildEmployerProgressView(Job job) {
    final status = job.status;
    final statusLabel = status.toUpperCase().replaceAll('_', ' ');
    final workerName = job.workerName ?? 'Worker';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'on_the_way':
        statusColor = AppColors.warning;
        statusIcon = Icons.directions_walk_rounded;
        break;
      case 'arrived':
        statusColor = AppColors.brand;
        statusIcon = Icons.location_on_rounded;
        break;
      case 'working':
        statusColor = AppColors.brand;
        statusIcon = Icons.construction_rounded;
        break;
      case 'proof_submitted':
        statusColor = AppColors.success;
        statusIcon = Icons.assignment_turned_in_outlined;
        break;
      default:
        statusColor = AppColors.inkMuted;
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORKER STATUS',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '$workerName — $statusLabel',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: AppRadii.pill,
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Employer: Completion Verification Card ───────────────────────────────

  Widget _buildEmployerProofVerification(
    BuildContext context,
    WidgetRef ref,
    Job job,
    String employerId,
    List<Application> applications,
    CompletionProof? proof,
  ) {
    final workerName = job.workerName ??
        applications.firstWhere((a) => a.status == 'assigned',
            orElse: () => Application(
                id: '', jobId: '', workerId: '', workerName: 'Worker',
                workerPhone: '', status: '', createdAt: DateTime.now())).workerName;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FDF4), Color(0xFFF9FFFE)],
        ),
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'VERIFY COMPLETION',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$workerName has submitted proof of completed work. Review and verify to release payment.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.inkMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.md),

          // Proof photos
          if (proof != null && proof.proofImageUrls.isNotEmpty) ...[
            Text(
              'PROOF PHOTOS (${proof.proofImageUrls.length})',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.inkMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: proof.proofImageUrls.map((url) {
                  final isDemo = url.startsWith('demo://');
                  return Container(
                    width: 90,
                    height: 90,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.control,
                      border: Border.all(color: AppColors.success.withOpacity(0.4)),
                      color: AppColors.surfaceRaised,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isDemo
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_outlined, color: AppColors.inkMuted, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'DEMO\nPHOTO',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.spaceMono(fontSize: 7, color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                          )
                        : Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.inkMuted,
                              size: 28,
                            ),
                          ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadii.control,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: AppColors.inkMuted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Worker submitted completion — photos loading...',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Submitted at
          if (proof != null) ...[
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 13, color: AppColors.inkMuted),
                const SizedBox(width: 4),
                Text(
                  'Submitted ${_formatTime(proof.submittedAt)}',
                  style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.inkMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.control),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    // 1. Verify the proof record
                    if (proof != null) {
                      await ref
                          .read(completionProofServiceProvider)
                          .verifyProof(jobId: job.id, verifiedBy: employerId);
                    }
                    // 2. Mark job as completed → triggers existing demo payment
                    final success = await ref
                        .read(jobServiceProvider)
                        .verifyCompletion(jobId: job.id);
                    if (success) {
                      ref.invalidate(jobDetailProvider(job.id));
                      ref.invalidate(jobsByCategoryProvider);
                      ref.invalidate(filteredJobsProvider);
                      ref.invalidate(completionProofForJobProvider(job.id));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text(
                              '✓ Job verified! Payment processing...',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 17),
                  label: Text(
                    'ACCEPT & PAY',
                    style: GoogleFonts.spaceMono(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.control),
                    backgroundColor: AppColors.dangerSubtle,
                  ),
                  onPressed: () {
                    final assignedApp = applications.firstWhere(
                      (a) => a.status == 'assigned',
                      orElse: () => Application(
                          id: '', jobId: '', workerId: '', workerName: 'Worker',
                          workerPhone: '', status: '', createdAt: DateTime.now()),
                    );
                    openReportIssueBottomSheet(
                      context,
                      ref,
                      jobId: job.id,
                      reporterId: employerId,
                      reporterRole: 'employer',
                      jobTitle: job.title,
                      otherPartyId: assignedApp.workerId.isNotEmpty ? assignedApp.workerId : null,
                    );
                  },
                  icon: const Icon(Icons.flag_outlined, size: 15, color: AppColors.danger),
                  label: Text(
                    'DISPUTE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildDetailCategoryFallback(String category) {
    final catObj = AppCategories.findById(category);
    final icon = catObj?.icon ?? Icons.work_outline_rounded;
    final prefix = category.length >= 3 ? category.substring(0, 3).toUpperCase() : category.toUpperCase();
    
    return Container(
      color: AppColors.surfaceRaised,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.brand,
            ),
            const SizedBox(height: 8),
            Text(
              prefix,
              style: GoogleFonts.spaceMono(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
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

  Widget _buildFeedbackAndDisputeSection(
    BuildContext context,
    WidgetRef ref,
    Job job,
    String reporterId,
    UserProfile user,
    String? liveUid,
    List<Application> applications,
  ) {
    final isJobOwner = job.employerId != null && reporterId == job.employerId;
    final hasAssigned = applications.any((a) => a.status == 'assigned');
    final assignedApp = hasAssigned
        ? applications.firstWhere((a) => a.status == 'assigned')
        : null;
    final otherPartyId = isJobOwner ? (assignedApp?.workerId ?? '') : (job.employerId ?? '');
    final otherPartyName = isJobOwner ? (assignedApp?.workerName ?? 'Worker') : (job.employerName);

    final hasRatedAsync = ref.watch(hasRatedProvider((jobId: job.id, raterId: reporterId)));
    final hasRated = hasRatedAsync.valueOrNull ?? false;

    final disputesAsync = ref.watch(jobDisputesProvider(job.id));
    final disputes = disputesAsync.valueOrNull ?? [];

    JobDispute? myDispute;
    for (final d in disputes) {
      if (d.reporterId == reporterId) {
        myDispute = d;
        break;
      }
    }

    return Container(
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
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.brand,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'JOB RESOLUTION & FEEDBACK',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),

          // Happy Path: Ratings
          Text(
            'Happy Path: Rate Experience',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (hasRated)
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Text(
                  'You have submitted a rating for this job.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else ...[
            Text(
              'Share your feedback. Rating helps keep the community safe and reliable.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.brand),
                  shape: RoundedRectangleBorder(borderRadius: AppRadii.control),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  openThumbsRatingBottomSheet(
                    context,
                    ref,
                    jobId: job.id,
                    evaluatorId: reporterId,
                    targetId: otherPartyId.isNotEmpty ? otherPartyId : (job.employerId ?? ''),
                    targetName: otherPartyName.isNotEmpty ? otherPartyName : 'User',
                    raterRole: isJobOwner ? 'employer' : 'worker',
                    employerId: job.employerId ?? '',
                    workerId: isJobOwner ? (otherPartyId.isNotEmpty ? otherPartyId : '') : reporterId,
                  );
                },
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 16, color: AppColors.brand),
                label: Text(
                  isJobOwner ? 'Rate Worker' : 'Rate Employer',
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brand,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),

          // Unhappy Path: Disputes/Complaints
          Text(
            'Unhappy Path: Report an Issue / Dispute',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // List any existing disputes
          if (disputes.isNotEmpty) ...[
            ...disputes.map((dispute) {
              final isMyDispute = dispute.reporterId == reporterId;
              final statusLabel = dispute.status == 'resolved' ? 'RESOLVED' : 'UNDER REVIEW';
              final statusColor = dispute.status == 'resolved' ? AppColors.success : AppColors.warning;
              final statusBgColor = dispute.status == 'resolved' ? AppColors.successSubtle : AppColors.warningSubtle;

              return Container(
                margin: const EdgeInsets.only(bottom: 8, top: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMyDispute ? AppColors.dangerSubtle : AppColors.surfaceRaised,
                  borderRadius: AppRadii.control,
                  border: Border.all(
                    color: isMyDispute ? AppColors.danger.withOpacity(0.2) : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMyDispute ? 'Dispute Filed by You' : (dispute.reporterRole == 'employer' ? 'Dispute Filed by Employer' : 'Dispute Filed by Worker'),
                          style: GoogleFonts.spaceMono(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.spaceMono(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Category: ${dispute.category}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dispute.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.inkPrimary,
                        height: 1.3,
                      ),
                    ),
                    if (dispute.resolutionNote != null && dispute.resolutionNote!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 6),
                      Text(
                        'Resolution Note:',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        dispute.resolutionNote!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.inkPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ] else ...[
            Text(
              'Did something go wrong? If there is an issue with payment, work quality, no-show, or misconduct, flag this job for review rather than leaving a rating.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkMuted),
            ),
          ],

          // Dispute Report Button
          if (myDispute == null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(borderRadius: AppRadii.control),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.dangerSubtle,
                ),
                onPressed: () {
                  openReportIssueBottomSheet(
                    context,
                    ref,
                    jobId: job.id,
                    reporterId: reporterId,
                    reporterRole: isJobOwner ? 'employer' : 'worker',
                    jobTitle: job.title,
                    otherPartyId: otherPartyId.isNotEmpty ? otherPartyId : null,
                  );
                },
                icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.danger),
                label: Text(
                  'Report an Issue',
                  style: GoogleFonts.spaceMono(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStepper(Payout? payout, double wage) {
    final status = payout?.status ?? 'payment_pending';
    
    final stepCompleted = true; // Job completed
    final stepVerified = true;  // Completion verified
    final stepProcessing = status == 'payout_processing' || status == 'paid';
    final stepPaid = status == 'paid';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.brandSubtle.withOpacity(0.3),
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.brand.withOpacity(0.3)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAYMENT',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '₹${wage.toStringAsFixed(0)}',
                style: GoogleFonts.spaceMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          
          _buildPaymentStepRow('Job completed', stepCompleted),
          const SizedBox(height: AppSpacing.xs),
          
          _buildPaymentStepRow('Completion verified', stepVerified),
          const SizedBox(height: AppSpacing.xs),
          
          _buildPaymentStepRow('Payment processing', stepProcessing),
          const SizedBox(height: AppSpacing.xs),
          
          _buildPaymentStepRow('Payout completed', stepPaid),
          
          if (payout != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction ID:',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
                SelectableText(
                  payout.transactionReference,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '✓ Same-day guaranteed UPI payout',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStepRow(String label, bool isDone) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
          size: 16,
          color: isDone ? AppColors.success : AppColors.inkMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? AppColors.inkPrimary : AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}


/// Loads and displays a worker's avatar from Supabase profiles.
/// Falls back to an initials circle if photo_url is absent.
class _WorkerAvatar extends ConsumerWidget {
  final String workerId;
  const _WorkerAvatar({required this.workerId});

  static final _uuidRe = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_uuidRe.hasMatch(workerId)) {
      return _fallbackAvatar('?');
    }

    final profileAsync = ref.watch(profileDetailsProvider(workerId));
    return profileAsync.when(
      data: (data) {
        final photoUrl = data['photo_url'] as String?;
        final name = data['name'] as String? ?? '?';
        if (photoUrl != null && photoUrl.isNotEmpty) {
          return ClipOval(
            child: Image.network(
              photoUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackAvatar(name),
            ),
          );
        }
        return _fallbackAvatar(name);
      },
      loading: () => _fallbackAvatar('…'),
      error: (_, __) => _fallbackAvatar('?'),
    );
  }

  Widget _fallbackAvatar(String nameOrInitial) {
    final initial = nameOrInitial.isNotEmpty
        ? nameOrInitial[0].toUpperCase()
        : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.sora(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.brand,
        ),
      ),
    );
  }
}




class _ApplicantRow extends ConsumerWidget {
  final Application app;
  final Job job;
  final UserProfile user;
  final bool isSelected;
  final bool isAssigned;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onRateWorker;
  final VoidCallback onRateEmployer;
  final VoidCallback onReportIssue;

  const _ApplicantRow({
    required this.app,
    required this.job,
    required this.user,
    required this.isSelected,
    required this.isAssigned,
    required this.onAccept,
    required this.onReject,
    required this.onRateWorker,
    required this.onRateEmployer,
    required this.onReportIssue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDetailsProvider(app.workerId));
    final liveUid = SupabaseService().client.auth.currentUser?.id;
    // Prefer the app's active profile ID. In demo mode, Supabase may still
    // have a different/anonymous session, which previously hid participant-only
    // actions such as Report an issue.
    final reporterId = (user.isLoggedIn && user.id != null && user.id!.isNotEmpty)
        ? user.id!
        : (liveUid ?? activeUserId);
    final isJobOwner = job.employerId != null && reporterId == job.employerId;
    final viewerIsThisWorker = reporterId == app.workerId;
    final isCompleted = job.status == 'completed';
    final viewerIsParticipant = isJobOwner || viewerIsThisWorker;
    final disputeAsync = (isCompleted && viewerIsParticipant && reporterId.isNotEmpty)
        ? ref.watch(myJobDisputeProvider((jobId: job.id, reporterId: reporterId)))
        : null;

    return profileAsync.when(
      data: (profileData) {
        final realName = profileData['name'] as String?;
        final workerName = realName != null && realName.isNotEmpty ? realName : app.workerName;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WorkerAvatar(workerId: app.workerId),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            workerName,
                            style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ref.watch(mutualRatingSummaryProvider(app.workerId)).when(
                          data: (summary) {
                            if (summary.totalRatings == 0) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceRaised,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  'New',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              );
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '👍',
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${summary.thumbsUpPercentage}%',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSelected && isJobOwner
                          ? '${app.workerPhone} • ${app.status.toUpperCase()}'
                          : app.status.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: isSelected ? AppColors.brand : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isAssigned && app.status != 'rejected' && isJobOwner) ...[
                    ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.pill,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.pill,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ] else if (isSelected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    if (isJobOwner)
                      GestureDetector(
                        onTap: onRateWorker,
                        child: _buildMiniRateButton('Rate Worker 👍'),
                      ),
                    if (viewerIsThisWorker && isCompleted)
                      GestureDetector(
                        onTap: onRateEmployer,
                        child: _buildMiniRateButton('Rate Employer 👍'),
                      ),
                    if (isCompleted && viewerIsParticipant) ...[
                      const SizedBox(height: 4),
                      if (disputeAsync?.valueOrNull == null)
                        GestureDetector(
                          onTap: onReportIssue,
                          child: _buildMiniIssueButton('Report an issue'),
                        )
                      else
                        _buildMiniIssueStatus(disputeAsync!.valueOrNull!.status),
                    ],
                  ],
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniIssueButton(String label) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.dangerSubtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.danger),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: AppColors.danger,
        ),
      ),
    );
  }

  Widget _buildMiniIssueStatus(String status) {
    final label = status == 'resolved' ? 'ISSUE RESOLVED' : 'ISSUE UNDER REVIEW';
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningSubtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.warning),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.warning,
        ),
      ),
    );
  }

  Widget _buildMiniRateButton(String label) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.brand),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: AppColors.brand,
        ),
      ),
    );
  }
}

class RecommendedWorkersSection extends StatefulWidget {
  final Job job;
  const RecommendedWorkersSection({super.key, required this.job});

  @override
  State<RecommendedWorkersSection> createState() => _RecommendedWorkersSectionState();
}

class _RecommendedWorkersSectionState extends State<RecommendedWorkersSection> {
  final Set<String> _invitedWorkerIds = {};
  final Set<String> _expandedWorkerIds = {};
  bool _isInviting = false;

  Future<void> _handleInvite(UserProfile worker) async {
    if (worker.id == null) return;
    setState(() {
      _isInviting = true;
    });

    try {
      final notif = NotificationService();
      await notif.insertNotification(
        userId: worker.id!,
        type: 'job_invite',
        title: 'Job Invitation ✉️',
        body: 'You have been invited to apply for "${widget.job.title}" under category "${widget.job.category}".',
        relatedJobId: widget.job.id,
      );

      setState(() {
        _invitedWorkerIds.add(worker.id!);
        _isInviting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Invitation sent to ${worker.name}!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isInviting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Failed to send invitation: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final matchesAsync = ref.watch(workerMatchesProvider(widget.job));

        return matchesAsync.when(
          data: (matches) {
            if (matches.isEmpty) {
              return const SizedBox.shrink();
            }

            final topMatches = matches.take(3).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEST MATCHES',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brand,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Column(
                  children: topMatches.map((match) {
                    final isInvited = _invitedWorkerIds.contains(match.worker.id);
                    final isExpanded = _expandedWorkerIds.contains(match.worker.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
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
                            children: [
                              _WorkerAvatar(workerId: match.worker.id ?? ''),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      match.worker.name,
                                      style: GoogleFonts.sora(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.inkPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          'Match Score: ${(match.score * 100).toStringAsFixed(0)}%',
                                          style: GoogleFonts.spaceMono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brand,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${(match.estimatedDistanceKm ?? 0.0).toStringAsFixed(1)} km away',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: AppColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _MatchedBadge(label: widget.job.category, matched: match.explanation.componentScores['skills'] != 0.0),
                              _MatchedBadge(label: 'Available today', matched: match.explanation.componentScores['availability'] != 0.0),
                              _MatchedBadge(label: 'Wage compatible', matched: match.explanation.componentScores['wage'] != 0.0),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedWorkerIds.remove(match.worker.id);
                                } else {
                                  _expandedWorkerIds.add(match.worker.id!);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    isExpanded ? 'Hide Match Details' : 'Show Match Details',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                  Icon(
                                    isExpanded ? Icons.expand_less : Icons.expand_more,
                                    size: 16,
                                    color: AppColors.brand,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceRaised,
                                borderRadius: AppRadii.control,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SCORE BREAKDOWN',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...match.explanation.positives.map((pos) => Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_rounded, color: Colors.green, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              pos,
                                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkPrimary),
                                            ),
                                          ],
                                        ),
                                      )),
                                  ...match.explanation.negatives.map((neg) => Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.close_rounded, color: Colors.red, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              neg,
                                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Container(
                                      decoration: const BoxDecoration(
                                        color: AppColors.canvas,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Worker Profile Details',
                                            style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: AppSpacing.md),
                                          ProviderCard(
                                            name: match.worker.name,
                                            photoUrl: match.worker.photoUrl,
                                            primarySkill: match.worker.skills.isNotEmpty ? match.worker.skills.first : 'Worker',
                                            skills: match.worker.skills,
                                            dailyRate: match.worker.dailyRate,
                                            rating: 4.8,
                                            jobsCompleted: 10,
                                            phone: match.worker.phone,
                                            isVerified: true,
                                            rateeId: match.worker.id,
                                          ),
                                          const SizedBox(height: AppSpacing.md),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.brand,
                                              minimumSize: const Size(double.infinity, 44),
                                            ),
                                            child: Text('Close', style: GoogleFonts.spaceMono(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: Text(
                                  'VIEW PROFILE',
                                  style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.inkPrimary),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              ElevatedButton(
                                onPressed: (isInvited || _isInviting) ? null : () => _handleInvite(match.worker),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInvited ? Colors.grey : AppColors.brand,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: Text(
                                  isInvited ? 'INVITED' : 'INVITE TO JOB',
                                  style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        );
      },
    );
  }
}


class _MatchedBadge extends StatelessWidget {

  final String label;
  final bool matched;
  const _MatchedBadge({required this.label, required this.matched});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: matched ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: AppRadii.control,
        border: Border.all(
          color: matched ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            matched ? Icons.check_rounded : Icons.close_rounded,
            size: 11,
            color: matched ? const Color(0xFF059669) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: matched ? const Color(0xFF047857) : const Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
    );
  }
}

