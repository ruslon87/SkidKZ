enum UserRole { buyer, wanghong, seller, admin }

class AppUser {
  final String id; // uid
  final String phoneNumber;
  final UserRole? role;

  // optional profile fields
  final String? name;

  // wanghong only
  final String? kaspiPhone; // номер каспи для выплат
  final bool? offerAccepted;

  const AppUser({
    required this.id,
    required this.phoneNumber,
    this.role,
    this.name,
    this.kaspiPhone,
    this.offerAccepted,
  });

  Map<String, dynamic> toMap() => {
        'phoneNumber': phoneNumber,
        'role': role?.name,
        'name': name,
        'kaspiPhone': kaspiPhone,
        'offerAccepted': offerAccepted,
        'createdAt': DateTime.now().toIso8601String(),
      };

  static AppUser fromMap(String uid, Map<String, dynamic> data) {
    final roleStr = data['role'] as String?;
    return AppUser(
      id: uid,
      phoneNumber: (data['phoneNumber'] as String?) ?? '',
      role: roleStr == null ? null : UserRole.values.firstWhere((r) => r.name == roleStr),
      name: data['name'] as String?,
      kaspiPhone: data['kaspiPhone'] as String?,
      offerAccepted: data['offerAccepted'] as bool?,
    );
  }
}
