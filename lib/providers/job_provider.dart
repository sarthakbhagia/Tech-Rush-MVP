import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../models/application.dart';
import '../services/job_service.dart';
import '../services/application_service.dart';

final jobServiceProvider = Provider<JobService>((ref) => JobService());
final applicationServiceProvider = Provider<ApplicationService>((ref) => ApplicationService());

/// Parameter object for parameterized job queries in Riverpod
class JobQueryParams {
  final String category;
  final String status;
  final double minPrice;
  final double maxPrice;
  final String searchQuery;
  final String sortBy;

  const JobQueryParams({
    this.category = 'All',
    this.status = 'ALL',
    this.minPrice = 0.0,
    this.maxPrice = 10000.0,
    this.searchQuery = '',
    this.sortBy = 'most_recent',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobQueryParams &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          status == other.status &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice &&
          searchQuery == other.searchQuery &&
          sortBy == other.sortBy;

  @override
  int get hashCode =>
      category.hashCode ^
      status.hashCode ^
      minPrice.hashCode ^
      maxPrice.hashCode ^
      searchQuery.hashCode ^
      sortBy.hashCode;
}

/// Provider to fetch filtered jobs from Supabase using JobQueryParams
final filteredJobsProvider =
    FutureProvider.family<List<Job>, JobQueryParams>((ref, params) async {
  final jobService = ref.watch(jobServiceProvider);
  return await jobService.fetchJobs(
    category: params.category,
    status: params.status,
    minPrice: params.minPrice,
    maxPrice: params.maxPrice,
    searchQuery: params.searchQuery,
    sortBy: params.sortBy,
  );
});

/// Provider for searching jobs in Supabase with ilike matching
final searchJobsProvider =
    FutureProvider.family<List<Job>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final jobService = ref.watch(jobServiceProvider);
  return await jobService.searchJobs(query.trim());
});

/// Provider to fetch jobs by category (from Supabase)
final jobsByCategoryProvider =
    FutureProvider.family<List<Job>, String>((ref, category) async {
  final jobService = ref.watch(jobServiceProvider);
  return await jobService.fetchJobsByCategory(category);
});

/// Provider for single job detail by ID from Supabase
final jobDetailProvider =
    FutureProvider.family<Job?, String>((ref, jobId) async {
  final jobService = ref.watch(jobServiceProvider);
  return await jobService.fetchJobById(jobId);
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

/// Provider to fetch jobs posted by a specific employer from Supabase
final jobsByEmployerProvider =
    FutureProvider.family<List<Job>, String>((ref, employerId) async {
  final jobService = ref.watch(jobServiceProvider);
  return await jobService.fetchJobsByEmployer(employerId);
});
