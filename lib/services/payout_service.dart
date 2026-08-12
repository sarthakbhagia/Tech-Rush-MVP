import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payout.dart';
import 'supabase_service.dart';


class PayoutService {
  final SupabaseClient _client = SupabaseService().client;
  static final Map<String, Payout> _localPayoutsStore = {};

  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Generates a random realistic Transaction Reference
  String _generateReference() {
    final rand = Random();
    final num = rand.nextInt(90000) + 10000;
    return 'KS-DEMO-$num';
  }

  /// Create a payout record for a completed job
  Future<Payout?> createPayout({
    required String jobId,
    required String workerId,
    required String employerId,
    required double amount,
  }) async {
    // 1. Prevent duplicates locally
    if (_localPayoutsStore.values.any((p) => p.jobId == jobId)) {
      if (kDebugMode) {
        print('⚠️ [PayoutService] Payout already exists locally for job $jobId');
      }
      return _localPayoutsStore.values.firstWhere((p) => p.jobId == jobId);
    }

    final now = DateTime.now();
    final ref = _generateReference();
    final payout = Payout(
      id: _uuidRegExp.hasMatch(jobId) ? jobId : 'payout_${now.millisecondsSinceEpoch}',
      jobId: jobId,
      workerId: workerId,
      employerId: employerId,
      amount: amount,
      status: 'payment_pending',
      transactionReference: ref,
      createdAt: now,
    );

    // Save locally
    _localPayoutsStore[payout.id] = payout;

    // 2. Insert to Supabase if UUIDs are valid
    if (_uuidRegExp.hasMatch(jobId) && _uuidRegExp.hasMatch(workerId) && _uuidRegExp.hasMatch(employerId)) {
      try {
        final payload = payout.toJson();
        // Supabase might fail if table is not created yet, so we catch and ignore/fallback
        await _client.from('payouts').insert(payload);
        if (kDebugMode) {
          print('✅ [PayoutService] Created remote payout in DB for job: $jobId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [PayoutService] DB insert failed (falling back to memory): $e');
        }
      }
    }

    return payout;
  }

  /// Fetches a payout details for a specific job
  Future<Payout?> fetchPayoutForJob(String jobId) async {
    // Check local store first
    final local = _localPayoutsStore.values.cast<Payout?>().firstWhere(
          (p) => p?.jobId == jobId,
          orElse: () => null,
        );
    if (local != null) return local;

    if (!_uuidRegExp.hasMatch(jobId)) return null;

    try {
      final res = await _client
          .from('payouts')
          .select()
          .eq('job_id', jobId)
          .maybeSingle();
      if (res != null) {
        final payout = Payout.fromJson(res);
        _localPayoutsStore[payout.id] = payout;
        return payout;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [PayoutService] DB fetch job payout failed: $e');
      }
    }
    return null;
  }

  /// Fetches all payouts associated with a user (either worker or employer)
  Future<List<Payout>> fetchPayoutsForUser(String userId, String role) async {
    // Collect local payouts matching user
    final localList = _localPayoutsStore.values.where((p) {
      if (role == 'worker') {
        return p.workerId == userId;
      } else {
        return p.employerId == userId;
      }
    }).toList();

    if (!_uuidRegExp.hasMatch(userId)) {
      // If we are in offline/demo mode, return local list
      return localList;
    }

    try {
      final query = _client.from('payouts').select();
      final res = role == 'worker'
          ? await query.eq('worker_id', userId)
          : await query.eq('employer_id', userId);

      final List rows = res as List;
      final remoteList = rows.map((r) => Payout.fromJson(r)).toList();

      // Merge remote list into local store & return unique union
      for (final p in remoteList) {
        _localPayoutsStore[p.id] = p;
      }

      final merged = {
        for (final p in [...localList, ...remoteList]) p.id: p
      }.values.toList();

      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [PayoutService] DB fetch payouts for user failed: $e');
      }
      localList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return localList;
    }
  }

  /// Update payout status
  Future<bool> updatePayoutStatus({
    required String payoutId,
    required String status,
  }) async {
    final existing = _localPayoutsStore[payoutId];
    if (existing == null) return false;

    final updated = existing.copyWith(
      status: status,
      processedAt: status == 'paid' ? DateTime.now() : existing.processedAt,
    );
    _localPayoutsStore[payoutId] = updated;

    if (!_uuidRegExp.hasMatch(payoutId)) {
      return true;
    }

    try {
      await _client.from('payouts').update({
        'status': status,
        if (status == 'paid') 'processed_at': DateTime.now().toIso8601String(),
      }).eq('id', payoutId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [PayoutService] DB update payout status failed: $e');
      }
      return true; // Return true as memory fallback is successful
    }
  }
}
