import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/spacing.dart';
import '../../models/payout.dart';
import '../../providers/payout_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/job_provider.dart';

class PayoutHistoryScreen extends ConsumerWidget {
  const PayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final resolvedWorkerId = (userProfile.id != null && userProfile.id!.isNotEmpty)
        ? userProfile.id!
        : 'f0000000-0000-0000-0000-000000000001';

    final payoutsAsync = ref.watch(userPayoutsProvider(UserPayoutsParams(
      userId: resolvedWorkerId,
      role: 'worker',
    )));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Earnings & Payouts',
          style: GoogleFonts.spaceMono(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.inkPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.inkPrimary),
          onPressed: () => context.pop(),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Demo Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            color: AppColors.brandSubtle.withOpacity(0.4),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.brand),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'DEMO MODE: These transactions are simulations for demonstration purposes only. No real banking details are used.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.brand,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: payoutsAsync.when(
              data: (payouts) {
                // If there are no payouts, show standard default demonstration payouts
                final displayPayouts = payouts.isEmpty
                    ? [
                        Payout(
                          id: 'demo-payout-1',
                          jobId: 'demo-job-1',
                          workerId: resolvedWorkerId,
                          employerId: 'demo-employer',
                          amount: 1300.0,
                          status: 'paid',
                          transactionReference: 'KS-DEMO-98210',
                          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
                          processedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 55)),
                        ),
                        Payout(
                          id: 'demo-payout-2',
                          jobId: 'demo-job-2',
                          workerId: resolvedWorkerId,
                          employerId: 'demo-employer',
                          amount: 556.0,
                          status: 'payout_processing',
                          transactionReference: 'KS-DEMO-47312',
                          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
                        ),
                      ]
                    : payouts;

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: displayPayouts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final payout = displayPayouts[index];
                    return _PayoutListTile(payout: payout);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
              error: (err, stack) => Center(
                child: Text('Error loading payouts: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutListTile extends ConsumerWidget {
  final Payout payout;
  const _PayoutListTile({required this.payout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve job detail dynamically if it's a real job, else fallback
    final isMockDemo = payout.id.startsWith('demo-payout');
    final jobAsync = isMockDemo
        ? const AsyncValue.data(null)
        : ref.watch(jobDetailProvider(payout.jobId));

    final String jobTitle = isMockDemo
        ? (payout.id == 'demo-payout-1'
            ? 'Living Room Wall Painting'
            : 'Water Leak Repair & Plumbing')
        : (jobAsync.asData?.value?.title ?? 'Daily Wage Task');

    final String dateString = DateFormat('dd MMM yyyy, hh:mm a').format(payout.createdAt);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (payout.status) {
      case 'paid':
        statusColor = AppColors.success;
        statusText = 'PAID';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'payout_processing':
        statusColor = Colors.orange.shade700;
        statusText = 'PROCESSING';
        statusIcon = Icons.access_time_filled_rounded;
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusText = 'PENDING';
        statusIcon = Icons.radio_button_unchecked_rounded;
        break;
    }

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateString,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '₹${payout.amount.toStringAsFixed(0)}',
                style: GoogleFonts.spaceMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Ref: ${payout.transactionReference}',
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  Text(
                    'DEMO TXN',
                    style: GoogleFonts.spaceMono(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
