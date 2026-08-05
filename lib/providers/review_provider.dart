import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../services/rating_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

final ratingServiceProvider = Provider<RatingService>((ref) {
  return RatingService();
});

final workerRatingSummaryProvider =
    FutureProvider.family<WorkerRatingSummary, String>((ref, workerId) async {
  final service = ref.watch(reviewServiceProvider);
  return service.fetchWorkerRatingSummary(workerId);
});

final workerReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, workerId) async {
  final service = ref.watch(reviewServiceProvider);
  return service.fetchReviewsForWorker(workerId);
});

/// Holds the thumbs counters (up, down) for a given user ID.
final thumbsCountersProvider =
    FutureProvider.family<({int thumbsUp, int thumbsDown}), String>(
        (ref, userId) async {
  final service = ref.watch(ratingServiceProvider);
  return service.fetchThumbsCounters(userId);
});
