class CompletionProof {
  final String id;
  final String jobId;
  final String workerId;
  final List<String> proofImageUrls;
  final bool workerConfirmed;
  final DateTime submittedAt;
  final String verificationStatus; // 'pending' | 'verified' | 'disputed'
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? notes;

  const CompletionProof({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.proofImageUrls,
    required this.workerConfirmed,
    required this.submittedAt,
    required this.verificationStatus,
    this.verifiedBy,
    this.verifiedAt,
    this.notes,
  });

  factory CompletionProof.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['proof_image_urls'];
    final List<String> imageUrls;
    if (rawUrls is List) {
      imageUrls = rawUrls.map((e) => e.toString()).toList();
    } else {
      imageUrls = [];
    }

    return CompletionProof(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? '',
      proofImageUrls: imageUrls,
      workerConfirmed: json['worker_confirmed'] as bool? ?? false,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'].toString())
          : DateTime.now(),
      verificationStatus: json['verification_status']?.toString() ?? 'pending',
      verifiedBy: json['verified_by']?.toString(),
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && !id.startsWith('proof_')) 'id': id,
      'job_id': jobId,
      'worker_id': workerId,
      'proof_image_urls': proofImageUrls,
      'worker_confirmed': workerConfirmed,
      'submitted_at': submittedAt.toIso8601String(),
      'verification_status': verificationStatus,
      if (verifiedBy != null) 'verified_by': verifiedBy,
      if (verifiedAt != null) 'verified_at': verifiedAt!.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  CompletionProof copyWith({
    String? id,
    String? jobId,
    String? workerId,
    List<String>? proofImageUrls,
    bool? workerConfirmed,
    DateTime? submittedAt,
    String? verificationStatus,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? notes,
  }) {
    return CompletionProof(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      workerId: workerId ?? this.workerId,
      proofImageUrls: proofImageUrls ?? this.proofImageUrls,
      workerConfirmed: workerConfirmed ?? this.workerConfirmed,
      submittedAt: submittedAt ?? this.submittedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      notes: notes ?? this.notes,
    );
  }
}
