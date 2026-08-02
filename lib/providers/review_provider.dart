import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../services/review_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
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
