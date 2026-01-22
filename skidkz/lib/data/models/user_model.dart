enum UserRole { buyer, wanghong, seller, admin }

class User {
  final String id;
  final String name;
  final String phoneNumber;
  final UserRole role;
  final String? promoCode; // Only for Wanghong

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.role,
    this.promoCode,
  });
}
