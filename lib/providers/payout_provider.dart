import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payout.dart';
import '../services/payout_service.dart';

final payoutServiceProvider = Provider<PayoutService>((ref) => PayoutService());

class UserPayoutsParams {
  final String userId;
  final String role; // 'worker' or 'employer'

  const UserPayoutsParams({required this.userId, required this.role});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPayoutsParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          role == other.role;

  @override
  int get hashCode => userId.hashCode ^ role.hashCode;
}

final userPayoutsProvider =
    FutureProvider.family<List<Payout>, UserPayoutsParams>((ref, params) async {
  final service = ref.watch(payoutServiceProvider);
  return await service.fetchPayoutsForUser(params.userId, params.role);
});

final jobPayoutProvider =
    FutureProvider.family<Payout?, String>((ref, jobId) async {
  final service = ref.watch(payoutServiceProvider);
  return await service.fetchPayoutForJob(jobId);
});
