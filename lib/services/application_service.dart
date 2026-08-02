import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application.dart';
import 'supabase_service.dart';

class ApplicationService {
  final SupabaseClient _client = SupabaseService().client;

  /// Creates a new application row in Supabase applications table
  Future<Application?> applyToJob({
    required String jobId,
    required String workerId,
    required String workerName,
    required String workerPhone,
  }) async {
    try {
      final payload = {
        'job_id': jobId,
        'worker_id': workerId,
        'worker_name': workerName,
        'worker_phone': workerPhone,
        'status': 'interested',
        'created_at': DateTime.now().toIso8601String(),
      };

      final res =
          await _client.from('applications').insert(payload).select().single();
      if (kDebugMode) {
        print('✅ [ApplicationService] Applied to job $jobId as worker $workerId');
      }
      return Application.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ApplicationService] Error applying to job: $e');
      }
      return null;
    }
  }

  /// Fetches all applications for a specific job (Employer view)
  Future<List<Application>> fetchApplicationsForJob(String jobId) async {
    try {
      final res = await _client
          .from('applications')
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);
      final List data = res as List;
      return data.map((json) => Application.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ApplicationService] Error fetching applications for job ($jobId): $e');
      }
      return [];
    }
  }

  /// Fetches all applications submitted by a specific worker (Worker view)
  Future<List<Application>> fetchApplicationsForWorker(String workerId) async {
    try {
      final res = await _client
          .from('applications')
          .select()
          .eq('worker_id', workerId)
          .order('created_at', ascending: false);
      final List data = res as List;
      return data.map((json) => Application.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ApplicationService] Error fetching applications for worker ($workerId): $e');
      }
      return [];
    }
  }

  /// Updates status of an application ('assigned' / 'rejected'), and if assigned,
  /// updates parent job status to 'assigned' and worker_name to workerName.
  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String jobId,
    required String workerName,
    required String status,
  }) async {
    try {
      // 1. Update application status
      await _client
          .from('applications')
          .update({'status': status})
          .eq('id', applicationId);

      // 2. If status is 'assigned', also update parent job status and worker_name
      if (status == 'assigned') {
        await _client.from('jobs').update({
          'status': 'assigned',
          'worker_name': workerName,
        }).eq('id', jobId);

        // Reject other applications for the same job
        await _client
            .from('applications')
            .update({'status': 'rejected'})
            .eq('job_id', jobId)
            .neq('id', applicationId);
      }

      if (kDebugMode) {
        print('✅ [ApplicationService] Updated application $applicationId status to $status');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ApplicationService] Error updating application status: $e');
      }
      return false;
    }
  }
}
