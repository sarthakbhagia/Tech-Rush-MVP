enum NotificationType { job, payment, system }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String timestamp;
  final NotificationType type;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? timestamp,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}

final List<NotificationItem> mockNotifications = [
  const NotificationItem(
    id: 'n1',
    title: 'Job Accepted: Electrician Gig',
    body: 'Ramesh K. accepted your dispatch for Indiranagar 4th Block.',
    timestamp: '10m ago',
    type: NotificationType.job,
    isRead: false,
  ),
  const NotificationItem(
    id: 'n2',
    title: 'Wage Payment Dispatched: ₹1,200',
    body: 'Daily wage payment for Deep House Cleaning has been released via UPI.',
    timestamp: '1h ago',
    type: NotificationType.payment,
    isRead: false,
  ),
  const NotificationItem(
    id: 'n3',
    title: 'New Application Received',
    body: 'Suresh V. applied for your Exterior Wall Painting job.',
    timestamp: '3h ago',
    type: NotificationType.job,
    isRead: false,
  ),
  const NotificationItem(
    id: 'n4',
    title: 'Profile Verification Approved',
    body: 'Your Aadhaar & Skill Verification badge is now active on KaamSetu.',
    timestamp: 'Yesterday',
    type: NotificationType.system,
    isRead: true,
  ),
];
