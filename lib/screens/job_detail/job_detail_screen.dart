import 'package:flutter/material.dart';
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

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, this.jobId = 'job-1'});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isApplying = false;

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
    final resolvedId =
        liveUser?.id ??
        (user.id?.isNotEmpty == true ? user.id! : null) ??
        (user.phone.isNotEmpty ? user.phone : 'worker_${user.name}');

    try {
      final app = await ref
          .read(applicationServiceProvider)
          .applyToJob(
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
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.inkPrimary,
          ),
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
          child: Container(color: AppColors.border, height: 1.0),
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
                  description:
                      'The requested job posting could not be found or has been un-published.',
                ),
              ),
            );
          }

          final isAssigned = job.status == 'assigned';
          final isCompleted = job.status == 'completed';
          final currentStep = isCompleted
              ? JobStepStatus.completed
              : (isAssigned ? JobStepStatus.assigned : JobStepStatus.posted);

          final asyncApps = ref.watch(jobApplicationsProvider(job.id));
          final applications = asyncApps.asData?.value ?? [];
          final liveUid = SupabaseService().client.auth.currentUser?.id;
          final viewerId = liveUid ?? user.id;
          // Applicant management is a property of this job, not the account's
          // selected role. A user must be the employer recorded on this job.
          final viewerOwnsJob = viewerId != null && viewerId == job.employerId;
          // RLS already returns only relevant applications. Keep the UI safe if
          // a stale/local response is broader than it should be.
          final visibleApplications = viewerOwnsJob
              ? applications
              : applications.where((app) => app.workerId == viewerId).toList();
          final employerProfileAsync =
              job.employerId != null && job.employerId!.isNotEmpty
              ? ref.watch(profileDetailsProvider(job.employerId!))
              : null;
          final employerPhotoUrl =
              employerProfileAsync?.valueOrNull?['photo_url'] as String?;

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

                // Employers see applicants on their own jobs. Workers see only
                // their own read-only application status.
                Text(
                  viewerOwnsJob
                      ? '${l10n.jobDetailApplicantBids} (${visibleApplications.length})'
                      : 'YOUR APPLICATION',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                if (visibleApplications.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.card,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      l10n.jobDetailNoApps,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  )
                else
                  Column(
                    children: visibleApplications.map((app) {
                      final isSelected = app.status == 'assigned';
                      final liveUid =
                          SupabaseService().client.auth.currentUser?.id;

                      return _ApplicantRow(
                        app: app,
                        job: job,
                        user: user,
                        isSelected: isSelected,
                        isAssigned: isAssigned,
                        canManageApplication: viewerOwnsJob,
                        onAccept: () => _handleAcceptApplication(app, job),
                        onReject: () => _handleRejectApplication(app, job),
                        onRateWorker: () async {
                          if (!isCompleted) {
                            await ref
                                .read(jobServiceProvider)
                                .updateJobStatus(
                                  jobId: job.id,
                                  status: 'completed',
                                );
                            ref.invalidate(jobDetailProvider(job.id));
                            ref.invalidate(jobsByCategoryProvider);
                            ref.invalidate(filteredJobsProvider);
                          }
                          if (mounted) {
                            openThumbsRatingBottomSheet(
                              context,
                              ref,
                              jobId: job.id,
                              evaluatorId: liveUid ?? user.id ?? '',
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
                            evaluatorId: liveUid ?? user.id ?? '',
                            targetId: job.employerId ?? '',
                            targetName: job.employerName,
                            raterRole: 'worker',
                            employerId: job.employerId ?? '',
                            workerId: app.workerId,
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
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
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
          final hasApplied = applications.any(
            (a) => a.workerId == bottomWorkerId,
          );
          final isAssigned = job.status == 'assigned';
          final isCompleted = job.status == 'completed';

          final liveUid = SupabaseService().client.auth.currentUser?.id;
          final loggedInEmployer = user.isLoggedIn && user.role == 'employer';
          final isOwner =
              (liveUid != null && liveUid == job.employerId) ||
              (user.id != null && user.id == job.employerId);

          if (loggedInEmployer) {
            if (isOwner) {
              if (isAssigned) {
                return StickyBottomBar(
                  label: 'STATUS: ASSIGNED',
                  price: job.wage,
                  ctaLabel: 'Mark Job as Completed',
                  isLoading: false,
                  disabled: false,
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  onCta: () async {
                    final success = await ref
                        .read(jobServiceProvider)
                        .updateJobStatus(jobId: job.id, status: 'completed');
                    if (success) {
                      ref.invalidate(jobDetailProvider(job.id));
                      ref.invalidate(jobsByCategoryProvider);
                      ref.invalidate(filteredJobsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.brand,
                            content: Text(
                              'Job marked as completed!',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                );
              } else if (isCompleted) {
                return StickyBottomBar(
                  label: 'STATUS: COMPLETED',
                  price: job.wage,
                  ctaLabel: 'Job Completed',
                  isLoading: false,
                  disabled: true,
                  icon: const Icon(
                    Icons.done_all_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  onCta: () {},
                );
              } else {
                return StickyBottomBar(
                  label: 'STATUS: OPEN',
                  price: job.wage,
                  ctaLabel: 'Awaiting Applicants...',
                  isLoading: false,
                  disabled: true,
                  icon: const Icon(
                    Icons.people_outline_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  onCta: () {},
                );
              }
            } else {
              // Viewing someone else's job as an employer
              return StickyBottomBar(
                label: 'DAILY RATE',
                price: job.wage,
                ctaLabel: 'Employer Mode',
                isLoading: false,
                disabled: true,
                icon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                onCta: () {},
              );
            }
          }

          if (isCompleted) {
            return StickyBottomBar(
              label: 'STATUS: COMPLETED',
              price: job.wage,
              ctaLabel: 'Job Completed',
              isLoading: false,
              disabled: true,
              icon: const Icon(
                Icons.done_all_rounded,
                size: 16,
                color: Colors.white,
              ),
              onCta: () {},
            );
          }

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
                ? const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.work_outline_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
            onCta: () => _handleExpressInterest(job),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildDetailCategoryFallback(String category) {
    final catObj = AppCategories.findById(category);
    final icon = catObj?.icon ?? Icons.work_outline_rounded;
    final prefix = category.length >= 3
        ? category.substring(0, 3).toUpperCase()
        : category.toUpperCase();

    return Container(
      color: AppColors.surfaceRaised,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.brand),
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
}

/// Loads and displays a worker's avatar from Supabase profiles.
/// Falls back to an initials circle if photo_url is absent.
class _WorkerAvatar extends ConsumerWidget {
  final String workerId;
  const _WorkerAvatar({required this.workerId});

  static final _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

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

class _ApplicantRow extends ConsumerWidget {
  final Application app;
  final Job job;
  final UserProfile user;
  final bool isSelected;
  final bool isAssigned;
  final bool canManageApplication;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onRateWorker;
  final VoidCallback onRateEmployer;

  const _ApplicantRow({
    required this.app,
    required this.job,
    required this.user,
    required this.isSelected,
    required this.isAssigned,
    required this.canManageApplication,
    required this.onAccept,
    required this.onReject,
    required this.onRateWorker,
    required this.onRateEmployer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDetailsProvider(app.workerId));
    final liveUid = SupabaseService().client.auth.currentUser?.id;
    final viewerIsEmployer = canManageApplication;
    final viewerIsThisWorker =
        liveUid == app.workerId || user.id == app.workerId;
    final isCompleted = job.status == 'completed';

    return profileAsync.when(
      data: (profileData) {
        final realName = profileData['name'] as String?;
        final workerName = realName != null && realName.isNotEmpty
            ? realName
            : app.workerName;

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
                        ref
                            .watch(mutualRatingSummaryProvider(app.workerId))
                            .when(
                              data: (summary) {
                                if (summary.totalRatings == 0) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceRaised,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFA7F3D0),
                                    ),
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
                      isSelected && viewerIsEmployer
                          ? '${app.workerPhone} • ${app.status.toUpperCase()}'
                          : app.status.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: isSelected
                            ? AppColors.brand
                            : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isAssigned &&
                      app.status != 'rejected' &&
                      canManageApplication) ...[
                    ElevatedButton(
                      onPressed: onAccept,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                    if (viewerIsEmployer)
                      GestureDetector(
                        onTap: onRateWorker,
                        child: _buildMiniRateButton('Rate Worker 👍'),
                      ),
                    if (viewerIsThisWorker && isCompleted)
                      GestureDetector(
                        onTap: onRateEmployer,
                        child: _buildMiniRateButton('Rate Employer 👍'),
                      ),
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
