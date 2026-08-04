class UserProfile {
  final String name;
  final String phone;
  final String email;
  final String role;
  final String streetAddress;
  final String locality;
  final String city;
  final String pincode;
  final String? photoUrl;
  final List<String> skills;
  final double dailyRate;
  final double dispatchRadiusKm;
  final String availabilityStatus; // 'available' or 'busy'
  final bool isLoggedIn;

  const UserProfile({
    this.name = 'Sharma Household',
    this.phone = '+91 98765 43210',
    this.email = 'sharma@example.com',
    this.role = 'employer',
    this.streetAddress = 'Flat 302, Green Acres',
    this.locality = 'Indiranagar',
    this.city = 'BLR',
    this.pincode = '560038',
    this.photoUrl,
    this.skills = const ['House Painting', 'Wall Tiling', 'Plumbing Leak Repair'],
    this.dailyRate = 650.0,
    this.dispatchRadiusKm = 15.0,
    this.availabilityStatus = 'available',
    this.isLoggedIn = true,
  });

  String get shortAddress {
    if (locality.isNotEmpty && city.isNotEmpty) {
      return '$locality, $city';
    } else if (locality.isNotEmpty) {
      return locality;
    } else if (streetAddress.isNotEmpty) {
      return streetAddress;
    }
    return 'Indiranagar, BLR';
  }

  String get fullAddress {
    final parts = [streetAddress, locality, city, pincode].where((p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'Indiranagar, BLR';
    return parts.join(', ');
  }

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? role,
    String? streetAddress,
    String? locality,
    String? city,
    String? pincode,
    String? photoUrl,
    List<String>? skills,
    double? dailyRate,
    double? dispatchRadiusKm,
    String? availabilityStatus,
    bool? isLoggedIn,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      streetAddress: streetAddress ?? this.streetAddress,
      locality: locality ?? this.locality,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      photoUrl: photoUrl ?? this.photoUrl,
      skills: skills ?? this.skills,
      dailyRate: dailyRate ?? this.dailyRate,
      dispatchRadiusKm: dispatchRadiusKm ?? this.dispatchRadiusKm,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}
