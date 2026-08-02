import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../models/application.dart';
import '../services/job_service.dart';
import '../services/application_service.dart';

final jobServiceProvider = Provider<JobService>((ref) => JobService());
final applicationServiceProvider = Provider<ApplicationService>((ref) => ApplicationService());

/// Provider to fetch jobs by category (with fallback mock jobs if database is empty)
final jobsByCategoryProvider =
    FutureProvider.family<List<Job>, String>((ref, category) async {
  final jobService = ref.watch(jobServiceProvider);
  final fetched = await jobService.fetchJobsByCategory(category);
  if (fetched.isNotEmpty) {
    return fetched;
  }
  // Fallback to local mock data if remote table has 0 rows
  if (category == 'All' || category.isEmpty) {
    return mockJobs;
  }
  return mockJobs
      .where((j) => j.category.toLowerCase() == category.toLowerCase())
      .toList();
});

/// Provider for single job detail by ID
final jobDetailProvider =
    FutureProvider.family<Job?, String>((ref, jobId) async {
  final jobService = ref.watch(jobServiceProvider);
  final job = await jobService.fetchJobById(jobId);
  if (job != null) {
    return job;
  }
  // Fallback match in mockJobs
  try {
    return mockJobs.firstWhere((j) => j.id == jobId);
  } catch (_) {
    return mockJobs.first;
  }
});

/// Provider for employer to view applications submitted for a job
final jobApplicationsProvider =
    FutureProvider.family<List<Application>, String>((ref, jobId) async {
  final appService = ref.watch(applicationServiceProvider);
  return await appService.fetchApplicationsForJob(jobId);
});

/// Provider for worker to view their own application history
final workerApplicationsProvider =
    FutureProvider.family<List<Application>, String>((ref, workerId) async {
  final appService = ref.watch(applicationServiceProvider);
  return await appService.fetchApplicationsForWorker(workerId);
});
