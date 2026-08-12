class Payout {
  final String id;
  final String jobId;
  final String workerId;
  final String employerId;
  final double amount;
  final String status; // 'payment_pending', 'payout_processing', 'paid'
  final String transactionReference;
  final DateTime createdAt;
  final DateTime? processedAt;

  const Payout({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.employerId,
    required this.amount,
    required this.status,
    required this.transactionReference,
    required this.createdAt,
    this.processedAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? '',
      employerId: json['employer_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'payment_pending',
      transactionReference: json['transaction_reference']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && !id.startsWith('payout-')) 'id': id,
      'job_id': jobId,
      'worker_id': workerId,
      'employer_id': employerId,
      'amount': amount,
      'status': status,
      'transaction_reference': transactionReference,
      'created_at': createdAt.toIso8601String(),
      if (processedAt != null) 'processed_at': processedAt!.toIso8601String(),
    };
  }

  Payout copyWith({
    String? id,
    String? jobId,
    String? workerId,
    String? employerId,
    double? amount,
    String? status,
    String? transactionReference,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return Payout(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      workerId: workerId ?? this.workerId,
      employerId: employerId ?? this.employerId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      transactionReference: transactionReference ?? this.transactionReference,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
