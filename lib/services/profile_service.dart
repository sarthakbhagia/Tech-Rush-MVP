import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

class ProfileService {
  final SupabaseClient _client = SupabaseService().client;

  static final RegExp _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Creates or updates a user profile in Supabase public.profiles table
  Future<bool> upsertProfile({
    required String userId,
    required String fullName,
    required String streetAddress,
    required String locality,
    required String city,
    required String email,
    required String phone,
    String role = 'employer',
    String? photoUrl,
  }) async {
    if (!_uuidRegExp.hasMatch(userId)) {
      if (kDebugMode) {
        print('ℹ️ [ProfileService] Skipping DB upsert for demo non-UUID user: $userId');
      }
      return true;
    }

    try {
      final data = {
        'id': userId,
        'full_name': fullName,
        'street_address': streetAddress,
        'locality': locality,
        'city': city,
        'email': email,
        'phone': phone,
        'role': role,
        if (photoUrl != null) 'photo_url': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('profiles').upsert(data);
      if (kDebugMode) {
        print('✅ [ProfileService] Profile created/updated for user: $userId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ProfileService] Error upserting profile: $e');
      }
      return false;
    }
  }

  /// Fetches profile by Supabase Auth user ID
  Future<UserProfile?> fetchProfile(String userId) async {
    if (!_uuidRegExp.hasMatch(userId)) {
      if (kDebugMode) {
        print('ℹ️ [ProfileService] Skipping DB fetch for demo non-UUID user: $userId');
      }
      return null;
    }

    try {
      final res =
          await _client.from('profiles').select().eq('id', userId).maybeSingle();

      if (res == null) return null;

      return UserProfile(
        name: res['full_name'] ?? 'Sharma Household',
        phone: res['phone'] ?? '',
        email: res['email'] ?? '',
        streetAddress: res['street_address'] ?? 'Flat 302, Green Acres',
        locality: res['locality'] ?? 'Indiranagar',
        city: res['city'] ?? 'BLR',
        pincode: res['pincode'] ?? '560038',
        photoUrl: res['photo_url'],
        isLoggedIn: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ProfileService] Error fetching profile ($userId): $e');
      }
      return null;
    }
  }
}
