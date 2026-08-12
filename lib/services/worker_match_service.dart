import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';
import 'rating_service.dart';

class MatchExplanation {
  final List<String> positives;
  final List<String> negatives;
  final Map<String, double> componentScores;

  const MatchExplanation({
    required this.positives,
    required this.negatives,
    required this.componentScores,
  });
}

class WorkerMatch {
  final UserProfile worker;
  final double score;
  final MatchExplanation explanation;
  final double? estimatedDistanceKm;

  const WorkerMatch({
    required this.worker,
    required this.score,
    required this.explanation,
    this.estimatedDistanceKm,
  });
}

class WorkerMatchService {
  final SupabaseClient _client = SupabaseService().client;
  final RatingService _ratingService = RatingService();

  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Main method to fetch and rank workers for a job
  Future<List<WorkerMatch>> getMatchesForJob(Job job) async {
    try {
      // 1. Fetch all workers from profiles table
      final res = await _client
          .from('profiles')
          .select('*, worker_profiles(location)')
          .eq('role', 'worker');

      final List rows = res as List;
      final List<UserProfile> workers = rows.map((row) {
        final List rawSkills = row['skills'] as List? ?? [];
        final skillsList = rawSkills.map((s) => s.toString()).toList();
        String? workerLoc;
        final wpData = row['worker_profiles'];
        if (wpData is Map) {
          workerLoc = wpData['location']?.toString();
        } else if (wpData is List && wpData.isNotEmpty) {
          workerLoc = wpData.first['location']?.toString();
        }

        return UserProfile(
          id: row['id']?.toString(),
          name: row['full_name'] ?? row['name'] ?? 'Worker',
          phone: row['phone'] ?? '',
          email: row['email'] ?? '',
          role: 'worker',
          streetAddress: row['street_address'] ?? '',
          locality: row['locality'] ?? '',
          city: row['city'] ?? '',
          pincode: row['pincode'] ?? '',
          photoUrl: row['photo_url'],
          skills: skillsList,
          dailyRate: (row['daily_rate'] as num?)?.toDouble() ?? 650.0,
          dispatchRadiusKm: (row['dispatch_radius_km'] as num?)?.toDouble() ?? 15.0,
          availabilityStatus: row['availability_status'] ?? 'available',
          workerAddress: workerLoc,
          isLoggedIn: true,
        );
      }).toList();

      // 2. Fetch applications for this job to exclude assigned workers
      final List<String> excludedWorkerIds = [];
      if (_uuidRegExp.hasMatch(job.id)) {
        final appRes = await _client
            .from('applications')
            .select('worker_id, status')
            .eq('job_id', job.id);
        
        for (final app in (appRes as List)) {
          if (app['status'] == 'assigned') {
            excludedWorkerIds.add(app['worker_id'].toString());
          }
        }
      }

      // 3. Score and filter workers
      final List<WorkerMatch> matches = [];

      for (final worker in workers) {
        // Condition check: Do not show workers already assigned, or unavailable
        if (worker.id != null && excludedWorkerIds.contains(worker.id)) {
          continue;
        }
        if (worker.availabilityStatus == 'busy') {
          continue;
        }

        final match = await calculateMatchScore(job, worker);
        matches.add(match);
      }

      // 4. Sort matches by score descending
      matches.sort((a, b) => b.score.compareTo(a.score));
      return matches;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [WorkerMatchService] Error fetching matches: $e');
      }
      return [];
    }
  }

  /// Calculates a rule-based matching score between a job and a worker profile
  Future<WorkerMatch> calculateMatchScore(Job job, UserProfile worker) async {
    final positives = <String>[];
    final negatives = <String>[];
    final componentScores = <String, double>{};

    int componentsCount = 0;
    double totalPointsObtained = 0.0;
    double maxPossiblePoints = 0.0;

    // 1. Skill Match (40% Weight)
    // Compare category vs skills
    final jobCategory = job.category.toLowerCase().trim();
    bool skillMatched = false;
    for (final skill in worker.skills) {
      final sLower = skill.toLowerCase();
      if (sLower.contains(jobCategory) || jobCategory.contains(sLower)) {
        skillMatched = true;
        break;
      }
      // Common mapping overrides
      if (jobCategory == 'painting' && (sLower.contains('paint') || sLower.contains('wall'))) skillMatched = true;
      if (jobCategory == 'cleaning' && (sLower.contains('clean') || sLower.contains('wash'))) skillMatched = true;
      if (jobCategory == 'plumbing' && (sLower.contains('plumb') || sLower.contains('leak'))) skillMatched = true;
      if (jobCategory == 'cooking' && (sLower.contains('cook') || sLower.contains('chef') || sLower.contains('meal'))) skillMatched = true;
      if (jobCategory == 'gardening' && (sLower.contains('garden') || sLower.contains('lawn') || sLower.contains('prun'))) skillMatched = true;
      if (jobCategory == 'electrical' && (sLower.contains('elect') || sLower.contains('wiring') || sLower.contains('mcb'))) skillMatched = true;
    }

    componentsCount++;
    maxPossiblePoints += 40.0;
    if (skillMatched) {
      totalPointsObtained += 40.0;
      componentScores['skills'] = 40.0;
      positives.add('Required skill matches');
    } else {
      componentScores['skills'] = 0.0;
      negatives.add('Category mismatch');
    }

    // 2. Distance Match (25% Weight)
    double? estimatedDistance;
    final workerLoc = worker.locality.toLowerCase().trim();
    final jobLoc = job.location.toLowerCase().trim();

    if (workerLoc.isNotEmpty && jobLoc.isNotEmpty) {
      // Lookup rule-based distance estimation
      estimatedDistance = _estimateDistance(workerLoc, jobLoc);
      
      componentsCount++;
      maxPossiblePoints += 25.0;

      if (estimatedDistance == 0.0) {
        totalPointsObtained += 25.0;
        componentScores['distance'] = 25.0;
        positives.add('Located in the same area');
      } else if (estimatedDistance <= worker.dispatchRadiusKm) {
        // Linear scaling based on dispatch radius
        final distFactor = (worker.dispatchRadiusKm - estimatedDistance) / worker.dispatchRadiusKm;
        final points = 10.0 + (15.0 * max(0.0, distFactor));
        totalPointsObtained += points;
        componentScores['distance'] = points;
        positives.add('Within dispatch radius (${estimatedDistance.toStringAsFixed(1)} km away)');
      } else {
        componentScores['distance'] = 0.0;
        negatives.add('Beyond dispatch radius (${estimatedDistance.toStringAsFixed(1)} km away)');
      }
    } else {
      componentScores['distance'] = 0.0;
    }

    // 3. Availability (15% Weight)
    componentsCount++;
    maxPossiblePoints += 15.0;
    if (worker.availabilityStatus == 'available') {
      totalPointsObtained += 15.0;
      componentScores['availability'] = 15.0;
      positives.add('Available today');
    } else {
      componentScores['availability'] = 0.0;
      negatives.add('Currently busy or unavailable');
    }

    // 4. Rating / Reputation (10% Weight)
    int thumbsUpPercentage = 100;
    bool hasRatingHistory = false;
    if (worker.id != null && _uuidRegExp.hasMatch(worker.id!)) {
      try {
        final summary = await _ratingService.fetchThumbsSummary(worker.id!);
        if (summary.totalRatings > 0 && summary.thumbsUpPercentage != null) {
          thumbsUpPercentage = summary.thumbsUpPercentage!;
          hasRatingHistory = true;
        }
      } catch (_) {}
    }

    componentsCount++;
    maxPossiblePoints += 10.0;
    if (hasRatingHistory) {
      final points = 10.0 * (thumbsUpPercentage / 100.0);
      totalPointsObtained += points;
      componentScores['rating'] = points;
      if (thumbsUpPercentage >= 85) {
        positives.add('High rating ($thumbsUpPercentage% Recommended)');
      } else {
        negatives.add('Rating is $thumbsUpPercentage% Recommended');
      }
    } else {
      // Neutral default for new workers
      totalPointsObtained += 8.0;
      componentScores['rating'] = 8.0;
      positives.add('New worker with excellent standing');
    }

    // 5. Wage Compatibility (10% Weight)
    componentsCount++;
    maxPossiblePoints += 10.0;
    if (job.wage >= worker.dailyRate) {
      totalPointsObtained += 10.0;
      componentScores['wage'] = 10.0;
      positives.add('Rate matches employer budget');
    } else {
      final ratio = job.wage / worker.dailyRate;
      final points = 10.0 * max(0.0, ratio);
      totalPointsObtained += points;
      componentScores['wage'] = points;
      negatives.add('Daily rate slightly higher than budget');
    }

    // Normalize final score to a percentage
    final finalScore = maxPossiblePoints > 0 
        ? (totalPointsObtained / maxPossiblePoints) * 100 
        : 0.0;

    return WorkerMatch(
      worker: worker,
      score: finalScore,
      explanation: MatchExplanation(
        positives: positives,
        negatives: negatives,
        componentScores: componentScores,
      ),
      estimatedDistanceKm: estimatedDistance,
    );
  }

  /// Distance matrix lookups for realistic match estimation
  double _estimateDistance(String loc1, String loc2) {
    final l1 = loc1.toLowerCase();
    final l2 = loc2.toLowerCase();

    if (l1 == l2) return 0.0;
    if (l1.contains(l2) || l2.contains(l1)) return 0.0;

    // Localities mapping
    bool isIndiranagar(String s) => s.contains('indiranagar');
    bool isKoramangala(String s) => s.contains('koramangala');
    bool isHSR(String s) => s.contains('hsr');
    bool isMurugeshpalya(String s) => s.contains('murugeshpalya');
    bool isEjipura(String s) => s.contains('ejipura');
    bool isBTM(String s) => s.contains('btm');
    bool isWhitefield(String s) => s.contains('whitefield');
    bool isJayanagar(String s) => s.contains('jayanagar');
    bool isBellandur(String s) => s.contains('bellandur');
    bool isSarjapur(String s) => s.contains('sarjapur');

    // Murugeshpalya adjacencies
    if (isMurugeshpalya(l1)) {
      if (isIndiranagar(l2)) return 2.5;
      if (isEjipura(l2)) return 3.0;
      if (isKoramangala(l2)) return 4.5;
      if (isBellandur(l2)) return 6.0;
    }
    if (isMurugeshpalya(l2)) {
      if (isIndiranagar(l1)) return 2.5;
      if (isEjipura(l1)) return 3.0;
      if (isKoramangala(l1)) return 4.5;
      if (isBellandur(l1)) return 6.0;
    }

    // Ejipura adjacencies
    if (isEjipura(l1)) {
      if (isKoramangala(l2)) return 1.5;
      if (isIndiranagar(l2)) return 4.0;
      if (isBTM(l2)) return 4.0;
      if (isHSR(l2)) return 4.5;
    }
    if (isEjipura(l2)) {
      if (isKoramangala(l1)) return 1.5;
      if (isIndiranagar(l1)) return 4.0;
      if (isBTM(l1)) return 4.0;
      if (isHSR(l1)) return 4.5;
    }

    // BTM Layout adjacencies
    if (isBTM(l1)) {
      if (isKoramangala(l2)) return 3.0;
      if (isHSR(l2)) return 3.5;
      if (isJayanagar(l2)) return 2.8;
    }
    if (isBTM(l2)) {
      if (isKoramangala(l1)) return 3.0;
      if (isHSR(l1)) return 3.5;
      if (isJayanagar(l1)) return 2.8;
    }

    // Default estimates between major hubs
    if (isIndiranagar(l1) && isKoramangala(l2)) return 5.5;
    if (isKoramangala(l1) && isIndiranagar(l2)) return 5.5;

    if (isIndiranagar(l1) && isHSR(l2)) return 7.5;
    if (isHSR(l1) && isIndiranagar(l2)) return 7.5;

    if (isKoramangala(l1) && isHSR(l2)) return 3.8;
    if (isHSR(l1) && isKoramangala(l2)) return 3.8;

    if (isWhitefield(l1) || isWhitefield(l2)) return 14.5; // Far

    return 6.0; // Default average fallback
  }
}
