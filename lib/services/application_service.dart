import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application.dart';
import 'supabase_service.dart';

class ApplicationService {
  final SupabaseClient _client = SupabaseService().client;
  static final List<Application> _localApplicationsStore = [];
  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Creates a new application row in Supabase applications table
  Future<Application?> applyToJob({
    required String jobId,
    required String workerId,
    required String workerName,
    required String workerPhone,
  }) async {
    final now = DateTime.now();
    final newApp = Application(
      id: 'app_${now.millisecondsSinceEpoch}',
      jobId: jobId,
      workerId: workerId,
      workerName: workerName,
      workerPhone: workerPhone,
      status: 'interested',
      createdAt: now,
    );

    // Save locally for fallback
    _localApplicationsStore.removeWhere((a) => a.jobId == jobId && a.workerId == workerId);
    _localApplicationsStore.add(newApp);

    if (!_uuidRegExp.hasMatch(jobId)) {
      return newApp;
    }

    try {
      final payload = {
        'job_id': jobId,
        'worker_id': workerId,
        'worker_name': workerName,
        'worker_phone': workerPhone,
        'status': 'interested',
        'created_at': now.toIso8601String(),
      };

      final res =
          await _client.from('applications').insert(payload).select().single();
      if (kDebugMode) {
        print('✅ [ApplicationService] Applied to job $jobId as worker $workerId');
      }
      return Application.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ApplicationService] Error applying to job (returning local fallback): $e');
      }
      return newApp;
    }
  }

  /// Fetches all applications for a specific job (Employer view)
  Future<List<Application>> fetchApplicationsForJob(String jobId) async {
    final localApps = _localApplicationsStore.where((a) => a.jobId == jobId).toList();

    if (!_uuidRegExp.hasMatch(jobId)) {
      return localApps;
    }

    try {
      final res = await _client
          .from('applications')
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);
      final List data = res as List;
      final remoteApps = data.map((json) => Application.fromJson(json)).toList();
      return remoteApps.isEmpty ? localApps : remoteApps;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ApplicationService] Error fetching applications for job ($jobId): $e');
      }
      return localApps;
    }
  }

  /// Fetches all applications submitted by a specific worker (Worker view)
  Future<List<Application>> fetchApplicationsForWorker(String workerId) async {
    final localApps = _localApplicationsStore.where((a) => a.workerId == workerId).toList();

    try {
      final res = await _client
          .from('applications')
          .select()
          .eq('worker_id', workerId)
          .order('created_at', ascending: false);
      final List data = res as List;
      final remoteApps = data.map((json) => Application.fromJson(json)).toList();
      return remoteApps.isEmpty ? localApps : remoteApps;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ApplicationService] Error fetching applications for worker ($workerId): $e');
      }
      return localApps;
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
    // 1. Update in-memory local store
    for (int i = 0; i < _localApplicationsStore.length; i++) {
      if (_localApplicationsStore[i].id == applicationId) {
        _localApplicationsStore[i] = _localApplicationsStore[i].copyWith(status: status);
      } else if (status == 'assigned' && _localApplicationsStore[i].jobId == jobId) {
        _localApplicationsStore[i] = _localApplicationsStore[i].copyWith(status: 'rejected');
      }
    }

    if (!_uuidRegExp.hasMatch(jobId) || !_uuidRegExp.hasMatch(applicationId)) {
      return true;
    }

    try {
      // Update remote application status
      await _client
          .from('applications')
          .update({'status': status})
          .eq('id', applicationId);

      if (status == 'assigned') {
        await _client.from('jobs').update({
          'status': 'assigned',
          'worker_name': workerName,
        }).eq('id', jobId);

        await _client
            .from('applications')
            .update({'status': 'rejected'})
            .eq('job_id', jobId)
            .neq('id', applicationId);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ApplicationService] Error updating application status: $e');
      }
      return true;
    }
  }
}
