import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class ApplicationService {
  final SupabaseClient _client = SupabaseService().client;
  final NotificationService _notif = NotificationService();

  static final List<Application> _localApplicationsStore = [];
  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  // ── Helper ───────────────────────────────────────────────────────────────

  /// Looks up a job row and returns the employer_id (for notification routing).
  Future<String?> _fetchEmployerIdForJob(String jobId) async {
    if (!_uuidRegExp.hasMatch(jobId)) return null;
    try {
      final res = await _client
          .from('jobs')
          .select('employer_id, title, employer_name')
          .eq('id', jobId)
          .maybeSingle();
      return res?['employer_id']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Looks up a job row and returns both employer_id and worker_id (via applications).
  Future<Map<String, String?>> _fetchJobContext(String jobId) async {
    if (!_uuidRegExp.hasMatch(jobId)) return {};
    try {
      final res = await _client
          .from('jobs')
          .select('employer_id, title, worker_name')
          .eq('id', jobId)
          .maybeSingle();
      if (res == null) return {};
      return {
        'employer_id': res['employer_id']?.toString(),
        'job_title': res['title']?.toString() ?? 'Job',
        'worker_name': res['worker_name']?.toString(),
      };
    } catch (_) {
      return {};
    }
  }

  // ── Apply ────────────────────────────────────────────────────────────────

  /// Creates a new application row in Supabase applications table.
  /// On success → inserts an `application_received` notification for the employer.
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
    _localApplicationsStore.removeWhere(
        (a) => a.jobId == jobId && a.workerId == workerId);
    _localApplicationsStore.add(newApp);

    if (!_uuidRegExp.hasMatch(jobId)) {
      return newApp;
    }

    try {
      final user = _client.auth.currentUser;
      final effectiveWorkerId =
          (user != null && _uuidRegExp.hasMatch(user.id)) ? user.id : workerId;

      final payload = {
        'job_id': jobId,
        'worker_id': effectiveWorkerId,
        'worker_name': workerName,
        'worker_phone': workerPhone,
        'status': 'interested',
        'created_at': now.toIso8601String(),
      };

      final res =
          await _client.from('applications').insert(payload).select().single();
      if (kDebugMode) {
        print(
            '✅ [ApplicationService] Applied to job $jobId as worker $effectiveWorkerId');
      }

      final application = Application.fromJson(res);

      // ── Notify employer ──────────────────────────────────────────────────
      final employerId = await _fetchEmployerIdForJob(jobId);
      if (employerId != null) {
        unawaited(_notif.insertNotification(
          userId: employerId,
          type: 'application_received',
          title: 'New Application Received',
          body: '$workerName applied for your job.',
          relatedJobId: jobId,
        ));
      }

      return application;
    } catch (e) {
      if (kDebugMode) {
        print(
            '⚠️ [ApplicationService] Error applying to job (returning local fallback): $e');
      }
      return newApp;
    }
  }

  // ── Fetch ────────────────────────────────────────────────────────────────

  /// Fetches all applications for a specific job (Employer view).
  Future<List<Application>> fetchApplicationsForJob(String jobId) async {
    final localApps =
        _localApplicationsStore.where((a) => a.jobId == jobId).toList();

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
      final remoteApps =
          data.map((json) => Application.fromJson(json)).toList();
      return remoteApps.isEmpty ? localApps : remoteApps;
    } catch (e) {
      if (kDebugMode) {
        print(
            '⚠️ [ApplicationService] Error fetching applications for job ($jobId): $e');
      }
      return localApps;
    }
  }

  /// Fetches all applications submitted by a specific worker (Worker view).
  Future<List<Application>> fetchApplicationsForWorker(String workerId) async {
    final localApps =
        _localApplicationsStore.where((a) => a.workerId == workerId).toList();

    try {
      final res = await _client
          .from('applications')
          .select()
          .eq('worker_id', workerId)
          .order('created_at', ascending: false);
      final List data = res as List;
      final remoteApps =
          data.map((json) => Application.fromJson(json)).toList();
      return remoteApps.isEmpty ? localApps : remoteApps;
    } catch (e) {
      if (kDebugMode) {
        print(
            '⚠️ [ApplicationService] Error fetching applications for worker ($workerId): $e');
      }
      return localApps;
    }
  }

  // ── Update Status ────────────────────────────────────────────────────────

  /// Updates status of an application ('assigned' / 'rejected').
  /// If assigned → also updates job status, rejects other applicants,
  /// and inserts a `job_accepted` notification for the worker.
  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String jobId,
    required String workerName,
    required String workerId,
    required String status,
  }) async {
    // 1. Update in-memory local store
    for (int i = 0; i < _localApplicationsStore.length; i++) {
      if (_localApplicationsStore[i].id == applicationId) {
        _localApplicationsStore[i] =
            _localApplicationsStore[i].copyWith(status: status);
      } else if (status == 'assigned' &&
          _localApplicationsStore[i].jobId == jobId) {
        _localApplicationsStore[i] =
            _localApplicationsStore[i].copyWith(status: 'rejected');
      }
    }

    if (!_uuidRegExp.hasMatch(jobId) ||
        !_uuidRegExp.hasMatch(applicationId)) {
      return true;
    }

    try {
      // Update remote application status
      await _client
          .from('applications')
          .update({'status': status}).eq('id', applicationId);

      if (status == 'assigned') {
        // Update job to 'assigned' with the worker's name
        await _client.from('jobs').update({
          'status': 'assigned',
          'worker_name': workerName,
        }).eq('id', jobId);

        // Reject all other pending applications for this job
        await _client
            .from('applications')
            .update({'status': 'rejected'})
            .eq('job_id', jobId)
            .neq('id', applicationId);

        // ── Notify worker ────────────────────────────────────────────────
        final effectiveWorkerId = _uuidRegExp.hasMatch(workerId)
            ? workerId
            : _localApplicationsStore
                    .firstWhere(
                      (a) => a.id == applicationId,
                      orElse: () => Application(
                          id: '',
                          jobId: jobId,
                          workerId: '',
                          workerName: workerName,
                          workerPhone: '',
                          status: status,
                          createdAt: DateTime.now()),
                    )
                    .workerId;

        if (_uuidRegExp.hasMatch(effectiveWorkerId)) {
          // Fetch job title for the notification body
          final jobCtx = await _fetchJobContext(jobId);
          final jobTitle = jobCtx['job_title'] ?? 'a job';
          unawaited(_notif.insertNotification(
            userId: effectiveWorkerId,
            type: 'job_accepted',
            title: 'Application Accepted! 🎉',
            body: 'Your application for "$jobTitle" has been accepted.',
            relatedJobId: jobId,
          ));
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(
            '⚠️ [ApplicationService] Error updating application status: $e');
      }
      return true;
    }
  }
}

/// Fire-and-forget helper — suppresses the "unawaited future" lint.
void unawaited(Future<void> future) {}
