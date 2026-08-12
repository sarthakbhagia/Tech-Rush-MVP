import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../services/worker_match_service.dart';
import 'job_provider.dart';

final workerMatchServiceProvider = Provider<WorkerMatchService>((ref) {
  return WorkerMatchService();
});

final workerMatchesProvider = FutureProvider.family<List<WorkerMatch>, Job>((ref, job) async {
  final matchService = ref.watch(workerMatchServiceProvider);
  return matchService.getMatchesForJob(job);
});
