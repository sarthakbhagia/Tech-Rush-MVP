enum ApplicationStatus { pending, selected, notSelected }

class Application {
  final String id;
  final String jobId;
  final String workerId;
  final ApplicationStatus status;
  final DateTime createdAt;

  const Application({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.status,
    required this.createdAt,
  });
}
