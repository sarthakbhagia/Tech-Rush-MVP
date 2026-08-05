import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

/// Represents the result of a thumbs-up / thumbs-down rating submission.
class RatingResult {
  final bool success;
  final String? errorMessage;
  const RatingResult({required this.success, this.errorMessage});
}

/// Service for the dual 👍 / 👎 thumbs-based rating system.
///
/// Writes to public.ratings and atomically increments the target's
/// rating_thumbs_up or rating_thumbs_down counter on public.profiles.
class RatingService {
  final SupabaseClient _client = SupabaseService().client;
  final NotificationService _notif = NotificationService();

  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  // ── In-memory fallback store for demo / offline mode ────────────────────
  static final List<Map<String, dynamic>> _localStore = [];

  /// Submits a 👍 or 👎 rating.
  ///
  /// [jobId]       — UUID of the completed job.
  /// [evaluatorId] — UUID of the person giving the rating (employer or worker).
  /// [targetId]    — UUID of the person being rated.
  /// [isThumbsUp]  — true = 👍, false = 👎.
  /// [comments]    — Optional text comment.
  Future<RatingResult> submitRating({
    required String jobId,
    required String evaluatorId,
    required String targetId,
    required bool isThumbsUp,
    String? comments,
  }) async {
    final ratingType = isThumbsUp ? 'thumbs_up' : 'thumbs_down';

    // Always persist locally for instant UI feedback
    _localStore.removeWhere((r) =>
        r['job_id'] == jobId &&
        r['evaluator_id'] == evaluatorId &&
        r['target_id'] == targetId);
    _localStore.add({
      'job_id': jobId,
      'evaluator_id': evaluatorId,
      'target_id': targetId,
      'rating_type': ratingType,
      'comments': comments,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Skip DB writes when IDs are non-UUIDs (demo mode)
    if (!_uuidRegExp.hasMatch(jobId) ||
        !_uuidRegExp.hasMatch(evaluatorId) ||
        !_uuidRegExp.hasMatch(targetId)) {
      if (kDebugMode) {
        print('ℹ️ [RatingService] Demo mode — rating stored locally only.');
      }
      return const RatingResult(success: true);
    }

    try {
      // 1. Insert rating row (upsert to handle re-submissions gracefully)
      await _client.from('ratings').upsert({
        'job_id': jobId,
        'evaluator_id': evaluatorId,
        'target_id': targetId,
        'rating_type': ratingType,
        if (comments != null && comments.trim().isNotEmpty)
          'comments': comments.trim(),
      });

      // 2. Atomically increment the target's counter via RPC
      if (isThumbsUp) {
        await _client.rpc('increment_thumbs_up', params: {'user_id': targetId});
      } else {
        await _client.rpc('increment_thumbs_down', params: {'user_id': targetId});
      }

      if (kDebugMode) {
        print(
            '✅ [RatingService] Submitted $ratingType for target $targetId on job $jobId');
      }

      // 3. Fire-and-forget notification to the target user
      final emoji = isThumbsUp ? '👍' : '👎';
      unawaited(_notif.insertNotification(
        userId: targetId,
        type: 'rating_received',
        title: 'You Received a Rating $emoji',
        body: isThumbsUp
            ? 'Great job! Someone gave you a thumbs up for your work.'
            : 'You received a thumbs down. Use feedback to improve.',
        relatedJobId: jobId,
      ));

      return const RatingResult(success: true);
    } on PostgrestException catch (e) {
      // Code 23505 = unique constraint violation (already rated)
      if (e.code == '23505') {
        if (kDebugMode) {
          print('ℹ️ [RatingService] Already rated this job/target combination.');
        }
        return const RatingResult(
          success: false,
          errorMessage: 'You have already submitted a rating for this job.',
        );
      }
      if (kDebugMode) {
        print('⚠️ [RatingService] PostgrestException: ${e.message}');
      }
      return RatingResult(success: false, errorMessage: e.message);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [RatingService] Error submitting rating: $e');
      }
      // Return success true for network errors so UX isn't blocked
      return const RatingResult(success: true);
    }
  }

  /// Checks if [evaluatorId] has already rated [targetId] for [jobId].
  Future<bool> hasRated({
    required String jobId,
    required String evaluatorId,
    required String targetId,
  }) async {
    // Check local store first
    final localMatch = _localStore.any((r) =>
        r['job_id'] == jobId &&
        r['evaluator_id'] == evaluatorId &&
        r['target_id'] == targetId);
    if (localMatch) return true;

    if (!_uuidRegExp.hasMatch(jobId) || !_uuidRegExp.hasMatch(evaluatorId)) {
      return false;
    }

    try {
      final res = await _client
          .from('ratings')
          .select('id')
          .eq('job_id', jobId)
          .eq('evaluator_id', evaluatorId)
          .eq('target_id', targetId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  /// Fetches thumbs counters (up, down) for a target user.
  Future<({int thumbsUp, int thumbsDown})> fetchThumbsCounters(
      String targetId) async {
    // Check local store
    final localUp = _localStore
        .where((r) =>
            r['target_id'] == targetId && r['rating_type'] == 'thumbs_up')
        .length;
    final localDown = _localStore
        .where((r) =>
            r['target_id'] == targetId && r['rating_type'] == 'thumbs_down')
        .length;

    if (!_uuidRegExp.hasMatch(targetId)) {
      return (thumbsUp: localUp, thumbsDown: localDown);
    }

    try {
      final res = await _client
          .from('profiles')
          .select('rating_thumbs_up, rating_thumbs_down')
          .eq('id', targetId)
          .maybeSingle();

      if (res == null) return (thumbsUp: localUp, thumbsDown: localDown);

      return (
        thumbsUp: (res['rating_thumbs_up'] as num?)?.toInt() ?? localUp,
        thumbsDown:
            (res['rating_thumbs_down'] as num?)?.toInt() ?? localDown,
      );
    } catch (_) {
      return (thumbsUp: localUp, thumbsDown: localDown);
    }
  }
}

/// Fire-and-forget helper — prevents unawaited lint.
void unawaited(Future<void> future) {}
