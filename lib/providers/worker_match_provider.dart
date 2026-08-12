import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../services/worker_match_service.dart';

final workerMatchServiceProvider = Provider<WorkerMatchService>((ref) {
  return WorkerMatchService();
});

/// Statuses that mean a job is no longer looking for a worker.
/// Smart Matching results are suppressed for all of these.
const _nonMatchingStatuses = {
  'assigned',
  'on_the_way',
  'arrived',
  'working',
  'proof_submitted',
  'completed',
  'cancelled',
  'disputed',
};

final workerMatchesProvider = FutureProvider.family<List<WorkerMatch>, Job>((ref, job) async {
  // Do NOT run matching for jobs that already have a worker or are closed.
  if (_nonMatchingStatuses.contains(job.status)) {
    return const [];
  }
  final matchService = ref.watch(workerMatchServiceProvider);
  return matchService.getMatchesForJob(job);
});
