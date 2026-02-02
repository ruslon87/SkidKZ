// lib/data/models/user_model.dart

enum UserRole { buyer, seller, wanghong, admin }

class UserModel {
  final String uid;
  final String? phone;
  final List<UserRole> roles;
  final UserRole activeRole;

  final BuyerProfile buyerProfile;
  final SellerProfile sellerProfile;
  final WanghongProfile wanghongProfile;

  UserModel({
    required this.uid,
    required this.roles,
    required this.activeRole,
    this.phone,
    required this.buyerProfile,
    required this.sellerProfile,
    required this.wanghongProfile,
  });

  static UserRole _roleFromString(String? s) {
    final v = (s ?? 'buyer').trim().toLowerCase();
    return UserRole.values.firstWhere(
      (r) => r.name == v,
      orElse: () => UserRole.buyer,
    );
  }

  static List<UserRole> _rolesFromAny(dynamic rawRoles, String? rawRoleLegacy) {
    // New: roles: ["buyer","seller"...]
    if (rawRoles is List) {
      final out = <UserRole>[];
      for (final x in rawRoles) {
        if (x is String) out.add(_roleFromString(x));
      }
      if (out.isNotEmpty) return out.toSet().toList();
    }

    // Legacy: role: "buyer"
    if (rawRoleLegacy is String && rawRoleLegacy.trim().isNotEmpty) {
      return [_roleFromString(rawRoleLegacy)];
    }

    return [UserRole.buyer];
  }

  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    final phone = data['phone'] as String?;

    final roles = _rolesFromAny(data['roles'], data['role']);
    final active = _roleFromString((data['activeRole'] as String?) ?? (data['role'] as String?));

    // activeRole must be in roles (sanity)
    final fixedActive = roles.contains(active) ? active : roles.first;

    final profiles = (data['profiles'] is Map<String, dynamic>)
        ? (data['profiles'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final buyerMap = (profiles['buyer'] is Map<String, dynamic>)
        ? (profiles['buyer'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final sellerMap = (profiles['seller'] is Map<String, dynamic>)
        ? (profiles['seller'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final wanghongMap = (profiles['wanghong'] is Map<String, dynamic>)
        ? (profiles['wanghong'] as Map<String, dynamic>)
        : <String, dynamic>{};

    return UserModel(
      uid: uid,
      phone: phone,
      roles: roles,
      activeRole: fixedActive,
      buyerProfile: BuyerProfile.fromMap(buyerMap),
      sellerProfile: SellerProfile.fromMap(sellerMap),
      wanghongProfile: WanghongProfile.fromMap(wanghongMap),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'phone': phone,
      'roles': roles.map((r) => r.name).toList(),
      'activeRole': activeRole.name,
      'profiles': {
        'buyer': buyerProfile.toMap(),
        'seller': sellerProfile.toMap(),
        'wanghong': wanghongProfile.toMap(),
      },
    };
  }
}

class BuyerProfile {
  final bool completed;

  final String fullName;
  final String city;

  // Один адрес
  final String street;
  final String apartment;
  final String comment;

  // Контакт
  final String contactPhone;

  final bool acceptedTerms;

  const BuyerProfile({
    required this.completed,
    required this.fullName,
    required this.city,
    required this.street,
    required this.apartment,
    required this.comment,
    required this.contactPhone,
    required this.acceptedTerms,
  });

  factory BuyerProfile.empty() => const BuyerProfile(
        completed: false,
        fullName: '',
        city: 'Алматы',
        street: '',
        apartment: '',
        comment: '',
        contactPhone: '',
        acceptedTerms: false,
      );

  factory BuyerProfile.fromMap(Map<String, dynamic> m) {
    return BuyerProfile(
      completed: (m['completed'] as bool?) ?? false,
      fullName: (m['fullName'] as String?) ?? '',
      city: (m['city'] as String?) ?? 'Алматы',
      street: (m['street'] as String?) ?? '',
      apartment: (m['apartment'] as String?) ?? '',
      comment: (m['comment'] as String?) ?? '',
      contactPhone: (m['contactPhone'] as String?) ?? '',
      acceptedTerms: (m['acceptedTerms'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'completed': completed,
        'fullName': fullName,
        'city': city,
        'street': street,
        'apartment': apartment,
        'comment': comment,
        'contactPhone': contactPhone,
        'acceptedTerms': acceptedTerms,
      };

  BuyerProfile copyWith({
    bool? completed,
    String? fullName,
    String? city,
    String? street,
    String? apartment,
    String? comment,
    String? contactPhone,
    bool? acceptedTerms,
  }) {
    return BuyerProfile(
      completed: completed ?? this.completed,
      fullName: fullName ?? this.fullName,
      city: city ?? this.city,
      street: street ?? this.street,
      apartment: apartment ?? this.apartment,
      comment: comment ?? this.comment,
      contactPhone: contactPhone ?? this.contactPhone,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    );
  }
}

class SellerProfile {
  final bool completed;

  const SellerProfile({required this.completed});

  factory SellerProfile.empty() => const SellerProfile(completed: false);

  factory SellerProfile.fromMap(Map<String, dynamic> m) {
    return SellerProfile(completed: (m['completed'] as bool?) ?? false);
  }

  Map<String, dynamic> toMap() => {'completed': completed};
}

class WanghongProfile {
  final bool completed;

  const WanghongProfile({required this.completed});

  factory WanghongProfile.empty() => const WanghongProfile(completed: false);

  factory WanghongProfile.fromMap(Map<String, dynamic> m) {
    return WanghongProfile(completed: (m['completed'] as bool?) ?? false);
  }

  Map<String, dynamic> toMap() => {'completed': completed};
}
