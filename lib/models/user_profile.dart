class UserProfile {
  final String name;
  final String phone;
  final String email;
  final String streetAddress;
  final String locality;
  final String city;
  final String pincode;
  final bool isLoggedIn;

  const UserProfile({
    this.name = 'Sharma Household',
    this.phone = '+91 98765 43210',
    this.email = 'sharma@example.com',
    this.streetAddress = 'Flat 302, Green Acres',
    this.locality = 'Indiranagar',
    this.city = 'BLR',
    this.pincode = '560038',
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
    String? streetAddress,
    String? locality,
    String? city,
    String? pincode,
    bool? isLoggedIn,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      streetAddress: streetAddress ?? this.streetAddress,
      locality: locality ?? this.locality,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}
