class Job {
  final String id;
  final String title;
  final String category;
  final String description;
  final double wage;
  final double? originalWage;
  final String status; // 'open', 'assigned', 'completed'
  final double rating;
  final int reviewCount;
  final String location;
  final String date;
  final String employerName;
  final String? workerName;
  final bool verified;
  final bool urgent;

  const Job({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.wage,
    this.originalWage,
    required this.status,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.date,
    required this.employerName,
    this.workerName,
    this.verified = true,
    this.urgent = false,
  });
}

final List<Job> mockJobs = [
  const Job(
    id: 'job-1',
    title: 'Full House Painting (Interior Walls)',
    category: 'Painting',
    description: '3 BHK apartment interior wall painting & primer coat. Paints provided on site.',
    wage: 1500,
    originalWage: 1800,
    status: 'open',
    rating: 4.8,
    reviewCount: 24,
    location: 'Indiranagar, Stage 2',
    date: 'Today 14:00',
    employerName: 'Sharma Household',
    verified: true,
    urgent: true,
  ),
  const Job(
    id: 'job-2',
    title: 'Deep Kitchen & Chimney Cleaning',
    category: 'Cleaning',
    description: 'Degreasing chimney filters, exhaust fan cleaning, and marble countertop scrub.',
    wage: 900,
    originalWage: 1200,
    status: 'open',
    rating: 4.9,
    reviewCount: 42,
    location: 'Koramangala, Block 4',
    date: 'Tomorrow 09:00',
    employerName: 'Verma Residences',
    verified: true,
  ),
  const Job(
    id: 'job-3',
    title: 'Emergency Bathroom Pipe Leak Repair',
    category: 'Plumbing',
    description: 'Replacing broken PVC joint under sink & sealing shower drain leakage.',
    wage: 750,
    originalWage: 850,
    status: 'assigned',
    rating: 4.7,
    reviewCount: 18,
    location: 'HSR Layout, Sector 3',
    date: 'Today 16:30',
    employerName: 'Kapoor Villa',
    workerName: 'Ramesh Kumar',
    verified: true,
    urgent: true,
  ),
  const Job(
    id: 'job-4',
    title: 'Balcony Garden Tiling & Drainage Fix',
    category: 'Gardening',
    description: 'Laying anti-skid floor tiles in 12x8 ft balcony and installing drainage grate.',
    wage: 1100,
    status: 'completed',
    rating: 5.0,
    reviewCount: 31,
    location: 'Jayanagar, 4th Block',
    date: 'Yesterday',
    employerName: 'Mehta Estate',
    workerName: 'Sunil Sharma',
    verified: true,
  ),
];
