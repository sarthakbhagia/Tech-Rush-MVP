import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/completion_proof.dart';
import '../services/completion_proof_service.dart';

final completionProofServiceProvider =
    Provider<CompletionProofService>((ref) => CompletionProofService());

/// Fetches the completion proof for a specific job.
final completionProofForJobProvider =
    FutureProvider.family<CompletionProof?, String>((ref, jobId) async {
  final service = ref.watch(completionProofServiceProvider);
  return await service.fetchProofForJob(jobId);
});
