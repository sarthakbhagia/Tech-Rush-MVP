import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/completion_proof.dart';
import 'supabase_service.dart';

class CompletionProofService {
  final SupabaseClient _client = SupabaseService().client;

  // Static in-memory fallback store keyed by job_id
  static final Map<String, CompletionProof> _localStore = {};

  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Submit completion proof for a job.
  /// Returns the proof record (local or DB-backed).
  Future<CompletionProof?> submitProof({
    required String jobId,
    required String workerId,
    required List<String> imageUrls,
  }) async {
    // Prevent duplicate submission
    if (_localStore.containsKey(jobId)) {
      if (kDebugMode) {
        print('⚠️ [CompletionProofService] Proof already exists locally for job $jobId');
      }
      return _localStore[jobId];
    }

    final now = DateTime.now();
    final proof = CompletionProof(
      id: 'proof_${now.millisecondsSinceEpoch}',
      jobId: jobId,
      workerId: workerId,
      proofImageUrls: imageUrls,
      workerConfirmed: true,
      submittedAt: now,
      verificationStatus: 'pending',
    );

    _localStore[jobId] = proof;

    if (_uuidRegExp.hasMatch(jobId) &&
        _uuidRegExp.hasMatch(workerId)) {
      try {
        final payload = {
          'job_id': jobId,
          'worker_id': workerId,
          'proof_image_urls': imageUrls,
          'worker_confirmed': true,
          'submitted_at': now.toIso8601String(),
          'verification_status': 'pending',
        };
        final res = await _client
            .from('completion_proofs')
            .insert(payload)
            .select()
            .single();
        final dbProof = CompletionProof.fromJson(res);
        _localStore[jobId] = dbProof;
        if (kDebugMode) {
          print('✅ [CompletionProofService] Proof created in DB for job $jobId');
        }
        return dbProof;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [CompletionProofService] DB insert failed (using local): $e');
        }
      }
    }

    return proof;
  }

  /// Fetch the completion proof for a given job.
  Future<CompletionProof?> fetchProofForJob(String jobId) async {
    if (_localStore.containsKey(jobId)) return _localStore[jobId];

    if (!_uuidRegExp.hasMatch(jobId)) return null;

    try {
      final res = await _client
          .from('completion_proofs')
          .select()
          .eq('job_id', jobId)
          .order('submitted_at', ascending: false)
          .maybeSingle();
      if (res != null) {
        final proof = CompletionProof.fromJson(res);
        _localStore[jobId] = proof;
        return proof;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [CompletionProofService] DB fetch proof failed: $e');
      }
    }
    return null;
  }

  /// Mark the proof as verified (called by employer on accepting).
  Future<bool> verifyProof({
    required String jobId,
    required String verifiedBy,
  }) async {
    final existing = _localStore[jobId];
    if (existing != null) {
      final updated = existing.copyWith(
        verificationStatus: 'verified',
        verifiedBy: verifiedBy,
        verifiedAt: DateTime.now(),
      );
      _localStore[jobId] = updated;
    }

    if (!_uuidRegExp.hasMatch(jobId)) return true;

    try {
      final proof = await fetchProofForJob(jobId);
      if (proof == null || proof.id.startsWith('proof_')) return true;

      await _client.from('completion_proofs').update({
        'verification_status': 'verified',
        'verified_by': verifiedBy,
        'verified_at': DateTime.now().toIso8601String(),
      }).eq('id', proof.id);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [CompletionProofService] DB verify proof failed: $e');
      }
      return true; // Local update already done
    }
  }

  /// Mark the proof as disputed (called when employer reports an issue).
  Future<bool> disputeProof({required String jobId}) async {
    final existing = _localStore[jobId];
    if (existing != null) {
      _localStore[jobId] = existing.copyWith(verificationStatus: 'disputed');
    }

    if (!_uuidRegExp.hasMatch(jobId)) return true;

    try {
      final proof = await fetchProofForJob(jobId);
      if (proof == null || proof.id.startsWith('proof_')) return true;
      await _client.from('completion_proofs').update({
        'verification_status': 'disputed',
      }).eq('id', proof.id);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [CompletionProofService] DB dispute proof failed: $e');
      }
      return true;
    }
  }
}
