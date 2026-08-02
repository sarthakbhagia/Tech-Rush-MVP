import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import 'supabase_service.dart';

class JobService {
  final SupabaseClient _client = SupabaseService().client;
  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Creates a new job in Supabase jobs table
  Future<Job?> createJob(Job job) async {
    try {
      final user = _client.auth.currentUser;
      final payload = job.toJson();
      if (user != null) {
        payload['employer_id'] = user.id;
      }

      final res = await _client.from('jobs').insert(payload).select().single();
      if (kDebugMode) {
        print('✅ [JobService] Created job: ${res['id']}');
      }
      return Job.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [JobService] Error creating job: $e');
      }
      return null;
    }
  }

  /// Fetches jobs from Supabase filtered by category ('All' fetches all)
  Future<List<Job>> fetchJobsByCategory(String category) async {
    try {
      var query = _client.from('jobs').select();
      if (category != 'All' && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final res = await query.order('created_at', ascending: false);
      final List data = res as List;
      final jobs = data.map((json) => Job.fromJson(json)).toList();

      if (jobs.isEmpty) {
        // Fallback to filtered mockJobs if database has no rows yet
        if (category == 'All' || category.isEmpty) {
          return mockJobs;
        }
        return mockJobs.where((j) => j.category.toLowerCase() == category.toLowerCase()).toList();
      }
      return jobs;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [JobService] Error fetching jobs by category ($category): $e');
      }
      // Return mockJobs fallback on connection error
      if (category == 'All' || category.isEmpty) {
        return mockJobs;
      }
      return mockJobs.where((j) => j.category.toLowerCase() == category.toLowerCase()).toList();
    }
  }

  /// Fetches jobs posted by a specific employer
  Future<List<Job>> fetchJobsByEmployer(String employerId) async {
    try {
      if (!_uuidRegExp.hasMatch(employerId)) {
        return mockJobs;
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
      return mockJobs;
    }
  }

  /// Fetches single job details by ID
  Future<Job?> fetchJobById(String jobId) async {
    // 1. If jobId is not a valid UUID (e.g. 'job-1', 'job-2'), return matching mockJob
    if (!_uuidRegExp.hasMatch(jobId)) {
      try {
        return mockJobs.firstWhere((j) => j.id == jobId);
      } catch (_) {
        return mockJobs.first;
      }
    }

    try {
      final res =
          await _client.from('jobs').select().eq('id', jobId).maybeSingle();
      if (res == null) {
        return mockJobs.firstWhere((j) => j.id == jobId, orElse: () => mockJobs.first);
      }
      return Job.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [JobService] Error fetching job ($jobId): $e');
      }
      return mockJobs.firstWhere((j) => j.id == jobId, orElse: () => mockJobs.first);
    }
  }
}
