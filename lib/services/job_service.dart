import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import 'supabase_service.dart';

class JobService {
  final SupabaseClient _client = SupabaseService().client;
  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Creates a new job in Supabase jobs table.
  /// Throws a [PostgrestException] or generic Exception on failure so the
  /// caller can surface the real error message instead of hiding it.
  Future<Job> createJob(Job job) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not authenticated — Supabase currentUser is null. Please sign in again.');
    }

    // Build minimal insert payload using only confirmed DB columns.
    // Do NOT rely on job.toJson() which includes client-side-only fields.
    final payload = <String, dynamic>{
      'employer_id': user.id, // always use live auth.uid()
      'title': job.title,
      'category': job.category,
      'description': job.description.isNotEmpty ? job.description : '.',
      'price': job.wage,
      'status': 'open',
      'location': job.location,
      'employer_name': job.employerName.isNotEmpty ? job.employerName : 'Employer',
      'urgent': job.urgent,
      if (job.originalWage != null) 'original_price': job.originalWage,
      if (job.imageUrl != null) 'image_url': job.imageUrl,
      if (job.workerName != null) 'worker_name': job.workerName,
    };

    if (kDebugMode) {
      print('🔄 [JobService] createJob payload: $payload');
      print('   auth.uid(): ${user.id}');
    }

    // Will throw PostgrestException on any DB/RLS error.
    final res = await _client.from('jobs').insert(payload).select().single();

    if (kDebugMode) {
      print('✅ [JobService] Created job: ${res['id']}');
    }
    return Job.fromJson(res);
  }

  /// Main multi-criteria query runner for Supabase `jobs` table
  Future<List<Job>> fetchJobs({
    String category = 'All',
    String status = 'ALL',
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    String? sortBy,
  }) async {
    try {
      var query = _client.from('jobs').select();

      // 1. Category Filter
      if (category != 'All' && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // 2. Status Filter ('open', 'assigned', 'completed')
      if (status != 'ALL' && status.isNotEmpty) {
        query = query.eq('status', status.toLowerCase());
      }

      // 3. Price Filter Range
      if (minPrice != null && minPrice > 0) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null && maxPrice < 10000) {
        query = query.lte('price', maxPrice);
      }

      // 4. Search Query Filter (ilike on title, category, location, description)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('title.ilike.%$q%,category.ilike.%$q%,location.ilike.%$q%,description.ilike.%$q%');
      }

      // 5. Sort Ordering
      var orderColumn = 'created_at';
      var ascending = false;

      if (sortBy == 'price_low') {
        orderColumn = 'price';
        ascending = true;
      } else if (sortBy == 'price_high') {
        orderColumn = 'price';
        ascending = false;
      } else if (sortBy == 'rating') {
        orderColumn = 'rating';
        ascending = false;
      }

      final res = await query.order(orderColumn, ascending: ascending);
      final List data = res as List;
      final jobs = data.map((json) => Job.fromJson(json)).toList();
      return jobs;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [JobService] Error fetching jobs: $e');
      }
      return [];
    }
  }

  /// Legacy helper for category fetching
  Future<List<Job>> fetchJobsByCategory(String category) async {
    return fetchJobs(category: category);
  }

  /// Search jobs in Supabase with ilike matching
  Future<List<Job>> searchJobs(String searchQuery) async {
    return fetchJobs(searchQuery: searchQuery);
  }

  /// Fetches jobs posted by a specific employer
  Future<List<Job>> fetchJobsByEmployer(String employerId) async {
    try {
      if (!_uuidRegExp.hasMatch(employerId)) {
        return [];
      }

      final res = await _client
          .from('jobs')
          .select()
          .eq('employer_id', employerId)
          .order('created_at', ascending: false);
      final List data = res as List;
      return data.map((json) => Job.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [JobService] Error fetching jobs for employer ($employerId): $e');
      }
      return [];
    }
  }

  /// Fetches single job details by ID from Supabase
  Future<Job?> fetchJobById(String jobId) async {
    if (!_uuidRegExp.hasMatch(jobId)) {
      try {
        return mockJobs.firstWhere((j) => j.id == jobId);
      } catch (_) {
        return null;
      }
    }

    try {
      final res =
          await _client.from('jobs').select().eq('id', jobId).maybeSingle();
      if (res == null) return null;
      return Job.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [JobService] Error fetching job ($jobId): $e');
      }
      return null;
    }
  }

  /// Updates status of a job ('open', 'assigned', 'completed') in Supabase
  Future<bool> updateJobStatus({
    required String jobId,
    required String status,
    String? workerName,
  }) async {
    if (!_uuidRegExp.hasMatch(jobId)) {
      return true;
    }

    try {
      final payload = <String, dynamic>{'status': status};
      if (workerName != null && workerName.isNotEmpty) {
        payload['worker_name'] = workerName;
      }

      await _client.from('jobs').update(payload).eq('id', jobId);
      if (kDebugMode) {
        print('✅ [JobService] Updated job $jobId status to $status');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [JobService] Error updating job status ($jobId): $e');
      }
      return false;
    }
  }
}
